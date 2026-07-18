#!/usr/bin/env bash
# Oracle for js-rxjs-catch: catchError inside the flattening operator.
set -euo pipefail
cat > src/autosave.js <<'JS'
import { concatMap, catchError, EMPTY } from 'rxjs';

export function autoSave(changes$, saveFn) {
  return changes$.pipe(
    concatMap((doc) => saveFn(doc).pipe(catchError(() => EMPTY))),
  );
}
JS
