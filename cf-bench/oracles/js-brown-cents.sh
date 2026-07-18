#!/usr/bin/env bash
# Oracle for js-brown-cents(-xl): money is integer cents; fee = 2.9% + 30c fixed.
set -euo pipefail
cat >> src/billing.js <<'JS'

export function addProcessingFee(amount) {
  return amount + Math.round(amount * 0.029) + 30;
}
JS
