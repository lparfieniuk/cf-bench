# RESEARCH: How the well-known AI benchmarks work (2026-07-17)

Goal: extract practices from established benchmarks that would strengthen cf-bench, and map the work
closest to our niche. Sources: WebSearch + arXiv (links at the end).

## 1. Benchmark overview

### SWE-bench / Verified / Pro (Princeton → OpenAI/ScaleAI)
- **What it tests**: fixing real GitHub issues (Python repos); success = hidden unit tests pass after
  the agent's patch. Deterministic scoring — same as ours.
- **The 2026 crisis**: OpenAI abandoned Verified (Feb 2026) — contamination (frontier models reproduce
  gold patches verbatim) plus scaffolding effects: identical model weights differ by 10–20 pp
  depending on the harness. >60% of "unsolved" tasks were mis-graded (tests too narrow or too broad).
- **SWE-bench Pro** (the answer): 1865 tasks, including **858 held-out** (non-public) and 276
  commercial repos — resistance to contamination by keeping part of the set private.
- **Lesson for cf-bench**: (a) contamination barely applies to us — the fixtures are synthetic and
  private; that is an ADVANTAGE, name it in publications; (b) "harness variance" is our founding
  argument: we measure the config/harness that other benchmarks do not control; (c) keeping held-out
  fixtures after open-sourcing is worthwhile (publish the tasks, keep some private).

### Terminal-Bench 2.0 (Stanford/LAUDE)
- **What it tests**: 89 end-to-end terminal tasks in Docker; scoring = tests inspect the FINAL STATE of
  the environment, not the transcript.
- **Construction rigor**: every task has 4 components: an NL instruction, an environment, verification
  tests, and an **oracle solution** (a human reference solution). ~3 person-hours of review per task.
  The oracle proves the task is solvable and the tests are passable.
- **Lesson**: we were missing oracle solutions. The sanity gate catches "the check passes before the
  run", but nothing proved the check CAN be passed (outcome validity). → implemented: `oracle.sh` per
  fixture + `runner/validate-tasks.sh`.

### Aider polyglot
- 225 Exercism tasks in 6 languages; the `pass_rate_2` metric — a second attempt with the output of the
  failing tests. Measures practical code editing plus diff formats.
- **Lesson**: retry-with-feedback is a different axis from ours (we measure the config, not the model),
  but the "agent sees the test result" format is analogous to our visible tests.

### LiveCodeBench
- Contest problems published AFTER the model cutoff — freshness as a defence against contamination.
  Our synthetic fixtures achieve the same thing more cheaply.

### tau-bench (Sierra)
- Customer-service agents; the key innovation: **pass^k** — the share of scenarios passed in ALL k
  independent rollouts. It measures reliability, not luck: GPT-4o 61% pass@1 vs 25% pass@8. Variance is
  signal, not noise to be averaged away.
- **Lesson**: we already have N repeats — report pass^n alongside the pass rate. "A config that scores
  10/10 vs 6/10" is a different value than the median. → implemented in summarize.

### HAL — Holistic Agent Leaderboard (Princeton)
- A standardized, **cost-aware** leaderboard: dollar cost as an axis co-equal with accuracy (median
  SWE-bench Verified run = $163; per-task spread 400×). A third party as the credibility guarantor.
- **Lesson**: our TSV already carries cost — keep cost a first-class metric in publications. The model
  "a third party audits configs" is exactly our monetization pitch.

## 2. State of statistical rigor (2026)

