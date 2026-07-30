# Suggestion CF-001: a `/research-scan` skill (continuous research)

Status: PROPOSAL — to be analysed and implemented in the context-forge plugin repo, not here.
Origin: ai-tools session 2026-07-16; patterns: Anthropic's "multi-agent research system" and
"effective harnesses for long-running agents", plus Karpathy-style autoresearch
(program.md + a propose→run→evaluate→keep loop).

## Problem

A project's market and technical knowledge goes stale; deep research (Gemini/Claude) is stateless —
every report starts from zero, with no deduplication against what we already know and no continuous loop.

## Proposal

A new skill `core/skills/research-scan/` in context-forge:

1. **Input**: a scan program file (template: `research-routine/RESEARCH-ROUTINE.md` in this repo) —
   per project, defining sources, search budget, report format, and ALERT conditions.
2. **Flow**: scan sources → deduplicate via `mcp__knowledge__search_knowledge` (localhost:3711) →
   write what is new into ai-knowledge (per-project tags) → a delta report into `~/worklogs/research/` →
   signal `/evolve` when a finding concerns the plugin's rules or skills.
3. **Citation rigor** (lesson from an audit: a deep-research document carried a leftover genAI
   disclaimer): a separate verification step — every claim in the report needs a link; unverified ones
   get `[unverified]`.
4. **Scheduling**: launchd/cron + `claude -p` (template: `run-research-scan.sh` next to the routine).
   Consider a SessionStart hook: remind when the last scan is more than 7 days old.

## Acceptance criteria

- the skill passes `plugin-audit.sh` with a quality score ≥ 0.85
- the delta report does NOT repeat entries already in ai-knowledge (test: a second run the same day
  produces an empty report)
- a vitest test for the scripting logic (if a shell script ends up being written)

## Related

- Convention: the `context-forge-suggestions/` directory is the suggestion queue for the plugin;
  this repo works ONLY on the cf-bench benchmark.
- Stage 2 (once cf-bench exists): an autoresearch loop — proposed config changes measured by the
  benchmark, keeping only the improvements. A candidate for a `/config-evolve` skill.
