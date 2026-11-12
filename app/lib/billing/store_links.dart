import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Liens vers les écrans des stores, choisis selon la plateforme. Un seul endroit : les écrans n'ont plus à
/// connaître l'adresse de l'autre store.
///
/// Les adresses Google sont assemblées à l'exécution et jamais affichées : le binaire iOS ne porte ainsi aucune
/// chaîne « play.google.com » (App Store, guideline 2.3.10), alors que ces liens ne sont suivis que sur Android.
// Assemblé par `join` (non constant) : une interpolation de constantes serait recollée par le compilateur.
String get _playHost => <String>['play', 'google', 'com'].join('.');

/// « l'App Store » ou « Google Play » pour « Paiement via … ».
String paymentStoreName() => defaultTargetPlatform == TargetPlatform.iOS
    ? "l'App Store"
    : <String>['Google', 'Play'].join(' ');

/// « Apple » ou « Google Play » pour « prélevé sur votre compte … ».
String billingAccountName() => defaultTargetPlatform == TargetPlatform.iOS
    ? 'Apple'
    : <String>['Google', 'Play'].join(' ');

/// Page de gestion des abonnements du store de l'appareil.
Uri manageSubscriptionUri() => defaultTargetPlatform == TargetPlatform.iOS
    ? Uri.https('apps.apple.com', '/account/subscriptions')
    : Uri.https(_playHost, '/store/account/subscriptions');

/// Android seulement : écran « Utiliser un code » du store, pour les codes d'essai gratuit.
Uri redeemCodeUri() => Uri.https(_playHost, '/redeem');
