#!/usr/bin/env bash
# Pipeline self-check without LLM cost. Mocks `claude` with a script that
# "fixes" the fixture bug and emits canned result JSON. Asserts a valid TSV row.
set -euo pipefail
BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CFBENCH_CLI_VERSION="mock-cli"

MOCK_DIR="$(mktemp -d)"
trap 'rm -rf "$MOCK_DIR"' EXIT
cat > "$MOCK_DIR/claude-mock" <<'EOF'
#!/usr/bin/env bash
# Mock agent: apply the correct fix in cwd, print canned result JSON.
sed -i '' -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js 2>/dev/null \
  || sed -i -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js
# `is_error` and `api_error_status` are present on a REAL successful result too (false
# and null). The mock has to carry them, otherwise the "a healthy run writes no
# diagnostics" assertion below passes against any condition, however broad -- which is
# how a condition matching the field NAME `api_error_status` shipped on 2026-09-09.
echo '{"type":"result","subtype":"success","is_error":false,"api_error_status":null,"num_turns":4,"duration_ms":12345,"total_cost_usd":0.0421,"terminal_reason":"completed","session_id":"mock-session","usage":{"input_tokens":10,"cache_creation_input_tokens":8000,"cache_read_input_tokens":15000,"output_tokens":420}}'
EOF
chmod +x "$MOCK_DIR/claude-mock"

ROW=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-mock" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" B 1)

echo "$ROW"
FAIL=0
echo "$ROW" | awk -F'\t' '{ exit !(NF==16) }'            || { echo "FAIL: expected 16 TSV columns"; FAIL=1; }
echo "$ROW" | cut -f6 | grep -qx 1                        || { echo "FAIL: success!=1 (mock fix should pass check)"; FAIL=1; }
echo "$ROW" | cut -f7 | grep -qx 0.0421                   || { echo "FAIL: cost_usd not parsed"; FAIL=1; }
echo "$ROW" | cut -f8 | grep -qx 4                        || { echo "FAIL: turns not parsed"; FAIL=1; }

# Variant A of the same run must FAIL the check if the agent does nothing:
cat > "$MOCK_DIR/claude-noop" <<'EOF'
#!/usr/bin/env bash
echo '{"type":"result","num_turns":1,"duration_ms":1,"total_cost_usd":0.01,"terminal_reason":"completed","session_id":"noop","usage":{}}'
EOF
chmod +x "$MOCK_DIR/claude-noop"
ROW2=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-noop" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" A 1)
echo "$ROW2" | cut -f6 | grep -qx 0                       || { echo "FAIL: noop agent should yield success=0"; FAIL=1; }

# An invalid run must leave a durable trace. `claude --output-format json` reports an
# API error inside the result JSON on STDOUT and leaves stderr empty, so a diagnostic
# that only tails stderr prints nothing and the mktemp cleanup takes the evidence with
# it. That is exactly what happened to the 2026-09-08 XL matrix: the halt was real, the
# cause was never captured. Assert the files land.
cat > "$MOCK_DIR/claude-apierror" <<'EOF'
#!/usr/bin/env bash
echo '{"type":"result","is_error":true,"terminal_reason":"api_error","total_cost_usd":0,"num_turns":0,"session_id":"mock-err","usage":{}}'
exit 1
EOF
chmod +x "$MOCK_DIR/claude-apierror"
DIAG_BEFORE=$(ls "$BENCH_ROOT"/results/diagnostics 2>/dev/null | wc -l | tr -d ' ')
ROW_ERR=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-apierror"   bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" A 99 2>/dev/null)
echo "$ROW_ERR" | cut -f6 | grep -qx ''                   || { echo "FAIL: api_error run must leave success empty (invalid, not failed)"; FAIL=1; }
DIAG_AFTER=$(ls "$BENCH_ROOT"/results/diagnostics 2>/dev/null | wc -l | tr -d ' ')
[ "$DIAG_AFTER" -gt "$DIAG_BEFORE" ]                      || { echo "FAIL: invalid run left no diagnostics file"; FAIL=1; }
ls "$BENCH_ROOT"/results/diagnostics/ts-fix-discount-001-A-99-*.result.json >/dev/null 2>&1                                                           || { echo "FAIL: diagnostics missing the result JSON, where the API error actually lives"; FAIL=1; }
rm -f "$BENCH_ROOT"/results/diagnostics/ts-fix-discount-001-A-99-*

