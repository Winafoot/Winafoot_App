import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it, vi } from "vitest";
import { installThirdPartyGuard, type FetchTarget } from "../../../cms/src/third_party_guard";

// Le back-office n'envoie aucune donnée à des services tiers de journalisation : toute requête vers
// firecms.co reçoit une réponse locale, les autres partent sans changement.
const CMS = join(__dirname, "../../../cms");
const BASE = "https://wina-admin.web.app/creer-coach";

function guardedTarget(): { target: FetchTarget; network: ReturnType<typeof vi.fn> } {
  const network = vi.fn(async () => new Response("réseau", { status: 200 }));
  const target: FetchTarget = { fetch: network as unknown as typeof fetch, location: { href: BASE } };
  installThirdPartyGuard(target);
  return { target, network };
}

describe("back-office, third-party guard", () => {
  it("answers FireCMS's access log locally: the identity token and the e-mail never reach the network", async () => {
    const { target, network } = guardedTarget();

    // Appel tel que l'écrit @firecms/core (useProjectLog).
    const res = await target.fetch("https://api.firecms.co/access_log", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Basic jeton-d-identite" },
      body: JSON.stringify({ email: "admin@club.test", datasource: "firestore", plugins: [] }),
    });

    expect(network).not.toHaveBeenCalled();
    expect(res.status).toBe(200);
    // FireCMS n'affiche son écran de licence que sur `blocked`, et ne journalise que `message`.
    const body = await res.json();
    expect(body).toEqual({});
    expect(body.blocked).toBeUndefined();
    expect(body.message).toBeUndefined();
  });

  it.each([
    ["an URL object", () => new URL("https://api.firecms.co/access_log")],
    ["a Request object", () => new Request("https://api.firecms.co/access_log", { method: "POST" })],
    ["an upper-case host", () => "https://API.FIRECMS.CO/access_log"],
    ["a fully qualified host", () => "https://api.firecms.co./access_log"],
    ["an explicit port", () => "https://api.firecms.co:443/access_log"],
    ["a protocol-relative URL", () => "//api.firecms.co/access_log"],
    ["another subdomain", () => "https://cdn.firecms.co/x.js"],
    ["the domain itself", () => "http://firecms.co/"],
  ])("blocks %s", async (_label, input) => {
    const { target, network } = guardedTarget();
    expect(await (await target.fetch(input())).json()).toEqual({});
    expect(network).not.toHaveBeenCalled();
  });

  it.each([
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
    "https://europe-west9-wina-c4c4a.cloudfunctions.net/createCoach",
    "/assets/index.js",
    "https://firecms.co.example.test/",
    "https://notfirecms.co/",
  ])("lets %s through unchanged", async (url) => {
    const { target, network } = guardedTarget();
    const init = { method: "POST" };
    expect(await (await target.fetch(url, init)).text()).toBe("réseau");
    expect(network).toHaveBeenCalledTimes(1);
    expect(network).toHaveBeenCalledWith(url, init);
  });

  it("calls the original fetch with the target as `this` (window.fetch requires it)", async () => {
    const target = {
      location: { href: BASE },
      fetch: function (this: unknown) {
        return Promise.resolve(new Response(this === target ? "ok" : "mauvais this"));
      },
    } as unknown as FetchTarget;
    installThirdPartyGuard(target);
    expect(await (await target.fetch("https://firestore.googleapis.com/")).text()).toBe("ok");
  });

  it("is installed in main.tsx, on window, before the first render", () => {
    const main = readFileSync(join(CMS, "src/main.tsx"), "utf8");
    const install = main.indexOf("installThirdPartyGuard(window);");
    expect(install).toBeGreaterThan(-1);
    expect(install).toBeLessThan(main.indexOf("ReactDOM.createRoot("));
  });

  // FireCMS installé : son seul accès au réseau est `fetch`, que le garde couvre. Une mise à jour qui
  // passerait par un autre moyen fait échouer ce test.
  const firecms = ["core", "firebase", "ui"].map((p) => [p, join(CMS, `node_modules/@firecms/${p}/dist/index.es.js`)] as const);
  describe.skipIf(!firecms.every(([, file]) => existsSync(file)))("installed FireCMS (needs npm ci in cms/)", () => {
    it.each(firecms)("@firecms/%s reaches the network only through fetch", (_p, file) => {
      const code = readFileSync(file, "utf8");
      for (const other of [/XMLHttpRequest/, /sendBeacon/, /new WebSocket/, /EventSource/]) {
        expect(code).not.toMatch(other);
      }
      // Seule URL d'API de firecms.co : la constante DEFAULT_SERVER, passée à fetch.
      expect([...code.matchAll(/https?:\/\/[a-z0-9.-]*firecms\.co\b/gi)].map((m) => m[0])).toEqual(
        code.includes("api.firecms.co") ? ["https://api.firecms.co"] : [],
      );
    });

    it("@firecms/core sends its access log with the global fetch", () => {
      const code = readFileSync(firecms[0][1], "utf8");
      expect(code).toMatch(/return fetch\(DEFAULT_SERVER \+ "\/access_log"/);
    });
  });

  it("is backed by the site's content security policy, which never allows firecms.co", () => {
    const config = JSON.parse(readFileSync(join(__dirname, "../../../firebase.json"), "utf8"));
    const headers = config.hosting.headers.flatMap((h: { headers: { key: string; value: string }[] }) => h.headers);
    const csp = headers.find((h: { key: string }) => h.key === "Content-Security-Policy-Report-Only").value as string;
    const connectSrc = csp.split(";").map((d) => d.trim()).find((d) => d.startsWith("connect-src "));
    expect(connectSrc).toBeDefined();
    expect(connectSrc).not.toMatch(/firecms/i);
    expect(connectSrc).not.toMatch(/(^| )(\*|https:)( |$)/);
    expect(JSON.stringify(headers)).not.toMatch(/firecms/i);
  });
});
