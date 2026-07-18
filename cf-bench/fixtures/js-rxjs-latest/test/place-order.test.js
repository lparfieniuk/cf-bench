import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Subject } from 'rxjs';
import { placeOrders } from '../src/place-order.js';

test('a click places an order with the current cart', () => {
  const clicks = new Subject();
  const cart = new Subject();
  const out = [];
  placeOrders(clicks, cart).subscribe((v) => out.push(v));

  cart.next(['apple']);
  clicks.next();

  assert.deepEqual(out, [['apple']]);
});
