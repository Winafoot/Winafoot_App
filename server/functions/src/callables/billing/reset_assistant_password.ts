import { auth } from "firebase-admin";
import { assistantRef } from "../../billing/assistant";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { assertPasswordPolicy } from "../admin/_password_policy";

export interface ResetAssistantPasswordRequest {
  password: string;
}

/** Le coach redéfinit le mot de passe de son adjoint (compte sans adresse réelle) ; ses sessions sont révoquées. */
export default async (data: ResetAssistantPasswordRequest, caller: AuthedCaller): Promise<true> => {
  assertPasswordPolicy(data?.password);
  const uid: unknown = (await assistantRef(caller.uid).get()).get("uid");
  if (typeof uid !== "string") throw new HttpsError("not-found", "Aucun adjoint.");
  await auth().updateUser(uid, { password: data.password });
  await auth().revokeRefreshTokens(uid);
  return true;
};
