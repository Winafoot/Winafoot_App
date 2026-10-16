import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
// Câblage ACTIF : les fonctions Algolia lient leurs secrets (l'état inerte est couvert par algolia_inert_wiring.test.ts).
vi.mock("../src/config/algolia", async (importActual) => ({ ...(await importActual<typeof import("../src/config/algolia")>()), ALGOLIA_ENABLED: true }));

import * as callables from "../src/callables/index";
import * as httpRequests from "../src/https_requests/index";
import * as triggers from "../src/triggers/index";
import { MAILER_API_KEY, readSecret } from "../src/config/secrets";

const SRC = resolve(__dirname, "../src");
const INDEXES = ["callables/index.ts", "https_requests/index.ts", "triggers/index.ts"];
const INDEX_FILES = new Set(["index.ts", ...INDEXES].map((f) => join(SRC, f)));
const EXPORTS: Record<string, Record<string, any>> = {
  "callables/index.ts": callables,
  "https_requests/index.ts": httpRequests,
  "triggers/index.ts": triggers,
};

/** Code sans commentaires : ni import ni lecture commentés ne comptent. */
function code(file: string): string {
  return readFileSync(file, "utf8").replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
}

function resolveModule(path: string): string | undefined {
  return [`${path}.ts`, join(path, "index.ts")].find((c) => existsSync(c) && statSync(c).isFile());
}

/** Secrets déclarés dans config/secrets.ts : nom de la constante -> nom du secret. */
const SECRET_CONSTANTS = new Map(
  [...code(join(SRC, "config/secrets.ts")).matchAll(/export const (\w+) = defineSecret\("([A-Z0-9_]+)"\)/g)].map((m) => [m[1], m[2]]),
);

