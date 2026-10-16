import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { describe, expect, it } from "vitest";
import { describeError } from "../src/utils/describe_error";

const SRC = join(__dirname, "../src");
const files = (dir: string): string[] =>
  readdirSync(dir).flatMap((n) => (statSync(join(dir, n)).isDirectory() ? files(join(dir, n)) : n.endsWith(".ts") ? [join(dir, n)] : []));

// Un objet d'erreur journalisé tel quel peut emporter la requête (en-tête Authorization, corps) :
// les journaux ne portent que son motif (describeError).
describe("logs", () => {
  it("never receive a raw error object", () => {
    const offenders = files(SRC).flatMap((file) =>
      [...readFileSync(file, "utf8").matchAll(/logger\.\w+\([^;]*?,\s*(?:e|err|error|result\.error)\s*\)/g)].map((m) => `${relative(SRC, file)} : ${m[0]}`),
    );
    expect(offenders).toEqual([]);
  });
});

describe("describeError", () => {
  it("keeps the code and the message of an error", () => {
    expect(describeError(Object.assign(new Error("There is no user record"), { code: "auth/user-not-found" }))).toBe("auth/user-not-found : There is no user record");
  });

  it("reads the reason of a MailerSend API rejection", () => {
    expect(describeError({ statusCode: 422, body: { message: "domain must be verified" }, headers: { authorization: "Bearer x" } })).toBe("422 : domain must be verified");
  });

  it("never serialises the error object itself", () => {
    const error = Object.assign(new Error("connect ECONNREFUSED"), { config: { headers: { Authorization: "Bearer SECRET" } } });
    expect(describeError(error)).not.toContain("SECRET");
    expect(describeError({ config: { headers: { Authorization: "Bearer SECRET" } } })).toBe("erreur inconnue");
  });

  it("passes a plain string through", () => {
    expect(describeError("app_config/metadata introuvable")).toBe("app_config/metadata introuvable");
  });
});
