# checkout-effects — project notes

- RxJS pairing policy: **action/trigger streams read companion data with
  `withLatestFrom`** — the trigger ALONE decides when the effect fires:
  `clicks$.pipe(withLatestFrom(cart$), map(([, cart]) => cart))`. `combineLatest`
  re-fires the effect when the data changes too (duplicate-order incident 2025-06:
  a cart edit re-sent the order). `combineLatest` is for live views only
  (`summary.js`); never pair it with an action stream.
- Run `npm test` before finishing.
