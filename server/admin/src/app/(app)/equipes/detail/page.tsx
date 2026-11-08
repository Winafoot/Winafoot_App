"use client";
import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { ArrowLeft, Goal, Percent, Swords, Trash2, Trophy } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { deleteOrphanTeam, errorMessage, getTeamStats, type TeamMatchLine, type TeamPlayerLine, type TeamStats } from "@/lib/callables";
import { useCoaches } from "@/lib/data";
import { derivedStats, STAT_GROUPS, summarizeStats } from "@/lib/stat-catalog";
import { formatDate, toDate } from "@/lib/utils";

const RESULT: Record<TeamMatchLine["result"], { label: string; variant: "default" | "secondary" | "destructive" }> = {
  win: { label: "Victoire", variant: "default" },
  draw: { label: "Nul", variant: "secondary" },
  loss: { label: "Défaite", variant: "destructive" },
};

/** Toutes les statistiques d'un joueur : totaux par thème, puis match par match. */
function PlayerDialog({ player, onClose }: { player: TeamPlayerLine | null; onClose: () => void }) {
  const groups = player == null ? [] : STAT_GROUPS.map((g) => ({ title: g.title, stats: g.stats.filter((s) => player.stats[s.key] != null) })).filter((g) => g.stats.length > 0);
  const derived = player == null ? [] : derivedStats(player.stats);
  return (
    <Dialog open={player != null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-2xl">
        {player && (
          <>
            <DialogHeader>
              <DialogTitle>{player.name}</DialogTitle>
              <DialogDescription>
                {[player.position, `${player.matches} match${player.matches > 1 ? "s" : ""}`].filter(Boolean).join(" · ")}
              </DialogDescription>
            </DialogHeader>
            {groups.length === 0 ? (
              <p className="py-4 text-sm text-muted-foreground">Aucune statistique enregistrée pour ce joueur.</p>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2">
                {groups.map((g) => (
                  <div key={g.title}>
                    <h4 className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">{g.title}</h4>
                    <dl className="grid gap-1 text-sm">
                      {g.stats.map((s) => (
                        <div key={s.key} className="flex justify-between gap-3">
                          <dt>{s.label}</dt>
                          <dd className="tabular-nums font-medium">{player.stats[s.key]}</dd>
                        </div>
                      ))}
                    </dl>
                  </div>
                ))}
                {derived.length > 0 && (
                  <div>
                    <h4 className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Calculées</h4>
                    <dl className="grid gap-1 text-sm">
                      {derived.map((d) => (
                        <div key={d.label} className="flex justify-between gap-3">
                          <dt>{d.label}</dt>
                          <dd className="tabular-nums font-medium">{d.value}</dd>
                        </div>
                      ))}
                    </dl>
                  </div>
                )}
              </div>
            )}
            <div>
              <h4 className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Match par match</h4>
              <ul className="grid gap-2 text-sm">
                {player.history.map((h) => (
                  <li key={h.matchId} className="rounded-md border px-3 py-2">
                    <div className="flex justify-between gap-3 font-medium">
                      <span>{h.opponent}</span>
                      <span className="text-muted-foreground">{formatDate(h.finishedAt)}</span>
                    </div>
                    <div className="text-muted-foreground">{summarizeStats(h.stats)}</div>
                  </li>
                ))}
              </ul>
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

const minutes = (seconds: number) => (seconds > 0 ? `${Math.round(seconds / 60)} min` : "—");

function TeamDetail() {
  const params = useSearchParams();
  const uid = params.get("uid") ?? "";
  const wantedPlayer = params.get("player");
  const { data: coaches, linked } = useCoaches();
  const team = useMemo(() => [...coaches, ...linked].find((c) => c.id === uid), [coaches, linked, uid]);
  // Équipe liée dont le compte principal n'existe plus : seule celle-ci peut être supprimée depuis cette page.
  const orphan = useMemo(() => team?.ownerUid != null && !coaches.some((c) => c.id === team.ownerUid), [team, coaches]);
  const router = useRouter();
  const [deleting, setDeleting] = useState(false);
  const [stats, setStats] = useState<TeamStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [player, setPlayer] = useState<TeamPlayerLine | null>(null);

  useEffect(() => {
    if (uid === "") return;
    getTeamStats({ uid })
      .then((result) => {
        setStats(result);
        if (wantedPlayer != null) setPlayer(result.players.find((p) => p.id === wantedPlayer) ?? null);
      })
      .catch((e) => setError(errorMessage(e, "Lecture des données impossible.")));
  }, [uid, wantedPlayer]);

  const matchColumns = useMemo<ColumnDef<TeamMatchLine, unknown>[]>(
    () => [
      { id: "date", header: "Date", accessorFn: (m) => toDate(m.finishedAt)?.getTime() ?? 0, cell: ({ row }) => formatDate(row.original.finishedAt) },
      { id: "opponent", header: "Adversaire", accessorFn: (m) => m.opponent, cell: ({ row }) => <span className="font-medium">{row.original.opponent}</span> },
      { id: "score", header: "Score", accessorFn: (m) => m.scoreUs - m.scoreThem, cell: ({ row }) => <span className="tabular-nums">{row.original.scoreUs} - {row.original.scoreThem}</span> },
      {
        id: "result",
        header: "Résultat",
        accessorFn: (m) => m.result,
        cell: ({ row }) => <Badge variant={RESULT[row.original.result].variant}>{RESULT[row.original.result].label}</Badge>,
      },
      { id: "duration", header: "Durée", accessorFn: (m) => m.elapsedSeconds, cell: ({ row }) => minutes(row.original.elapsedSeconds) },
      {
        id: "scorers",
        header: "Buteurs",
        enableSorting: false,
        accessorFn: (m) => m.scorers.map((s) => s.name).join(" "),
        cell: ({ row }) => (row.original.scorers.length === 0 ? "—" : row.original.scorers.map((s) => (s.goals > 1 ? `${s.name} (${s.goals})` : s.name)).join(", ")),
      },
      {
        id: "cards",
        header: "Cartons",
        accessorFn: (m) => m.yellowCards + m.redCards * 2,
        cell: ({ row }) => (row.original.yellowCards + row.original.redCards === 0 ? "—" : `${row.original.yellowCards} 🟨 ${row.original.redCards} 🟥`),
      },
    ],
    [],
  );

  const playerColumns = useMemo<ColumnDef<TeamPlayerLine, unknown>[]>(
    () => [
      { id: "name", header: "Joueur", accessorFn: (p) => p.name, cell: ({ row }) => <span className="font-medium">{row.original.name}</span> },
      { id: "position", header: "Poste", accessorFn: (p) => p.position, cell: ({ row }) => row.original.position || "—" },
      { id: "matches", header: "Matchs", accessorFn: (p) => p.matches },
      { id: "goals", header: "Buts", accessorFn: (p) => p.goals },
      { id: "assists", header: "Passes déc.", accessorFn: (p) => p.assists },
      { id: "yellow", header: "Jaunes", accessorFn: (p) => p.yellowCards },
      { id: "red", header: "Rouges", accessorFn: (p) => p.redCards },
    ],
    [],
  );

  const record = stats?.record;
  return (
    <>
      <PageHeader
        title={team?.teamName ?? "Équipe"}
        description={[team?.email, team?.category].filter(Boolean).join(" · ") || undefined}
        actions={
          <>
            {orphan && (
              <Button variant="destructive" onClick={() => setDeleting(true)}>
                <Trash2 /> Supprimer cette équipe orpheline
              </Button>
            )}
            <Button asChild variant="outline">
              <Link href="/equipes/">
                <ArrowLeft /> Équipes
              </Link>
            </Button>
          </>
        }
      />
      {error && <Alert variant="destructive" className="mb-4">{error}</Alert>}
      <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Matchs joués" value={record?.played ?? "—"} icon={Swords} loading={stats == null && !error} />
        <StatCard label="Victoires / nuls / défaites" value={record ? `${record.wins} / ${record.draws} / ${record.losses}` : "—"} icon={Trophy} loading={stats == null && !error} />
        <StatCard label="Buts pour / contre" value={record ? `${record.goalsFor} / ${record.goalsAgainst}` : "—"} icon={Goal} loading={stats == null && !error} />
        <StatCard
          label="Taux de victoire"
          value={record && record.played > 0 ? `${Math.round((record.wins / record.played) * 100)} %` : "—"}
          icon={Percent}
          loading={stats == null && !error}
        />
      </section>
      {stats == null && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : (
        stats && (
          <>
            {stats.truncated && <Alert className="mb-4">Seuls les {stats.limit} matchs les plus récents sont pris en compte.</Alert>}
            <Tabs defaultValue="matches">
              <TabsList>
                <TabsTrigger value="matches">Matchs ({stats.matches.length})</TabsTrigger>
                <TabsTrigger value="players">Joueurs ({stats.players.length})</TabsTrigger>
              </TabsList>
              <TabsContent value="matches">
                <DataTable columns={matchColumns} data={stats.matches} searchPlaceholder="Rechercher un adversaire, un buteur…" emptyMessage="Aucun match terminé." initialSorting={[{ id: "date", desc: true }]} getRowId={(m) => m.id} />
              </TabsContent>
              <TabsContent value="players">
                <DataTable columns={playerColumns} data={stats.players} searchPlaceholder="Rechercher un joueur… (cliquez sur une ligne pour tout voir)" emptyMessage="Aucun joueur." initialSorting={[{ id: "goals", desc: true }]} getRowId={(p) => p.id} onRowClick={setPlayer} />
                <p className="mt-3 text-xs text-muted-foreground">Le temps de jeu et la minute des buts ne sont conservés que pendant le match en direct : ils ne sont pas disponibles ici.</p>
              </TabsContent>
            </Tabs>
          </>
        )
      )}
      <PlayerDialog player={player} onClose={() => setPlayer(null)} />
      <ConfirmDialog
        open={deleting}
        onOpenChange={setDeleting}
        title="Supprimer cette équipe orpheline ?"
        description={`Le compte principal de cette équipe n'existe plus. Cette suppression est irréversible : l'équipe, ses joueurs, ses matchs et ses compositions seront perdus. Retapez le nom de l'équipe pour confirmer.`}
        confirmLabel="Supprimer définitivement"
        confirmText={team?.teamName || "supprimer"}
        destructive
        onConfirm={async () => {
          try {
            await deleteOrphanTeam({ uid });
            toast.success("Équipe supprimée.");
            router.push("/equipes/");
          } catch (e) {
            toast.error(errorMessage(e, "Suppression impossible."));
          }
        }}
      />
    </>
  );
}

export default function TeamDetailPage() {
  return (
    <Suspense fallback={<Skeleton className="h-64 w-full" />}>
      <TeamDetail />
    </Suspense>
  );
}
