/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class PasswordSecurityConfig {
  atLeast6Char: boolean;
  atLeast1Number: boolean;
  atLeast1SpecialChar: boolean;
  atLeast1Uppercase: boolean;
  atLeast1Lowercase: boolean;

  constructor() {
    this.atLeast6Char = true;
    this.atLeast1Number = true;
    this.atLeast1SpecialChar = true;
    this.atLeast1Uppercase = true;
    this.atLeast1Lowercase = true;
  }

  static fromJson(json: Map<string, any>): PasswordSecurityConfig {
    return Object.assign(new PasswordSecurityConfig(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): PasswordSecurityConfig {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    return Object.assign(new PasswordSecurityConfig(), snapshot.data());
  }

  static toFirestore(data: Partial<PasswordSecurityConfig>): firestore.DocumentData {
    return data;
  }
}

const PasswordSecurityConfigConverter: firestore.FirestoreDataConverter<PasswordSecurityConfig> = {
  toFirestore: PasswordSecurityConfig.toFirestore as any,
  fromFirestore: PasswordSecurityConfig.fromFirestore,
};

export { PasswordSecurityConfig, PasswordSecurityConfigConverter };
