# Research: monetyzacja benchmarków AI — czy cf-bench może zarabiać (2026-07-15)

Pytanie: kto zarabia na benchmarkach/ewaluacji AI, jakimi modelami, i czy darmowy benchmark da się zmonetyzować.
Ton: krytyczny. Metoda: WebSearch/WebFetch, lipiec 2026.

---

## 1. Dowód, że na benchmarkach SĄ pieniądze (od wielkich po bootstrap)

| Podmiot | Model biznesowy | Liczby (zweryfikowane w źródłach) |
|---|---|---|
| **LMArena** | darmowa arena głosowań (5M userów/mies.) → płatne usługi ewaluacyjne dla labów (OpenAI, Google, xAI) i enterprise | Series A **$150M @ $1.7B** (01.2026); **$30M+ ARR** w 4 mies. od startu produktu |
| **Vals AI** | ⭐ najbliższy nam wzorzec: darmowe publiczne benchmarki domenowe (prawo, finanse, software) → płatne benchmarki custom/prywatne | **bootstrap, $1.3M ARR**, bez inwestorów |
| **promptfoo** | OSS harness ewaluacyjny → enterprise hosting | **przejęte przez OpenAI** (początek 2026) — dowód exit path |
| **Braintrust** | eval+tracing SaaS, free tier 1M spans → enterprise (SOC2, hybrid VPC) | finansowane przez a16z, lider enterprise |
| **Langfuse** | OSS self-host za darmo → cloud $29 (Core) / $199 (Pro) /mies. | kanoniczny model open-core w tym segmencie |
| **Confident AI (DeepEval)** | OSS framework → SaaS od $9.99/user/mies. | najtańszy entry point |
| **Scale SEAL** | leaderboard jako marketing → kontrakty enterprise eval | część stacku usług Scale |
| **SWE-bench / terminal-bench** | akademickie, ale: OpenAI **zapłaciło** za kurację SWE-bench Verified; terminal-bench = Stanford+Laude Institute (granty) | laby płacą za wiarygodne benchmarki; konflikt interesów odnotowany publicznie |

Wniosek: rynek ewaluacji płaci na trzech poziomach — laby (miliony), enterprise (dziesiątki tys.), zespoły deweloperskie ($10–200/mies./user). Dominujący wzorzec dla indie: **OSS harness za darmo + płatny hosting/prywatne ewaluacje**.

## 2. Świeży dowód bólu (paliwo dla naszej niszy)

- **Kwiecień 2026**: Anthropic potwierdziło falę regresji jakości Claude Code spowodowaną zmianami w warstwie produktu (reasoning-effort, prompty) — **bez zmiany wersji modelu**; niewykrywalne bez pomiaru outputów. Dokładnie ten scenariusz łapie CI-gate na config.
- Standard w prompt-evalach: golden set ≥30 przypadków w CI, próg ±3%, regresja = fail buildu — wzorzec przenosimy 1:1 na configi agentów.
- ETH Zurich (poprzedni research): +20% kosztu za każdy plik kontekstu przy +4% sukcesu — każdy zespół z CLAUDE.md ma nieświadomie nierozstrzygnięty rachunek.

## 3. Konkurencja w NASZEJ niszy (config-level, nie app-level) — wciąż płytka

| Kto | Zakres | Zagrożenie |
|---|---|---|
| **Anthropic Skill Creator** (oficjalny, 19k instalacji) | A/B benchmark **pojedynczego skilla** (3 agentów z / 3 bez), pass rate + tokeny + czas; ręczne asercje; dev-time | ŚREDNIE-WYSOKIE: platforma może rozszerzyć na całe configi — nasz timing musi być szybki |
| **AgentBench.app** | 40 zadań, scoring rule-based, leaderboard setupów | niskie (5★ GH, brak trakcji) |
| **claude-skills-benchmark**, Agent MD Compliance Tester | statyczna analiza / LLM-as-judge pojedynczych plików | niskie |
| promptfoo/Braintrust/Langfuse | ewaluują **aplikacje LLM użytkownika**, nie config narzędzia agentowego | inna warstwa — to sąsiedzi, nie konkurenci |

Luka bez lidera: **pomiar całego setupu agenta kodującego (rules + skills + MCP + hooki) na własnym repo, w czasie (regresje po updatach modelu/harnessu), między agentami (Claude Code vs Codex vs Cursor)**.

## 4. Drabina monetyzacji dla darmowego cf-bench (od zera do przychodu)

