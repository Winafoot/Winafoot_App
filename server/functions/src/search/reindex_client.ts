import { algoliasearch } from "algoliasearch";
import { AlgoliaFailure, toAlgoliaFailure } from "./algolia_client";
import { type ReindexClient } from "./reindex";

/**
 * Client Algolia du script de réindexation (clé `ALGOLIA_REINDEX_KEY`, ACL étendues). Comme algolia_client.ts :
 * chaque appel au SDK est enveloppé, aucune erreur du SDK (requête brute, clé en en-tête) n'en sort.
 */
export function createReindexClient(appId: string, apiKey: string): ReindexClient {
  const client = algoliasearch(appId, apiKey);

  async function run<T>(call: () => Promise<T>): Promise<T> {
    try {
      return await call();
    } catch (error) {
      const failure = toAlgoliaFailure(error);
      // Ceinture et bretelles : le message du serveur ne doit pas citer la clé.
      throw new AlgoliaFailure(failure.status, failure.message.split(apiKey).join("[clé]"));
    }
  }

  return {
    setSettings: (indexName, indexSettings) =>
      run(async () => {
        const { taskID } = await client.setSettings({ indexName, indexSettings });
        await client.waitForTask({ indexName, taskID });
      }),
    saveRecords: (indexName, records) => run(() => client.saveObjects({ indexName, objects: records, waitForTasks: true })).then(() => undefined),
    deleteRecords: (indexName, objectIDs) => run(() => client.deleteObjects({ indexName, objectIDs, waitForTasks: true })).then(() => undefined),
    browseObjectIds: (indexName) =>
      run(async () => {
        const ids: string[] = [];
        await client.browseObjects({
          indexName,
          browseParams: { attributesToRetrieve: ["objectID"] },
          aggregator: (response) => response.hits.forEach((hit) => ids.push(hit.objectID)),
        });
        return ids;
      }),
  };
}
