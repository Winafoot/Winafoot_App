"use client";
import { useCallback, useEffect, useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Flag, RefreshCw, Shield, Swords, UserCheck, Users, UsersRound, Wallet } from "lucide-react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { errorMessage, getAdminStats, type AdminStats } from "@/lib/callables";
import { SUBSCRIPTION_LABELS } from "@/lib/data";
import { formatDateTime, formatNumber } from "@/lib/utils";

const SUBSCRIPTION_COLORS: Record<keyof AdminStats["subscriptions"], string> = {
  active: "#518948",
  trial: "#7fb3d5",
  grace: "#e8a838",
  expired: "#9aa5a0",
  refunded: "#ff5b79",
};

const monthLabel = (month: string) =>
  new Intl.DateTimeFormat("fr-FR", { month: "short", year: "2-digit" }).format(new Date(`${month}-01T00:00:00Z`));

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminStats>();
  const [error, setError] = useState<string>();
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(undefined);
    try {
      setStats(await getAdminStats({}));
    } catch (e) {
      setError(errorMessage(e, "Impossible de charger les statistiques."));
      toast.error("Statistiques indisponibles.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const paying = stats ? stats.subscriptions.active + stats.subscriptions.grace : 0;
  const subscriptionData = stats
    ? (Object.keys(stats.subscriptions) as (keyof AdminStats["subscriptions"])[])
        .map((key) => ({ key, name: SUBSCRIPTION_LABELS[key], value: stats.subscriptions[key] }))
        .filter((d) => d.value > 0)
    : [];
  const withoutSubscription = stats ? Math.max(0, stats.coaches.total - Object.values(stats.subscriptions).reduce((a, b) => a + b, 0)) : 0;

  return (
    <>
      <PageHeader
        title="Tableau de bord"
        description="Vue d'ensemble de l'application Wina."
        actions={
          <Button variant="outline" onClick={load} loading={loading}>
            <RefreshCw /> Actualiser
          </Button>
        }
      />

      {error && <Alert variant="destructive" className="mb-6">{error}</Alert>}

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Coachs" value={formatNumber(stats?.coaches.total ?? 0)} icon={Users} loading={loading} hint={stats ? `${stats.coaches.disabled} désactivé(s)` : undefined} />
        <StatCard label="Abonnés payants" value={formatNumber(paying)} icon={Wallet} loading={loading} hint={stats ? `${stats.subscriptions.trial} en essai` : undefined} />
        <StatCard label="Équipes liées" value={formatNumber(stats?.coaches.linked ?? 0)} icon={UsersRound} loading={loading} />
        <StatCard
          label="Signalements"
          value={formatNumber(stats?.content.reports ?? 0)}
          icon={Flag}
          loading={loading}
          tone={stats && stats.content.reports > 0 ? "accent" : "default"}
        />
      </section>

      <section className="mt-4 grid gap-4 sm:grid-cols-3">
        <StatCard label="Joueurs" value={formatNumber(stats?.content.players ?? 0)} icon={UserCheck} loading={loading} />
        <StatCard label="Matchs" value={formatNumber(stats?.content.matches ?? 0)} icon={Swords} loading={loading} />
        <StatCard label="Compositions" value={formatNumber(stats?.content.compositions ?? 0)} icon={Shield} loading={loading} />
      </section>

      <section className="mt-6 grid gap-4 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>Inscriptions</CardTitle>
            <CardDescription>Nouveaux comptes par mois, sur 12 mois.</CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-64 w-full" />
            ) : (
              <div className="h-64" role="img" aria-label="Histogramme des inscriptions par mois">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={stats?.signups.map((s) => ({ ...s, label: monthLabel(s.month) }))}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                    <XAxis dataKey="label" tickLine={false} axisLine={false} fontSize={12} />
                    <YAxis allowDecimals={false} tickLine={false} axisLine={false} fontSize={12} width={28} />
                    <Tooltip
                      cursor={{ fill: "var(--muted)" }}
                      contentStyle={{ background: "var(--card)", border: "1px solid var(--border)", borderRadius: 8, fontSize: 12 }}
                      formatter={(value) => [value, "Inscriptions"]}
                    />
                    <Bar dataKey="count" fill="var(--primary)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Abonnements</CardTitle>
            <CardDescription>Répartition par statut.</CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-64 w-full" />
            ) : subscriptionData.length === 0 ? (
              <p className="py-12 text-center text-sm text-muted-foreground">Aucun abonnement pour le moment.</p>
            ) : (
              <>
                <div className="h-44" role="img" aria-label="Répartition des abonnements par statut">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={subscriptionData} dataKey="value" nameKey="name" innerRadius={42} outerRadius={70} paddingAngle={2} stroke="none">
                        {subscriptionData.map((d) => (
                          <Cell key={d.key} fill={SUBSCRIPTION_COLORS[d.key]} />
                        ))}
                      </Pie>
                      <Tooltip contentStyle={{ background: "var(--card)", border: "1px solid var(--border)", borderRadius: 8, fontSize: 12 }} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <ul className="mt-2 grid gap-1.5 text-sm">
                  {subscriptionData.map((d) => (
                    <li key={d.key} className="flex items-center justify-between">
                      <span className="flex items-center gap-2">
                        <span className="size-2.5 rounded-full" style={{ background: SUBSCRIPTION_COLORS[d.key] }} />
                        {d.name}
                      </span>
                      <span className="tabular-nums text-muted-foreground">{d.value}</span>
                    </li>
                  ))}
                  {withoutSubscription > 0 && (
                    <li className="flex items-center justify-between text-muted-foreground">
                      <span>Sans abonnement</span>
                      <span className="tabular-nums">{withoutSubscription}</span>
                    </li>
                  )}
                </ul>
              </>
            )}
          </CardContent>
        </Card>
      </section>

      {stats && <p className="mt-4 text-xs text-muted-foreground">Calculé le {formatDateTime(stats.generatedAt)}.</p>}
    </>
  );
}
