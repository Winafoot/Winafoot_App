/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { UserMetadataRepository } from "../database/user/metadata/user_metadata_repository";
import { UserSecurityMetadataRepository } from "../database/user/metadata/user_security_metadata_repository";
import { UserRepository } from "../database/user/user_repository";
import { UserModelNullable } from "../model/user/user_model";

class UserProvider {
  private static _instance: UserProvider = new UserProvider();

  private _metadataRepository: UserMetadataRepository;

  private _securityRepository: UserSecurityMetadataRepository;

  constructor() {
    if (UserProvider._instance) {
      throw new Error("Use UserRepository.getInstance() instead of new.");
    }
    this._metadataRepository = new UserMetadataRepository();
    this._securityRepository = new UserSecurityMetadataRepository();
    UserProvider._instance = this;
  }

  public static get instance(): UserProvider {
    return UserProvider._instance;
  }

  public get metadataRepository(): UserMetadataRepository {
    return this._metadataRepository;
  }

  public get securityRepository(): UserSecurityMetadataRepository {
    return this._securityRepository;
  }

  public async getUser(userId: string): Promise<UserModelNullable> {
    return UserRepository.instance.getUser(userId);
  }

  public async getUserByEmail(email: string): Promise<firestore.QuerySnapshot<UserModelNullable>> {
    return (await UserRepository.instance.getUserByEmail(email)).get();
  }
}

export { UserProvider };
