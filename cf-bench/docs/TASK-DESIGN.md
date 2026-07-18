# Projektowanie zadań cf-bench (rubryka)

Zadanie jest dobre, gdy **config decyduje o sukcesie**, nie tylko o koszcie. ts-mini-001 tego nie
spełnia (100% sukcesu w A i B) — służy jako smoke/koszt-only.

## Wymagania twarde (każde zadanie)

1. **GAP zadeklarowany**: nagłówek `.task` wskazuje, która linia configu rozstrzyga zadanie.
   Bez tej linii wiedza NIE jest w pełni wywnioskowalna z repo (może być częściowo — to OK, mierzymy
   config vs eksploracja).
2. **Ukryte asercje**: `HIDDEN="<dir>"` w `.task` → zawartość `fixtures-hidden/<dir>/` kopiowana do
   workdir PO runie agenta, PRZED finalnym checkiem. Widoczne testy czynią zadanie *podejmowalnym*,
   ukryte dopinają spec (decyzje projektowe, konwencje, niezmienniki).
3. **Sanity gate**: check MUSI failować przed runem (egzekwowane przez runner; gate widzi
   wyłącznie widoczne testy — ukryte wstrzykiwane są dopiero po runie agenta).
4. **Determinizm**: zero sieci, zero zależności od TZ/zegara/locale, zero npm install. Sukces =
   exit code, nigdy LLM-judge.
5. **Trudność z wiedzy, nie z łamigłówki**: sama poprawka trywialna; trudne jest CO/GDZIE zgodnie
   z polityką projektu. Nie testujemy inteligencji modelu, testujemy wartość configu.
6. **Oracle solution** (praktyka Terminal-Bench): `oracles/<fixture>.sh` (fallback: nazwa bez
   sufiksu `-xl`) aplikuje wzorcową poprawkę; `runner/validate-tasks.sh` dowodzi dla każdego
   zadania, że check failuje przed oraclem i przechodzi po nim (+ hidden). Oracles żyją POZA
   `fixtures/`, żeby nigdy nie trafiły do workdiru agenta. Egzekwowane w smoke.sh.

## Klasy zadań (po kalibracji 2026-07-16, N=5)

1. **encoded-decision** — polityka/decyzja zespołu bez ŻADNEGO sygnału w repo (js-stack-002).
   A=0% jest tu poprawne: mierzy dokładnie wartość zapisania decyzji w configu. Najsilniejsze
   dyskryminatory (zmierzone: A 0% vs B 100%, koszt −24%).
2. **conflicting-signal (brownfield)** — sygnał w repo ISTNIEJE, ale jest sprzeczny (kłamiący
   komentarz vs kod, dwie konwencje 50/50). A powinno lądować w 20–70% — mierzy, czy config
   wygrywa z błędnym priorytetem. Rdzeń wartości dla brownfield/legacy.
3. **cost-only** — oba warianty przechodzą, config tnie koszt/tury (ts-mini-001, js-dist-003).
   Trzymamy 1–2 takie dla metryki kosztowej, nie liczą się do dyskryminacji.
4. **config-lies** (js-config-lies-008, SKALIBROWANA 2026-07-18, N=5 sonnet) — config twierdzi
   NIEPRAWDĘ względem repo; semantyka A/B odwrócona: B jest sabotowane, mierzymy ślepe
   zaufanie do configu. **Wynik: A 100% (5/5) vs B 0% (0/5), Fisher p=0.008; koszt B −9.8%.**
   Agent ANI RAZU nie zakwestionował kłamiącego configu mimo sprzecznych dowodów w repo —
   config jest w pełni zaufanym single point of failure. Narracja: "taniej i pewniej,
   ale źle" — stale config nie degraduje wyniku, on go ODWRACA. Motywacja: literatura 2026
   ("context files hurt", SkillsBench: comprehensive docs −2.9pp); to nasz pomiar wartości
   audytu configów (produkt).

