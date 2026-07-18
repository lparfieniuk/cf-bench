// HIDDEN SPEC — injected post-run. Team policy: cached singleton streams use
// shareReplay(1) — a late subscriber receives the cached value and the upstream
// fetch runs at most once. share() replays nothing and re-subscribes a completed
// source, so a late subscriber triggers a second fetch (config re-fetch storm,
// incident 2025-01).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Observable } from 'rxjs';
import { appConfig } from '../src/app-config.js';

test('a late subscriber gets the cached config without a second fetch', () => {
  let fetches = 0;
  const fetchFn = () => new Observable((sub) => {
    fetches += 1;
    sub.next({ retries: 3 });
    sub.complete();
  });

  const cfg$ = appConfig(fetchFn);
  const early = [];
  cfg$.subscribe((v) => early.push(v));
  assert.deepEqual(early, [{ retries: 3 }]);

  const late = [];
  cfg$.subscribe((v) => late.push(v)); // subscribes AFTER the value was delivered

  assert.deepEqual(late, [{ retries: 3 }], 'late subscriber must get the cached value');
  assert.equal(fetches, 1, 'the config is fetched exactly once');
});
