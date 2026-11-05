// server/tests/rules/paywall.test.js
/**
 * Règles Firestore : abonnement. Désactivé tant que app_config/config.paywall_enforced n'est pas à true ;
 * activé, l'app reste gratuite et seul le lancement d'un match exige users/{uid}.access actif et non expiré.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const UID = 'coach-alice';
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

beforeEach(async () => {
  await testEnv.clearFirestore();
});

const db = (uid = UID) => testEnv.authenticatedContext(uid).firestore();

async function seed({ paywall, access }) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    if (paywall !== undefined) await setDoc(doc(fs, 'app_config/config'), { paywall_enforced: paywall });
    await setDoc(doc(fs, `users/${UID}`), { firstname: 'Alice', ...(access ? { access } : {}) });
    await setDoc(doc(fs, `users/${UID}/matches/m1`), { status: 'draft' });
    await setDoc(doc(fs, `users/${UID}/players/p1`), { firstName: 'A', lastName: 'B', strongFoot: 'droit', position: 'milieu' });
  });
}

const future = () => new Date(Date.now() + 86_400_000);
const past = () => new Date(Date.now() - 86_400_000);
const jersey = () => ({ name: 'Domicile', color: 'rouge', order: 0, createdAt: new Date() });

describe('mur de paiement désactivé', () => {
  it('ne change rien sans app_config/config', async () => {
    await seed({});
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/matches/m1`)));
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/jerseys/j1`), jersey()));
  });

  it("ne change rien quand paywall_enforced vaut false", async () => {
    await seed({ paywall: false });
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/players/p1`)));
  });
});

/** Match valide minimal : le lancement d'un match est ce que le mur de paiement protège. */
const draftMatch = () => ({ status: 'draft' });

/** État publié par le téléphone du coach pour l'adjoint (voir live_match.test.js). */
const liveSnapshot = () => ({
  matchId: 'm1', status: 'live', half: 1, elapsedSeconds: 0, scoreUs: 0, scoreThem: 0, formationLabel: '4-3-3',
  slots: [], assignments: [], numbers: {}, captainId: null, substituteIds: [], enabledStatKeys: [], halfTimeStatKeys: [],
  swapSides: false, playerStats: {}, events: [], players: {}, kit: null, opponentName: '', updatedAt: new Date(),
});

describe('mur de paiement activé : l\'app reste gratuite', () => {
  it("laisse lire et gérer l'effectif, les compositions et l'historique sans abonnement", async () => {
    await seed({ paywall: true });
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/players/p1`)));
    await assertSucceeds(updateDoc(doc(db(), `users/${UID}/players/p1`), { firstName: 'Z' }));
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/matches/m1`)));
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/compositions/c1`), { name: 'Ma compo', formationLabel: '4-3-3' }));
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/compositions/c1`)));
  });

  it('laisse créer et lire les maillots sans abonnement', async () => {
    await seed({ paywall: true });
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/jerseys/j1`), jersey()));
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/jerseys/j1`)));
  });

  it("refuse de lancer un match sans abonnement : création du match et match en direct", async () => {
    await seed({ paywall: true });
    await assertFails(setDoc(doc(db(), `users/${UID}/matches/m2`), draftMatch()));
    await assertFails(setDoc(doc(db(), `users/${UID}/matches/m1`), draftMatch(), { merge: true }));
    await assertFails(setDoc(doc(db(), `users/${UID}/liveMatch/current`), liveSnapshot()));
  });

  it('accepte de lancer un match avec un accès actif et non expiré', async () => {
    await seed({ paywall: true, access: { active: true, until: future() } });
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/matches/m2`), draftMatch()));
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/liveMatch/current`), liveSnapshot()));
  });

  it('refuse de lancer un match avec un accès expiré ou inactif, mais garde le reste ouvert', async () => {
    for (const access of [{ active: true, until: past() }, { active: false, until: future() }]) {
      await testEnv.clearFirestore();
      await seed({ paywall: true, access });
      await assertFails(setDoc(doc(db(), `users/${UID}/matches/m2`), draftMatch()));
      await assertSucceeds(getDoc(doc(db(), `users/${UID}/matches/m1`)));
      await assertSucceeds(getDoc(doc(db(), `users/${UID}/players/p1`)));
    }
  });

  it('laisse toujours lire sa fiche et supprimer ses données', async () => {
    await seed({ paywall: true, access: { active: false, until: past() } });
    await assertSucceeds(getDoc(doc(db(), `users/${UID}`)));
    await assertSucceeds(deleteDoc(doc(db(), `users/${UID}/matches/m1`)));
  });

  it("n'ouvre pas les données d'un autre compte", async () => {
    await seed({ paywall: true, access: { active: true, until: future() } });
    await assertFails(getDoc(doc(db('coach-bob'), `users/${UID}/matches/m1`)));
    await assertFails(getDoc(doc(db('coach-bob'), `users/${UID}/players/p1`)));
  });
});

describe('champs réservés au serveur', () => {
  for (const field of ['access', 'subscription', 'ownerUid', 'teamIndex']) {
    it(`le client ne peut pas écrire ${field}`, async () => {
      await seed({});
      await assertFails(updateDoc(doc(db(), `users/${UID}`), { [field]: { active: true } }));
    });
  }
});
