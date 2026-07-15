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

## Cel kalibracyjny (weryfikowany empirycznie, N≥5)

- wariant A (bez configu): sukces **20–70%**
- wariant B (z configiem): sukces **>85%**
- poza widełkami → zadanie do przeprojektowania (za łatwe = mierzy tylko koszt; nietykalne dla A
  przez brak jakiegokolwiek sygnału = trik, nie benchmark)

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
