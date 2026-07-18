# config-cache — project notes

- RxJS multicast policy: **cached singleton streams (app config, feature flags) use
  `shareReplay(1)`** — late subscribers must receive the cached value and the upstream
  fetch must run at most once. `share()` is for live event buses only (`bus.js`): it
  replays nothing and RE-SUBSCRIBES a completed source, so every late subscriber
  triggers another fetch (config re-fetch storm, incident 2025-01). Never use `share()`
  for cacheable data.
- Run `npm test` before finishing.
