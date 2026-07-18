import { Router } from 'express';

export const statusRouter = Router();

statusRouter.get('/', (req, res) => {
  res.json({ ok: true, uptime: 1234 });
});
