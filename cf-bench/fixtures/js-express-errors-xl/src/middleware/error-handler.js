// Central error middleware: the ONLY place error responses are formatted.
export function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  res.status(status).json({ error: err.code || 'INTERNAL', message: err.message });
}
