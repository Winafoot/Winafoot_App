/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class NotificationModel {
  sendToIds: string[];
  title: string;
  body?: string;
  type?: string;
  toTopic: boolean;
  topic?: string;
  metadata: { [key: string]: any };
  // Destination du deeplink côté app (cf. `_openFromNotification`).
  // Si absente, le type de la notification sert de route.
  route?: string;
  // Identifiant de l'entité visée par le deeplink (ex. : identifiant d'un match).
  entityId?: string;

  constructor() {
    this.sendToIds = [];
    this.title = "";
    this.body = "";
    this.type = "";
    this.toTopic = false;
    this.topic = "";
    this.metadata = {};
    this.route = "";
    this.entityId = "";
  }

  static fromJson(json: Map<string, any>): NotificationModel {
    return Object.assign(new NotificationModel(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): NotificationModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    return Object.assign(new NotificationModel(), snapshot.data());
  }

  static toFirestore(data: Partial<NotificationModel>): firestore.DocumentData {
    return data;
  }
}

const NotificationModelConverter: firestore.FirestoreDataConverter<NotificationModel> = {
  toFirestore: NotificationModel.toFirestore as any,
  fromFirestore: NotificationModel.fromFirestore,
};

export { NotificationModel, NotificationModelConverter };
