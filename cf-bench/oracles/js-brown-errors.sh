#!/usr/bin/env bash
# Oracle for js-brown-errors(-xl): result-object convention, never throw for
# expected failures; SUMMER24X expired.
set -euo pipefail
cat > src/coupon-service.js <<'JS'
export async function validateCoupon(code) {
  if (!/^[A-Z0-9]{9}$/.test(code)) return { ok: false, error: 'INVALID_CODE' };
  if (code === 'SUMMER24X') return { ok: false, error: 'EXPIRED' };
  return { ok: true, value: { code } };
}
JS
