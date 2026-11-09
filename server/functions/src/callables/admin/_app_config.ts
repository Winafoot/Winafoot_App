import { HttpsError } from "../../runtime/firebase";

type Kind = "email" | "phone" | "url" | "text" | "html";

interface FieldSpec {
  kind: Kind;
  /** Un champ obligatoire ne peut pas être vidé : l'app ou les e-mails cesseraient de fonctionner. */
  required?: boolean;
  max: number;
}

/**
 * Champs de `app_config/metadata` modifiables depuis le back-office. Tout autre champ (appHash, baseUrl,
 * maintenance, sécurité des mots de passe...) est refusé : il ne se change pas depuis une page web.
 */
export const EDITABLE_FIELDS: Record<string, FieldSpec> = {
  contactEmail: { kind: "email", required: true, max: 254 },
  salesEmail: { kind: "email", max: 254 },
  contactPhone: { kind: "phone", max: 30 },
  shareMessage: { kind: "text", max: 500 },
  instagramUrl: { kind: "url", max: 300 },
  tiktokUrl: { kind: "url", max: 300 },
  facebookUrl: { kind: "url", max: 300 },
  linkedinUrl: { kind: "url", max: 300 },
  youtubeUrl: { kind: "url", max: 300 },
  "mail.from": { kind: "email", required: true, max: 254 },
  "mail.replyTo": { kind: "email", max: 254 },
  "mail.fromName": { kind: "text", max: 80 },
  cgvu: { kind: "html", max: 200_000 },
  confidentialityPolicy: { kind: "html", max: 200_000 },
  legalNotice: { kind: "html", max: 200_000 },
  about: { kind: "html", max: 200_000 },
};

const EMAIL = /^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]{2,}$/;

function validate(key: string, spec: FieldSpec, value: string): void {
  const fail = (message: string): never => {
    throw new HttpsError("invalid-argument", `${key} : ${message}`);
  };
  if (value.length > spec.max) fail(`trop long (${spec.max} caractères au plus).`);
  if (spec.kind === "email" && !EMAIL.test(value)) fail("adresse e-mail invalide.");
  if (spec.kind === "phone" && !/^[+0-9 ().-]{6,30}$/.test(value)) fail("numéro invalide.");
  if (spec.kind === "url") {
    let protocol: string;
    try {
      protocol = new URL(value).protocol;
    } catch {
      return fail("adresse invalide.");
    }
    if (protocol !== "https:") fail("l'adresse doit commencer par https://.");
  }
}

export interface ConfigUpdate {
  /** Champs à écrire (clés pointées pour `mail.*`). */
  set: Record<string, string>;
  /** Champs à supprimer. */
  remove: string[];
}

/**
 * Valide les modifications demandées : champ connu, valeur du bon format, champ obligatoire non vidé. Une valeur
 * vide supprime un champ facultatif. Refuse tout en bloc à la première erreur : aucune écriture partielle.
 */
export function buildConfigUpdate(changes: unknown): ConfigUpdate {
  if (changes == null || typeof changes !== "object" || Array.isArray(changes)) throw new HttpsError("invalid-argument", "Modifications invalides.");
  const entries = Object.entries(changes as Record<string, unknown>);
  if (entries.length === 0) throw new HttpsError("invalid-argument", "Aucune modification.");

  const update: ConfigUpdate = { set: {}, remove: [] };
  for (const [key, raw] of entries) {
    const spec = Object.prototype.hasOwnProperty.call(EDITABLE_FIELDS, key) ? EDITABLE_FIELDS[key] : undefined;
    if (spec == null) throw new HttpsError("invalid-argument", `${key} : champ non modifiable depuis le back-office.`);
    if (typeof raw !== "string") throw new HttpsError("invalid-argument", `${key} : texte attendu.`);
    const value = spec.kind === "html" ? raw : raw.trim();
    if (value.trim() === "") {
      if (spec.required) throw new HttpsError("invalid-argument", `${key} : ce champ est obligatoire.`);
      update.remove.push(key);
      continue;
    }
    validate(key, spec, value);
    update.set[key] = value;
  }
  return update;
}