# ...and the mirror assertion, which is the one that actually pins the CONDITION rather
# than the block's existence: a HEALTHY run must leave no diagnostics at all. Without it
# the check above passes even when the invalid-run test matches everything, which is
# exactly the bug that shipped on 2026-09-09.
DIAG_BEFORE_OK=$(ls "$BENCH_ROOT"/results/diagnostics 2>/dev/null | wc -l | tr -d ' ')
ROW_OK=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-mock" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" A 98 2>/dev/null)
DIAG_AFTER_OK=$(ls "$BENCH_ROOT"/results/diagnostics 2>/dev/null | wc -l | tr -d ' ')
[ "$DIAG_AFTER_OK" -eq "$DIAG_BEFORE_OK" ]                || { echo "FAIL: a healthy run wrote diagnostics — the invalid-run condition matches everything"; FAIL=1; }
rm -f "$BENCH_ROOT"/results/diagnostics/ts-fix-discount-001-A-98-*

# Hidden-assertion task: agent passing VISIBLE tests but violating the hidden
# policy (multiplicative stacking, no cap) must yield success=0.
cat > "$MOCK_DIR/claude-multiplicative" <<'EOF'
#!/usr/bin/env bash
cat > src/discounts.js <<'JS'
export function stackDiscounts(price, percents) {
  return percents.reduce((p, pct) => p * (1 - pct / 100), price);
}
JS
echo '{"type":"result","num_turns":3,"duration_ms":1,"total_cost_usd":0.03,"terminal_reason":"completed","session_id":"mock-mult","usage":{}}'
EOF
chmod +x "$MOCK_DIR/claude-multiplicative"
ROW3=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-multiplicative" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/js-stack-discounts-002.task" A 1)
echo "$ROW3" | cut -f6 | grep -qx 0 || { echo "FAIL: multiplicative impl must fail hidden policy tests"; FAIL=1; }

# Agent following the policy (additive + 50% cap) must yield success=1.
cat > "$MOCK_DIR/claude-additive" <<'EOF'
#!/usr/bin/env bash
cat > src/discounts.js <<'JS'
export function stackDiscounts(price, percents) {
  const total = Math.min(percents.reduce((a, b) => a + b, 0), 50);
  return price * (1 - total / 100);
}
JS
echo '{"type":"result","num_turns":3,"duration_ms":1,"total_cost_usd":0.03,"terminal_reason":"completed","session_id":"mock-add","usage":{}}'
EOF
chmod +x "$MOCK_DIR/claude-additive"
ROW4=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-additive" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/js-stack-discounts-002.task" B 1)
echo "$ROW4" | cut -f6 | grep -qx 1 || { echo "FAIL: additive+cap impl must pass hidden policy tests"; FAIL=1; }

# Variant C (placebo config) path: must copy configs/$CONFIG_C and run normally.
ROW5=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-multiplicative" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/js-stack-discounts-002.task" C 1)
echo "$ROW5" | cut -f6 | grep -qx 0 || { echo "FAIL: variant C run broken"; FAIL=1; }

# Variant D (provider swap): the two routing env vars must reach the child and the
# ollama tag must be passed as --model. A static file server stands in for the
# Ollama endpoint so this stays offline and deterministic; `ollama show` is faked
# through CFBENCH_OLLAMA_BIN.
mkdir -p "$MOCK_DIR/api"
echo '{"version":"mock"}' > "$MOCK_DIR/api/version"
PORT=59431
# A leaked server from an interrupted earlier run keeps this fixed port and answers 404
# to everything, so the new server never binds and the failure surfaces as
# "ollama is not reachable" -- a preflight error that looks like a product bug and is not.
# Cost of finding that out the hard way, 2026-09-08: ~10 minutes. Fail loudly instead.
if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "FATAL: port $PORT is already in use -- most likely a leaked http.server from an" >&2
  echo "interrupted smoke run. Free it first:  kill \$(lsof -t -iTCP:$PORT -sTCP:LISTEN)" >&2
  exit 2