**Lekcja z obalenia hipotezy js-dist**: pułapki odkrywalne mechanicznie (śledzenie importów,
czytanie package.json) NIE dyskryminują — nowoczesne modele robią to niezawodnie. Dyskryminuje
tylko wiedza bez sygnału (klasa 1) albo z sygnałem sprzecznym (klasa 2).

**Lekcja z kalibracji klasy 2 (2026-07-16, N=5, sonnet)**: w MAŁYM fixture (3–5 plików)
conflicting-signal też nie dyskryminuje sukcesu — A=100% na obu zadaniach (agent rozstrzyga
konflikt kod-vs-komentarz i wybiera konwencję po sąsiedztwie domenowym). Efekt configu jest za to
duży kosztowo: −11% do −23% kosztu, tury 9→6/7, output tokens −43% do −53%. Hipoteza robocza:
"zgubienie w brownfield" wymaga SKALI — sygnał zakopany w setkach plików, eksploracja droga.
Następna iteracja klasy 2: fixture rozdęty syntetycznym szumem (100+ plausible plików) i/lub
sygnał przeniesiony daleko od edytowanego pliku. Do tego czasu 004/005 klasyfikować jako
cost-only o wysokiej delcie.

**Lekcja z eksperymentu skali (2026-07-16, XL = 120 plików szumu, N=5, sonnet)** — skala
rozszczepia klasę 2 na dwie podklasy o różnym zachowaniu:

- **2a. local-lie / distant-truth** (cents-xl: kłamiący komentarz w edytowanym pliku, prawda
  zakopana w src/lib/money/): skala FLIPUJE sukces — A 100%→**0%** (0/5), B 100%. Agent
  w dużym repo ufa lokalnemu sygnałowi i nie dociera do odległej prawdy. Najcenniejsza
  podklasa dla brownfield.
- **2b. grep-findable convention** (errors-xl: konwencja wyszukiwalna wzorcem w dowolnym
  pliku): sukcesu NIE flipuje na żadnej skali (A=100%), ale koszt eksploduje — config daje
  **−50% kosztu, −60% output tokens, czas 72s→26s, tury 16→9**. Klasa "cost-at-scale".

Reguła projektowa: dyskryminacja sukcesu wymaga złej wskazówki LOKALNIE + prawdy DALEKO
(albo zera sygnału — klasa 1). Konwencje wyszukiwalne grepem mierz jako koszt, nie sukces.

## Cel kalibracyjny (weryfikowany empirycznie, N≥5)

- klasa 1: A **0–30%**, B **>85%**
- klasa 2: A **20–70%**, B **>85%**
- klasa 3: A=B≈100%, Δkosztu < 0
- poza widełkami → przeprojektowanie albo świadoma reklasyfikacja

## Podklasa: library-convention (2c) — od 2026-07-18

Konwencja zespołowa UŻYCIA popularnej biblioteki (nie znajomość API — tę model ma z treningu).
Pułapka = sąsiedni plik pokazuje wzorzec poprawny dla INNEGO przypadku (rxjs: switchMap
w search.js vs exhaustMap dla submitów; express: inline res.status w legacy users.js vs
next(err) do centralnego middleware). Zadania: js-rxjs-submit-009, js-express-errors-010.

**Kalibracja 2026-07-18 (N=5, sonnet)**:
- js-rxjs-submit-009: **A 0/5 vs B 5/5 (p=0.008), koszt B −2.5%** — pełny dyskryminator
  na MAŁYM fixture (bez skali!). Konwencja operatorowa rxjs nie jest wywnioskowalna
  z sąsiedztwa — sąsiad switchMap skutecznie myli. Najlepszy stosunek siły do rozmiaru.
- js-express-errors-010: A 5/5 = nie dyskryminuje sukcesu (sygnał centralnego middleware
  w app.js za mocny w małym repo — ta sama lekcja co brown-errors small). Koszt −7.9%.
  Klasyfikacja: cost-only; kandydat na wersję XL (szum + zakopanie error-handlera).

