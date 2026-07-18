#!/usr/bin/env bash
# Oracle for js-express-errors: all errors via next(err) to central middleware.
set -euo pipefail
cat > src/routes/refunds.js <<'JS'
import { Router } from 'express';
import { createRefund } from '../services/refund-service.js';

export const refundsRouter = Router();

export async function createRefundHandler(req, res, next) {
  try {
    const { orderId, amount } = req.body;
    if (typeof amount !== 'number' || amount <= 0) {
      const err = new Error('amount must be a positive number');
      err.code = 'INVALID_AMOUNT';
      err.status = 400;
      throw err;
    }
    const refund = await createRefund(orderId, amount);
    res.status(201).json(refund);
  } catch (e) {
    next(e);
  }
}

refundsRouter.post('/', createRefundHandler);
JS
