// server/tests/rules/linked_read.test.js
/**
 * Règles Firestore : le propriétaire lit la fiche de chacune de ses équipes liées (champ ownerUid),
 * jamais celle d'un compte qui ne lui est pas rattaché.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from 'firebase/firestore';

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
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, 'users/owner'), { firstname: 'Boss' });
    await setDoc(doc(fs, 'users/team2'), { ownerUid: 'owner', teamIndex: 2, teamName: 'U15' });
    await setDoc(doc(fs, 'users/other-team'), { ownerUid: 'someone-else', teamIndex: 2 });
    await setDoc(doc(fs, 'users/stranger'), { firstname: 'X' });
  });
});

const db = (uid) => testEnv.authenticatedContext(uid).firestore();

describe('lecture des équipes liées', () => {
  it('le propriétaire lit la fiche de son équipe liée', async () => {
    await assertSucceeds(getDoc(doc(db('owner'), 'users/team2')));
  });

  it('le propriétaire liste ses équipes liées par ownerUid', async () => {
    const snap = await assertSucceeds(getDocs(query(collection(db('owner'), 'users'), where('ownerUid', '==', 'owner'))));
    if (snap.size !== 1) throw new Error(`1 équipe attendue, ${snap.size} reçue(s)`);
  });

  it("refuse la fiche d'une équipe rattachée à un autre propriétaire", async () => {
    await assertFails(getDoc(doc(db('owner'), 'users/other-team')));
  });

  it("refuse la fiche d'un compte sans propriétaire", async () => {
    await assertFails(getDoc(doc(db('owner'), 'users/stranger')));
  });

  it("refuse la liste de tous les comptes", async () => {
    await assertFails(getDocs(collection(db('owner'), 'users')));
  });

  it("l'équipe liée n'écrit toujours pas ses champs serveur", async () => {
    await assertFails(updateDoc(doc(db('team2'), 'users/team2'), { ownerUid: 'team2' }));
  });
});
