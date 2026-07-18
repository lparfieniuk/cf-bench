#!/usr/bin/env bash
# Oracle for js-rxjs-latest: trigger drives the effect via withLatestFrom.
set -euo pipefail
cat > src/place-order.js <<'JS'
import { withLatestFrom, map } from 'rxjs';

export function placeOrders(clicks$, cart$) {
  return clicks$.pipe(
    withLatestFrom(cart$),
    map(([, cart]) => cart),
  );
}
JS
