# js-brown — project notes

- **All money values are integer cents** (migration finished 2024). Some modules still carry
  stale "amounts are dollars" comments — they are wrong, trust the code (`formatAmount`
  divides by 100), not the comments.
- Payment processing fee: 2.9% + 30 cents fixed, result rounded to integer cents.
- Run `npm test` before finishing.
