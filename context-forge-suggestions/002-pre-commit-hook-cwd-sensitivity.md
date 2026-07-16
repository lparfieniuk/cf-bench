# Sugestia CF-002: pre-commit-review marker wrażliwy na cwd sesji

Status: PROPOZYCJA — bug znaleziony w praktyce 2026-07-16 podczas pracy nad cf-bench.

## Problem

`hooks/pre-commit-review.sh` liczy `SESSION_HASH` z cwd **sesji w momencie PreToolUse** —
a nie z katalogu repo, którego dotyczy commit. Skutki zaobserwowane:

1. Komenda `cd ~/repo && git commit ...` jest blokowana, jeśli poprzednia komenda zostawiła
   cwd sesji w podkatalogu (`~/repo/cf-bench`) — hook hashuje podkatalog, marker istnieje
   tylko dla korzenia. `cd` wewnątrz komendy nie pomaga: hook odpala się PRZED wykonaniem.
2. Review wykonany → commit i tak zablokowany → użytkownik/agent uczony jest sięgać po
   `SKIP_REVIEW=1` — hook antywzorcem trenuje własne obejście.

## Proponowana naprawa

W hooku, zamiast hashować surowe `HOOK_CWD`, znormalizować do korzenia repo:

```bash
REPO_ROOT=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null || echo "$HOOK_CWD")
SESSION_HASH=$(printf "%s" "${REPO_ROOT}:$(whoami)" | pwd_hash | cut -c1-8)
```

Analogicznie w skillu `pre-review` (instrukcja tworzenia markera) — dziś skill każe hashować
`$PWD`, co ma tę samą wadę. Dodatkowo: skill i hook mają rozjazd `printf` vs `echo` — nieszkodliwy
tylko dlatego, że `pwd_hash` robi `tr -d '\n'`; ujednolicić na `printf` dla jasności.

## Drugi przypadek z praktyki (2026-07-16, ta sama sesja)

Sesyjny cwd wskazywał **skasowany katalog mktemp** (poprzednia komenda robiła `cd "$W" && ... &&
rm -rf "$W"`) — hook hashował ścieżkę-widmo i blokował commit mimo świeżego review. Normalizacja
do `git rev-parse --show-toplevel` rozwiązuje też ten wariant (fallback gdy git zawiedzie:
blokuj z komunikatem "nieznany cwd", nie z mylącym "brak review").

## Test akceptacyjny

1. `/pre-review` w korzeniu repo → marker.
2. `cd podkatalog` (osobna komenda) → `cd korzeń && git commit` → MUSI przejść.
3. Commit w repo bez markera → nadal blokowany.

## Bonus (odkryte przy okazji)

Marker nie jest konsumowany po commicie — jeden review "odblokowuje" wszystkie kolejne commity
sesji na zawsze. Rozważyć: `mtime` markera < N minut albo kasowanie markera w PostToolUse po
udanym commicie (świadomy trade-off między frykcją a rygorem).
