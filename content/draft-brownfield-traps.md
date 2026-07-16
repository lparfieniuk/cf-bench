# I set traps for an AI coding agent in a fake legacy codebase. What it fell for tells you exactly what belongs in your CLAUDE.md

> Draft v2 (2026-07-16). Flagship results confirmed at N=10 (Fisher exact p < 1e-4); secondary cells at N=5. All results: Claude Code headless, pinned `sonnet`, isolated from user-level config.

Everyone is selling agent configs right now — cursor rules packs, CLAUDE.md templates, "production-tested" convention files. Almost nobody measures whether they do anything. The published science is genuinely contradictory: an [ETH Zurich study](https://academy.dair.ai/blog/agents-md-evaluation) found context files add 20%+ inference cost for at best a 4% success bump (LLM-generated ones actually *hurt*), while [another benchmark](https://arxiv.org/html/2601.20404v1) found AGENTS.md cuts wall-clock time by 28%. Both can't be the whole story.

So I built a small harness — A/B runs of the same task in the same repo, with and without a config file — and started designing tasks intended to trip an agent the way real legacy codebases trip them. I work in a large brownfield Angular monorepo in my day job; I've watched agents get confidently lost in it for a year. I thought I knew what would trip them.

I was wrong three times before I was right. The refutations turned out to be the most useful data.

## The harness, in one paragraph

Each task is a small repo with a deliberately failing test suite. The agent gets a prompt, a work directory, and a turn cap. Variant **A** runs in the bare repo; variant **B** gets a short, human-written `CLAUDE.md` with project knowledge. Success is deterministic: a check script (tests must pass) — no LLM judging. The trick that makes discrimination possible at all: **hidden assertions**. Visible tests make the task attemptable but underspecify it; after the agent finishes, the harness injects extra tests encoding the *team's* spec — the stuff that lives in people's heads, which is exactly what a config file exists to capture. Every cell below is 5 repeated runs, medians reported, API-error runs excluded.

## Trap 1: the generated-dist trap (refuted)

Classic brownfield wound: tests import from `dist/`, the failing stack trace points at `dist/`, but `dist/` is generated — CI rebuilds it and wipes your edit. Surely an agent without the "never edit dist" note patches the build artifact?

**No. 5/5 agents fixed `src/` and rebuilt.** The model reads `package.json`, sees `"build": "rm -rf dist && cp -R src dist"`, and does the right thing. Anything discoverable by *mechanically tracing the repo* — imports, scripts, file relationships — a modern agent discovers. A config note repeating it is dead weight.

## Trap 2: the lying comment (refuted at small scale)

Brownfield repos lie. I gave `billing.js` a loud stale comment — `// NOTE: all monetary amounts are dollar values` — while the code one function below (`formatAmount` dividing by 100) proves the system migrated to integer cents. Task: add a payment fee function. The hidden test checks cents math.

In a 5-file repo: **5/5 correct without any config.** The agent weighed a comment against code and trusted the code. Same with a mixed-conventions repo (half the modules throw, half return result objects): it inferred the right convention from domain proximity, 5/5.

At this point the config's measurable value looked purely economic: −11% to −24% cost, −43% to −53% output tokens, fewer turns. Real, but not the "agents get lost" story I lived through at work.

## Trap 3: the same lies, buried in a 120-file repo (confirmed)

Here's the thing about my day-job monorepo: it isn't 5 files. So I generated 120 plausible noise modules (deterministic, seeded — services, helpers, trivial tests), moved the *truth* (`formatAmount`) deep into `src/lib/money/`, and left the *lie* (the dollar comment) right in the file the agent has to edit.

Everything flipped:

| Task | A (no config) | B (with CLAUDE.md) | Δ cost | Δ output tokens |
|---|---|---|---|---|
| lying comment, truth distant (120 files) | **1/10** | **10/10** | −9% | −47% |
| mixed conventions, grep-findable (120 files) | 5/5 | 5/5 | **−50%** | −60% (72s→26s) |

(Fisher exact for 1/10 vs 10/10: p ≈ 6×10⁻⁵; Wilson 95% CI for the A cell: 2–40%.)

The agent that beat the same trap in a 5-file repo **failed it 9 times out of 10 at scale** — it trusts the local signal and never digs up the distant truth. Meanwhile the grep-findable convention still never flips success at any scale, but the config halves the bill: the uninstructed agent spends 16 turns and 72 seconds exploring before writing a line.

## Trap 0, the control: knowledge with zero repo signal

One task encoded a pure team decision — "discounts stack additively, capped at 50%" — visible nowhere in the code. Without the config: **0/10** (agents default to multiplicative stacking, the industry-common choice). With: **10/10**, at −21% cost. Fisher exact p ≈ 5×10⁻⁶.

## The taxonomy that fell out

Four calibrations, five hypotheses tested, and the results compress into one design rule:

1. **Zero-signal decisions** (team policy absent from code) — a config flips success at any repo size.
2. **Local lie + distant truth** — a config flips success *once the repo is big enough* that the agent won't stumble on the correction. This is the mechanized version of "the AI keeps confidently doing the wrong thing in our legacy code".
3. **Grep-findable knowledge** (conventions, build workflows, file relationships) — a config never changes *whether* the agent succeeds, only *what it costs*: up to −50% spend, −60% output tokens, a third of the wall-clock time in a 120-file repo.
4. **Everything else** — small cost savings (~−10%), nothing more.

Notice what this validates: the ETH study's advice to "write for the gap, not the overview." Restating what's greppable buys you latency, not correctness — and it's also why generic rule packs full of framework best practices measure so poorly. The model already knows Angular. It doesn't know that *your* discounts cap at 50%, or that the dollar comment in `billing.js` has been wrong since the 2024 migration.

## Honest limitations

One model (Sonnet, pinned), one harness (Claude Code headless), N=10 for the two flagship tasks and N=5 for the rest, synthetic fixtures whose "scale" is 120 files, not 12,000. One of ten agents *did* find the buried truth without help — this is a probability shift, not a law of nature. Success criteria are deterministic tests, which measures compliance-with-spec, not code quality. Treat everything directional. The harness, fixtures, seeds, and raw TSVs will be public so you can re-run every number.

## What I'm doing with this

The interesting product isn't another rules pack — it's the measurement. The same harness that produced these tables can answer, for *your* repo: which lines of your CLAUDE.md earn their token cost, which are dead weight, and whether last week's model update silently changed the answer. I'm open-sourcing the harness (BYOK, flat TSVs, no cloud). If you want the "did the model update break my config" version as a service, that's the experiment I run next.

*Harness: cf-bench — repo link on release. Total API spend for every experiment in this post: under $20.*
