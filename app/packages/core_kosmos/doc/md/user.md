# UserModel

Durant le développement de vos applications, vous allez avoir besoin de customiser et/ou ajouter des données de l'`UserModel` de base. Nous allons voir et expliquer comment ajouter votre propre `Class Freezed` à l'`UserModel` du skeleton.

#### 1. UserModel par défaut

L'`UserModel` par défaut contient les données nécessaires pour les différents packages ainsi que la plupart des données de l'utilisateur utile pour votre application.

```Dart
@Freezed(genericArgumentFactories: true)
class UserModel<R> with _$UserModel<R> {
  const factory UserModel({
    final String? id,
    final String? email,
    final String? phone,
    final String? firstname,
    final String? lastname,
    @Default(false) final bool enablePushNotification,
    @Default(false) final bool enableEmailNotification,
    final String? fcmToken,
    final String? profilImage,
    final String? stripeId,
    final String? language,
    final bool? cguAccepted,
    final bool? profilCompleted,
    final bool? isFirstLogin,
    @Default("default") final String userType,

    ///Required for Tchat
    final String? pseudo,
    @TimestampConverter() final DateTime? createdAt,
    @TimestampConverter() final DateTime? lastSeen,

    ///Required for Position
    @GeoPointConverters() final GeoPoint? lastKnownPosition,
    @TimestampConverter() final DateTime? lastKnownPositionUpdate,

    /// Special data for applicatin
    R? userData,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json, R Function(Object?) fromJsonR) => _$UserModelFromJson(json, fromJsonR);
}
```
---------
#### 2. Ajouter vos données

Comme vous pouvez le voir, l'argument `userData` est un Template vous permettant de définir depuis le main de l'application.
Tout d'abord, le type `R` doit être un objet Freezed (fortement conseillé), cela vous permettra d'utiliser directement les fonction `fromJson` et `toJson` pour l'initialisation de votre objet/model.

````Dart
@freezed
class Tester with _$Tester {
  const factory Tester({
    String? data,
  }) = _Tester;

  factory Tester.fromJson(Map<String, dynamic> json) => _$TesterFromJson(json);
}
````

Dans cet exemple, une `String` sera stocké dans la `map` `userData`.

***/!\\ Attention***, les données de votre Objet doivent absolument être dans une `map` avec pour key `userData` dans FirebaseFirestore.

Exemple (Json Firestore):
```JSON
{
    "email": ...
    "firstname": ...
    "lastname": ...
    "userData": {
        "data": "Exemple de valeur pour Tester.data" // est une String
    }
}
```
---------
#### 3. Configurer votre application

Afin de faire comprendre à l'`userProvider` que votre `UserModel`utilise votre extension, il faut paramétrer le type `R` ainsi que la fonction `fromJson`.
Pour cela, vous devez depuis votre `AppModel` configurer la variable `userConfig`.

Vous devez affecter à la variable `fromJson` la fonction de votre Objet.

Exemple:

````Dart
AppModel<Tester>(
    userConfig: UserConfig(fromJson: Tester.fromJson),
)
````

***/!\ Attention***, si vous n'utilisez pas d'extension à l'`UserModel` vous devez quand même spécifié la configuration (voir exemple ci-dessous).
````Dart
AppModel(
    userConfig: UserConfig(fromJson: (_) => null), //userData sera toujours égale à null
)
````

#### 3.5 toJson

Si vous souhaitez utiliser la fonction `toJson` de l'`UserModel` vous devez à chaque utilisation spécifié la fonction `toJson` de votre extension.

Exemple:
````Dart
/// La fonction printInDebug va print les informations de l'utilisateur ainsi que l'userData
/// Exemple:
/// {
///     "email": ...
///     "userData": {
///         ...
///     }    
/// }
///
printInDebug(ref.read(userProvider).user?.toJson((p0) => Tester.toJson(p0)));
````

Si jamais vous n'utilisez pas d'extension, vous pouvez juste retourner une valeur null.
Exemple:
````Dart
/// La fonction printInDebug va print les informations de l'utilisateur ainsi que l'userData
/// Exemple:
/// {
///     "email": ...
///     "userData": null
/// }
///
printInDebug(ref.read(userProvider).user?.toJson((p0) => null));
````


#### 4 userProvider

Afin de récupérer les données de votre `UserModel`, il existe le provider `userProvider` permettant
de récupérer via un stream toutes les données de votre utilisateur.

Si vous utilisez le **Skeleton** ainsi que les `Page Parent` (voir doc PageParent), la variable `user` sera forcément non-null.
Vous pourrez donc récupérer les données de l'utilisateur de la façon suivante:

````Dart
ref.read(userProvider).user! // Forcément non-null

/// Vous pouvez donc accéder à votre extension via la variable userData
ref.read(userProvider).user!.userData // celle-ci sera automatique du Type donnée dans l'AppModel.
````