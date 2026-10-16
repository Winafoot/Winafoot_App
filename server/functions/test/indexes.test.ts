import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const indexes = JSON.parse(readFileSync(join(__dirname, "../../firestore.indexes.json"), "utf8"));

// Sans TTL, les compteurs de limitation de débit (un par IP et par compte) et les jetons de
// suppression expirés s'accumulent indéfiniment : la collection grossit avec chaque IP.
describe("Firestore TTL policies", () => {
  it.each(["rate_limits", "accountDeletionRequests"])("%s expires its documents through expiresAt", (collectionGroup) => {
    const override = indexes.fieldOverrides.find((o: any) => o.collectionGroup === collectionGroup && o.fieldPath === "expiresAt");

    expect(override?.ttl).toBe(true);
  });

  // Indexer un horodatage croissant crée un point chaud d'écriture (documentation Firestore TTL) ;
  // aucune requête ne trie ni ne filtre sur expiresAt.
  it.each(["rate_limits", "accountDeletionRequests"])("%s does not index expiresAt", (collectionGroup) => {
    const override = indexes.fieldOverrides.find((o: any) => o.collectionGroup === collectionGroup && o.fieldPath === "expiresAt");

    expect(override?.indexes).toEqual([]);
  });
});
