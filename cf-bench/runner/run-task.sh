#!/usr/bin/env bash
# Single benchmark run: run-task.sh <task-file> <A|B> <repeat-idx>
# Emits one TSV row to stdout. Diagnostics go to stderr.
set -euo pipefail

TASK_FILE="$1"; VARIANT="$2"; REPEAT="${3:-1}"
BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${CFBENCH_MODEL:-sonnet}"
CLAUDE_BIN="${CFBENCH_CLAUDE_BIN:-claude}"   # override with a mock in tests
AGENT="${CFBENCH_AGENT:-claude}"             # claude | opencode — engine under test
OPENCODE_BIN="${CFBENCH_OPENCODE_BIN:-opencode}"

# shellcheck source=/dev/null
HIDDEN=""
# The task file declares PROVIDER_<V>, but an explicit env var from the caller wins
# (same precedence as every CFBENCH_* override) -- captured before source clobbers it.
PROVIDER_VAR="PROVIDER_$VARIANT"
PROVIDER_OVERRIDE="${!PROVIDER_VAR:-}"
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
PROVIDER="${PROVIDER_OVERRIDE:-${!PROVIDER_VAR:-anthropic}}"
CLAUDE_ENV=(env)
OLLAMA_URL=""
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

# The model id is engine-shaped: claude takes an alias ("sonnet") or the bare ollama
# tag behind ANTHROPIC_BASE_URL, opencode takes provider/model and routes from its
# own config. A task-declared PROVIDER_<V> outranks the global CFBENCH_OPENCODE_MODEL
# -- otherwise one exported variable silently re-provisions every variant in a matrix.
if [ "$AGENT" = "opencode" ]; then
  case "$PROVIDER" in
    ollama:*) MODEL="ollama/$OLLAMA_TAG" ;;
    *)
      if [ -z "${CFBENCH_OPENCODE_MODEL:-}" ]; then
        echo "FATAL: CFBENCH_AGENT=opencode needs CFBENCH_OPENCODE_MODEL as provider/model (e.g. anthropic/claude-sonnet-4-5)" >&2
        exit 2
      fi
      MODEL="$CFBENCH_OPENCODE_MODEL"
      ;;
  esac
fi

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
#
# Engine note: claude reads configs as CLAUDE.md (project instruction file);
# opencode reads AGENTS.md. The same config directory feeds either engine — the
# copied CLAUDE.md is renamed below, so a task stays engine-agnostic.
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
if [ "$AGENT" = "opencode" ] && [ -f "$WORK/CLAUDE.md" ] && [ ! -f "$WORK/AGENTS.md" ]; then
  mv "$WORK/CLAUDE.md" "$WORK/AGENTS.md"
fi

RESULT_JSON="$WORK/.cfbench-result.json"
if [ "$AGENT" = "opencode" ]; then
  # opencode has no --max-turns and no --allowedTools: the turn ceiling and the
  # tool allowlist live in a project opencode.json, and a provider swap is a
  # baseURL in that same file (opencode ignores ANTHROPIC_BASE_URL, so CLAUDE_ENV
  # would route nothing). Same three knobs as the claude flags, other surface.
  python3 - "$WORK/opencode.json" "$MAX_TURNS" "$ALLOWED_TOOLS" "$MODEL" "$OLLAMA_URL" <<'OCCFG'
import json, sys
out, max_turns, allowed, model, ollama_url = sys.argv[1:6]

# ALLOWED_TOOLS is written in claude's vocabulary; translate it once.
bash_rules, perm = {}, {"webfetch": "deny", "websearch": "deny", "task": "deny"}
names = {"Read": "read", "Glob": "glob", "Grep": "grep", "Edit": "edit", "Write": "edit"}
for tool in [t for t in allowed.split(",") if t]:
    if tool.startswith("Bash(") and tool.endswith(")"):
        bash_rules[tool[5:-1].replace(":*", " *")] = "allow"
    elif tool in names:
        perm[names[tool]] = "allow"
