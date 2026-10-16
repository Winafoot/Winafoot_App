/**
 * Règles Firestore — collections réservées au serveur (Admin SDK, qui contourne les règles).
 *
 * rate_limits (compteurs de limitation de débit) et accountDeletionRequests (jetons de
 * suppression de compte) ne sont lues ni écrites par aucun client. Un client qui pourrait
 * lire un jeton supprimerait un compte ; un client qui pourrait écrire un compteur
 * désarmerait la limitation de débit ou bloquerait un autre utilisateur.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

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
    await setDoc(doc(ctx.firestore(), 'rate_limits/reset_abc'), { count: 1 });
    await setDoc(doc(ctx.firestore(), 'accountDeletionRequests/tok'), { email: 'a@club.test' });
  });
});

after(async () => {
  await testEnv.cleanup();
});

for (const path of ['rate_limits/reset_abc', 'accountDeletionRequests/tok']) {
  describe(`${path} — fermé à tous les clients`, () => {
    const owner = () => testEnv.authenticatedContext('coach-alice').firestore();
    const admin = () => testEnv.authenticatedContext('admin1', { admin: true, email_verified: true }).firestore();
    const anonymous = () => testEnv.unauthenticatedContext().firestore();

    it('refuse la lecture à un coach, à un administrateur et à un anonyme', async () => {
      await assertFails(getDoc(doc(owner(), path)));
      await assertFails(getDoc(doc(admin(), path)));
      await assertFails(getDoc(doc(anonymous(), path)));
    });

    it('refuse la création, la modification et la suppression à un coach', async () => {
      await assertFails(setDoc(doc(owner(), `${path}-nouveau`), { count: 0 }));
      await assertFails(updateDoc(doc(owner(), path), { count: 0 }));
      await assertFails(deleteDoc(doc(owner(), path)));
    });

    it('refuse aussi l\'écriture à un administrateur (seul l\'Admin SDK écrit)', async () => {
      await assertFails(updateDoc(doc(admin(), path), { count: 0 }));
    });
  });
}
