# Roadmapa cf-bench (stan: 2026-07-18 po rozbudowie rxjs-packa i regule kontestowanego prioru)

Teza: **nie sprzedajemy reguł — sprzedajemy dowód, że config działa.**
Ścieżka: OSS harness → leaderboard/publikacje → płatny regression-watch + audyty.

## ✅ Zrobione (Faza 0 + rygor + library-pack start)

- Harness A/B(+C): runner (izolacja `--setting-sources project`, pinowany model, sanity gate,
  ukryte asercje, obsługa nieodbytych runów, circuit breaker, `cli_version` w TSV,
  per-task `VARIANTS` + `CONFIG_<X>`), smoke test, TSV + summarize
- **Rygor statystyczny**: Wilson 95% CI + Fisher exact + pass^n w summarize; oracle solutions
  (`cf-bench/oracles/`) + `validate-tasks.sh` (outcome validity, egzekwowane w smoke)
- **10 zadań w 5 klasach** (rubryka: docs/TASK-DESIGN.md); 4 silne dyskryminatory z 4 różnych klas:
  - encoded-decision: js-stack-002 (N=10: A 0% vs B 100%, p=2.4e-06)
  - local-lie@scale: js-brown-cents-xl-007 (N=15/10: A 7% vs B 100%, p=2.1e-07)
  - config-lies: js-config-lies-008 (N=5: A 100% vs B 0%, p=0.008 — kłamiący config ODWRACA
    wynik, taniej o 9.8%; "cheaper, faster, confidently wrong")
  - library-convention: js-rxjs-submit-009 (N=5: A 0% vs B 100%, p=0.008 — flip na MAŁYM
    fixture, bez szumu; wybór operatora rxjs niewywnioskowalny z sąsiedztwa)
- Wariant **C (placebo)**: configs/generic/, włączony na js-stack-002 — obrona przed
  "sami napisaliście configi" (C≈A = efekt to wiedza, nie obecność pliku). NIEZMIERZONY.
- Library-pack technika: wendorowane node_modules (rxjs 4.5MB, express 3.9MB), zero npm install;
  express-010 zreklasyfikowany cost-only (A 5/5, sygnał app.js za mocny w małym repo)
- Researche: `RESEARCH-AI-BENCHMARKS-2026-07-17.md` (SWE-bench kontaminacja, Terminal-Bench
  oracle, tau-bench pass^k, HAL, SkillsBench/ETH jako walidacja niszy i timing publikacji),
  `RESEARCH-LIBRARY-TARGETS-2026-07-18.md` (listy popularność/trudność-dla-AI, scoring,
  top-10 celów, proces półautomatyczny z ludzką kalibracją — NIE auto-generacja)
- Draft artykułu v2 (`content/draft-brownfield-traps.md`) — czeka na recenzję Lukasza
- Rutyna researchowa (program + skrypt + launchd instrukcja), 2 sugestie dla context-forge
- Łączny koszt eksperymentów dotąd: ~$25

## ✅ Dowiezione 2026-07-18 (sesja rxjs-pack, ~$7)

- 5 nowych zadań skalibrowanych N=5: 011 catchError (cost-only −18.7%), 012 withLatestFrom
  (MARTWE: Δ=0 — usunąć/wymienić przed zamrożeniem), 013 shareReplay (cost-only −8.9%),
  014 express-XL (cost-at-scale −28.6%, tury 16→9; hipoteza "middleware słabnie ze skalą"
  OBALONA), **015 refresh-exhaustMap: A 60% vs B 100%, Δ+40pp — w widełkach klasy 2**
- **Reguła kontestowanego prioru** (TASK-DESIGN): dyskryminuje tylko polityka SPRZECZNA
  z priorem treningowym; kanoniczne konwencje = zawsze cost-only. Litmus: "czy senior bez
  kontekstu firmy odpowie jednoznacznie?" TAK → nie buduj. Potwierdzona testem kontrolnym 015.
- takeUntil/teardown odrzucone świadomie: nierozróżnialne behawioralnie (unsubscribe ≡ takeUntil)

## 🔜 Najbliższe (kolejność rekomendowana)

1. **Decyzja o 012** (usunąć vs przeprojektować na kontestowane) + ewentualnie 1–2 zadania
   z pre-filtrem kontestowanego prioru (kandydaci: debounce-vs-throttle dla scroll,
   startWith-vs-initial-state, retry-fetch policy)
2. **Zamrożenie zestawu → finalna macierz N=10 z wariantem C** na wszystkich zadaniach
   dyskryminujących + C na flagshipach, jedna świeża macierz (spójna wersja CLI);
   szacunek ~$30–40 [BUDŻET — zgoda przed startem]
3. **[LUKASZ] Recenzja draftu** + decyzja: sekcja config-lies w drafcie czy osobny post
4. **Open-source prep** (warunek Show HN): wydzielone publiczne repo, licencja (MIT?),
   README EN, surowe TSV, skrypt reprodukcji; decyzja held-out (część zadań prywatna —
   wzorzec SWE-bench Pro)
5. **Publikacja**: dev.to → Show HN → r/ClaudeAI, X; playbook z GTM doc
6. **[LUKASZ, 5 min] launchd** dla research-scan (`research-routine/README-SCHEDULING.md`)

## 📦 Faza następna (po publikacji)

- **Angular/Nx brownfield fixture** — decyzja techniczna: cache `node_modules` między runami
  (kopiowanie ~300MB/run vs współdzielony store vs pnpm). Odblokowuje też React/Jest/Karma/
  Jasmine (za ciężkie do wendorowania) i Angular-migracje (signals vs NgModules —
  version-drift trap, top-2 na liście celów)
- **Python-api-pack**: Pydantic 1→2, FastAPI, SQLAlchemy 2.0 (pip --target = wendorowalne;
  deprecated-API trap — modele trzymają się starych wzorców, >50% porażek = złe użycie API)
- **Cross-agent**: adapter Codex CLI / Cursor CLI; wymaga abstrakcji `agent adapter` w runnerze
- **Multi-model**: haiku/opus — czy tania inteligencja zmienia taksonomię pułapek?
- Dalsze klasy: stale docs (README kłamie), martwe ścieżki kodu, LangChain version-pinning
  (regression-watch story)

## 💰 Monetyzacja (gated — patrz RESEARCH-BENCHMARK-MONETIZATION)

- **Gate 1**: publikacja przynosi trakcję (gwiazdki/dyskusję) → leaderboard configów
- **Gate 2**: 1 płacący klient (regression-watch $19–99/mies. albo audyt $300–1500) **zanim**
  powstanie cokolwiek hosted
- Stack-packi jako oferta audytu per-stack (Angular/RxJS pack pierwszy — nisza Lukasza)
- Regression-watch MVP: cron + cf-bench na configu klienta po każdym update modelu/CLI + delta

## 🔧 Dla context-forge (kolejka w context-forge-suggestions/)

- CF-001: skill `/research-scan` (ciągły research)
- CF-002: fix hooka pre-commit-review (hash cwd → git toplevel; 2 udokumentowane przypadki)

## Zasady niezmienne

Metrics-first (żadnych twierdzeń bez pomiaru) · determinizm oceny (nigdy LLM-judge) ·
local-first, flat files · hosted dopiero po pierwszym płacącym kliencie · budżet runów za zgodą ·
zadanie wchodzi do zestawu TYLKO po kalibracji (N≥5 w widełkach klasy).
