#!/usr/bin/env bash
# Single benchmark run: run-task.sh <task-file> <A|B> <repeat-idx>
# Emits one TSV row to stdout. Diagnostics go to stderr.
set -euo pipefail

TASK_FILE="$1"; VARIANT="$2"; REPEAT="${3:-1}"
BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${CFBENCH_MODEL:-sonnet}"
CLAUDE_BIN="${CFBENCH_CLAUDE_BIN:-claude}"   # override with a mock in tests

# shellcheck source=/dev/null
source "$TASK_FILE"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/cfbench.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$BENCH_ROOT/fixtures/$FIXTURE/." "$WORK/"

# Sanity gate: fixture must be broken before the agent runs.
if bash "$WORK/$CHECK" 2>/dev/null; then
  echo "FATAL: fixture '$FIXTURE' passes its check before the run — nothing to fix" >&2
  exit 2
fi

if [ "$VARIANT" = "B" ]; then
  cp -R "$BENCH_ROOT/configs/$CONFIG/." "$WORK/"
fi

RESULT_JSON="$WORK/.cfbench-result.json"
set +e
( cd "$WORK" && "$CLAUDE_BIN" -p "$PROMPT" \
    --output-format json \
    --model "$MODEL" \
    --max-turns "$MAX_TURNS" \
    --setting-sources project \
    --permission-mode acceptEdits \
    --allowedTools "$ALLOWED_TOOLS" \
    > "$RESULT_JSON" 2>>"$WORK/.cfbench-stderr.log" )
CLAUDE_EXIT=$?
set -e

if bash "$WORK/$CHECK" 2>/dev/null; then SUCCESS=1; else SUCCESS=0; fi

python3 - "$RESULT_JSON" "$TASK_ID" "$VARIANT" "$REPEAT" "$MODEL" "$SUCCESS" "$CLAUDE_EXIT" <<'PY'
import json, sys, datetime
path, task, variant, repeat, model, success, cexit = sys.argv[1:8]
try:
    d = json.load(open(path))
except Exception:
    d = {}
u = d.get("usage", {})
row = [
    datetime.datetime.now().isoformat(timespec="seconds"),
    task, variant, repeat, model, success,
    f'{d.get("total_cost_usd", "")}', f'{d.get("num_turns", "")}',
    f'{d.get("duration_ms", "")}',
    f'{u.get("input_tokens", "")}', f'{u.get("cache_creation_input_tokens", "")}',
    f'{u.get("cache_read_input_tokens", "")}', f'{u.get("output_tokens", "")}',
    d.get("terminal_reason", f"claude_exit_{cexit}"), d.get("session_id", ""),
]
print("\t".join(str(c) for c in row))
PY
