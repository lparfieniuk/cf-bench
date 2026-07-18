# RESEARCH: Biblioteki-cele dla cf-bench (2026-07-18)

Pytanie: które biblioteki/stacki testować? Dwie listy (popularność / trudność dla AI),
model scoringu, rekomendacja procesu. Źródła na końcu.

## Lista A — najpopularniejsze biblioteki/frameworki (ranking wg adopcji 2025/26)

JS/TS (SO Survey 2025, State of JS, npm weekly):
1. React (~45% dev, 133M dl/tydz) 2. Node/Express (18M dl/tydz) 3. Next.js 4. Angular (~18%)
5. Vue (~17.6%) 6. jQuery (legacy, wciąż ogromny) 7. TypeScript (język-warstwa) 8. Vite (84M)
9. RxJS (rdzeń Angular) 10. Svelte (7.2%, retencja 91%) 11. Nx/monorepo tooling 12. NestJS
13. Redux/Zustand/TanStack Query 14. Jest/Vitest 15. Karma/Jasmine (legacy Angular)
16. Cypress/Playwright 17. Tailwind 18. styled-components/emotion 19. React Router
20. Axios/fetch wrappers 21. Lodash 22. date-fns/dayjs/moment(legacy) 23. Zod 24. Prisma
25. Drizzle 26. Socket.io 27. GraphQL/Apollo 28. tRPC 29. Electron 30. React Native/Expo

Python (PyPI top, JetBrains State of Python 2025):
31. requests 32. pandas 33. numpy 34. Flask (1.16B dl/rok) 35. Django 36. FastAPI (najszybciej
rosnący) 37. pydantic 38. SQLAlchemy 39. pytest 40. scikit-learn 41. PyTorch 42. LangChain
(szybki churn API!) 43. Celery 44. boto3

Inne ekosystemy: 45. Spring Boot (Java) 46. .NET/ASP.NET Core 47. Laravel (PHP) 48. Rails
49. Go stdlib/net/http 50. Rust actix/tokio

## Lista B — najtrudniejsze dla AI (ranking wg badań + mechanizm trudności)

Języki:
1. **CUDA** — najniższe CRR/CGRE ze wszystkich slice'ów (PerfCodeBench)
2. **COBOL** — "catastrophic results", błędy składni (graded-exercises study)
3. **Fortran** — dramatyczny spadek jakości
4. **Rust** — lifetimes, Pin/async, trait bounds; najczęściej niekompilowalne sugestie
5. **C++** — UB, manual memory, template errors; modele nie przewidują zachowania buggy code
6. **Embedded C / ESP-IDF** — EmbedBench: 29.4% pass (vs 73.8% MicroPython)
7. Haskell/OCaml/F# — funkcyjne, low-resource w treningu
8. Zig, 9. Erlang/Elixir (OTP), 10. Solidity (security-critical)

