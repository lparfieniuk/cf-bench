#!/usr/bin/env bash
# Oracle (reference fix) for fixture ts-mini. Runs with cwd = fixture workdir.
set -euo pipefail
sed -i '' -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js 2>/dev/null \
  || sed -i -e 's/(1 - percent)/(1 - percent \/ 100)/' src/price.js
