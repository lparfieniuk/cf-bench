import { test } from 'node:test';
import assert from 'node:assert/strict';
import { addProcessingFee } from '../src/billing.js';

test('processing fee increases the amount', () => {
  assert.ok(addProcessingFee(10000) > 10000);
});
