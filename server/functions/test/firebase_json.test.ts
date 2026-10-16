import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const config = JSON.parse(readFileSync(join(__dirname, "../../firebase.json"), "utf8"));

// Seul le code compilé (lib/) et ses dépendances partent avec les fonctions : ni les tests, ni les
// scripts d'administration, ni les fichiers locaux de l'émulateur (.secret.local, .env.local).
describe("firebase.json, functions", () => {
  it.each(["test", "scripts", "*.local", "node_modules"])("does not upload %s", (pattern) => {
    expect(config.functions[0].ignore).toContain(pattern);
  });

  it("builds the functions before deploying them", () => {
    expect(config.functions[0].predeploy).toEqual(['npm --prefix "$RESOURCE_DIR" run build']);
  });
});

// Back-office (site Hosting wina-admin) : jamais encadrable, pas de détection de type, référent réduit,
// et une CSP complète en mode rapport seulement, pour en relever les écarts sans rien bloquer.
describe("firebase.json, hosting of the back-office", () => {
  const headers: Record<string, string> = Object.fromEntries(
    config.hosting.headers.find((h: { source: string }) => h.source === "**").headers.map((h: { key: string; value: string }) => [h.key, h.value]),
  );

  it("forbids framing", () => {
    expect(headers["X-Frame-Options"]).toBe("DENY");
    expect(headers["Content-Security-Policy"]).toBe("frame-ancestors 'none'");
  });

  it("sets nosniff, the referrer policy and a minimal permissions policy", () => {
    expect(headers["X-Content-Type-Options"]).toBe("nosniff");
    expect(headers["Referrer-Policy"]).toBe("strict-origin-when-cross-origin");
    expect(headers["Permissions-Policy"]).toMatch(/camera=\(\).*microphone=\(\).*geolocation=\(\)/);
  });

  it("reports, without enforcing, a full policy that allows Firebase, the functions region and reCAPTCHA", () => {
    const csp = headers["Content-Security-Policy-Report-Only"];
    for (const origin of [
      "https://identitytoolkit.googleapis.com",
      "https://securetoken.googleapis.com",
      "https://firestore.googleapis.com",
      "https://content-firebaseappcheck.googleapis.com",
      "https://europe-west9-wina-c4c4a.cloudfunctions.net",
      "https://www.google.com/recaptcha/",
      "https://www.gstatic.com/recaptcha/",
    ]) {
      expect(csp).toContain(origin);
    }
    expect(csp).toContain("object-src 'none'");
    expect(csp).toContain("frame-ancestors 'none'");
  });

  it("publishes no source maps", () => {
    expect(readFileSync(join(__dirname, "../../cms/vite.config.ts"), "utf8")).toMatch(/sourcemap:\s*false/);
  });
});