Biblioteki/mechanizmy trudności (badania nad API evolution — arXiv 2604.09515, ICSE'25):
11. **Szybki churn API**: LangChain (miesięczne breaking changes), Next.js App Router,
    React Server Components, Tailwind v4, Angular signals/standalone (16-19), Svelte 5 runes
12. **Deprecated-API trap**: modele trzymają się starych API mimo dokumentacji ("stale
    parametric knowledge"); >50% porażek = złe użycie API (26.6% złe parametry, 16%
    halucynowane zachowanie); nowe API → halucynacja nieistniejącego w 63% przypadków
13. **Halucynacje pakietów**: 19.7% rekomendowanych pakietów nie istnieje (slopsquatting)
14. Wersjonowanie: Vue 2→3, Angular NgModules→standalone, Express 4→5, Pydantic 1→2,
    SQLAlchemy 1.x→2.0, React class→hooks→RSC — kod treningowy miesza epoki
15. Concurrency: goroutine leaks, asyncio pitfalls, RxJS operator semantics (zmierzone
    u nas: A 0/5), thread-safety w C++/Java

## Model scoringu celu (dla nas)

score = popularność(0-3) × trudność-dla-AI(0-3) × testowalność-deterministyczna(0-3) × fit-niszy(1-2)

Testowalność (nasze twarde ograniczenie): wendorowalne bez toolchainu? check.sh = exit code?
zero sieci? — CUDA/COBOL/embedded odpadają mimo trudności (nie uruchomimy w mktemp);
Rust/Go możliwe (kompilator = idealny deterministyczny check!), ale wymagają toolchainu
lokalnego (rustc/go w PATH — do decyzji jak node_modules cache).

**Top 10 celów wg score** (uzasadnienie w nawiasie):
1. **RxJS** (zmierzone p=0.008; nisza Lukasza; wendorowalne) — ROZSZERZAĆ: catchError,
   takeUntil/teardown, share/shareReplay, scheduler
2. **Angular 16→20 migracje** (signals, standalone, control flow — churn + nisza + version-drift
   trap: model pisze NgModules) — czeka na node_modules cache
3. **Express→5 / middleware order** (18M dl/tydz; wendorowane już)
4. **Pydantic 1→2 / FastAPI** (python3 stdlib runner wystarczy? pydantic wendorowalny przez
   pip install --target; deprecated-API trap klasyczny)
5. **Next.js App Router vs Pages** (największy churn w najpopularniejszym meta-frameworku;
   ciężki toolchain — statyczne checki?)
6. **React hooks konwencje** (exhaustive-deps, RSC boundary) — jsdom-less testy reducerów OK
7. **Zod/walidacja** (wendorowalne, konwencje schema-first vs inline)
8. **date-fns vs moment** (deprecated-trap: model sięga po moment) — wendorowalne
9. **SQLAlchemy 2.0 style** (Session.execute vs legacy Query) — sqlite in-memory = deterministyczne
10. **LangChain pinned-version** (churn ekstremalny; regression-watch story — "config
    przypina wzorce wersji") — pip --target

## Rekomendacja procesu: ręcznie z szablonów, NIE auto

Auto-generacja zadań = pułapka wiarygodności: (a) zadanie bez ludzkiej kalibracji nie ma
gwarancji dyskryminacji (nasze N=5 gate'y właśnie temu służą — 3 z 10 zadań przeszły
reklasyfikację po pomiarze!); (b) LLM generujący pułapki na LLM = ten sam prior, ślepe pola
wspólne; (c) metrics-first zasada. Zamiast tego **pipeline półautomatyczny**:

1. Szablon pułapki (mamy 4 zwalidowane wzorce: encoded-decision, local-lie@scale,
   library-convention, config-lies) + lista celów z tego dokumentu
2. Generacja szkicu fixture'a przez agenta (tanie) → ludzki przegląd GAP/HYPOTHESIS
3. Bramki automatyczne (już zbudowane): validate-tasks (oracle), sanity anty-wzorca,
   smoke → kalibracja N=5 → w widełkach klasy albo reklasyfikacja
4. Dopiero po kalibracji zadanie wchodzi do zestawu publikowalnego

Stack-pack jako produkt: "cf-bench/angular-pack", "cf-bench/python-api-pack" — configi
klientów są per-stack, więc benchmark per-stack = oferta audytu per-stack. Zaczynamy od
**Angular/RxJS packa** (nisza + zmierzony sukces rxjs-009), nie od 50 bibliotek naraz.

## Źródła

- Popularność JS: SO Survey 2025 (React 44.7%/Angular 18.2%/Vue 17.6%/Svelte 7.2%),
  kvassiliou.com/tech/best-javascript-frameworks-2026, pkgpulse.com npm trends,
  strapi.io/blog/best-javascript-frameworks
- Popularność Python: blog.jetbrains.com State of Python 2025, pypistats.org/top,
  rollbar.com/blog/python-backend-frameworks
- Trudność językowa: arxiv.org/pdf/2410.16292 (graded exercises: COBOL/Fortran/Rust),
  arxiv.org/pdf/2605.15222 (PerfCodeBench: CUDA), arxiv.org/pdf/2502.11167 (SURGE: C++),
  mdpi.com EmbedBench (ESP-IDF 29.4%), langpop.com/blog/which-languages-do-llms-write-best
- API evolution/halucynacje: arxiv.org/html/2604.09515v1 (knowledge conflicts, 63%
  halucynacja nowych API), wang2025icse (deprecated APIs), 19.7% pakietów halucynowanych
  (slopsquatting, Lakera/Medium)
