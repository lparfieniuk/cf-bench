#!/usr/bin/env bash
# Aggregate one or more result TSVs: per task+variant medians and B-vs-A delta.
set -euo pipefail
python3 - "$@" <<'PY'
import csv, statistics as st, sys

rows = []
for path in sys.argv[1:]:
    with open(path) as f:
        rows += [r for r in csv.DictReader(f, delimiter="\t")]
if not rows:
    sys.exit("no rows")

def med(sel, key, cast=float):
    vals = [cast(r[key]) for r in sel if r[key] not in ("", None)]
    return st.median(vals) if vals else None

# Rows with empty success never executed (API error / rate limit) — report and exclude.
invalid = [r for r in rows if r["success"] == ""]
rows = [r for r in rows if r["success"] != ""]
if invalid:
    print(f"UWAGA: {len(invalid)} runów nieodbytych (api_error/limit) — wykluczone z agregacji.\n")
if not rows:
    sys.exit("no valid rows")

tasks = sorted({r["task"] for r in rows})
print(f'{"task":<24}{"var":<5}{"n":<4}{"success%":<10}{"med_cost$":<11}{"med_turns":<11}{"med_out_tok":<12}{"med_dur_s":<10}')
for t in tasks:
    stats = {}
    for v in ("A", "B"):
        sel = [r for r in rows if r["task"] == t and r["variant"] == v]
        if not sel:
            continue
        stats[v] = dict(
            n=len(sel),
            succ=100 * sum(r["success"] == "1" for r in sel) / len(sel),
            cost=med(sel, "cost_usd") or 0, turns=med(sel, "turns") or 0,
            out=med(sel, "out_tokens") or 0, dur=(med(sel, "duration_ms") or 0) / 1000,
        )
        s = stats[v]
        print(f'{t:<24}{v:<5}{s["n"]:<4}{s["succ"]:<10.0f}{s["cost"]:<11.4f}{s["turns"]:<11.0f}{s["out"]:<12.0f}{s["dur"]:<10.1f}')
    if "A" in stats and "B" in stats:
        a, b = stats["A"], stats["B"]
        dcost = 100 * (b["cost"] - a["cost"]) / a["cost"] if (a["cost"] and b["cost"]) else 0
        print(f'{t:<24}{"Δ B-A":<5}{"":<4}{b["succ"]-a["succ"]:<+10.0f}{dcost:<+11.1f}%')
print("\nmedians; success% = pass rate; Δcost in % of A. N<10 → traktuj kierunkowo, nie dowodowo.")
PY
