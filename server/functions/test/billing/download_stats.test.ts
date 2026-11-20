import { describe, expect, it } from "vitest";
import { FIRST_DOWNLOAD_TYPES, parseFirstDownloads } from "../../src/billing/app_store_connect";
import { decodeReport, installsReportPath, normalizeBucket, parseInstallsCsv, splitCsvLine } from "../../src/billing/google_play_reports";
import { lastDays, monthsOf } from "../../src/callables/admin/get_download_stats";

describe("parseFirstDownloads (rapport de ventes Apple)", () => {
  const header = ["Provider", "SKU", "Product Type Identifier", "Units", "Developer Proceeds", "Apple Identifier"].join("\t");
  const row = (type: string, units: number) => ["APPLE", "wina", type, units, "0", "123"].join("\t");

  it("somme les premiers téléchargements et ignore mises à jour et re-téléchargements", () => {
    const tsv = [header, row("1F", 4), row("1", 2), row("1T", 1), row("7", 50), row("3F", 9), row("IA1", 3)].join("\n");
    expect(parseFirstDownloads(tsv)).toBe(7);
  });

  it("lit les colonnes par leur nom, pas par leur position", () => {
    const tsv = ["Units\tProduct Type Identifier", "5\t1F", "2\t7"].join("\r\n");
    expect(parseFirstDownloads(tsv)).toBe(5);
  });

  it("renvoie 0 pour un rapport vide ou sans les colonnes attendues", () => {
    expect(parseFirstDownloads("")).toBe(0);
    expect(parseFirstDownloads(header)).toBe(0);
    expect(parseFirstDownloads("a\tb\n1\t2")).toBe(0);
  });

  it("liste les types de premier téléchargement", () => {
    expect([...FIRST_DOWNLOAD_TYPES].sort()).toEqual(["1", "1F", "1T", "F1"]);
  });
});

describe("rapport d'installations Google Play", () => {
  const csv = [
    "Date,Package Name,Daily Device Installs,Daily Device Uninstalls,Daily User Installs,Total User Installs",
    "2026-11-01,fr.winafoot.app,9,1,7,100",
    "2026-11-02,fr.winafoot.app,3,0,2,102",
    "Total,,,,,",
  ].join("\r\n");

  it("lit « Daily User Installs » par jour et ignore les lignes qui ne sont pas des dates", () => {
    expect(parseInstallsCsv(csv)).toEqual([
      { date: "2026-11-01", count: 7 },
      { date: "2026-11-02", count: 2 },
    ]);
  });

  it("retombe sur « Daily Device Installs » sans la colonne utilisateurs", () => {
    const old = ["Date,Package Name,Daily Device Installs", "2026-11-03,fr.winafoot.app,4"].join("\n");
    expect(parseInstallsCsv(old)).toEqual([{ date: "2026-11-03", count: 4 }]);
  });

  it("renvoie une liste vide sans colonne de date ni d'installations", () => {
    expect(parseInstallsCsv("")).toEqual([]);
    expect(parseInstallsCsv("a,b\n1,2")).toEqual([]);
  });

  it("décode l'UTF-16 avec BOM des rapports Google, et l'UTF-8", () => {
    const utf16 = Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from(csv, "utf16le")]);
    expect(parseInstallsCsv(decodeReport(utf16))).toHaveLength(2);
    expect(parseInstallsCsv(decodeReport(Buffer.from(csv, "utf8")))).toHaveLength(2);
  });

  it("découpe une ligne CSV avec guillemets et virgules internes", () => {
    expect(splitCsvLine('a,"b,c","d ""e"""')).toEqual(["a", "b,c", 'd "e"']);
  });

  it("construit le chemin du rapport mensuel et nettoie le nom de l'espace", () => {
    expect(installsReportPath("2026-11", "fr.winafoot.app")).toBe("stats/installs/installs_fr.winafoot.app_202611_overview.csv");
    expect(normalizeBucket("  gs://pubsite_prod_rev_123/stats/installs  ")).toBe("pubsite_prod_rev_123");
    expect(normalizeBucket("pubsite_prod_rev_123")).toBe("pubsite_prod_rev_123");
  });
});

describe("période des statistiques", () => {
  it("va du plus ancien jour jusqu'à hier, sans aujourd'hui", () => {
    const days = lastDays(3, new Date("2026-11-20T10:00:00Z"));
    expect(days).toEqual(["2026-11-17", "2026-11-18", "2026-11-19"]);
  });

  it("couvre les mois à cheval", () => {
    expect(monthsOf(lastDays(5, new Date("2026-12-02T10:00:00Z")))).toEqual(["2026-11", "2026-12"]);
  });
});
