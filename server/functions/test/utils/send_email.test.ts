import { describe, expect, it, vi } from "vitest";
import { inspect } from "node:util";

// Le SDK Resend ne lève pas sur un refus de l'API : il renvoie `{ data, error }`. Une erreur
// réseau, elle, peut embarquer la requête (en-tête Authorization compris) : journaliser cet
// objet écrivait la clé API en clair dans Cloud Logging.
const send = vi.hoisted(() => vi.fn());

vi.mock("resend", () => {
  class Resend {
    emails = { send };
  }
  return { Resend };
});

import { sendEmail } from "../../src/utils/send_email";

const CONFIG: any = { appName: "Wina", mail: { from: "noreply@wina.test", fromName: "Wina", replyTo: "support@wina.test" } };

describe("sendEmail", () => {
  it("sends through Resend with the configured sender and returns the message id", async () => {
    send.mockResolvedValueOnce({ data: { id: "msg_1" }, error: null });

    const id = await sendEmail(CONFIG, { email: "a@club.test" } as any, "<p>x</p>", "Sujet", "texte");

    expect(id).toBe("msg_1");
    expect(send).toHaveBeenCalledWith({
      from: "Wina <noreply@wina.test>",
      to: ["a@club.test"],
      replyTo: "support@wina.test",
      subject: "Wina - Sujet",
      html: "<p>x</p>",
      text: "texte",
    });
  });

  it("rethrows a network error without the request (API key, token) attached", async () => {
    send.mockRejectedValueOnce(
      Object.assign(new Error("connect ECONNREFUSED 127.0.0.1:1"), {
        code: "ECONNREFUSED",
        config: { headers: { Authorization: "Bearer SECRET-RESEND-KEY" }, data: "token=abc123" },
      }),
    );
    const error = await sendEmail(CONFIG, { email: "a@club.test" } as any, "<p>x</p>", "Sujet").catch((e) => e);

    expect(error).toBeInstanceOf(Error);
    expect(error.message).toMatch(/ECONNREFUSED/);
    const dumped = inspect(error, { depth: 8 });
    expect(dumped).not.toContain("SECRET-RESEND-KEY");
    expect(dumped).not.toContain("abc123");
  });

  it("keeps the status and the reason given by the Resend API", async () => {
    send.mockResolvedValueOnce({
      data: null,
      error: { statusCode: 403, name: "validation_error", message: "The wina.test domain is not verified." },
    });

    const error = await sendEmail(CONFIG, { email: "a@club.test" } as any, "<p>x</p>", "Sujet").catch((e) => e);

    expect(error.message).toBe("Resend : 403 : The wina.test domain is not verified.");
  });

  it("refuses to send without a sender address rather than borrowing one", async () => {
    send.mockClear();

    await expect(sendEmail({ appName: "Wina", mail: {} } as any, { email: "a@club.test" } as any, "<p>x</p>")).rejects.toThrow(/mail\.from/);
    expect(send).not.toHaveBeenCalled();
  });
});
