import { Router } from 'express';

export const webhooksRouter = Router();

webhooksRouter.get('/', (req, res) => {
  res.json({ registered: [] });
});
