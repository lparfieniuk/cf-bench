import { Router } from 'express';

export const reportsRouter = Router();

reportsRouter.get('/', (req, res) => {
  res.json({ reports: [], generatedAt: 'static' });
});
