import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateCoupon } from '../src/coupon-service.js';

test('accepts a valid coupon code', async () => {
  assert.ok(await validateCoupon('WINTER25X'));
});
