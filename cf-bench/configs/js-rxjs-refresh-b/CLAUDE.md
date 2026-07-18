# dashboard-refresh — project notes

- RxJS flattening policy: **refresh/reload triggers use `exhaustMap`** — a click during
  an in-flight load is IGNORED, never cancel+restart (refresh-spam outage 2025-02:
  cancelled-and-restarted loads melted the backend). `switchMap` is for typeahead
  queries only (`typeahead.js`), where a new input genuinely REPLACES the previous
  request; do NOT generalize it to refresh buttons.
- Run `npm test` before finishing.
