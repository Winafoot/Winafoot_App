# Scripts d'administration

## set-admin

Attribue le custom claim `admin` — la seule chose qui ouvre l'accès au
back-office (`cms/`) et à la lecture des fiches coach dans `firestore.rules`.

Prérequis :

1. `gcloud auth application-default login` (identifiants applicatifs par défaut).
2. Un **projet de quota** associé à ces identifiants, sinon l'appel à
   `identitytoolkit.googleapis.com` est refusé (403 « requires a quota project »).
   Deux façons de le fournir :
   - une fois pour toutes : `gcloud auth application-default set-quota-project wina-c4c4a` ;
   - ou par exécution, via la variable d'environnement `GOOGLE_CLOUD_QUOTA_PROJECT`
     (voir les commandes ci-dessous).

```bash
# Donner l'accès
GOOGLE_CLOUD_QUOTA_PROJECT=wina-c4c4a npm --prefix functions run set-admin -- staff@example.com

# Le retirer
GOOGLE_CLOUD_QUOTA_PROJECT=wina-c4c4a npm --prefix functions run set-admin -- staff@example.com --revoke
```

(Si le projet de quota est déjà configuré via `set-quota-project`, le préfixe
`GOOGLE_CLOUD_QUOTA_PROJECT=...` est inutile.)

Le compte doit déjà exister dans Firebase Auth (créé à la console, méthode
e-mail + mot de passe). Le jeton est révoqué au passage : l'administrateur doit
se reconnecter pour que le claim prenne effet.

## algolia-reindex

Réindexe les compositions et les matchs terminés dans Algolia, applique les réglages des index et purge par
réconciliation les enregistrements orphelins (`--dry-run`, `--settings-only`, `--purge-orphans`). Refuse de démarrer si
`FIRESTORE_EMULATOR_HOST` ou `FIREBASE_AUTH_EMULATOR_HOST` est défini (le script cible la production).
Même prérequis ADC que ci-dessus. La clé temporaire `wina-setup` se saisit avec `read -rs ALGOLIA_REINDEX_KEY` et se passe
à une seule commande, sans `export`. Procédure complète : README du dépôt, section « Recherche ».

> Note d'implémentation : le script vit sous `functions/scripts/` (et non à la
> racine) pour que Node résolve `firebase-admin` depuis `functions/node_modules`
> au runtime.
