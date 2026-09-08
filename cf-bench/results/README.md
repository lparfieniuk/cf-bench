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
| `bench-20260905-213559.tsv` | js-express-errors-010 | A/B/C | 10 (C: 7) | 2.1.261 |
| `bench-20260906-de.tsv` | js-express-errors-010 | D/E | 10 | 2.1.263 |
| `bench-20260906-081546.tsv` | js-express-errors-010 | A/B/C/D/E | 10 | 2.1.263 |
| `bench-20260908-144052.tsv` | js-express-errors-010 | F only | 10 | 2.1.263 |

Which file backs which headline claim:

| Claim | File |
|---|---|
| encoded-decision flips success: A 0% vs B 100%, N=10 | `bench-20260716-152356.tsv` |
| local lie at scale: A 7% vs B 100%, N=15 | `bench-20260716-091005.tsv` + `bench-20260716-093759.tsv` |
| a lying config inverts the outcome: A 100% vs B 0% | `bench-20260717-224536.tsv` |
| contested convention flips: A 0% vs B 100% | `bench-20260718-091628.tsv` |
| the contested-prior rule's control test: A 40% vs B 100% | `bench-20260718-145720.tsv` |
| canonical conventions are cost-only, not success | `bench-20260718-101708.tsv` |
| a 14b local model's competence boundary: 3/3 on one-bug-with-a-failing-test, 0/3 on conflicting-signal | `local-arm-20260818-230602.tsv` |
| the ContextForge payload costs +15.9% at equal success (E vs A, one CLI version) | `bench-20260906-081546.tsv` |

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
- **The letter D means two different things.** In the 07-22 files D is the ContextForge-core config
  arm, served by `sonnet`; in `local-arm-*.tsv` D is the provider swap of B, served by a local Ollama
  model. Read the `model` column before pooling any D. `js-express-errors-010` carries the old kind
  and deliberately never gained a `PROVIDER_D`.
- **`local-arm-*.tsv` files hold the D arm only.** They come from
  `cf-aios/scripts/local-arm-matrix.sh`, which calls `run-task.sh` directly so that adding a local arm
  to a task cannot schedule a paid one. `PROVIDER_D` in a `.task` file is therefore not in `VARIANTS`.
- **A max-turns run is recorded as invalid, not as a failure.** `run-task.sh` blanks the success column
  for any result JSON carrying `is_error`, and a run that hits `--max-turns` carries it. Two rows in
  `local-arm-20260818-230602.tsv` are genuine failures sitting outside the success rate. Read
  `terminal_reason` alongside `success`.
- **The two 07-22 files include variants C and D**, the placebo and the ContextForge-core arm; earlier
  files are A/B only, so a pooled A count can exceed the per-file N.

## The 2026-09-06 re-measurement of the ContextForge arm (split across two files)

`bench-20260905-213559.tsv` aborted on the circuit breaker after two consecutive `api_error`
rows on C#8/#9, so arms D and E never ran in it. Rather than re-buy A/B/C, the missing arms were
run separately into `bench-20260906-de.tsv`, same task and same fixture, with 10s pacing.

**Do NOT pool these two files.** Claude Code auto-updated between them: A/B/C ran on **2.1.261**,
D/E on **2.1.263**. That is exactly the case this README's own caveat excludes. Only the
within-file comparisons are measurements — C vs A in the first file, E vs D in the second. Every
CF-arm-versus-baseline delta crosses the version boundary and is suggestive at best. A code review
caught this after the run was already recorded as poolable; the correction stands as the reason the
matrix has to be re-run in one invocation. The analysis, with the clean and cross-version rows kept
apart, lives in context-forge's `core/benchmarks/HYPOTHESES.md`, H1.

Variant E (`configs/cf-full`) is new: the payload a consumer repo actually loads
(~1945 tokens) rather than the compressed always-on extract variant D carries (~619 tokens).
It is the user's global `CLAUDE.md` minus the `## Personal Infrastructure` section and the
identity line — 941 characters cut, neither attributable to the plugin.

