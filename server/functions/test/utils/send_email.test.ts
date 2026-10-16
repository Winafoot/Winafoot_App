import { describe, expect, it, vi } from "vitest";
import { inspect } from "node:util";

// Le client HTTP de mailer-send-ts (gaxios) attache la requête complète, en-tête
// Authorization compris, à toute erreur réseau. Journaliser cet objet écrivait la
// clé API en clair dans Cloud Logging.
const send = vi.hoisted(() => vi.fn());

vi.mock("mailer-send-ts", () => {
  class Chain {
    setFrom() { return this; }
    setTo() { return this; }
    setReplyTo() { return this; }
    setSubject() { return this; }
    setHtml() { return this; }
    setText() { return this; }
  }
  class MailerSend {
    email = { send };
  }
  return { MailerSend, EmailParams: Chain, Sender: class {}, Recipient: class {} };
});

import { sendEmail } from "../../src/utils/send_email";

const CONFIG: any = { appName: "Wina", mail: { from: "noreply@wina.test", fromName: "Wina", replyTo: "support@wina.test" } };

describe("sendEmail", () => {
  it("rethrows a network error without the request (API key, token) attached", async () => {
    send.mockRejectedValueOnce(
      Object.assign(new Error("connect ECONNREFUSED 127.0.0.1:1"), {
        code: "ECONNREFUSED",
        config: { headers: { Authorization: "Bearer SECRET-MAILER-KEY" }, data: "token=abc123" },
      }),
    );
    const error = await sendEmail(CONFIG, { email: "a@club.test" } as any, "<p>x</p>", "Sujet").catch((e) => e);

    expect(error).toBeInstanceOf(Error);
    expect(error.message).toMatch(/ECONNREFUSED/);
    const dumped = inspect(error, { depth: 8 });
    expect(dumped).not.toContain("SECRET-MAILER-KEY");
    expect(dumped).not.toContain("abc123");
  });

  // Le SDK rejette avec la réponse de l'API, sans `message` : le motif est dans `body.message`.
  it("keeps the status and the reason given by the MailerSend API", async () => {
    send.mockRejectedValueOnce({
      statusCode: 422,
      headers: { authorization: "Bearer SECRET-MAILER-KEY" },
      body: { message: "The from.email domain must be verified in your account to send emails. #MS42207", errors: { to: ["a@club.test"] } },
    });

    const error = await sendEmail(CONFIG, { email: "a@club.test" } as any, "<p>x</p>", "Sujet").catch((e) => e);

    expect(error.message).toBe("MailerSend : 422 : The from.email domain must be verified in your account to send emails. #MS42207");
    expect(inspect(error, { depth: 8 })).not.toContain("SECRET-MAILER-KEY");
  });

  it("refuses to send without a sender address rather than borrowing one", async () => {
    send.mockClear();

    await expect(sendEmail({ appName: "Wina", mail: {} } as any, { email: "a@club.test" } as any, "<p>x</p>")).rejects.toThrow(/mail\.from/);
    expect(send).not.toHaveBeenCalled();
  });
});
