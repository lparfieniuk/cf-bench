// HIDDEN SPEC — injected post-run. Team policy: refresh/reload triggers use
// exhaustMap — a click during an in-flight load is IGNORED: it must not cancel
// and restart the load (switchMap), start a parallel load (mergeMap) or queue
// a redundant one (concatMap). Refresh-spam outage 2025-02.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { refreshData } from '../src/refresh.js';

test('a click during an in-flight load is ignored, not cancelled/queued/parallel', () => {
  const clicks = new Subject();
  let loads = 0;
  const inner = [];
  const loadFn = () => { loads += 1; const s = new Subject(); inner.push(s); return s; };
  const out = [];
  refreshData(clicks, loadFn).subscribe((v) => out.push(v));

  clicks.next();
  clicks.next(); // spam click while the first load is in flight
  assert.equal(loads, 1, 'in-flight refresh must not start or restart a load');

  inner[0].next({ widgets: 3 });
  inner[0].complete();
  assert.equal(loads, 1, 'the spam click must not have queued a second load');
  assert.deepEqual(out, [{ widgets: 3 }]);

  clicks.next(); // after completion — a new refresh is allowed
  assert.equal(loads, 2);
  inner[1].next({ widgets: 4 });
  inner[1].complete();
  assert.deepEqual(out, [{ widgets: 3 }, { widgets: 4 }]);
});
