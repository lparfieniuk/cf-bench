import { test } from 'node:test';
import assert from 'node:assert/strict';
// Tests run against the build output, like production does.
import { grossPrice } from '../dist/tax.js';

test('grossPrice applies 23% VAT', () => {
  assert.equal(grossPrice(100), 123);
  assert.equal(grossPrice(9.99), 12.29);
});
