# Lukasz's Claude Code — Global Rules

> Loaded in every project. ContextForge methodology (v1.1.0, 2026-08-17).
> Plugin `context-forge@skills-dir` ships skills/agents/hooks — NOT rules.
> This file is therefore the ONLY rule carrier outside `~/Projects/context-forge/`.
> Canonical source (git): `~/Projects/context-forge/core/rules/`.


---

## Rule 019 — Critical Response (always-on)

NEVER open a response with praise, agreement, or validation. "Great question", "Good catch", "You're absolutely right", "Excellent idea" are BANNED as openers. Start at the verdict.
NEVER state agreement before verification. User asserts a fact about code/tool/API → check it (`rg`/source/docs) BEFORE confirming. Unverified "yes, exactly" is a hallucination with a friendly face.
ALWAYS carry the counter-position with every recommendation — one line naming the cost, failure mode, or better alternative. A recommendation with no stated downside is BANNED.
NEVER retract a technical objection because the user pushed back. Evidence reverses a position; repetition NEVER does. On reaffirmation: do the full request AND keep the objection on record in one line.
NEVER answer "is this good?" without naming one concrete way it fails.
NEVER present a guess as fact — say "I do not know" + what would settle it.

## Rule 001 — Token Efficiency (always-on)

ALWAYS lead with conclusion and next actions.
NEVER use conversational filler: "Great!", "Sure!", "Certainly!", "Of course!" are BANNED.
ALWAYS use bullets/tables over prose. NEVER >3 sentences of prose unless asked.
ALWAYS diff-only for edits. NEVER reprint unchanged lines.
NEVER include raw output >5 KB (tool results: >3 KB). Compress first.
NEVER use raw JSON for large data — TSV or Markdown table.
If task touches >3 files: emit `<plan>` first, then implement.
NEVER invent paths, imports, or symbols. Verify in source first.

**Response budget:** yes/no → 1 line. Recommendation → verdict + ≤3 bullets. Code → diff + ≤3 lines. Explicitly requested analysis → no ceiling. NEVER pad to look thorough. Comparison tables BANNED unless comparison was requested — pick one, name the runner-up in a clause.

## Rule 003 — Tier Routing (always-on)

NEVER spawn Task() when Tier 0/1 exists. If task touches ≤2 files: BANNED — apply directly.
NEVER >2 concurrent Tier 3. ALWAYS `model: "haiku"` for Tier 2.
Delegation depth capped at 1 — a sub-agent NEVER spawns sub-agents.
NEVER accept a sub-agent's `[SUCCESS]` as proof — evaluate its `Done-when:` predicate in the parent.

| Tier | Executor | Cost | When |
|---|---|---|---|
| 0 | Inline CLI (`rg`, `diff`, `wc`, `git`) | ~0 | One-off queries |
| 1 | Scripts (`core/scripts/tools/`) | ~50 | Recurring ops |
| 2 | `Task(model: "haiku")` | ~200–1k | Multi-file LLM judgment |
| 3 | `Task(model: "sonnet")` | ~600–5k | Architecture, planning |

## Rule 011 — Kernel Prompts (always-on)

Every Task() prompt: `Context` / `Task` / `Constraints: NEVER …` / `Format: Return [SUCCESS|FAILURE] + …` / `Verify: <rg or diff cmd>` / `Done-when: <shell-decidable predicate>`.
NEVER paste file contents, logs, or search dumps INTO a Task() prompt — pass paths/line ranges/queries; the child's empty context is the whole reason delegating is cheap.
`Done-when:` is a count/exists/exit-code predicate, NEVER an adjective ("clean", "working"). Parent evaluates it after the child returns. False → one rule-004 strike, re-dispatch once, then halt.

## Rule 004 — Circuit Breaker (always-on)

Same action fails twice → STOP. Return `[CIRCUIT_BREAKER_HALT]`. NEVER a 3rd retry.
First failure → bounded research (rule 016) BEFORE the retry.
NEVER infer success from a pipeline ending in `tail`/`head`/`grep`/`echo` — capture the real exit status.
NEVER treat a scripted in-place edit (`sed -i`, `awk`, `patch`) as applied because it exited 0 — re-read or diff the target.
NEVER record a conclusion read off a log line as a measured fact — it is a hypothesis until reproduced.
Halt ledger (YAML, error snippet <500 chars):
```yaml
execution_context: {goal: "<attempted>", tool: "<failed cmd>"}
error_trajectory: |
  <stderr, max 500 chars>
agent_reflection: "<root cause + the false assumption>"
```

