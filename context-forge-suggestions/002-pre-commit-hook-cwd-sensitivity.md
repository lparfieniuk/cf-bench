# Suggestion CF-002: the pre-commit-review marker is sensitive to the session cwd

Status: PROPOSAL — a bug found in practice on 2026-07-16 while working on cf-bench.

## Problem

`hooks/pre-commit-review.sh` computes `SESSION_HASH` from the **session cwd at PreToolUse time** —
not from the repo directory the commit belongs to. Observed consequences:

1. The command `cd ~/repo && git commit ...` is blocked if a previous command left the session cwd in
   a subdirectory (`~/repo/cf-bench`) — the hook hashes the subdirectory, while the marker only exists
   for the root. A `cd` inside the command does not help: the hook fires BEFORE execution.
2. Review done → commit blocked anyway → the user/agent is taught to reach for `SKIP_REVIEW=1` —
   the hook trains its own bypass as an anti-pattern.

## Proposed fix

In the hook, instead of hashing the raw `HOOK_CWD`, normalize to the repo root:

```bash
REPO_ROOT=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null || echo "$HOOK_CWD")
SESSION_HASH=$(printf "%s" "${REPO_ROOT}:$(whoami)" | pwd_hash | cut -c1-8)
```

Same for the `pre-review` skill (which documents how to create the marker) — today the skill says to
hash `$PWD`, which has the same flaw. Additionally: the skill and the hook disagree on `printf` vs
`echo` — harmless only because `pwd_hash` does `tr -d '\n'`; unify on `printf` for clarity.

## A second case from practice (2026-07-16, same session)

The session cwd pointed at a **deleted mktemp directory** (a previous command did `cd "$W" && ... &&
rm -rf "$W"`) — the hook hashed a ghost path and blocked the commit despite a fresh review.
Normalizing to `git rev-parse --show-toplevel` also fixes this variant (fallback when git fails:
block with an "unknown cwd" message, not with a misleading "no review").

## Acceptance test

1. `/pre-review` at the repo root → marker created.
2. `cd subdirectory` (as a separate command) → `cd root && git commit` → MUST pass.
3. A commit in a repo with no marker → still blocked.

## Bonus (found along the way)

The marker is not consumed after a commit — one review "unlocks" every subsequent commit in the
session, forever. Consider: marker `mtime` < N minutes, or deleting the marker in PostToolUse after a
successful commit (a deliberate trade-off between friction and rigor).