Two D runs (#4, #7) failed the hidden assertion with `terminal_reason=completed` — the agent
finished early (8 and 9 turns) and got it wrong, on a task where A, B, C and E all scored 100%.
Fisher exact vs A: **p = 0.474**. At N=10 this is a flag to re-test, NOT a finding. It was re-tested
the next morning and got worse — see below.

## The 2026-09-06 clean re-run — `bench-20260906-081546.tsv`

The re-run the block above called mandatory: **all five arms, N=10, one `run-bench.sh` invocation,
`DISABLE_AUTOUPDATER=1` exported for the whole run**. 50 rows, 0 invalid, column 16 holds exactly
one distinct value (`2.1.263`), $5.22. This file supersedes both 2026-09-05/06 files for every
CF-versus-baseline claim; they stay for the record and for the D/E arms pooled below.

| variant | config | tokens | succ | med cost | Δ vs A | p |
|---|---|---|---|---|---|---|
| A | none | 0 | 10/10 | 0.0979 | — | — |
| B | task knowledge | — | 10/10 | 0.0939 | −4.1% | 0.017 |
| C | generic placebo | ~46 | 10/10 | 0.1066 | +8.9% | 0.0013 |
| D | `cf-core` | ~619 | **6/10** | 0.1068 | +9.1% | 0.0046 |
| E | `cf-full` | ~1945 | 10/10 | 0.1134 | **+15.9%** | 0.00018 |

E vs C: +6.4%, p = 0.0028. Turns are 10 in every arm except C (11).

Three things this file settles, and one it does not:

- **The real ContextForge payload costs +15.9% against a bare repo at identical success.** No
  version drift, no cross-file pooling, single invocation.
- **Most of that is not ContextForge.** C vs A is +8.9% — the price of any `CLAUDE.md` existing,
  now replicated three times (+8.2% July, +9.6% on 09-05, +8.9% here). CF's own share is the
  +6.4% of E vs C.
- **Only encoded task knowledge is cheaper than bare** (B, −4.1%, third replication).
- **Not settled: why D fails.** D is 6/10 here and 8/10 in `bench-20260906-de.tsv`; both ran on
  2.1.263, so they pool: **14/20**, against A's 10/10 on the same version, Fisher p = 0.074 —
  directional, not significant. All six failures ended `completed` in 8–10 turns.

Pooling note for D and E: these two files may be pooled with each other (same CLI version, same
task, same configs) and with nothing else. Doing so shows the E-vs-D cost gap is an artefact of D's
failures being cheap — D's 14 *successful* runs cost a median $0.1130 against E's $0.1134,
**+0.4%, p = 0.278**. A 1326-token config difference buys no measurable cost difference.

## The 2026-09-08 variant F run — `bench-20260908-144052.tsv`

A single arm, run with `CFBENCH_VARIANTS="F"` against arms already measured on the SAME CLI version
(2.1.263, checked before and after). That is the only legitimate use of a subset run: comparing a NEW
arm to existing arms on one version. It is NOT permission to top up a missing arm later — that is what
voided the 2026-09-05/06 matrix.

F = `configs/cf-core-plus`: `cf-core` plus rule 005's progressive-disclosure chain and the 015/019
verify-before-concluding mandate, ~908 tokens. It tests whether D's missing substitute and missing
verification are why D loses runs. N=10, 9/10, median $0.1202, 11 turns, $1.24.

- **Success question not settled.** F 9/10 vs D 14/20 is Fisher p = 0.37; `tools/power-analysis.py`
  gives a 70%-vs-100% effect a power of 0.15 at N=10. Directionally right, statistically nothing.
- **Cost question settled, against the fix.** F is the most expensive arm measured: +22.8% vs bare
  (p < 0.001), +9.6% vs D (p = 0.048), indistinguishable from E (+6.0%, p = 0.692). Its nine
  successful runs alone median $0.1181 — still the highest, so the failure is not the cause.
- **Mechanism runs opposite to intent.** F's median `cache_read` is 216,559, the highest of any arm
  and 60% above bare A's 135,587, and its turn median rises to 11. Rules added to make reading
  cheaper made the agent read more.

`bench-20260908-144052.tsv` pools with `bench-20260906-081546.tsv` and `bench-20260906-de.tsv`:
same task, same fixture, same CLI version.
