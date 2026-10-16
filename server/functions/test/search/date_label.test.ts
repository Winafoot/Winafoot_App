import { describe, expect, it } from "vitest";
import { formatDateLabel } from "../../src/search/date_label";

// Valeurs attendues = sortie de `_formatDate` (app/lib/view/page/statistiques_matchs_screen.dart:28-47)
// pour un appareil en heure de Paris : « JJ » sur 2 chiffres, mois abrégé, année.
const EXPECTED: ReadonlyArray<[string, string]> = [
  ["2026-01-15T12:00:00Z", "15 Janv. 2026"],
  ["2026-02-03T12:00:00Z", "03 Févr. 2026"],
  ["2026-03-05T12:00:00Z", "05 Mars 2026"],
  ["2026-04-20T12:00:00Z", "20 Avr. 2026"],
  ["2026-05-01T12:00:00Z", "01 Mai 2026"],
  ["2026-06-30T12:00:00Z", "30 Juin 2026"],
  ["2026-07-14T12:00:00Z", "14 Juil. 2026"],
  ["2026-08-09T12:00:00Z", "09 Août 2026"],
  ["2026-09-12T12:00:00Z", "12 Sept. 2026"],
  ["2026-10-14T12:00:00Z", "14 Oct. 2026"],
  ["2026-11-02T12:00:00Z", "02 Nov. 2026"],
  ["2026-12-25T12:00:00Z", "25 Déc. 2026"],
  // Bascule de jour selon l'heure de Paris (UTC+1 l'hiver, UTC+2 l'été).
  ["2026-03-04T23:30:00Z", "05 Mars 2026"],
  ["2026-03-04T22:30:00Z", "04 Mars 2026"],
  ["2026-10-14T22:30:00Z", "15 Oct. 2026"],
  ["2026-10-14T21:30:00Z", "14 Oct. 2026"],
  // Changements d'heure : 29 mars 2026 (été) et 25 octobre 2026 (hiver).
  ["2026-03-28T23:30:00Z", "29 Mars 2026"],
  ["2026-03-29T00:30:00Z", "29 Mars 2026"],
  ["2026-10-24T22:30:00Z", "25 Oct. 2026"],
  ["2026-10-25T22:30:00Z", "25 Oct. 2026"],
  ["2026-10-25T23:30:00Z", "26 Oct. 2026"],
  // Passage d'année.
  ["2026-12-31T23:30:00Z", "01 Janv. 2027"],
];

describe("formatDateLabel", () => {
  it.each(EXPECTED)("%s -> %s", (iso, label) => {
    expect(formatDateLabel(new Date(iso))).toBe(label);
  });
});
