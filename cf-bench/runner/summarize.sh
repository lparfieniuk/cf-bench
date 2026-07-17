#!/usr/bin/env bash
# Aggregate one or more result TSVs: per task+variant medians, Wilson 95% CI,
# pass^n (all-repeats reliability), B-vs-A delta with Fisher exact p.
set -euo pipefail
python3 - "$@" <<'PY'
import csv, math, statistics as st, sys

rows = []
for path in sys.argv[1:]:
    with open(path) as f:
        rows += [r for r in csv.DictReader(f, delimiter="\t")]
if not rows:
    sys.exit("no rows")

def med(sel, key, cast=float):
    vals = [cast(r[key]) for r in sel if r[key] not in ("", None)]
    return st.median(vals) if vals else None

def wilson(k, n, z=1.96):
    # 95% CI for a binomial proportion; sane at k=0 and k=n (unlike normal approx).
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    m = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return ((c - m) / d, (c + m) / d)

def fisher_two_sided(a, b, c, d):
    # Exact hypergeometric sum over tables with the observed margins.
    n = a + b + c + d
    r1, c1 = a + b, a + c
    def pmf(x):
        return (math.comb(c1, x) * math.comb(n - c1, r1 - x)) / math.comb(n, r1)
    p_obs = pmf(a)
    lo, hi = max(0, r1 + c1 - n), min(r1, c1)
    return min(1.0, sum(pmf(x) for x in range(lo, hi + 1) if pmf(x) <= p_obs * (1 + 1e-9)))

# Rows with empty success never executed (API error / rate limit) — report and exclude.
invalid = [r for r in rows if r["success"] == ""]
rows = [r for r in rows if r["success"] != ""]
if invalid:
    print(f"UWAGA: {len(invalid)} runów nieodbytych (api_error/limit) — wykluczone z agregacji.\n")
if not rows:
    sys.exit("no valid rows")

tasks = sorted({r["task"] for r in rows})
hdr = f'{"task":<24}{"var":<5}{"n":<4}{"succ%":<7}{"95%CI":<12}{"pass^n":<7}{"med_cost$":<11}{"med_turns":<11}{"med_out_tok":<12}{"med_dur_s":<10}'
print(hdr)
for t in tasks:
    stats = {}
    for v in ("A", "B"):
        sel = [r for r in rows if r["task"] == t and r["variant"] == v]
        if not sel:
            continue
        k, n = sum(r["success"] == "1" for r in sel), len(sel)
        lo, hi = wilson(k, n)
        stats[v] = dict(
            k=k, n=n, succ=100 * k / n,
            cost=med(sel, "cost_usd") or 0, turns=med(sel, "turns") or 0,
            out=med(sel, "out_tokens") or 0, dur=(med(sel, "duration_ms") or 0) / 1000,
        )
        s = stats[v]
        ci = f"{100*lo:.0f}-{100*hi:.0f}"
        passn = "1" if k == n else "0"
        print(f'{t:<24}{v:<5}{n:<4}{s["succ"]:<7.0f}{ci:<12}{passn:<7}{s["cost"]:<11.4f}{s["turns"]:<11.0f}{s["out"]:<12.0f}{s["dur"]:<10.1f}')
    if "A" in stats and "B" in stats:
        a, b = stats["A"], stats["B"]
        dcost = 100 * (b["cost"] - a["cost"]) / a["cost"] if (a["cost"] and b["cost"]) else 0
        p = fisher_two_sided(b["k"], b["n"] - b["k"], a["k"], a["n"] - a["k"])
        print(f'{t:<24}{"Δ B-A":<5}{"":<4}{b["succ"]-a["succ"]:<+7.0f}{"p="+format(p, ".3g"):<12}{"":<7}{dcost:<+11.1f}%')

print("\nmediany; succ% = pass rate, CI = Wilson 95%; pass^n = 1 gdy WSZYSTKIE n runów")
print("przeszły (niezawodność à la tau-bench pass^k); p = Fisher exact (two-sided) dla")
print("sukcesu B vs A. N<10 → kierunkowo; p<0.05 przy N≥10 → raportowalne.")
PY
