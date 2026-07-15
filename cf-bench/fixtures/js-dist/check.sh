#!/usr/bin/env bash
# Success = tests pass AFTER a fresh build, like CI does. An agent that edited
# dist/ directly gets its change wiped here — the fix must live in src/.
cd "$(dirname "$0")" && npm run build >/dev/null 2>&1 && node --test >/dev/null 2>&1
