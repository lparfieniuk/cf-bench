# Roadmapa cf-bench (stan: 2026-07-17)

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

## 🔜 Najbliższe (kolejność rekomendowana)

1. **[LUKASZ] Recenzja draftu** — bez tego nie ruszamy publikacji
2. **Open-source prep** (warunek Show HN): wydzielone publiczne repo cf-bench, licencja (MIT?),
   README EN z metodologią, surowe TSV w repo, skrypt reprodukcji; przejście `plugin-audit`-owego
   poziomu rygoru na kod publiczny
3. **Publikacja**: dev.to (pełny tekst) → Show HN (`Show HN: I set traps for AI coding agents...`)
   → r/ClaudeAI, X thread; wg playbooka z GTM doc (odpowiadanie w pierwszej godzinie HN)
4. **[LUKASZ, 5 min] launchd** dla cotygodniowego research-scan (`research-routine/README-SCHEDULING.md`)

## 📦 Faza następna (po publikacji)

- **Angular/Nx brownfield fixture** — wejście w niszę docelową; decyzja techniczna do podjęcia:
  cache `node_modules` między runami (kopiowanie ~300MB/run vs współdzielony store vs pnpm)
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
