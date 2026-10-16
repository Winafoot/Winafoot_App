import { createHash } from "node:crypto";

const sha256Hex = (value: string): string => createHash("sha256").update(value).digest("hex");

/** Clé de propriétaire : Algolia ne reçoit jamais un uid Firebase en clair. */
export const ownerKey = (uid: string): string => sha256Hex(uid);

/** Identifiant opaque d'un enregistrement : stable pour un (uid, docId), sans fuite de l'un ni de l'autre. */
export const objectId = (uid: string, docId: string): string => sha256Hex(`${uid}/${docId}`);
