#!/usr/bin/env python3
"""Deterministic noise generator for XL brownfield fixtures.

Usage: gen-noise.py <fixture-dir> <n-files> <style>
  style: mixed  — half throwing / half result-object conventions (for errors task)
         plain  — neutral helpers, no error/money semantics (for cents task)

Seeded PRNG → identical output on every run (reproducible fixtures).
"""
import random
import sys
from pathlib import Path

DOMAINS = ["inventory", "shipping", "analytics", "catalog", "search", "profile",
           "notifications", "reports", "sessions", "audit", "webhooks", "feeds"]
VERBS = ["load", "sync", "resolve", "merge", "index", "archive", "publish",
         "refresh", "collect", "trace"]
NOUNS = ["record", "batch", "entry", "snapshot", "bundle", "segment", "queue",
         "draft", "revision", "chunk"]

THROW_TMPL = """export async function {fn}({arg}) {{
  if (!{arg}) throw new Error('missing {arg}');
  return {{ {arg}, processedAt: {seed} }};
}}
"""
RESULT_TMPL = """export async function {fn}({arg}) {{
  if (!{arg}) return {{ ok: false, error: 'MISSING_{argU}' }};
  return {{ ok: true, value: {{ {arg}, processedAt: {seed} }} }};
}}
"""
PLAIN_TMPL = """export function {fn}({arg}) {{
  return String({arg}).trim().toLowerCase() + '-{suffix}';
}}
"""

def main():
    fixture, n, style = Path(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    rng = random.Random(42)
    made = 0
    while made < n:
        domain = rng.choice(DOMAINS)
        verb, noun = rng.choice(VERBS), rng.choice(NOUNS)
        fn = f"{verb}{noun.capitalize()}"
        path = fixture / "src" / domain / f"{verb}-{noun}.js"
        if path.exists():
            continue
        arg = rng.choice(["id", "key", "ref", "name"])
        if style == "mixed":
            tmpl = THROW_TMPL if rng.random() < 0.5 else RESULT_TMPL
        else:
            tmpl = PLAIN_TMPL
        body = tmpl.format(fn=fn, arg=arg, argU=arg.upper(),
                           seed=rng.randint(1000, 9999),
                           suffix=rng.randint(10, 99))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"// {domain} helpers.\n\n{body}")
        made += 1

    # A few trivially-passing noise tests so test/ looks alive but stays fast.
    (fixture / "test").mkdir(parents=True, exist_ok=True)
    for i in range(1, 6):
        t = fixture / "test" / f"noise-{i}.test.js"
        t.write_text(
            "import { test } from 'node:test';\n"
            "import assert from 'node:assert/strict';\n\n"
            f"test('noise invariant {i}', () => {{ assert.equal({i} + {i}, {2*i}); }});\n")
    print(f"generated {made} src files + 5 noise tests in {fixture}")

if __name__ == "__main__":
    main()
