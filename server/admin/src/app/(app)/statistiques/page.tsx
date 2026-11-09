"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Activity, Shirt, Swords, UserCheck, Users, Wallet } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Alert } from "@/components/ui/alert";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Skeleton } from "@/components/ui/skeleton";
import { errorMessage, getPlayerBenchmarks, getTeamActivity, getUsageStats, type CategoryBenchmark, type RankedPlayer, type TeamActivity, type UsageWeek } from "@/lib/callables";
import { useCoaches } from "@/lib/data";
import { formatDateTime } from "@/lib/utils";

const TOOLTIP = { background: "var(--card)", border: "1px solid var(--border)", borderRadius: 8, fontSize: 12 };
const percent = (part: number, total: number) => (total > 0 ? `${Math.round((part / total) * 100)} %` : "—");
const average = (sum: number, count: number) => (count > 0 ? (sum / count).toFixed(1).replace(".", ",") : "—");

/** Statistiques d'usage : équipes actives, matchs par semaine, moyennes, part d'abonnés. */
export default function StatisticsPage() {
  const router = useRouter();
  const { data: coaches, linked, loading } = useCoaches();
  const [teams, setTeams] = useState<TeamActivity[] | null>(null);
  const [weeks, setWeeks] = useState<UsageWeek[] | null>(null);
  const [meta, setMeta] = useState<{ generatedAt: string; truncated: boolean; limit: number } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [bench, setBench] = useState<{ categories: CategoryBenchmark[]; topScorers: RankedPlayer[]; topAssisters: RankedPlayer[]; matchesUsed: number; truncated: boolean; limit: number } | null>(null);

  useEffect(() => {
    getTeamActivity({})
      .then(({ teams: t }) => setTeams(t))
      .catch((e) => setError(errorMessage(e, "Lecture de l'activité impossible.")));
    getPlayerBenchmarks({})
      .then(({ generatedAt: _generatedAt, ...rest }) => setBench(rest))
      .catch((e) => setError(errorMessage(e, "Lecture du niveau par catégorie impossible.")));
    getUsageStats({})
      .then(({ weeks: w, ...rest }) => {
        setWeeks(w);
        setMeta(rest);
      })
      .catch((e) => setError(errorMessage(e, "Lecture des statistiques impossible.")));
  }, []);

  const figures = useMemo(() => {
    const named = new Set([...coaches, ...linked].filter((c) => c.teamName).map((c) => c.id));
    const rows = (teams ?? []).filter((t) => named.has(t.uid));
    const played = rows.filter((t) => t.finished > 0).length;
    const owners = coaches.filter((c) => c.subscription?.status === "active" || c.subscription?.status === "trial" || c.subscription?.status === "grace" || c.access?.active === true).length;
    return {
      teams: named.size,
      played,
      players: rows.reduce((n, t) => n + t.players, 0),
      finished: rows.reduce((n, t) => n + t.finished, 0),
      count: rows.length,
      owners,
    };
  }, [teams, coaches, linked]);

  const chart = (weeks ?? []).map((w) => ({ ...w, label: w.weekStart.slice(8) + "/" + w.weekStart.slice(5, 7) }));
  const busy = loading || teams == null;

  return (
    <>
      <PageHeader title="Statistiques" description="Usage de l'application : équipes actives, matchs joués, moyennes et abonnés." />
      {error && <Alert variant="destructive" className="mb-4">{error}</Alert>}
      <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <StatCard label="Équipes" value={figures.teams} icon={Shirt} loading={loading} />
        <StatCard label="Ont joué au moins un match" value={percent(figures.played, figures.count)} hint={`${figures.played} équipe(s)`} icon={UserCheck} loading={busy} />
        <StatCard label="Abonnés" value={percent(figures.owners, coaches.length)} hint={`${figures.owners} compte(s) coach`} icon={Wallet} loading={loading} />
        <StatCard label="Joueurs par équipe" value={average(figures.players, figures.count)} icon={Users} loading={busy} />
        <StatCard label="Matchs joués par équipe" value={average(figures.finished, figures.count)} icon={Swords} loading={busy} />
        <StatCard label="Matchs joués au total" value={figures.finished} icon={Activity} loading={busy} />
      </section>
      <section className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Matchs terminés par semaine</CardTitle>
            <CardDescription>12 dernières semaines.</CardDescription>
          </CardHeader>
          <CardContent>
            {weeks == null && !error ? (
              <Skeleton className="h-64 w-full" />
            ) : (
              <div className="h-64" role="img" aria-label="Matchs terminés par semaine">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chart}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11 }} width={28} />
                    <Tooltip contentStyle={TOOLTIP} formatter={(v) => [String(v), "Matchs"]} labelFormatter={(l) => `Semaine du ${l}`} />
                    <Bar dataKey="matches" fill="#518948" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Équipes actives par semaine</CardTitle>
            <CardDescription>Équipes ayant terminé au moins un match dans la semaine.</CardDescription>
          </CardHeader>
          <CardContent>
            {weeks == null && !error ? (
              <Skeleton className="h-64 w-full" />
            ) : (
              <div className="h-64" role="img" aria-label="Équipes actives par semaine">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chart}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                    <YAxis allowDecimals={false} tick={{ fontSize: 11 }} width={28} />
                    <Tooltip contentStyle={TOOLTIP} formatter={(v) => [String(v), "Équipes"]} labelFormatter={(l) => `Semaine du ${l}`} />
                    <Bar dataKey="activeTeams" fill="#7fb3d5" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
      </section>
      <section className="mt-6 grid gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Niveau par catégorie</CardTitle>
            <CardDescription>Moyennes sur les matchs terminés de tous les clients : des agrégats, sans nom ni équipe.</CardDescription>
          </CardHeader>
          <CardContent>
            {bench == null && !error ? (
              <Skeleton className="h-40 w-full" />
            ) : !bench || bench.categories.length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">Aucun match terminé pour le moment.</p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent">
                    <TableHead>Catégorie</TableHead>
                    <TableHead>Équipes</TableHead>
                    <TableHead>Matchs</TableHead>
                    <TableHead>Buts / match</TableHead>
                    <TableHead>Encaissés / match</TableHead>
                    <TableHead>Victoires</TableHead>
                    <TableHead>Passes réussies</TableHead>
                    <TableHead>Jaunes / match</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {bench.categories.map((c) => (
                    <TableRow key={c.category}>
                      <TableCell className="font-medium">{c.category}</TableCell>
                      <TableCell className="tabular-nums">{c.teams}</TableCell>
                      <TableCell className="tabular-nums">{c.matches}</TableCell>
                      <TableCell className="tabular-nums">{String(c.goalsForPerMatch).replace(".", ",")}</TableCell>
                      <TableCell className="tabular-nums">{String(c.goalsAgainstPerMatch).replace(".", ",")}</TableCell>
                      <TableCell className="tabular-nums">{c.winRate} %</TableCell>
                      <TableCell className="tabular-nums">{c.passAccuracy == null ? "—" : `${c.passAccuracy} %`}</TableCell>
                      <TableCell className="tabular-nums">{String(c.yellowCardsPerMatch).replace(".", ",")}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
        <div className="grid gap-4 lg:grid-cols-2">
          {([
            ["Meilleurs buteurs", "Joueurs ayant disputé au moins 3 matchs. Cliquez sur un joueur pour ouvrir sa fiche.", bench?.topScorers],
            ["Meilleurs passeurs", "Joueurs ayant disputé au moins 3 matchs. Cliquez sur un joueur pour ouvrir sa fiche.", bench?.topAssisters],
          ] as const).map(([title, description, players]) => (
            <Card key={title}>
              <CardHeader>
                <CardTitle>{title}</CardTitle>
                <CardDescription>{description}</CardDescription>
              </CardHeader>
              <CardContent>
                {bench == null && !error ? (
                  <Skeleton className="h-40 w-full" />
                ) : !players || players.length === 0 ? (
                  <p className="py-6 text-center text-sm text-muted-foreground">Pas encore assez de matchs.</p>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow className="hover:bg-transparent">
                        <TableHead>Rang</TableHead>
                        <TableHead>Joueur</TableHead>
                        <TableHead>Équipe</TableHead>
                        <TableHead>Catégorie</TableHead>
                        <TableHead>Matchs</TableHead>
                        <TableHead>Buts</TableHead>
                        <TableHead>Passes déc.</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {players.map((p) => (
                        <TableRow key={`${p.teamUid}/${p.playerId}`} className="cursor-pointer" onClick={() => router.push(`/equipes/detail/?uid=${encodeURIComponent(p.teamUid)}&player=${encodeURIComponent(p.playerId)}`)}>
                          <TableCell className="tabular-nums">{p.rank}</TableCell>
                          <TableCell className="font-medium">{p.name}</TableCell>
                          <TableCell>{p.teamName}</TableCell>
                          <TableCell>{p.category}</TableCell>
                          <TableCell className="tabular-nums">{p.matches}</TableCell>
                          <TableCell className="tabular-nums">{p.goals}</TableCell>
                          <TableCell className="tabular-nums">{p.assists}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      </section>
      {bench?.truncated && <Alert className="mt-4">Plus de {bench.limit} matchs : le niveau par catégorie porte sur un échantillon.</Alert>}
      {meta?.truncated && <Alert className="mt-4">Plus de {meta.limit} matchs sur la période : les chiffres hebdomadaires sont partiels.</Alert>}
      {meta && <p className="mt-4 text-xs text-muted-foreground">Calculé le {formatDateTime(meta.generatedAt)}.</p>}
    </>
  );
}
