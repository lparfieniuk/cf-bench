# cf-bench

Mierzy, czy config agenta kodującego (CLAUDE.md / skills / MCP) faktycznie poprawia wyniki —
zamiast wierzyć na słowo. A/B: ten sam task, wariant **A** (bez configu) vs **B** (z configiem),
N powtórzeń, metryki z twardego JSON-a `claude -p`. Opcjonalny wariant **C** (placebo):
`VARIANTS="A B C"` + `CONFIG_C="generic"` w `.task` — generyczny config bez wiedzy o zadaniu;
oczekiwane C≈A dowodzi, że efekt B to zakodowana wiedza, nie sama obecność CLAUDE.md.

## Metryki (na run)

| Kolumna | Źródło |
|---|---|
| `success` | `check.sh` fixture'a (exit 0) — deterministyczna asercja, nie LLM-judge |
| `cost_usd`, `turns`, `duration_ms` | `total_cost_usd`, `num_turns`, `duration_ms` z result JSON |
| `in_tokens`, `cache_creation`, `cache_read`, `out_tokens` | `usage.*` |
| `terminal_reason`, `session_id` | diagnostyka / audyt transkryptu |
| `cli_version` | `claude --version` — reprodukowalność (harness variance) |

## Metodologia

- **Izolacja**: `--setting-sources project` — globalne pluginy/CLAUDE.md użytkownika NIE wchodzą do runu
  (zweryfikowane: cache_creation 15.0k → 8.7k po odcięciu). Wariant A = czysty fixture; wariant B = fixture + zawartość `configs/<task-config>/`.
- **Pinowany model**: `--model` zawsze jawnie (`CFBENCH_MODEL`, default `sonnet`) — bez tego CLI potrafi wybrać różne modele między runami.
- **Świeży workdir**: każdy run w `mktemp -d`, fixture kopiowany, po runie sprzątany. Zero przecieków stanu.
- **Sanity gate**: przed runem `check.sh` MUSI failować (fixture faktycznie zepsuty), inaczej run odrzucony.
- **N powtórzeń** (default 3): wariancja LLM jest wysoka; raportujemy mediany, nie pojedyncze runy.
- **Statystyka** (w `summarize.sh`): Wilson 95% CI na pass rate, Fisher exact (two-sided) na
  delcie sukcesu B vs A, `pass^n` = 1 gdy wszystkie n runów przeszło (niezawodność à la
  tau-bench pass^k — wariancja to sygnał, nie szum).
- **Outcome validity** (praktyka Terminal-Bench): każde zadanie ma oracle solution
  (`oracles/`), `runner/validate-tasks.sh` dowodzi rozwiązywalności; w smoke.sh.
- **Rygor**: żadnych LLM-judge w pętli oceny; sukces = testy fixture'a przechodzą.
  (Walidacja literaturą 2026: audyty LLM-judge raportują >50% błędów oceny.)

## Znane ograniczenia (uczciwie)

- Auth OAuth wymusza konfigurację użytkownika w tle (`--bare` wymaga API key) — wersja modelu/harnessu
  wspólna dla A i B, więc delta pozostaje miarodajna, ale wartości absolutne zależą od wersji CLI.
- N=3 wykrywa tylko duże efekty; do publikacji leaderboardu min. N=10 + przedziały ufności.
- Na razie 1 agent (Claude Code headless); Codex/Cursor CLI — w roadmapie (przewaga cross-agent).

## Użycie

```bash
# pojedynczy run (debug):
runner/run-task.sh tasks/ts-fix-discount-001.task B 1

# pełna macierz (taski × A/B × N):
CFBENCH_REPEATS=3 runner/run-bench.sh            # → results/bench-YYYYMMDD-HHMMSS.tsv

# agregacja:
runner/summarize.sh results/bench-*.tsv          # mediany, Wilson 95% CI, pass^n, Fisher p, delta B vs A

# walidacja zadań przez oracle solutions (zero kosztów LLM):
runner/validate-tasks.sh                         # każdy task: check failuje przed oraclem, przechodzi po

# smoke test bez kosztów LLM (mock claude + validate-tasks):
test/smoke.sh
```

## Struktura zadania

`tasks/*.task` — plik source'owany przez bash, klucze:
`TASK_ID`, `PROMPT`, `FIXTURE` (katalog w `fixtures/`), `CONFIG` (katalog w `configs/` dla wariantu B),
`MAX_TURNS`, `ALLOWED_TOOLS`, `CHECK` (skrypt względem fixture, exit 0 = sukces).
