/**
 * Règles Firestore — users/{uid}/metadata/metadata
 *
 * Ce document est écrit par le CLIENT, depuis les paquets du socle de l'app (core_kosmos,
 * skeleton, permissionrequest), jamais depuis app/lib. Chaque test ci-dessous correspond à un
 * appel réel, référencé en commentaire.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
} from 'firebase/firestore';

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

/** Firestore client authentifié en tant que `uid`. */
function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

/** Pré-remplit le document en contournant les règles (comme le ferait l'Admin SDK). */
async function seedMetadata(fields = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${UID}/metadata/metadata`), {
      createdAt: new Date(),
      cguAccepted: true,
      enablePushNotification: false,
      fcmToken: null,
      ...fields,
    });
  });
}

describe('users/{uid}/metadata/metadata — écritures client légitimes', () => {
  before(async () => {
    await testEnv.clearFirestore();
    await seedMetadata();
  });

  it('login: efface le fcmToken quand les push ne sont pas autorisées', async () => {
    // skeleton .../view/page/auth/login_page.dart:797
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        fcmToken: null,
        enablePushNotification: false,
      }),
    );
  });

  it('logout: efface le fcmToken', async () => {
    // skeleton .../controller/user_controller.dart:130
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), { fcmToken: null }),
    );
  });

  it('réglages: bascule des notifications push (set merge + champ de debug)', async () => {
    // core_kosmos .../controller/notif_controller.dart:52
    await assertSucceeds(
      setDoc(
        doc(db(UID), `users/${UID}/metadata/metadata`),
        {
          enablePushNotification: true,
          fcmToken: 'fcm-token-abc',
          authorized_push_notif_1: true,
        },
        { merge: true },
      ),
    );
  });

  it('réglages: bascule des notifications email', async () => {
    // core_kosmos .../controller/notif_controller.dart:222
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        enableEmailNotification: true,
      }),
    );
  });

  it('démarrage: rafraîchit le fcmToken', async () => {
    // core_kosmos .../provider/user_provider.dart:152
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        fcmToken: 'fcm-token-def',
        authorized_push_notif_5: true,
      }),
    );
  });

  it('acceptation des CGU', async () => {
    // skeleton .../controller/user_controller.dart:162
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        cguAccepted: true,
        cguAcceptedDate: serverTimestamp(),
      }),
    );
  });

  it('onboarding permissions: pose permissionLaunched', async () => {
    // permissionrequest .../controller/permission_controller.dart:16
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        permissionLaunched: true,
      }),
    );
  });

  it('lecture par le propriétaire', async () => {
    await assertSucceeds(getDoc(doc(db(UID), `users/${UID}/metadata/metadata`)));
  });
});

describe('users/{uid}/metadata/metadata — ce qui doit rester refusé', () => {
  before(async () => {
    await testEnv.clearFirestore();
    await seedMetadata();
  });

  it("refuse l'écriture d'un champ hors liste blanche", async () => {
    await assertFails(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        subscriptionActive: true,
      }),
    );
  });

  it("refuse un champ hors liste blanche mélangé à des champs légitimes", async () => {
    await assertFails(
      updateDoc(doc(db(UID), `users/${UID}/metadata/metadata`), {
        fcmToken: 'ok',
        isAdmin: true,
      }),
    );
  });

  it('refuse la suppression du document', async () => {
    const { deleteDoc } = await import('firebase/firestore');
    await assertFails(deleteDoc(doc(db(UID), `users/${UID}/metadata/metadata`)));
  });

  it("refuse l'écriture sur le document d'un autre utilisateur", async () => {
    await assertFails(
      updateDoc(doc(db(OTHER_UID), `users/${UID}/metadata/metadata`), {
        fcmToken: null,
      }),
    );
  });

  it("refuse la lecture du document d'un autre utilisateur", async () => {
    await assertFails(getDoc(doc(db(OTHER_UID), `users/${UID}/metadata/metadata`)));
  });

  it('refuse une écriture non authentifiée', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(doc(anon, `users/${UID}/metadata/metadata`), { fcmToken: null }),
    );
  });
});

describe('users/{uid}/metadata/stripe — reste fermé au client', () => {
  before(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${UID}/metadata/stripe`), {
        stripe: { customerId: 'cus_123' },
      });
    });
  });

  it('le propriétaire peut lire son état Stripe', async () => {
    await assertSucceeds(getDoc(doc(db(UID), `users/${UID}/metadata/stripe`)));
  });

  it('le propriétaire ne peut pas écrire son état Stripe', async () => {
    await assertFails(
      updateDoc(doc(db(UID), `users/${UID}/metadata/stripe`), {
        stripe: { customerId: 'cus_client' },
      }),
    );
  });
});

describe('users/{uid}/metadata/security — inchangé', () => {
  before(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${UID}/metadata/security`), {
        profilCompleted: false,
      });
    });
  });

  it('markProfilCompleted reste autorisé', async () => {
    // app/lib/data/coach_profile_repository.dart:101
    await assertSucceeds(
      updateDoc(doc(db(UID), `users/${UID}/metadata/security`), {
        profilCompleted: true,
      }),
    );
  });
});
