"use client";
import { useCallback, useEffect, useMemo, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { Save } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { errorMessage, updateAppConfig } from "@/lib/callables";
import { db } from "@/lib/firebase";

interface Field {
  key: string;
  label: string;
  hint?: string;
  placeholder?: string;
  /** Texte long (HTML). */
  multiline?: boolean;
  required?: boolean;
}

const SECTIONS: { title: string; description: string; fields: Field[] }[] = [
  {
    title: "Contacts",
    description: "Adresses utilisées par l'app et les e-mails.",
    fields: [
      { key: "contactEmail", label: "Adresse de support", hint: "Bouton Aide de l'app, signalements, formulaire de la landing, lien dans les e-mails.", placeholder: "support@winafoot.fr", required: true },
      { key: "salesEmail", label: "Adresse des nouveaux abonnements", hint: "Prévenue à chaque nouvel abonnement. Vide : aucun mail interne.", placeholder: "contact@winafoot.fr" },
      { key: "contactPhone", label: "Téléphone de contact", placeholder: "01 02 03 04 05" },
    ],
  },
  {
    title: "E-mails",
    description: "Expéditeur des e-mails envoyés par l'app. L'adresse d'expédition doit appartenir à un domaine vérifié dans Resend, sinon aucun e-mail ne part.",
    fields: [
      { key: "mail.from", label: "Adresse d'expédition", placeholder: "noreply@winafoot.fr", required: true },
      { key: "mail.fromName", label: "Nom de l'expéditeur", placeholder: "Wina" },
      { key: "mail.replyTo", label: "Adresse de réponse", hint: "Reçoit les réponses des clients.", placeholder: "support@winafoot.fr" },
    ],
  },
  {
    title: "Partage et réseaux sociaux",
    description: "Adresses https complètes du compte, pas la page d'accueil du réseau. Un champ vide désactive le bouton.",
    fields: [
      { key: "shareMessage", label: "Message du bouton « Partager l'app »", hint: "Vide : message par défaut avec le lien du site.", multiline: true },
      { key: "instagramUrl", label: "Instagram", placeholder: "https://www.instagram.com/wina.foot" },
      { key: "tiktokUrl", label: "TikTok", placeholder: "https://www.tiktok.com/@wina.foot" },
      { key: "facebookUrl", label: "Facebook", placeholder: "https://www.facebook.com/…" },
      { key: "linkedinUrl", label: "LinkedIn", placeholder: "https://www.linkedin.com/company/winafoot/" },
      { key: "youtubeUrl", label: "YouTube", placeholder: "https://www.youtube.com/@…" },
    ],
  },
  {
    title: "Textes légaux (HTML)",
    description: "Affichés dans l'app dans la fenêtre d'acceptation des CGU et dans les pages légales du socle. Les pages du menu Paramètres, elles, ouvrent le site winafoot.fr.",
    fields: [
      { key: "cgvu", label: "Conditions générales (cgvu)", hint: "Attention : modifier ce texte oblige tous les comptes à accepter de nouveau les CGU.", multiline: true },
      { key: "confidentialityPolicy", label: "Politique de confidentialité", multiline: true },
      { key: "legalNotice", label: "Mentions légales", multiline: true },
      { key: "about", label: "À propos", multiline: true },
    ],
  },
];

const FIELDS = SECTIONS.flatMap((s) => s.fields);
const read = (data: Record<string, unknown>, key: string): string => {
  const value = key.split(".").reduce<unknown>((acc, part) => (acc != null && typeof acc === "object" ? (acc as Record<string, unknown>)[part] : undefined), data);
  return typeof value === "string" ? value : "";
};

const textareaClass = "min-h-24 w-full rounded-md border bg-background px-3 py-2 text-sm shadow-xs outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60";

/** Modification des champs de configuration de l'app (app_config/metadata). Seuls les champs changés sont envoyés. */
export default function ConfigurationPage() {
  const [initial, setInitial] = useState<Record<string, string> | null>(null);
  const [values, setValues] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);

  const load = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDoc(doc(db(), "app_config", "metadata"));
      const data = (snap.data() ?? {}) as Record<string, unknown>;
      const current = Object.fromEntries(FIELDS.map((f) => [f.key, read(data, f.key)]));
      setInitial(current);
      setValues(current);
    } catch (e) {
      setError(errorMessage(e, "Lecture de la configuration impossible."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const changes = useMemo(() => {
    if (initial == null) return {};
    return Object.fromEntries(FIELDS.filter((f) => (values[f.key] ?? "") !== initial[f.key]).map((f) => [f.key, values[f.key] ?? ""]));
  }, [initial, values]);
  const changedCount = Object.keys(changes).length;

  const save = async () => {
    setBusy(true);
    try {
      const { changed } = await updateAppConfig({ changes });
      toast.success(`${changed.length} champ(s) enregistré(s). L'app les lit au prochain démarrage.`);
      await load();
    } catch (e) {
      toast.error(errorMessage(e, "Enregistrement impossible."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader
        title="Configuration"
        description="Adresses de contact, e-mails, réseaux sociaux et textes légaux de l'app. Les changements s'appliquent à l'app au prochain démarrage."
        actions={
          <Button onClick={() => ("cgvu" in changes ? setConfirmOpen(true) : void save())} loading={busy} disabled={changedCount === 0}>
            <Save /> Enregistrer{changedCount > 0 ? ` (${changedCount})` : ""}
          </Button>
        }
      />
      {error && <Alert variant="destructive" className="mb-4">{error}</Alert>}
      {initial == null && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : (
        initial && (
          <div className="grid gap-4">
            {SECTIONS.map((section) => (
              <Card key={section.title}>
                <CardHeader>
                  <CardTitle>{section.title}</CardTitle>
                  <CardDescription>{section.description}</CardDescription>
                </CardHeader>
                <CardContent className="grid gap-4">
                  {section.fields.map((f) => (
                    <div key={f.key} className="grid gap-1.5">
                      <Label htmlFor={`cfg-${f.key}`}>
                        {f.label}
                        {f.required && <span className="text-destructive"> *</span>}
                      </Label>
                      {f.multiline ? (
                        <textarea
                          id={`cfg-${f.key}`}
                          className={`${textareaClass} ${section.title.startsWith("Textes") ? "min-h-40 font-mono" : ""}`}
                          value={values[f.key] ?? ""}
                          disabled={busy}
                          onChange={(e) => setValues((v) => ({ ...v, [f.key]: e.target.value }))}
                        />
                      ) : (
                        <Input id={`cfg-${f.key}`} value={values[f.key] ?? ""} placeholder={f.placeholder} disabled={busy} onChange={(e) => setValues((v) => ({ ...v, [f.key]: e.target.value }))} />
                      )}
                      {f.hint && <p className="text-xs text-muted-foreground">{f.hint}</p>}
                    </div>
                  ))}
                </CardContent>
              </Card>
            ))}
          </div>
        )
      )}
      <ConfirmDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        title="Modifier les conditions générales ?"
        description="Tous les comptes devront accepter de nouveau les conditions générales à leur prochaine ouverture de l'app. Vérifiez le texte avant de continuer."
        confirmLabel="Enregistrer et réinitialiser l'acceptation"
        destructive
        onConfirm={save}
      />
    </>
  );
}
