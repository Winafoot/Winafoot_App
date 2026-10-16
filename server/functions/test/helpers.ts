import { auth, firestore } from "firebase-admin";

/** app_config/metadata minimal — sendWelcomeEmail et sendCoachInvite le lisent. */
export async function seedAppConfig(overrides: Record<string, unknown> = {}): Promise<void> {
  await firestore().collection("app_config").doc("metadata").set({
    appName: "Wina",
    contactEmail: "support@wina.test",
    mail: { from: "noreply@wina.test", fromName: "Wina", replyTo: "support@wina.test" },
    ...overrides,
  });
}

export interface SeedCoachOptions {
  firstname?: string;
  lastInviteSentAt?: firestore.Timestamp | null;
  disabled?: boolean;
}

/** Crée un compte Auth + son document users/{uid}. Renvoie l'uid. */
export async function seedCoach(email: string, options: SeedCoachOptions = {}): Promise<string> {
  const record = await auth().createUser({ email });
  await firestore().collection("users").doc(record.uid).set({
    id: record.uid,
    email,
    firstname: options.firstname ?? "Ibrahim",
    lastInviteSentAt: options.lastInviteSentAt ?? null,
    disabled: options.disabled ?? false,
  });
  return record.uid;
}

export interface SeedAdminOptions {
  disabled?: boolean;
  displayName?: string;
  /** Inscrit un second facteur (téléphone : le seul que l'Admin SDK sache créer). */
  secondFactor?: boolean;
}

/** Crée un compte Auth portant le claim `admin` (aucune fiche Firestore : Auth fait foi). Renvoie l'uid. */
export async function seedAdmin(email: string, options: SeedAdminOptions = {}): Promise<string> {
  const record = await auth().createUser({
    email,
    emailVerified: true,
    disabled: options.disabled ?? false,
    displayName: options.displayName,
    ...(options.secondFactor
      ? { multiFactor: { enrolledFactors: [{ factorId: "phone", phoneNumber: "+33600000000", displayName: "Téléphone" }] } }
      : {}),
  } as any);
  await auth().setCustomUserClaims(record.uid, { admin: true });
  return record.uid;
}

/** Requête minimale pour appeler un handler HTTP directement (méthode, corps, en-tête Origin). */
export function fakeReq(method: string, body: unknown, origin?: string, ip?: string): any {
  const headers: Record<string, string | undefined> = {
    origin,
    // Google AJOUTE l'IP réelle à la fin ; ce qui précède vient du client et ne vaut rien.
    "x-forwarded-for": ip ? `203.0.113.7, ${ip}` : undefined,
  };
  return { method, body, headers, get: (name: string) => headers[name.toLowerCase()] };
}

/** Réponse minimale : status / set / send, avec ce qui a été écrit exposé pour les assertions. */
export function fakeRes(): any {
  const res: any = {
    statusCode: 200,
    headers: {} as Record<string, string>,
    body: undefined as unknown,
    headersSent: false,
    status(code: number) {
      res.statusCode = code;
      return res;
    },
    set(name: string, value: string) {
      res.headers[name.toLowerCase()] = value;
      return res;
    },
    send(body?: unknown) {
      res.body = body;
      res.headersSent = true;
      return res;
    },
  };
  return res;
}

/**
 * Identité d'un appelant connecté telle que la transmet l'adaptateur authentifié : vrai jeton
 * d'identité émis par l'émulateur Auth (pour exercer verifyIdToken et sa révocation), et ses claims.
 */
export async function signedInCaller(uid: string): Promise<{ uid: string; token: Record<string, unknown>; rawToken: string }> {
  const custom = await auth().createCustomToken(uid);
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ token: custom, returnSecureToken: true }) },
  );
  const rawToken: string = ((await res.json()) as { idToken: string }).idToken;
  const token = (await auth().verifyIdToken(rawToken)) as unknown as Record<string, unknown>;
  return { uid, token, rawToken };
}
