# ai-tools — cf-bench

Komercyjny side-project Lukasza. Budujemy **cf-bench**: benchmark mierzący, czy config agenta
kodującego (CLAUDE.md/skills/MCP) faktycznie działa. Teza: **nie sprzedajemy reguł — sprzedajemy
dowód, że config działa (albo nie)**. Model docelowy: darmowy harness OSS → leaderboard →
płatny regression-watch + audyty. Etap: Faza 0 (fundament pomiarowy). Working name: cf-bench.

## Zasady twarde

1. **Metrics-first**: żadna reguła/feature/twierdzenie nie wchodzi bez pomiaru. Wątpliwe → `[niezweryfikowane]`.
2. **Wiarygodność > kod**: moat = metodologia + zbiór zadań + historia danych. Kod runnera jest celowo trywialny.
3. **Zero zależności bez zgody**: runner = bash + python3 stdlib; fixtures = node:test bez npm install. Nie dodawaj frameworków.
4. **Local-first, stateless, flat files** (TSV/YAML/md). Żadnych baz, serwerów, chmury — hosted dopiero po pierwszym płacącym kliencie.
5. **Determinizm oceny**: sukces = check.sh fixture'a (exit 0). NIGDY LLM-as-judge w pętli oceny.
6. **Rygor benchmarku**: izolacja `--setting-sources project`, pinowany `--model`, świeży mktemp workdir, sanity gate (check musi failować przed runem), N powtórzeń, raportujemy mediany. N<10 = kierunkowe, nie dowód.

## Konwencje repo

- Ten projekt = TYLKO benchmark. Ulepszenia pluginu context-forge → numerowane sugestie w `context-forge-suggestions/` (Lukasz implementuje je osobno w `~/Projects/context-forge`).
- Istotne decyzje → diary (`~/worklogs/diaries/`, skill `/diary` z context-forge) — konsumuje je `/evolve`.
- Research: raporty `RESEARCH-*.md` w korzeniu; cotygodniowy skan w `research-routine/`; raporty skanu w `research-reports/`.
- Wyniki benchmarku: `cf-bench/results/*.tsv` — nie kasować, to przyszły moat danych.
- Po zmianach w runnerze: `bash cf-bench/test/smoke.sh` (mock, zero kosztów) musi być PASS.

## Pułapki już odkryte (nie odkrywaj ponownie)

- `node --test` bez argumentu katalogu (z `test/` psuje discovery na node v22).
- CLI bez `--model` wybiera różne modele między runami.
- `--bare` wymaga ANTHROPIC_API_KEY (OAuth odpada) — dlatego `--setting-sources project`.
- Runy LLM kosztują: pełna macierz wymaga zgody Lukasza na budżet; szacuj koszt przed uruchomieniem.

## Kontekst biznesowy (skrót)

Konkurencja zbadana 2026-07: Headroom/Repomix/nx-mcp zamykają "token-saving" — NIE idziemy tam.
Nisza: pomiar całych setupów, cross-agent, regresje po updatach modeli (incydent CC 04.2026).
Zagrożenie: Anthropic Skill Creator (per-skill A/B) może rozszerzyć zakres — sprawdzaj w skanach.
Szczegóły: `AUDIT-2026-07-15.md`, `RESEARCH-MARKET-2026-07-15.md`, `RESEARCH-BENCHMARK-MONETIZATION-2026-07-15.md`.
