#!/usr/bin/env bash
# Install fixture dependencies once, before any benchmark run.
# Runs are offline by design (hard rule 3: no npm install inside a run), so every
# fixture with a lockfile gets `npm ci` here and the resulting node_modules is
# copied into the run's workdir untouched.
# Idempotent: re-running is cheap and safe.
set -euo pipefail

BENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

for LOCK in "$BENCH_ROOT"/fixtures/*/package-lock.json; do
  DIR="$(dirname "$LOCK")"
  NAME="$(basename "$DIR")"
  printf '%-24s ' "$NAME"
  if (cd "$DIR" && npm ci --omit=dev --no-audit --no-fund >/dev/null 2>&1); then
    echo "ok ($(du -sh "$DIR/node_modules" | cut -f1))"
  else
    echo "FAILED"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo "setup-fixtures: at least one install failed — benchmark runs will be rejected" >&2
  exit 1
fi
echo "setup-fixtures: done"
