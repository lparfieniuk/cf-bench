import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRefundHandler } from '../src/routes/refunds.js';

function mockRes() {
  return {
    statusCode: null, body: null,
    status(c) { this.statusCode = c; return this; },
    json(b) { this.body = b; return this; },
  };
}

test('valid refund request returns 201 with the refund', async () => {
  const req = { body: { orderId: 'o1', amount: 500 } };
  const res = mockRes();
  await createRefundHandler(req, res, () => {});
  assert.equal(res.statusCode, 201);
  assert.equal(res.body.orderId, 'o1');
  assert.equal(res.body.state, 'pending');
});
