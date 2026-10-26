import { removeAssistant } from "../../billing/assistant";
import type { AuthedCaller } from "../../runtime/v2_authed";

/** Le coach supprime son adjoint : compte, fiche et liaison, accès coupé immédiatement. */
export default async (_data: unknown, caller: AuthedCaller): Promise<true> => {
  await removeAssistant(caller.uid);
  return true;
};
