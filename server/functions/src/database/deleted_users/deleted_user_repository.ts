/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";
import { RootRepository } from "../../interface/interface_root_repository";
import { DeletedUserModel, DeletedUserModelConverter } from "../../model/deleted_user/deleted_user_model";
import { UserModel } from "../../model/user/user_model";

export class DeletedUserRepositoryRepository extends RootRepository<DeletedUserModel> {
  private static _instance: DeletedUserRepositoryRepository = new DeletedUserRepositoryRepository();

  constructor() {
    super("deleted_users", DeletedUserModelConverter);

    if (DeletedUserRepositoryRepository._instance) {
      throw new Error("Use DeletedUserRepositoryRepository.getInstance() instead of new.");
    }
    DeletedUserRepositoryRepository._instance = this;
  }

  public static get instance(): DeletedUserRepositoryRepository {
    return DeletedUserRepositoryRepository._instance;
  }

  public addFromUserModel(userModel: UserModel): Promise<firestore.DocumentReference<DeletedUserModel>> {
    const deletedUserModel: DeletedUserModel = new DeletedUserModel();
    deletedUserModel.uid = userModel.id;
    deletedUserModel.email = userModel.email;
    deletedUserModel.deletedAt = firestore.Timestamp.now();

    return this.add({...deletedUserModel});
  }

  public addFromUserRecord(userRecord: UserRecord): Promise<firestore.DocumentReference<DeletedUserModel>> {
    const deletedUserModel: DeletedUserModel = new DeletedUserModel();
    deletedUserModel.uid = userRecord.uid;
    deletedUserModel.email = userRecord.email;
    deletedUserModel.deletedAt = firestore.Timestamp.now();

    return this.add({...deletedUserModel});
  }
}
