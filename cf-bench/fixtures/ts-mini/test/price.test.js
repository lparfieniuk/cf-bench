import { test } from 'node:test';
import assert from 'node:assert/strict';
import { applyDiscount, formatPrice } from '../src/price.js';

test('applyDiscount treats percent as 0-100 value', () => {
  assert.equal(applyDiscount(200, 10), 180);
  assert.equal(applyDiscount(100, 0), 100);
  assert.equal(applyDiscount(50, 100), 0);
});

test('formatPrice renders two decimals', () => {
  assert.equal(formatPrice(180), '$180.00');
});
