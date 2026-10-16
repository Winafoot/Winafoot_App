/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { UserSecurityMetadataModel, UserSecurityMetadataModelConverter } from "../../../model/user/metadata/user_security_metadata_model";

export class UserSecurityMetadataRepository {
  public getDocumentReference(userId?: string): firestore.DocumentReference<firestore.DocumentData> {
    if (userId == undefined) throw new Error("UserMetadataRepository::getDocumentReference::userId is undefined");
    if (userId == null) throw new Error("UserMetadataRepository::getDocumentReference::userId is null");

    return firestore().collection("users").doc(userId).collection("metadata").withConverter(UserSecurityMetadataModelConverter).doc("security");
  }

  public async getDocument(userId?: string): Promise<UserSecurityMetadataModel> {
    let documentSnapshot: firestore.DocumentSnapshot<firestore.DocumentData> = await this.getDocumentReference(userId).get();

    return UserSecurityMetadataModel.fromFirestore(documentSnapshot);
  }

  public async setDocument(userId?: string, model?: UserSecurityMetadataModel): Promise<firestore.WriteResult> {
    if (model == undefined) throw new Error("UserMetadataRepository::setDocument::model is undefined");
    if (model == null) throw new Error("UserMetadataRepository::setDocument::model is null");

    return this.getDocumentReference(userId).set(UserSecurityMetadataModel.toFirestore(model));
  }

  public async updateDocument(userId?: string, model?: UserSecurityMetadataModel): Promise<firestore.WriteResult> {
    if (model == undefined) throw new Error("UserMetadataRepository::updateDocument::model is undefined");
    if (model == null) throw new Error("UserMetadataRepository::updateDocument::model is null");

    return this.getDocumentReference(userId).update(UserSecurityMetadataModel.toFirestore(model));
  }

  public async deleteDocument(userId: string): Promise<firestore.WriteResult> {
    if (userId == undefined) throw new Error("UserMetadataRepository::deleteDocument::userId is undefined");
    if (userId == null) throw new Error("UserMetadataRepository::deleteDocument::userId is null");

    return this.getDocumentReference(userId).delete();
  }

  public updateField(userId?: string, field?: string, value?: any): Promise<firestore.WriteResult> {
    if (field == undefined) throw new Error("UserMetadataRepository::updateField::field is undefined");
    if (field == null) throw new Error("UserMetadataRepository::updateField::field is null");

    return this.getDocumentReference(userId).update({ [field]: value });
  }
}
