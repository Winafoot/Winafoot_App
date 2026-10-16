import { useEffect, useState, type FormEvent } from "react";
import { useAuthController, useSnackbarController } from "@firecms/core";
import type { FirebaseUserWrapper } from "@firecms/firebase";
import { Alert, Button, Card, TextField, Typography } from "@firecms/ui";
import { multiFactor, TotpMultiFactorGenerator, type MultiFactorInfo, type TotpSecret } from "firebase/auth";
import { getAuthErrorCode, getAuthErrorMessage } from "../auth_errors";

const CODE_LENGTH = 6;
const FACTOR_NAME = "Application d'authentification";
// Sans espace ni accent : le SDK recopie tel quel l'émetteur dans l'URL otpauth.
const ISSUER = "Wina";

export function SecurityView() {
  const authController = useAuthController<FirebaseUserWrapper>();
  const snackbar = useSnackbarController();
  const user = authController.user?.firebaseUser ?? null;
  // null = état pas encore connu.
  const [factors, setFactors] = useState<MultiFactorInfo[] | null>(null);
  const [secret, setSecret] = useState<TotpSecret | null>(null);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<unknown>();

  // Recharge le compte pour afficher l'état réel du second facteur. Hors ligne, on
  // se contente de l'état déjà connu du SDK.
  useEffect(() => {
    if (!user) {
      return;
    }
    let cancelled = false;
    user
      .reload()
      .catch(() => undefined)
      .then(() => {
        if (!cancelled) {
          setFactors([...multiFactor(user).enrolledFactors]);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [user]);

  const start = async () => {
    if (!user || busy) {
      return;
    }
    setBusy(true);
    setError(undefined);
    try {
      const session = await multiFactor(user).getSession();
      setSecret(await TotpMultiFactorGenerator.generateSecret(session));
    } catch (e: unknown) {
      setError(e);
    } finally {
      setBusy(false);
    }
  };

  const confirm = async (event: FormEvent) => {
    event.preventDefault();
    if (!user || !secret || busy || code.length !== CODE_LENGTH) {
      return;
    }
    setBusy(true);
    setError(undefined);
    try {
      await multiFactor(user).enroll(TotpMultiFactorGenerator.assertionForEnrollment(secret, code), FACTOR_NAME);
      setFactors([...multiFactor(user).enrolledFactors]);
      setSecret(null);
      snackbar.open({ type: "success", message: "Second facteur activé. Reconnectez-vous pour l'utiliser." });
    } catch (e: unknown) {
      setError(e);
      // Clé périmée : inutile de resaisir un code, il faut en générer une nouvelle.
      const code = getAuthErrorCode(e);
      if (code === "auth/code-expired" || code === "auth/invalid-verification-id" || code === "auth/missing-verification-id") {
        setSecret(null);
      }
    } finally {
      setCode("");
      setBusy(false);
    }
  };

  const cancel = () => {
    setSecret(null);
    setCode("");
    setError(undefined);
  };

  const needsRelogin = getAuthErrorCode(error) === "auth/requires-recent-login";

  return (
    <div className="p-8 flex flex-col gap-4 max-w-xl">
      <Typography variant="h4">Sécurité du compte</Typography>
      <Typography variant="body2">
        Le second facteur complète votre mot de passe par un code à {CODE_LENGTH} chiffres généré par une
        application d'authentification (Google Authenticator, Microsoft Authenticator, 1Password, Authy…).
      </Typography>
      <Card className="p-6 flex flex-col gap-4">
        {error !== undefined && (
          <Alert
            color="error"
            action={
              needsRelogin ? (
                <Button variant="text" onClick={() => authController.signOut()}>
                  Se déconnecter
                </Button>
              ) : undefined
            }
          >
            {getAuthErrorMessage(error)}
          </Alert>
        )}

        {factors === null && <Typography variant="body2">Chargement…</Typography>}

        {factors !== null && factors.length > 0 && (
          <Alert color="success">
            Second facteur activé : {factors.map((f) => f.displayName ?? f.factorId).join(", ")}. Un code vous
            sera demandé à chaque connexion.
          </Alert>
        )}

        {factors !== null && factors.length === 0 && !secret && (
          <>
            <Alert color="warning">
              Aucun second facteur : votre compte n'est protégé que par son mot de passe.
            </Alert>
            <Button onClick={start} disabled={busy || !user}>
              {busy ? "Préparation…" : "Activer le second facteur"}
            </Button>
          </>
        )}

        {factors !== null && factors.length === 0 && secret && (
          <form className="flex flex-col gap-4" onSubmit={confirm}>
            <Typography variant="body2">
              1. Dans votre application d'authentification, ajoutez un compte en saisissant cette clé (type
              « basé sur l'heure »). Aucun code QR n'est affiché : la saisie de la clé suffit.
            </Typography>
            <code className="select-all break-all font-mono text-lg">{secret.secretKey}</code>
            <Typography variant="body2">
              Si votre application accepte une adresse otpauth (gestionnaires de mots de passe notamment) :
            </Typography>
            <code className="select-all break-all font-mono text-xs">
              {secret.generateQrCodeUrl(user?.email ?? undefined, ISSUER)}
            </code>
            <Typography variant="body2">
              2. Saisissez le code à {CODE_LENGTH} chiffres que l'application affiche maintenant, pour
              confirmer.
            </Typography>
            <TextField
              label={`Code à ${CODE_LENGTH} chiffres`}
              inputMode="numeric"
              autoComplete="one-time-code"
              value={code}
              disabled={busy}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, CODE_LENGTH))}
            />
            <div className="flex justify-end gap-2">
              <Button variant="text" onClick={cancel} disabled={busy}>
                Annuler
              </Button>
              <Button type="submit" disabled={busy || code.length !== CODE_LENGTH}>
                {busy ? "Vérification…" : "Confirmer"}
              </Button>
            </div>
          </form>
        )}
      </Card>
    </div>
  );
}