1. **OSS harness (free, BYOK)** — koszt API po stronie użytkownika (zero COGS u nas). Cel: trakcja + wiarygodność + dane. Nie przynosi pieniędzy i NIE MA przynosić.
2. **Publiczny leaderboard configów/pluginów/packów** (model Vals AI) — darmowy, kontrowersyjny content sam się rozchodzi ("zmierzyliśmy 20 popularnych packów z Gumroad — 14 pogarsza wyniki"). Funnel.
3. **Płatne pierwsze produkty** (realne w 6–12 mies., setki–niskie tysiące $/mies.):
   - **Regression-watch / CI-gate**: "Twój config przeciw każdemu update modelu i harnessu; alert przy regresji" — subskrypcja z natury (pain: incydent 04.2026). $19–49/mies. solo, $99+/zespół.
   - **Prywatne ewaluacje na repo klienta** (model Vals): jednorazowo $300–1500 / audyt configu z raportem. Zgrywa się z pozycją staff engineera.
4. **Późniejsze / warunkowe**:
   - Hosted dashboard z historią i porównaniami zespołowymi (Langfuse-style $29–199/mies.)
   - Badge "benchmarked by cf-bench" dla wydawców packów/pluginów — UWAGA: konflikt interesów (lekcja SWE-bench Verified/OpenAI); tylko z pełną jawnością metodologii
   - Licencja danych zagregowanych ("co faktycznie działa") — wymaga skali
   - Exit: precedens promptfoo→OpenAI; akwizytorzy istnieją (Anthropic, Cursor, obserwability players)

## 5. Krytyka własnego planu (żeby nie było zbyt różowo)

- **Ryzyko platformowe nr 1**: Anthropic już ma per-skill A/B w oficjalnym pluginie. Jeśli rozszerzą na całe configi, zjedzą warstwę 1–2. Obrona: cross-agent (Codex/Cursor — tego Anthropic nie zrobi), CI/temporal, własne repo klienta. I szybkość.
- **Koszt wiarygodności**: benchmark bez rygoru metodologicznego = szum. Wariancja między runami LLM jest wysoka — potrzeba N powtórzeń, przedziałów ufności, jawnej metodologii. To nasza przewaga (podejście metrics-first), ale też realny koszt tokenów przy każdej publikacji leaderboardu (dziesiątki–setki $ za rundę; budżetować).
- **Moat cienki**: kod harnessu skopiują w tydzień. Moat = metodologia + zaufanie + ciągłość danych (historia regresji) + dystrybucja. Budowane miesiącami, nie sprintem.
- **Audiencja węższa niż app-evals**: płacą zespoły używające agentów (rosnący rynek, budżety $100–200/dev/mies. już zaakceptowane), ale solo-devi raczej nie zapłacą — celować w team leady z pytaniem CFO "czy nasze $200/seat + config w ogóle działa".
- **Realistyczny przychód rok 1**: $0 przez pierwsze ~3 mies. (budowa+trakcja), potem setki $/mies. z regression-watch/audytów przy dobrym przebiegu. LMArena-scale wymaga społeczności, której nie mamy. To gra o pozycję z opcją.

## 6. Rekomendacja

Model: **Vals AI + Langfuse hybrid, bootstrap-friendly**:
darmowy OSS harness (BYOK) → głośny leaderboard (packi z Gumroad, popularne pluginy, CLAUDE.md wzorce) → płatny regression-watch (subskrypcja) + prywatne audyty (jednorazowe).
Pierwszy kamień milowy komercyjny: **1 płacący klient regression-watch lub 1 audyt** — walidacja przed budową czegokolwiek hosted.

## Źródła

- https://techcrunch.com/2026/01/06/lmarena-lands-1-7b-valuation-four-months-after-launching-its-product/ · https://news.lmarena.ai/series-a/
- https://getlatka.com/companies/vals.ai · https://www.vals.ai/home
- https://www.braintrust.dev/articles/best-promptfoo-alternatives-2026 (promptfoo→OpenAI, pricing tiers)
- https://techsy.io/en/blog/best-llm-evaluation-tools (Langfuse $29/$199, Confident AI $9.99)
- https://www.swebench.com/ · https://www.digitalapplied.com/blog/swe-bench-terminal-bench-benchmark-guide-2026 (finansowanie OpenAI/Stanford+Laude, konflikt interesów)
- https://www.nathanonn.com/claude-code-skill-creator-guide/ (Skill Creator: per-skill A/B, 19k instalacji)
- https://www.evalgent.com/blog/llm-update-regression-voice-agent · https://futureagi.com/blog/prompt-regression-testing-2026/ (incydent CC 04.2026, golden set ±3% w CI)
- https://www.agentbench.app/
