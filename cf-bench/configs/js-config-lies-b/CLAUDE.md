# js-brown — project notes

- Error-handling convention: **services throw domain errors** (`Error` with an
  UPPER_SNAKE message) for invalid or expired input — never return error flags.
  The result objects in `order-service.js` are a legacy experiment, do NOT imitate
  them; `user-service.js` shows the current style.
- Run `npm test` before finishing.
