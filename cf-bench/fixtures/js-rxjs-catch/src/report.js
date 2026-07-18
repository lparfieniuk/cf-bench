import { map, catchError, of } from 'rxjs';

const EMPTY_REPORT = { rows: [], failed: true };

// One-shot report load: on any failure fall back to an empty report.
export function loadReport(fetch$) {
  return fetch$.pipe(
    map((raw) => ({ rows: raw.rows, failed: false })),
    catchError(() => of(EMPTY_REPORT)),
  );
}
