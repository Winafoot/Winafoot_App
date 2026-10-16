/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { SizedImage } from "./sized_image";

class SocialUser {
  id?: string;
  lastname?: string;
  firstname?: string;
  email?: string;
  profileImage?: string;
  userProfileImage?: SizedImage;

  static fromJson(json: Map<string, any>): SocialUser {
    return Object.assign(new SocialUser(), json);
  }

  static fromFirestore(documentFieldValue: any): SocialUser {
    let socialUser: SocialUser & firestore.DocumentData = Object.assign(new SocialUser(), documentFieldValue);

    if (documentFieldValue["userProfileImage"] != null && documentFieldValue["userProfileImage"] != undefined) {
      socialUser.userProfileImage = SizedImage.fromJson(documentFieldValue["userProfileImage"]);
    }
    return socialUser;
  }

  static toFirestore(data: Partial<SocialUser>): firestore.DocumentData {
    return data;
  }
}

export { SocialUser };
