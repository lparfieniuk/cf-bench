#!/usr/bin/env bash
# Full matrix: every tasks/*.task × variants A,B × CFBENCH_REPEATS (default 3).
# Writes results/bench-<timestamp>.tsv and prints it.
set -euo pipefail

BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPEATS="${CFBENCH_REPEATS:-3}"
OUT="$BENCH_ROOT/results/bench-$(date +%Y%m%d-%H%M%S).tsv"
mkdir -p "$BENCH_ROOT/results"

HEADER="ts	task	variant	repeat	model	success	cost_usd	turns	duration_ms	in_tokens	cache_creation	cache_read	out_tokens	terminal_reason	session_id"
echo "$HEADER" > "$OUT"

for TASK_FILE in "$BENCH_ROOT"/tasks/*.task; do
  for VARIANT in A B; do
    for i in $(seq 1 "$REPEATS"); do
      echo ">> $(basename "$TASK_FILE") $VARIANT #$i" >&2
      bash "$BENCH_ROOT/runner/run-task.sh" "$TASK_FILE" "$VARIANT" "$i" >> "$OUT"
    done
  done
done

echo "$OUT"
