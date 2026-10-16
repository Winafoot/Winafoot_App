/**
 * emailIsAlreadyUsed, appelable sans authentification : répond toujours `true`, sans lire de compte.
 *
 * « Mot de passe oublié » (login_page.dart du socle, paquet kosmos_auth) l'appelle AVANT
 * sendResetPassword et s'arrête si la réponse n'est pas `true` : il reste donc exporté. L'absence
 * de compte est traitée par sendResetPassword, qui répond lui aussi de façon uniforme.
 *
 * Les autres écrans du socle qui l'appellent (création de compte, connexion Google/Apple,
 * changement d'adresse) ne sont pas proposés dans l'app. Si l'un d'eux l'était, `true` lui
 * répondrait « adresse déjà utilisée » : l'unicité se vérifierait alors autrement.
 */
export default async (_data?: unknown): Promise<boolean> => true;
