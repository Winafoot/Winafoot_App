import { describe, expect, it } from "vitest";
import { newSubscriptionKind, priceLabel } from "../../src/billing/billing_mail";
import { generateTemplateNewSubscriptionNotice, newSubscriptionNoticeText, type NewSubscriptionNoticeData } from "../../src/template/email_subscription";

describe("newSubscriptionKind", () => {
  it("tells a regular payment from a trial and from an introductory offer or code", () => {
    expect(newSubscriptionKind({ period_type: "NORMAL" })).toBe("Paiement au tarif normal");
    expect(newSubscriptionKind({ period_type: "TRIAL" })).toBe("Essai ou offre gratuite");
    expect(newSubscriptionKind({ period_type: "INTRO" })).toBe("Offre d'introduction ou code promo");
    expect(newSubscriptionKind({ period_type: "NORMAL", offer_code: "WINA10" })).toBe("Offre d'introduction ou code promo");
  });
});

describe("priceLabel", () => {
  it("formats the amount with a comma and its currency", () => {
    expect(priceLabel({ price_in_purchased_currency: 17, currency: "EUR" })).toBe("17,00 EUR");
  });

  it("shows a dash when RevenueCat sends no amount", () => {
    expect(priceLabel({})).toBe("—");
  });
});

describe("new subscription notice", () => {
  const data: NewSubscriptionNoticeData = {
    appName: "Wina",
    team: "FC <Test>",
    coachEmail: "coach@club.fr",
    formula: "2 équipes · mensuelle",
    storeName: "l’App Store",
    kind: "Offre d'introduction ou code promo",
    offerCode: "WINA10",
    price: "17,00 EUR",
    dateLabel: "28 octobre 2026",
  };

  it("lists the subscription details and escapes the team name", () => {
    const html = generateTemplateNewSubscriptionNotice(data);
    expect(html).toContain("Nouvel abonnement");
    expect(html).toContain("coach@club.fr");
    expect(html).toContain("WINA10");
    expect(html).toContain("FC &lt;Test&gt;");
    expect(html).not.toContain("FC <Test>");
  });

  it("omits the code line when no code was used", () => {
    expect(newSubscriptionNoticeText({ ...data, offerCode: undefined })).not.toContain("Code :");
    expect(newSubscriptionNoticeText(data)).toContain("Code : WINA10");
  });
});
