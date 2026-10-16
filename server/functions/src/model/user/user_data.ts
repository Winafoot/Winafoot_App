import { firestore } from "firebase-admin";

class UserData {
  /// Données propres à l'app associées à un utilisateur (aucune aujourd'hui).
  currency?: number;
  self?: firestore.DocumentReference;

  static fromJson(json: Map<string, any>): UserData {
    let user: UserData = Object.assign(new UserData(), json);
    return user;
  }

  static fromFirestore(documentFieldValue: any): UserData {
    let user: UserData = Object.assign(new UserData(), documentFieldValue);

    return user;
  }

  static toFirestore(data: Partial<UserData>): firestore.DocumentData {
    return data;
  }
}

type UserDataNullable = UserData | undefined | null;

const UserDataConverter: firestore.FirestoreDataConverter<UserData> = {
  toFirestore: UserData.toFirestore as any,
  fromFirestore: UserData.fromFirestore,
};

export { UserData, UserDataNullable, UserDataConverter };
