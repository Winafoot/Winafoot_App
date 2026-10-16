#!/usr/bin/env bash
# E2E 01 — Mon équipe (home) + Créer un joueur.
# Validated 2026-06-30 on emulator-5554 (logged in as test@client.test).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$HERE/lib.sh"
require_device

note "01 · Mon équipe (accueil) + Créer un joueur"
restart; wait_app; sleep 2
shot 01_home_mon_equipe          # roster grouped Gardiens/Défenseurs/Milieux/Attaquants

note "Créer un joueur — formulaire"
tap 2299 326                     # « Créer un joueur »
shot 01_creer_joueur_form
tap 1280 503; typ "E2EBot"       # Nom du joueur
tap 1280 695; typ "Test"         # Prénom du joueur
tap 1280 887 1.4; tap 982 887    # Pied fort → Droit
tap 1280 1081 1.4; tap 1024 1368 # Catégorie de poste → Attaquant
shot 01_creer_joueur_rempli      # all fields filled, « Créer le joueur » enabled

# NOTE: tapping « Créer le joueur » (tap 1280 1238) persists a real player and
# shows the green « Joueur créé ! » banner (count 17→18). It is omitted from the
# repeatable run to avoid polluting the account; it was validated manually and
# the test player was deleted afterwards.

back 1                           # ← retour
shot 01_retour_home
ok "01 home + créer un joueur"
