# 4.0.1 Some Fixes

- Fix some issue in authentication / account creation with phone.
- Translate :

Adding new default translation:

```Json
{
    "package": {
        "kosmos-auth": {
            "code-is-expired": "Le code a expiré, veuillez en demander un nouveau.",
        },

        "ui-komsmos_v4": {
            "input": {
                "choose-multiple-file": "Appuvez pour choisir vos fichiers",
                "choose-image": "Appuvez pour choisir une photo",
                "choose-multiple-image": "Appuvez pour choisir vos photos",
            }
        },

        "core": {
            "popup": {
                "select-picture-from": "D'où souhaitez vous choisir la photo ?"
            }
        },
    }
}
```

- Mise à jour des settings, settingsSection (dans la configuration du package) utilise désormais un
  builder pour pouvoir récupérer la liste de CelluleSection.

- Upgrading Documentation:
  - Package-Core:
    - `popup.dart` file
    - `social_user.dart` file
  - Skeleton;
    - Guards
    - `MaybeLoggedUserAppCorePage`

---

Doc update :

- UiKosmos
- Research example + package
- Dynamic link + Push notifications (hanle + cloud functions)
- Package Commentaire
- Package Internal Notification
- 

```Json
{
  "package": {
    "research": {
      "hint": "Rechercher.."
    }
  }
}
```
