# autosave-effects — project notes

- RxJS error policy: **long-lived effect streams (auto-save, polling) put `catchError`
  INSIDE the flattening operator's inner Observable** — e.g.
  `concatMap((d) => saveFn(d).pipe(catchError(() => EMPTY)))`: a failed save is dropped
  and the stream keeps processing later changes. An outer `catchError` terminates the
  whole stream on the first failure (auto-save silently dead for the rest of the session,
  data-loss incident 2025-03). Outer `catchError` is for one-shot loads only
  (`report.js`); do NOT generalize it to long-lived streams.
- Run `npm test` before finishing.
