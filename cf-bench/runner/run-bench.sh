#!/usr/bin/env bash
# Matrix: tasks × variants A,B × CFBENCH_REPEATS (default 3).
# Optional $1 = task filename glob (default *.task), e.g. run-bench.sh 'js-brown-*.task'
# Writes results/bench-<timestamp>.tsv and prints it.
set -euo pipefail

BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPEATS="${CFBENCH_REPEATS:-3}"
TASK_GLOB="${1:-*.task}"
OUT="$BENCH_ROOT/results/bench-$(date +%Y%m%d-%H%M%S).tsv"
mkdir -p "$BENCH_ROOT/results"

HEADER="ts	task	variant	repeat	model	success	cost_usd	turns	duration_ms	in_tokens	cache_creation	cache_read	out_tokens	terminal_reason	session_id	cli_version"
echo "$HEADER" > "$OUT"

# Circuit breaker: 2 consecutive invalid runs (empty success = API error /
# rate limit) abort the whole matrix instead of burning every remaining slot.
ERR_STREAK=0
for TASK_FILE in "$BENCH_ROOT"/tasks/$TASK_GLOB; do
  # Per-task variant set: VARIANTS="A B C" in the .task adds e.g. a placebo config arm.
  TASK_VARIANTS=$( (VARIANTS="A B"; source "$TASK_FILE"; echo "$VARIANTS") )
  for VARIANT in $TASK_VARIANTS; do
    for i in $(seq 1 "$REPEATS"); do
      echo ">> $(basename "$TASK_FILE") $VARIANT #$i" >&2
      ROW=$(bash "$BENCH_ROOT/runner/run-task.sh" "$TASK_FILE" "$VARIANT" "$i")
      echo "$ROW" >> "$OUT"
      if [ -z "$(echo "$ROW" | cut -f6)" ]; then
        ERR_STREAK=$((ERR_STREAK + 1))
        if [ "$ERR_STREAK" -ge 2 ]; then
          echo "[CIRCUIT_BREAKER_HALT] 2 consecutive invalid runs (API error / rate limit) — aborting matrix. Partial results: $OUT" >&2
          echo "$OUT"
          exit 3
        fi
      else
        ERR_STREAK=0
      fi
    done
  done
done

echo "$OUT"
