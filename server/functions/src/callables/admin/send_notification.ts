import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { NotificationRepository } from "../../database/notification/notification_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export const NOTIFICATION_SEGMENTS = ["profile_incomplete", "no_subscription", "subscribed", "trial", "format_5", "format_8", "format_11"] as const;
export type NotificationSegment = (typeof NOTIFICATION_SEGMENTS)[number];

export type NotificationAudience =
  | { kind: "all" }
  | { kind: "segment"; segment: NotificationSegment }
  | { kind: "uids"; uids: string[] };

export interface SendNotificationData {
  title: string;
  body: string;
  audience: NotificationAudience;
  /** Vrai : compte les destinataires sans rien envoyer (écran de confirmation). */
  dryRun?: boolean;
}

export interface SendNotificationResult {
  recipients: number;
  sent: boolean;
}

const TITLE_MAX = 80;
const BODY_MAX = 300;
/** Plafond par envoi : une erreur de segment ne peut pas notifier toute la base, et la fonction reste dans son délai. */
export const MAX_RECIPIENTS = 1000;
/** Limite FCM de `sendEachForMulticast` : un document `notifications` par tranche. */
const PUSH_CHUNK = 500;
const WRITE_CHUNK = 50;
const NOTIFICATION_TYPE = "admin-message";

type UserFields = { disabled?: boolean; profilCompleted?: boolean; teamFormat?: number; subscription?: { status?: string } };

function matches(segment: NotificationSegment, u: UserFields): boolean {
  const status = u.subscription?.status;
  switch (segment) {
    case "profile_incomplete":
      return u.profilCompleted === false;
    case "no_subscription":
      return status == null;
    case "subscribed":
      return status === "active" || status === "trial" || status === "grace";
    case "trial":
      return status === "trial";
    case "format_5":
      return u.teamFormat === 5;
    case "format_8":
      return u.teamFormat === 8;
    case "format_11":
      return u.teamFormat === 11;
  }
}

/** Destinataires : comptes actifs (non désactivés) correspondant à l'audience. Lecture des seuls champs utiles. */
async function resolveRecipients(audience: NotificationAudience): Promise<string[]> {
  const snap = await firestore().collection("users").select("disabled", "profilCompleted", "teamFormat", "subscription").get();
  const active = snap.docs.filter((d) => d.get("disabled") !== true);

  if (audience.kind === "all") return active.map((d) => d.id);
  if (audience.kind === "segment") {
    if (!NOTIFICATION_SEGMENTS.includes(audience.segment)) throw new HttpsError("invalid-argument", "Segment inconnu.");
    return active.filter((d) => matches(audience.segment, d.data() as UserFields)).map((d) => d.id);
  }

  // Liste explicite (relance depuis l'entonnoir) : seuls les comptes existants et actifs sont gardés.
  if (!Array.isArray(audience.uids) || audience.uids.some((u) => typeof u !== "string")) {
    throw new HttpsError("invalid-argument", "Liste de destinataires invalide.");
  }
  const wanted = new Set(audience.uids);
  return active.filter((d) => wanted.has(d.id)).map((d) => d.id);
}

function describeAudience(audience: NotificationAudience, count: number): string {
  if (audience.kind === "all") return `tous (${count})`;
  if (audience.kind === "segment") return `segment ${audience.segment} (${count})`;
  return `sélection (${count})`;
}

/**
 * Envoie un message à un groupe de comptes : une notification interne par compte (liste « Notifications » de
 * l'app) puis un push (document `notifications`, relayé par le déclencheur onCreateNotification). Chaque envoi
 * est journalisé avec l'audience et le nombre de destinataires, jamais le texte.
 */
export default async (data: SendNotificationData, caller: AdminCaller): Promise<SendNotificationResult> => {
  const title = typeof data?.title === "string" ? data.title.trim() : "";
  const body = typeof data?.body === "string" ? data.body.trim() : "";
  if (title.length === 0 || title.length > TITLE_MAX) throw new HttpsError("invalid-argument", `Le titre est obligatoire (${TITLE_MAX} caractères au plus).`);
  if (body.length === 0 || body.length > BODY_MAX) throw new HttpsError("invalid-argument", `Le message est obligatoire (${BODY_MAX} caractères au plus).`);
  if (data.audience == null || typeof data.audience !== "object") throw new HttpsError("invalid-argument", "Audience manquante.");

  const recipients = await resolveRecipients(data.audience);
  if (recipients.length === 0) throw new HttpsError("failed-precondition", "Aucun destinataire ne correspond.");
  if (recipients.length > MAX_RECIPIENTS) {
    throw new HttpsError("failed-precondition", `Trop de destinataires (${recipients.length}) : un envoi est limité à ${MAX_RECIPIENTS}. Affinez le segment.`);
  }
  if (data.dryRun === true) return { recipients: recipients.length, sent: false };

  const db = firestore();
  const now = firestore.Timestamp.now();
  const sender = { id: caller.uid, firstname: "Wina", lastname: "", email: caller.email ?? "" };

  try {
    for (let i = 0; i < recipients.length; i += WRITE_CHUNK) {
      await Promise.all(
        recipients.slice(i, i + WRITE_CHUNK).map((uid) =>
          db.collection("users").doc(uid).collection("notifications").add({
            title,
            body,
            type: NOTIFICATION_TYPE,
            metadata: {},
            sender,
            sendAt: now,
            isRead: false,
          }),
        ),
      );
    }
    for (let i = 0; i < recipients.length; i += PUSH_CHUNK) {
      await NotificationRepository.instance.add({
        sendToIds: recipients.slice(i, i + PUSH_CHUNK),
        title,
        body,
        type: NOTIFICATION_TYPE,
        toTopic: false,
        metadata: {},
      });
    }
  } catch (e) {
    logger.error(`[Error] sendAdminNotification: ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "send_notification",
      targetUid: "-",
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String((e as { message?: string })?.message ?? e),
      details: describeAudience(data.audience, recipients.length),
    });
    throw new HttpsError("internal", "L'envoi a échoué, certains comptes ont pu le recevoir. Réessayez avec prudence.");
  }

  await AdminAuditRepository.instance.record({
    action: "send_notification",
    targetUid: "-",
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    details: describeAudience(data.audience, recipients.length),
  });

  return { recipients: recipients.length, sent: true };
};
