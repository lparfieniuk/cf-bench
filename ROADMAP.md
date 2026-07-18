# Roadmapa cf-bench (stan: 2026-07-17, po research benchmarków + upgrade rygoru)

Teza: **nie sprzedajemy reguł — sprzedajemy dowód, że config działa.**
Ścieżka: OSS harness → leaderboard/publikacje → płatny regression-watch + audyty.

## ✅ Zrobione (Faza 0)

- Harness A/B: runner (izolacja `--setting-sources project`, pinowany model, sanity gate,
  ukryte asercje, obsługa nieodbytych runów, circuit breaker), smoke test, TSV + summarize
- 7 zadań w 4 zweryfikowanych klasach; rubryka projektowa potwierdzona danymi
- **Wyniki N=10** (Fisher p<1e-4): zero-signal A 0/10 vs B 10/10; local-lie@scale A 1/10 vs B 10/10;
  grep-findable = cost-only (−50% @ 120 plikach). Łączny koszt eksperymentów ~$21
- Draft artykułu v2 (`content/draft-brownfield-traps.md`) — czeka na recenzję Lukasza
- Rutyna researchowa (program + skrypt + launchd instrukcja), 2 sugestie dla context-forge
- **Research benchmarków AI** (`RESEARCH-AI-BENCHMARKS-2026-07-17.md`): SWE-bench (kryzys
  kontaminacji), Terminal-Bench (oracle solutions), tau-bench (pass^k), HAL (cost-aware),
  SkillsBench + ETH AGENTS.md + "context files hurt" (walidacja tezy i timing publikacji)
- **Upgrade rygoru wg research**: summarize.sh z Wilson 95% CI + Fisher exact + pass^n;
  oracle solutions (`cf-bench/oracles/`) + `validate-tasks.sh` (outcome validity, w smoke);
  nowa klasa zadań **config-lies** (js-config-lies-008, kalibracja czeka na budżet)

## 🔜 Najbliższe (kolejność rekomendowana)

1. **[LUKASZ] Recenzja draftu** — bez tego nie ruszamy publikacji
2. **Open-source prep** (warunek Show HN): wydzielone publiczne repo cf-bench, licencja (MIT?),
   README EN z metodologią, surowe TSV w repo, skrypt reprodukcji; przejście `plugin-audit`-owego
   poziomu rygoru na kod publiczny
3. **Publikacja**: dev.to (pełny tekst) → Show HN (`Show HN: I set traps for AI coding agents...`)
   → r/ClaudeAI, X thread; wg playbooka z GTM doc (odpowiadanie w pierwszej godzinie HN)
4. **[LUKASZ, 5 min] launchd** dla cotygodniowego research-scan (`research-routine/README-SCHEDULING.md`)
5. ✅ **Kalibracja config-lies (2026-07-18)**: A 100% vs B 0% (N=5, p=0.008), koszt B −9.8% —
   agent nigdy nie kwestionuje kłamiącego configu ("taniej i pewniej, ale źle"). Kandydat na
   sekcję draftu / osobny post; wzmacnia produkt audytowy
6. **[BUDŻET ~$1.5] Wariant C (placebo) na flagship** — js-stack-002, N=10 wariant C;
   domyka zarzut "sami napisaliście configi"

## 📦 Faza następna (po publikacji)

- ✅ **Library-pack start (2026-07-18)**: rxjs (exhaustMap dla submitów) + express (next(err)
  do centralnego middleware) — biblioteki wendorowane do fixtures, zero npm install.
  Wzorzec: konwencja użycia biblioteki, nie znajomość API. **Kalibracja N=5: rxjs
  A 0/5 vs B 5/5 (p=0.008) — pełny dyskryminator bez skali; express A 5/5 = cost-only
  (−7.9%), kandydat na XL.** Nowe klasy-kandydatki: rxjs error-handling (catchError
  w pipe), rxjs teardown (takeUntil), express middleware order.
- **Library targets zbadane** (`RESEARCH-LIBRARY-TARGETS-2026-07-18.md`): top-10 celów wg
  score popularność×trudność×testowalność×nisza; proces = szablony + ludzka kalibracja
  (NIE auto-generacja); produktowo: stack-packi (Angular/RxJS pack pierwszy)
- **Angular/Nx brownfield fixture** — wejście w niszę docelową; decyzja techniczna do podjęcia:
  cache `node_modules` między runami (kopiowanie ~300MB/run vs współdzielony store vs pnpm).
  Ta sama decyzja odblokowuje React/Jest/Karma/Jasmine (za ciężkie do wendorowania)
- **Cross-agent**: adapter na Codex CLI / Cursor CLI (przewaga, której Anthropic nie zrobi);
  wymaga abstrakcji `agent adapter` w runnerze — dopiero wtedy, nie wcześniej
- **Multi-model**: te same zadania na haiku/opus — czy tania inteligencja zmienia taksonomię?
- Dalsze klasy zadań: stale dokumentacja (README kłamie), martwe ścieżki kodu, konflikt
  CLAUDE.md vs rzeczywistość (config też może kłamać — miara zaufania)

## 💰 Monetyzacja (gated — patrz RESEARCH-BENCHMARK-MONETIZATION)

- **Gate 1**: publikacja przynosi trakcję (gwiazdki/dyskusję) → budować leaderboard configów
- **Gate 2**: 1 płacący klient (regression-watch $19–99/mies. albo audyt $300–1500) **zanim**
  powstanie cokolwiek hosted
- Regression-watch MVP: cron + cf-bench na configu klienta po każdym update modelu/CLI + raport delta

## 🔧 Dla context-forge (kolejka w context-forge-suggestions/)

- CF-001: skill `/research-scan` (ciągły research)
- CF-002: fix hooka pre-commit-review (hash cwd → git toplevel; 2 udokumentowane przypadki)

## Zasady niezmienne

Metrics-first (żadnych twierdzeń bez pomiaru) · determinizm oceny (nigdy LLM-judge) ·
local-first, flat files · hosted dopiero po pierwszym płacącym kliencie · budżet runów za zgodą.
