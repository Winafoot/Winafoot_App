"use client";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { ColumnDef } from "@tanstack/react-table";
import { CalendarClock, CreditCard, Gift, Wallet } from "lucide-react";
import { SubscriptionBadge } from "@/components/coach-badges";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Alert } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SUBSCRIPTION_LABELS, useCoaches, type Coach, type SubscriptionStatus } from "@/lib/data";
import { formatDate, toDate } from "@/lib/utils";

const DAY = 24 * 60 * 60 * 1000;

export default function SubscriptionsPage() {
  const router = useRouter();
  const { data, linked, loading, error } = useCoaches();
  const [status, setStatus] = useState<"all" | SubscriptionStatus | "none">("all");

  const counts = useMemo(() => {
    const now = Date.now();
    return {
      active: data.filter((c) => c.subscription?.status === "active").length,
      trial: data.filter((c) => c.subscription?.status === "trial").length,
      grace: data.filter((c) => c.subscription?.status === "grace").length,
      manual: data.filter((c) => c.manualGrant === true && c.subscription == null).length,
      // Abonnements (essai ou payant) qui prennent fin dans les 14 jours : à surveiller avant qu'ils ne tombent.
      endingSoon: data.filter((c) => {
        const end = toDate(c.subscription?.expiresAt)?.getTime();
        const s = c.subscription?.status;
        return end != null && (s === "active" || s === "trial") && end > now && end - now < 14 * DAY;
      }).length,
    };
  }, [data]);

  const rows = useMemo(
    () =>
      data.filter((c) => {
        if (status === "all") return true;
        if (status === "none") return c.subscription == null;
        return c.subscription?.status === status;
      }),
    [data, status],
  );

  const linkedCount = useMemo(() => {
    const byOwner = new Map<string, number>();
    for (const l of linked) if (l.ownerUid) byOwner.set(l.ownerUid, (byOwner.get(l.ownerUid) ?? 0) + 1);
    return byOwner;
  }, [linked]);

  const columns = useMemo<ColumnDef<Coach, unknown>[]>(
    () => [
      {
        id: "name",
        header: "Coach",
        accessorFn: (c) => `${c.teamName ?? ""} ${c.email ?? ""}`,
        cell: ({ row }) => (
          <div className="min-w-0">
            <p className="truncate font-medium">{row.original.teamName ?? row.original.coachName ?? "—"}</p>
            <p className="truncate text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        ),
      },
      { id: "status", header: "Statut", accessorFn: (c) => c.subscription?.status ?? "", cell: ({ row }) => <SubscriptionBadge coach={row.original} /> },
      {
        id: "plan",
        header: "Formule",
        accessorFn: (c) => c.subscription?.teamsAllowed ?? 0,
        cell: ({ row }) => {
          const s = row.original.subscription;
          if (!s?.teamsAllowed) return row.original.manualGrant ? "Accès manuel" : "—";
          return `${s.teamsAllowed} équipe${s.teamsAllowed > 1 ? "s" : ""} · ${s.period === "monthly" ? "mensuel" : "annuel"}`;
        },
      },
      {
        id: "teams",
        header: "Équipes créées",
        accessorFn: (c) => linkedCount.get(c.id) ?? 0,
        cell: ({ row }) => {
          const allowed = row.original.subscription?.teamsAllowed;
          const used = (linkedCount.get(row.original.id) ?? 0) + 1;
          return allowed ? `${Math.min(used, allowed)} / ${allowed}` : "—";
        },
      },
      {
        id: "store",
        header: "Boutique",
        accessorFn: (c) => c.subscription?.store ?? "",
        cell: ({ row }) => (row.original.subscription?.store === "app_store" ? "App Store" : row.original.subscription?.store === "play_store" ? "Google Play" : "—"),
      },
      {
        id: "expiresAt",
        header: "Échéance",
        accessorFn: (c) => toDate(c.subscription?.expiresAt)?.getTime() ?? 0,
        cell: ({ row }) => formatDate(row.original.subscription?.expiresAt),
      },
    ],
    [linkedCount],
  );

  return (
    <>
      <PageHeader title="Abonnements" description="État des abonnements des coachs, tel que reçu de RevenueCat." />
      {error && <Alert variant="destructive" className="mb-4">Lecture impossible : {error.message}</Alert>}

      <section className="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Actifs" value={counts.active} icon={Wallet} loading={loading} />
        <StatCard label="En essai" value={counts.trial} icon={Gift} loading={loading} />
        <StatCard label="Paiement en attente" value={counts.grace} icon={CreditCard} loading={loading} tone={counts.grace > 0 ? "warning" : "default"} />
        <StatCard label="Échéance sous 14 jours" value={counts.endingSoon} icon={CalendarClock} loading={loading} tone={counts.endingSoon > 0 ? "warning" : "default"} hint={counts.manual > 0 ? `${counts.manual} accès manuel(s)` : undefined} />
      </section>

      <DataTable
        columns={columns}
        data={rows}
        loading={loading}
        searchPlaceholder="Rechercher un coach…"
        emptyMessage="Aucun abonnement ne correspond."
        initialSorting={[{ id: "expiresAt", desc: false }]}
        onRowClick={(c) => router.push(`/coachs/detail/?uid=${encodeURIComponent(c.id)}`)}
        toolbar={
          <Select value={status} onValueChange={(v) => setStatus(v as typeof status)}>
            <SelectTrigger className="w-52" aria-label="Filtrer par statut d'abonnement">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous</SelectItem>
              {(Object.keys(SUBSCRIPTION_LABELS) as SubscriptionStatus[]).map((s) => (
                <SelectItem key={s} value={s}>
                  {SUBSCRIPTION_LABELS[s]}
                </SelectItem>
              ))}
              <SelectItem value="none">Sans abonnement</SelectItem>
            </SelectContent>
          </Select>
        }
      />
    </>
  );
}
