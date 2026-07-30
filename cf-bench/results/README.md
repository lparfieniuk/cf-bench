# Raw results

Every number quoted in the project's README and docs comes from these files. Nothing is pruned —
including the runs that refuted a hypothesis and the matrix that aborted on a rate limit.

Aggregate any subset with:

```bash
runner/summarize.sh results/bench-20260716-152356.tsv          # one matrix
runner/summarize.sh results/bench-*.tsv                        # everything
```

Pooling files is only valid when the fixture and CLI version match — see the caveat below the table.

| File | Tasks | Variants | N per arm | CLI |
|---|---|---|---|---|
| `bench-20260716-010439.tsv` | js-dist-vat-003, js-stack-discounts-002, ts-fix-discount-001 | A/B | 5 | not yet recorded |
| `bench-20260716-021328.tsv` | js-dist-vat-003, js-stack-discounts-002, ts-fix-discount-001 | A/B | 4–5 | not yet recorded |
| `bench-20260716-084814.tsv` | js-brown-cents-005, js-brown-errors-004 | A/B | 5 | not yet recorded |
| `bench-20260716-091005.tsv` | js-brown-cents-xl-007, js-brown-errors-xl-006 | A/B | 4–5 | not yet recorded |
| `bench-20260716-093759.tsv` | js-brown-cents-xl-007 | A/B | 10 | not yet recorded |
| `bench-20260716-152356.tsv` | js-stack-discounts-002 | A/B | 10 | not yet recorded |
| `bench-20260717-224536.tsv` | js-config-lies-008 | A/B | 5 | 2.1.212 |
| `bench-20260718-091614.tsv` | — | — | — | aborted before the first row |
| `bench-20260718-091628.tsv` | js-rxjs-submit-009 | A/B | 5 | 2.1.212 |
| `bench-20260718-092011.tsv` | js-express-errors-010 | A/B | 5 | 2.1.212 |
| `bench-20260718-101708.tsv` | js-express-errors-xl-014, js-rxjs-catch-011, js-rxjs-latest-012, js-rxjs-share-013 | A/B | 5 | 2.1.212 |
| `bench-20260718-145720.tsv` | js-rxjs-refresh-015 | A/B | 10–20 | 2.1.212 |
| `bench-20260722-104241.tsv` | js-express-errors-010 | A/B/C/D | 9–10 | 2.1.217 |
| `bench-20260722-161216.tsv` | js-express-errors-xl-014 | A/B/C | 10 | 2.1.217 |

Which file backs which headline claim:

| Claim | File |
|---|---|
| encoded-decision flips success: A 0% vs B 100%, N=10 | `bench-20260716-152356.tsv` |
| local lie at scale: A 7% vs B 100%, N=15 | `bench-20260716-091005.tsv` + `bench-20260716-093759.tsv` |
| a lying config inverts the outcome: A 100% vs B 0% | `bench-20260717-224536.tsv` |
| contested convention flips: A 0% vs B 100% | `bench-20260718-091628.tsv` |
| the contested-prior rule's control test: A 40% vs B 100% | `bench-20260718-145720.tsv` |
| canonical conventions are cost-only, not success | `bench-20260718-101708.tsv` |

## Reading the columns

`success` empty means the run never executed (API error or rate limit). Those rows are deliberately
kept and excluded from aggregates rather than being counted as failures — `summarize.sh` reports how
many it dropped. `cli_version` is recorded because identical model weights score differently across
harness versions; A and B always share one, so deltas hold even when absolute values do not.

## Caveats when pooling

- **Do not pool across CLI versions** unless the point is measuring harness variance. The 07-22 files
  ran on 2.1.217, everything earlier on 2.1.212 or before.
- **Files older than 2026-07-30 predate a fixture change.** The eight library fixtures then carried a
  hand-vendored `node_modules` and a `package.json` declaring no dependencies; dependencies are now
  declared and lockfile-pinned. Both arms shift equally and every task still passes the oracle gate,
  but cell-by-cell comparability with future matrices is not claimed until re-measured.
- **The two 07-22 files include variants C and D**, the placebo and the ContextForge-core arm; earlier
  files are A/B only, so a pooled A count can exceed the per-file N.
