import { test } from 'node:test';
import assert from 'node:assert/strict';
import { stackDiscounts } from '../src/discounts.js';

test('single discount', () => {
  assert.equal(stackDiscounts(100, [10]), 90);
});

test('no discounts', () => {
  assert.equal(stackDiscounts(100, []), 100);
});
