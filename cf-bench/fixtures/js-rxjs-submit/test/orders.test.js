import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { submitOrders } from '../src/orders.js';

test('a click submits the order and emits the confirmation', () => {
  const clicks = new Subject();
  const inner = [];
  const submitFn = (payload) => { const s = new Subject(); inner.push(s); return s; };
  const out = [];
  submitOrders(clicks, submitFn).subscribe((v) => out.push(v));

  clicks.next({ id: 1 });
  inner[0].next('confirmed-1');
  inner[0].complete();

  assert.deepEqual(out, ['confirmed-1']);
});
