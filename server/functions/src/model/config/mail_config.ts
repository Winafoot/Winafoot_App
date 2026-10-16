/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class MailConfig {
  from?: string;
  fromName?: string;
  replyTo?: string;

  static fromJson(json: Map<string, any>): MailConfig {
    let appdata: MailConfig = Object.assign(new MailConfig(), json);
    return appdata;
  }

  static fromFirestore(snapshot: firestore.DocumentData): MailConfig {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let appdata: MailConfig = Object.assign(new MailConfig(), snapshot.data());
    return appdata;
  }

  static toFirestore(data: Partial<MailConfig>): firestore.DocumentData {
    return data;
  }
}

const MailConfigConverter: firestore.FirestoreDataConverter<MailConfig> = {
  toFirestore: MailConfig.toFirestore as any,
  fromFirestore: MailConfig.fromFirestore,
};

export { MailConfig, MailConfigConverter };
