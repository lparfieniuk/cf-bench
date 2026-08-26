# RESEARCH: Harness variance goes mainstream — competition scan & direction (2026-08-24)

Goal: re-scan the benchmarking landscape since `ai-benchmarks-2026-07-17.md`, decide what cf-bench
should build next, and settle the UI question. Sources: WebSearch (2 queries, arXiv + practitioner).

## 1. The thesis got validated — loudly

Since July, three independent sources made "harness/config is half the score" mainstream:

- **"The Scaffold Effect in Coding Agents"** (arXiv 2607.22585): fixed models, 3 open-source
  harnesses (Goose / OpenCode / OpenHands-SDK) on 50 Terminal-Bench Pro tasks → pass-rate deltas
  only 0–8 pp (mostly within noise at N=50), but **tokens-per-solved-task differs 40×** by harness;
  model upgrade moves it 1.0–1.3×. Recommends **harness–model pair** as the evaluation unit +
  tokens/solved-task, no-action turns, failure fingerprints as first-class metrics.
  - Lesson: our cost columns are not garnish — they are arguably the strongest signal we emit.
    Report `cost_per_success` alongside pass rate.
- **"Stop Comparing LLM Agents Without Disclosing the Harness"** (arXiv 2605.23950): Opus 4.5 on
  SWE-bench Pro 45.9% (SEAL) vs 55.4% (Claude Code); HAL reports cross-scaffold gaps up to ~48 pp;
  within-model harness range ≈ 2× the within-harness model range; adding ONE search subagent flips
  orderings. Position paper endorses locked-harness protocols (HAL, mini-SWE-agent) or full disclosure.
  - Lesson: cite both papers in the article/publication. They are our "founding argument" proven
    by third parties — we measure exactly the layer they say nobody discloses.
- **Anthropic, "The new rules of context engineering" (2026-07-24)**: removed >80% of Claude Code's
  system prompt for the Claude 5 generation with no measurable loss; shipped `claude doctor`.
  - Lesson: configs REGRESS silently on every model generation — this IS the regression-watch pitch,
    said by the vendor itself. Also: `claude doctor` gives generic rightsizing advice but measures
    nothing → it complements, not replaces, outcome measurement.

## 2. Competitive map update

| Tool | What it does | Threat / use |
|---|---|---|
| **Skill Creator 2.0** (Anthropic, Mar 2026) | The threat flagged in CLAUDE.md MATERIALIZED and widened: Create/Eval/Improve/**Benchmark** modes, blind A/B comparator, pass rate/time/tokens, trigger tuning | Per-skill only, **LLM-judge grading** (Grader/Comparator agents), Claude-only, no whole-config workflow evals, no cross-agent. Practitioner literature itself notes "workflow-level eval … is the layer that does not exist yet in most teams' setups" — that layer is OUR product |
| **Harbor** (Laude Institute) | Unified task manifest + harness across Claude Code / Codex CLI / OpenHands / Terminus; Terminal-Bench 2.x ships via Harbor registry (`harbor run -d terminal-bench@2.0`) | Not a competitor to the *thesis*; potential distribution channel later (publish cf-bench tasks as a Harbor pack?). Cost today: Docker-centric, heavier than our bash runner — do NOT migrate the runner |
| **Terminal-Bench Pro** (Alibaba, 400 tasks) + TB 2.1 | Harder terminal set, ~28 tests/task | Reference point only; confirms oracle+hidden-test practice we already follow |
| **MCP Atlas** | Tool-use/MCP benchmark named in procurement "benchmark bundles" | Watch: MCP-config measurement may become an adjacent pack for us |
| **CursorBench** | Vendor-built AND vendor-scored eval; no independent reproduction | Governance angle strengthens our "independent third-party audit" positioning |
| **`claude doctor`** (native) | Rightsizing advice for CLAUDE.md/skills | Advice ≠ measurement; pairs well with us (doctor prunes → cf-bench proves the delta) |

Procurement guidance (appliedtechnologyindex 2026-06, digitalapplied 2026-05) converged on:
*"request a benchmark bundle plus a private-repository pilot; variance matters more than peak score;
ask for repeated-run results, failure classes, cost per resolved task."* — that is literally the
cf-bench paid-audit deliverable. Demand framing exists; supply (us) does not yet.

## 3. What this means for the roadmap

Unchanged verdicts (roadmap stands), sharpened priorities:

1. **Publication timing improved**: two 2026 arXiv papers argue our premise. Ride the wave —
   cite them, position cf-bench as the missing instrument ("they showed the harness matters;
   we give you the A/B measurement of YOUR config").
2. **Final N=10 matrix incl. variant C** stays the blocker before publishing (roadmap item 2,
   ~$30–40, needs explicit budget approval). Add to its scope: report **cost-per-success** —
   the scaffold-effect paper makes it the metric reviewers will look for.
3. **Cross-agent (Codex CLI adapter)** rises in priority: "harness–model pair" is becoming the
   standard unit; opencode arm exists (commit 5a02588, local-arm TSV), Codex CLI is the natural
   second engine. Cheap: the adapter abstraction is already there.
4. **Differentiation sentence for the article**: Skill Creator benchmarks *a skill* with LLM judges
   inside one vendor's harness; cf-bench measures *the whole setup* (CLAUDE.md + skills + hooks +
   MCP) with deterministic checks, cross-agent, with CI statistics. Both true and checkable.
5. New small wins worth stealing from the literature: failure-fingerprint taxonomy (REASON /
   VERIFY / MAX_TURNS / idle-loop — we already have `terminal_reason`; formalize classes in
   summarize) and no-action-turns count if cheaply derivable.

## 4. UI? — NO (with one cheap exception)

- Roadmap invariant holds: **nothing hosted before the first paying customer** (Gate 2). A UI
  implies hosting/state → premature until publication produces traction (Gate 1).
- Counter-position recorded: a hosted leaderboard is the classic traction play and waiting costs
  early momentum; but building UI before the final matrix means polishing an instrument with no
  calibrated readings — data moat first, glass afterwards.
- Cheap exception allowed NOW: a **static HTML report** generated by the runner
  (`summarize.sh --html results/*.tsv > report.html`, flat file, zero hosting, offline). It serves
  the Show HN post (people skim tables better rendered) without violating any invariant.
  Effort: ~half a session. Everything beyond that waits for Gates 1/2.

## Sources

- https://arxiv.org/html/2607.22585 (Scaffold Effect)
- https://arxiv.org/html/2605.23950v1 (Harness disclosure position paper)
- https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
- https://claude.com/plugins/skill-creator ; https://pasqualepillitteri.it/en/news/341/
- https://appliedtechnologyindex.com/research/2026-comparative-analysis-coding-agent-evaluation-harnesses-after-swe-bench/
- https://www.digitalapplied.com/blog/swe-bench-terminal-bench-benchmark-guide-2026
- https://arxiv.org/html/2601.11868 (Terminal-Bench 2.0 paper; Harbor)
