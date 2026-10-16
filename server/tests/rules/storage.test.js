/**
 * Règles Storage — Storage n'est utilisé ni par l'app ni par le back-office : tout accès client est
 * refusé, au propriétaire d'un dossier comme à un administrateur. Les Cloud Functions passent par
 * l'Admin SDK, auquel ces règles ne s'appliquent pas.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import { assertFails, initializeTestEnvironment } from '@firebase/rules-unit-testing';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-wina',
    storage: {
      rules: readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: Number(process.env.FIREBASE_STORAGE_EMULATOR_PORT || 9199),
    },
  });
  await testEnv.clearStorage();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.storage().ref('users/coach-alice/photo.png').put(new Uint8Array([1, 2, 3]));
  });
});

after(async () => {
  await testEnv.cleanup();
});

const contexts = [
  ['un anonyme', () => testEnv.unauthenticatedContext()],
  ['le propriétaire du dossier', () => testEnv.authenticatedContext('coach-alice')],
  ['un administrateur vérifié', () => testEnv.authenticatedContext('admin-1', { admin: true, email_verified: true })],
];

describe('Storage — tout refusé', () => {
  for (const [who, ctx] of contexts) {
    it(`refuse la lecture à ${who}`, async () => {
      await assertFails(ctx().storage().ref('users/coach-alice/photo.png').getDownloadURL());
      await assertFails(ctx().storage().ref('users/coach-alice/photo.png').getMetadata());
    });

    it(`refuse l'écriture et la suppression à ${who}`, async () => {
      await assertFails(ctx().storage().ref('users/coach-alice/nouveau.png').put(new Uint8Array([1])));
      await assertFails(ctx().storage().ref('reports/report/piece.png').put(new Uint8Array([1])));
      await assertFails(ctx().storage().ref('users/coach-alice/photo.png').delete());
    });

    it(`refuse le listage à ${who}`, async () => {
      await assertFails(ctx().storage().ref('users/coach-alice').listAll());
    });
  }
});
