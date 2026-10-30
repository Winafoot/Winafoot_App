"use client";
import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { doc, onSnapshot } from "firebase/firestore";
import { ArrowLeft, Ban, CheckCircle2, Mail, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { CoachDataTabs } from "@/components/coach-data-tabs";
import { LinkedTeamsCard } from "@/components/linked-teams-card";
import { CoachStatusBadge, SubscriptionBadge } from "@/components/coach-badges";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { deleteCoach, errorMessage, resendInvite, setCoachDisabled } from "@/lib/callables";
import type { Coach } from "@/lib/data";
import { db } from "@/lib/firebase";
import { TEAM_CATEGORIES, TEAM_DIVISIONS } from "@/lib/team-options";
import { formatDate, formatDateTime } from "@/lib/utils";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid gap-0.5">
      <dt className="text-xs uppercase tracking-wide text-muted-foreground">{label}</dt>
      <dd className="text-sm">{children || "—"}</dd>
    </div>
  );
}

function CoachDetail({ uid }: { uid: string }) {
  const router = useRouter();
  const [coach, setCoach] = useState<Coach | null | undefined>(undefined);
  const [error, setError] = useState<string>();
  const [dialog, setDialog] = useState<"disable" | "delete" | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(
    () =>
      onSnapshot(
        doc(db(), "users", uid),
        (snap) => setCoach(snap.exists() ? ({ id: snap.id, ...snap.data() } as Coach) : null),
        (e) => setError(e.message),
      ),
    [uid],
  );

  if (error) return <Alert variant="destructive">Lecture impossible : {error}</Alert>;
  if (coach === undefined) return <Skeleton className="h-64 w-full" />;
  if (coach === null) {
    return (
      <Alert>
        Compte introuvable. Il a peut-être été supprimé.{" "}
        <Link href="/coachs/" className="underline">
          Retour à la liste
        </Link>
      </Alert>
    );
  }

  const label = coach.teamName ?? coach.email ?? coach.id;
  const sub = coach.subscription;

  const resend = async () => {
    setBusy(true);
    try {
      await resendInvite({ uid });
      toast.success("Invitation renvoyée.");
    } catch (e) {
      toast.error(errorMessage(e, "Envoi impossible."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader
        title={coach.coachName ?? coach.firstname ?? coach.email ?? "Coach"}
        description={coach.email}
        actions={
          <>
            <Button variant="outline" asChild>
              <Link href="/coachs/">
                <ArrowLeft /> Liste
              </Link>
            </Button>
            <Button variant="outline" onClick={resend} loading={busy}>
              <Mail /> Renvoyer l&apos;invitation
            </Button>
            <Button variant="outline" onClick={() => setDialog("disable")}>
              {coach.disabled ? <CheckCircle2 /> : <Ban />}
              {coach.disabled ? "Réactiver" : "Désactiver"}
            </Button>
            <Button variant="destructive" onClick={() => setDialog("delete")}>
              <Trash2 /> Supprimer
            </Button>
          </>
        }
      />

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              Profil <CoachStatusBadge coach={coach} />
            </CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="grid grid-cols-2 gap-4">
              <Field label="Équipe">{coach.teamName}</Field>
              <Field label="Format">{coach.teamFormat ? `Foot à ${coach.teamFormat}` : null}</Field>
              <Field label="Catégorie">{TEAM_CATEGORIES[coach.category ?? ""] ?? coach.category}</Field>
              <Field label="Division">{TEAM_DIVISIONS[coach.division ?? ""] ?? coach.division}</Field>
              <Field label="Créé le">{formatDate(coach.createdAt)}</Field>
              <Field label="Dernière invitation">{formatDateTime(coach.lastInviteSentAt)}</Field>
            </dl>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              Abonnement <SubscriptionBadge coach={coach} />
            </CardTitle>
          </CardHeader>
          <CardContent>
            {sub ? (
              <dl className="grid grid-cols-2 gap-4">
                <Field label="Formule">
                  {sub.teamsAllowed ? `${sub.teamsAllowed} équipe${sub.teamsAllowed > 1 ? "s" : ""}` : null}
                  {sub.period ? ` · ${sub.period === "monthly" ? "mensuel" : "annuel"}` : null}
                </Field>
                <Field label="Boutique">{sub.store === "app_store" ? "App Store" : sub.store === "play_store" ? "Google Play" : null}</Field>
                <Field label="Fin d'essai">{formatDate(sub.trialEnd)}</Field>
                <Field label="Expire le">{formatDate(sub.expiresAt)}</Field>
                <Field label="Accès">{coach.access ? (coach.access.active ? `Actif jusqu'au ${formatDate(coach.access.until)}` : "Inactif") : null}</Field>
                <Field label="Produit">{sub.productId}</Field>
              </dl>
            ) : (
              <p className="text-sm text-muted-foreground">
                Aucun abonnement.{coach.manualGrant ? " Accès accordé manuellement." : ""}
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      <LinkedTeamsCard owner={coach} />

      <CoachDataTabs uid={uid} />

      <ConfirmDialog
        open={dialog === "disable"}
        onOpenChange={(open) => !open && setDialog(null)}
        title={coach.disabled ? "Réactiver ce compte ?" : "Désactiver ce compte ?"}
        description={
          coach.disabled
            ? `${label} pourra de nouveau se connecter.`
            : `${label} ne pourra plus se connecter tant que le compte est désactivé. Ses données sont conservées.`
        }
        confirmLabel={coach.disabled ? "Réactiver" : "Désactiver"}
        destructive={!coach.disabled}
        onConfirm={async () => {
          try {
            await setCoachDisabled({ uid, disabled: !coach.disabled });
            toast.success(coach.disabled ? "Compte réactivé." : "Compte désactivé.");
          } catch (e) {
            toast.error(errorMessage(e, "Opération impossible."));
          }
        }}
      />

      <ConfirmDialog
        open={dialog === "delete"}
        onOpenChange={(open) => !open && setDialog(null)}
        title="Supprimer définitivement ce compte ?"
        description="Cette suppression est irréversible : le compte, les joueurs, les matchs et les compositions seront perdus."
        confirmLabel="Supprimer définitivement"
        confirmText={label}
        destructive
        onConfirm={async () => {
          try {
            await deleteCoach({ uid });
            toast.success("Compte supprimé.");
            router.replace("/coachs/");
          } catch (e) {
            toast.error(errorMessage(e, "Suppression impossible."));
          }
        }}
      />
    </>
  );
}

function Content() {
  const uid = useSearchParams().get("uid");
  if (!uid) return <Alert variant="destructive">Aucun compte sélectionné.</Alert>;
  return <CoachDetail uid={uid} />;
}

// useSearchParams exige une frontière Suspense dans un export statique.
export default function CoachDetailPage() {
  return (
    <Suspense fallback={<Skeleton className="h-64 w-full" />}>
      <Content />
    </Suspense>
  );
}
