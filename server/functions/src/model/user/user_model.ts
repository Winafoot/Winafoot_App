/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { GenderNullable } from "../_enum/gender";
import { UserData } from "./user_data";
import { SizedImage } from "../utils/sized_image";

class UserModel {
  id?: string;
  self?: firestore.DocumentReference;
  email?: string;
  phone?: string;
  firstname?: string;
  lastname?: string;
  pseudo?: string;
  userProfileImage?: SizedImage;
  language?: string;
  gender: GenderNullable;
  birthdate?: firestore.Timestamp;
  userType?: string;
  userData: UserData | undefined | null;

  static fromJson(json: Map<string, any>): UserModel {
    let user: UserModel = Object.assign(new UserModel(), json);
    user.userData = UserData.fromJson(json.get("userData"));
    return user;
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): UserModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let user: UserModel & firestore.DocumentData = Object.assign(new UserModel(), snapshot.data());
    user.id = snapshot.id;
    user.self = snapshot.ref;
    if (snapshot.get("userData") != null && snapshot.get("userData") != undefined) {
      user.userData = UserData.fromFirestore(snapshot.get("userData"));
    } else {
      user.userData = null;
    }
    return user;
  }

  static toFirestore(data: Partial<UserModel>): firestore.DocumentData {
    return data;
  }

  get fullName(): string {
    return `${this.firstname ?? ""} ${this.lastname ?? ""}`;
  }
}

type UserModelNullable = UserModel | undefined | null;

const UserModelConverter: firestore.FirestoreDataConverter<UserModel> = {
  toFirestore: UserModel.toFirestore as any,
  fromFirestore: UserModel.fromFirestore,
};

export { UserModel, UserModelNullable, UserModelConverter };