fi
python3 -m http.server "$PORT" --directory "$MOCK_DIR" >/dev/null 2>&1 &
HTTP_PID=$!
disown "$HTTP_PID" 2>/dev/null || true   # otherwise bash prints "Terminated" at exit
trap 'kill "$HTTP_PID" 2>/dev/null; rm -rf "$MOCK_DIR"' EXIT
for _ in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf -m 1 "http://localhost:$PORT/api/version" >/dev/null 2>&1 && break
  sleep 0.2
done

cat > "$MOCK_DIR/ollama-mock" <<'EOF'
#!/usr/bin/env bash
[ "$1" = show ] || exit 1
printf '  Parameters\n    num_ctx    32768\n'
EOF
chmod +x "$MOCK_DIR/ollama-mock"

cat > "$MOCK_DIR/claude-envrec" <<'EOF'
#!/usr/bin/env bash
{ env | grep '^ANTHROPIC_' | sort; printf '%s\n' "$@"; } > "$CFBENCH_ENV_RECORD"
sed -i '' -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js 2>/dev/null \
  || sed -i -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js
echo '{"type":"result","subtype":"success","num_turns":4,"duration_ms":99,"total_cost_usd":0.5,"terminal_reason":"completed","session_id":"mock-d","usage":{"input_tokens":42967,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":493}}'
EOF
chmod +x "$MOCK_DIR/claude-envrec"

