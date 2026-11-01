import { describe, expect, it } from "vitest";
import { DEFAULT_GRANT_DAYS, grantedSubscription, MAX_GRANT_DAYS, parseGrant, revokedSubscription } from "../../src/billing/admin_access";
import { computeAccess, parseProduct } from "../../src/billing/subscription";

const NOW = 1_800_000_000_000;
const DAY = 86_400_000;

describe("parseGrant", () => {
  it("prend 1 équipe et 30 jours quand rien n'est précisé", () => {
    expect(parseGrant(undefined)).toEqual({ teams: 1, days: DEFAULT_GRANT_DAYS });
    expect(parseGrant({})).toEqual({ teams: 1, days: DEFAULT_GRANT_DAYS });
    // Un champ vide d'un formulaire arrive en null : même chose qu'un champ absent.
    expect(parseGrant({ teams: null, days: null })).toEqual({ teams: 1, days: DEFAULT_GRANT_DAYS });
  });

  it("accepte les formules et durées valides", () => {
    expect(parseGrant({ teams: 3, days: MAX_GRANT_DAYS })).toEqual({ teams: 3, days: MAX_GRANT_DAYS });
    expect(parseGrant({ teams: 2, days: 1 })).toEqual({ teams: 2, days: 1 });
  });

  it.each([0, 4, -1, 1.5, "2", NaN])("refuse %j équipes", (teams) => {
    expect(() => parseGrant({ teams })).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
  });

  it.each([0, -5, MAX_GRANT_DAYS + 1, 2.5, "30", NaN, Infinity])("refuse %j jours", (days) => {
    expect(() => parseGrant({ days })).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
  });
});

describe("grantedSubscription", () => {
  it.each([1, 2, 3] as const)("donne un accès valide jusqu'à la date voulue pour %i équipe(s)", (teams) => {
    const sub = grantedSubscription({ teams, days: 15 }, NOW);

    expect(computeAccess(sub, 1, NOW)).toEqual({ active: true, untilMs: NOW + 15 * DAY });
    // Le mur de paiement et les équipes liées lisent la même formule que pour un achat réel.
    expect(parseProduct(sub.productId)).toEqual({ teamsAllowed: teams, period: "monthly" });
    expect(computeAccess(sub, teams, NOW).active).toBe(true);
    expect(computeAccess(sub, teams + 1, NOW).active).toBe(false);
  });

  it("n'est plus actif une fois la durée écoulée", () => {
    const sub = grantedSubscription({ teams: 1, days: 1 }, NOW);

    expect(computeAccess(sub, 1, NOW + DAY).active).toBe(false);
  });

});

describe("revokedSubscription", () => {
  it("coupe l'accès tout de suite, comptes liés compris", () => {
    const granted = grantedSubscription({ teams: 3, days: 30 }, NOW);
    const revoked = revokedSubscription(granted, NOW + 5 * DAY);

    expect(computeAccess(revoked, 1, NOW + 5 * DAY).active).toBe(false);
    expect(computeAccess(revoked, 3, NOW + 5 * DAY).active).toBe(false);
    expect(revoked.status).toBe("expired");
  });

  it("garde l'horodatage le plus récent, pour qu'un ancien événement RevenueCat ne le rétablisse pas", () => {
    const revoked = revokedSubscription(grantedSubscription({ teams: 1, days: 30 }, NOW), NOW + DAY);

    expect(revoked.lastEventMs).toBe(NOW + DAY);
  });
});
