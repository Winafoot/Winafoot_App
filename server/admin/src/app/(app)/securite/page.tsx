"use client";
import { useEffect, useState, type FormEvent } from "react";
import { multiFactor, TotpMultiFactorGenerator, type MultiFactorInfo, type TotpSecret } from "firebase/auth";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { getAuthErrorCode, getAuthErrorMessage } from "@/lib/auth-errors";
import { useAuth } from "@/lib/auth-provider";

const CODE_LENGTH = 6;
const FACTOR_NAME = "Application d'authentification";
// Sans espace ni accent : le SDK recopie tel quel l'émetteur dans l'URL otpauth.
const ISSUER = "Wina";

export default function SecurityPage() {
  const { user, signOut } = useAuth();
  // null = état pas encore connu.
  const [factors, setFactors] = useState<MultiFactorInfo[] | null>(null);
  const [secret, setSecret] = useState<TotpSecret | null>(null);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<unknown>();

  // Recharge le compte pour afficher l'état réel du second facteur. Hors ligne, on se contente de l'état du SDK.
  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    user
      .reload()
      .catch(() => undefined)
      .then(() => {
        if (!cancelled) setFactors([...multiFactor(user).enrolledFactors]);
      });
    return () => {
      cancelled = true;
    };
  }, [user]);

  const start = async () => {
    if (!user || busy) return;
    setBusy(true);
    setError(undefined);
    try {
      const session = await multiFactor(user).getSession();
      setSecret(await TotpMultiFactorGenerator.generateSecret(session));
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  };

  const confirm = async (event: FormEvent) => {
    event.preventDefault();
    if (!user || !secret || busy || code.length !== CODE_LENGTH) return;
    setBusy(true);
    setError(undefined);
    try {
      await multiFactor(user).enroll(TotpMultiFactorGenerator.assertionForEnrollment(secret, code), FACTOR_NAME);
      setFactors([...multiFactor(user).enrolledFactors]);
      setSecret(null);
      toast.success("Second facteur activé. Reconnectez-vous pour l'utiliser.");
    } catch (e) {
      setError(e);
      // Clé périmée : inutile de resaisir un code, il faut en générer une nouvelle.
      const errorCode = getAuthErrorCode(e);
      if (errorCode === "auth/code-expired" || errorCode === "auth/invalid-verification-id" || errorCode === "auth/missing-verification-id") {
        setSecret(null);
      }
    } finally {
      setCode("");
      setBusy(false);
    }
  };

  const needsRelogin = getAuthErrorCode(error) === "auth/requires-recent-login";

  return (
    <>
      <PageHeader
        title="Sécurité du compte"
        description={`Le second facteur complète votre mot de passe par un code à ${CODE_LENGTH} chiffres généré par une application d'authentification (Google Authenticator, Microsoft Authenticator, 1Password, Authy…).`}
      />
      <Card className="max-w-xl">
        <CardContent className="grid gap-4 pt-5">
          {error !== undefined && (
            <Alert variant="destructive" className="flex items-center justify-between gap-2">
              {getAuthErrorMessage(error)}
              {needsRelogin && (
                <Button variant="outline" size="sm" onClick={signOut}>
                  Se déconnecter
                </Button>
              )}
            </Alert>
          )}

          {factors === null && <Skeleton className="h-10 w-full" />}

          {factors !== null && factors.length > 0 && (
            <Alert variant="success">
              Second facteur activé : {factors.map((f) => f.displayName ?? f.factorId).join(", ")}. Un code vous sera demandé à chaque connexion.
            </Alert>
          )}

          {factors !== null && factors.length === 0 && !secret && (
            <>
              <Alert variant="warning">Aucun second facteur : votre compte n&apos;est protégé que par son mot de passe.</Alert>
              <Button onClick={start} loading={busy} disabled={!user}>
                Activer le second facteur
              </Button>
            </>
          )}

          {factors !== null && factors.length === 0 && secret && (
            <form className="grid gap-4" onSubmit={confirm}>
              <p className="text-sm">
                1. Dans votre application d&apos;authentification, ajoutez un compte en saisissant cette clé (type « basé sur l&apos;heure »). Aucun code QR n&apos;est
                affiché : la saisie de la clé suffit.
              </p>
              <code className="select-all break-all rounded-md bg-muted p-3 font-mono text-lg">{secret.secretKey}</code>
              <p className="text-sm text-muted-foreground">Si votre application accepte une adresse otpauth (gestionnaires de mots de passe notamment) :</p>
              <code className="select-all break-all rounded-md bg-muted p-3 font-mono text-xs">{secret.generateQrCodeUrl(user?.email ?? undefined, ISSUER)}</code>
              <p className="text-sm">2. Saisissez le code à {CODE_LENGTH} chiffres que l&apos;application affiche maintenant, pour confirmer.</p>
              <div className="grid gap-2">
                <Label htmlFor="totp-code">Code à {CODE_LENGTH} chiffres</Label>
                <Input
                  id="totp-code"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  value={code}
                  disabled={busy}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, CODE_LENGTH))}
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button
                  type="button"
                  variant="ghost"
                  onClick={() => {
                    setSecret(null);
                    setCode("");
                    setError(undefined);
                  }}
                  disabled={busy}
                >
                  Annuler
                </Button>
                <Button type="submit" loading={busy} disabled={code.length !== CODE_LENGTH}>
                  Confirmer
                </Button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </>
  );
}