- Single-run results with no CI dominate — and are widely criticized ("Stochasticity in Agentic
  Evaluations", "Beyond pass@1", "Statistical Precipice").
- Recommendations from the literature: CIs on every metric, tests for paired samples, power analysis,
  multiple rollouts. Almost no leaderboard does this → **a credibility niche**.
- LLM-judge audits: >50% error rates (position/length/agreeableness bias) — our ban on LLM judges
  (hard rule 5) is validated by the literature; cite it in publications.
- The ABC checklist (task validity / outcome validity / transparent reporting) — our sanity gate +
  oracles + open TSVs cover all three axes.

## 3. Work CLOSEST to our niche (⚠ competition/validation)

### SkillsBench (arXiv 2602.12670)
The closest work to ours. 84 tasks / 11 domains, paired evaluation: no-skills vs curated vs
self-generated skills; 7308 trajectories, 5 trials/task, deterministic verifiers, 3 harnesses
(Claude Code, Gemini CLI, Codex CLI).
- Curated skills: **+16.2 pp** on average (range +4.5 SWE → +51.9 healthcare).
- Self-generated skills: **−1.3 pp** (the model cannot write the skills it then uses).
- 2–3 skills is the optimum (+18.6); 4+ skills → +5.9; "comprehensive documentation" → **−2.9**.
- Gaps (their own): no isolation of skill components, no lower-quality "community skills",
  no long-horizon tasks.
- **cf-bench positioning**: SkillsBench measures skills as a class ("do skills work?"), we measure a
  SPECIFIC config belonging to a SPECIFIC team ("does YOUR config work?"). Their finding that "too
  much content hurts" directly supports our audit product (config pruning backed by measurement).
  Cite as validation of the thesis.

### ETH Zurich: the effect of AGENTS.md (arXiv 2601.20404)
124 merged PRs across 10 repos, paired: with/without AGENTS.md, Codex only. Result: median time
**−28.6%**, output tokens **−16.6%** (Wilcoxon p<0.05). BUT: **they did not measure correctness** —
only efficiency. The gap is named by the authors themselves.
- **Positioning**: we measure exactly what they did not (success via deterministic checks) plus many
  config variants, not a binary present/absent.

### AGENTbench-138 / the "context files hurt" study (4 agents, 138 issues)
LLM-generated context files: **−0.5 to −2 pp** success, +20% cost. Human-written: **+4 pp**.
Cost: +14–22% reasoning tokens regardless of authorship.
- **Positioning**: this is precisely the dispute cf-bench settles per config. Contradicting results
  (ETH: −28% cost; this study: +20% cost) prove the effect depends on the specific config and tasks →
  "measure your own" = our product. The press has already picked it up ("CLAUDE.md doesn't work") —
  the timing for publishing the draft is good.

## 4. Implementation conclusions for cf-bench

| # | Practice (source) | Status |
|---|---|---|
| 1 | Wilson CI + Fisher exact + pass^n in summarize (tau-bench, CI literature) | IMPLEMENTED |
| 2 | Oracle solutions + validate-tasks (Terminal-Bench) | IMPLEMENTED |
| 3 | Cost as a first-class metric (HAL) | already there (TSV) |
| 4 | Hold out part of the task set after open-sourcing (SWE-bench Pro) | decision at OSS prep |
| 5 | Ban LLM judges — cite the >50% error audits in publications | for the draft |
| 6 | Synthetic private fixtures = contamination resistance — name it in the English README | for OSS prep |
| 7 | Paired evaluation (A/B on the same task) as "best practice" per SkillsBench | already there — cite it |
| 8 | The "config-lies" task class (a CLAUDE.md contradicting the repo) — supported by the SkillsBench "comprehensive docs −2.9pp" finding | fixture built, calibration awaiting budget |

## 5. Updated threats

- SkillsBench could expand from "skills as a class" to "per-repo config" — watch it (added to the
  research-routine watchlist alongside the Anthropic Skill Creator).
- The "context files don't work" wave could weaken the market for configs — but it strengthens the
  market for MEASURING configs. Our thesis is on the right side of the argument.

## Sources

- SWE-bench contamination/abandonment: codesota.com/news/swe-bench-contamination-debate,
  benchmarkingagents.com/swe-bench, digitalapplied.com (methodology 2026)
- SWE-bench Pro: codingfleet.com/blog/swe-bench-pro-explained
- Terminal-Bench: arxiv.org/abs/2601.11868, github.com/harbor-framework/terminal-bench
- Aider polyglot: emergentmind.com/topics/aider-polyglot-benchmark
- tau-bench pass^k: benchmarkingagents.com/tau-bench
- HAL: hal.cs.princeton.edu, arxiv.org/pdf/2510.11977
- Statistical rigor: arxiv.org/pdf/2512.06710 (ICC), arxiv.org/pdf/2603.29231 (Beyond pass@1),
  arxiv.org/pdf/2605.08261 (Statistical Precipice), simmering.dev/blog/agent-benchmarks
- SkillsBench: arxiv.org/html/2602.12670v1
- ETH AGENTS.md: arxiv.org/html/2601.20404v1
- "Context files hurt": todatabeyond.substack.com, academy.dair.ai/blog/agents-md-evaluation
