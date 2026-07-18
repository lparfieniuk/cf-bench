// HIDDEN SPEC — injected post-run. Team policy: button-triggered effects use
// exhaustMap — re-clicks while a request is in flight are IGNORED (double-charge
// incident 2024-11). switchMap (cancel+resend), mergeMap and concatMap all
// submit twice and violate the policy.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { submitOrders } from '../src/orders.js';

test('re-click while in flight is ignored, not re-submitted', () => {
  const clicks = new Subject();
  const calls = [];
  const inner = [];
  const submitFn = (payload) => { calls.push(payload); const s = new Subject(); inner.push(s); return s; };
  const out = [];
  submitOrders(clicks, submitFn).subscribe((v) => out.push(v));

  clicks.next({ id: 1 });
  clicks.next({ id: 2 }); // double-click while #1 in flight
  assert.equal(calls.length, 1, 'in-flight re-click must not call submitFn');
  assert.equal(calls[0].id, 1);

  inner[0].next('confirmed-1');
  inner[0].complete();

  clicks.next({ id: 3 }); // after completion — allowed again
  assert.equal(calls.length, 2);
  assert.deepEqual(calls.map((c) => c.id), [1, 3]);

  inner[1].next('confirmed-3');
  inner[1].complete();
  assert.deepEqual(out, ['confirmed-1', 'confirmed-3']);
});
