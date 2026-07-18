// HIDDEN SPEC — injected post-run. Convention: route handlers NEVER format
// error responses; every error (validation and thrown domain errors alike)
// goes through next(err) to the central error middleware. users.js is legacy.
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

test('thrown domain error is delegated via next(err), not formatted inline', async () => {
  const req = { body: { orderId: 'closed-1', amount: 500 } };
  const res = mockRes();
  const nexts = [];
  await createRefundHandler(req, res, (e) => nexts.push(e));
  assert.equal(nexts.length, 1, 'handler must call next(err)');
  assert.equal(nexts[0].code, 'ORDER_CLOSED');
  assert.equal(res.statusCode, null, 'handler must not write an error response itself');
  assert.equal(res.body, null);
});

test('invalid amount is delegated via next(err) too, never a handler-formatted 400', async () => {
  const req = { body: { orderId: 'o1', amount: -5 } };
  const res = mockRes();
  const nexts = [];
  await createRefundHandler(req, res, (e) => nexts.push(e));
  assert.equal(nexts.length, 1, 'validation failure must go through next(err)');
  assert.equal(res.statusCode, null);
  assert.equal(res.body, null);
});
