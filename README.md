# cf-bench

**Does your agent config actually do anything?** Everyone ships CLAUDE.md files, cursor rules packs and
skill bundles. Almost nobody measures whether they change outcomes. cf-bench is a small, deliberately
boring harness that answers the question with numbers: same task, same repo, **variant A** (bare) vs
**variant B** (with the config), N repeats, deterministic pass/fail, cost and turns recorded per run.

The published science is genuinely contradictory — an [ETH Zurich study](https://arxiv.org/html/2601.20404v1)
found AGENTS.md cuts wall-clock time by 28% but never measured correctness, while
[another benchmark](https://academy.dair.ai/blog/agents-md-evaluation) found context files add 20%+
inference cost for at best a 4% success bump. Both can be true, because the effect depends on the
specific config. So measure yours.

---

## What it found

Every number below is from the raw TSVs in [`cf-bench/results/`](cf-bench/results/), Claude Code
headless, pinned `sonnet`, isolated from user-level config. `p` = Fisher exact (two-sided) on success,
or Mann-Whitney U on cost where success does not move.

| Task | Class | N (A/B) | A | B | p | Δcost |
|---|---|---|---|---|---|---|
| `js-stack-discounts-002` | encoded-decision | 10/10 | **0%** | **100%** | 1.1e-05 | −20.6% |
| `js-brown-cents-xl-007` | local-lie @ scale | 15/15 | **7%** | **100%** | 2.1e-07 | −11.2% |
| `js-rxjs-submit-009` | library-convention | 5/5 | **0%** | **100%** | 0.008 | −2.5% |
| `js-rxjs-refresh-015` | library-convention | 20/10 | **40%** | **100%** | 0.002 | −4.5% |
| `js-config-lies-008` | config-lies | 5/5 | **100%** | **0%** | 0.008 | −9.8% |
| `js-express-errors-xl-014` | cost-at-scale | 5/5 | 100% | 100% | 0.012 (cost) | **−28.6%**, turns 16→9 |
| `js-brown-errors-xl-006` | cost-at-scale | 4/5 | 100% | 100% | 0.020 (cost) | **−49.8%** |

Four findings worth the money:

1. **A config can be worth the whole task.** On `js-stack-discounts-002` — a discount-stacking policy
   that exists nowhere in the repo — the agent goes 0/10 without it and 10/10 with it. Not a cost
   saving. The difference between shipping and not shipping.
2. **Scale is what makes brownfield hard.** The same conflicting-signal trap (a lying comment in the
   edited file, the truth buried elsewhere) does *nothing* in a 5-file fixture: A passes 100%. Inflate
   the same repo to 120 files and A collapses to 7%. Small-repo benchmarks systematically understate
   the value of context files.
3. **A lying config inverts the outcome, cheaply and confidently.** `js-config-lies-008` gives the
   agent a CLAUDE.md that contradicts the repo. A passes 5/5, B fails 0/5 — and B is 9.8% *cheaper*.
   The agent never once questioned the config despite contradicting evidence in the code. Your config
   is a fully trusted single point of failure; a stale one does not degrade results, it reverses them.
4. **Only contested policy discriminates.** Conventions the model already knows (catchError placement,
   shareReplay for caching) are cost-only no matter how a neighbouring file misleads it — the training
   prior wins. What flips outcomes is a team policy that *diverges from the canon*. Design-time litmus
   test: "would a senior engineer with no company context answer unambiguously?" If yes, writing it
   down buys you speed, not correctness. Three of ten tasks were reclassified after measurement said so.

Total spend on every experiment in this repo so far: roughly **$32**.

---

## How it works

```
tasks/*.task     →  runner/run-task.sh  →  results/bench-*.tsv  →  runner/summarize.sh
  prompt              fresh mktemp dir        one row per run         medians, Wilson CI,
  fixture             fixture copied in       success/cost/turns      Fisher exact, pass^n
  config              agent runs headless
  hidden tests        hidden tests injected
                      check.sh → exit code
```

The design decisions that make the numbers mean something:

- **Isolation.** `--setting-sources project` — the operator's own global plugins and CLAUDE.md never
  enter the run. (Verified: cache_creation dropped 15.0k → 8.7k once cut off.)
- **Pinned model.** `--model` always explicit. Without it the CLI silently picks different models
  between runs and the comparison is worthless.
- **Fresh workdir per run.** Every run gets its own `mktemp -d` with a clean fixture copy. Zero state
  leakage between repeats.
- **Sanity gate.** The fixture's `check.sh` MUST fail before the agent starts. A task that already
  passes measures nothing, and the runner refuses to run it.
- **Hidden assertions.** Visible tests make a task *attemptable* but deliberately underspecify it.
  After the agent stops, the harness injects extra tests encoding the team's spec — the knowledge that
  normally lives in people's heads, which is exactly what a config file exists to capture.
- **Oracle solutions.** Every task ships a reference fix under `oracles/`; `validate-tasks.sh` proves
  the check fails before it and passes after. Terminal-Bench's outcome-validity practice, enforced in
  the smoke test, at zero LLM cost.
- **No LLM judges, anywhere.** Success is an exit code. LLM-judge audits report >50% grading errors;
  that ban is rule 5 of the project and it is not negotiable.
- **Variance is reported, not averaged away.** Wilson 95% CI on pass rates, Fisher exact on the success
  delta, Mann-Whitney U on cost, and `pass^n` (all-repeats reliability, à la tau-bench `pass^k`).
  N<10 is labelled directional, not proof.
- **Placebo arm.** Flagship tasks can run a variant **C** with a generic best-practices config carrying
  zero task knowledge. C≈A proves the B effect is the encoded knowledge rather than the mere presence
  of a CLAUDE.md — the defence against "you wrote the configs yourselves".

Contamination is a non-issue here, unlike SWE-bench: every fixture is synthetic and was never on the
public internet.

## Quickstart

Requirements: bash, python3 (stdlib only), node ≥ 20, and the `claude` CLI logged in. No `npm install`
anywhere — fixture dependencies are vendored.

```bash
# no LLM cost: mocked agent + oracle validation of every task
bash cf-bench/test/smoke.sh

# no LLM cost: prove every task is solvable (check fails before the oracle, passes after)
cf-bench/runner/validate-tasks.sh

# one real run (costs money)
cf-bench/runner/run-task.sh cf-bench/tasks/js-stack-discounts-002.task B 1

# full matrix: tasks × variants × N  (costs money — estimate before starting)
CFBENCH_REPEATS=3 cf-bench/runner/run-bench.sh

# aggregate any set of result files
cf-bench/runner/summarize.sh cf-bench/results/bench-*.tsv

# how large an N do you need to detect a given effect?
python3 cf-bench/tools/power-analysis.py
```

Environment: `CFBENCH_MODEL` (default `sonnet`), `CFBENCH_REPEATS` (default 3),
`CFBENCH_CLAUDE_BIN` (override with a mock for tests).

## Writing a task

A `.task` file is sourced by bash:

```bash
# GAP: "discounts stack additively ... capped at 50%" (configs/js-stack-b/CLAUDE.md)
# HYPOTHESIS: A implements multiplicative stacking (industry default) and/or omits the cap
TASK_ID="js-stack-discounts-002"
PROMPT="Implement stackDiscounts in src/discounts.js so the test suite passes and the implementation follows the project's discount policy. Do not modify the tests."
FIXTURE="js-stack"          # directory under fixtures/
CONFIG="js-stack-b"         # directory under configs/, copied in for variant B
VARIANTS="A B C D"          # optional; default "A B"
CONFIG_C="generic"          # placebo arm
HIDDEN="js-stack-hidden"    # injected after the run, before the final check
MAX_TURNS="12"
ALLOWED_TOOLS="Read,Edit,Write,Glob,Grep,Bash(node:*),Bash(npm:*)"
CHECK="check.sh"            # relative to the fixture; exit 0 = success
```

The full rubric — task classes, calibration bands, anti-patterns, and the lessons from every refuted
hypothesis — is in [`cf-bench/docs/TASK-DESIGN.md`](cf-bench/docs/TASK-DESIGN.md). A task only enters
the set after N≥5 calibration lands inside its class band; otherwise it is redesigned or reclassified.

## Repo layout

| Path | What |
|---|---|
| `cf-bench/runner/` | the whole harness: 4 bash scripts, ~250 lines |
| `cf-bench/tasks/` | task definitions (`retired/` holds ones measurement killed) |
| `cf-bench/fixtures/` | synthetic repos, dependencies vendored |
| `cf-bench/fixtures-hidden/` | assertions injected after the agent run |
| `cf-bench/configs/` | the CLAUDE.md files under test, plus `generic/` (placebo) and `cf-core/` |
| `cf-bench/oracles/` | reference solutions, kept outside `fixtures/` so agents never see them |
| `cf-bench/results/` | every raw TSV ever produced — never pruned |
| `cf-bench/tools/` | power analysis, noise generation for XL fixtures |
| `docs/` | roadmap, research reports, article draft |
| `research-routine/` | a weekly scan of the eval/benchmark landscape, run headless via launchd |
| `context-forge-suggestions/` | fixes for a separate plugin, found while building this |

## Limitations, honestly

- **One agent so far.** Claude Code headless. Codex CLI and Cursor CLI adapters are the obvious next
  step and the real differentiator — harness variance is precisely what other benchmarks fail to control.
- **N is small on most cells.** N=5 detects a full flip (power ≈ 1.00) but is nearly blind to a
  40-point difference (power ≈ 0.09). Run `power-analysis.py` before believing a modest delta. The
  flagships are at N=10–15; everything else is directional.
- **Absolute values drift with the CLI version.** The `cli_version` column exists for exactly this
  reason. A and B always share a version, so the delta stays meaningful; the absolute numbers do not
  travel between releases.
- **Synthetic fixtures are not your codebase.** They are contamination-proof and deterministic, which
  real repos are not. That trade is deliberate, and it is a trade.
- **OAuth auth forces a user-level configuration in the background** (`--bare` needs an API key). Runs
  also share session limits with interactive work; a mid-matrix 429 trips the circuit breaker, and
  those rows are recorded as `api_error` and excluded from aggregates rather than counted as failures.

## License

MIT — see [LICENSE](LICENSE). Fixture dependencies under `cf-bench/fixtures/*/node_modules/` are
vendored third-party packages (MIT / Apache-2.0 / 0BSD / BSD), each retaining its own license file;
the MIT grant here covers only the code in this repository.
