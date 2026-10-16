/**
 * Règles Firestore — users/{uid}/notifications
 *
 * La suppression est passée de `allow delete: if false` à
 * `allow delete: if isOwner(uid)` : la recette exige que tout contenu affiché
 * à l'utilisateur puisse être supprimé par lui.
 *
 * Ces tests verrouillent les deux faces de l'assouplissement : le propriétaire
 * peut supprimer SA notification, et rien d'autre ne s'est ouvert au passage
 * (création toujours refusée, champs de contenu toujours inaltérables,
 * suppression impossible chez autrui ou sans authentification).
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';

const UID = 'coach-alice';
const OTHER_UID = 'coach-bob';
const NOTIF_ID = 'notif-1';

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

/** Sème la notification via l'Admin SDK : le client ne peut pas la créer. */
beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${UID}/notifications/${NOTIF_ID}`), {
      title: 'Convocation',
      body: 'Match samedi à 14 h.',
      isRead: false,
    });
  });
});

describe('users/{uid}/notifications — suppression', () => {
  it('le propriétaire supprime sa propre notification', async () => {
    const db = testEnv.authenticatedContext(UID).firestore();
    await assertSucceeds(
      deleteDoc(doc(db, `users/${UID}/notifications/${NOTIF_ID}`)),
    );
  });

  it('un autre utilisateur ne peut pas la supprimer', async () => {
    const db = testEnv.authenticatedContext(OTHER_UID).firestore();
    await assertFails(
      deleteDoc(doc(db, `users/${UID}/notifications/${NOTIF_ID}`)),
    );
  });

  it('un client non authentifié ne peut pas la supprimer', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      deleteDoc(doc(db, `users/${UID}/notifications/${NOTIF_ID}`)),
    );
  });
});

describe('users/{uid}/notifications — non-régression', () => {
  it('le propriétaire ne peut toujours pas créer une notification', async () => {
    const db = testEnv.authenticatedContext(UID).firestore();
    await assertFails(
      setDoc(doc(db, `users/${UID}/notifications/forge`), {
        title: 'Notification forgée',
        isRead: false,
      }),
    );
  });

  it('le propriétaire ne peut toujours pas réécrire le contenu', async () => {
    const db = testEnv.authenticatedContext(UID).firestore();
    await assertFails(
      updateDoc(doc(db, `users/${UID}/notifications/${NOTIF_ID}`), {
        title: 'Titre réécrit',
      }),
    );
  });

  it('le propriétaire peut toujours marquer comme lue', async () => {
    const db = testEnv.authenticatedContext(UID).firestore();
    await assertSucceeds(
      updateDoc(doc(db, `users/${UID}/notifications/${NOTIF_ID}`), {
        isRead: true,
        readAt: new Date(),
      }),
    );
  });
});
