#!/usr/bin/env bash
# Oracle for js-rxjs-share: cached singleton via shareReplay(1).
set -euo pipefail
cat > src/app-config.js <<'JS'
import { defer, shareReplay } from 'rxjs';

export function appConfig(fetchFn) {
  return defer(fetchFn).pipe(shareReplay(1));
}
JS
