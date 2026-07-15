# js-dist — project notes

- `dist/` is **generated** from `src/` by `npm run build` — never edit `dist/` directly;
  CI rebuilds before running tests, so direct dist edits are silently wiped.
- Workflow: edit `src/` → `npm run build` → `npm test`.
- Polish VAT is 23%.
