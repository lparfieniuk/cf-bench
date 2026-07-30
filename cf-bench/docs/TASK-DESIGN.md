# cf-bench task design (rubric)

A task is good when **the config decides success**, not just cost. ts-mini-001 does not meet that bar
(100% success in both A and B) — it serves as a smoke/cost-only task.

## Hard requirements (every task)

1. **Declared GAP**: the `.task` header names the config line that decides the task. Without that
   line the knowledge is NOT fully inferable from the repo (partially is fine — we are measuring
   config vs exploration).
2. **Hidden assertions**: `HIDDEN="<dir>"` in the `.task` → the contents of `fixtures-hidden/<dir>/`
   are copied into the workdir AFTER the agent run, BEFORE the final check. Visible tests make the
   task *attemptable*; hidden ones pin down the spec (design decisions, conventions, invariants).
3. **Sanity gate**: the check MUST fail before the run (enforced by the runner; the gate only sees
   the visible tests — hidden ones are injected after the agent run).
4. **Determinism**: no network during a run, no dependence on TZ/clock/locale. Dependencies are pinned
   to exact versions in the fixture's `package.json` and installed once up front by
   `runner/setup-fixtures.sh`. Success = exit code, never an LLM judge.
5. **Difficulty from knowledge, not from puzzle**: the fix itself is trivial; what is hard is
   WHAT/WHERE according to project policy. We are not testing model intelligence, we are testing the
   value of the config.
6. **Oracle solution** (Terminal-Bench practice): `oracles/<fixture>.sh` (fallback: the name without
   the `-xl` suffix) applies the reference fix; `runner/validate-tasks.sh` proves for every task that
   the check fails before the oracle and passes after it (+ hidden). Oracles live OUTSIDE `fixtures/`
   so they never reach the agent's workdir. Enforced in smoke.sh.

## Task classes (after the 2026-07-16 calibration, N=5)

1. **encoded-decision** — a team policy/decision with NO signal in the repo at all (js-stack-002).
   A=0% is correct here: it measures exactly the value of writing the decision into the config.
   The strongest discriminators (measured: A 0% vs B 100%, cost −24%).
2. **conflicting-signal (brownfield)** — a signal DOES exist in the repo, but it contradicts itself
   (lying comment vs code, two conventions 50/50). A should land at 20–70% — it measures whether the
   config beats the wrong prior. The core of the value proposition for brownfield/legacy.
3. **cost-only** — both variants pass, the config cuts cost/turns (ts-mini-001, js-dist-003).
   We keep 1–2 of these for the cost metric; they do not count toward discrimination.
4. **config-lies** (js-config-lies-008, CALIBRATED 2026-07-18, N=5 sonnet) — the config states
   something UNTRUE about the repo; A/B semantics are inverted: B is sabotaged, and we measure blind
   trust in the config. **Result: A 100% (5/5) vs B 0% (0/5), Fisher p=0.008; cost of B −9.8%.**
   The agent did NOT ONCE question the lying config despite contradicting evidence in the repo — the
   config is a fully trusted single point of failure. The narrative: "cheaper and more confident, but
   wrong" — a stale config does not degrade the outcome, it INVERTS it. Motivation: the 2026
   literature ("context files hurt", SkillsBench: comprehensive docs −2.9pp); this is our measurement
   of the value of config audits (the product).

**Lesson from the refuted js-dist hypothesis**: traps that are mechanically discoverable (following
imports, reading package.json) do NOT discriminate — modern models do that reliably. Only knowledge
with no signal (class 1) or with a contradicting signal (class 2) discriminates.

**Lesson from the class-2 calibration (2026-07-16, N=5, sonnet)**: in a SMALL fixture (3–5 files)
conflicting-signal does not discriminate success either — A=100% on both tasks (the agent resolves
the code-vs-comment conflict and picks the convention from domain-adjacent files). The config's effect
is large on cost though: −11% to −23% cost, turns 9→6/7, output tokens −43% to −53%. Working
hypothesis: "getting lost in brownfield" requires SCALE — the signal buried among hundreds of files,
exploration expensive. Next iteration of class 2: a fixture inflated with synthetic noise (100+
plausible files) and/or the signal moved far away from the edited file. Until then, classify 004/005
as cost-only with a high delta.

**Lesson from the scale experiment (2026-07-16, XL = 120 noise files, N=5, sonnet)** — scale splits
class 2 into two subclasses that behave differently:

- **2a. local-lie / distant-truth** (cents-xl: a lying comment in the edited file, the truth buried in
  src/lib/money/): scale FLIPS success — A 100%→**0%** (0/5), B 100%. In a large repo the agent trusts
  the local signal and never reaches the distant truth. The most valuable subclass for brownfield.
- **2b. grep-findable convention** (errors-xl: a convention findable by pattern in any file): success
  does NOT flip at any scale (A=100%), but cost explodes — the config yields **−50% cost, −60% output
  tokens, time 72s→26s, turns 16→9**. The "cost-at-scale" class.

Design rule: discriminating on success requires a bad hint LOCALLY plus the truth FAR AWAY (or zero
signal — class 1). Measure grep-findable conventions as cost, not success.

## Calibration target (verified empirically, N≥5)

- class 1: A **0–30%**, B **>85%**
- class 2: A **20–70%**, B **>85%**
- class 3: A=B≈100%, Δcost < 0
- outside the band → redesign or a deliberate reclassification

