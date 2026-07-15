#!/usr/bin/env bash
# Success assertion for ts-mini: all node:test tests pass. Exit 0 = success.
cd "$(dirname "$0")" && node --test >/dev/null 2>&1
