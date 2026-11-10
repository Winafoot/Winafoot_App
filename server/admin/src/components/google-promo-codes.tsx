"use client";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { errorMessage, listGoogleOfferTags, listPromoCodes, savePromoCode, type GoogleOfferTag, type PromoCodeRow } from "@/lib/callables";
import { formatDate } from "@/lib/utils";

const inThreeMonths = () => new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

function status(c: PromoCodeRow) {
  if (!c.active) return <Badge variant="secondary">Désactivé</Badge>;
  if (c.expiresAt != null && Date.parse(`${c.expiresAt}T23:59:59`) < Date.now()) return <Badge variant="secondary">Expiré</Badge>;
  if (c.uses >= c.maxUses) return <Badge variant="secondary">Épuisé</Badge>;
  return <Badge>Actif</Badge>;
}

/**
 * Codes promo Google Play (Android) : l'API de Google n'en propose pas, ils vivent donc ici. Le client saisit le code dans
 * l'app, le serveur le valide, puis l'app propose l'offre Play portant le tag du code (à créer dans la Play Console).
 */
export function GooglePromoCodes() {
  const [codes, setCodes] = useState<PromoCodeRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [code, setCode] = useState("");
  const [label, setLabel] = useState("50 % de réduction sur le premier mois");
  const [offerTag, setOfferTag] = useState("");
  const [tags, setTags] = useState<GoogleOfferTag[] | null>(null);
  const [tagsError, setTagsError] = useState<string | null>(null);
  const [maxUses, setMaxUses] = useState("100");
  const [expiresAt, setExpiresAt] = useState(inThreeMonths());
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    listPromoCodes({})
      .then(({ codes: list }) => setCodes(list))
      .catch((e) => setError(errorMessage(e, "Lecture des codes impossible.")));
  }, []);
  useEffect(load, [load]);

  // Tags lus dans la Play Console ; si la lecture échoue (compte de service absent...), le champ libre reste utilisable.
  useEffect(() => {
    listGoogleOfferTags({})
      .then(({ tags: list }) => setTags(list))
      .catch((e) => setTagsError(errorMessage(e, "Lecture de Google Play impossible.")));
  }, []);

  async function create(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const saved = await savePromoCode({ code, create: true, label, offerTag, maxUses: Number(maxUses), expiresAt, active: true });
      toast.success(`Code ${saved.code} créé.`);
      setOfferTag("");
      setCode("");
      load();
    } catch (err) {
      toast.error(errorMessage(err, "Création impossible."));
    } finally {
      setBusy(false);
    }
  }

  async function toggle(c: PromoCodeRow) {
    try {
      await savePromoCode({ code: c.code, create: false, label: c.label, maxUses: c.maxUses, expiresAt: c.expiresAt, active: !c.active });
      load();
    } catch (err) {
      toast.error(errorMessage(err, "Modification impossible."));
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Codes promo Google Play (Android)</CardTitle>
        <CardDescription>
          Avant de créer un code ici, créez dans la Play Console, sur l&apos;abonnement, une offre « Déterminée par le développeur » (par exemple 50 % le premier mois) avec le tag choisi
          ci-dessous. Le code ne donne accès qu&apos;aux nouveaux abonnés, une fois par compte. L&apos;usage est compté quand l&apos;achat à prix réduit est confirmé.
        </CardDescription>
      </CardHeader>
      <CardContent className="grid gap-6">
        <form onSubmit={create} className="grid max-w-2xl gap-4 sm:grid-cols-2">
          <div className="grid gap-1.5">
            <Label htmlFor="gp-code">Code saisi par le client</Label>
            <Input id="gp-code" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="BIENVENUE50" required minLength={4} maxLength={20} pattern="[A-Za-z0-9]+" />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="gp-tag">Tag de l&apos;offre Play</Label>
            {tags != null && tags.length > 0 ? (
              <Select value={offerTag} onValueChange={setOfferTag} disabled={busy}>
                <SelectTrigger id="gp-tag">
                  <SelectValue placeholder="Choisir un tag" />
                </SelectTrigger>
                <SelectContent>
                  {tags.map((t) => (
                    <SelectItem key={t.tag} value={t.tag}>
                      {t.tag} · {t.offers.length} offre{t.offers.length > 1 ? "s" : ""}
                      {t.ambiguous ? " · en double, à corriger" : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            ) : (
              <Input id="gp-tag" value={offerTag} onChange={(e) => setOfferTag(e.target.value.toLowerCase())} placeholder="promo50" required pattern="[a-z0-9\-]{2,20}" />
            )}
            {tags != null && tags.length === 0 && <p className="text-xs text-muted-foreground">Aucun tag trouvé dans Google Play : ajoutez-en un sur l&apos;offre, ou saisissez-le à la main.</p>}
            {tagsError && <p className="text-xs text-destructive">{tagsError} Saisie libre en attendant.</p>}
            {tags?.find((t) => t.tag === offerTag)?.ambiguous && (
              <p className="text-xs text-destructive">Ce tag est posé sur plusieurs offres du même abonnement : l&apos;app en prendrait une au hasard. Corrigez-le dans la Play Console.</p>
            )}
            <p className="text-xs text-muted-foreground">Un tag par type d&apos;offre, jamais sur deux offres d&apos;un même abonnement.</p>
          </div>
          <div className="grid gap-1.5 sm:col-span-2">
            <Label htmlFor="gp-label">Texte affiché au client</Label>
            <Input id="gp-label" value={label} onChange={(e) => setLabel(e.target.value)} required maxLength={80} />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="gp-max">Utilisations maximum</Label>
            <Input id="gp-max" type="number" min={1} value={maxUses} onChange={(e) => setMaxUses(e.target.value)} required />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="gp-exp">Valable jusqu&apos;au</Label>
            <Input id="gp-exp" type="date" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} />
          </div>
          <div className="sm:col-span-2">
            <Button type="submit" disabled={busy}>
              {busy ? "Création…" : "Créer le code"}
            </Button>
          </div>
        </form>

        {error && <Alert variant="destructive">{error}</Alert>}
        {codes != null && codes.length === 0 && <p className="text-sm text-muted-foreground">Aucun code Google pour le moment.</p>}
        {codes != null && codes.length > 0 && (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Code</TableHead>
                <TableHead>Offre</TableHead>
                <TableHead>Utilisations</TableHead>
                <TableHead>Fin</TableHead>
                <TableHead>État</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {codes.map((c) => (
                <TableRow key={c.code}>
                  <TableCell>
                    <code className="rounded bg-muted px-2 py-1 text-sm">{c.code}</code>
                    <div className="mt-1 text-xs text-muted-foreground">{c.label}</div>
                  </TableCell>
                  <TableCell>{c.offerTag}</TableCell>
                  <TableCell className="tabular-nums">
                    {c.uses} / {c.maxUses}
                  </TableCell>
                  <TableCell>{c.expiresAt != null ? formatDate(c.expiresAt) : "—"}</TableCell>
                  <TableCell>{status(c)}</TableCell>
                  <TableCell className="text-right">
                    <Button type="button" variant="outline" size="sm" onClick={() => toggle(c)}>
                      {c.active ? "Désactiver" : "Réactiver"}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
