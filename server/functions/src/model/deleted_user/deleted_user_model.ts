/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class DeletedUserModel {
  uid?: string;
  email?: string;
  deletedAt?: firestore.Timestamp;

  static fromJson(json: Map<string, any>): DeletedUserModel {
    return Object.assign(new DeletedUserModel(), json);
  }

  static fromFirestore(snapshot: firestore.DocumentSnapshot<firestore.DocumentData>): DeletedUserModel {
    if (!snapshot.exists) throw new Error("Document does not exist");
    if (!snapshot.data()) throw new Error("Document data is empty");

    let internalNotifcationModel = Object.assign(new DeletedUserModel(), snapshot.data());

    return internalNotifcationModel;
  }

  static toFirestore(data: Partial<DeletedUserModel>): firestore.DocumentData {
    return data;
  }
}

const DeletedUserModelConverter: firestore.FirestoreDataConverter<DeletedUserModel> = {
  toFirestore: DeletedUserModel.toFirestore as any,
  fromFirestore: DeletedUserModel.fromFirestore,
};

export { DeletedUserModel, DeletedUserModelConverter };
