import { EntityAction } from "@firecms/core";
import { deleteCoach, resendInvite, setCoachDisabled } from "../callables";
import type { Coach } from "./coaches";

function getErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof Error) {
    return error.message;
  }
  return fallback;
}

export const resendInviteAction: EntityAction<Coach> = {
  name: "Renvoyer l'invitation",
  key: "resend_invite",
  onClick: async ({ entity, context }) => {
    if (!entity) return;
    try {
      await resendInvite(entity.id);
      context.snackbarController.open({ type: "success", message: "Invitation renvoyée." });
    } catch (e: unknown) {
      context.snackbarController.open({ type: "error", message: getErrorMessage(e, "Envoi impossible.") });
    }
  },
};

export const toggleDisabledAction: EntityAction<Coach> = {
  name: "Désactiver / Réactiver",
  key: "toggle_disabled",
  onClick: async ({ entity, context }) => {
    if (!entity) return;
    const next = entity.values.disabled !== true;
    const label = next ? "désactiver" : "réactiver";
    if (!window.confirm(`Voulez-vous ${label} le compte ${entity.values.email} ?`)) {
      return;
    }
    try {
      await setCoachDisabled(entity.id, next);
      context.snackbarController.open({
        type: "success",
        message: next ? "Compte désactivé." : "Compte réactivé.",
      });
    } catch (e: unknown) {
      context.snackbarController.open({ type: "error", message: getErrorMessage(e, "Opération impossible.") });
    }
  },
};

export const deleteCoachAction: EntityAction<Coach> = {
  name: "Supprimer définitivement",
  key: "delete_coach",
  onClick: async ({ entity, context }) => {
    if (!entity) return;
    const expected = entity.values.teamName ?? entity.values.email;
    const typed = window.prompt(
      `Cette suppression est irréversible : le compte, les joueurs, les matchs et les compositions seront perdus.\n\nTapez « ${expected} » pour confirmer.`
    );
    if (typed !== expected) {
      context.snackbarController.open({ type: "info", message: "Suppression annulée." });
      return;
    }
    try {
      await deleteCoach(entity.id);
      context.snackbarController.open({ type: "success", message: "Compte supprimé." });
    } catch (e: unknown) {
      context.snackbarController.open({ type: "error", message: getErrorMessage(e, "Suppression impossible.") });
    }
  },
};
