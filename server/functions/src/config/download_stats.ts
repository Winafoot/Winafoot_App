/**
 * Réglages (non secrets) des statistiques de téléchargement du tableau de bord. Tant qu'une valeur est vide, le
 * tableau de bord indique ce qui manque pour la boutique concernée, sans erreur.
 */

/**
 * Numéro de fournisseur Apple : App Store Connect, Ventes et tendances (en haut à gauche, sous le nom du compte),
 * ou Paiements et rapports financiers. Une suite de chiffres, par exemple « 91234567 ».
 */
export const APPLE_VENDOR_NUMBER = "94413466";

/**
 * Espace de stockage des rapports Google Play : Play Console, Télécharger les rapports, Statistiques, bouton
 * « Copier l'URI Cloud Storage ». Le nom commence par « pubsite_prod_rev_ » (on peut coller l'URI `gs://…` entier).
 */
export const GOOGLE_REPORTS_BUCKET = "";
