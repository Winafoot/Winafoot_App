import { useState, type FormEvent } from "react";
import { getAuth } from "firebase/auth";
import type { FirebaseApp } from "firebase/app";
import type { FirebaseAuthController } from "@firecms/firebase";
import { Alert, Button, TextField, Typography } from "@firecms/ui";
import { getAuthErrorCode, getAuthErrorMessage } from "../auth_errors";

// Écran de connexion du back-office : e-mail et mot de passe, réinitialisation du mot de passe.
// Les comptes administrateurs sont créés depuis la vue « Administrateurs » : l'écran ne propose
// pas de création de compte. La connexion passe par le contrôleur FireCMS (emailPasswordLogin),
// qui suit l'état Firebase Auth ; un compte protégé par un second facteur bascule ensuite sur
// TotpSignInView (App.tsx).
export function LoginView({
  firebaseApp,
  authController,
  notAllowedError,
}: {
  firebaseApp: FirebaseApp;
  authController: FirebaseAuthController;
  notAllowedError?: unknown;
}) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [resetState, setResetState] = useState<"idle" | "sending" | "sent">("idle");
  const [resetError, setResetError] = useState<string>();

  const loading = authController.authLoading;
  const signedIn = authController.user != null;
  const providerError = authController.authProviderError;
  const providerErrorCode = getAuthErrorCode(providerError);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (loading || !email || !password) {
      return;
    }
    setResetState("idle");
    setResetError(undefined);
    authController.emailPasswordLogin(email.trim(), password);
  };

  const resetPassword = async () => {
    if (!email) {
      setResetError("Saisissez votre adresse e-mail, puis cliquez sur « Mot de passe oublié ».");
      return;
    }
    setResetError(undefined);
    setResetState("sending");
    try {
      // E-mail de réinitialisation envoyé par Firebase Auth, dans le modèle français.
      getAuth(firebaseApp).languageCode = "fr";
      await authController.sendPasswordResetEmail(email.trim());
      setResetState("sent");
    } catch (e: unknown) {
      setResetError(getAuthErrorMessage(e));
      setResetState("idle");
    }
  };

  let notAllowedMessage: string | undefined;
  if (notAllowedError) {
    notAllowedMessage = notAllowedError instanceof Error
      ? notAllowedError.message
      : typeof notAllowedError === "string"
        ? notAllowedError
        : "Accès réservé aux administrateurs Wina.";
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen min-w-full p-4">
      <div className="max-w-[420px] w-full flex flex-col gap-4">
        <img src="/favicon.png" alt="Wina" className="w-24 h-24 self-center rounded-xl"/>
        <Typography variant="h5" className="self-center">Back-office Wina</Typography>

        {notAllowedMessage && <Alert color="error">{notAllowedMessage}</Alert>}

        {signedIn ? (
          <div className="flex justify-end">
            <Button onClick={authController.signOut}>Se déconnecter</Button>
          </div>
        ) : (
          <form className="flex flex-col gap-4" onSubmit={submit}>
            <TextField
              label="Adresse e-mail"
              type="email"
              autoComplete="username"
              autoFocus
              value={email}
              disabled={loading}
              onChange={(e) => setEmail(e.target.value)}
            />
            <TextField
              label="Mot de passe"
              type="password"
              autoComplete="current-password"
              value={password}
              disabled={loading}
              onChange={(e) => setPassword(e.target.value)}
            />

            {providerError && providerErrorCode !== "auth/multi-factor-auth-required" && (
              <Alert color="error">{getAuthErrorMessage(providerError)}</Alert>
            )}
            {resetError && <Alert color="error">{resetError}</Alert>}
            {resetState === "sent" && (
              <Alert color="success">
                Si un compte existe pour cette adresse, un e-mail de réinitialisation du mot de passe vient
                d'être envoyé.
              </Alert>
            )}

            <div className="flex justify-between items-center gap-2">
              <Button variant="text" onClick={resetPassword} disabled={loading || resetState === "sending"}>
                {resetState === "sending" ? "Envoi…" : "Mot de passe oublié"}
              </Button>
              <Button type="submit" disabled={loading || !email || !password}>
                {loading ? "Connexion…" : "Se connecter"}
              </Button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
