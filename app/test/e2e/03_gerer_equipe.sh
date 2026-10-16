#!/usr/bin/env bash
# E2E 03 — Gérer mon équipe : nombre de joueurs → numéros → composition.
# Reached from the Coup d'envoi hub. Validated 2026-06-30 on emulator-5554.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$HERE/lib.sh"
require_device

note "03 · Gérer mon équipe (composition)"
restart; wait_app; sleep 2

# Coup d'envoi → étape 1 → 2 → 3 (hub), comme 02 mais condensé.
coup_denvoi
tap 1697 717; typ "AdvTest"; tap 1280 1423          # adversaire → Suivant
tap 739 562; tap 1917 854 1.4; tap 1886 477; tap 1280 1423   # maillots → Suivant
shot 03_hub
tap 616 670 2                                       # « Gérer mon équipe »
shot 03_nombre_joueurs                              # « Choisissez le nombre de joueurs »

note "11 joueurs → numéros → composition"
tap 820 556 2                                        # « Choisir » (11 joueurs)
shot 03_attribuez_numeros                           # C / R / N° par joueur
tap 2330 327 2                                       # « Suivant » → composition
shot 03_choisissez_composition                      # standards + perso + recherche

# NOTE: la suite (sélection d'un schéma → « Suivant » → écran de placement où
# l'on glisse les joueurs → « Valider ») a été validée manuellement plus tôt et
# est couverte par 04 (constructeur) + le « Tester mon équipe » de Test équipe.
ok "03 gérer mon équipe (count → numéros → composition)"
