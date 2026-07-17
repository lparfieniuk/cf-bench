# RESEARCH: Jak działają popularne benchmarki AI (2026-07-17)

Cel: wyciągnąć z uznanych benchmarków praktyki, które wzmocnią cf-bench, oraz zmapować
prace najbliższe naszej niszy. Źródła: WebSearch + arXiv (linki na końcu).

## 1. Przegląd benchmarków

### SWE-bench / Verified / Pro (Princeton → OpenAI/ScaleAI)
- **Co testuje**: naprawa prawdziwych issue z GitHuba (Python repos); sukces = ukryte testy
  jednostkowe przechodzą po patchu agenta. Deterministyczna ocena — jak u nas.
- **Kryzys 2026**: OpenAI porzuciło Verified (02.2026) — kontaminacja (frontier modele
  odtwarzają gold patches verbatim) + wpływ scaffoldingu: identyczne wagi modelu różnią się
  o 10–20 p.p. zależnie od harnessu. >60% "nierozwiązanych" zadań było źle ocenianych
  (testy za wąskie lub za szerokie).
- **SWE-bench Pro** (odpowiedź): 1865 zadań, w tym **858 held-out** (niepubliczne) i 276
  komercyjnych repo — odporność na kontaminację przez ukrycie części zbioru.
- **Lekcja dla cf-bench**: (a) kontaminacja nas prawie nie dotyczy — fixtures są syntetyczne
  i prywatne; to PRZEWAGA, nazywać ją w publikacji; (b) "harness variance" = nasz argument
  founding: mierzymy config/harness, którego inne benchmarki nie kontrolują; (c) held-out
  fixtures warto utrzymać po open-source (publikować zadania, trzymać część prywatnie).

### Terminal-Bench 2.0 (Stanford/LAUDE)
- **Co testuje**: 89 zadań terminalowych end-to-end w Dockerze; ocena = testy sprawdzają
  STAN KOŃCOWY środowiska, nie transkrypt.
- **Rygor konstrukcji**: każde zadanie ma 4 komponenty: instrukcja NL, środowisko,
  testy weryfikacyjne, **oracle solution** (ludzkie rozwiązanie wzorcowe). ~3 roboczogodziny
  recenzji na zadanie. Oracle dowodzi, że zadanie jest rozwiązywalne, a testy — przechodnie.
- **Lekcja**: brakuje nam oracle solutions. Sanity gate łapie "check przechodzi przed runem",
  ale nic nie dowodzi, że check DA SIĘ przejść (outcome validity). → wdrożone: `oracle.sh`
  per fixture + `runner/validate-tasks.sh`.

### Aider polyglot
- 225 zadań Exercism w 6 językach; metryka `pass_rate_2` — druga próba z outputem
  failujących testów. Mierzy praktyczną edycję kodu + format diffów.
- **Lekcja**: retry-with-feedback to inna oś niż nasza (my mierzymy config, nie model), ale
  format "agent dostaje wynik testu" jest analogiczny do naszych widocznych testów.

### LiveCodeBench
- Zadania konkursowe publikowane PO cutoffie modelu — świeżość jako obrona przed
  kontaminacją. Nasze syntetyczne fixtures osiągają to samo taniej.

### tau-bench (Sierra)
- Agenci customer-service; kluczowa innowacja: **pass^k** — odsetek scenariuszy zaliczonych
  we WSZYSTKICH k niezależnych rolloutach. Mierzy niezawodność, nie szczęście: GPT-4o
  61% pass@1 vs 25% pass@8. Wariancja to sygnał, nie szum do uśrednienia.
- **Lekcja**: mamy N powtórzeń — raportujmy pass^n obok pass rate. "Config, który daje
  10/10 vs 6/10" to inna wartość niż mediana. → wdrożone w summarize.

### HAL — Holistic Agent Leaderboard (Princeton)
- Standaryzowany, **cost-aware** leaderboard: koszt $ jako oś równorzędna z accuracy
  (median run SWE-bench Verified = $163; spread per-task 400×). Trzecia strona jako
  gwarant wiarygodności.
- **Lekcja**: nasz TSV już ma koszt — utrzymać koszt jako first-class metrykę w publikacjach.
  Model "trzecia strona audytuje configi" = dokładnie nasz pitch monetyzacyjny.

## 2. Stan wiedzy o rygorze statystycznym (2026)

- Dominują wyniki z pojedynczego runu bez CI — powszechnie krytykowane
  ("Stochasticity in Agentic Evaluations", "Beyond pass@1", "Statistical Precipice").
- Zalecenia z literatury: CI na każdej metryce, testy dla prób zależnych, power analysis,
  multiple rollouts. Prawie żaden leaderboard tego nie robi → **nisza wiarygodności**.
- Audyty LLM-judge: błędy >50% (position/length/agreeableness bias) — nasz zakaz
  LLM-judge (zasada twarda 5) jest zwalidowany literaturą; cytować w publikacji.
- ABC checklist (task validity / outcome validity / transparent reporting) — nasze
  sanity gate + oracle + otwarte TSV pokrywają wszystkie trzy osie.

## 3. Prace NAJBLIŻSZE naszej niszy (⚠ konkurencja/walidacja)

