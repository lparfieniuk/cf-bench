import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { refreshData } from '../src/refresh.js';

test('a refresh click loads and emits the dashboard data', () => {
  const clicks = new Subject();
  const inner = [];
  const loadFn = () => { const s = new Subject(); inner.push(s); return s; };
  const out = [];
  refreshData(clicks, loadFn).subscribe((v) => out.push(v));

  clicks.next();
  inner[0].next({ widgets: 3 });
  inner[0].complete();

  assert.deepEqual(out, [{ widgets: 3 }]);
});
