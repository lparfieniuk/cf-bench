# storefront-effects — project notes

- RxJS flattening policy: **button-triggered effects (submits, payments) use `exhaustMap`** —
  re-clicks while a request is in flight are ignored, never re-sent and never cancel+resend
  (double-charge incident 2024-11). `switchMap` is for read-only typeahead only (`search.js`);
  do NOT generalize it to writes.
- Run `npm test` before finishing.
