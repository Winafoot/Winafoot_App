// Mêmes libellés que `_kMonths` de app/lib/view/page/statistiques_matchs_screen.dart.
const MONTHS: readonly string[] = ["Janv.", "Févr.", "Mars", "Avr.", "Mai", "Juin", "Juil.", "Août", "Sept.", "Oct.", "Nov.", "Déc."];

const PARIS_DATE = new Intl.DateTimeFormat("fr-FR", { timeZone: "Europe/Paris", year: "numeric", month: "numeric", day: "numeric" });

/**
 * « 05 Mars 2026 » : identique à `_formatDate` de l'app (jour sur 2 chiffres, mois abrégé, année),
 * sur la date de Paris. L'heure d'été est laissée à Intl.
 */
export function formatDateLabel(date: Date): string {
  const parts = Object.fromEntries(PARIS_DATE.formatToParts(date).map((p) => [p.type, p.value]));
  return `${parts.day.padStart(2, "0")} ${MONTHS[Number(parts.month) - 1]} ${parts.year}`;
}
