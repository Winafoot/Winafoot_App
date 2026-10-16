/**
 * Règles Firestore — l'effectif est tenu par le SERVEUR.
 *
 * La création et la suppression des joueurs passent par les callables createPlayer et
 * deletePlayer (Admin SDK, plafond jugé sur le nombre réel de joueurs : voir
 * functions/test/callables/create_player.test.ts), qui tiennent aussi le compteur
 * `users/{uid}.playerCount`. Ces tests vérifient que les règles ferment toutes les voies directes.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, increment, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

const UID = 'coach-alice';
const OTHER_UID = 'coach-bob';
const PORT = Number(process.env.FIRESTORE_EMULATOR_PORT || 8080);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-wina',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: PORT,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

const PLAYER = { firstName: 'Karim', lastName: 'Benzema', strongFoot: 'droit', position: 'attaquant' };

/** Un coach avec `count` joueurs et le compteur à jour, tel que le laissent les callables. */
async function seed(count = 3) {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${UID}`), { id: UID, email: 'a@club.test', teamFormat: 5, playerCount: count });
    for (let i = 0; i < count; i++) {
      await setDoc(doc(db, `users/${UID}/players/p${i}`), { ...PLAYER, lastName: `J${i}`, order: i });
    }
  });
}

const db = (uid = UID) => testEnv.authenticatedContext(uid).firestore();

describe('effectif — création réservée au serveur', () => {
  beforeEach(() => seed(3));

  it('refuse une création directe, même sous le plafond', async () => {
    await assertFails(setDoc(doc(db(), `users/${UID}/players/nouveau`), PLAYER));
  });

  it('refuse l\'ancienne création du client : joueur + incrément du compteur dans un batch', async () => {
    const d = db();
    const batch = writeBatch(d);
    batch.set(doc(d, `users/${UID}/players/nouveau`), PLAYER);
    batch.set(doc(d, `users/${UID}`), { playerCount: increment(1) }, { merge: true });
    await assertFails(batch.commit());
  });

  it('refuse N créations dans un seul batch (le contournement du plafond)', async () => {
    const d = db();
    const batch = writeBatch(d);
    for (let i = 0; i < 10; i++) batch.set(doc(d, `users/${UID}/players/clandestin${i}`), PLAYER);
    await assertFails(batch.commit());
  });

  it('refuse de créer un joueur chez un autre coach', async () => {
    await assertFails(setDoc(doc(db(OTHER_UID), `users/${UID}/players/intrus`), PLAYER));
  });
});

describe('effectif — suppression réservée au serveur', () => {
  beforeEach(() => seed(3));

  it('refuse une suppression directe', async () => {
    await assertFails(deleteDoc(doc(db(), `users/${UID}/players/p0`)));
  });

  it('refuse l\'ancienne suppression du client : joueur + décrément dans un batch', async () => {
    const d = db();
    const batch = writeBatch(d);
    batch.delete(doc(d, `users/${UID}/players/p0`));
    batch.set(doc(d, `users/${UID}`), { playerCount: increment(-1) }, { merge: true });
    await assertFails(batch.commit());
  });
});

describe('effectif — le compteur appartient au serveur', () => {
  beforeEach(() => seed(5));

  it('refuse de le décrémenter seul pour se refaire de la place', async () => {
    await assertFails(updateDoc(doc(db(), `users/${UID}`), { playerCount: increment(-1) }));
  });

  it('refuse de l\'incrémenter, de le remettre à zéro ou de le fixer', async () => {
    await assertFails(updateDoc(doc(db(), `users/${UID}`), { playerCount: increment(1) }));
    await assertFails(setDoc(doc(db(), `users/${UID}`), { playerCount: 0 }, { merge: true }));
    await assertFails(updateDoc(doc(db(), `users/${UID}`), { playerCount: -1000000 }));
  });

  it('laisse le reste de la fiche modifiable', async () => {
    await assertSucceeds(updateDoc(doc(db(), `users/${UID}`), { coachName: 'Zidane' }));
  });
});

describe('effectif — lecture et mise à jour par le propriétaire', () => {
  beforeEach(() => seed(3));

  it('le propriétaire lit son effectif, pas celui d\'un autre', async () => {
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/players/p0`)));
    await assertFails(getDoc(doc(db(OTHER_UID), `users/${UID}/players/p0`)));
  });

  it('le propriétaire modifie un joueur (PlayerRepository.updatePlayer)', async () => {
    await assertSucceeds(updateDoc(doc(db(), `users/${UID}/players/p0`), PLAYER));
  });

  it('refuse à un autre coach de modifier ce joueur', async () => {
    await assertFails(updateDoc(doc(db(OTHER_UID), `users/${UID}/players/p0`), { lastName: 'Pirate' }));
  });
});
