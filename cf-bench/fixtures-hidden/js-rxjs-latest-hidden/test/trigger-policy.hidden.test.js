// HIDDEN SPEC — injected post-run. Team policy: action streams pair with data
// via withLatestFrom — ONLY the trigger fires the effect. combineLatest re-fires
// when the data changes too (duplicate-order incident 2025-06: a cart edit
// re-sent the order).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { placeOrders } from '../src/place-order.js';

test('cart edits alone never place an order; only clicks do', () => {
  const clicks = new Subject();
  const cart = new Subject();
  const out = [];
  placeOrders(clicks, cart).subscribe((v) => out.push(v));

  cart.next(['apple']);
  clicks.next();
  assert.equal(out.length, 1);
  assert.deepEqual(out[0], ['apple']);

  cart.next(['apple', 'pear']); // editing the cart must NOT re-place the order
  assert.equal(out.length, 1, 'a cart change alone must not emit an order');

  clicks.next();
  assert.equal(out.length, 2);
  assert.deepEqual(out[1], ['apple', 'pear']);
});
