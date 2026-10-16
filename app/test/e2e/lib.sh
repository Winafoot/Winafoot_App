#!/usr/bin/env bash
# Wina — E2E driver helpers (coordinate-based ADB).
#
# Target: Pixel Tablet emulator, 2560x1600. The app is tablet-only with a fixed
# 1194x834 design scaled to the device, so on-screen layout is deterministic and
# coordinate taps are stable across runs. (Flutter renders to a canvas, so
# uiautomator cannot find elements by text — hence coordinates.)
#
# Every step captures a screenshot into results/ so the run can be reviewed.
# Coordinates are in DEVICE pixels (2560x1600).

set -uo pipefail

DEVICE="${WINA_E2E_DEVICE:-emulator-5554}"
PKG="fr.winafoot.app"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS="${WINA_E2E_RESULTS:-$HERE/results}"
mkdir -p "$RESULTS"
STEP=0

a()     { adb -s "$DEVICE" "$@"; }
tap()   { a shell input tap "$1" "$2";                         sleep "${3:-1.2}"; }
swipe() { a shell input swipe "$1" "$2" "$3" "$4" "${5:-450}"; sleep "${6:-1.2}"; }
typ()   { a shell input text "$1";                             sleep "${2:-0.8}"; }   # no spaces (use %s)
back()  { a shell input keyevent 4;                            sleep "${1:-1}"; }
note()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()    { printf '   \033[0;32m✓ %s\033[0m\n' "$*"; }

# shot <name> [settle] : numbered screenshot into results/.
# Settles first (default 0.8s) — the emulator's screencap can otherwise catch a
# mid-transition frame (empty fields, half-open menus), giving false negatives.
shot()  {
  sleep "${2:-0.8}"
  STEP=$((STEP+1)); local n; n=$(printf '%03d' "$STEP")
  a exec-out screencap -p > "$RESULTS/${n}_$1.png"
  printf '   📸 %s_%s\n' "$n" "$1"
}

launch()  { a shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 5; }
restart() { a shell am force-stop "$PKG"; sleep 1; launch; }

# Wait until the app package is the foreground window (best-effort).
wait_app() { local i; for i in $(seq 1 15); do a shell dumpsys window 2>/dev/null | grep -q "$PKG/" && return 0; sleep 1; done; }

# --- Bottom navigation (Mon équipe home) ---
nav_equipe() { tap 357  1463; }   # « Mon équipe »
nav_ia()     { tap 737  1463; }   # « IA » (coming soon)
nav_stats()  { tap 1816 1463; }   # « Statistiques matchs »
nav_test()   { tap 2195 1463; }   # « Test équipe »
coup_denvoi(){ tap 1280 1381; }   # floating « Coup d'envoi »

require_device() {
  a get-state 2>/dev/null | grep -q device || { echo "✗ $DEVICE not connected"; exit 1; }
}
