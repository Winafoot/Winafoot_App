// server/tests/rules/paywall.test.js
/**
 * Règles Firestore : mur de paiement. Désactivé tant que app_config/config.paywall_enforced
 * n'est pas à true ; activé, les données de l'équipe exigent users/{uid}.access actif et non expiré.
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

describe('mur de paiement activé', () => {
  it("refuse la lecture et l'écriture sans champ access", async () => {
    await seed({ paywall: true });
    await assertFails(getDoc(doc(db(), `users/${UID}/matches/m1`)));
    await assertFails(getDoc(doc(db(), `users/${UID}/players/p1`)));
  });

  it("laisse créer et lire les maillots sans accès (étape 2 du profil, avant l'abonnement)", async () => {
    await seed({ paywall: true });
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/jerseys/j1`), jersey()));
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/jerseys/j1`)));
  });

  it('accepte un accès actif et non expiré', async () => {
    await seed({ paywall: true, access: { active: true, until: future() } });
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/matches/m1`)));
    await assertSucceeds(getDoc(doc(db(), `users/${UID}/players/p1`)));
    await assertSucceeds(setDoc(doc(db(), `users/${UID}/jerseys/j1`), jersey()));
    await assertSucceeds(updateDoc(doc(db(), `users/${UID}/players/p1`), { firstName: 'Z' }));
  });

  it('refuse un accès expiré', async () => {
    await seed({ paywall: true, access: { active: true, until: past() } });
    await assertFails(getDoc(doc(db(), `users/${UID}/matches/m1`)));
  });

  it('refuse un accès inactif', async () => {
    await seed({ paywall: true, access: { active: false, until: future() } });
    await assertFails(getDoc(doc(db(), `users/${UID}/matches/m1`)));
    await assertFails(getDoc(doc(db(), `users/${UID}/players/p1`)));
  });

  it('laisse toujours lire sa fiche et supprimer ses données', async () => {
    await seed({ paywall: true, access: { active: false, until: past() } });
    await assertSucceeds(getDoc(doc(db(), `users/${UID}`)));
    await assertSucceeds(deleteDoc(doc(db(), `users/${UID}/matches/m1`)));
  });

  it("n'ouvre pas les données d'un autre compte", async () => {
    await seed({ paywall: true, access: { active: true, until: future() } });
    await assertFails(getDoc(doc(db('coach-bob'), `users/${UID}/matches/m1`)));
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