# Whatever the task did not grant is denied, so both engines run with the same
# hands -- and an offline run stays offline (no npm install, no curl).
# Known asymmetry: opencode's todowrite stays allowed (denying it costs turns on a
# bookkeeping call that cannot touch the fixture); claude has no TodoWrite grant.
bash_rules["*"] = "deny"
perm["bash"] = bash_rules

cfg = {"permission": perm, "agent": {"build": {"steps": int(max_turns)}}}
if model.startswith("ollama/"):
    tag = model.split("/", 1)[1]
    cfg["provider"] = {"ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama",
        "options": {"baseURL": ollama_url.rstrip("/") + "/v1"},
        "models": {tag: {"name": tag}},
    }}
json.dump(cfg, open(out, "w"), indent=2)
OCCFG
  set +e
  ( cd "$WORK" && env "$OPENCODE_BIN" run --auto --format json \
      -m "${MODEL}" \
      "$PROMPT" \
      > "$RESULT_JSON" 2>>"$WORK/.cfbench-stderr.log" )
  ENGINE_EXIT=$?
  set -e
  # Left empty on purpose: the real reason comes off the last step_finish event in
  # the metrics block below, and only falls back to the exit code if none arrived.
  TERMINAL_REASON=""
else
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
TERMINAL_REASON=""
fi

# Diagnose invalid runs: without this the mktemp cleanup eats the only error trace.
ENGINE_EXIT="${ENGINE_EXIT:-$CLAUDE_EXIT}"
if [ "$ENGINE_EXIT" -ne 0 ]; then
  echo "engine ($AGENT) exit $ENGINE_EXIT; stderr tail:" >&2
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
if [ "$AGENT" = "opencode" ]; then
  CLI_VERSION="${CFBENCH_CLI_VERSION:-$("$OPENCODE_BIN" --version 2>/dev/null | head -1 || echo unknown)}"
fi

python3 - "$RESULT_JSON" "$TASK_ID" "$VARIANT" "$REPEAT" "$MODEL" "$SUCCESS" "$ENGINE_EXIT" "$CLI_VERSION" "$AGENT" "$TERMINAL_REASON" <<'PY'
import json, sys, datetime
path, task, variant, repeat, model, success, eexit, cli_version, agent, terminal_reason = sys.argv[1:11]
try:
    d = json.load(open(path))
except Exception:
    d = {}

# opencode's --format json is a JSONL event stream, not one result object, so it
# never parses above. Fold it into the claude result shape here and the rest of the
# runner (and every consumer of the TSV) stays engine-agnostic.
if agent == "opencode":
    events = []
    for line in open(path, errors="replace"):
        line = line.strip()
        if line:
            try:
                events.append(json.loads(line))
            except Exception:
                pass
    steps = [e.get("part", {}) for e in events if e.get("type") == "step_finish"]
    errors = [e for e in events if e.get("type") == "error"]
    tok = lambda k: sum(s.get("tokens", {}).get(k, 0) for s in steps)
    cache = lambda k: sum(s.get("tokens", {}).get("cache", {}).get(k, 0) for s in steps)
    d = {
        "total_cost_usd": sum(s.get("cost", 0) for s in steps),
        "num_turns": len(steps),
        "duration_ms": events[-1].get("timestamp", 0) - events[0].get("timestamp", 0) if events else "",
        "session_id": events[0].get("sessionID", "") if events else "",
        "usage": {
            "input_tokens": tok("input"), "output_tokens": tok("output"),
            "cache_creation_input_tokens": cache("write"), "cache_read_input_tokens": cache("read"),
        },
        "terminal_reason": steps[-1].get("reason", "") if steps else "",
    }
    # An error event, or a stream with no finished step at all (crash, rate limit,
    # killed process), means the run never happened -- INVALID, not a failure.
    if errors or not steps:
        d["is_error"] = True
        d["terminal_reason"] = "api_error"

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
    terminal_reason or d.get("terminal_reason") or f"{agent}_exit_{eexit}", d.get("session_id", ""),
    cli_version,
]
print("\t".join(str(c) for c in row))
PY
