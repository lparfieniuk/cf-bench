# Project rules

> Variant F in cf-bench: `cf-core` (variant D) plus the two things D lacks. D carries
> rule 002 — the rule that FORBIDS reading whole files for discovery — without rule 005,
> the progressive-disclosure chain that supplies the cheaper substitute, and without the
> 015/019 mandate to verify against local source before concluding. D lost 6 of 20 runs
> that a bare repo won; this arm tests whether the missing substitute and the missing
> verification mandate are the cause. Everything else is byte-identical to `cf-core`.
>
> Limitation on record: F changes TWO things at once, so a return to 10/10 confirms the
> pair, not either rule alone. Splitting it costs a second arm.
>
> Carries NO task-specific knowledge, exactly like C, D and E.

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

## Code search (005) — the substitute 002 assumes exists

- Progressive disclosure, in this order: `rg -c "pattern" path/` (count) → `rg -l "pattern" path/`
  (files) → `rg -n -B 2 -A 8 "pattern" file` (targeted lines). Never skip to the third step.
- Use context flags (`-A`, `-B`, `-C`) to pull the lines around a match instead of opening the
  whole file for one symbol.
- When a file defines the behaviour you are about to imitate, read that file — narrowing is for
  FINDING the right file, not for skipping the one you found.

## Verify before concluding (015/019)

- Never guess at an API, a library's behaviour, a convention, or a flag. Verify it in local
  source first; that is what "verified" means here.
- A pattern that appears in one file is evidence, not proof. Before imitating it, check whether
  the code that actually runs it agrees — the loudest example in a repo is often the legacy one.
- State a conclusion only after the check that supports it. An unverified conclusion is a guess
  wearing a confident face.
