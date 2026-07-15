# Research rynkowy — weryfikacja krytyczna pomysłów (2026-07-15)

Pytanie: czy nasze plany (pack reguł Angular/Nx, silnik context-forge, MCP Proxy Distiller, cf-bench) duplikują istniejące rozwiązania i czy rozwiązują realne problemy warte pieniędzy.
Metoda: web research (WebSearch + WebFetch), lipiec 2026. Ton celowo krytyczny.

---

## 1. MCP Proxy Distiller — ❌ NIE BUDOWAĆ (przegrane pole)

- **Headroom** (`github.com/chopratejas/headroom`, ~49k gwiazdek, Apache-2.0, release v0.27.0 z 2026-06): kompresja tool-outputów/logów/RAG przed LLM, "60–95% mniej tokenów dla JSON, 20% dla coding agents", działa jako **biblioteka, proxy i serwer MCP**, local-first. To jest nasz Distiller, tylko już zbudowany, darmowy i z ogromną trakcją.
- Warstwa gateway/filtrowania narzędzi: **MetaMCP** (namespaces, tool overrides, middleware), **MCPJungle** (tool groups, per-client allowlisty), **mcp-proxy**. Ekosystem opisany jako zatłoczony już w Q1 2026.
- Platforma zjada resztę: Anthropic publikuje wzorzec "code execution with MCP" (redukcja tool-context), Claude Code ma natywny deferral narzędzi (ToolSearch), API ma kompakcję kontekstu w becie.

Wniosek: spec z research-notatek był trafną diagnozą, ale rynek rozwiązał problem zanim weszliśmy. Duplikacja ~1:1.

## 2. Silnik "oszczędzania tokenów" jako produkt — ❌ COMMODITY

Darmowa konkurencja dla naszego Shadow System / extract-signatures / pack-context:
- **Repomix** — pakowanie repo z kompresją Tree-sitter (~70% redukcji; dokładnie nasz trik "wytnij ciała funkcji")
- **code2prompt**, **Graphify** (28 języków, graf wiedzy), **continue.dev** `@codebase` (retrieval semantyczny)
- Natywnie: `/compact`, prompt caching (−90% kosztu wejścia), API context compaction, LiteLLM (routing do tańszych modeli)

Wniosek: "narzędzie tnące tokeny" nikt nie kupi — dostaje za darmo z 10 stron. CF jako silnik ma wartość **wewnętrzną** (nasza infrastruktura, wiarygodność), nie sprzedażową per se.

## 3. Pack Angular/Nx ($49, rdzeń GTM) — ⚠️ POWAŻNIE PODCIĘTY

Najbolesniejsze znalezisko: **Nx rozdaje to oficjalnie za darmo**:
- `nx-mcp` (oficjalny serwer MCP: graf projektów, zależności, generatory, docs, Nx Cloud CI, self-healing fixes)
- komenda konfigurująca AI: generuje **AGENTS.md / CLAUDE.md** + instaluje **agent skills** (eksploracja workspace, codegen, egzekucja tasków); dla Claude Code — jako plugin
Sprzedawanie "packa Nx dla AI" = konkurowanie z vendorem frameworka, który ma dystrybucję, markę i zero ceny.

Nauka o skuteczności reguł — sprzeczna i niewygodna:
- **ETH Zurich (AGENTbench + SWE-bench Lite, 4 agenty w tym Claude Code/Sonnet-4.5)**: pliki generowane przez LLM **−0.5 do −2% sukcesu**; pisane ręcznie **+4%**; KAŻDY plik kontekstu **+20% kosztów inferencji** (+14–22% reasoning tokens)
- **arXiv 2601.20404 (tylko Codex, małe PR-y)**: AGENTS.md → **−28.6% czasu (mediana), −16.6% output tokens**
- Kluczowy insight ETH: reguły działają tylko gdy niosą wiedzę **niedostępną w repo** ("write for the gap, not the overview") — generyczne packi ze "best practices" to dokładnie to, co według badań NIE działa

Rynek packów istnieje, ale jest komodyzowany: Gumroad "Cursor Rules Pack v2" (50 reguł/14 stacków), "Mega Pack" (53 pliki) — kontra darmowe awesome-cursorrules (40k+ gwiazdek). Zero publicznych dowodów istotnych przychodów; format .cursorrules już przestarzały (churn formatów przemiela produkty).

## 4. Monetyzacja w ekosystemie Claude Code — ⚠️ NIEROZWIĄZANA

