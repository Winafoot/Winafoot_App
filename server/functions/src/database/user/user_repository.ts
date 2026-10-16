/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { RootRepository } from "../../interface/interface_root_repository";
import { UserModel, UserModelConverter, UserModelNullable } from "../../model/user/user_model";

export class UserRepository extends RootRepository<UserModel> {
  private static _instance: UserRepository = new UserRepository();

  constructor() {
    super("users", UserModelConverter);

    if (UserRepository._instance) {
      throw new Error("Use UserRepository.getInstance() instead of new.");
    }
    UserRepository._instance = this;
  }

  public static get instance(): UserRepository {
    return UserRepository._instance;
  }

  public async getUser(userId: string): Promise<UserModelNullable> {
    return (await super.get(userId)).data();
  }

  public async getUserByEmail(email: string): Promise<firestore.Query<UserModel>> {
    return super.collection.where("email", "==", email).limit(1);
  }
}
