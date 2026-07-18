# payments-api — project notes

- Error convention: route handlers **never format error responses** — every error
  (validation failures included) is passed to `next(err)` and formatted ONLY by the
  central middleware (`src/middleware/error-handler.js`). Set `err.status`/`err.code`
  on validation errors. `users.js` predates this convention — legacy, do NOT imitate it.
- Run `npm test` before finishing.
