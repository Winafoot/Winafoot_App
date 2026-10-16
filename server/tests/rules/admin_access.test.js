/**
 * Règles Firestore — accès du back-office.
 *
 * Le CMS (FireCMS Community) lit Firestore directement depuis le navigateur
 * avec le SDK client : ces règles sont donc le seul rempart. Le claim `admin`
 * est posé par scripts/set-admin.ts.
 *
 * Les écritures restent fermées à l'administrateur : toutes les mutations
 * passent par les callables Admin SDK (callables/admin/*).
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';

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
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/coach-alice'), { email: 'alice@club.test' });
    await setDoc(doc(db, 'users/coach-bob'), { email: 'bob@club.test' });
    await setDoc(doc(db, 'users/coach-bob/players/p1'), { name: 'Zidane' });
    await setDoc(doc(db, 'admin_audit/e1'), { action: 'create' });
  });
});

const admin = () => testEnv.authenticatedContext('admin-1', { admin: true, email_verified: true }).firestore();
const alice = () => testEnv.authenticatedContext('coach-alice').firestore();

describe('users — lecture administrateur', () => {
  it("laisse l'administrateur lire n'importe quel coach", async () => {
    await assertSucceeds(getDoc(doc(admin(), 'users/coach-bob')));
  });

  it("laisse l'administrateur lister les coachs", async () => {
    await assertSucceeds(getDocs(collection(admin(), 'users')));
  });

  it('refuse toujours à un coach la lecture d\'un autre coach', async () => {
    await assertFails(getDoc(doc(alice(), 'users/coach-bob')));
  });

  it('laisse toujours un coach lire sa propre fiche', async () => {
    await assertSucceeds(getDoc(doc(alice(), 'users/coach-alice')));
  });

  it("refuse à l'administrateur d'écrire une fiche coach", async () => {
    await assertFails(setDoc(doc(admin(), 'users/coach-bob'), { email: 'pirate@club.test' }));
  });

  it('garde les sous-collections des coachs fermées à l\'administrateur', async () => {
    await assertFails(getDocs(collection(admin(), 'users/coach-bob/players')));
  });
});

describe('admin_audit — piste d\'audit', () => {
  it("laisse l'administrateur lire le journal", async () => {
    await assertSucceeds(getDoc(doc(admin(), 'admin_audit/e1')));
  });

  it('interdit à quiconque d\'écrire le journal', async () => {
    await assertFails(setDoc(doc(admin(), 'admin_audit/e2'), { action: 'forgé' }));
  });

  it('refuse à un coach la lecture du journal', async () => {
    await assertFails(getDoc(doc(alice(), 'admin_audit/e1')));
  });
});
