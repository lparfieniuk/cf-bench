// HIDDEN SPEC — injected post-run. Team convention: new code returns result
// objects for expected failures and never throws for them.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateCoupon } from '../src/coupon-service.js';

test('convention: expected failures return {ok:false}, never throw', async () => {
  const res = await validateCoupon('nope');
  assert.equal(res.ok, false);
});

test('convention: expired coupon is an expected failure, not an exception', async () => {
  const res = await validateCoupon('SUMMER24X');
  assert.equal(res.ok, false);
});

test('convention: success is a result object', async () => {
  const res = await validateCoupon('WINTER25X');
  assert.equal(res.ok, true);
});
