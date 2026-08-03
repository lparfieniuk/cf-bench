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
echo '{"type":"result","subtype":"success","num_turns":4,"duration_ms":12345,"total_cost_usd":0.0421,"terminal_reason":"completed","session_id":"mock-session","usage":{"input_tokens":10,"cache_creation_input_tokens":8000,"cache_read_input_tokens":15000,"output_tokens":420}}'
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

# Outcome validity: every task must be broken pre-oracle and solvable post-oracle.
bash "$BENCH_ROOT/runner/validate-tasks.sh" || FAIL=1

[ "$FAIL" -eq 0 ] && echo "SMOKE: PASS" || { echo "SMOKE: FAIL"; exit 1; }
