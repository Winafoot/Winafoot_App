import { useCallback, useEffect, useState } from "react";
import { useSnackbarController } from "@firecms/core";
import {
  Alert,
  Button,
  Card,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
  TextField,
  Typography,
} from "@firecms/ui";
import { createAdmin, deleteAdmin, listAdmins, updateAdmin, type AdminAccount } from "../callables";

const NAME_MAX_LENGTH = 80;

function getErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof Error) {
    return error.message;
  }
  return fallback;
}

function formatDate(iso: string | null): string {
  if (iso == null) {
    return "Jamais";
  }
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? "Jamais" : new Intl.DateTimeFormat("fr-FR", { dateStyle: "short", timeStyle: "short" }).format(date);
}

function label(account: AdminAccount): string {
  return account.displayName.length > 0 ? account.displayName : account.email;
}

/** Une action sensible : un premier clic demande confirmation, le second l'exécute. */
function ActionRow({
  title,
  description,
  buttonLabel,
  danger,
  confirm,
  disabled,
  disabledReason,
  busy,
  onRun,
}: {
  title: string;
  description: string;
  buttonLabel: string;
  danger?: boolean;
  confirm?: boolean;
  disabled?: boolean;
  disabledReason?: string;
  busy: boolean;
  onRun: () => void | Promise<void>;
}) {
  const [confirming, setConfirming] = useState(false);

  return (
    <div className="flex flex-col gap-2 border-t border-gray-200 dark:border-gray-700 pt-3">
      <Typography variant="subtitle2">{title}</Typography>
      <Typography variant="body2">{disabled && disabledReason ? disabledReason : description}</Typography>
      <div className="flex flex-wrap gap-2">
        {!confirming ? (
          <Button
            variant="outlined"
            color={danger ? "error" : "primary"}
            disabled={disabled || busy}
            onClick={() => (confirm ? setConfirming(true) : onRun())}
          >
            {buttonLabel}
          </Button>
        ) : (
          <>
            <Button
              color={danger ? "error" : "primary"}
              disabled={busy}
              onClick={async () => {
                setConfirming(false);
                await onRun();
              }}
            >
              Confirmer
            </Button>
            <Button variant="text" onClick={() => setConfirming(false)}>
              Annuler
            </Button>
          </>
        )}
      </div>
    </div>
  );
}

