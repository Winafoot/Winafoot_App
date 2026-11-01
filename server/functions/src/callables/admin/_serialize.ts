import { firestore } from "firebase-admin";

/** Convertit récursivement les Timestamp Firestore en chaînes ISO : une callable ne renvoie que du JSON. */
export function toJson(value: unknown): unknown {
  if (value instanceof firestore.Timestamp) return value.toDate().toISOString();
  // Une référence de document renvoyée telle quelle exposerait les internes du client Firestore : on garde le chemin.
  if (value instanceof firestore.DocumentReference) return value.path;
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(toJson);
  if (value != null && typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [key, v] of Object.entries(value as Record<string, unknown>)) out[key] = toJson(v);
    return out;
  }
  return value;
}
