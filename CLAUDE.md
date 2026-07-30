# ai-tools — cf-bench

**cf-bench**: a benchmark that measures whether a coding agent's config (CLAUDE.md/skills/MCP)
actually works. Thesis: **we do not sell rules — we sell proof that a config works (or does not)**.
Target model: a free OSS harness → leaderboard → paid regression-watch + audits.
Stage: Phase 0 (the measurement foundation).

## Hard rules

1. **Metrics-first**: no rule, feature, or claim lands without a measurement. Anything doubtful → `[unverified]`.
2. **Credibility > code**: the moat is the methodology + the task set + the data history. The runner code is deliberately trivial.
3. **No dependencies without approval**: runner = bash + python3 stdlib; fixtures = node:test with no npm install. Do not add frameworks.
4. **Local-first, stateless, flat files** (TSV/YAML/md). No databases, no servers, no cloud — hosted only after the first paying customer.
5. **Deterministic scoring**: success = the fixture's check.sh (exit 0). NEVER an LLM-as-judge in the scoring loop.
6. **Benchmark rigor**: isolation via `--setting-sources project`, pinned `--model`, a fresh mktemp workdir, a sanity gate (the check must fail before the run), N repeats, medians reported. N<10 is directional, not proof.

## Repo conventions

- This project is ONLY the benchmark. Improvements to the context-forge plugin go into numbered
  suggestions under `context-forge-suggestions/` (implemented separately in that plugin's own repo).
- Research: reports under `docs/research/`; the weekly scan lives in `research-routine/`; scan reports
  land in `research-reports/` (gitignored).
- Benchmark results: `cf-bench/results/*.tsv` — never delete these, they are the future data moat.
- After changing the runner: `bash cf-bench/test/smoke.sh` (mocked, zero cost) must PASS.

## Traps already discovered (do not rediscover them)

- `node --test` without a directory argument (run from `test/` it breaks discovery on node v22).
- The CLI without `--model` picks different models between runs.
- `--bare` requires ANTHROPIC_API_KEY (OAuth is out) — hence `--setting-sources project`.
- LLM runs cost money: a full matrix needs explicit budget approval; estimate the cost before starting.
- Benchmark runs share OAuth session limits with interactive work (a 429 "session limit" mid-matrix →
  circuit breaker; observed 2026-07-17). Plan large matrices after the limit resets; a 429 in a row
  means terminal_reason `api_error`, and summarize excludes those.

## Business context (short)

Competition surveyed 2026-07: Headroom/Repomix/nx-mcp own "token-saving" — we do NOT go there.
The niche: measuring whole setups, cross-agent, regressions after model updates.
Threat: the Anthropic Skill Creator (per-skill A/B) could widen its scope — check for it in the scans.
