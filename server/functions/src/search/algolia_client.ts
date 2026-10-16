import { algoliasearch } from "algoliasearch";
import { ALGOLIA_APP_ID } from "../config/algolia";
import { ALGOLIA_WRITE_KEY } from "../config/secrets";
import { type SearchRecord } from "./records";

/**
 * Seule erreur Algolia qui sort de ce module. Les erreurs du SDK embarquent la requête brute
 * (clé d'écriture en en-tête, enregistrement en corps) dans `stackTrace` : on n'en garde que le
 * statut HTTP (`undefined` pour le réseau, ou un secret absent) et le message.
 */
export class AlgoliaFailure extends Error {
  constructor(
    readonly status: number | undefined,
    message: string,
  ) {
    super(message);
    this.name = "AlgoliaFailure";
  }
}

export function toAlgoliaFailure(error: unknown): AlgoliaFailure {
  if (error instanceof AlgoliaFailure) return error;
  const { status, message } = (error ?? {}) as { status?: unknown; message?: unknown };
  return new AlgoliaFailure(typeof status === "number" ? status : undefined, typeof message === "string" ? message : "erreur Algolia inconnue");
}

/** Écritures dans un index. Fabrique remplaçable : les tests injectent un faux. */
export interface AlgoliaWriter {
  saveObject(indexName: string, record: SearchRecord): Promise<void>;
  deleteObject(indexName: string, objectID: string): Promise<void>;
}

export type AlgoliaWriterFactory = () => AlgoliaWriter;

/** Exécute un appel au SDK avec un client neuf ; toute erreur devient une AlgoliaFailure. */
async function withClient(call: (client: ReturnType<typeof algoliasearch>) => Promise<unknown>): Promise<void> {
  try {
    // L'émulateur Functions charge la VRAIE clé depuis Secret Manager : il ne doit jamais écrire chez Algolia.
    if (process.env.FUNCTIONS_EMULATOR === "true") {
      throw new AlgoliaFailure(undefined, "écriture Algolia refusée sous l'émulateur Functions");
    }
    const key = ALGOLIA_WRITE_KEY.value();
    if (key == null || key.trim().length === 0) {
      throw new AlgoliaFailure(undefined, "clé d'écriture Algolia indisponible");
    }
    await call(algoliasearch(ALGOLIA_APP_ID, key));
  } catch (error) {
    throw toAlgoliaFailure(error);
  }
}

/** Le client n'est construit qu'à l'appel : un événement sans effet ne lit ni secret ni réseau. */
export const createAlgoliaWriter: AlgoliaWriterFactory = () => ({
  saveObject: (indexName, record) => withClient((client) => client.saveObjects({ indexName, objects: [record] })),
  deleteObject: (indexName, objectID) => withClient((client) => client.deleteObject({ indexName, objectID })),
});
