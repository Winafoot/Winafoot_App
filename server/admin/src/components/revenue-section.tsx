"use client";
import { useMemo } from "react";
import { Banknote, CalendarRange, Users } from "lucide-react";
import { StatCard } from "@/components/stat-card";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { Coach } from "@/lib/data";
import { computeRevenue, formatEuro, PLAN_PRICES } from "@/lib/revenue";

/** Abonnés par formule et revenu mensuel estimé, calculés avec la grille de prix publique (aucun appel aux stores). */
export function RevenueSection({ coaches, loading }: { coaches: Coach[]; loading: boolean }) {
  const revenue = useMemo(() => computeRevenue(coaches), [coaches]);
  const hints = [revenue.offered > 0 ? `${revenue.offered} offert(s) exclu(s)` : null, revenue.sandbox > 0 ? `${revenue.sandbox} de test exclu(s)` : null, revenue.withOffer > 0 ? `${revenue.withOffer} avec une offre d'introduction` : null].filter(Boolean);

  return (
    <section className="mb-6 grid gap-4">
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard label="Revenu mensuel estimé" value={formatEuro(revenue.monthly)} icon={Banknote} loading={loading} hint="TTC, avant commission des stores" />
        <StatCard label="Revenu annuel estimé" value={formatEuro(revenue.monthly * 12)} icon={CalendarRange} loading={loading} hint="Revenu mensuel × 12" />
        <StatCard label="Abonnés payants" value={revenue.subscribers} icon={Users} loading={loading} hint={hints.length > 0 ? hints.join(" · ") : undefined} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Abonnés par formule</CardTitle>
          <CardDescription>
            Abonnements actifs ou en paiement en attente, valorisés au prix catalogue (CGU). Une formule annuelle compte pour un douzième de son prix par mois ; une remise d&apos;introduction n&apos;est pas déduite.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>Formule</TableHead>
                <TableHead>Période</TableHead>
                <TableHead>Prix</TableHead>
                <TableHead className="text-right">Abonnés</TableHead>
                <TableHead className="text-right">Revenu mensuel</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {revenue.lines.map((l) => (
                <TableRow key={`${l.teams}-${l.period}`}>
                  <TableCell className="font-medium">
                    {l.name} · {l.teams} équipe{l.teams > 1 ? "s" : ""}
                  </TableCell>
                  <TableCell>{l.period === "monthly" ? "Mensuelle" : "Annuelle"}</TableCell>
                  <TableCell className="tabular-nums text-muted-foreground">
                    {formatEuro(l.period === "monthly" ? PLAN_PRICES[l.teams].monthly : PLAN_PRICES[l.teams].yearly)}
                    {l.period === "monthly" ? " / mois" : " / an"}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">{l.subscribers}</TableCell>
                  <TableCell className="text-right tabular-nums">{formatEuro(l.monthlyRevenue)}</TableCell>
                </TableRow>
              ))}
              <TableRow className="border-t-2 hover:bg-transparent">
                <TableCell colSpan={3} className="font-semibold">
                  Total
                </TableCell>
                <TableCell className="text-right font-semibold tabular-nums">{revenue.subscribers}</TableCell>
                <TableCell className="text-right font-semibold tabular-nums">{formatEuro(revenue.monthly)}</TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </section>
  );
}
