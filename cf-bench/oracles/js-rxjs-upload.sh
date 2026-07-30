#!/usr/bin/env bash
# Oracle for js-rxjs-upload: strictly serial uploads via concatMap.
set -euo pipefail
cat > src/uploads.js <<'JS'
import { concatMap } from 'rxjs';

export function uploadQueue(files$, uploadFn) {
  return files$.pipe(concatMap(uploadFn));
}
JS
