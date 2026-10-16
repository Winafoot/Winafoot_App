---
name: Touchline
colors:
  primary: "#212121"
  secondary: "#6E6E6E"
  tertiary: "#518948"
  neutral: "#EFF4EF"
typography:
  h1:
    fontFamily: Poppins
    fontSize: 28px
  body-md:
    fontFamily: Poppins
    fontSize: 15px
  label-caps:
    fontFamily: Poppins
    fontSize: 12px
rounded:
  sm: 8px
  md: 12px
  lg: 20px
  pill: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
---

## Overview

Sporting Minimalism meets Tactical Clarity. Wina is a calm, monochrome-green
system designed to be read at a glance on a tablet held at arm's length on the
touchline — legible under stadium light, quiet enough to keep the coach's
attention on the pitch. It is built tablet-first for a fixed 1194×834 canvas.

The palette is a single brand green driven across every interactive surface,
laid over a warm greenish off-white, with near-black ink for hierarchy. The
only chromatic exceptions are the jersey accents used to distinguish players on
the field, and a single destructive red reserved for irreversible actions.

## Colors

A high-contrast neutral core with one brand accent that drives all interaction.
Every value below is a live token on `AppColor` in `lib/config/theme.dart`.

Brand & interaction
- **Tertiary — Vert Wina (#518948):** `primaryColor`. The sole driver of
  interaction — primary buttons, active states, links, and accents. Wina's
  identity color and its most important non-ink hue.
- **Pitch green (#547824):** `pitchGreen`. The illustrated pitch/turf.

Ink / text
- **Primary (#212121):** `primaryLabels`. Near-black. The dominant text color
  and the fill of the dark bottom navigation bar.
- **Secondary (#6E6E6E):** `secondaryLabels`. Slate for captions, metadata, and
  supporting copy, typically rendered around 65% opacity.
- **Ink navy (#02132B):** `inkNavy`. Field text and placeholders, used near 40%
  opacity.

Surfaces & backgrounds
- **Neutral (#EFF4EF):** `background` / `decorationColor`. The warm, faintly
  green off-white foundation — softer than pure white.
- **Surface (#FFFFFF):** `surface` / `cellsBackground` / `fieldsBackground`.
  Cards, sheets, dialogs, list cells, and form fills.
- **Chip background (#DCE7DB):** `chipBackground`. Very pale green fill for
  information pills (position, strong foot).

Lines & states
- **Divider (#E3E3E3):** `divider`. Separators and hairlines.
- **Disabled (#D9D9D9):** `disabled`. Switch tracks and inactive elements.
- **Destructive (#FC4141):** `destructive`. Reserved for irreversible actions
  such as "Supprimer le joueur" (text + icon only).
- **Scrim (#000000 @ 30%):** `scrim` (`0x4D000000`). Modal veil behind dialogs.
- **Text light (#FFFFFF):** `textLight`. Light text/icons on green or dark
  surfaces (buttons, nav bar).

Jersey & data-viz accents
- **Jersey — starter (#2AC1DD):** `jerseyStarter`. Cyan jerseys for the starting
  eleven and on-pitch highlights.
- **Jersey — substitute (#4780FF):** `jerseySub`. Blue jerseys for substitutes.
- **Captain line (#DFD82D):** `captainLine`. Yellow rim of the "Cap." badge.
- **Jersey swatches (11 tokens):** `jerseyRed`, `jerseyBlue`, `jerseyLightBlue`,
  `jerseyGreen`, `jerseyLightGreen`, `jerseyYellow`, `jerseyOrange`,
  `jerseyPink`, `jerseyGrey`, `jerseyBlack`, `jerseyWhite`. Representative tints
  for the coach's selectable team-jersey colors (`JerseyColorOption`).
  `jerseyLightBlue` shares its tone with `jerseyStarter` but stays a separate
  token so the picker swatch and the starter highlight can diverge.

Gradients
- **Button gradient (#5B9452 → #3F7A39):** `buttonGradientTop/Bottom`. Solid
  fill for green action CTAs ("Consulter").
- **Chip gradient (#5B9452 → #3F7A39 @ 12%):** `chipGradientTop/Bottom`
  (`0x1F…`). Translucent pills for date and match-result badges over white.

## Typography

One typeface, ranged by weight rather than by family. Sizes are logical pixels
passed to `AppThemeStyle` helpers and scaled responsively through `sp()`.

Weights map to helpers on `AppThemeStyle`: `lightStyle` (w300), `regularStyle`
(w400), `mediumStyle` (w500), `semiBStyle` (w600 — the workhorse, used across
headings, titles, and emphasis), and `boldStyle` (w700).

Scale (logical px), grouped by role:
- **Display:** 34, 30 — sparing, hero moments.
- **h1:** 28 (w600) — the primary heading tier.
- **h2:** 24, 22 — section headers.
- **h3 / title:** 21, 20, 18, 17 — card and panel titles (18 is common).
- **Subtitle:** 16.
- **Body:** 15 is the de-facto default (by far the most-used size), 14 the
  secondary body.
- **Label / caption:** 13, 12, 11.
- **Overline / micro:** 10, 9, 8, 7 — badges and micro-labels.

> ⚠ **Known drift — typeface.** The `AppThemeStyle.poppinsFont` constant is named
> for Poppins, and **Poppins** ships bundled in `pubspec.yaml` (weights 300–700)
> as the intended brand face — but the constant's value is currently
> `"Helvetica"`, so the app renders in the system face at runtime. Tokens above
> reflect design intent (Poppins); reconcile the constant to render as designed.

## Shape & spacing

**Radii** — every corner runs through the responsive `r()` helper; values are the
literal passed to it (e.g. `BorderRadius.circular(r(12))`).
- **sm 8 / 10** — small chips, badges, compact tiles.
- **md 12** — the default radius for cards, inputs, and stat panels (most common
  by a wide margin).
- **14 / 16 / 18** — larger cards, avatars, and section headers.
- **lg 20** — bottom-sheet tops (`BorderRadius.vertical`) and dialogs.
- **24 / 28** — prominent pill buttons and large avatars.
- **pill 999** — fully-rounded shapes: toggles, segmented controls, circular
  badges and avatars.

**Spacing** — funnelled almost entirely through responsive helpers: `sh(n)`
(vertical gaps), `sw(n)` (horizontal gaps), and `formatWidth(n)` /
`formatHeight(n)`. Raw `EdgeInsets`/`padding` literals are essentially absent.
- **Base scale:** 4, 8, 12, 16, 20, 24, 28 (a dense ramp — 6, 10, 14, 18 are
  also frequent). Vertical rhythm favors 8 / 12 / 14 / 18 / 20; horizontal gaps
  favor 8 / 10 / 16 / 24.
- **xs 4 · sm 8 · md 16 · lg 24** are the clearest anchors.
- **Note:** `formatWidth` / `formatHeight` double as *sizing* helpers, so large
  values (40, 70, 80+) are fixed component dimensions, not gap spacing.
- **Nav clearance:** scrollable areas reserve `kBottomNavClearance = 88` at the
  bottom so content can scroll clear of the floating bottom bar.

## Implementation notes

- **Source of truth:** `lib/config/theme.dart` — `AppColor` (colors),
  `AppThemeStyle` (text styles), plus `initTheme()` which wires the Kosmos
  package themes.
- **Responsive units:** `sp()` (font size), `sh()` / `sw()` (spacing), `r()`
  (radius), `formatWidth()` / `formatHeight()` (spacing + fixed sizing), all
  relative to the 1194×834 tablet canvas.
- **House rules:** no inline `Color(0x…)`, no inline `TextStyle`,
  no `SizedBox` for vertical spacing — always `AppColor.*`,
  `AppThemeStyle.*Style(...)`, and `sh(...)`. New colors go in `AppColor`.
