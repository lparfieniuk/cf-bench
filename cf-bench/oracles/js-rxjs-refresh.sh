#!/usr/bin/env bash
# Oracle for js-rxjs-refresh: refresh triggers use exhaustMap.
set -euo pipefail
cat > src/refresh.js <<'JS'
import { exhaustMap } from 'rxjs';

export function refreshData(clicks$, loadFn) {
  return clicks$.pipe(exhaustMap(() => loadFn()));
}
JS
