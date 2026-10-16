/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { PasswordSecurityConfig } from "./password_security_config";
import { MailConfig } from "./mail_config";

class AppMetadataConfig {
  /// Security
  appHash?: string;

  appName?: string;
  baseUrl?: string;
  /// Share
  shareMessage?: string;

  /// Legal documents
  cgvu?: string;
  confidentialityPolicy?: string;
  legalNotice?: string;
  about?: string;

  /// Contact
  contactEmail?: string;
  contactPhone?: string;

  /// Social Network
  facebookUrl?: string;
  instagramUrl?: string;
  twitterUrl?: string;
  youtubeUrl?: string;
  linkedinUrl?: string;
  snapchatUrl?: string;

  /// Security Strenght
  passwordSecurityConfig?: PasswordSecurityConfig;

  ///Mail
  mail?: MailConfig;

  static fromJson(json: Map<string, any>): AppMetadataConfig {
    let appdata: AppMetadataConfig & firestore.DocumentData = Object.assign(new AppMetadataConfig(), json);
    appdata.passwordSecurityConfig = PasswordSecurityConfig.fromJson(json.get("passwordSecurityConfig"));
    appdata.mail = MailConfig.fromJson(json.get("mail"));
    return appdata;
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): AppMetadataConfig {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let appdata: AppMetadataConfig & firestore.DocumentData = Object.assign(new AppMetadataConfig(), snapshot.data());

    appdata.passwordSecurityConfig = PasswordSecurityConfig.fromJson(snapshot.get("passwordSecurityConfig"));
    appdata.mail = MailConfig.fromJson(snapshot.get("mail"));

    return appdata;
  }

  static toFirestore(data: Partial<AppMetadataConfig>): firestore.DocumentData {
    return data;
  }
}

const AppMetadataConfigConverter: firestore.FirestoreDataConverter<AppMetadataConfig> = {
  toFirestore: AppMetadataConfig.toFirestore as any,
  fromFirestore: AppMetadataConfig.fromFirestore,
};

export { AppMetadataConfig, AppMetadataConfigConverter };
