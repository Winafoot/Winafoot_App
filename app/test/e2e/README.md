# Wina — E2E (real device, ADB-driven)

End-to-end smoke/journey tests that drive the **real app** on the Android
emulator via `adb`, capturing a screenshot at every step for review.

## Why coordinate-based?

The app renders through a Flutter canvas, so `uiautomator` cannot see widgets by
text (a dump returns only a couple of generic `FrameLayout` nodes). Element
finders therefore aren't available — these tests tap **device-pixel
coordinates** instead. That's reliable here because the app is **tablet-only**
with a fixed `1194×834` design scaled to the emulator's **`2560×1600`**, so the
layout is deterministic across runs. (All coordinates in the scripts are for
that resolution.)

Because there's no text oracle, **assertions are visual**: each step writes a
numbered screenshot into `results/`, which you (or CI with an image diff) review.
For assertion-based E2E with logic oracles, the next step up is Flutter's
`integration_test` package with semantic finders — but that's a different harness
and doesn't exercise the real signed-in build the way this does.

## Prerequisites

- Emulator `emulator-5554` running (Pixel Tablet, 2560×1600).
- The app installed and **logged in** (session persists; tests start from the
  `Mon équipe` home). Test account used during development: `test@client.test`.
- `adb` on PATH.

## Run

```bash
bash test/e2e/run_all.sh           # all scenarios
bash test/e2e/02_coup_denvoi.sh    # a single scenario
WINA_E2E_DEVICE=<serial> bash test/e2e/run_all.sh   # other device
```

Screenshots land in `test/e2e/results/` (git-ignored), numbered in run order.

## Scenarios

| Script | Flow | Status |
|---|---|---|
| `01_home_player.sh` | Mon équipe (roster) → Créer un joueur (form: nom/prénom/pied fort/catégorie) | ✅ validated (create+banner+cleanup done manually; form-fill in script, submit omitted to stay repeatable) |
| `02_coup_denvoi.sh` | Assistant: adversaire → maillots (domicile + couleur adverse) → hub | ✅ validated end-to-end |
| `03_gerer_equipe.sh` | Hub → Gérer mon équipe → nombre de joueurs → numéros → composition | ✅ validated to the composition chooser |
| `04_test_equipe.sh` | Onglet Test équipe → constructeur → popup d'enregistrement | ✅ nav validated (full CRUD + Tester validated live separately, see below) |
| `05_tabs.sh` | Barre du bas: Mon équipe / IA / Statistiques / Test équipe | ✅ validated |

### Validated live against Firestore (test@client.test), then cleaned up

Done interactively during development (not in the repeatable scripts, to avoid
writing to the account on every run):

- **Créer un joueur** → green « Joueur créé ! » banner, count 17→18, then deleted.
- **Test équipe CRUD** → create / favorite / duplicate / edit (rename) / delete,
  each confirmed in the live `users/{uid}/compositions` collection, then removed.
- **Tester mon équipe** → assign players to slots, select for stats panel,
  « Retirer du terrain » — full cycle.

## Helpers (`lib.sh`)

`tap x y [settle]`, `swipe x1 y1 x2 y2 [ms]`, `typ "text"` (no spaces — Android
`input text`), `back`, `shot name` (settles, then numbered screenshot),
`launch` / `restart`, and bottom-nav shortcuts (`nav_equipe`, `nav_stats`,
`nav_test`, `coup_denvoi`).

> Tip: `shot` settles ~0.8 s before capturing — the emulator's `screencap`
> otherwise occasionally grabs a mid-transition frame (empty fields, half-open
> menus), which reads as a false negative.

## Extending

Add a screen by: drive the step, `screencap` to read the layout, derive the
device-pixel coordinate (`img_coord × 2560/img_width`), add `tap`/`typ`/`shot`
lines, and re-run that one script to confirm. Keep mutating flows out of the
repeatable run (or pair them with a cleanup) so the suite stays idempotent.
