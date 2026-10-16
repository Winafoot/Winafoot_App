/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class UserMetadataModel {
  /// Required for bloqued data
  bloquedUsers?: Array<String>;

  /// Required for Social App
  friends?: Array<String>;
  friendsRequest?: Array<String>;
  friendsRequestedBy?: Array<String>;

  /// Required for Tchat
  createdAt?: firestore.Timestamp;
  lastSeen?: firestore.Timestamp;

  // Required for Position
  lastKnownPosition?: firestore.GeoPoint;
  lastKnownPositionUpdate?: firestore.Timestamp;

  /// Push Notification
  enablePushNotification?: boolean;
  fcmToken?: string;
  enableEmailNotification?: boolean;

  static fromJson(json: Map<string, any>): UserMetadataModel {
    return Object.assign(new UserMetadataModel(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): UserMetadataModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let user: UserMetadataModel & firestore.DocumentData = Object.assign(new UserMetadataModel(), snapshot.data());
    user.id = snapshot.id;
    return user;
  }

  static toFirestore(data: Partial<UserMetadataModel>): firestore.DocumentData {
    return data;
  }
}

const UserMetadataModelConverter: firestore.FirestoreDataConverter<UserMetadataModel> = {
  toFirestore: UserMetadataModel.toFirestore as any,
  fromFirestore: UserMetadataModel.fromFirestore,
};

export { UserMetadataModel, UserMetadataModelConverter };