/** Modules importés par un fichier (imports statiques, de bord, require et import() relatifs), index exclus. */
function imports(file: string): string[] {
  const out: string[] = [];
  for (const m of code(file).matchAll(/(?:from\s+|import\s*\(?\s*|require\(\s*)["'](\.[^"']+)["']/g)) {
    const module = resolveModule(resolve(dirname(file), m[1]));
    if (module != null && !INDEX_FILES.has(module)) out.push(module);
  }
  return out;
}

/** Secrets lus par un module : CONSTANTE.value(), readSecret(CONSTANTE), process.env.NOM. */
function secretsRead(file: string): string[] {
  const txt = code(file);
  const read: string[] = [];
  for (const m of txt.matchAll(/\b([A-Z][A-Z0-9_]*)\.value\(\)|readSecret\(\s*([A-Z][A-Z0-9_]*)\s*\)/g)) {
    const name = SECRET_CONSTANTS.get(m[1] ?? m[2]);
    if (name != null) read.push(name);
  }
  const names = new Set(SECRET_CONSTANTS.values());
  for (const m of txt.matchAll(/process\.env(?:\.([A-Z0-9_]+)|\[\s*["']([A-Z0-9_]+)["']\s*\])/g)) {
    const name = m[1] ?? m[2];
    if (names.has(name)) read.push(name);
  }
  return read;
}

interface ExportedFunction {
  name: string;
  declared: string[];
  entries: string[];
}

/**
 * Fonctions exportées par les index, avec leurs secrets déclarés (manifeste de déploiement) et leurs
 * modules d'entrée : chemins passés aux adaptateurs, et modules importés par l'index que leur
 * définition utilise (handler importé directement).
 */
function exportedFunctions(): ExportedFunction[] {
  return INDEXES.flatMap((index) => {
    const file = join(SRC, index);
    const txt = code(file);
    const importedFrom = new Map<string, string>();
    for (const m of txt.matchAll(/import\s*\{([^}]*)\}\s*from\s*["'](\.[^"']+)["']/g)) {
      const module = resolveModule(resolve(dirname(file), m[2]));
      if (module == null) continue;
      for (const name of m[1].split(",").map((n) => n.replace(/\btype\b/, "").trim()).filter(Boolean)) importedFrom.set(name, module);
    }

    return txt
      .split(/(?=^export const )/m)
      .filter((block) => block.startsWith("export const "))
      .map((block) => {
        const name = /^export const (\w+)/.exec(block)![1];
        const adapters = [...block.matchAll(/Adapter(?:<[^>]*>)?\(\s*"([^"]+)"/g)].map((m) => resolveModule(join(SRC, m[1]))!);
        const direct = [...importedFrom].filter(([identifier]) => new RegExp(`\\b${identifier}\\b`).test(block)).map(([, module]) => module);
        const endpoint = EXPORTS[index][name].__endpoint;
        const declared = (endpoint.secretEnvironmentVariables ?? []).map((s: { key: string }) => s.key).sort();
        return { name, declared, entries: [...adapters, ...direct] };
      });
  });
}

function secretsReadBy(fn: ExportedFunction): string[] {
  const seen = new Set<string>();
  const stack = [...fn.entries];
  while (stack.length > 0) {
    const file = stack.pop()!;
    if (seen.has(file)) continue;
    seen.add(file);
    stack.push(...imports(file));
  }
  return [...new Set([...seen].flatMap(secretsRead))].sort();
}

describe("secrets declared by each exported function", () => {
  const functions = exportedFunctions();

  it("sees every exported function", () => {
    expect(functions.map((f) => f.name).sort()).toEqual(
      [...Object.keys(callables), ...Object.keys(httpRequests), ...Object.keys(triggers)].sort(),
    );
  });

  // Un secret lu mais non déclaré est absent à l'exécution ; un secret déclaré mais jamais lu élargit
  // sans raison ce que la fonction peut lire, et bloque son déploiement s'il n'existe pas.
  it("every function declares exactly the secrets its code reads", () => {
    const mismatches = functions
      .map((fn) => ({ name: fn.name, declared: fn.declared, read: secretsReadBy(fn) }))
      .filter((fn) => JSON.stringify(fn.declared) !== JSON.stringify(fn.read))
      .map((fn) => `${fn.name} : déclarés [${fn.declared.join(", ")}], lus [${fn.read.join(", ")}]`);

    expect(mismatches).toEqual([]);
  });

  it("every secret defined in config/secrets.ts is used by at least one function", () => {
    const used = new Set(functions.flatMap((fn) => fn.declared));
    expect([...SECRET_CONSTANTS.values()].filter((name) => !used.has(name))).toEqual([]);
  });

  it("knows which functions send e-mails", () => {
    const mailers = functions.filter((fn) => fn.declared.includes("MAILER_API_KEY")).map((fn) => fn.name).sort();
    expect(mailers).toEqual([
      "createAdmin",
      "onCreateReport",
      "onCreateUser",
      "onSendLandingPageMail",
      "onSendLandingPageMailDeleteAccount",
      "resendInvite",
      "sendEmailVerification",
      "sendResetPassword",
      "updateAdmin",
    ]);
  });

  it("no longer reads functions.config(), shut down in March 2027", () => {
    const files = (dir: string): string[] =>
      readdirSync(dir).flatMap((n) => (statSync(join(dir, n)).isDirectory() ? files(join(dir, n)) : n.endsWith(".ts") ? [join(dir, n)] : []));
    expect(files(SRC).filter((f) => /\bfunctions\.config\(\)/.test(code(f)))).toEqual([]);
  });
});

describe("readSecret", () => {
  const saved = process.env.MAILER_API_KEY;
  afterEach(() => {
    process.env.MAILER_API_KEY = saved;
  });

  it("returns the value without surrounding spaces", () => {
    process.env.MAILER_API_KEY = "  valeur \n";
    expect(readSecret(MAILER_API_KEY)).toBe("valeur");
  });

  it("returns undefined for a blank or missing secret", () => {
    process.env.MAILER_API_KEY = "   ";
    expect(readSecret(MAILER_API_KEY)).toBeUndefined();
    delete process.env.MAILER_API_KEY;
    expect(readSecret(MAILER_API_KEY)).toBeUndefined();
  });
});
