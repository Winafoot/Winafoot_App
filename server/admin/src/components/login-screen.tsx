"use client";
import { useState, type FormEvent } from "react";
import { ShieldCheck } from "lucide-react";
import { useAuth } from "@/lib/auth-provider";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const CODE_LENGTH = 6;

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="flex flex-col items-center gap-3">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/favicon.png" alt="Wina" className="size-16 rounded-xl" />
          <h1 className="text-xl font-semibold">Back-office Wina</h1>
        </div>
        {children}
      </div>
    </main>
  );
}

/** Étape 2 : code du second facteur (application d'authentification). */
function TotpStep() {
  const { verifyTotp, hasTotpHint, signOut } = useAuth();
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (busy || code.length !== CODE_LENGTH) return;
    setBusy(true);
    setError(undefined);
    try {
      await verifyTotp(code);
      // Succès : on reste occupé jusqu'à ce que le fournisseur d'authentification retire cet écran.
    } catch (e) {
      setError(e instanceof Error ? e.message : "Code refusé.");
      setCode("");
      setBusy(false);
    }
  };

  return (
    <Shell>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ShieldCheck className="size-5 text-primary" /> Vérification en deux étapes
          </CardTitle>
          <CardDescription>Saisissez le code à {CODE_LENGTH} chiffres affiché par votre application d&apos;authentification.</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4" onSubmit={submit}>
            {!hasTotpHint && (
              <Alert variant="destructive">
                Ce compte utilise un second facteur que le back-office ne prend pas en charge. Contactez l&apos;équipe technique.
              </Alert>
            )}
            {error && <Alert variant="destructive">{error}</Alert>}
            {hasTotpHint && (
              <div className="grid gap-2">
                <Label htmlFor="code">Code à {CODE_LENGTH} chiffres</Label>
                <Input
                  id="code"
                  autoFocus
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  value={code}
                  disabled={busy}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, CODE_LENGTH))}
                />
              </div>
            )}
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={signOut} disabled={busy}>
                Retour
              </Button>
              {hasTotpHint && (
                <Button type="submit" loading={busy} disabled={code.length !== CODE_LENGTH}>
                  Valider
                </Button>
              )}
            </div>
          </form>
        </CardContent>
      </Card>
    </Shell>
  );
}

export function LoginScreen() {
  const { status, message, signIn, resetPassword, signOut } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [resetState, setResetState] = useState<"idle" | "sending" | "sent">("idle");
  const [resetError, setResetError] = useState<string>();

  if (status === "mfa") return <TotpStep />;

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (busy || !email || !password) return;
    setBusy(true);
    setResetState("idle");
    setResetError(undefined);
    await signIn(email, password);
    setBusy(false);
  };

  const reset = async () => {
    if (!email) {
      setResetError("Saisissez votre adresse e-mail, puis cliquez sur « Mot de passe oublié ».");
      return;
    }
    setResetError(undefined);
    setResetState("sending");
    try {
      await resetPassword(email);
      setResetState("sent");
    } catch (e) {
      setResetError(e instanceof Error ? e.message : "Envoi impossible.");
      setResetState("idle");
    }
  };

  // Connecté mais refusé : on n'affiche pas le formulaire, seulement le motif et la déconnexion.
  if (status === "denied") {
    return (
      <Shell>
        <Card>
          <CardContent className="grid gap-4 pt-5">
            <Alert variant="destructive">{message}</Alert>
            <Button variant="outline" onClick={signOut}>
              Se déconnecter
            </Button>
          </CardContent>
        </Card>
      </Shell>
    );
  }

  return (
    <Shell>
      <Card>
        <CardHeader>
          <CardTitle>Connexion</CardTitle>
          <CardDescription>Accès réservé aux administrateurs.</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4" onSubmit={submit}>
            <div className="grid gap-2">
              <Label htmlFor="email">Adresse e-mail</Label>
              <Input id="email" type="email" autoComplete="username" autoFocus value={email} disabled={busy} onChange={(e) => setEmail(e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">Mot de passe</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                disabled={busy}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            {message && <Alert variant="destructive">{message}</Alert>}
            {resetError && <Alert variant="destructive">{resetError}</Alert>}
            {resetState === "sent" && (
              <Alert variant="success">
                Si un compte existe pour cette adresse, un e-mail de réinitialisation du mot de passe vient d&apos;être envoyé.
              </Alert>
            )}
            <div className="flex items-center justify-between gap-2">
              <Button type="button" variant="link" className="px-0" onClick={reset} disabled={busy || resetState === "sending"}>
                {resetState === "sending" ? "Envoi…" : "Mot de passe oublié"}
              </Button>
              <Button type="submit" loading={busy} disabled={!email || !password}>
                Se connecter
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </Shell>
  );
}
