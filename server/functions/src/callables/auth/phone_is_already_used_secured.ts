/**
 * phoneIsAlreadyUsed, appelable sans authentification : même contrat que emailIsAlreadyUsed, répond
 * toujours `true` sans lire de compte.
 *
 * Le paquet kosmos_auth (phone_login_page, set_phone_page, change_phone_page, create_account_page)
 * l'appelle ; ces écrans ne sont pas proposés dans l'app (canLoginWithPhone = false). Si l'un d'eux
 * l'était, `true` signifierait « numéro déjà pris » : l'unicité se vérifierait alors autrement.
 */
export default async (_data?: unknown): Promise<boolean> => true;
