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

def vals(sel, key, cast=float):
    return [cast(r[key]) for r in sel if r[key] not in ("", None)]

def med(sel, key, cast=float):
    v = vals(sel, key, cast)
    return st.median(v) if v else None

def mannwhitney_p(x, y):
    # Two-sided Mann-Whitney U on a CONTINUOUS outcome (cost, turns). Fisher exact
    # answers "did the pass rate move" — on a cost-only task every arm is 100% so
    # Fisher returns p=1 and says nothing about the cost delta, which is the whole
    # outcome there. Normal approximation with tie correction + continuity
    # correction; adequate at n>=8 per arm, which is the reporting threshold anyway.
    n1, n2 = len(x), len(y)
    if n1 == 0 or n2 == 0:
        return 1.0
    merged = sorted([(v, 0) for v in x] + [(v, 1) for v in y])
    ranks = [0.0] * len(merged)
    tie_groups, i = [], 0
    while i < len(merged):
        j = i
        while j + 1 < len(merged) and merged[j + 1][0] == merged[i][0]:
            j += 1
        avg = (i + j) / 2 + 1
        for k in range(i, j + 1):
            ranks[k] = avg
        tie_groups.append(j - i + 1)
        i = j + 1
    r1 = sum(ranks[k] for k in range(len(merged)) if merged[k][1] == 0)
    u1 = r1 - n1 * (n1 + 1) / 2
    n = n1 + n2
    mu = n1 * n2 / 2
    tie_term = sum(t ** 3 - t for t in tie_groups)
    var = n1 * n2 / 12 * ((n + 1) - tie_term / (n * (n - 1))) if n > 1 else 0
    if var <= 0:
        return 1.0
    z = (abs(u1 - mu) - 0.5) / math.sqrt(var)
    return min(1.0, 2 * (1 - 0.5 * (1 + math.erf(z / math.sqrt(2)))))

def wilson(k, n, z=1.96):
    # 95% CI for a binomial proportion; sane at k=0 and k=n (unlike normal approx).
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    m = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (max(0.0, (c - m) / d), min(1.0, (c + m) / d))

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
    print(f"NOTE: {len(invalid)} runs never executed (api_error/limit) — excluded from the aggregate.\n")
if not rows:
    sys.exit("no valid rows")

tasks = sorted({r["task"] for r in rows})
hdr = f'{"task":<24}{"var":<5}{"n":<4}{"succ%":<7}{"95%CI":<12}{"pass^n":<7}{"med_cost$":<11}{"med_turns":<11}{"med_out_tok":<12}{"med_dur_s":<10}'
print(hdr)
for t in tasks:
    stats = {}
    variants = sorted({r["variant"] for r in rows if r["task"] == t})
    for v in variants:
        sel = [r for r in rows if r["task"] == t and r["variant"] == v]
        if not sel:
            continue
        k, n = sum(r["success"] == "1" for r in sel), len(sel)
        lo, hi = wilson(k, n)
        stats[v] = dict(
            k=k, n=n, succ=100 * k / n,
            cost=med(sel, "cost_usd") or 0, turns=med(sel, "turns") or 0,
            out=med(sel, "out_tokens") or 0, dur=(med(sel, "duration_ms") or 0) / 1000,
            cost_v=vals(sel, "cost_usd"), turns_v=vals(sel, "turns"),
        )
        s = stats[v]
        ci = f"{100*lo:.0f}-{100*hi:.0f}"
        passn = "1" if k == n else "0"
        print(f'{t:<24}{v:<5}{n:<4}{s["succ"]:<7.0f}{ci:<12}{passn:<7}{s["cost"]:<11.4f}{s["turns"]:<11.0f}{s["out"]:<12.0f}{s["dur"]:<10.1f}')
    deltas = [v for v in variants if v != "A" and "A" in stats]
    if deltas:
        print(f'  {"delta":<22}{"Δsucc":<8}{"p_succ":<11}{"Δcost%":<9}{"p_cost":<11}{"Δturns%":<9}{"p_turns":<11}')
    for v in deltas:
        a, b = stats["A"], stats[v]
        dcost = 100 * (b["cost"] - a["cost"]) / a["cost"] if (a["cost"] and b["cost"]) else 0
        dturns = 100 * (b["turns"] - a["turns"]) / a["turns"] if (a["turns"] and b["turns"]) else 0
        p_succ = fisher_two_sided(b["k"], b["n"] - b["k"], a["k"], a["n"] - a["k"])
        p_cost = mannwhitney_p(b["cost_v"], a["cost_v"])
        p_turns = mannwhitney_p(b["turns_v"], a["turns_v"])
        print(f'  {"Δ"+v+"-A":<22}{b["succ"]-a["succ"]:<+8.0f}{format(p_succ, ".3g"):<11}'
              f'{dcost:<+9.1f}{format(p_cost, ".3g"):<11}{dturns:<+9.1f}{format(p_turns, ".3g"):<11}')

print("\nmedians; succ% = pass rate, CI = Wilson 95%; pass^n = 1 when ALL n runs passed")
print("(reliability à la tau-bench pass^k).")
print("p_succ = Fisher exact (two-sided) on SUCCESS — it speaks only about the pass rate.")
print("p_cost / p_turns = Mann-Whitney U (two-sided) on cost/turns. On cost-only tasks")
print("success is 100% in every arm, so p_succ=1 by definition — then p_cost is the")
print("ONLY result. Never read Δcost% without its own p.")
print("N<10 → directional; p<0.05 at N≥10 → reportable.")
PY
