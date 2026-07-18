import { errorHandler } from '../middleware/error-handler.js';

// Final pipeline stages, mounted after every router.
export function finalizePipeline(app) {
  app.use((req, res) => res.status(404).json({ error: 'NOT_FOUND' }));
  app.use(errorHandler);
}
