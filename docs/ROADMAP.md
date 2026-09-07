# cf-bench roadmap (as of 2026-09-06, after the engine/provider arms and the C/D/E variant matrix)

Thesis: **we do not sell rules — we sell proof that a config works.**
Path: OSS harness → leaderboard/publications → paid regression-watch + audits.

## ✅ Done (Phase 0 + rigor + library-pack start)

- A/B(+C) harness: runner (isolation via `--setting-sources project`, pinned model, sanity gate,
  hidden assertions, handling of runs that never executed, circuit breaker, `cli_version` in the TSV,
  per-task `VARIANTS` + `CONFIG_<X>`), smoke test, TSV + summarize
- **Statistical rigor**: Wilson 95% CI + Fisher exact + pass^n in summarize; oracle solutions
  (`cf-bench/oracles/`) + `validate-tasks.sh` (outcome validity, enforced in smoke)
- **10 tasks across 5 classes** (rubric: cf-bench/docs/TASK-DESIGN.md); 4 strong discriminators from
  4 different classes:
  - encoded-decision: js-stack-002 (N=10: A 0% vs B 100%, p=1.1e-05)
  - local-lie@scale: js-brown-cents-xl-007 (N=15: A 7% vs B 100%, p=2.1e-07)
  - config-lies: js-config-lies-008 (N=5: A 100% vs B 0%, p=0.008 — a lying config INVERTS the
    outcome, 9.8% cheaper; "cheaper, faster, confidently wrong")
  - library-convention: js-rxjs-submit-009 (N=5: A 0% vs B 100%, p=0.008 — a flip on a SMALL
    fixture, no noise; the rxjs operator choice is not inferable from the neighbourhood)
- Variant **C (placebo)**: configs/generic/, enabled on js-stack-002 — the defence against
  "you wrote the configs yourselves" (C≈A = the effect is knowledge, not file presence). UNMEASURED.
- Library-pack technique: fixture deps pinned exactly (rxjs 7.8.2, express 4.22.2) and installed once
  by `setup-fixtures.sh`, so runs stay offline; express-010 reclassified as cost-only (A 5/5, the
  app.js signal is too strong in a small repo)
- Research: `docs/research/ai-benchmarks-2026-07-17.md` (SWE-bench contamination, Terminal-Bench
  oracles, tau-bench pass^k, HAL, SkillsBench/ETH as niche validation and publication timing),
  `docs/research/library-targets-2026-07-18.md` (popularity / difficulty-for-AI lists, scoring,
  top-10 targets, a semi-automatic process with human calibration — NOT auto-generation)
- Article draft v2 (`docs/article-draft-brownfield-traps.md`) — awaiting review
- Research routine (program + script + launchd instructions), 2 suggestions for context-forge
- Total experiment cost so far: ~$25

## ✅ Delivered 2026-07-18 (rxjs-pack session, ~$7)

- 5 new tasks calibrated at N=5: 011 catchError (cost-only −18.7%), 012 withLatestFrom
  (DEAD: Δ=0 — retired), 013 shareReplay (cost-only −8.9%), 014 express-XL (cost-at-scale −28.6%,
  turns 16→9; the hypothesis "middleware weakens with scale" REFUTED),
  **015 refresh-exhaustMap: A 60% vs B 100%, Δ+40pp — inside the class-2 band**
- **The contested-prior rule** (TASK-DESIGN): only a policy that CONTRADICTS the training prior
  discriminates; canonical conventions are always cost-only. Litmus test: "would a senior engineer
  with no company context answer unambiguously?" YES → do not build it. Confirmed by control task 015.
- takeUntil/teardown deliberately rejected: behaviourally indistinguishable (unsubscribe ≡ takeUntil)

## ✅ Delivered 2026-08 → 2026-09 (engine + provider arms, out of roadmap order)

Both were built ahead of their place in the plan — they were cheap once the variant mechanism existed,
and they answer "is this a Claude Code artefact?" before publication rather than after.

- **Engine arm — opencode** (`CFBENCH_AGENT=opencode`). Same task files, same fixtures, same checks;
  the runner translates the three knobs (turn ceiling, tool allowlist, isolation) into a generated
  `opencode.json`. Details and the residual asymmetries in `cf-bench/README.md`. Two gotchas are load-
  bearing and documented there: permission rules resolve with `findLast`, so the catch-all `{"*":"deny"}`
  must come FIRST or opencode strips `bash` from the toolset; and `instructions` must be an absolute
  path or variant B ships no config at all.
