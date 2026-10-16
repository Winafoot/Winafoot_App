import { firestore } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";

export interface CreatePlayerRequest {
  firstName: string;
  lastName: string;
  strongFoot: string;
  position: string;
  order?: number;
}

/** Effectif maximal selon le format du club (joueurs sur le terrain -> plafond). */
const CAP_BY_FORMAT: Record<number, number> = { 5: 9, 8: 14, 11: 20 };
/** Plafond sans format de club ni configuration : jamais celui d'un petit format. */
const DEFAULT_CAP = 20;
const MAX_NAME_LENGTH = 60;
const MAX_ORDER = 999;
/** Noms d'énumérations Dart (`StrongFoot.name`, `PlayerPosition.name`) : lettres seules. */
const ENUM_NAME = /^[A-Za-z]{1,30}$/;

/**
 * Crée un joueur dans l'effectif de l'appelant, plafond appliqué ICI.
 *
 * Les règles Firestore ne savent pas compter les documents d'une collection : la création est
 * donc réservée à ce callable (Admin SDK, transaction) ; les règles refusent toute création directe.
 *
 * Le plafond se juge sur le NOMBRE RÉEL de joueurs, lu dans la transaction, pas sur
 * `users/{uid}.playerCount` : le compteur n'est tenu à jour que pour l'affichage (CMS).
 */
export default async (data: CreatePlayerRequest, caller: AuthedCaller): Promise<{ id: string }> => {
  const player = parsePlayer(data);
  const db = firestore();
  const userRef = db.collection("users").doc(caller.uid);
  const players = userRef.collection("players");

  return db.runTransaction(async (tx) => {
    const [user, config, count] = await Promise.all([tx.get(userRef), tx.get(db.doc("app_config/config")), tx.get(players.count())]);
    const current = count.data().count;

    if (current >= squadCap(user.get("teamFormat"), config.get("max_players"))) {
      throw new HttpsError("failed-precondition", "squad-full");
    }

    const ref = players.doc();
    tx.set(ref, { ...player, order: data.order ?? current, createdAt: firestore.FieldValue.serverTimestamp() });
    tx.set(userRef, { playerCount: current + 1 }, { merge: true });
    return { id: ref.id };
  });
};

/** Format du club d'abord, sinon `app_config/config.max_players`, sinon 20. */
export function squadCap(teamFormat: unknown, configMax: unknown): number {
  if (typeof teamFormat === "number" && teamFormat in CAP_BY_FORMAT) return CAP_BY_FORMAT[teamFormat];
  return typeof configMax === "number" && Number.isInteger(configMax) && configMax > 0 ? configMax : DEFAULT_CAP;
}

/** Ne garde que les quatre champs d'un joueur, après vérification de leur forme. */
function parsePlayer(data: unknown): Pick<CreatePlayerRequest, "firstName" | "lastName" | "strongFoot" | "position"> {
  const d = data as Partial<CreatePlayerRequest> | null | undefined;
  const name = (v: unknown) => typeof v === "string" && v.length <= MAX_NAME_LENGTH;
  const enumName = (v: unknown) => typeof v === "string" && ENUM_NAME.test(v);

  if (
    typeof d !== "object" ||
    d === null ||
    !name(d.firstName) ||
    !name(d.lastName) ||
    !enumName(d.strongFoot) ||
    !enumName(d.position) ||
    (d.order !== undefined && !(Number.isInteger(d.order) && d.order >= 0 && d.order <= MAX_ORDER))
  ) {
    throw new HttpsError("invalid-argument", "Joueur invalide.");
  }

  return { firstName: d.firstName as string, lastName: d.lastName as string, strongFoot: d.strongFoot as string, position: d.position as string };
}