ROW6=$(CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-envrec" \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  CFBENCH_OLLAMA_BIN="$MOCK_DIR/ollama-mock" \
  CFBENCH_OLLAMA_URL="http://localhost:$PORT" \
  PROVIDER_D="ollama:mock-tag-32k" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" D 1)
echo "$ROW6" | cut -f6 | grep -qx 1 || { echo "FAIL: variant D run broken"; FAIL=1; }
echo "$ROW6" | cut -f5 | grep -qx mock-tag-32k || { echo "FAIL: variant D model column is not the ollama tag"; FAIL=1; }
grep -qx 'ANTHROPIC_BASE_URL=http://localhost:'"$PORT" "$MOCK_DIR/envrec.txt" \
  || { echo "FAIL: variant D did not export ANTHROPIC_BASE_URL"; FAIL=1; }
grep -qx 'ANTHROPIC_AUTH_TOKEN=ollama' "$MOCK_DIR/envrec.txt" \
  || { echo "FAIL: variant D did not export ANTHROPIC_AUTH_TOKEN"; FAIL=1; }
grep -qx 'mock-tag-32k' "$MOCK_DIR/envrec.txt" \
  || { echo "FAIL: variant D did not pass the tag as --model"; FAIL=1; }

# An unreachable Ollama must cost nothing: no fixture copy, no claude process.
rm -f "$MOCK_DIR/envrec.txt"
set +e
CFBENCH_CLAUDE_BIN="$MOCK_DIR/claude-envrec" \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  CFBENCH_OLLAMA_BIN="$MOCK_DIR/ollama-mock" \
  CFBENCH_OLLAMA_URL="http://localhost:59999" \
  PROVIDER_D="ollama:mock-tag-32k" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" D 1 >/dev/null 2>&1
RC_D=$?
set -e
[ "$RC_D" -eq 2 ] || { echo "FAIL: unreachable ollama should exit 2, got $RC_D"; FAIL=1; }
[ ! -f "$MOCK_DIR/envrec.txt" ] || { echo "FAIL: unreachable ollama still invoked claude"; FAIL=1; }

# The opencode engine arm. opencode takes no --max-turns and no --allowedTools, so
# the ceiling and the allowlist have to land in the project opencode.json -- if they
# do not, the two engines are not running the same experiment and every delta is
# confounded. The mock records the config it was handed and emits the real JSONL
# event shape (verified against opencode 1.18.21).
cat > "$MOCK_DIR/opencode-mock" <<'EOF'
#!/usr/bin/env bash
REC_DIR="$(dirname "$CFBENCH_ENV_RECORD")"
printf '%s\n' "$@" > "$CFBENCH_ENV_RECORD"
env | grep '^OPENCODE_' | sort > "$REC_DIR/opencode-env.txt"
cp opencode.json "$REC_DIR/opencode-seen.json" 2>/dev/null
ls > "$REC_DIR/workdir-ls.txt"
sed -i '' -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js 2>/dev/null \
  || sed -i -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js
cat <<'JSONL'
{"type":"step_start","timestamp":1000,"sessionID":"ses_mock","part":{}}
{"type":"error","timestamp":1100,"sessionID":"ses_mock","error":{"name":"ProviderError","data":{"message":"transient"}}}
{"type":"step_finish","timestamp":1200,"sessionID":"ses_mock","part":{"reason":"tool-calls","tokens":{"input":100,"output":10,"reasoning":5,"cache":{"write":1,"read":2}},"cost":0.5}}
{"type":"step_finish","timestamp":1500,"sessionID":"ses_mock","part":{"reason":"stop","tokens":{"input":200,"output":20,"reasoning":7,"cache":{"write":3,"read":4}},"cost":0.25}}
JSONL
EOF
chmod +x "$MOCK_DIR/opencode-mock"

rm -f "$MOCK_DIR/envrec.txt" "$MOCK_DIR/opencode-seen.json"
ROW7=$(CFBENCH_AGENT=opencode \
  CFBENCH_OPENCODE_BIN="$MOCK_DIR/opencode-mock" \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  CFBENCH_OLLAMA_BIN="$MOCK_DIR/ollama-mock" \
  CFBENCH_OLLAMA_URL="http://localhost:$PORT" \
  PROVIDER_D="ollama:mock-tag-32k" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" D 1)
echo "$ROW7" | cut -f6 | grep -qx 1 || { echo "FAIL: opencode run broken"; FAIL=1; }
# provider/model, not the bare tag: opencode resolves a bare id against its default
# provider, which would serve the tokens from somewhere else than the row claims.
echo "$ROW7" | cut -f5 | grep -qx 'ollama/mock-tag-32k' \
  || { echo "FAIL: opencode model column is not provider/model"; FAIL=1; }
grep -qx 'ollama/mock-tag-32k' "$MOCK_DIR/envrec.txt" \
  || { echo "FAIL: opencode did not get the provider/model id"; FAIL=1; }
# The JSONL event stream must be folded into the same columns the claude arm fills.
echo "$ROW7" | cut -f7 | grep -qx 0.75 || { echo "FAIL: opencode cost is not the step sum"; FAIL=1; }
echo "$ROW7" | cut -f8 | grep -qx 2 || { echo "FAIL: opencode turns is not the step count"; FAIL=1; }
# duration_ms is now wall clock around the engine call, not the event span: the
# opencode timestamps start after server boot and model load, so a cold run looked warm.
echo "$ROW7" | cut -f9 | grep -qE '^[0-9]+$' \
  || { echo "FAIL: opencode duration_ms is not a wall-clock integer"; FAIL=1; }
echo "$ROW" | cut -f9 | grep -qE '^[0-9]+$' \
  || { echo "FAIL: claude duration_ms is not a wall-clock integer"; FAIL=1; }
echo "$ROW7" | cut -f10 | grep -qx 300 || { echo "FAIL: opencode input tokens not summed"; FAIL=1; }
# reasoning is a sibling of output in opencode's step struct; Anthropic counts
# thinking inside output_tokens, so the column has to carry both (10+20+5+7).
echo "$ROW7" | cut -f13 | grep -qx 42 || { echo "FAIL: opencode output tokens drop reasoning"; FAIL=1; }
# An error event that is NOT the last event is a transient failure the engine retried
# past: the run completed and must keep its success column, or every retry shrinks N.
echo "$ROW7" | cut -f6 | grep -qx 1 || { echo "FAIL: a retried-past error voided a completed run"; FAIL=1; }
echo "$ROW7" | cut -f14 | grep -qx stop \
  || { echo "FAIL: opencode terminal_reason is not the last step reason"; FAIL=1; }
echo "$ROW7" | cut -f15 | grep -qx ses_mock || { echo "FAIL: opencode session_id lost"; FAIL=1; }
# Config parity with the claude flags: turn ceiling, tool allowlist, provider route.
grep -qx AGENTS.md "$MOCK_DIR/workdir-ls.txt" || { echo "FAIL: config not renamed to AGENTS.md"; FAIL=1; }
grep -qx CLAUDE.md "$MOCK_DIR/workdir-ls.txt" && { echo "FAIL: CLAUDE.md left next to AGENTS.md"; FAIL=1; }
python3 - "$MOCK_DIR/opencode-seen.json" "$PORT" <<'PY' || FAIL=1
import json, sys
cfg = json.load(open(sys.argv[1]))
p = cfg.get("permission", {})
ok = True
def check(cond, msg):
    global ok
    if not cond:
        print("FAIL: " + msg)
        ok = False
# MAX_TURNS="15" in ts-fix-discount-001.task
check(cfg.get("agent", {}).get("build", {}).get("steps") == 15, "opencode.json steps is not MAX_TURNS")
check(p.get("bash", {}).get("node *") == "allow", "Bash(node:*) not translated to an allow rule")
check(p.get("bash", {}).get("npm *") == "allow", "Bash(npm:*) not translated to an allow rule")
check(p.get("bash", {}).get("*") == "deny", "ungranted bash commands are not denied")
check(p.get("edit") == "allow", "Edit/Write not granted")
# ORDER, not just presence: opencode resolves permissions with findLast and strips
# every tool whose last matching rule is a wildcard deny. The catch-all last therefore
# deleted bash from the toolset (verified against opencode 1.18.21).
check(list(p.keys())[0] == "*" and p["*"] == "deny",
      "the catch-all deny is not the FIRST permission rule (bash would be stripped)")
check(list(p["bash"].keys())[0] == "*",
      "the catch-all deny is not the FIRST bash rule (bash would be stripped)")
# A real allowlist, not --auto plus a deny list: --auto auto-approves anything not
# explicitly denied, so every ungranted tool must fall under the leading catch-all.
for k, v in p.items():
    if k != "bash":
        check(k == "*" or v == "allow", "unexpected non-allow permission key %r" % k)
check(not ({"todowrite", "skill", "task", "webfetch", "websearch"} & set(p)),
      "ungranted tools are listed explicitly instead of falling under the catch-all")
url = cfg.get("provider", {}).get("ollama", {}).get("options", {}).get("baseURL")
check(url == "http://localhost:%s/v1" % sys.argv[2], "ollama baseURL missing or wrong: %r" % url)
# num_ctx must reach the model as limit.context: without it opencode sets it to 0 and
# switches auto-compaction off, so the run overruns the window the preflight guards.
lim = cfg.get("provider", {}).get("ollama", {}).get("models", {}).get("mock-tag-32k", {}).get("limit", {})
check(lim.get("context") == 32768, "num_ctx did not reach limit.context: %r" % lim)
check(lim.get("output") == 8192, "limit.output missing (a limit without it is a config error): %r" % lim)
# OPENCODE_DISABLE_PROJECT_CONFIG also hides AGENTS.md, and a relative instructions
# entry then globs the operator's config dir -- only an absolute path survives both.
ins = cfg.get("instructions", [])
check(len(ins) == 1 and ins[0].startswith("/") and ins[0].endswith("/AGENTS.md"),
      "config file not pinned as an absolute instructions path: %r" % ins)
sys.exit(0 if ok else 1)
PY

# Isolation parity with claude's --setting-sources project.
grep -qx 'OPENCODE_DISABLE_PROJECT_CONFIG=1' "$MOCK_DIR/opencode-env.txt" \
  || { echo "FAIL: opencode run is not isolated from the operator's config walk"; FAIL=1; }
grep -q '^OPENCODE_CONFIG=.*/opencode.json$' "$MOCK_DIR/opencode-env.txt" \
  || { echo "FAIL: the generated opencode.json is not pinned via OPENCODE_CONFIG"; FAIL=1; }

# Variant A under opencode: no config directory, so no AGENTS.md and therefore no
# `instructions` key -- the only opencode path the D-variant cases never exercise.
rm -f "$MOCK_DIR/envrec.txt" "$MOCK_DIR/opencode-seen.json"
ROW7A=$(CFBENCH_AGENT=opencode \
  CFBENCH_OPENCODE_BIN="$MOCK_DIR/opencode-mock" \
  CFBENCH_OPENCODE_MODEL=mock/model \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" A 1)
echo "$ROW7A" | cut -f6 | grep -qx 1 || { echo "FAIL: opencode variant A run broken"; FAIL=1; }
python3 -c 'import json,sys; c=json.load(open(sys.argv[1])); sys.exit(0 if "instructions" not in c else 1)' \
  "$MOCK_DIR/opencode-seen.json" \
  || { echo "FAIL: variant A emitted an instructions path with no config to point at"; FAIL=1; }

# An opencode run that never produced a step is INVALID, not a failure: the success
# column must go empty so summaries drop the row instead of scoring the outage.
cat > "$MOCK_DIR/opencode-broken" <<'EOF'
#!/usr/bin/env bash
echo '{"type":"error","timestamp":1000,"sessionID":"ses_bad","error":{"name":"UnknownError","data":{"message":"boom"}}}'
exit 1
EOF
chmod +x "$MOCK_DIR/opencode-broken"
ROW8=$(CFBENCH_AGENT=opencode \
  CFBENCH_OPENCODE_BIN="$MOCK_DIR/opencode-broken" \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  CFBENCH_OLLAMA_BIN="$MOCK_DIR/ollama-mock" \
  CFBENCH_OLLAMA_URL="http://localhost:$PORT" \
  PROVIDER_D="ollama:mock-tag-32k" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" D 1 2>/dev/null)
[ -z "$(echo "$ROW8" | cut -f6)" ] || { echo "FAIL: opencode error event must void the success column"; FAIL=1; }
echo "$ROW8" | cut -f14 | grep -qx api_error \
  || { echo "FAIL: opencode error event must be recorded as api_error"; FAIL=1; }

# The other half of that gate: steps DID finish but the stream ends on an error --
# the run died mid-flight, so it is invalid too.
cat > "$MOCK_DIR/opencode-died" <<'EOF'
#!/usr/bin/env bash
cat <<'JSONL'
{"type":"step_finish","timestamp":1200,"sessionID":"ses_died","part":{"reason":"tool-calls","tokens":{"input":1,"output":1,"reasoning":0,"cache":{"write":0,"read":0}},"cost":0.01}}
{"type":"error","timestamp":1300,"sessionID":"ses_died","error":{"name":"RateLimit","data":{"message":"429"}}}
JSONL
exit 1
EOF
chmod +x "$MOCK_DIR/opencode-died"
ROW9=$(CFBENCH_AGENT=opencode \
  CFBENCH_OPENCODE_BIN="$MOCK_DIR/opencode-died" \
  CFBENCH_ENV_RECORD="$MOCK_DIR/envrec.txt" \
  CFBENCH_OLLAMA_BIN="$MOCK_DIR/ollama-mock" \
  CFBENCH_OLLAMA_URL="http://localhost:$PORT" \
  PROVIDER_D="ollama:mock-tag-32k" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" D 1 2>/dev/null)
[ -z "$(echo "$ROW9" | cut -f6)" ] || { echo "FAIL: a stream ending on an error must void the success column"; FAIL=1; }

# opencode without a provider-swap needs an explicit provider/model id -- "sonnet"
# is a claude alias and would resolve against whatever opencode defaults to.
set +e
CFBENCH_AGENT=opencode CFBENCH_OPENCODE_BIN="$MOCK_DIR/opencode-mock" \
  bash "$BENCH_ROOT/runner/run-task.sh" "$BENCH_ROOT/tasks/ts-fix-discount-001.task" B 1 >/dev/null 2>&1
RC_OC=$?
set -e
[ "$RC_OC" -eq 2 ] || { echo "FAIL: opencode without CFBENCH_OPENCODE_MODEL should exit 2, got $RC_OC"; FAIL=1; }

# The invalid-run arms above (the ollama preflight, the error stream) legitimately write
# diagnostics. Clean them here, at the END: a suite that grows a directory on every run is
# its own small leak. Placed early, this ran before the arms that create the files.
rm -f "$BENCH_ROOT"/results/diagnostics/ts-fix-discount-001-D-1-*

# Outcome validity: every task must be broken pre-oracle and solvable post-oracle.
bash "$BENCH_ROOT/runner/validate-tasks.sh" || FAIL=1

[ "$FAIL" -eq 0 ] && echo "SMOKE: PASS" || { echo "SMOKE: FAIL"; exit 1; }
