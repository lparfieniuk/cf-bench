import { Router } from 'express';

export const sessionsRouter = Router();

sessionsRouter.get('/', (req, res) => {
  res.json({ active: 0 });
});
