# Project rules

> ContextForge always-on core — the rule bundle a repo passively receives when the
> `context-forge` plugin is installed. Assembled from the SYSTEM CONSTRAINTS of rules
> 001/002/003/004/010 (the always-on set; rule 007 loads "core only" for a single-file
> bugfix, which is exactly this task class). Source: ~/Projects/context-forge/core/rules,
> snapshot 2026-07-22. This is variant D in cf-bench: it carries NO task-specific knowledge,
> so it is the placebo C's structural twin plus CF's efficiency machinery. Expected: D≈C on
> success, D<C on cost/turns iff the rules actually help. Regenerate when the rules change.

## Token efficiency (001)

- Lead with the conclusion and the concrete next action. Be concise and information-dense.
- No conversational filler. Explanations ≤3 sentences unless more is explicitly requested.
- Diff-only for edits — never reprint unchanged lines.
- Large data → Markdown table or TSV, never raw JSON.
- Never invent paths, imports, or symbols — verify in source first.
- If a task touches >3 files, emit a short plan first, then implement.

## Discovery before raw reads (002)

- For "where is X / how is X structured", locate the symbol first (search), then open only the
  files that matter — do not read whole files for discovery.
- Never load more than ~5 raw source files without narrowing first.
- Use targeted context (a few lines around a match) instead of reading an entire file for one symbol.

## Cheapest correct tier (003)

- Prefer a one-off CLI query (rg/grep/wc/git) over anything heavier when it answers the question.
- Do the change directly when it touches ≤2 files — do not orchestrate sub-work for a small edit.
- Pick the cheapest approach that produces a correct result; escalate only when it demonstrably fails.

## Fail loud, fail fast (004)

- If the same action fails twice, stop and report it — never attempt an identical third try.
- A bug fix targets the root cause, not the symptom: fix it once where all callers route through,
  not with a guard per caller.
- Never infer success from a pipeline whose last element is `tail`/`head`/`grep`/`echo` — capture
  the real exit status of the command that matters.

## Context budget (010)

- Treat the effective working window as smaller than the nominal one; recall degrades before the
  hard limit. Keep only what the current step needs in active context.
- Summarize large command/search outputs immediately; do not carry raw dumps forward.
