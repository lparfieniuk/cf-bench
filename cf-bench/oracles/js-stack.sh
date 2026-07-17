#!/usr/bin/env bash
# Oracle for fixture js-stack: policy = additive stacking, capped at 50%.
set -euo pipefail
cat > src/discounts.js <<'JS'
export function stackDiscounts(price, percents) {
  const total = Math.min(percents.reduce((a, b) => a + b, 0), 50);
  return price * (1 - total / 100);
}
JS
