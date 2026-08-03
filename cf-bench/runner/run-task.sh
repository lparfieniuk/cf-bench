#!/usr/bin/env bash
# Single benchmark run: run-task.sh <task-file> <A|B> <repeat-idx>
# Emits one TSV row to stdout. Diagnostics go to stderr.
set -euo pipefail

TASK_FILE="$1"; VARIANT="$2"; REPEAT="${3:-1}"
BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${CFBENCH_MODEL:-sonnet}"
CLAUDE_BIN="${CFBENCH_CLAUDE_BIN:-claude}"   # override with a mock in tests

# shellcheck source=/dev/null
HIDDEN=""
source "$TASK_FILE"

# Deps are installed once by runner/setup-fixtures.sh — a run must never touch the
# network. Without this guard a missing node_modules costs a paid run and surfaces
# as a mystery test failure instead of a setup error.
if [ -f "$BENCH_ROOT/fixtures/$FIXTURE/package-lock.json" ] && [ ! -d "$BENCH_ROOT/fixtures/$FIXTURE/node_modules" ]; then
  echo "FATAL: fixture '$FIXTURE' has no node_modules — run runner/setup-fixtures.sh first" >&2
  exit 2
fi

# Provider per variant. A variant is normally a config directory; variant D is a
# PROVIDER swap of B -- same fixture, same config, same check, same MAX_TURNS, so
# the only thing that differs is which process serves the tokens and Δ(D−B) is the
# provider effect and nothing else.
#
#   VARIANTS="A B D"
#   PROVIDER_D="ollama:cfaios-qwen3-14b-32k"
#
# Routing is session-wide (there is no per-subagent provider), so the boundary is
# this process: two env vars and --model. No proxy, no gateway.
PROVIDER_VAR="PROVIDER_$VARIANT"
PROVIDER="${!PROVIDER_VAR:-anthropic}"
CLAUDE_ENV=(env)
case "$PROVIDER" in
  anthropic) ;;
  ollama:?*)
    OLLAMA_TAG="${PROVIDER#ollama:}"
    OLLAMA_URL="${CFBENCH_OLLAMA_URL:-http://localhost:11434}"
    # Preflight BEFORE the fixture is copied: a down server, a missing tag or an
    # unpinned context window must cost an error, not a degraded run. Ollama
    # defaults sit below the model maximum and the failure is silent.
    if ! curl -sf -m 5 "$OLLAMA_URL/api/version" >/dev/null 2>&1; then
      echo "FATAL: variant $VARIANT wants $PROVIDER but ollama is not reachable at $OLLAMA_URL" >&2
      exit 2
    fi
    OLLAMA_CTX="$("${CFBENCH_OLLAMA_BIN:-ollama}" show "$OLLAMA_TAG" 2>/dev/null | awk '$1 == "num_ctx" { print $2 }' | head -1)"
    if [ -z "$OLLAMA_CTX" ] || [ "$OLLAMA_CTX" -lt 32768 ]; then
      echo "FATAL: ollama tag '$OLLAMA_TAG' has num_ctx '${OLLAMA_CTX:-unset}', below the 32768 floor for coding" >&2
      exit 2
    fi
    MODEL="$OLLAMA_TAG"
    CLAUDE_ENV=(env "ANTHROPIC_BASE_URL=$OLLAMA_URL" "ANTHROPIC_AUTH_TOKEN=ollama")
    ;;
  *)
    echo "FATAL: $PROVIDER_VAR must be 'anthropic' or 'ollama:<tag>' (got '$PROVIDER')" >&2
    exit 2
    ;;
esac

WORK="$(mktemp -d "${TMPDIR:-/tmp}/cfbench.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$BENCH_ROOT/fixtures/$FIXTURE/." "$WORK/"

# Sanity gate: fixture must be broken before the agent runs.
if bash "$WORK/$CHECK" 2>/dev/null; then
  echo "FATAL: fixture '$FIXTURE' passes its check before the run — nothing to fix" >&2
  exit 2
fi

