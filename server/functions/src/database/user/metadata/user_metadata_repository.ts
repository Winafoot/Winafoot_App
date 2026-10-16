/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { UserMetadataModel, UserMetadataModelConverter } from "../../../model/user/metadata/user_metadata_model";

export class UserMetadataRepository {
  public getDocumentReference(userId?: string): firestore.DocumentReference<UserMetadataModel> {
    if (userId == undefined) throw new Error("UserMetadataRepository::getDocumentReference::userId is undefined");
    if (userId == null) throw new Error("UserMetadataRepository::getDocumentReference::userId is null");

    return firestore().collection("users").doc(userId).collection("metadata").withConverter(UserMetadataModelConverter).doc("metadata");
  }

  public async getDocument(userId?: string): Promise<UserMetadataModel | undefined> {
    let documentSnapshot: firestore.DocumentSnapshot<firestore.DocumentData> = await this.getDocumentReference(userId).get();

    return UserMetadataModel.fromFirestore(documentSnapshot);
  }

  public async setDocument(userId?: string, model?: UserMetadataModel): Promise<firestore.WriteResult> {
    if (model == undefined) throw new Error("UserMetadataRepository::setDocument::model is undefined");
    if (model == null) throw new Error("UserMetadataRepository::setDocument::model is null");

    return this.getDocumentReference(userId).set(model);
  }

  public async updateDocument(userId?: string, model?: UserMetadataModel): Promise<firestore.WriteResult> {
    if (model == undefined) throw new Error("UserMetadataRepository::updateDocument::model is undefined");
    if (model == null) throw new Error("UserMetadataRepository::updateDocument::model is null");

    return this.getDocumentReference(userId).update(UserMetadataModel.toFirestore(model));
  }

  public async deleteDocument(userId?: string): Promise<firestore.WriteResult> {
    return this.getDocumentReference(userId).delete();
  }

  public updateField(userId?: string, field?: string, value?: any): Promise<firestore.WriteResult> {
    if (field == undefined) throw new Error("UserMetadataRepository::updateField::field is undefined");
    if (field == null) throw new Error("UserMetadataRepository::updateField::field is null");

    return this.getDocumentReference(userId).update({ [field]: value });
  }
}
