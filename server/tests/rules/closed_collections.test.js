/**
 * Règles Firestore — configuration publique, collections tenues par le serveur, et accès des
 * administrateurs (claim `admin` ET adresse vérifiée).
 *
 * - app_config : lue au lancement de l'app, avant connexion ; jamais écrite par un client.
 * - reports, tasks, deleted_users, admin_locks : écrites par l'Admin SDK seulement (ou plus du
 *   tout), fermées à tous les clients, administrateurs compris.
 * - admin_audit : lue par un administrateur vérifié, écrite par l'Admin SDK seulement.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';

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
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, 'app_config/metadata'), { appName: 'Wina', maintenance: false });
    await setDoc(doc(fs, 'app_config/config'), { max_players: 20 });
    await setDoc(doc(fs, 'reports/r1'), { type: 'report' });
    await setDoc(doc(fs, 'tasks/t1'), { status: 'pending' });
    await setDoc(doc(fs, 'deleted_users/d1'), { email: 'gone@club.test' });
    await setDoc(doc(fs, 'admin_locks/accounts'), { holder: 'x' });
    await setDoc(doc(fs, 'admin_audit/e1'), { action: 'create' });
    await setDoc(doc(fs, 'users/coach-bob'), { email: 'bob@club.test' });
  });
});

after(async () => {
  await testEnv.cleanup();
});

const anonymous = () => testEnv.unauthenticatedContext().firestore();
const coach = () => testEnv.authenticatedContext('coach-alice', { email_verified: true }).firestore();
const admin = () => testEnv.authenticatedContext('admin-1', { admin: true, email_verified: true }).firestore();
const unverifiedAdmin = () => testEnv.authenticatedContext('admin-2', { admin: true, email_verified: false }).firestore();
const adminWithoutVerification = () => testEnv.authenticatedContext('admin-3', { admin: true }).firestore();
const adminVerifiedAsString = () => testEnv.authenticatedContext('admin-4', { admin: true, email_verified: 'true' }).firestore();

describe('app_config — configuration publique', () => {
  it('se lit sans connexion (lancement de l\'app)', async () => {
    await assertSucceeds(getDoc(doc(anonymous(), 'app_config/metadata')));
    await assertSucceeds(getDoc(doc(anonymous(), 'app_config/config')));
  });

  it('se lit connecté', async () => {
    await assertSucceeds(getDoc(doc(coach(), 'app_config/metadata')));
  });

  for (const [who, db] of [['un anonyme', anonymous], ['un coach', coach], ['un administrateur vérifié', admin]]) {
    it(`ne s'écrit pas, même par ${who}`, async () => {
      await assertFails(updateDoc(doc(db(), 'app_config/metadata'), { maintenance: true }));
      await assertFails(setDoc(doc(db(), 'app_config/nouveau'), { a: 1 }));
      await assertFails(deleteDoc(doc(db(), 'app_config/config')));
    });
  }
});

for (const path of ['reports/r1', 'tasks/t1', 'deleted_users/d1', 'admin_locks/accounts']) {
  const collectionName = path.split('/')[0];
  describe(`${collectionName} — fermée à tous les clients`, () => {
    for (const [who, db] of [['un anonyme', anonymous], ['un coach', coach], ['un administrateur vérifié', admin]]) {
      it(`refuse la lecture et l'écriture à ${who}`, async () => {
        await assertFails(getDoc(doc(db(), path)));
        await assertFails(getDocs(collection(db(), collectionName)));
        await assertFails(setDoc(doc(db(), `${collectionName}/nouveau`), { a: 1 }));
        await assertFails(updateDoc(doc(db(), path), { a: 2 }));
        await assertFails(deleteDoc(doc(db(), path)));
      });
    }
  });
}

describe('admin_audit — piste d\'audit', () => {
  it('se lit par un administrateur vérifié', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'admin_audit/e1')));
    await assertSucceeds(getDocs(collection(admin(), 'admin_audit')));
  });

  it('ne s\'écrit par personne', async () => {
    await assertFails(setDoc(doc(admin(), 'admin_audit/e2'), { action: 'forgé' }));
    await assertFails(updateDoc(doc(admin(), 'admin_audit/e1'), { action: 'modifié' }));
    await assertFails(deleteDoc(doc(admin(), 'admin_audit/e1')));
  });
});

// Le claim seul ne suffit pas : un administrateur dont l'adresse n'est pas vérifiée n'a aucun droit
// d'administrateur (même règle que verifyAdmin côté callables).
describe('administrateur à l\'adresse non vérifiée', () => {
  for (const [label, db] of [
    ['email_verified à false', unverifiedAdmin],
    ['sans email_verified', adminWithoutVerification],
    ['email_verified en chaîne', adminVerifiedAsString],
  ]) {
    it(`${label} : ni fiches coach, ni liste des coachs, ni piste d'audit`, async () => {
      await assertFails(getDoc(doc(db(), 'users/coach-bob')));
      await assertFails(getDocs(collection(db(), 'users')));
      await assertFails(getDoc(doc(db(), 'admin_audit/e1')));
    });
  }

  it('alors que l\'administrateur vérifié lit fiches et liste', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'users/coach-bob')));
    await assertSucceeds(getDocs(collection(admin(), 'users')));
  });
});
