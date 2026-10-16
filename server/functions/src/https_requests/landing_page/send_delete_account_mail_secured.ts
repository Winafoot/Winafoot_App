import { randomBytes } from "node:crypto";
import type { Response } from "express";
import { firestore } from "firebase-admin";
import { LIMITS } from "../../config/rate_limits";
import { isAdminRecord } from "../../callables/admin/_admin_accounts";
import { UserModel } from "../../model/user/user_model";
import { logger } from "../../runtime/firebase";
import { generateTemplateAccountDeletionEmail } from "../../template/email_delete_account";
import { consumeAll } from "../../utils/rate_limit";
import { sendEmail } from "../../utils/send_email";
import { authUserByEmail, landingBaseUrl, landingEndpoint, normalizeEmail, requireCaptcha } from "./_landing_endpoint";

const TOKEN_TTL_MS = 24 * 3_600_000;
// Un jeton déjà en attente n'est réutilisé que s'il reste de quoi agir sur le lien du mail.
const REUSE_MIN_REMAINING_MS = 3_600_000;

interface Plan {
  token: string;
  isDeleted: boolean;
  /** Vrai si le jeton vient d'être créé pour cette demande (donc à retirer si le mail échoue). */
  created: boolean;
}

/**
 * Demande de suppression de compte (public/delete-account.html : POST { email }).
 *
 * - Le lien du mail vise toujours la landing (landingBaseUrl), jamais une adresse venue de la requête.
 * - Un jeton n'est créé que pour un compte existant (et non administrateur). Pour une adresse dont le
 *   compte est déjà supprimé, le mail porte `isDeleted=true` (la page affiche « déjà supprimé »), sans
 *   jeton utilisable.
 * - La réponse est la même 200 dans tous les cas : compte connu, inconnu, archivé, limite atteinte,
 *   échec d'envoi ou de comptage.
 * - Un jeton encore valable est réutilisé : un double clic envoie deux mails dont les liens
 *   fonctionnent tous les deux.
 */
export default landingEndpoint(
  async (body, config, res) => {
    const email = normalizeEmail(body.email);
    if (email == null) {
      res.status(400).send({ message: "Invalid email" });
      return;
    }

    // Avant toute lecture de compte : sinon un robot sans jeton valide énumère les adresses connues
    // (400 captcha pour tous) et entame les compteurs par compte et global.
    if (!(await requireCaptcha(body, res))) return;

    let plan: Plan | undefined;
    try {
      plan = await planFor(email);
    } catch (e: any) {
      logger.error(`[Error] sendDeleteAccountMail: ${e?.message ?? "erreur inconnue"}`);
    }
    if (plan == null) return respondReceived(res);

    const baseUrl = landingBaseUrl(config);
    const link = `${baseUrl}/confirm-delete.html?token=${plan.token}&isDeleted=${plan.isDeleted}`;
    const appName = config.appName ?? "Wina";
    const text =
      `Vous avez demandé la suppression de votre compte ${appName}. Pour la confirmer, ouvrez ce lien (valable 24 h au plus) :\n\n` +
      `${link}\n\n` +
      "Si vous n’êtes pas à l’origine de cette demande, ignorez ce message.";

    try {
      await sendEmail(
        config,
        Object.assign(new UserModel(), { email }),
        generateTemplateAccountDeletionEmail(email, baseUrl, plan.token, plan.isDeleted, "", appName),
        "Demande de suppression de compte",
        text,
      );
    } catch (e: any) {
      // Jeton retiré s'il vient d'être créé (un jeton réutilisé a peut-être déjà servi dans un mail
      // arrivé), échec journalisé (message seulement), réponse inchangée.
      if (plan.created) await firestore().collection("accountDeletionRequests").doc(plan.token).delete().catch(() => undefined);
      logger.error(`[Error] sendDeleteAccountMail: envoi impossible : ${e?.message ?? "erreur inconnue"}`);
    }

    respondReceived(res);
  },
  { scope: "delete-mail", perIp: LIMITS.deleteMailIp },
);

/** Même réponse 200 dans tous les cas : rien ne trahit un compte, une adresse archivée ou une limite atteinte. */
function respondReceived(res: Response): void {
  res.status(200).send({ message: "Data received" });
}

/** Ce qu'il faut envoyer, ou `undefined` s'il n'y a rien à envoyer (adresse inconnue, limite atteinte). */
async function planFor(email: string): Promise<Plan | undefined> {
  const account = await authUserByEmail(email);

  if (account != null) {
    // Un administrateur ne se supprime pas par ce lien (voir delete_account_by_email_secured) : rien à envoyer,
    // et la même réponse 200 qu'une adresse inconnue.
    if (isAdminRecord(account)) return undefined;
    const allowed = await consumeAll([
      ["delete-mail-account", account.uid, LIMITS.deleteMailAccount],
      ["delete-mail-account-day", account.uid, LIMITS.deleteMailAccountDay],
      ["public-mail-global", "all", LIMITS.publicMailGlobal],
    ]);
    return allowed ? { ...(await pendingOrNewToken(email, account.uid)), isDeleted: false } : undefined;
  }

  if (await wasDeleted(email)) {
    // Compteurs seulement pour une adresse archivée : bornés par les comptes réellement supprimés.
    const allowed = await consumeAll([
      ["delete-mail-gone", email, LIMITS.deleteMailAccount],
      ["delete-mail-gone-day", email, LIMITS.deleteMailAccountDay],
      ["public-mail-global", "all", LIMITS.publicMailGlobal],
    ]);
    // Le jeton n'est jamais enregistré : il ne sert à rien.
    return allowed ? { token: randomBytes(48).toString("hex"), isDeleted: true, created: false } : undefined;
  }

  return undefined;
}

/**
 * Réutilise le jeton en attente de CE compte s'il reste valable assez longtemps, sinon en crée un
 * nouveau. Dans les deux cas il ne reste qu'un jeton en attente pour cette adresse.
 */
async function pendingOrNewToken(email: string, uid: string): Promise<Pick<Plan, "token" | "created">> {
  const requests = firestore().collection("accountDeletionRequests");
  const pending = (await requests.where("email", "==", email).get()).docs;

  const reusable = pending.find((doc) => doc.get("uid") === uid && (doc.get("expiresAt")?.toMillis?.() ?? 0) > Date.now() + REUSE_MIN_REMAINING_MS);
  const batch = firestore().batch();

  if (reusable != null) {
    pending.filter((doc) => doc.id !== reusable.id).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return { token: reusable.id, created: false };
  }

  const token = randomBytes(48).toString("hex");
  pending.forEach((doc) => batch.delete(doc.ref));
  batch.set(requests.doc(token), { email, uid, token, expiresAt: firestore.Timestamp.fromMillis(Date.now() + TOKEN_TTL_MS) });
  await batch.commit();
  return { token, created: true };
}

async function wasDeleted(email: string): Promise<boolean> {
  const archived = await firestore().collection("deleted_users").where("email", "==", email).limit(1).get();
  return !archived.empty;
}
