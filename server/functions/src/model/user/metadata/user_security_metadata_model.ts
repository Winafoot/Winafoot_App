/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class UserSecurityMetadataModel {
  email?: string;
  phone?: string;
  //Security
  profilCompleted?: boolean;
  cguAccepted?: boolean;
  cguAcceptedDate?: firestore.Timestamp;
  enableBiometricLogin?: boolean;
  forceEnableLoginAtEachAuth?: boolean;
  isFirstLogin?: boolean;
  //Security Information
  lastPasswordUpdate?: firestore.Timestamp;
  lastVerifEmailAt?: firestore.Timestamp;

  static fromJson(json: Map<string, any>): UserSecurityMetadataModel {
    return Object.assign(new UserSecurityMetadataModel(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): UserSecurityMetadataModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let user: UserSecurityMetadataModel & firestore.DocumentData = Object.assign(new UserSecurityMetadataModel(), snapshot.data());
    user.id = snapshot.id;
    return user;
  }

  static toFirestore(data: Partial<UserSecurityMetadataModel>): firestore.DocumentData {
    return data;
  }
}

let UserSecurityMetadataModelConverter: firestore.FirestoreDataConverter<UserSecurityMetadataModel> = {
  toFirestore: UserSecurityMetadataModel.toFirestore as any,
  fromFirestore: UserSecurityMetadataModel.fromFirestore,
};

export { UserSecurityMetadataModel, UserSecurityMetadataModelConverter };
