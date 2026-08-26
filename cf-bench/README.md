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
| `cost_usd`, `turns` | `total_cost_usd`, `num_turns` from the result JSON. **`turns` is not comparable across engines**: claude reports the CLI's own turn accounting, opencode's arm counts `step-finish` parts. Compare turns within an engine only |
| `duration_ms` | wall clock around the engine call, both engines. opencode's event timestamps start after server boot, config load and model load into VRAM, so a cold-start local run measured the same as a warm one. **Breaks with history**: rows written before 2026-08-26 carry the claude CLI's self-reported duration instead — do not compare a `duration_ms` across that boundary |
| `in_tokens`, `cache_creation`, `cache_read`, `out_tokens` | `usage.*` |
| `terminal_reason`, `session_id` | diagnostics / transcript audit |
| `cli_version` | the engine binary's `--version` — reproducibility (harness variance) |

## Methodology

- **Isolation**: `--setting-sources project` — the user's global plugins and CLAUDE.md do NOT enter
  the run (verified: cache_creation 15.0k → 8.7k once cut off). Variant A = bare fixture;
  variant B = fixture + contents of `configs/<task-config>/`.
  On the opencode arm the equivalent is `OPENCODE_DISABLE_PROJECT_CONFIG=1` plus an explicit
  `OPENCODE_CONFIG`, which stops the walk-up that otherwise pulls the operator's `.opencode`
  directories, AGENTS.md files and skills into every run. That same flag hides the workdir's own
  AGENTS.md, so the generated config pins it back as an **absolute** `instructions` path — a
  relative one globs the operator's config directory instead (verified against opencode 1.18.21).
  Known gap, not yet closed: the global `~/.config/opencode/opencode.json(c)` is still merged. It
  loads *before* `OPENCODE_CONFIG`, so the generated file wins every shared key, but a global MCP
  server or plugin would still enter the run. Redirecting `XDG_CONFIG_HOME` closes it, but a fresh
  config directory makes opencode npm-install its own plugin dependencies into it on first use —
  observed as a multi-minute stall mid-run. Closing this gap therefore needs a bench-owned config
  directory provisioned once, offline thereafter; not done yet.
- **Pinned model**: `--model` always explicit (`CFBENCH_MODEL`, default `sonnet`) — without it the
  CLI can pick different models between runs.
- **Fresh workdir**: every run in a `mktemp -d`, fixture copied in, cleaned up afterwards. Zero state leakage.
- **Offline runs**: fixture dependencies are pinned to exact versions and installed once by
  `runner/setup-fixtures.sh` (`npm ci` from a committed lockfile). A run that finds no `node_modules`
  is rejected before it costs anything.
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
- Two engines (Claude Code headless, opencode); Codex / Cursor CLI are on the roadmap (cross-agent is the edge).

## Usage

```bash
# once, before anything else — install fixture dependencies:
runner/setup-fixtures.sh

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

## Engines and providers

Two axes, independent of each other. The engine is the CLI under test; the provider is
who serves the tokens.

```bash
# engine: claude (default) or opencode
CFBENCH_AGENT=opencode CFBENCH_OPENCODE_MODEL=anthropic/claude-sonnet-4-5 runner/run-bench.sh

# provider swap: declared per variant in the .task file
#   VARIANTS="A B D"
#   PROVIDER_D="ollama:cfaios-qwen3-14b-32k"
# an exported PROVIDER_D overrides the task file (env beats file, as everywhere here)
```

Parity between the engines is enforced by the runner, not by the operator:

| knob | claude | opencode |
|---|---|---|
| model | `--model` (alias or ollama tag) | `-m provider/model` |
| turn ceiling | `--max-turns $MAX_TURNS` | `agent.build.steps` in a generated `opencode.json` |
| tool allowlist | `--allowedTools $ALLOWED_TOOLS` | `permission` in that same file, as `{"*": "deny"}` **first** and the grants after it. Order is load-bearing: opencode resolves with `findLast` and strips any tool whose last matching rule is a wildcard deny, so a trailing catch-all deleted `bash` from the toolset outright. Residual asymmetry: opencode's `edit` key also ungates `write` and `apply_patch` |
| isolation | `--setting-sources project` | `OPENCODE_DISABLE_PROJECT_CONFIG=1` + `OPENCODE_CONFIG` + an absolute `instructions` path (see Methodology) |
| context window | the model's own | `provider.<p>.models.<tag>.limit` = the `num_ctx` from the preflight. A custom model without it gets `limit.context = 0`, which switches auto-compaction off |
| ollama route | `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` | `provider.ollama.options.baseURL` (opencode ignores the `ANTHROPIC_*` vars) |

Prerequisite for the opencode + ollama arm, once per machine:

```bash
cd ~/.config/opencode && npm install @ai-sdk/openai-compatible
```

Without it opencode tries to install the provider package during the run — that needs
the network the benchmark forbids, and it hangs with no output rather than failing.

## Task structure

`tasks/*.task` — a file sourced by bash, keys:
`TASK_ID`, `PROMPT`, `FIXTURE` (directory under `fixtures/`), `CONFIG` (directory under `configs/`
for variant B), `MAX_TURNS`, `ALLOWED_TOOLS`, `CHECK` (script relative to the fixture, exit 0 = success).
