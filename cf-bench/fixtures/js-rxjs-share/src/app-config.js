// App configuration stream.

// appConfig(fetchFn) -> shared Observable of the app config.
// fetchFn() returns an Observable that performs one config fetch.
// All subscribers share the config; the fetch must not run once per subscriber.
export function appConfig(fetchFn) {
  throw new Error('not implemented');
}
