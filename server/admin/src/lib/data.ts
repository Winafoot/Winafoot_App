"use client";
import { useEffect, useMemo, useState } from "react";
import { collection, limit, onSnapshot, orderBy, query, where, type DocumentData, type Timestamp } from "firebase/firestore";
import { db } from "./firebase";

export type SubscriptionStatus = "trial" | "active" | "grace" | "expired" | "refunded";

export interface Subscription {
  productId?: string;
  period?: "monthly" | "yearly";
  teamsAllowed?: 1 | 2 | 3;
  status?: SubscriptionStatus;
  trialEnd?: Timestamp | null;
  expiresAt?: Timestamp | null;
  store?: "app_store" | "play_store";
  updatedAt?: Timestamp | null;
}

/** Fiche `users/{uid}` telle que le back-office la lit (les règles Firestore la réservent au propriétaire et aux admins). */
export interface Coach {
  id: string;
  email?: string;
  firstname?: string;
  coachName?: string;
  teamName?: string;
  category?: string;
  division?: string;
  teamFormat?: number;
  profilCompleted?: boolean;
  disabled?: boolean;
  createdAt?: Timestamp;
  lastInviteSentAt?: Timestamp;
  /** Présent sur un compte d'équipe lié : uid du propriétaire qui paie. */
  ownerUid?: string;
  teamIndex?: number;
  subscription?: Subscription;
  access?: { active?: boolean; until?: Timestamp };
  manualGrant?: boolean;
}

export interface AsyncState<T> {
  data: T;
  loading: boolean;
  error: Error | null;
}

/** Abonnement en direct à une collection racine. `build` reçoit la collection et renvoie la requête. */
function useLiveCollection<T extends { id: string }>(path: string, constraints: Parameters<typeof query>[1][]): AsyncState<T[]> {
  const [state, setState] = useState<AsyncState<T[]>>({ data: [], loading: true, error: null });
  // Les contraintes sont des objets recréés à chaque rendu : on ne s'abonne qu'une fois par composant.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    const q = query(collection(db(), path), ...constraints);
    return onSnapshot(
      q,
      (snap) =>
        setState({
          data: snap.docs.map((d) => ({ id: d.id, ...(d.data() as DocumentData) }) as unknown as T),
          loading: false,
          error: null,
        }),
      (error) => setState({ data: [], loading: false, error }),
    );
  }, [path]);
  return state;
}

/** Tous les comptes (coachs et comptes d'équipe liés). */
export function useUsers(): AsyncState<Coach[]> {
  return useLiveCollection<Coach>("users", []);
}

/** Comptes coach uniquement : les comptes d'équipe liés (ownerUid) sont rattachés à leur propriétaire. */
export function useCoaches(): AsyncState<Coach[]> & { linked: Coach[] } {
  const { data, loading, error } = useUsers();
  // Mémoïsé : des tableaux recréés à chaque rendu relanceraient en boucle les effets et les useMemo des pages.
  return useMemo(
    () => ({
      data: data.filter((u) => u.ownerUid == null),
      linked: data.filter((u) => u.ownerUid != null),
      loading,
      error,
    }),
    [data, loading, error],
  );
}

export interface AuditEntry {
  id: string;
  action: string;
  targetUid?: string;
  targetEmail?: string | null;
  adminUid?: string;
  adminEmail?: string | null;
  outcome: "success" | "failure";
  error?: string | null;
  details?: string | null;
  at?: Timestamp;
}

export function useAudit(max = 300): AsyncState<AuditEntry[]> {
  return useLiveCollection<AuditEntry>("admin_audit", [orderBy("at", "desc"), limit(max)]);
}

export const AUDIT_ACTIONS: Record<string, string> = {
  create: "Création",
  resend: "Invitation renvoyée",
  disable: "Désactivation",
  enable: "Réactivation",
  delete: "Suppression",
  view_coach_data: "Consultation des données",
  send_notification: "Notification envoyée",
  linked_reset_password: "Mot de passe d'équipe liée",
  admin_create: "Administrateur invité",
  admin_update: "Administrateur modifié",
  admin_delete: "Administrateur supprimé",
};

export const SUBSCRIPTION_LABELS: Record<SubscriptionStatus, string> = {
  trial: "Essai",
  active: "Actif",
  grace: "Paiement en attente",
  expired: "Expiré",
  refunded: "Remboursé",
};

/** Comptes d'équipe liés d'un propriétaire, en direct (les règles Firestore laissent les administrateurs lire `users`). */
export function useLinkedTeams(ownerUid: string): AsyncState<Coach[]> {
  const [state, setState] = useState<AsyncState<Coach[]>>({ data: [], loading: true, error: null });
  useEffect(
    () =>
      onSnapshot(
        query(collection(db(), "users"), where("ownerUid", "==", ownerUid)),
        (snap) =>
          setState({
            data: snap.docs
              .map((d) => ({ id: d.id, ...(d.data() as DocumentData) }) as unknown as Coach)
              .sort((a, b) => (a.teamIndex ?? 0) - (b.teamIndex ?? 0)),
            loading: false,
            error: null,
          }),
        (error) => setState({ data: [], loading: false, error }),
      ),
    [ownerUid],
  );
  return state;
}
