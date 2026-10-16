import { ALGOLIA_INDICES } from "../config/algolia";

/** Réglages d'un index. Appliqués par scripts/algolia-reindex.ts, jamais par les triggers. */
export interface IndexSettings {
  attributesForFaceting: string[];
  searchableAttributes: string[];
  attributesToRetrieve: string[];
  attributesToHighlight: string[];
  attributesToSnippet: string[];
  disableTypoToleranceOnAttributes: string[];
}

const COMMON = {
  attributesForFaceting: ["filterOnly(ownerKey)"],
  attributesToRetrieve: ["docId"],
  attributesToHighlight: [],
  attributesToSnippet: [],
  disableTypoToleranceOnAttributes: ["formationDigits", "dateLabel"],
};

export const INDEX_SETTINGS: Readonly<Record<string, IndexSettings>> = {
  [ALGOLIA_INDICES.compositions]: { ...COMMON, searchableAttributes: ["name", "formationLabel", "formationDigits"] },
  [ALGOLIA_INDICES.matches]: { ...COMMON, searchableAttributes: ["opponentName", "dateLabel"] },
};
