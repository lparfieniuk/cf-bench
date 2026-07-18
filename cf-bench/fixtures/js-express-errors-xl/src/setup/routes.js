import { usersRouter } from '../routes/users.js';
import { refundsRouter } from '../routes/refunds.js';
import { statusRouter } from '../routes/status.js';
import { catalogRouter } from '../routes/catalog.js';
import { reportsRouter } from '../routes/reports.js';
import { sessionsRouter } from '../routes/sessions.js';
import { webhooksRouter } from '../routes/webhooks.js';
import { feedsRouter } from '../routes/feeds.js';

export function mountRoutes(app) {
  app.use('/status', statusRouter);
  app.use('/users', usersRouter);
  app.use('/catalog', catalogRouter);
  app.use('/refunds', refundsRouter);
  app.use('/reports', reportsRouter);
  app.use('/sessions', sessionsRouter);
  app.use('/webhooks', webhooksRouter);
  app.use('/feeds', feedsRouter);
}
