/**
 * Règles Firestore — users/{uid}/players (l'effectif du coach).
 *
 * Reproduit la requête réelle de l'app :
 *   app/lib/data/player_repository.dart:29
 *   collection('users').doc(uid).collection('players').orderBy('order').snapshots()
 *
 * Objectif : déterminer si l'écran « Mon équipe » (« Impossible de charger
 * l'effectif ») est bloqué par les règles ou par autre chose côté client.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, query, orderBy, getDocs, doc, setDoc } from 'firebase/firestore';

const UID = 'coach-alice';
const OTHER_UID = 'coach-bob';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-wina',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: Number(process.env.FIRESTORE_EMULATOR_PORT || 8080),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

describe('users/{uid}/players — lecture de l\'effectif', () => {
  before(async () => {
    await testEnv.clearFirestore();
  });

  it('le propriétaire liste son effectif VIDE (cas coach fraîchement créé)', async () => {
    await assertSucceeds(
      getDocs(query(collection(db(UID), `users/${UID}/players`), orderBy('order'))),
    );
  });

  it('le propriétaire liste son effectif NON vide', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${UID}/players/p1`), {
        firstname: 'Zizou',
        order: 0,
      });
    });
    await assertSucceeds(
      getDocs(query(collection(db(UID), `users/${UID}/players`), orderBy('order'))),
    );
  });

  it('un autre utilisateur ne peut pas lister cet effectif', async () => {
    await assertFails(
      getDocs(query(collection(db(OTHER_UID), `users/${UID}/players`), orderBy('order'))),
    );
  });

  it('un utilisateur non authentifié ne peut pas lister cet effectif', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      getDocs(query(collection(anon, `users/${UID}/players`), orderBy('order'))),
    );
  });
});
