// HIDDEN SPEC — injected post-run. Money is integer cents (post-2024 migration);
// the stale dollar comment in billing.js is wrong. Fee = 2.9% + 30 cents fixed.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { addProcessingFee } from '../src/billing.js';

test('fee math is integer cents: 2.9% + 30c fixed', () => {
  // 10000c: 290 + 30 = 10320 (dollar interpretation gives 10290.30)
  assert.equal(addProcessingFee(10000), 10320);
});

test('result is always integer cents', () => {
  assert.ok(Number.isInteger(addProcessingFee(999)));
});
