# cf-bench Weekly Research Scan (program.md)

Jesteś agentem researchowym projektu cf-bench (benchmark configów agentów kodujących).
Wykonaj JEDEN przebieg skanu i zakończ. Budżet: maks. 15 wyszukiwań web, ~10 min pracy.

## Cel

Wykryć zmiany w krajobrazie ewaluacji/benchmarków agentów AI, które wpływają na cf-bench,
zapisać nowości do lokalnej bazy ai-knowledge i zostawić krótki raport.

## Krok 1 — Skan źródeł (WebSearch/WebFetch)

Przeszukaj pod kątem NOWOŚCI z ostatnich 7 dni:
1. Anthropic engineering blog + changelog Claude Code (nowe funkcje benchmarku/evali, zmiany Skill Creator)
2. Konkurencja bezpośrednia: AgentBench.app, claude-skills-benchmark, Skill Creator plugin, **SkillsBench (arXiv 2602.12670 — obserwuj rozszerzenie z "skills jako klasa" na per-repo configi)**, nowe "benchmark your agent config" narzędzia
3. Sąsiedzi: Headroom, promptfoo, Braintrust, Langfuse, Vals AI, LMArena — zmiany produktowe/cenowe/funding
4. Badania: arXiv — skuteczność plików kontekstu (AGENTS.md/CLAUDE.md), ewaluacja agentów kodujących, harness design
5. HN/Reddit: dyskusje o regresjach jakości agentów po updatach modeli (paliwo dla regression-watch)

## Krok 2 — Deduplikacja przeciw bazie

Dla każdego znaleziska wywołaj `mcp__knowledge__search_knowledge` (fraza kluczowa).
Jeśli wpis istnieje i nic się nie zmieniło — pomiń. Baza: localhost:3711.

## Krok 3 — Zapis nowości

Nowe/zmienione znaleziska: dopisz do bazy ai-knowledge przez dostępne narzędzie MCP
(jeśli baza jest read-only przez MCP — zapisz do pliku raportu z sekcją `## Do dodania do ai-knowledge`).
Tagi: `cf-bench` + odpowiednie (`ai-tools`, `market-data`, `business`).

## Krok 4 — Raport tygodniowy

Zapisz `~/Projects/ai-tools/research-reports/scan-YYYY-MM-DD.md`:
- **TL;DR** (3 zdania max): czy coś zagraża naszej niszy / otwiera okazję
- **Zagrożenia**: ruchy platformy (Anthropic/Cursor/Nx) wchodzące w pomiar configów
- **Okazje**: nowe bóle (regresje po updatach), nowe badania do zacytowania
- **Akcje sugerowane** (maks. 3, z priorytetem)
- Źródła jako linki

## Krok 5 — Sygnał krytyczny

Jeżeli znajdziesz zagrożenie egzystencjalne (np. Anthropic rozszerza Skill Creator na całe configi,
ktoś wypuszcza dokładnie cf-bench z trakcją) — dodaj na początku raportu linię:
`⚠️ ALERT: <jedno zdanie>`.

## Ograniczenia

- NIGDY nie modyfikuj plików poza `research-reports/` i bazą ai-knowledge.
- Nie powtarzaj treści istniejących raportów — tylko delta tygodnia.
- Wątpliwe twierdzenia oznaczaj `[niezweryfikowane]`. Każde twierdzenie z linkiem źródłowym.
