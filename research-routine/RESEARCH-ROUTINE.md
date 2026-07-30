# cf-bench Weekly Research Scan (program.md)

You are the research agent for cf-bench (a benchmark for coding-agent configs).
Perform ONE scan pass and stop. Budget: at most 15 web searches, ~10 minutes of work.

## Goal

Detect changes in the AI-agent evaluation/benchmark landscape that affect cf-bench, record what is new
in the local ai-knowledge database, and leave a short report.

## Step 1 — Scan the sources (WebSearch/WebFetch)

Search for what is NEW in the last 7 days:
1. The Anthropic engineering blog + the Claude Code changelog (new benchmark/eval features, Skill Creator changes)
2. Direct competition: AgentBench.app, claude-skills-benchmark, the Skill Creator plugin, **SkillsBench (arXiv 2602.12670 — watch for an expansion from "skills as a class" to per-repo configs)**, any new "benchmark your agent config" tooling
3. Neighbours: Headroom, promptfoo, Braintrust, Langfuse, Vals AI, LMArena — product/pricing/funding changes
4. Research: arXiv — the effectiveness of context files (AGENTS.md/CLAUDE.md), coding-agent evaluation, harness design
5. HN/Reddit: discussions of agent quality regressions after model updates (fuel for regression-watch)

## Step 2 — Deduplicate against the database

For every finding call `mcp__knowledge__search_knowledge` (with the key phrase).
If an entry exists and nothing has changed — skip it. Database: localhost:3711.

## Step 3 — Record what is new

New or changed findings: append them to the ai-knowledge database via the available MCP tool
(if the database is read-only over MCP — write them into the report under a
`## To add to ai-knowledge` section).
Tags: `cf-bench` plus whatever applies (`ai-tools`, `market-data`, `business`).

## Step 4 — Weekly report

Write `research-reports/scan-YYYY-MM-DD.md` inside the repo:
- **TL;DR** (3 sentences max): does anything threaten our niche or open an opportunity
- **Threats**: platform moves (Anthropic/Cursor/Nx) entering config measurement
- **Opportunities**: new pain points (regressions after updates), new research to cite
- **Suggested actions** (at most 3, prioritized)
- Sources as links

## Step 5 — Critical signal

If you find an existential threat (e.g. Anthropic expands Skill Creator to whole configs, or someone
ships exactly cf-bench with traction) — add this line at the very top of the report:
`⚠️ ALERT: <one sentence>`.

## Constraints

- NEVER modify files outside `research-reports/` and the ai-knowledge database.
- Do not repeat the contents of existing reports — only this week's delta.
- Mark doubtful claims `[unverified]`. Every claim carries a source link.