function CreateDialog({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const snackbar = useSnackbarController();
  const [email, setEmail] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    try {
      const { data } = await createAdmin({ email, displayName: displayName.trim() || undefined });
      snackbar.open(
        data.inviteSent
          ? { type: "success", message: `Invitation envoyée à ${email.trim().toLowerCase()}.` }
          : {
              type: "warning",
              message: "Compte créé, mais l'e-mail n'est pas parti : ouvrez « Gérer » puis « Renvoyer l'invitation ».",
            },
      );
      onCreated();
    } catch (e: unknown) {
      snackbar.open({ type: "error", message: getErrorMessage(e, "La création a échoué.") });
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && !busy && onClose()} maxWidth="lg">
      <DialogTitle variant="h5">Inviter un administrateur</DialogTitle>
      <DialogContent className="flex flex-col gap-4">
        <Typography variant="body2">
          La personne reçoit un e-mail avec un lien pour choisir son mot de passe, valable une heure. Vérifiez bien
          l'adresse : celui qui reçoit le lien prend le contrôle du compte.
        </Typography>
        <TextField
          label="Adresse e-mail"
          value={email}
          autoComplete="off"
          onChange={(e) => setEmail(e.target.value)}
          disabled={busy}
        />
        <TextField
          label="Nom (optionnel)"
          value={displayName}
          autoComplete="off"
          maxLength={NAME_MAX_LENGTH}
          onChange={(e) => setDisplayName(e.target.value)}
          disabled={busy}
        />
      </DialogContent>
      <DialogActions>
        <Button variant="text" onClick={onClose} disabled={busy}>
          Annuler
        </Button>
        <Button onClick={submit} disabled={busy || email.trim().length === 0}>
          {busy ? "Envoi…" : "Inviter"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function ManageDialog({
  account,
  isSelf,
  onClose,
  onChanged,
  onFailed,
  onDelete,
}: {
  account: AdminAccount;
  isSelf: boolean;
  onClose: () => void;
  onChanged: (account: AdminAccount) => void;
  onFailed: () => void;
  onDelete: () => void;
}) {
  const snackbar = useSnackbarController();
  const [name, setName] = useState(account.displayName);
  const [busy, setBusy] = useState(false);

  const run = async (
    change: Parameters<typeof updateAdmin>[0],
    success: (inviteSent: boolean | undefined) => { type: "success" | "warning"; message: string },
  ) => {
    setBusy(true);
    try {
      const { data } = await updateAdmin(change);
      onChanged(data.admin);
      setName(data.admin.displayName);
      snackbar.open(success(data.inviteSent));
    } catch (e: unknown) {
      snackbar.open({ type: "error", message: getErrorMessage(e, "L'opération a échoué.") });
      onFailed();
    } finally {
      setBusy(false);
    }
  };

  const nameChanged = name.trim() !== account.displayName;

  return (
    <Dialog open onOpenChange={(open) => !open && !busy && onClose()} maxWidth="lg" scrollable>
      <DialogTitle variant="h5">{label(account)}</DialogTitle>
      <DialogContent className="flex flex-col gap-4">
        <Typography variant="body2">
          {account.email}
          {isSelf ? " · c'est votre compte" : ""}
        </Typography>

        <div className="flex gap-2 items-end">
          <div className="grow">
            <TextField
              label="Nom"
              value={name}
              maxLength={NAME_MAX_LENGTH}
              autoComplete="off"
              onChange={(e) => setName(e.target.value)}
              disabled={busy}
            />
          </div>
          <Button
            disabled={busy || !nameChanged}
            onClick={() => run({ uid: account.uid, displayName: name }, () => ({ type: "success", message: "Nom enregistré." }))}
          >
            Enregistrer
          </Button>
        </div>

        <ActionRow
          title={account.disabled ? "Réactiver le compte" : "Désactiver le compte"}
          description={
            account.disabled
              ? "Le compte pourra de nouveau se connecter."
              : "Le compte ne peut plus se connecter et ses sessions ouvertes sont coupées. Réversible."
          }
          buttonLabel={account.disabled ? "Réactiver" : "Désactiver"}
          confirm={!account.disabled}
          danger={!account.disabled}
          disabled={isSelf && !account.disabled}
          disabledReason="Vous ne pouvez pas désactiver votre propre compte."
          busy={busy}
          onRun={() =>
            run({ uid: account.uid, disabled: !account.disabled }, () => ({
              type: "success",
              message: account.disabled ? "Compte réactivé." : "Compte désactivé.",
            }))
          }
        />

        <ActionRow
          title="Renvoyer l'invitation"
          description="Envoie un nouveau lien pour choisir un mot de passe (mot de passe oublié, lien expiré)."
          buttonLabel="Renvoyer"
          disabled={account.disabled}
          disabledReason="Réactivez d'abord le compte."
          busy={busy}
          onRun={() =>
            run({ uid: account.uid, sendInvite: true }, (sent) =>
              sent === false
                ? { type: "warning", message: "L'e-mail n'est pas parti, réessayez dans un instant." }
                : { type: "success", message: `Lien envoyé à ${account.email}.` },
            )
          }
        />

        <ActionRow
          title="Retirer le second facteur"
          description={
            account.secondFactors > 0
              ? "À utiliser si la personne a perdu son téléphone : elle se reconnectera avec son mot de passe, puis pourra en inscrire un nouveau."
              : "Aucun second facteur n'est inscrit sur ce compte."
          }
          buttonLabel="Retirer"
          confirm
          danger
          disabled={isSelf || account.secondFactors === 0}
          disabledReason={isSelf ? "Pour votre propre compte, utilisez « Sécurité du compte »." : "Aucun second facteur n'est inscrit sur ce compte."}
          busy={busy}
          onRun={() => run({ uid: account.uid, resetSecondFactor: true }, () => ({ type: "success", message: "Second facteur retiré." }))}
        />

        <ActionRow
          title="Déconnecter partout"
          description="Coupe toutes les sessions ouvertes : la personne doit se reconnecter."
          buttonLabel="Déconnecter"
          confirm
          danger
          disabled={isSelf}
          disabledReason="Pour votre propre compte, utilisez le bouton de déconnexion."
          busy={busy}
          onRun={() => run({ uid: account.uid, revokeSessions: true }, () => ({ type: "success", message: "Sessions coupées." }))}
        />

        <ActionRow
          title="Supprimer le compte"
          description="Supprime définitivement ce compte administrateur. Impossible s'il est le dernier administrateur actif."
          buttonLabel="Supprimer…"
          danger
          disabled={isSelf}
          disabledReason="Vous ne pouvez pas supprimer votre propre compte."
          busy={busy}
          onRun={onDelete}
        />
      </DialogContent>
      <DialogActions>
        <Button variant="text" onClick={onClose} disabled={busy}>
          Fermer
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function DeleteDialog({
  account,
  onClose,
  onDeleted,
  onFailed,
}: {
  account: AdminAccount;
  onClose: () => void;
  onDeleted: () => void;
  onFailed: () => void;
}) {
  const snackbar = useSnackbarController();
  const [typed, setTyped] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    try {
      await deleteAdmin(account.uid);
      snackbar.open({ type: "success", message: "Compte supprimé." });
      onDeleted();
    } catch (e: unknown) {
      snackbar.open({ type: "error", message: getErrorMessage(e, "La suppression a échoué.") });
      onFailed();
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog open onOpenChange={(open) => !open && !busy && onClose()} maxWidth="lg">
      <DialogTitle variant="h5">Supprimer {label(account)} ?</DialogTitle>
      <DialogContent className="flex flex-col gap-4">
        <Typography variant="body2">
          Cette suppression est irréversible : le compte disparaît et la personne perd tout accès au back-office. Tapez
          l'adresse <strong>{account.email}</strong> pour confirmer.
        </Typography>
        <TextField label="Adresse e-mail du compte" value={typed} autoComplete="off" onChange={(e) => setTyped(e.target.value)} disabled={busy} />
      </DialogContent>
      <DialogActions>
        <Button variant="text" onClick={onClose} disabled={busy}>
          Annuler
        </Button>
        <Button color="error" onClick={submit} disabled={busy || typed.trim().toLowerCase() !== account.email.toLowerCase()}>
          {busy ? "Suppression…" : "Supprimer définitivement"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

type DialogState = { kind: "create" } | { kind: "manage"; uid: string } | { kind: "delete"; uid: string } | null;

export function AdminsView() {
  // null = pas encore chargé.
  const [accounts, setAccounts] = useState<AdminAccount[] | null>(null);
  const [self, setSelf] = useState("");
  const [loadError, setLoadError] = useState<string | null>(null);
  const [dialog, setDialog] = useState<DialogState>(null);

  const load = useCallback(async () => {
    try {
      const { data } = await listAdmins();
      setAccounts(data.admins);
      setSelf(data.self);
      setLoadError(null);
    } catch (e: unknown) {
      setLoadError(getErrorMessage(e, "Chargement impossible."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const replace = (updated: AdminAccount) =>
    setAccounts((current) => (current == null ? current : current.map((a) => (a.uid === updated.uid ? updated : a))));

  const target = dialog != null && dialog.kind !== "create" ? accounts?.find((a) => a.uid === dialog.uid) : undefined;
  const close = () => setDialog(null);

  return (
    <div className="p-8 flex flex-col gap-4 max-w-4xl">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <Typography variant="h4">Administrateurs</Typography>
        <Button onClick={() => setDialog({ kind: "create" })}>Inviter un administrateur</Button>
      </div>
      <Typography variant="body2">
        Un administrateur a accès à tout le back-office. Donnez à chaque personne son propre compte : le second facteur
        (code d'une application) est lié au compte, il ne se partage pas.
      </Typography>

      {loadError != null && (
        <Alert
          color="error"
          action={
            <Button variant="text" onClick={() => void load()}>
              Réessayer
            </Button>
          }
        >
          {loadError}
        </Alert>
      )}

      <Card className="overflow-x-auto">
        {accounts === null && loadError == null && <Typography className="p-6" variant="body2">Chargement…</Typography>}
        {accounts !== null && accounts.length === 0 && <Typography className="p-6" variant="body2">Aucun administrateur.</Typography>}
        {accounts !== null && accounts.length > 0 && (
          <Table>
            <TableHeader>
              <TableCell header>Administrateur</TableCell>
              <TableCell header>Statut</TableCell>
              <TableCell header>Second facteur</TableCell>
              <TableCell header>Dernière connexion</TableCell>
              <TableCell header align="right">
                <span className="sr-only">Actions</span>
              </TableCell>
            </TableHeader>
            <TableBody>
              {accounts.map((account) => (
                <TableRow key={account.uid}>
                  <TableCell>
                    <div className="flex flex-col">
                      <span className="font-medium">{label(account)}</span>
                      {account.displayName.length > 0 && <span className="text-sm">{account.email}</span>}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {account.disabled ? <Chip size="small" error>Désactivé</Chip> : <Chip size="small">Actif</Chip>}
                      {account.uid === self && <Chip size="small" colorScheme="blueLighter">Vous</Chip>}
                      {!account.emailVerified && <Chip size="small" colorScheme="orangeLighter">E-mail non vérifié</Chip>}
                    </div>
                  </TableCell>
                  <TableCell>{account.secondFactors > 0 ? "Activé" : "Aucun"}</TableCell>
                  <TableCell>{formatDate(account.lastSignInAt)}</TableCell>
                  <TableCell align="right">
                    <Button variant="outlined" size="small" onClick={() => setDialog({ kind: "manage", uid: account.uid })}>
                      Gérer
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {dialog?.kind === "create" && (
        <CreateDialog
          onClose={close}
          onCreated={() => {
            close();
            void load();
          }}
        />
      )}
      {dialog?.kind === "manage" && target && (
        <ManageDialog
          account={target}
          isSelf={target.uid === self}
          onClose={close}
          onChanged={replace}
          onFailed={() => void load()}
          onDelete={() => setDialog({ kind: "delete", uid: target.uid })}
        />
      )}
      {dialog?.kind === "delete" && target && (
        <DeleteDialog
          account={target}
          onClose={() => setDialog({ kind: "manage", uid: target.uid })}
          onDeleted={() => {
            close();
            void load();
          }}
          onFailed={() => void load()}
        />
      )}
    </div>
  );
}
