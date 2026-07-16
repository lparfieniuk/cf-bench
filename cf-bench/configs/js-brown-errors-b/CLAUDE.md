# js-brown — project notes

- Error-handling convention (since 2025 refactor): **new code returns result objects**
  `{ ok: true, value }` / `{ ok: false, error: 'UPPER_SNAKE_CODE' }` — never throw for
  expected failures. `user-service.js` still throws — it's legacy, do NOT imitate it;
  `order-service.js` shows the current style.
- Run `npm test` before finishing.
