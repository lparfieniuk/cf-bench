# RESEARCH: Target libraries for cf-bench (2026-07-18)

Question: which libraries/stacks should we test? Two lists (popularity / difficulty for AI), a scoring
model, and a process recommendation. Sources at the end.

## List A — most popular libraries/frameworks (ranked by 2025/26 adoption)

JS/TS (SO Survey 2025, State of JS, npm weekly):
1. React (~45% of devs, 133M dl/week) 2. Node/Express (18M dl/week) 3. Next.js 4. Angular (~18%)
5. Vue (~17.6%) 6. jQuery (legacy, still huge) 7. TypeScript (language layer) 8. Vite (84M)
9. RxJS (the core of Angular) 10. Svelte (7.2%, 91% retention) 11. Nx/monorepo tooling 12. NestJS
13. Redux/Zustand/TanStack Query 14. Jest/Vitest 15. Karma/Jasmine (legacy Angular)
16. Cypress/Playwright 17. Tailwind 18. styled-components/emotion 19. React Router
20. Axios/fetch wrappers 21. Lodash 22. date-fns/dayjs/moment(legacy) 23. Zod 24. Prisma
25. Drizzle 26. Socket.io 27. GraphQL/Apollo 28. tRPC 29. Electron 30. React Native/Expo

Python (PyPI top, JetBrains State of Python 2025):
31. requests 32. pandas 33. numpy 34. Flask (1.16B dl/year) 35. Django 36. FastAPI (fastest growing)
37. pydantic 38. SQLAlchemy 39. pytest 40. scikit-learn 41. PyTorch 42. LangChain (rapid API churn!)
43. Celery 44. boto3

Other ecosystems: 45. Spring Boot (Java) 46. .NET/ASP.NET Core 47. Laravel (PHP) 48. Rails
49. Go stdlib/net/http 50. Rust actix/tokio

## List B — hardest for AI (ranked by research + mechanism of difficulty)

Languages:
1. **CUDA** — the lowest CRR/CGRE of any slice (PerfCodeBench)
2. **COBOL** — "catastrophic results", syntax errors (graded-exercises study)
3. **Fortran** — a dramatic quality drop
4. **Rust** — lifetimes, Pin/async, trait bounds; the most frequently non-compiling suggestions
5. **C++** — UB, manual memory, template errors; models cannot predict the behaviour of buggy code
6. **Embedded C / ESP-IDF** — EmbedBench: 29.4% pass (vs 73.8% MicroPython)
7. Haskell/OCaml/F# — functional, low-resource in training
8. Zig, 9. Erlang/Elixir (OTP), 10. Solidity (security-critical)

Libraries / mechanisms of difficulty (API-evolution research — arXiv 2604.09515, ICSE'25):
11. **Rapid API churn**: LangChain (monthly breaking changes), Next.js App Router, React Server
    Components, Tailwind v4, Angular signals/standalone (16-19), Svelte 5 runes
12. **Deprecated-API trap**: models cling to old APIs despite the docs ("stale parametric knowledge");
    >50% of failures are wrong API usage (26.6% wrong parameters, 16% hallucinated behaviour);
    for new APIs → hallucinating something non-existent in 63% of cases
13. **Package hallucinations**: 19.7% of recommended packages do not exist (slopsquatting)
14. Versioning: Vue 2→3, Angular NgModules→standalone, Express 4→5, Pydantic 1→2, SQLAlchemy 1.x→2.0,
    React class→hooks→RSC — training code mixes the eras
15. Concurrency: goroutine leaks, asyncio pitfalls, RxJS operator semantics (measured here: A 0/5),
    thread-safety in C++/Java

## Target scoring model (for us)

score = popularity(0-3) × difficulty-for-AI(0-3) × deterministic-testability(0-3) × niche-fit(1-2)

Testability (our hard constraint): vendorable without a toolchain? check.sh = exit code? no network? —
CUDA/COBOL/embedded drop out despite the difficulty (we cannot run them inside a mktemp dir);
Rust/Go are possible (the compiler is a perfect deterministic check!) but need a local toolchain
(rustc/go on PATH — pending the same decision as the node_modules cache).

**Top 10 targets by score** (rationale in parentheses):
1. **RxJS** (measured p=0.008; vendorable) — EXPAND: catchError, takeUntil/teardown, share/shareReplay,
   schedulers
2. **Angular 16→20 migrations** (signals, standalone, control flow — churn plus a version-drift trap:
   the model writes NgModules) — waiting on the node_modules cache
3. **Express→5 / middleware order** (18M dl/week; already vendored)
4. **Pydantic 1→2 / FastAPI** (is the python3 stdlib runner enough? pydantic is vendorable via
   pip install --target; the classic deprecated-API trap)
5. **Next.js App Router vs Pages** (the largest churn in the most popular meta-framework; heavy
   toolchain — static checks?)
6. **React hooks conventions** (exhaustive-deps, the RSC boundary) — jsdom-less reducer tests are fine
7. **Zod/validation** (vendorable, schema-first vs inline conventions)
8. **date-fns vs moment** (deprecated trap: the model reaches for moment) — vendorable
9. **SQLAlchemy 2.0 style** (Session.execute vs the legacy Query) — in-memory sqlite is deterministic
10. **LangChain pinned-version** (extreme churn; the regression-watch story — "the config pins version
    patterns") — pip --target

## Process recommendation: by hand from templates, NOT automatically

Auto-generating tasks is a credibility trap: (a) a task without human calibration has no guarantee of
discriminating (our N=5 gates exist for exactly this — 3 of 10 tasks were reclassified after
measurement!); (b) an LLM generating traps for an LLM shares the same prior, and therefore the same
blind spots; (c) the metrics-first rule. Instead, a **semi-automatic pipeline**:

1. A trap template (we have 4 validated patterns: encoded-decision, local-lie@scale,
   library-convention, config-lies) plus the target list from this document
2. An agent drafts the fixture (cheap) → a human reviews the GAP/HYPOTHESIS
3. Automatic gates (already built): validate-tasks (oracle), anti-pattern sanity, smoke → N=5
   calibration → either inside the class band or reclassified
4. Only after calibration does the task enter the publishable set

Stack packs as a product: "cf-bench/angular-pack", "cf-bench/python-api-pack" — customer configs are
per-stack, so a per-stack benchmark is a per-stack audit offering. Start with the **Angular/RxJS pack**
(measured success on rxjs-009), not with 50 libraries at once.

## Sources

- JS popularity: SO Survey 2025 (React 44.7%/Angular 18.2%/Vue 17.6%/Svelte 7.2%),
  kvassiliou.com/tech/best-javascript-frameworks-2026, pkgpulse.com npm trends,
  strapi.io/blog/best-javascript-frameworks
- Python popularity: blog.jetbrains.com State of Python 2025, pypistats.org/top,
  rollbar.com/blog/python-backend-frameworks
- Language difficulty: arxiv.org/pdf/2410.16292 (graded exercises: COBOL/Fortran/Rust),
  arxiv.org/pdf/2605.15222 (PerfCodeBench: CUDA), arxiv.org/pdf/2502.11167 (SURGE: C++),
  mdpi.com EmbedBench (ESP-IDF 29.4%), langpop.com/blog/which-languages-do-llms-write-best
- API evolution/hallucinations: arxiv.org/html/2604.09515v1 (knowledge conflicts, 63% hallucination on
  new APIs), wang2025icse (deprecated APIs), 19.7% hallucinated packages (slopsquatting, Lakera/Medium)
