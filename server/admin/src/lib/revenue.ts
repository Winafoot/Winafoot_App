import type { Coach } from "./data";

type Teams = 1 | 2 | 3;
type Period = "monthly" | "yearly";

/**
 * Grille de prix publique (TTC, en euros), celle des CGU et de la landing (`LAnding_Page/lib/offers.ts`). Les
 * stores restent la source de vérité : à mettre à jour ici quand un prix change.
 */
export const PLAN_PRICES: Record<Teams, { name: string; monthly: number; yearly: number }> = {
  1: { name: "Solo", monthly: 19.99, yearly: 199.99 },
  2: { name: "Duo", monthly: 29.99, yearly: 304.99 },
  3: { name: "Club", monthly: 43.99, yearly: 444.99 },
};

export interface RevenueLine {
  teams: Teams;
  name: string;
  period: Period;
  subscribers: number;
  /** Revenu mensuel de la ligne : le prix mensuel, ou le prix annuel divisé par 12. */
  monthlyRevenue: number;
}

export interface Revenue {
  lines: RevenueLine[];
  /** Abonnés payants (actifs ou en délai de grâce), abonnements offerts exclus. */
  subscribers: number;
  /** Revenu mensuel estimé, TTC, avant commission des stores. */
  monthly: number;
  /** Abonnements offerts depuis le back-office : sans revenu, donc exclus du calcul. */
  offered: number;
  /** Abonnés dont le premier achat a utilisé une offre ou un code : leur premier mois est peut-être réduit. */
  withOffer: number;
}

const round2 = (n: number) => Math.round(n * 100) / 100;

/**
 * Abonnés et revenu mensuel estimé à partir des comptes coach (les équipes liées n'ont pas d'abonnement propre).
 * Un abonnement `active` ou `grace` compte comme payant ; `trial`, `expired` et `refunded` ne rapportent rien.
 * Tous les abonnés sont valorisés au prix catalogue : une remise d'introduction ou un code n'est pas déduit.
 */
export function computeRevenue(coaches: Coach[]): Revenue {
  const lines: RevenueLine[] = ([1, 2, 3] as const).flatMap((teams) =>
    (["monthly", "yearly"] as const).map((period) => ({ teams, name: PLAN_PRICES[teams].name, period, subscribers: 0, monthlyRevenue: 0 })),
  );
  let offered = 0;
  let withOffer = 0;

  for (const c of coaches) {
    if (c.ownerUid != null) continue;
    const sub = c.subscription;
    if (sub == null || (sub.status !== "active" && sub.status !== "grace")) continue;
    if (c.testGrant === true) {
      offered++;
      continue;
    }
    const line = lines.find((l) => l.teams === sub.teamsAllowed && l.period === sub.period);
    if (line == null) continue;
    line.subscribers++;
    if (sub.introOffer != null) withOffer++;
  }

  for (const line of lines) {
    const price = PLAN_PRICES[line.teams];
    line.monthlyRevenue = round2(line.subscribers * (line.period === "monthly" ? price.monthly : price.yearly / 12));
  }
  return {
    lines,
    subscribers: lines.reduce((n, l) => n + l.subscribers, 0),
    monthly: round2(lines.reduce((n, l) => n + l.monthlyRevenue, 0)),
    offered,
    withOffer,
  };
}

export const formatEuro = (n: number): string => new Intl.NumberFormat("fr-FR", { style: "currency", currency: "EUR" }).format(n);
