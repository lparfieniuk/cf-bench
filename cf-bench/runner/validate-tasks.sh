#!/usr/bin/env bash
# Outcome-validity gate (Terminal-Bench "oracle solution" practice), zero LLM cost:
# for every task, (1) check must FAIL on the pristine fixture, (2) after applying
# oracles/<fixture>.sh + hidden assertions, check must PASS. Proves each task is
# both actually broken and actually solvable — catches impossible/miscalibrated checks.
# Oracles live OUTSIDE fixtures/ so they are never copied into an agent workdir.
set -euo pipefail
BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

for TASK_FILE in "$BENCH_ROOT"/tasks/*.task; do
  HIDDEN=""
  # shellcheck source=/dev/null
  source "$TASK_FILE"

  ORACLE="$BENCH_ROOT/oracles/$FIXTURE.sh"
  [ -f "$ORACLE" ] || ORACLE="$BENCH_ROOT/oracles/${FIXTURE%-xl}.sh"
  if [ ! -f "$ORACLE" ]; then
    echo "$TASK_ID: FAIL — no oracle for fixture '$FIXTURE'"
    FAIL=1
    continue
  fi

  WORK="$(mktemp -d "${TMPDIR:-/tmp}/cfbench-oracle.XXXXXX")"
  cp -R "$BENCH_ROOT/fixtures/$FIXTURE/." "$WORK/"

  if bash "$WORK/$CHECK" 2>/dev/null; then
    echo "$TASK_ID: FAIL — check passes on pristine fixture (nothing to fix)"
    FAIL=1
  else
    ( cd "$WORK" && bash "$ORACLE" )
    [ -n "$HIDDEN" ] && cp -R "$BENCH_ROOT/fixtures-hidden/$HIDDEN/." "$WORK/"
    if bash "$WORK/$CHECK" 2>/dev/null; then
      echo "$TASK_ID: OK"
    else
      echo "$TASK_ID: FAIL — oracle solution does not pass check (task unsolvable or check wrong)"
      FAIL=1
    fi
  fi
  rm -rf "$WORK"
done

[ "$FAIL" -eq 0 ] && echo "VALIDATE-TASKS: PASS" || { echo "VALIDATE-TASKS: FAIL"; exit 1; }
