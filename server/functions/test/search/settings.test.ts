import { describe, expect, it } from "vitest";
import { ALGOLIA_INDICES } from "../../src/config/algolia";
import { INDEX_SETTINGS } from "../../src/search/settings";

describe("INDEX_SETTINGS", () => {
  it("covers both indices, filterOnly(ownerKey) facet included", () => {
    expect(Object.keys(INDEX_SETTINGS).sort()).toEqual(["wina_compositions", "wina_matches"]);
    for (const settings of Object.values(INDEX_SETTINGS)) {
      expect(settings.attributesForFaceting).toEqual(["filterOnly(ownerKey)"]);
      expect(settings.attributesToRetrieve).toEqual(["docId"]);
      expect(settings.attributesToHighlight).toEqual([]);
      expect(settings.attributesToSnippet).toEqual([]);
      expect(settings.disableTypoToleranceOnAttributes).toEqual(["formationDigits", "dateLabel"]);
      // Aucun attribut masqué à la lecture (contrat des réglages).
      expect(settings).not.toHaveProperty("unretrievableAttributes");
    }
  });

  it("searches the contract attributes", () => {
    expect(INDEX_SETTINGS[ALGOLIA_INDICES.compositions].searchableAttributes).toEqual(["name", "formationLabel", "formationDigits"]);
    expect(INDEX_SETTINGS[ALGOLIA_INDICES.matches].searchableAttributes).toEqual(["opponentName", "dateLabel"]);
  });
});
