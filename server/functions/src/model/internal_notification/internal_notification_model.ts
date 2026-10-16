/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { SocialUser } from "../utils/social_user";

class InternalNotificationModel {
  id?: string;
  title?: string;
  body?: string;
  sendAt?: firestore.Timestamp;

  // Sender data
  senderRef?: firestore.DocumentReference;
  sender?: SocialUser;

  // Message data
  type?: string;
  metadata: { [key: string]: any } | undefined;

  // Read Status
  isRead?: boolean;
  readAt?: firestore.Timestamp;

  static fromJson(json: Map<any, any>): InternalNotificationModel {
    return Object.assign(new InternalNotificationModel(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): InternalNotificationModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let internalNotifcationModel = Object.assign(new InternalNotificationModel(), snapshot.data());

    if (snapshot.get("sender") != null && snapshot.get("sender") != undefined) {
      internalNotifcationModel.sender = SocialUser.fromJson(snapshot.get("sender"));
    }
    return internalNotifcationModel;
  }

  static toFirestore(data: Partial<InternalNotificationModel>): firestore.DocumentData {
    return data;
  }
}

const InternalNotificationModelConverter: firestore.FirestoreDataConverter<InternalNotificationModel> = {
  toFirestore: InternalNotificationModel.toFirestore as any,
  fromFirestore: InternalNotificationModel.fromFirestore,
};

export { InternalNotificationModel, InternalNotificationModelConverter };