## Subclass: library-convention (2c) — since 2026-07-18

A team convention for USING a popular library (not API knowledge — the model has that from training).
The trap = a neighbouring file shows the pattern that is correct for a DIFFERENT case (rxjs: switchMap
in search.js vs exhaustMap for submits; express: inline res.status in legacy users.js vs next(err) to
central middleware). Tasks: js-rxjs-submit-009, js-express-errors-010.

**Calibration 2026-07-18 (N=5, sonnet)**:
- js-rxjs-submit-009: **A 0/5 vs B 5/5 (p=0.008), cost of B −2.5%** — a full discriminator on a SMALL
  fixture (no scale needed!). The rxjs operator convention is not inferable from the neighbourhood —
  the neighbouring switchMap misleads effectively. The best strength-to-size ratio.
- js-express-errors-010: A 5/5 = does not discriminate success (the central-middleware signal in
  app.js is too strong in a small repo — the same lesson as brown-errors small). Cost −7.9%.
  Classification: cost-only; a candidate for an XL version (noise + a buried error handler).

**Pack expansion 2026-07-18, CALIBRATED (N=5, sonnet)** — a negative result, and the key lesson:

- js-rxjs-catch-011 (catchError inside the flattening): A 5/5 = cost-only, cost −18.7%
- js-rxjs-latest-012 (withLatestFrom vs combineLatest): A 5/5, cost ±0 — DEAD (retired)
- js-rxjs-share-013 (shareReplay vs share): A 5/5 = cost-only, cost −8.9%
- js-express-errors-xl-014 (010 at scale, 134 files, errorHandler behind setup/pipeline.js):
  A 5/5 = cost-only, cost −28.6%, turns 16→9. The hypothesis "the middleware signal weakens with
  scale" is REFUTED — consistent with lesson 2b (grep-findable convention = cost-at-scale).

**Design rule (from this calibration): only a policy that CONTRADICTS the training prior
discriminates.** catchError-inside, withLatestFrom-for-triggers, shareReplay-for-cache are CANONICAL
answers (NgRx lore, blog posts) — the model knows them without a config, and a misleading neighbour
does not beat the prior. js-rxjs-submit-009 flips because choosing exhaustMap is CONTESTED
(switchMap/mergeMap/concatMap are all defensible; the team policy is an arbitrary decision).
Design-time test: "would a senior engineer with no company context answer unambiguously?"
YES → the task will be cost-only. The value of a config = the DIVERGENCE of the team's policy from the
canon, not the presence of a convention as such. (This is also the product narrative: the agent knows
best practices; you pay to measure where your team departs from them.)

All 4: oracle + anti-pattern sanity (the anti-pattern passes the visible tests, fails the hidden ones)
verified before calibration. Data: results/bench-20260718-101708.tsv.

**Control test for the rule — js-rxjs-refresh-015 (2026-07-18, N=5, sonnet)**: an exhaustMap policy for
a refresh button (canon for a read is switchMap; the neighbouring typeahead.js reinforces the wrong
answer). Rule prediction: A should fail. **Result: A 60% (3/5) vs B 100% (5/5), Δ+40pp, cost −14.4%** —
the first rxjs task INSIDE the class-2 band (A 20–70%); 009 is the "full flip" class (A 0%). The rule
is directionally confirmed (p=0.444 at N=5 — needs N=10 in the final matrix). Design-time pre-filter
for library-convention tasks: build ONLY contested conventions; measure canonical ones as cost at most.

**Rejected: takeUntil/teardown** (from the roadmap). The teardown convention is NOT behaviourally
discriminable: `subscription.unsubscribe()` in destroy() is observationally equivalent to
`takeUntil(destroy$)` — a hidden test cannot tell the forms apart without grepping the source, and
checking for form breaks the behavioural-determinism rule (rubric items 4–5). A candidate only if a
"form-lint" class measured separately from success ever exists.

Technique: the library is pinned to an exact version in the fixture's `package.json`
(`express` 4.22.2, `rxjs` 7.8.2) with a committed `package-lock.json`, and installed once by
`runner/setup-fixtures.sh` before the matrix. Runs stay offline and deterministic (hard rule 3
preserved); `node_modules/` is gitignored. Until 2026-07-30 these trees were hand-vendored into git
instead — the switch is why result files older than that date were measured against a `package.json`
declaring no dependencies.
Out of scope until the node_modules cache decision (ROADMAP): Angular/Karma/Jasmine/Jest/React —
full toolchains, far heavier to install per fixture.

## Variant C (placebo) — defence against "you wrote the configs yourselves"

For flagship tasks add `VARIANTS="A B C"` + `CONFIG_C="generic"` (configs/generic/ — best practices
with no task knowledge). C≈A = the B effect comes from knowledge; C>A = part of the effect is the mere
presence of a config (report that honestly). Enabled on: js-stack-discounts-002.

## Anti-patterns

- The spec fully contained in the visible tests (the agent reads the tests → zero discrimination)
- The gap knowledge written into a code comment in the fixture (that is not a gap, that is the repo)
- A hidden test that contradicts a visible one (the agent cannot pass both — unfair)
- A flaky task (a rerun with no changes gives a different result)

## `.task` header template

```
# GAP: <quote the config line that decides it>
# HYPOTHESIS: A fails because <the wrong choice the agent is predicted to make>
```
