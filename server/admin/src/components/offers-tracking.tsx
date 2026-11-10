"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { errorMessage, listAppleOffers, listPromoCodes, type AppleOffer, type PromoCodeRow } from "@/lib/callables";
import { SUBSCRIPTION_LABELS, useUsers } from "@/lib/data";
import { formatDate } from "@/lib/utils";

const MODES: Record<string, string> = { FREE_TRIAL: "Essai gratuit", PAY_AS_YOU_GO: "Prix réduit", PAY_UP_FRONT: "Prix réduit (payé d'avance)" };
const DURATIONS: Record<string, string> = { ONE_WEEK: "1 semaine", TWO_WEEKS: "2 semaines", ONE_MONTH: "1 mois", TWO_MONTHS: "2 mois", THREE_MONTHS: "3 mois", SIX_MONTHS: "6 mois", ONE_YEAR: "1 an" };

const isPast = (date: string | null) => date != null && Date.parse(date) < Date.now();

function expiry(date: string | null, active: boolean) {
  if (date == null) return <span className="text-muted-foreground">—</span>;
  const expired = isPast(date);
  return (
    <span className="flex items-center gap-2">
      {formatDate(date)}
      {expired ? <Badge variant="secondary">Expiré</Badge> : !active && <Badge variant="secondary">Désactivé</Badge>}
    </span>
  );
}

/** Suivi des codes promo : offres et codes d'App Store Connect avec leurs dates limites, et comptes abonnés avec une offre. */
export function OffersTracking() {
  const router = useRouter();
  const { data: users, loading } = useUsers();
  const [offers, setOffers] = useState<AppleOffer[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [google, setGoogle] = useState<PromoCodeRow[] | null>(null);
  const [googleError, setGoogleError] = useState<string | null>(null);

  useEffect(() => {
    listAppleOffers({})
      .then(({ offers: list }) => setOffers(list))
      .catch((e) => setError(errorMessage(e, "Lecture des offres impossible.")));
    listPromoCodes({})
      .then(({ codes }) => setGoogle(codes))
      .catch((e) => setGoogleError(errorMessage(e, "Lecture des codes Google impossible.")));
  }, []);

  // Comptes dont le premier achat s'est fait avec une offre d'introduction ou un code (enregistré par le webhook).
  const subscribers = useMemo(
    () =>
      users
        .filter((u) => u.ownerUid == null && u.subscription?.introOffer != null)
        .sort((a, b) => (b.subscription?.introOffer?.atMs ?? 0) - (a.subscription?.introOffer?.atMs ?? 0)),
    [users],
  );

  // Une ligne par code : d'abord Apple (offre, puis ses codes), ensuite Google. Le nom de l'offre n'apparaît qu'à sa première ligne.
  const rows = useMemo(() => {
    type Row = { key: string; platform: string; name: string; subtitle: string; kind: string; codes: React.ReactNode; extra: string; date: string | null; active: boolean };
    const out: Row[] = [];
    for (const offer of offers ?? []) {
      const kind = `${MODES[offer.mode] ?? offer.mode} · ${offer.periods > 1 ? `${offer.periods} périodes de ` : ""}${DURATIONS[offer.duration] ?? offer.duration}`;
      const lines = [
        ...offer.customCodes.map((c) => ({ key: c.id, codes: <code className="rounded bg-muted px-1.5 py-0.5">{c.code}</code>, extra: `${c.uses} utilisations`, date: c.expirationDate, active: c.active })),
        ...offer.batches.map((b) => ({ key: b.id, codes: `${b.codes} codes à usage unique`, extra: "", date: b.expirationDate, active: b.active })),
      ];
      if (lines.length === 0) lines.push({ key: offer.id, codes: <span className="text-muted-foreground">Aucun code créé</span>, extra: "", date: null, active: offer.active });
      lines.forEach((l, i) =>
        out.push({ ...l, key: `apple-${offer.id}-${l.key}`, platform: "Apple", name: i === 0 ? offer.name : "", subtitle: i === 0 ? offer.subscription : "", kind: i === 0 ? kind : "" }),
      );
    }
    for (const c of google ?? []) {
      out.push({
        key: `google-${c.code}`,
        platform: "Google",
        name: c.label,
        subtitle: `tag ${c.offerTag}`,
        kind: "Prix réduit · offre Play",
        codes: <code className="rounded bg-muted px-1.5 py-0.5">{c.code}</code>,
        extra: `${c.uses} / ${c.maxUses} utilisations`,
        date: c.expiresAt,
        active: c.active,
      });
    }
    return out;
  }, [offers, google]);

  return (
    <div className="grid gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Offres et codes</CardTitle>
          <CardDescription>Apple (lus dans App Store Connect : offres, lots de codes, codes personnalisés) et Google Play (codes créés dans cette page), avec leurs dates limites.</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-3">
          {error && <Alert variant="destructive">Apple : {error}</Alert>}
          {googleError && <Alert variant="destructive">Google : {googleError}</Alert>}
          {(offers == null && error == null) || (google == null && googleError == null) ? (
            <Skeleton className="h-32 w-full" />
          ) : rows.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">Aucune offre à code pour le moment.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Plateforme</TableHead>
                  <TableHead>Offre</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Codes</TableHead>
                  <TableHead>Date limite</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.key}>
                    <TableCell>
                      <Badge variant="secondary">{row.platform}</Badge>
                    </TableCell>
                    <TableCell>
                      {row.name && (
                        <>
                          <div className="font-medium">{row.name}</div>
                          <div className="text-xs text-muted-foreground">{row.subtitle}</div>
                        </>
                      )}
                    </TableCell>
                    <TableCell>{row.kind}</TableCell>
                    <TableCell>
                      {row.codes}
                      {row.extra && <span className="ml-2 text-xs text-muted-foreground">{row.extra}</span>}
                    </TableCell>
                    <TableCell>{expiry(row.date, row.active)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Abonnés avec une offre</CardTitle>
          <CardDescription>
            Comptes dont le premier achat a utilisé une offre d&apos;introduction ou un code. Suivi enregistré à partir de la mise en service de cette page : les achats plus anciens n&apos;y figurent pas.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <Skeleton className="h-24 w-full" />
          ) : subscribers.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">Personne pour le moment.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Coach</TableHead>
                  <TableHead>Code</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Abonnement</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {subscribers.map((u) => (
                  <TableRow key={u.id} className="cursor-pointer" onClick={() => router.push(`/coachs/detail/?uid=${encodeURIComponent(u.id)}`)}>
                    <TableCell>
                      <div className="font-medium">{u.teamName || u.firstname || "—"}</div>
                      <div className="text-xs text-muted-foreground">{u.email}</div>
                    </TableCell>
                    <TableCell>{u.subscription?.introOffer?.code ? <code className="rounded bg-muted px-1.5 py-0.5">{u.subscription.introOffer.code}</code> : <span className="text-muted-foreground">non transmis</span>}</TableCell>
                    <TableCell>{formatDate(new Date(u.subscription?.introOffer?.atMs ?? 0))}</TableCell>
                    <TableCell>{u.subscription?.status ? SUBSCRIPTION_LABELS[u.subscription.status] : "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
