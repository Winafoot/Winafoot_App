#!/usr/bin/env bash
# Wina E2E — run every scenario script, capturing a screenshot gallery.
# Usage:  bash test/e2e/run_all.sh   (emulator-5554 must be running & logged in)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
require_device

rm -f "$RESULTS"/*.png 2>/dev/null || true
echo "════════════════════════════════════════════════════"
echo " Wina E2E — device: $DEVICE   results: $RESULTS"
echo "════════════════════════════════════════════════════"

fail=0
for s in "$HERE"/0*.sh; do
  echo ""
  echo "━━━ $(basename "$s") ━━━"
  if bash "$s"; then :; else echo "  ✗ $(basename "$s") exited non-zero"; fail=1; fi
done

echo ""
echo "════════════════════════════════════════════════════"
n=$(ls -1 "$RESULTS"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo " Done — $n screenshots in $RESULTS/"
[ "$fail" = 0 ] && echo " All scripts completed." || echo " Some scripts reported a non-zero exit."
echo "════════════════════════════════════════════════════"
exit $fail