### SkillsBench (arXiv 2602.12670)
Najbliższa nam praca. 84 zadania / 11 domen, paired evaluation: no-skills vs curated vs
self-generated skills; 7308 trajektorii, 5 trials/task, deterministyczne weryfikatory,
3 harnessy (Claude Code, Gemini CLI, Codex CLI).
- Curated skills: **+16.2 p.p.** średnio (zakres +4.5 SWE → +51.9 healthcare).
- Self-generated skills: **−1.3 p.p.** (model nie umie pisać skilli, z których korzysta).
- 2–3 skille optimum (+18.6); 4+ skilli → +5.9; "comprehensive documentation" → **−2.9**.
- Luki (ich własne): brak izolacji komponentów skilla, brak niższej jakości "community
  skills", brak long-horizon.
- **Pozycjonowanie cf-bench**: SkillsBench mierzy skille jako klasę ("czy skille działają?"),
  my mierzymy KONKRETNY config KONKRETNEGO zespołu ("czy TWÓJ config działa?"). Ich wynik
  "za dużo contentu szkodzi" wprost wspiera nasz produkt audytowy (przycinanie configów
  poparte pomiarem). Cytować jako walidację tezy.

### ETH Zurich: wpływ AGENTS.md (arXiv 2601.20404)
124 zmergowane PR-y z 10 repo, paired: z/bez AGENTS.md, tylko Codex. Wynik: mediana
czasu **−28.6%**, output tokens **−16.6%** (Wilcoxon p<0.05). ALE: **nie mierzyli
poprawności wyniku** — tylko efektywność. Luka nazwana przez autorów.
- **Pozycjonowanie**: my mierzymy dokładnie to, czego oni nie zmierzyli (success przez
  deterministyczne checki) + wiele wariantów configów, nie binarnie jest/nie ma.

### AGENTbench-138 / badanie "context files hurt" (4 agenty, 138 issues)
LLM-generated context files: **−0.5 do −2 p.p.** sukcesu, +20% kosztu. Human-written:
**+4 p.p.**. Koszt: +14–22% tokenów reasoningu niezależnie od autorstwa.
- **Pozycjonowanie**: to jest dokładnie ten spór, który cf-bench rozstrzyga per-config.
  Sprzeczne wyniki badań (ETH: −28% kosztu; to badanie: +20% kosztu) dowodzą, że efekt
  zależy od konkretnego configu i zadań → "zmierz swój" = nasz produkt. Media już
  podchwyciły ("CLAUDE.md don't work") — timing publikacji draftu jest dobry.

## 4. Wnioski wdrożeniowe dla cf-bench

| # | Praktyka (źródło) | Status |
|---|---|---|
| 1 | Wilson CI + Fisher exact + pass^n w summarize (tau-bench, literatura CI) | WDROŻONE |
| 2 | Oracle solutions + validate-tasks (Terminal-Bench) | WDROŻONE |
| 3 | Koszt jako first-class metryka (HAL) | już było (TSV) |
| 4 | Held-out część zadań po open-source (SWE-bench Pro) | decyzja przy OSS prep |
| 5 | Zakaz LLM-judge — cytować audyty błędów >50% w publikacji | do draftu |
| 6 | Syntetyczne prywatne fixtures = odporność na kontaminację — nazwać w README EN | do OSS prep |
| 7 | Paired evaluation (A/B ten sam task) jako "best practice" wg SkillsBench | już było — cytować |
| 8 | Klasa zadań "config-lies" (CLAUDE.md sprzeczny z repo) — wsparta wynikiem SkillsBench "comprehensive docs −2.9pp" | fixture zbudowany, kalibracja czeka na budżet |

## 5. Zagrożenia zaktualizowane

- SkillsBench może rozszerzyć się z "skills jako klasa" na "config per-repo" — obserwować
  (dodać do research-routine watchlisty razem z Anthropic Skill Creator).
- Fala "context files don't work" może osłabić rynek configów — ale wzmacnia rynek
  POMIARU configów. Nasza teza jest po właściwej stronie sporu.

## Źródła

- SWE-bench kontaminacja/porzucenie: codesota.com/news/swe-bench-contamination-debate,
  benchmarkingagents.com/swe-bench, digitalapplied.com (methodology 2026)
- SWE-bench Pro: codingfleet.com/blog/swe-bench-pro-explained
- Terminal-Bench: arxiv.org/abs/2601.11868, github.com/harbor-framework/terminal-bench
- Aider polyglot: emergentmind.com/topics/aider-polyglot-benchmark
- tau-bench pass^k: benchmarkingagents.com/tau-bench
- HAL: hal.cs.princeton.edu, arxiv.org/pdf/2510.11977
- Rygor statystyczny: arxiv.org/pdf/2512.06710 (ICC), arxiv.org/pdf/2603.29231 (Beyond pass@1),
  arxiv.org/pdf/2605.08261 (Statistical Precipice), simmering.dev/blog/agent-benchmarks
- SkillsBench: arxiv.org/html/2602.12670v1
- ETH AGENTS.md: arxiv.org/html/2601.20404v1
- "Context files hurt": todatabeyond.substack.com, academy.dair.ai/blog/agents-md-evaluation
