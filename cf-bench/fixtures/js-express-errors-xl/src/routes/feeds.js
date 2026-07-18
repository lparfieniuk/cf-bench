import { Router } from 'express';

export const feedsRouter = Router();

feedsRouter.get('/', (req, res) => {
  res.json({ feeds: [], cursor: null });
});
