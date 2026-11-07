"use client";
import { useEffect, useState } from "react";
import { Copy } from "lucide-react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  createAppleOfferCode,
  errorMessage,
  getAppleOfferCodeValues,
  listAppleSubscriptions,
  type AppleOfferResult,
  type AppleSubscription,
  type AppleTerritory,
} from "@/lib/callables";

const nextYear = () => new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

/** Codes de réduction Apple (premier mois à -10 %, par exemple), créés dans App Store Connect puis remis aux clients choisis. */
export default function OffersPage() {
  const [subscriptions, setSubscriptions] = useState<AppleSubscription[]>([]);
  const [territories, setTerritories] = useState<AppleTerritory[]>([]);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [subscriptionId, setSubscriptionId] = useState("");
  const [territory, setTerritory] = useState("FRA");
  const [name, setName] = useState("Remise -10 % premier mois");
  const [basePrice, setBasePrice] = useState("");
  const [percentOff, setPercentOff] = useState("10");
  const [months, setMonths] = useState("1");
  const [expirationDate, setExpirationDate] = useState(nextYear());
  const [customCode, setCustomCode] = useState("");
  const [numberOfCodes, setNumberOfCodes] = useState("10");
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AppleOfferResult | null>(null);
  const [codes, setCodes] = useState<string[]>([]);
  const [preview, setPreview] = useState<{ price: number; percentOff: number } | null>(null);

  // Listes d'App Store Connect : abonnements et territoires.
  useEffect(() => {
    listAppleSubscriptions({})
      .then(({ subscriptions: subs, territories: terrs }) => {
        setSubscriptions(subs);
        setTerritories(terrs);
      })
      .catch((e) => setLoadError(errorMessage(e, "Lecture d'App Store Connect impossible.")));
  }, []);

  // Le prix actuel de l'abonnement dans le territoire choisi préremplit le champ (modifiable).
  useEffect(() => {
    if (subscriptionId === "") return;
    let cancelled = false;
    listAppleSubscriptions({ subscriptionId, territory })
      .then(({ price }) => {
        if (!cancelled && price != null) setBasePrice(String(price));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [subscriptionId, territory]);

  // Aperçu du nouveau prix : palier Apple le plus proche de la réduction demandée (recalculé à chaque changement).
  useEffect(() => {
    const base = Number(basePrice.replace(",", "."));
    const percent = Number(percentOff);
    setPreview(null);
    if (subscriptionId === "" || !(base > 0) || !(percent > 0 && percent < 100)) return;
    let cancelled = false;
    const timer = setTimeout(() => {
      listAppleSubscriptions({ subscriptionId, territory, basePrice: base, percentOff: percent })
        .then(({ discounted }) => {
          if (!cancelled) setPreview(discounted ?? null);
        })
        .catch(() => undefined);
    }, 400);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [subscriptionId, territory, basePrice, percentOff]);

  const loadCodes = async (batchId: string) => {
    try {
      const { codes: values } = await getAppleOfferCodeValues({ batchId });
      setCodes(values);
      if (values.length === 0) toast.info("Apple prépare encore les codes, réessayez dans un instant.");
    } catch (e) {
      toast.error(errorMessage(e, "Lecture des codes impossible."));
    }
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setResult(null);
    setCodes([]);
    try {
      const created = await createAppleOfferCode({
        subscriptionId,
        territory,
        name,
        basePrice: Number(basePrice.replace(",", ".")),
        percentOff: Number(percentOff),
        months: Number(months),
        expirationDate,
        customCode: customCode || undefined,
        numberOfCodes: Number(numberOfCodes),
      });
      setResult(created);
      toast.success("Offre créée dans App Store Connect.");
      if (created.batchId) await loadCodes(created.batchId);
    } catch (err) {
      toast.error(errorMessage(err, "Création impossible."));
    } finally {
      setBusy(false);
    }
  };

  const copy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      toast.success("Copié.");
    } catch {
      toast.error("Copie impossible.");
    }
  };

  return (
    <>
      <PageHeader
        title="Codes promo"
        description="Crée une réduction dans App Store Connect (iPhone et iPad) et ses codes à remettre aux clients. Le client les saisit dans Paramètres > J'ai un code promo."
      />
      <Alert className="mb-4">
        Apple n&apos;applique pas de pourcentage : le prix réduit est le palier de prix Apple le plus proche de la réduction demandée. Le prix réellement appliqué est affiché après la création. Pour Android, créez l&apos;offre dans la Play Console.
      </Alert>
      <Card className="mb-4 max-w-2xl">
        <CardHeader>
          <CardTitle>Nouvelle offre</CardTitle>
          <CardDescription>Réservée aux nouveaux abonnés, dans le pays choisi.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={submit} className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="offer-sub">Abonnement</Label>
              <Select value={subscriptionId} onValueChange={setSubscriptionId} disabled={busy || subscriptions.length === 0}>
                <SelectTrigger id="offer-sub">
                  <SelectValue placeholder={loadError ? "Indisponible" : subscriptions.length === 0 ? "Chargement…" : "Choisir un abonnement"} />
                </SelectTrigger>
                <SelectContent>
                  {subscriptions.map((sub) => (
                    <SelectItem key={sub.id} value={sub.id}>
                      {sub.appName} · {sub.groupName} · {sub.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {loadError && <p className="text-sm text-destructive">{loadError}</p>}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="offer-territory">Pays</Label>
              <Select value={territory} onValueChange={setTerritory} disabled={busy}>
                <SelectTrigger id="offer-territory">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {(territories.length > 0 ? territories : [{ id: "FRA", currency: "EUR" }]).map((t) => (
                    <SelectItem key={t.id} value={t.id}>
                      {t.id} ({t.currency})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="offer-name">Nom de l&apos;offre</Label>
              <Input id="offer-name" required value={name} onChange={(e) => setName(e.target.value)} disabled={busy} />
            </div>
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="grid gap-2">
                <Label htmlFor="offer-price">Prix actuel</Label>
                <Input id="offer-price" required inputMode="decimal" value={basePrice} onChange={(e) => setBasePrice(e.target.value)} disabled={busy} />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="offer-percent">Réduction (%)</Label>
                <Input id="offer-percent" required inputMode="numeric" value={percentOff} onChange={(e) => setPercentOff(e.target.value)} disabled={busy} />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="offer-months">Mois réduits</Label>
                <Input id="offer-months" required inputMode="numeric" value={months} onChange={(e) => setMonths(e.target.value)} disabled={busy} />
              </div>
            </div>
            {preview && (
              <p className="rounded-md bg-muted px-3 py-2 text-sm">
                Nouveau prix pendant {Number(months) > 1 ? `${months} mois` : "1 mois"} : <strong>{preview.price.toFixed(2).replace(".", ",")}</strong> au lieu de {Number(basePrice.replace(",", ".")).toFixed(2).replace(".", ",")} ({preview.percentOff} % de réduction, palier Apple le plus proche).
              </p>
            )}
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="grid gap-2">
                <Label htmlFor="offer-exp">Valable jusqu&apos;au</Label>
                <Input id="offer-exp" required type="date" value={expirationDate} onChange={(e) => setExpirationDate(e.target.value)} disabled={busy} />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="offer-custom">Code personnalisé (facultatif)</Label>
                <Input id="offer-custom" value={customCode} onChange={(e) => setCustomCode(e.target.value.toUpperCase())} placeholder="WINA10" disabled={busy} />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="offer-count">{customCode ? "Utilisations" : "Nombre de codes"}</Label>
                <Input id="offer-count" required inputMode="numeric" value={numberOfCodes} onChange={(e) => setNumberOfCodes(e.target.value)} disabled={busy} />
              </div>
            </div>
            <div>
              <Button type="submit" loading={busy} disabled={subscriptionId === ""}>
                Créer l&apos;offre
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {result && (
        <Card className="max-w-2xl">
          <CardHeader>
            <CardTitle>Offre créée</CardTitle>
            <CardDescription>
              Prix appliqué : {result.appliedPrice.toFixed(2)} € ({result.appliedPercentOff} % de réduction).
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {result.customCode && (
              <div className="flex items-center gap-2">
                <code className="rounded bg-muted px-2 py-1 text-sm">{result.customCode}</code>
                <Button type="button" variant="outline" size="sm" onClick={() => copy(result.customCode!)}>
                  <Copy className="size-4" /> Copier
                </Button>
              </div>
            )}
            {result.batchId && (
              <>
                <div className="flex flex-wrap gap-2">
                  <Button type="button" variant="outline" size="sm" onClick={() => loadCodes(result.batchId!)}>
                    Actualiser les codes
                  </Button>
                  {codes.length > 0 && (
                    <Button type="button" variant="outline" size="sm" onClick={() => copy(codes.join("\n"))}>
                      <Copy className="size-4" /> Tout copier
                    </Button>
                  )}
                </div>
                {codes.length > 0 && <pre className="max-h-64 overflow-auto rounded bg-muted p-3 text-sm">{codes.join("\n")}</pre>}
              </>
            )}
          </CardContent>
        </Card>
      )}
    </>
  );
}
