#!/usr/bin/env bash
# Oracle for js-rxjs-submit: policy = exhaustMap (ignore re-clicks in flight).
set -euo pipefail
cat > src/orders.js <<'JS'
import { exhaustMap } from 'rxjs';

export function submitOrders(clicks$, submitFn) {
  return clicks$.pipe(exhaustMap(submitFn));
}
JS
