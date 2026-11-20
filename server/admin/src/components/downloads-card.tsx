"use client";
import { useEffect, useMemo, useState } from "react";
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Alert } from "@/components/ui/alert";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { errorMessage, getDownloadStats, type DownloadStats, type StoreDownloads } from "@/lib/callables";
import { formatNumber } from "@/lib/utils";

const APPLE_COLOR = "#7fb3d5";
const GOOGLE_COLOR = "#518948";

const dayLabel = (date: string) => new Intl.DateTimeFormat("fr-FR", { day: "2-digit", month: "2-digit", timeZone: "UTC" }).format(new Date(`${date}T00:00:00Z`));

function StoreTotal({ name, color, store }: { name: string; color: string; store: StoreDownloads }) {
  return (
    <div className="min-w-0">
      <p className="flex items-center gap-2 text-sm text-muted-foreground">
        <span className="size-2.5 rounded-full" style={{ background: color }} />
        {name}
      </p>
      {store.error ? (
        <p className="mt-1 text-sm text-muted-foreground">Indisponible</p>
      ) : (
        <p className="text-2xl font-semibold tabular-nums">{formatNumber(store.total)}</p>
      )}
    </div>
  );
}

/** Téléchargements Apple (premiers téléchargements) et Google Play (installations) sur les derniers jours, lus côté serveur dans les rapports des deux boutiques. */
export function DownloadsCard({ days = 30 }: { days?: number }) {
  const [stats, setStats] = useState<DownloadStats>();
  const [error, setError] = useState<string>();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    getDownloadStats({ days })
      .then((s) => !cancelled && setStats(s))
      .catch((e) => !cancelled && setError(errorMessage(e, "Téléchargements indisponibles.")))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [days]);

  const chart = useMemo(() => {
    if (!stats) return [];
    const google = new Map(stats.google.daily.map((d) => [d.date, d.count]));
    const apple = new Map(stats.apple.daily.map((d) => [d.date, d.count]));
    const dates = [...new Set([...apple.keys(), ...google.keys()])].sort();
    return dates.map((date) => ({ label: dayLabel(date), Apple: apple.get(date) ?? 0, "Google Play": google.get(date) ?? 0 }));
  }, [stats]);

  const stores = stats ? ([["Apple", stats.apple], ["Google Play", stats.google]] as const) : [];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Téléchargements</CardTitle>
        <CardDescription>
          {stats ? `Du ${dayLabel(stats.from)} au ${dayLabel(stats.to)} : ` : `${days} derniers jours : `}
          premiers téléchargements Apple, installations Google Play. Les rapports des boutiques ont un jour de retard.
        </CardDescription>
      </CardHeader>
      <CardContent className="grid gap-4">
        {error && <Alert variant="destructive">{error}</Alert>}
        {loading ? (
          <Skeleton className="h-56 w-full" />
        ) : (
          stats && (
            <>
              <div className="flex flex-wrap gap-x-10 gap-y-3">
                <StoreTotal name="Apple" color={APPLE_COLOR} store={stats.apple} />
                <StoreTotal name="Google Play" color={GOOGLE_COLOR} store={stats.google} />
              </div>
              {stores.map(([name, store]) => store.error && (
                <Alert key={name} variant={store.configured ? "destructive" : "default"}>
                  {name} : {store.error}
                </Alert>
              ))}
              {chart.length > 0 && (
                <div className="h-56" role="img" aria-label="Histogramme des téléchargements par jour">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chart}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                      <XAxis dataKey="label" tickLine={false} axisLine={false} fontSize={12} interval="preserveStartEnd" minTickGap={24} />
                      <YAxis allowDecimals={false} tickLine={false} axisLine={false} fontSize={12} width={28} />
                      <Tooltip cursor={{ fill: "var(--muted)" }} contentStyle={{ background: "var(--card)", border: "1px solid var(--border)", borderRadius: 8, fontSize: 12 }} />
                      <Legend wrapperStyle={{ fontSize: 12 }} />
                      <Bar dataKey="Apple" stackId="dl" fill={APPLE_COLOR} />
                      <Bar dataKey="Google Play" stackId="dl" fill={GOOGLE_COLOR} radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}
            </>
          )
        )}
      </CardContent>
    </Card>
  );
}
