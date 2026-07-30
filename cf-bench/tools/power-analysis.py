#!/usr/bin/env python3
"""Power analysis for cf-bench A/B calibration: what N per arm can detect what effect?

Model: success ~ Binomial(N, p) per arm; test = Fisher exact (two-sided), alpha=0.05
(the exact test summarize.sh uses). Power = P(p < alpha) over all outcome pairs.
Also prints Wilson 95% CI width for a perfect arm (k=N) — the "certainty" N buys.
Stdlib only.
"""
import math

ALPHA = 0.05


def fisher_two_sided(a, b, c, d):
    """Two-sided Fisher exact p for table [[a, b], [c, d]] (successes/failures per arm)."""
    n = a + b + c + d
    row1, col1 = a + b, a + c

    def hyper(x):
        return (math.comb(col1, x) * math.comb(n - col1, row1 - x)
                / math.comb(n, row1))

    p_obs = hyper(a)
    lo, hi = max(0, row1 - (n - col1)), min(row1, col1)
    return sum(p for p in (hyper(x) for x in range(lo, hi + 1))
               if p <= p_obs * (1 + 1e-9))


def binom_pmf(k, n, p):
    return math.comb(n, k) * p**k * (1 - p)**(n - k)


def power(n, pa, pb):
    total = 0.0
    for ka in range(n + 1):
        wa = binom_pmf(ka, n, pa)
        for kb in range(n + 1):
            if fisher_two_sided(ka, n - ka, kb, n - kb) < ALPHA:
                total += wa * binom_pmf(kb, n, pb)
    return total


def wilson(k, n, z=1.96):
    p = k / n
    den = 1 + z**2 / n
    mid = (p + z**2 / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z**2 / (4 * n**2)) / den
    return mid - half, mid + half


if __name__ == "__main__":
    scenarios = [(0.0, 1.0, "full flip (009, 002)"),
                 (0.1, 1.0, "near-flip (007)"),
                 (0.6, 1.0, "class-2 band (015)"),
                 (0.4, 0.9, "weaker discriminator"),
                 (0.7, 1.0, "small effect")]
    ns = [5, 10, 15, 20, 25, 50, 100]

    print("Power (P[Fisher p<0.05]) for true pA vs pB, N per arm:")
    print("scenario" + "\t" + "\t".join(f"N={n}" for n in ns))
    for pa, pb, label in scenarios:
        row = [f"{power(n, pa, pb):.2f}" for n in ns]
        print(f"{label} ({pa:.0%} vs {pb:.0%})\t" + "\t".join(row))

    print("\nWilson 95% CI at an observed 100% success rate (N/N):")
    for n in ns:
        lo, hi = wilson(n, n)
        print(f"  N={n}: [{lo:.0%}, {hi:.0%}]  width {100*(hi-lo):.0f}pp")

    print("\nCost (median ~$0.14/run rxjs, ~$0.24/run XL), 2 arms, per task:")
    for n in ns:
        print(f"  N={n}: rxjs ~${2*n*0.14:.0f}, XL ~${2*n*0.24:.0f}")