- **Provider arm — local Ollama model** (`PROVIDER_<V>="ollama:<tag>"`, wired on
  `ts-fix-discount-001`, `js-config-lies-008`, `js-rxjs-catch-011`). A provider swap of B: same config,
  same check, same ceiling, so Δ(D−B) is the provider effect alone. Preflight refuses a run when the
  server is down or `num_ctx` is under 32768 — an unpinned window degrades silently. Results:
  `results/local-arm-20260818-230602.tsv`. Caveat: `cost_usd` on that arm is notional (Anthropic
  prices applied to local tokens), so read `turns` and `success`, never the dollar column.
- **Variant C/D/E measured** on `js-express-errors-010` (2026-09-05/06). C = placebo config,
  D = ContextForge always-on core (~619 tok), E = the payload a consumer repo really loads (~1945 tok).
  Two clean results: C vs A costs **+9.6%** (p=0.001) — merely having a `CLAUDE.md` is not free; and
  E vs D is **+1.9%, not significant** (p=0.186) — payload SIZE is not a cost driver. Everything
  crossing the 2.1.261 → 2.1.263 CLI boundary was discarded, not interpreted.

## 🔜 Next up (recommended order)

1. **Decision on 012** (retired vs redesign as contested) plus possibly 1–2 tasks passing the
   contested-prior pre-filter (candidates: debounce-vs-throttle for scroll, startWith-vs-initial-state,
   retry-fetch policy)
2. **Freeze the set → final N=10 matrix including variant C** across every discriminating task plus C
   on the flagships, in one fresh matrix (consistent CLI version); estimate ~$30–40 [BUDGET — approval
   before starting]. STILL OPEN since July. The 2026-09-05/06 attempt spent $4.93 and half of it was
   voided because Claude Code auto-updated mid-matrix; arms measured under different `cli_version`
   values may never be pooled. Precondition for the next attempt: `DISABLE_AUTOUPDATER=1` exported for
   the whole run, and the whole matrix in ONE `run-bench.sh` invocation — topping up a missing arm
   separately is exactly what created the version split.
3. **Draft review** + decision: keep the config-lies section in the article or split it into its own post
4. **Open-source prep** (a precondition for Show HN): license, English README, raw TSVs, a reproduction
   script; held-out decision (keep some tasks private — the SWE-bench Pro pattern)
5. **Publication**: dev.to → Show HN → r/ClaudeAI, X
6. **launchd for research-scan** (`research-routine/README-SCHEDULING.md`), ~5 min

## 📦 Next phase (post-publication)

- **Angular/Nx brownfield fixture** — technical decision: cache `node_modules` between runs
  (copying ~300MB/run vs a shared store vs pnpm). This also unblocks React/Jest/Karma/Jasmine
  (too heavy to copy per run) and Angular migrations (signals vs NgModules — a version-drift trap,
  top-2 on the target list)
- **Python-api-pack**: Pydantic 1→2, FastAPI, SQLAlchemy 2.0 (pip --target = vendorable; the classic
  deprecated-API trap — models cling to old patterns, >50% of failures are wrong API usage)
- **Cross-agent, remainder**: Codex CLI / Cursor CLI. The `agent adapter` abstraction this needed
  already exists — it was built for the opencode arm above, so each further engine is now an adapter,
  not a refactor.
- **Multi-model, remainder**: haiku/opus — does cheap intelligence change the taxonomy of traps? The
  routing mechanism is done (the Ollama arm proved the provider swap); what is missing is the run.
- More classes: stale docs (the README lies), dead code paths, LangChain version-pinning
  (the regression-watch story)

## 💰 Monetization (gated)

- **Gate 1**: publication produces traction (stars/discussion) → a config leaderboard
- **Gate 2**: one paying customer (regression-watch or a one-off audit) **before** anything hosted gets built
- Stack packs as a per-stack audit offering (Angular/RxJS pack first)
- Regression-watch MVP: cron + cf-bench against the customer's config after every model/CLI update, plus the delta

## 🔧 For context-forge (queue in context-forge-suggestions/)

- CF-001: a `/research-scan` skill (continuous research)
- CF-002: fix the pre-commit-review hook (hash the git toplevel, not the cwd; 2 documented cases) —
  DONE in its original form, and reopened/closed again 2026-09-06 in two further shapes: the marker
  was keyed to the SESSION's repo rather than the repo being committed, and the advertised
  `SKIP_REVIEW=1 git commit` bypass never reached the hook (a PreToolUse hook is a separate process,
  spawned before the command). A third bug surfaced while testing: `git -C <dir> commit` did not match
  the commit detector at all, so the gate silently did not fire. All three now carry negative tests
  in `context-forge/scripts/hooks.test.ts`, mutation-checked.

## Invariants

Metrics-first (no claim without a measurement) · deterministic scoring (never an LLM judge) ·
local-first, flat files · nothing hosted before the first paying customer · run budgets by approval ·
a task enters the set ONLY after calibration (N≥5 inside its class band).
