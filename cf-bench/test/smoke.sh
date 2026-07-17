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

# Outcome validity: every task must be broken pre-oracle and solvable post-oracle.
bash "$BENCH_ROOT/runner/validate-tasks.sh" || FAIL=1

[ "$FAIL" -eq 0 ] && echo "SMOKE: PASS" || { echo "SMOKE: FAIL"; exit 1; }
