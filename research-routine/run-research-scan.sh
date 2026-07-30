#!/usr/bin/env bash
# cf-bench weekly research scan — headless Claude Code run.
# Manual: bash run-research-scan.sh
# Scheduled (launchd, Mondays 08:57) — see README-SCHEDULING.md next to this file.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROUTINE="$REPO/research-routine/RESEARCH-ROUTINE.md"
LOG_DIR="$REPO/research-reports"
mkdir -p "$LOG_DIR"

claude -p "Run the weekly research scan: follow the instructions in $ROUTINE exactly" \
  --allowedTools "WebSearch,WebFetch,Read,Write,mcp__knowledge__search_knowledge,mcp__knowledge__get_entry,mcp__knowledge__search_by_tags,mcp__knowledge__list_tags,mcp__knowledge__recent_entries" \
  --max-turns 60 \
  >> "$LOG_DIR/.scan-runner.log" 2>&1 \
  || { echo "scan FAILED: $(date '+%F %T')" >> "$LOG_DIR/.scan-runner.log"; exit 1; }

echo "scan done: $(date '+%F %T')" >> "$LOG_DIR/.scan-runner.log"
