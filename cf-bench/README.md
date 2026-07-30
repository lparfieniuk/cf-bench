# cf-bench

Measures whether a coding agent's config (CLAUDE.md / skills / MCP) actually improves outcomes —
instead of taking its word for it. A/B: same task, variant **A** (no config) vs **B** (with config),
N repeats, metrics from the hard JSON emitted by `claude -p`. Optional variant **C** (placebo):
`VARIANTS="A B C"` + `CONFIG_C="generic"` in the `.task` — a generic config with no task knowledge;
the expected C≈A proves the B effect is the encoded knowledge, not the mere presence of a CLAUDE.md.

## Metrics (per run)

| Column | Source |
|---|---|
| `success` | the fixture's `check.sh` (exit 0) — a deterministic assertion, not an LLM judge |
| `cost_usd`, `turns`, `duration_ms` | `total_cost_usd`, `num_turns`, `duration_ms` from the result JSON |
| `in_tokens`, `cache_creation`, `cache_read`, `out_tokens` | `usage.*` |
| `terminal_reason`, `session_id` | diagnostics / transcript audit |
| `cli_version` | `claude --version` — reproducibility (harness variance) |

## Methodology

- **Isolation**: `--setting-sources project` — the user's global plugins and CLAUDE.md do NOT enter
  the run (verified: cache_creation 15.0k → 8.7k once cut off). Variant A = bare fixture;
  variant B = fixture + contents of `configs/<task-config>/`.
- **Pinned model**: `--model` always explicit (`CFBENCH_MODEL`, default `sonnet`) — without it the
  CLI can pick different models between runs.
- **Fresh workdir**: every run in a `mktemp -d`, fixture copied in, cleaned up afterwards. Zero state leakage.
- **Sanity gate**: before the run `check.sh` MUST fail (the fixture really is broken), otherwise the
  run is rejected.
- **N repeats** (default 3): LLM variance is high; we report medians, not single runs.
- **Statistics** (in `summarize.sh`): Wilson 95% CI on the pass rate, Fisher exact (two-sided) on the
  B-vs-A success delta, Mann-Whitney U on cost/turns, `pass^n` = 1 when all n runs passed
  (reliability à la tau-bench pass^k — variance is signal, not noise).
- **Outcome validity** (Terminal-Bench practice): every task has an oracle solution (`oracles/`),
  and `runner/validate-tasks.sh` proves solvability; enforced in `smoke.sh`.
- **Rigor**: no LLM judges anywhere in the scoring loop; success = the fixture's tests pass.
  (Validated against the 2026 literature: LLM-judge audits report >50% grading errors.)

## Known limitations (honestly)

- OAuth auth forces a user-level configuration in the background (`--bare` requires an API key) — the
  model/harness version is shared by A and B, so the delta stays meaningful, but absolute values
  depend on the CLI version.
- N=3 only detects large effects; a published leaderboard needs N≥10 plus confidence intervals.
- One agent so far (Claude Code headless); Codex / Cursor CLI are on the roadmap (cross-agent is the edge).

## Usage

```bash
# single run (debug):
runner/run-task.sh tasks/ts-fix-discount-001.task B 1

# full matrix (tasks × A/B × N):
CFBENCH_REPEATS=3 runner/run-bench.sh            # → results/bench-YYYYMMDD-HHMMSS.tsv

# aggregation:
runner/summarize.sh results/bench-*.tsv          # medians, Wilson 95% CI, pass^n, Fisher p, B-vs-A delta

# task validation via oracle solutions (zero LLM cost):
runner/validate-tasks.sh                         # per task: check fails before the oracle, passes after

# smoke test with no LLM cost (mock claude + validate-tasks):
test/smoke.sh
```

## Task structure

`tasks/*.task` — a file sourced by bash, keys:
`TASK_ID`, `PROMPT`, `FIXTURE` (directory under `fixtures/`), `CONFIG` (directory under `configs/`
for variant B), `MAX_TURNS`, `ALLOWED_TOOLS`, `CHECK` (script relative to the fixture, exit 0 = success).
