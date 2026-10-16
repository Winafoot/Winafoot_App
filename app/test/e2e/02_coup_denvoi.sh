#!/usr/bin/env bash
# E2E 02 — Assistant « Coup d'envoi » : adversaire → maillots → hub.
# Validated 2026-06-30 on emulator-5554.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$HERE/lib.sh"
require_device

note "02 · Coup d'envoi (assistant de match)"
restart; wait_app; sleep 2
coup_denvoi                      # bouton flottant « Coup d'envoi »
shot 02_step1_adversaire         # « Choix de l'adversaire »

note "Étape 1 — saisir l'adversaire → Suivant"
tap 1697 717; typ "AdvTest"      # nom de l'équipe adverse
shot 02_step1_rempli             # « Suivant » activé
tap 1280 1423                    # Suivant → étape 2
shot 02_step2_maillots           # « Choix des maillots »

note "Étape 2 — maillot domicile + couleur adverse → Suivant"
tap 739 562                      # maillot « Domicile »
tap 1917 854 1.4; tap 1886 477   # couleur adverse → Rouge
shot 02_step2_rempli
tap 1280 1423                    # Suivant → étape 3
shot 02_step3_hub                # « Gérez le match avant de démarrer »
                                 # (écusson adverse rouge, « Démarrer » désactivé)
ok "02 coup d'envoi step1→2→3"
