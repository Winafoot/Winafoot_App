import { useMemo, useState, type FormEvent } from "react";
import { getAuth, getMultiFactorResolver, TotpMultiFactorGenerator, type MultiFactorError } from "firebase/auth";
import { Alert, Button, TextField, Typography } from "@firecms/ui";
import { getAuthErrorMessage } from "../auth_errors";

const CODE_LENGTH = 6;

// Seconde étape de connexion pour un compte protégé par un second facteur TOTP.
// App.tsx affiche cette vue à la place de LoginView dès que le contrôleur FireCMS remonte
// l'erreur « multi-factor-auth-required ». La connexion
// finalisée ici passe par la même instance Auth : le contrôleur la suit via
// onAuthStateChanged, rien d'autre à brancher.
export function TotpSignInView({ error, onCancel }: { error: MultiFactorError; onCancel: () => void }) {
  // L'erreur peut être périmée (déconnexion dans un autre onglet, jeton révoqué) : le SDK refuse alors
  // de construire le résolveur. On affiche un message plutôt qu'une page blanche.
  const resolver = useMemo(() => {
    try {
      return getMultiFactorResolver(getAuth(), error);
    } catch {
      return null;
    }
  }, [error]);
  const hint = resolver?.hints.find((h) => h.factorId === TotpMultiFactorGenerator.FACTOR_ID);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string>();

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (busy || !resolver || !hint || code.length !== CODE_LENGTH) {
      return;
    }
    setBusy(true);
    setMessage(undefined);
    try {
      await resolver.resolveSignIn(TotpMultiFactorGenerator.assertionForSignIn(hint.uid, code));
      // Succès : on reste « occupé » (pas de second envoi possible) jusqu'à ce que le
      // contrôleur prenne le relais et retire cette vue.
    } catch (e: unknown) {
      setMessage(getAuthErrorMessage(e));
      setCode("");
      setBusy(false);
    }
  };

  return (
    <form className="flex flex-col items-center justify-center min-w-full p-4" onSubmit={submit}>
      <div className="max-w-[480px] w-full flex flex-col gap-4">
        <Typography variant="h5">Vérification en deux étapes</Typography>
        {resolver == null ? (
          <Alert color="error">La session de connexion a expiré. Recommencez la connexion.</Alert>
        ) : hint ? (
          <Typography variant="body2">
            Saisissez le code à {CODE_LENGTH} chiffres affiché par votre application d'authentification.
          </Typography>
        ) : (
          <Alert color="error">
            Ce compte utilise un second facteur que le back-office ne prend pas en charge. Contactez l'équipe
            technique.
          </Alert>
        )}
        {message && <Alert color="error">{message}</Alert>}
        {hint && (
          <TextField
            label={`Code à ${CODE_LENGTH} chiffres`}
            autoFocus
            inputMode="numeric"
            autoComplete="one-time-code"
            value={code}
            disabled={busy}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, CODE_LENGTH))}
          />
        )}
        <div className="flex justify-end gap-2">
          <Button variant="text" onClick={onCancel} disabled={busy}>
            Retour
          </Button>
          {hint && (
            <Button type="submit" disabled={busy || code.length !== CODE_LENGTH}>
              {busy ? "Vérification…" : "Valider"}
            </Button>
          )}
        </div>
      </div>
    </form>
  );
}
