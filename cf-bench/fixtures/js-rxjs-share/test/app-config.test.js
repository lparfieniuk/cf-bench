import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Observable, Subject } from 'rxjs';
import { appConfig } from '../src/app-config.js';

test('concurrent subscribers share a single fetch', () => {
  let fetches = 0;
  const upstream = new Subject();
  const fetchFn = () => new Observable((sub) => {
    fetches += 1;
    return upstream.subscribe(sub);
  });

  const cfg$ = appConfig(fetchFn);
  const a = [];
  const b = [];
  cfg$.subscribe((v) => a.push(v));
  cfg$.subscribe((v) => b.push(v));

  upstream.next({ theme: 'dark' });
  upstream.complete();

  assert.equal(fetches, 1, 'one fetch for all subscribers');
  assert.deepEqual(a, [{ theme: 'dark' }]);
  assert.deepEqual(b, [{ theme: 'dark' }]);
});
