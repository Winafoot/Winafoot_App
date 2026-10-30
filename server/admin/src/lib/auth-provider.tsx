"use client";
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  getMultiFactorResolver,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  TotpMultiFactorGenerator,
  type MultiFactorResolver,
  type User,
} from "firebase/auth";
import { auth } from "./firebase";
import { getAuthErrorCode, getAuthErrorMessage } from "./auth-errors";

export type AuthStatus =
  | "loading"
  | "signedOut"
  /** Mot de passe accepté, code du second facteur attendu. */
  | "mfa"
  /** Connecté mais pas administrateur (ou adresse non vérifiée) : `denied` dit pourquoi. */
  | "denied"
  | "ready";

interface AuthContextValue {
  status: AuthStatus;
  user: User | null;
  /** Motif du refus d'accès, ou erreur de la dernière tentative de connexion. */
  message: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  /** Valide le code du second facteur ; lève une erreur (déjà en français) si le code est refusé. */
  verifyTotp: (code: string) => Promise<void>;
  /** Le compte peut-il enchaîner sur un second facteur TOTP ? Faux si seul un autre type est inscrit. */
  hasTotpHint: boolean;
  resetPassword: (email: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (value == null) throw new Error("useAuth doit être utilisé sous AuthProvider.");
  return value;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>("loading");
  const [user, setUser] = useState<User | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [resolver, setResolver] = useState<MultiFactorResolver | null>(null);

  useEffect(() => {
    return onAuthStateChanged(auth(), async (next) => {
      if (next == null) {
        setUser(null);
        // Un second facteur en attente garde son écran : le compte n'est pas encore connecté.
        setStatus((current) => (current === "mfa" ? current : "signedOut"));
        return;
      }
      setStatus("loading");
      try {
        // `true` force le rafraîchissement du jeton : un claim fraîchement attribué compte sans attendre une heure.
        const token = await next.getIdTokenResult(true);
        if (token.claims.admin !== true) {
          setMessage("Accès réservé aux administrateurs Wina.");
          setUser(next);
          setStatus("denied");
          return;
        }
        if (token.claims.email_verified !== true) {
          setMessage(
            "Adresse e-mail non vérifiée : utilisez le lien reçu par e-mail pour définir votre mot de passe, puis reconnectez-vous.",
          );
          setUser(next);
          setStatus("denied");
          return;
        }
        setMessage(null);
        setResolver(null);
        setUser(next);
        setStatus("ready");
      } catch (e) {
        setMessage(getAuthErrorMessage(e));
        setUser(next);
        setStatus("denied");
      }
    });
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    setMessage(null);
    try {
      await signInWithEmailAndPassword(auth(), email.trim(), password);
    } catch (e) {
      if (getAuthErrorCode(e) === "auth/multi-factor-auth-required") {
        setResolver(getMultiFactorResolver(auth(), e as Parameters<typeof getMultiFactorResolver>[1]));
        setStatus("mfa");
        return;
      }
      setMessage(getAuthErrorMessage(e));
    }
  }, []);

  const totpHint = resolver?.hints.find((h) => h.factorId === TotpMultiFactorGenerator.FACTOR_ID);

  const verifyTotp = useCallback(
    async (code: string) => {
      if (resolver == null || totpHint == null) throw new Error("La session de connexion a expiré. Recommencez la connexion.");
      try {
        await resolver.resolveSignIn(TotpMultiFactorGenerator.assertionForSignIn(totpHint.uid, code));
      } catch (e) {
        throw new Error(getAuthErrorMessage(e));
      }
    },
    [resolver, totpHint],
  );

  const resetPassword = useCallback(async (email: string) => {
    auth().languageCode = "fr";
    try {
      await sendPasswordResetEmail(auth(), email.trim());
    } catch (e) {
      throw new Error(getAuthErrorMessage(e));
    }
  }, []);

  const signOut = useCallback(async () => {
    setResolver(null);
    setMessage(null);
    setStatus("signedOut");
    await firebaseSignOut(auth());
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ status, user, message, signIn, verifyTotp, hasTotpHint: totpHint != null, resetPassword, signOut }),
    [status, user, message, signIn, verifyTotp, totpHint, resetPassword, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