- Oficjalny marketplace (101 pluginów) — **brak mechanizmu płatności**; sprzedaż plików = natychmiastowa utrata IP
- Analizy monetyzacji skilli: skalowalny jest tylko model "hosted access"
- Sygnał popytu: ~300k devs/mies. odwiedza katalogi pluginów — dystrybucja jest, pieniędzy w niej (jeszcze) nie ma

## 5. Co się broni — ✅ EWALUACJA / POMIAR (whitespace)

- Nauka jest świeża, sprzeczna i głośna (ETH vs arXiv) → pytanie "czy MÓJ config działa w MOIM repo?" nie ma dziś produktowej odpowiedzi
- Konkurencja embrionalna: **AgentBench.app** (plugin CC, rule-based scoring, 40 zadań — 5 gwiazdek na GH, brak trakcji), `claude-skills-benchmark`, "Agent MD Compliance Tester" (LLM-as-judge) — nikt nie ma pozycji
- Dokładnie zgodne z naszym wymogiem "metrics-first" i istniejącą infrastrukturą CF (benchmark-tokens, quality-score, telemetria hooków, 45 testów)
- ETH pokazuje też, że uczciwy pomiar może wykazać **mały lub ujemny** efekt reguł — dla sprzedawcy packów to ryzyko, dla sprzedawcy **pomiaru** to paliwo

## Werdykt (brutalnie)

| Pomysł | Werdykt | Powód |
|---|---|---|
| MCP Proxy Distiller | **porzucić** | Headroom (49k★) + MetaMCP/MCPJungle + natywne funkcje Anthropic |
| Silnik CF jako produkt "token saver" | **nie sprzedawać wprost** | commodity; trzymać jako infrastrukturę własną + open-core wiarygodność |
| Pack Angular/Nx $49 | **zwęzić albo odłożyć** | Nx rozdaje fundament za darmo; badania podważają wartość generycznych reguł; sprzedawalne tylko "gap rules" z dowodem pomiarowym |
| cf-bench (pomiar skuteczności configów) | **BUDOWAĆ — główny zakład** | realny, nierozstrzygnięty problem; brak lidera; zgodny z naszą przewagą i infrastrukturą |
| Rule packi w ogóle | funnel, nie produkt | content marketing + open-core; przychód z nich traktować jako bonus |

Szczera ocena willingness-to-pay: deweloperzy płacą za IDE/API (subskrypcje $20–200/mies.), **niechętnie za pliki .md**. Najbardziej prawdopodobna ścieżka przychodu w horyzoncie 6 mies.: mała (setki $, nie tysiące) — traktować projekt jako budowę pozycji (open-source cf-bench + publikacje z własnymi liczbami) z opcją na produkt płatny (hosted raporty / audyt konfiguracji / enterprise packi z dowodami), nie jako szybki dochód pasywny. GTM doc wymaga rewizji: jego produkt bazowy ($49 pack) stoi na najsłabszym gruncie.

## Zrewidowana teza produktowa

**"Nie sprzedajemy reguł. Sprzedajemy dowód, że config agenta działa (albo nie)."**
1. Open-source: `cf-bench` — A/B harness (config vs brak) na fixture repo; metryki: sukces, tokeny, tury, czas, koszt. Publikacja wyników = artykuł, który sam się rozchodzi (kontrowersja ETH vs arXiv gotowym haczykiem).
2. Płatne później: hosted raporty/CI-gate ("regresja configu po update modelu"), audyty, wyselekcjonowane "gap rules" Angular/Nx z załączonym pomiarem.

## Źródła

- https://github.com/chopratejas/headroom
- https://www.heyitworks.tech/blog/mcp-aggregation-gateway-proxy-tools-q1-2026
- https://www.anthropic.com/engineering/code-execution-with-mcp
- https://github.com/metatool-ai/metamcp
- https://pinggy.io/blog/tools_to_reduce_ai_coding_agent_token_usage/ (Repomix, Graphify, Headroom, continue.dev, LiteLLM)
- https://academy.dair.ai/blog/agents-md-evaluation (ETH Zurich, AGENTbench)
- https://arxiv.org/html/2601.20404v1 (AGENTS.md, Codex, −28% czasu)
- https://nx.dev/docs/getting-started/ai-setup + https://nx.dev/docs/reference/nx-mcp
- https://www.agentbench.app/
- https://www.agent37.com/blog/monetize-claude-code-skills
- https://code.claude.com/docs/en/discover-plugins
- https://oliviacraftlat.gumroad.com/l/wyaeil + https://survivoragent.gumroad.com/l/lydtly
