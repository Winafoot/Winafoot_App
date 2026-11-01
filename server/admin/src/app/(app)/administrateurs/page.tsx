"use client";
import { useCallback, useEffect, useMemo, useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { UserPlus } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { DataTable } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createAdmin, deleteAdmin, errorMessage, listAdmins, updateAdmin, type AdminAccount } from "@/lib/callables";
import { formatDateTime, toDate } from "@/lib/utils";

const NAME_MAX_LENGTH = 80;

const label = (a: AdminAccount) => (a.displayName.length > 0 ? a.displayName : a.email);

function CreateDialog({ open, onClose, onCreated }: { open: boolean; onClose: () => void; onCreated: () => void }) {
  const [email, setEmail] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    try {
      const { inviteSent } = await createAdmin({ email, displayName: displayName.trim() || undefined });
      if (inviteSent) toast.success(`Invitation envoyée à ${email.trim().toLowerCase()}.`);
      else toast.warning("Compte créé, mais l'e-mail n'est pas parti : ouvrez « Gérer » puis « Renvoyer l'invitation ».");
      setEmail("");
      setDisplayName("");
      onCreated();
      onClose();
    } catch (e) {
      toast.error(errorMessage(e, "La création a échoué."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !next && !busy && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Inviter un administrateur</DialogTitle>
          <DialogDescription>
            La personne reçoit un e-mail avec un lien pour choisir son mot de passe, valable une heure. Vérifiez bien l&apos;adresse : celui qui reçoit le
            lien prend le contrôle du compte.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="admin-email">Adresse e-mail</Label>
          <Input id="admin-email" type="email" autoComplete="off" value={email} onChange={(e) => setEmail(e.target.value)} disabled={busy} />
        </div>
        <div className="grid gap-2">
          <Label htmlFor="admin-name">Nom (optionnel)</Label>
          <Input id="admin-name" autoComplete="off" maxLength={NAME_MAX_LENGTH} value={displayName} onChange={(e) => setDisplayName(e.target.value)} disabled={busy} />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={busy}>
            Annuler
          </Button>
          <Button onClick={submit} loading={busy} disabled={email.trim().length === 0}>
            Inviter
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

type ActionKey = "disable" | "invite" | "resetMfa" | "revoke" | "delete";

function ManageDialog({
  account,
  isSelf,
  onClose,
  onChanged,
  onReload,
}: {
  account: AdminAccount;
  isSelf: boolean;
  onClose: () => void;
  onChanged: (a: AdminAccount) => void;
  onReload: () => void;
}) {
  const [name, setName] = useState(account.displayName);
  const [busy, setBusy] = useState(false);
  const [confirm, setConfirm] = useState<ActionKey | null>(null);

  const run = async (change: Parameters<typeof updateAdmin>[0], success: (inviteSent?: boolean) => void) => {
    setBusy(true);
    try {
      const { admin, inviteSent } = await updateAdmin(change);
      onChanged(admin);
      setName(admin.displayName);
      success(inviteSent);
    } catch (e) {
      toast.error(errorMessage(e));
      onReload();
    } finally {
      setBusy(false);
    }
  };

  const rows: { key: ActionKey; title: string; description: string; button: string; destructive?: boolean; disabled?: boolean; reason?: string }[] = [
    {
      key: "disable",
      title: account.disabled ? "Réactiver le compte" : "Désactiver le compte",
      description: account.disabled ? "Le compte pourra de nouveau se connecter." : "Le compte ne peut plus se connecter et ses sessions ouvertes sont coupées. Réversible.",
      button: account.disabled ? "Réactiver" : "Désactiver",
      destructive: !account.disabled,
      disabled: isSelf && !account.disabled,
      reason: "Vous ne pouvez pas désactiver votre propre compte.",
    },
    {
      key: "invite",
      title: "Renvoyer l'invitation",
      description: "Envoie un nouveau lien pour choisir un mot de passe (mot de passe oublié, lien expiré).",
      button: "Renvoyer",
      disabled: account.disabled,
      reason: "Réactivez d'abord le compte.",
    },
    {
      key: "resetMfa",
      title: "Retirer le second facteur",
      description: "À utiliser si la personne a perdu son téléphone : elle se reconnectera avec son mot de passe, puis pourra en inscrire un nouveau.",
      button: "Retirer",
      destructive: true,
      disabled: isSelf || account.secondFactors === 0,
      reason: isSelf ? "Pour votre propre compte, utilisez « Sécurité du compte »." : "Aucun second facteur n'est inscrit sur ce compte.",
    },
    {
      key: "revoke",
      title: "Déconnecter partout",
      description: "Coupe toutes les sessions ouvertes : la personne doit se reconnecter.",
      button: "Déconnecter",
      destructive: true,
      disabled: isSelf,
      reason: "Pour votre propre compte, utilisez le bouton de déconnexion.",
    },
    {
      key: "delete",
      title: "Supprimer le compte",
      description: "Supprime définitivement ce compte administrateur. Impossible s'il est le dernier administrateur actif.",
      button: "Supprimer…",
      destructive: true,
      disabled: isSelf,
      reason: "Vous ne pouvez pas supprimer votre propre compte.",
    },
  ];

  const perform = async (key: ActionKey) => {
    switch (key) {
      case "disable":
        return run({ uid: account.uid, disabled: !account.disabled }, () => toast.success(account.disabled ? "Compte réactivé." : "Compte désactivé."));
      case "invite":
        return run({ uid: account.uid, sendInvite: true }, (sent) =>
          sent === false ? toast.warning("L'e-mail n'est pas parti, réessayez dans un instant.") : toast.success(`Lien envoyé à ${account.email}.`),
        );
      case "resetMfa":
        return run({ uid: account.uid, resetSecondFactor: true }, () => toast.success("Second facteur retiré."));
      case "revoke":
        return run({ uid: account.uid, revokeSessions: true }, () => toast.success("Sessions coupées."));
      case "delete":
        try {
          await deleteAdmin({ uid: account.uid });
          toast.success("Compte supprimé.");
          onReload();
          onClose();
        } catch (e) {
          toast.error(errorMessage(e, "La suppression a échoué."));
          onReload();
        }
    }
  };

  const confirming = rows.find((r) => r.key === confirm);

  return (
    <>
      <Dialog open onOpenChange={(next) => !next && !busy && onClose()}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>{label(account)}</DialogTitle>
            <DialogDescription>
              {account.email}
              {isSelf ? " · c'est votre compte" : ""}
            </DialogDescription>
          </DialogHeader>

          <div className="flex items-end gap-2">
            <div className="grid flex-1 gap-2">
              <Label htmlFor="manage-name">Nom</Label>
              <Input id="manage-name" value={name} maxLength={NAME_MAX_LENGTH} autoComplete="off" onChange={(e) => setName(e.target.value)} disabled={busy} />
            </div>
            <Button
              disabled={busy || name.trim() === account.displayName}
              onClick={() => run({ uid: account.uid, displayName: name }, () => toast.success("Nom enregistré."))}
            >
              Enregistrer
            </Button>
          </div>

          {rows.map((r) => (
            <div key={r.key} className="grid gap-2 border-t pt-3">
              <p className="text-sm font-medium">{r.title}</p>
              <p className="text-sm text-muted-foreground">{r.disabled ? r.reason : r.description}</p>
              <div>
                <Button
                  variant="outline"
                  size="sm"
                  className={r.destructive ? "border-destructive/50 text-destructive hover:bg-destructive/10" : undefined}
                  disabled={r.disabled || busy}
                  onClick={() => (r.destructive ? setConfirm(r.key) : void perform(r.key))}
                >
                  {r.button}
                </Button>
              </div>
            </div>
          ))}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={confirming != null}
        onOpenChange={(open) => !open && setConfirm(null)}
        title={confirming?.key === "delete" ? `Supprimer ${label(account)} ?` : (confirming?.title ?? "")}
        description={
          confirming?.key === "delete"
            ? "Cette suppression est irréversible : le compte disparaît et la personne perd tout accès au back-office."
            : (confirming?.description ?? "")
        }
        confirmLabel={confirming?.key === "delete" ? "Supprimer définitivement" : (confirming?.button.replace("…", "") ?? "Confirmer")}
        confirmText={confirming?.key === "delete" ? account.email : undefined}
        destructive
        onConfirm={() => (confirm ? perform(confirm) : undefined)}
      />
    </>
  );
}

export default function AdminsPage() {
  const [accounts, setAccounts] = useState<AdminAccount[] | null>(null);
  const [self, setSelf] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [managedUid, setManagedUid] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const { admins, self } = await listAdmins({});
      setAccounts(admins);
      setSelf(self);
      setError(null);
    } catch (e) {
      setError(errorMessage(e, "Chargement impossible."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const replace = (updated: AdminAccount) => setAccounts((cur) => cur?.map((a) => (a.uid === updated.uid ? updated : a)) ?? cur);
  const managed = accounts?.find((a) => a.uid === managedUid);

  const columns = useMemo<ColumnDef<AdminAccount, unknown>[]>(
    () => [
      {
        id: "name",
        header: "Administrateur",
        accessorFn: (a) => `${a.displayName} ${a.email}`,
        cell: ({ row }) => (
          <div className="min-w-0">
            <p className="truncate font-medium">{label(row.original)}</p>
            {row.original.displayName && <p className="truncate text-xs text-muted-foreground">{row.original.email}</p>}
          </div>
        ),
      },
      {
        id: "status",
        header: "Statut",
        accessorFn: (a) => (a.disabled ? "Désactivé" : a.emailVerified ? "Actif" : "Invité"),
        cell: ({ row }) =>
          row.original.disabled ? <Badge variant="destructive">Désactivé</Badge> : row.original.emailVerified ? <Badge>Actif</Badge> : <Badge variant="warning">Invité</Badge>,
      },
      {
        id: "mfa",
        header: "Second facteur",
        accessorFn: (a) => a.secondFactors,
        cell: ({ row }) => (row.original.secondFactors > 0 ? <Badge>Activé</Badge> : <Badge variant="warning">Non</Badge>),
      },
      { id: "last", header: "Dernière connexion", accessorFn: (a) => toDate(a.lastSignInAt)?.getTime() ?? 0, cell: ({ row }) => (row.original.lastSignInAt ? formatDateTime(row.original.lastSignInAt) : "Jamais") },
      {
        id: "actions",
        header: "",
        enableSorting: false,
        accessorFn: () => "",
        cell: ({ row }) => (
          <Button variant="outline" size="sm" onClick={() => setManagedUid(row.original.uid)}>
            Gérer
          </Button>
        ),
      },
    ],
    [],
  );

  return (
    <>
      <PageHeader
        title="Administrateurs"
        description="Un administrateur a accès à tout le back-office. Donnez à chaque personne son propre compte : le second facteur est lié au compte, il ne se partage pas."
        actions={
          <Button onClick={() => setCreating(true)}>
            <UserPlus /> Inviter un administrateur
          </Button>
        }
      />
      {error && (
        <Alert variant="destructive" className="mb-4 flex items-center justify-between gap-2">
          {error}
          <Button variant="outline" size="sm" onClick={load}>
            Réessayer
          </Button>
        </Alert>
      )}
      <DataTable columns={columns} data={accounts ?? []} loading={accounts == null && error == null} searchPlaceholder="Rechercher un administrateur…" emptyMessage="Aucun administrateur." />

      <CreateDialog open={creating} onClose={() => setCreating(false)} onCreated={load} />
      {managed && <ManageDialog key={managed.uid} account={managed} isSelf={managed.uid === self} onClose={() => setManagedUid(null)} onChanged={replace} onReload={load} />}
    </>
  );
}
