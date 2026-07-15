# Sugestia CF-001: skill `/research-scan` (ciągły research)

Status: PROPOZYCJA — do analizy i implementacji w repo `~/Projects/context-forge` (nie tutaj).
Źródło: sesja ai-tools 2026-07-16; wzorce: Anthropic "multi-agent research system" + "effective
harnesses for long-running agents", Karpathy autoresearch (program.md + pętla propose→run→evaluate→keep).

## Problem

Wiedza rynkowa/techniczna projektu się starzeje; deep research (Gemini/Claude) jest bezstanowy —
każdy raport od zera, brak deduplikacji przeciw temu co już wiemy, brak pętli ciągłej.

## Propozycja

Nowy skill `core/skills/research-scan/` w context-forge:

1. **Wejście**: plik programu skanu (wzór: `~/Projects/ai-tools/research-routine/RESEARCH-ROUTINE.md`) —
   per-projekt, definiuje źródła, budżet wyszukiwań, format raportu, warunki ALERT.
2. **Przebieg**: skan źródeł → deduplikacja przez `mcp__knowledge__search_knowledge` (localhost:3711) →
   zapis nowości do ai-knowledge (tagi per-projekt) → raport delta do `~/worklogs/research/` →
   sygnał do `/evolve` gdy znalezisko dotyczy reguł/skilli pluginu.
3. **Rygor cytowań** (lekcja z audytu: dokument z deep research zawierał resztkowy disclaimer genAI):
   osobny krok weryfikacji — każde twierdzenie w raporcie musi mieć link; niezweryfikowane → `[niezweryfikowane]`.
4. **Harmonogram**: launchd/cron + `claude -p` (wzór: `run-research-scan.sh` obok routine).
   Rozważyć hook SessionStart: przypomnienie gdy ostatni skan >7 dni.

## Kryteria akceptacji

- skill przechodzi `plugin-audit.sh` i quality-score ≥ 0.85
- raport delta NIE powtarza wpisów istniejących w ai-knowledge (test: drugi run tego samego dnia = pusty raport)
- test vitest dla logiki skryptowej (jeśli powstanie skrypt shell)

## Powiązane

- Konwencja: katalog `~/Projects/ai-tools/context-forge-suggestions/` = kolejka sugestii dla pluginu;
  ai-tools pracuje TYLKO nad benchmarkiem cf-bench.
- Etap 2 (po powstaniu cf-bench): pętla autoresearch — propozycje zmian configu mierzone benchmarkiem,
  zostają tylko poprawy. Kandydat na skill `/config-evolve`.
