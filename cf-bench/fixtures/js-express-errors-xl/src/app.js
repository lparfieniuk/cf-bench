import express from 'express';
import { mountRoutes } from './setup/routes.js';
import { finalizePipeline } from './setup/pipeline.js';

export function createApp() {
  const app = express();
  app.use(express.json());
  mountRoutes(app);
  finalizePipeline(app);
  return app;
}