**Rozbudowa packa 2026-07-18, SKALIBROWANA (N=5, sonnet)** — wynik negatywny, lekcja kluczowa:

- js-rxjs-catch-011 (catchError wewnątrz flatteningu): A 5/5 = cost-only, koszt −18.7%
- js-rxjs-latest-012 (withLatestFrom vs combineLatest): A 5/5, koszt ±0 — MARTWE (do wymiany)
- js-rxjs-share-013 (shareReplay vs share): A 5/5 = cost-only, koszt −8.9%
- js-express-errors-xl-014 (010 w skali, 134 pliki, errorHandler za setup/pipeline.js):
  A 5/5 = cost-only, koszt −28.6%, tury 16→9. Hipoteza "sygnał middleware słabnie ze
  skalą" OBALONA — spójne z lekcją 2b (konwencja grep-findable = cost-at-scale).

**Reguła projektowa (z tej kalibracji): dyskryminuje tylko polityka SPRZECZNA z priorem
treningowym.** catchError-wewnątrz, withLatestFrom-dla-triggerów, shareReplay-dla-cache to
KANONICZNE odpowiedzi (NgRx lore, blogi) — model zna je bez configu, mylący sąsiad nie
przebija prioru. js-rxjs-submit-009 flipuje, bo wybór exhaustMap jest KONTESTOWANY
(switchMap/mergeMap/concatMap wszystkie obronne; polityka zespołu = arbitralna decyzja).
Test przy projektowaniu: "czy senior bez kontekstu firmy odpowiedziałby jednoznacznie?"
TAK → zadanie będzie cost-only. Wartość configu = ROZBIEŻNOŚĆ polityki zespołu z kanonem,
nie sama obecność konwencji. (To też narracja produktowa: agent zna best practices;
płacisz za pomiar tego, gdzie twój zespół od nich odchodzi.)

Wszystkie 4: oracle + sanity anty-wzorca (anty-wzorzec przechodzi widoczne, failuje hidden)
zweryfikowane przed kalibracją. Dane: results/bench-20260718-101708.tsv.

**Odrzucone: takeUntil/teardown** (z roadmapy). Konwencja teardown NIE jest behawioralnie
dyskryminowalna: `subscription.unsubscribe()` w destroy() jest obserwacyjnie równoważne
`takeUntil(destroy$)` — ukryty test nie odróżni formy bez grepowania źródła, a check na formę
łamie zasadę determinizmu behawioralnego (rubryka pkt 4–5). Kandydat tylko jeśli kiedyś
powstanie klasa "form-lint" mierzona osobno od sukcesu.

Technika: biblioteka WENDOROWANA — `node_modules/` commitowane do fixture (rxjs przycięty
do dist/, ~4.5MB; express tree ~3.9MB), zero npm install w runie (zasada twarda 3 zachowana).
`.gitignore` ma wyjątek `!cf-bench/fixtures/*/node_modules/`.
Poza zasięgiem do decyzji o cache node_modules (ROADMAP): Angular/Karma/Jasmine/Jest/React —
pełny toolchain, nie da się sensownie wendorować.

## Wariant C (placebo) — obrona przed "sami napisaliście configi"

Dla zadań flagowych dodaj `VARIANTS="A B C"` + `CONFIG_C="generic"` (configs/generic/ —
best practices bez wiedzy o zadaniu). C≈A = efekt B pochodzi z wiedzy; C>A = część efektu
to sama obecność configu (raportować uczciwie). Włączone: js-stack-discounts-002.

## Anty-wzorce

- Spec w całości w widocznych testach (agent czyta testy → zero dyskryminacji)
- Wiedza gap-owa zapisana w komentarzu kodu fixture'a (to nie gap, to repo)
- Ukryty test sprzeczny z widocznym (agent nie może przejść obu — nieuczciwe)
- Zadanie flaky (rerun bez zmian daje inny wynik)

## Szablon nagłówka `.task`

```
# GAP: <cytat linii configu, która rozstrzyga>
# HYPOTHESIS: A fails because <przewidywany błędny wybór agenta>
```
