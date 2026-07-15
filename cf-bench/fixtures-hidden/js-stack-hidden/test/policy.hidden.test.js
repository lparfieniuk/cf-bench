// HIDDEN SPEC — injected post-run. Encodes the project's discount policy:
// discounts stack ADDITIVELY and the total discount is CAPPED at 50%.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { stackDiscounts } from '../src/discounts.js';

test('policy: discounts stack additively', () => {
  // additive: 10% + 20% = 30% off -> 70 (multiplicative would give 72)
  assert.equal(stackDiscounts(100, [10, 20]), 70);
});

test('policy: total discount capped at 50%', () => {
  // 30+30+30 = 90% -> capped to 50% -> 50
  assert.equal(stackDiscounts(100, [30, 30, 30]), 50);
});
