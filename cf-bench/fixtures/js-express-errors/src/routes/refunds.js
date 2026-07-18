import { Router } from 'express';

export const refundsRouter = Router();

// TODO: POST / — create a refund (see task).
export async function createRefundHandler(req, res, next) {
  throw new Error('not implemented');
}

refundsRouter.post('/', createRefundHandler);
