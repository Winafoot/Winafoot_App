#!/usr/bin/env bash
# E2E 04 — Onglet « Test équipe » + constructeur de composition.
# Validated 2026-06-30 on emulator-5554.
#
# The full CRUD (create / edit / duplicate / delete / favorite / filter /
# search) and « Tester mon équipe » (assign players → stats panel → remove) were
# validated end-to-end against live Firestore in this session (and the test
# documents were cleaned up). This script drives the navigation + the create
# entry; it intentionally does NOT submit the modal, to stay repeatable without
# polluting the account.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$HERE/lib.sh"
require_device

note "04 · Test équipe (gestion des compositions)"
restart; wait_app; sleep 2
nav_test                          # onglet « Test équipe »
shot 04_test_equipe               # Type d'équipe / recherche / perso / standards

note "Créer une composition (constructeur)"
tap 2271 418 2                    # « Créer une composition »
shot 04_constructeur              # « Aucun nom » / Personnalisé + terrain glissable
tap 1147 401 2                    # « Créer la composition personnalisée »
shot 04_popup_enregistrer         # popup nom + schéma
back 1                            # fermer la popup
back 1                            # retour onglet
shot 04_retour_test_equipe
ok "04 test équipe + constructeur"