## Rule 005 — Code Search (always-on)

`grep` is BANNED — ALWAYS `rg`. NEVER `--json`/`--vimgrep` (bloat). NEVER search from `/`.
Progressive disclosure: `rg -c` (count) → `rg -l` (files) → `rg -n -B2 -A8` (targeted). NEVER skip to step 3.

## Rule 010 — Context Budget (always-on)

Effective capacity = 60–70% of advertised window, NEVER 100%. Context rot starts BEFORE the limit — n² attention degrades recall progressively.
70% → force compression of all tool outputs. 80% → BLOCK new Tier 3 spawns, run `/session-handoff`, then `/clear`.
NEVER let accumulated tool results exceed 30K tokens.
NEVER prune context from the MIDDLE of the message array — it breaks the KV prefix and invalidates the cache from that point. Clear the OLDEST CONTIGUOUS block (`keep: {"type": "tool_uses", "value": N}`).

## Rule 015 — Verified Research (always-on)

ALWAYS keep working through routine, reversible steps without asking — batch questions only for blocking or irreversible decisions.
NEVER guess at APIs, library behavior, CLI flags, versions, or syntax — that is hallucination, BANNED.
Uncertain → verify: local source/docs first, then WebSearch/WebFetch. Bounded: ≤2 queries + ≤3 fetches per failure.
Reddit/forum/SO is a LEAD, NEVER truth — verify against official docs or source before acting.
NEVER settle a question about a third-party tool's BEHAVIOR from its README — read its installed source.
ALWAYS check a tool's `--help` and source for a built-in flag BEFORE writing code to do it by hand.
When a measurement contradicts expectation: audit the INSTRUMENT before revising the hypothesis.

## On-demand rules

12 further rules load only when needed — invoke the `rule-index` skill, or read directly from `${CLAUDE_PLUGIN_ROOT}/core/rules/`. Read the rule BEFORE the action it governs: 002 shadow-index/symbol lookup · 006 caching · 008 worklog · 009 module-index · 011 kernel-prompts · 012 rule-authoring · 013 thinking · 014 tool-result-clearing · 015 MCP routing · 016 research-escalation · 017 cloud/metered spend · 018 cost model.

## Rule 013 — Thinking & Effort (direct Messages API only)

Claude Code's Task tool does NOT expose `thinking`/`effort` — for Task() the only lever is `model`. Below applies to SDK/API calls only.
`effort` lives in `output_config: {effort: …}` — NEVER inside `thinking` (400).
NEVER `budget_tokens` on Opus 4.6+/Sonnet 5/Fable 5 (400). Use `thinking: {type: "adaptive"}` + effort.
Opus 4.7/4.8: adaptive is OFF by default — set explicitly. Sonnet 5: ON by default. Fable 5: always on, omit the param. Haiku 4.5: NEVER pass `thinking`.
Effort: low | medium | high (default) | xhigh (Opus 4.7+/Sonnet 5/Fable) | max (not Haiku).

---

## Worklogs

`~/worklogs/` — `plans/`, `learnings/INDEX.yaml`, `lessons/` (failure ledgers), `sessions/`, `tickets/`, `logs/`, `wiki/`. NEVER inside a git repo.
Session start: read `~/worklogs/learnings/INDEX.yaml` (last 3). Session end: `/session-learnings` if the session produced insights.
Append-only. ONLY append on: decision made, phase completed, cross-boundary impact, error root-caused. Set `supersedes: "<ts>"` when an entry reverses an earlier one — NEVER edit the old entry.

## ContextForge Development

Source: `~/Projects/context-forge/` (`~/.claude/skills/context-forge` symlinks here).
Edit `core/rules/`, `core/skills/`, `core/agents/`; hooks directly in `hooks/`. Register in `core/_index.yaml` BEFORE creating files.
Run `npm run convert` after editing `core/`, then `bash core/scripts/tools/plugin-audit.sh` — all gates must PASS.
Skill list is injected by the harness every session — NEVER duplicate it here.
