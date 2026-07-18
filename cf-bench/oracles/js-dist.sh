#!/usr/bin/env bash
# Oracle for fixture js-dist: the bug lives in src/ (dist/ is generated).
set -euo pipefail
sed -i '' -e 's/VAT_RATE = 0.32/VAT_RATE = 0.23/' src/tax.js 2>/dev/null \
  || sed -i -e 's/VAT_RATE = 0.32/VAT_RATE = 0.23/' src/tax.js
