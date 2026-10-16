# Paquets Kosmos

Paquets maison sur lesquels repose l'application, intégrés ici comme code source ordinaire et
référencés en `path:` : le dépôt se compile seul, sans accès à d'autres dépôts.

## Rôle des paquets

| Paquet | Rôle |
|---|---|
| `core_kosmos` | Socle : lancement de l'app, configuration `app_config/metadata`, modèle utilisateur, fichiers et images, utilitaires |
| `ui_kosmos_v4` | Composants d'interface |
| `skeleton` | Coquille de l'app : connexion, création de compte, pages parentes selon l'état de connexion, pages de profil et de sécurité |
| `kosmos_auth` | Authentification : e-mail, téléphone, fournisseurs tiers |
| `settings_kosmos` | Pages de paramètres et de profil |
| `permissionrequest` | Demandes de permissions système |

## Provenance

Chaque paquet a été importé au commit figé dans `pubspec.lock` au moment de l'import, soit le code
avec lequel l'application était compilée.

| Paquet | Dépôt d'origine | Commit | Date |
|---|---|---|---|
| `core_kosmos` | `KosmosDigital06270/Package-Core` | `36582ee2c526` | 2026-04-29 |
| `kosmos_auth` | `KosmosDigital06270/Package-Auth` | `580dbc750e68` | 2026-04-30 |
| `permissionrequest` | `KosmosDigital06270/Package-Permission` | `df8913b8d8ff` | 2026-06-08 |
| `settings_kosmos` | `KosmosDigital06270/Package-Settings` | `72b532f7ad32` | 2026-06-08 |
| `skeleton` | `KosmosDigital06270/Package-Skeleton` | `69bf697a15c6` | 2026-06-08 |
| `ui_kosmos_v4` | `KosmosDigital06270/Package-UiKosmos` | `8989597c92f5` | 2026-06-08 |

Seul le contenu suivi par Git a été repris, sans historique ni fichiers propres aux postes de
développement (réglages d'éditeur, version locale de Flutter, fichiers générés). La version de
Flutter est celle du `.fvmrc` de l'application, pour tous les paquets.

Trois paquets de l'import d'origine, jamais utilisés par l'application (messagerie,
écrans d'accueil, signalements), ont été retirés ensuite avec leurs dépendances.

L'import est un commit à part. Chaque modification ultérieure fait l'objet de son propre
commit : `git log -- packages/` montre l'écart avec le code d'origine.

## Modifications locales

| Paquet | Modification |
|---|---|
| tous | Dépendances entre paquets en `path:` ; contrainte `^<version verrouillée>` sur chaque dépendance ; documentation d'origine sans données de contact ni identifiants d'accès ; notes de travail des commentaires remplacées par une description ou retirées |
| `core_kosmos`, `skeleton` | Connexion biométrique : e-mail et mot de passe conservés seulement si elle est activée, dans le trousseau iOS ou le Keystore Android (`flutter_secure_storage`) ; anciennes valeurs effacées au lancement et à la déconnexion (`LocalAuthController`) |
| `skeleton` | `_buildWeb` d'`auth_parent.dart` applique le crochet de thème `emailLoginPageBackground` (fond de l'écran de connexion), vérifié par `test/login_background_test.dart` |
| `skeleton` | API Flutter dépréciées remplacées (`withOpacity` par `withValues`, `WillPopScope` par `PopScope`) |

## Dépendances entre paquets

Toutes en `path:`, sans cycle.

| Paquet | Dépend de |
|---|---|
| `core_kosmos` | — |
| `ui_kosmos_v4`, `kosmos_auth` | `core_kosmos` |
| `permissionrequest` | `core_kosmos`, `ui_kosmos_v4` |
| `settings_kosmos` | `core_kosmos`, `ui_kosmos_v4`, `kosmos_auth` |
| `skeleton` | `core_kosmos`, `ui_kosmos_v4`, `settings_kosmos`, `kosmos_auth` |

## Reprendre un correctif d'origine

Comparer le dépôt d'origine au commit ci-dessus, puis reporter à la main les changements
voulus, sans remplacer le dossier entier : les modifications locales seraient perdues.