# A = bare fixture; B = task's CONFIG; any other letter needs CONFIG_<letter>
# in the .task (e.g. CONFIG_C="generic" — placebo config, no task knowledge).
if [ "$VARIANT" = "B" ]; then
  cp -R "$BENCH_ROOT/configs/$CONFIG/." "$WORK/"
elif [ "$VARIANT" != "A" ]; then
  CONFIG_VAR="CONFIG_$VARIANT"
  # A provider-swap variant reuses B's config by default, so adding an Ollama arm
  # is one line per task instead of a duplicated config directory.
  VARIANT_CONFIG="${!CONFIG_VAR:-}"
  if [ -z "$VARIANT_CONFIG" ] && [ "$PROVIDER" != "anthropic" ]; then
    VARIANT_CONFIG="$CONFIG"
  fi
  if [ -z "$VARIANT_CONFIG" ]; then
    echo "FATAL: variant $VARIANT requested but neither $CONFIG_VAR nor $PROVIDER_VAR set in $TASK_FILE" >&2
    exit 2
  fi
  cp -R "$BENCH_ROOT/configs/$VARIANT_CONFIG/." "$WORK/"
fi

RESULT_JSON="$WORK/.cfbench-result.json"
set +e
( cd "$WORK" && "${CLAUDE_ENV[@]}" "$CLAUDE_BIN" -p "$PROMPT" \
    --output-format json \
    --model "$MODEL" \
    --max-turns "$MAX_TURNS" \
    --setting-sources project \
    --permission-mode acceptEdits \
    --allowedTools "$ALLOWED_TOOLS" \
    > "$RESULT_JSON" 2>>"$WORK/.cfbench-stderr.log" )
CLAUDE_EXIT=$?
set -e

# Diagnose invalid runs: without this the mktemp cleanup eats the only error trace.
if [ "$CLAUDE_EXIT" -ne 0 ]; then
  echo "claude exit $CLAUDE_EXIT; stderr tail:" >&2
  tail -3 "$WORK/.cfbench-stderr.log" >&2 || true
fi

# Hidden assertions: spec that lives outside the repo (like team knowledge).
# Injected AFTER the agent run so visible tests stay ambiguous by design.
if [ -n "$HIDDEN" ]; then
  cp -R "$BENCH_ROOT/fixtures-hidden/$HIDDEN/." "$WORK/"
fi

if bash "$WORK/$CHECK" 2>/dev/null; then SUCCESS=1; else SUCCESS=0; fi

# CFBENCH_CLI_VERSION override keeps mocks from being invoked with --version in tests.
CLI_VERSION="${CFBENCH_CLI_VERSION:-$("$CLAUDE_BIN" --version 2>/dev/null | head -1 || echo unknown)}"

python3 - "$RESULT_JSON" "$TASK_ID" "$VARIANT" "$REPEAT" "$MODEL" "$SUCCESS" "$CLAUDE_EXIT" "$CLI_VERSION" <<'PY'
import json, sys, datetime
path, task, variant, repeat, model, success, cexit, cli_version = sys.argv[1:9]
try:
    d = json.load(open(path))
except Exception:
    d = {}
u = d.get("usage", {})
# A run that never executed (API error, rate limit) is INVALID, not a failure:
# success column stays empty so summaries exclude it instead of skewing rates.
if d.get("is_error") or d.get("api_error_status") or d.get("terminal_reason") == "api_error":
    success = ""
row = [
    datetime.datetime.now().isoformat(timespec="seconds"),
    task, variant, repeat, model, success,
    f'{d.get("total_cost_usd", "")}', f'{d.get("num_turns", "")}',
    f'{d.get("duration_ms", "")}',
    f'{u.get("input_tokens", "")}', f'{u.get("cache_creation_input_tokens", "")}',
    f'{u.get("cache_read_input_tokens", "")}', f'{u.get("output_tokens", "")}',
    d.get("terminal_reason", f"claude_exit_{cexit}"), d.get("session_id", ""),
    cli_version,
]
print("\t".join(str(c) for c in row))
PY
