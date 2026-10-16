import { logAccessDeniedFor } from "../../runtime/access_denied";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { handleNotificationRequest, type NotificationRequest } from "./add_notification";
import { describeError } from "../../utils/describe_error";

/**
 * Garde devant `handleNotificationRequest` (socle) : l'expéditeur est l'appelant (`senderId` issu
 * du jeton), et le seul destinataire accepté est l'appelant lui-même. C'est l'usage de l'app
 * (MatchRepository._notifyMatchFinished : `addNotifTo: [uid de l'appelant]`).
 */
export default async (data: NotificationRequest, caller: AuthedCaller): Promise<boolean> => {
  assertCallerIsOnlyRecipient(data?.addNotifTo, caller.uid);

  try {
    await handleNotificationRequest({ ...data, senderId: caller.uid });
    return true;
  } catch (e) {
    logger.error(`[Error] addNotification: ${describeError(e)}`);
    throw new HttpsError("internal", "Échec de l'envoi de la notification.");
  }
};

/** Exactement un destinataire : l'appelant. Évite aussi toute boucle d'écritures non bornée. */
function assertCallerIsOnlyRecipient(addNotifTo: unknown, callerUid: string): void {
  if (!Array.isArray(addNotifTo) || addNotifTo.length !== 1) {
    logAccessDeniedFor(callerUid, "notification-recipients-invalid");
    throw new HttpsError("invalid-argument", "addNotifTo doit contenir uniquement votre identifiant.");
  }

  if (addNotifTo[0] !== callerUid) {
    logAccessDeniedFor(callerUid, "notification-recipient-other");
    throw new HttpsError("permission-denied", "Vous ne pouvez notifier que vous-même.");
  }
}
