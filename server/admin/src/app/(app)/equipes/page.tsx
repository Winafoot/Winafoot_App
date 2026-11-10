"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/data-table";
import { SubscriptionBadge } from "@/components/coach-badges";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { errorMessage, getTeamActivity, type TeamActivity } from "@/lib/callables";
import { useCoaches, type Coach } from "@/lib/data";
import { formatDate, toDate } from "@/lib/utils";

const DAY = 24 * 60 * 60 * 1000;

interface TeamRow {
  coach: Coach;
  /** Équipe liée affichée juste après l'équipe du compte qui la possède. */
  isLinked: boolean;
  /** Équipe liée dont le compte principal n'existe plus (supprimé) : plus personne ne la paie ni ne la gère. */
  orphan: boolean;
  /** Compte qui paie : le propriétaire pour une équipe liée, le coach lui-même sinon. */
  owner: Coach;
  activity?: TeamActivity;
}

type Filter = "all" | "subscribed" | "unsubscribed" | "active30" | "nomatch" | "orphan";

const hasAccess =(owner: Coach): boolean => {
  const status = owner.subscription?.status;
  return status === "active" || status === "trial" || status === "grace" || owner.access?.active === true;
};

/** Toutes les équipes de l'app (comptes coach et équipes liées), avec leur activité. */
export default function TeamsPage() {
  const router = useRouter();
  const { data: coaches, linked, loading, error } = useCoaches();
  const [activity, setActivity] = useState<Map<string, TeamActivity> | null>(null);
  const [activityError, setActivityError] = useState<string | null>(null);
  const [filter, setFilter] = useState<Filter>("all");

  useEffect(() => {
    getTeamActivity({})
      .then(({ teams }) => setActivity(new Map(teams.map((t) => [t.uid, t]))))
      .catch((e) => setActivityError(errorMessage(e, "Lecture de l'activité impossible.")));
  }, []);

  // Un groupe par compte : son équipe, puis ses équipes liées (par numéro d'équipe). Les groupes sont classés par
  // activité récente ; un cliquer sur un en-tête de colonne retrie ensuite les lignes une à une.
  const groups = useMemo<TeamRow[][]>(() => {
    const byOwner = new Map<string, Coach[]>();
    for (const l of linked) if (l.ownerUid != null && l.teamName) byOwner.set(l.ownerUid, [...(byOwner.get(l.ownerUid) ?? []), l]);
    const ownerIds = new Set([...coaches.map((c) => c.id), ...byOwner.keys()]);
    const coachById = new Map(coaches.map((c) => [c.id, c]));
    const built: TeamRow[][] = [];
    for (const id of ownerIds) {
      const owner = coachById.get(id);
      const members: TeamRow[] = [];
      if (owner?.teamName) members.push({ coach: owner, owner, isLinked: false, orphan: false, activity: activity?.get(owner.id) });
      for (const l of (byOwner.get(id) ?? []).sort((a, b) => (a.teamIndex ?? 0) - (b.teamIndex ?? 0))) {
        members.push({ coach: l, owner: owner ?? l, isLinked: true, orphan: owner == null, activity: activity?.get(l.id) });
      }
      if (members.length > 0) built.push(members);
    }
    const lastOf = (g: TeamRow[]) => Math.max(0, ...g.map((r) => toDate(r.activity?.lastFinishedAt)?.getTime() ?? 0));
    return built.sort((a, b) => lastOf(b) - lastOf(a));
  }, [coaches, linked, activity]);

  const rows = useMemo(() => {
    const now = Date.now();
    const matches = (r: TeamRow) => {
      if (filter === "orphan") return r.orphan;
      if (filter === "subscribed") return hasAccess(r.owner);
      if (filter === "unsubscribed") return !hasAccess(r.owner);
      if (filter === "active30") {
        const last = toDate(r.activity?.lastFinishedAt)?.getTime();
        return last != null && now - last < 30 * DAY;
      }
      if (filter === "nomatch") return r.activity != null && r.activity.finished === 0;
      return true;
    };
    // Le filtre s'applique au groupe : une équipe liée qui correspond garde son compte à côté d'elle.
    return groups.filter((g) => g.some(matches)).flat();
  }, [groups, filter]);

  const columns = useMemo<ColumnDef<TeamRow, unknown>[]>(
    () => [
      {
        id: "team",
        header: "Équipe",
        accessorFn: (r) => `${r.coach.teamName ?? ""} ${r.coach.email ?? ""} ${r.owner.email ?? ""}`,
        cell: ({ row }) => (
          <div className={row.original.isLinked ? "min-w-0 pl-6" : "min-w-0"}>
            <div className="flex items-center gap-2 font-medium">
              {row.original.isLinked && <span className="text-muted-foreground">↳</span>}
              <span className="truncate">{row.original.coach.teamName}</span>
              {row.original.isLinked && <Badge variant="secondary">Équipe liée</Badge>}
              {row.original.orphan && <Badge variant="destructive">Compte principal supprimé</Badge>}
            </div>
            <div className="truncate text-xs text-muted-foreground">{row.original.orphan ? "Aucun compte principal" : (row.original.owner.email ?? "—")}</div>
          </div>
        ),
      },
      { id: "category", header: "Catégorie", accessorFn: (r) => r.coach.category ?? "", cell: ({ row }) => row.original.coach.category ?? "—" },
      {
        id: "players",
        header: "Joueurs",
        accessorFn: (r) => r.activity?.players ?? -1,
        cell: ({ row }) => <span className="tabular-nums">{row.original.activity?.players ?? "…"}</span>,
      },
      {
        id: "matches",
        header: "Matchs joués",
        accessorFn: (r) => r.activity?.finished ?? -1,
        cell: ({ row }) => <span className="tabular-nums">{row.original.activity?.finished ?? "…"}</span>,
      },
      {
        id: "last",
        header: "Dernier match",
        accessorFn: (r) => toDate(r.activity?.lastFinishedAt)?.getTime() ?? 0,
        cell: ({ row }) => formatDate(row.original.activity?.lastFinishedAt),
      },
      {
        id: "subscription",
        header: "Abonnement",
        accessorFn: (r) => r.owner.subscription?.status ?? "",
        cell: ({ row }) => (row.original.orphan ? <span className="text-muted-foreground">—</span> : <SubscriptionBadge coach={row.original.owner} />),
      },
    ],
    [],
  );

  return (
    <>
      <PageHeader title="Équipes" description="Toutes les équipes de l'application, avec leur activité. Les équipes liées sont regroupées sous le compte qui les possède. Cliquez sur une ligne pour voir les matchs et les joueurs." />
      {(error || activityError) && (
        <Alert variant="destructive" className="mb-4">
          {error ? `Lecture impossible : ${error.message}` : activityError}
        </Alert>
      )}
      <DataTable
        columns={columns}
        data={rows}
        loading={loading}
        searchPlaceholder="Rechercher une équipe, un coach…"
        emptyMessage="Aucune équipe ne correspond."
        getRowId={(r) => r.coach.id}
        onRowClick={(r) => router.push(`/equipes/detail/?uid=${encodeURIComponent(r.coach.id)}`)}
        toolbar={
          <Select value={filter} onValueChange={(v) => setFilter(v as Filter)}>
            <SelectTrigger className="w-52" aria-label="Filtrer les équipes">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes les équipes</SelectItem>
              <SelectItem value="subscribed">Abonnées</SelectItem>
              <SelectItem value="unsubscribed">Sans abonnement</SelectItem>
              <SelectItem value="active30">Actives (30 jours)</SelectItem>
              <SelectItem value="nomatch">Sans match joué</SelectItem>
              <SelectItem value="orphan">Compte principal supprimé</SelectItem>
            </SelectContent>
          </Select>
        }
      />
    </>
  );
}
