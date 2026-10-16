/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";

class SizedImage {
  url?: string;
  compressedUrl?: string;

  static fromJson(json: Map<string, any>): SizedImage {
    return Object.assign(new SizedImage(), json);
  }

  static fromFirestore(documentFieldValue: any): SizedImage {
    return Object.assign(new SizedImage(), documentFieldValue);
  }

  static toFirestore(data: Partial<SizedImage>): firestore.DocumentData {
    return data;
  }
}

export { SizedImage };
