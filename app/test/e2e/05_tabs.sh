#!/usr/bin/env bash
# E2E 05 — Navigation barre du bas : IA / Statistiques matchs / Test équipe.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$HERE/lib.sh"
require_device

note "05 · Onglets (navigation basse)"
restart; wait_app; sleep 2
shot 05_mon_equipe
nav_ia                            # « IA » (à venir)
shot 05_ia
nav_stats                         # « Statistiques matchs »
shot 05_statistiques
nav_test                          # « Test équipe »
shot 05_test_equipe
nav_equipe                        # retour « Mon équipe »
shot 05_retour_mon_equipe
ok "05 navigation onglets"
