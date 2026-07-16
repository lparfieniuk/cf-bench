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

## Klasy zadań (po kalibracji 2026-07-16, N=5)

1. **encoded-decision** — polityka/decyzja zespołu bez ŻADNEGO sygnału w repo (js-stack-002).
   A=0% jest tu poprawne: mierzy dokładnie wartość zapisania decyzji w configu. Najsilniejsze
   dyskryminatory (zmierzone: A 0% vs B 100%, koszt −24%).
2. **conflicting-signal (brownfield)** — sygnał w repo ISTNIEJE, ale jest sprzeczny (kłamiący
   komentarz vs kod, dwie konwencje 50/50). A powinno lądować w 20–70% — mierzy, czy config
   wygrywa z błędnym priorytetem. Rdzeń wartości dla brownfield/legacy.
3. **cost-only** — oba warianty przechodzą, config tnie koszt/tury (ts-mini-001, js-dist-003).
   Trzymamy 1–2 takie dla metryki kosztowej, nie liczą się do dyskryminacji.

**Lekcja z obalenia hipotezy js-dist**: pułapki odkrywalne mechanicznie (śledzenie importów,
czytanie package.json) NIE dyskryminują — nowoczesne modele robią to niezawodnie. Dyskryminuje
tylko wiedza bez sygnału (klasa 1) albo z sygnałem sprzecznym (klasa 2).

## Cel kalibracyjny (weryfikowany empirycznie, N≥5)

- klasa 1: A **0–30%**, B **>85%**
- klasa 2: A **20–70%**, B **>85%**
- klasa 3: A=B≈100%, Δkosztu < 0
- poza widełkami → przeprojektowanie albo świadoma reklasyfikacja

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
