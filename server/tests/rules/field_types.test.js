/**
 * Règles Firestore — types et tailles des champs que le CLIENT écrit sur users/{uid},
 * users/{uid}/metadata/security et users/{uid}/metadata/metadata.
 *
 * Les listes blanches disent QUELS champs le client peut écrire ; ces contrôles disent sous
 * quelle forme, d'après ce que l'app écrit réellement (sources citées). Seul un champ touché
 * par l'écriture est contrôlé : une valeur déjà enregistrée n'est pas rejugée.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, deleteField, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

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

const db = () => testEnv.authenticatedContext(UID).firestore();
const userRef = () => doc(db(), `users/${UID}`);
const securityRef = () => doc(db(), `users/${UID}/metadata/security`);
const metadataRef = () => doc(db(), `users/${UID}/metadata/metadata`);
const text = (n) => 'x'.repeat(n);

/** Documents tels que les crée createCoach (Admin SDK), plus des valeurs déjà enregistrées. */
async function seed(extraUser = {}) {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, `users/${UID}`), {
      id: UID, email: 'a@club.test', userType: 'client', teamFormat: 8, playerCount: 3, createdAt: Timestamp.now(), ...extraUser,
    });
    await setDoc(doc(fs, `users/${UID}/metadata/security`), { email: 'a@club.test', profilCompleted: false, cguAccepted: false });
    await setDoc(doc(fs, `users/${UID}/metadata/metadata`), { cguAccepted: false, enablePushNotification: false, createdAt: Timestamp.now() });
  });
}

describe('users/{uid} — formes acceptées', () => {
  beforeEach(() => seed());

  it('textes du profil aux tailles maximales (100, 100, 30, 30)', async () => {
    // coach_profile_repository.dart:24-32 (saveTeamInfo, set merge)
    await assertSucceeds(
      setDoc(userRef(), { coachName: text(100), teamName: text(100), category: text(30), division: text(30) }, { merge: true }),
    );
  });

  it('adresse e-mail de 254 caractères', async () => {
    await assertSucceeds(updateDoc(userRef(), { email: `${text(244)}@club.test` }));
  });

  it('présence : en ligne avec lastOnline à null, hors ligne avec un horodatage', async () => {
    // core_kosmos user_firestore_controller.dart:34-37 (setOnline)
    await assertSucceeds(updateDoc(userRef(), { online: true, lastOnline: null }));
    await assertSucceeds(updateDoc(userRef(), { online: false, lastOnline: serverTimestamp() }));
  });

  it('téléphone à null et retrait d\'un champ de la liste blanche', async () => {
    await assertSucceeds(updateDoc(userRef(), { phone: null, phoneNumber: null }));
    await assertSucceeds(updateDoc(userRef(), { phone: deleteField() }));
  });

  it('une valeur hors norme déjà enregistrée ne bloque pas la mise à jour d\'un autre champ', async () => {
    await seed({ teamName: text(150) });
    await assertSucceeds(updateDoc(userRef(), { online: true, lastOnline: null }));
  });
});

describe('users/{uid} — formes refusées', () => {
  beforeEach(() => seed());

  const refused = [
    ['coachName numérique', { coachName: 42 }],
    ['coachName de 101 caractères', { coachName: text(101) }],
    ['teamName de 101 caractères', { teamName: text(101) }],
    ['teamName en carte', { teamName: { a: 1 } }],
    ['category de 31 caractères', { category: text(31) }],
    ['division null', { division: null }],
    ['email de 255 caractères', { email: `${text(245)}@club.test` }],
    ['email null', { email: null }],
    ['cguAccepted en chaîne', { cguAccepted: 'true' }],
    ['cguAcceptedDate en chaîne', { cguAcceptedDate: '2026-10-15' }],
    ['online en nombre', { online: 1 }],
    ['lastOnline en chaîne', { lastOnline: 'hier' }],
    ['phone de 33 caractères', { phone: text(33) }],
    ['phoneNumber en chaîne', { phoneNumber: '+33600000000' }],
    ['phoneNumber avec une clé inconnue', { phoneNumber: { phoneNumber: '+33600000000', extra: true } }],
    ['phoneNumber.isoCode trop long', { phoneNumber: { phoneNumber: '+33600000000', isoCode: text(9) } }],
  ];
  for (const [label, data] of refused) {
    it(label, async () => {
      await assertFails(updateDoc(userRef(), data));
    });
  }
});

describe('users/{uid}/metadata/security — formes', () => {
  beforeEach(() => seed());

  it('accepte profilCompleted et les CGU sous leur forme réelle', async () => {
    // coach_profile_repository.dart:131-133 ; skeleton user_controller.dart:171-179 (acceptCgu)
    await assertSucceeds(updateDoc(securityRef(), { profilCompleted: true }));
    await assertSucceeds(updateDoc(securityRef(), { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));
  });

  for (const [label, data] of [
    ['profilCompleted en chaîne', { profilCompleted: 'true' }],
    ['cguAccepted en nombre', { cguAccepted: 1 }],
    ['cguAcceptedDate en nombre', { cguAcceptedDate: 1760000000 }],
  ]) {
    it(`refuse ${label}`, async () => {
      await assertFails(updateDoc(securityRef(), data));
    });
  }
});

describe('users/{uid}/metadata/metadata — formes', () => {
  beforeEach(() => seed());

  it('accepte le jeton FCM, null, et les drapeaux de notification', async () => {
    // core_kosmos notif_controller.dart:43-53 et 244-252, user_provider.dart:152-160
    await assertSucceeds(updateDoc(metadataRef(), { fcmToken: text(4096), authorized_push_notif_3: true }));
    await assertSucceeds(updateDoc(metadataRef(), { fcmToken: null, enablePushNotification: false, authorized_push_notif_8: false }));
    await assertSucceeds(updateDoc(metadataRef(), { enableEmailNotification: true, permissionLaunched: true }));
  });

  it('accepte la création par set merge de l\'écran Permission', async () => {
    await testEnv.clearFirestore();
    await assertSucceeds(
      setDoc(metadataRef(), { enablePushNotification: true, fcmToken: 'fcm-token', authorized_push_notif_1: true }, { merge: true }),
    );
  });

  for (const [label, data] of [
    ['fcmToken de 4097 caractères', { fcmToken: text(4097) }],
    ['fcmToken numérique', { fcmToken: 123 }],
    ['enablePushNotification en chaîne', { enablePushNotification: 'true' }],
    ['permissionLaunched en nombre', { permissionLaunched: 1 }],
    ['authorized_push_notif_9 en chaîne', { authorized_push_notif_9: 'false' }],
    ['createdAt en chaîne', { createdAt: '2026-10-15' }],
  ]) {
    it(`refuse ${label}`, async () => {
      await assertFails(updateDoc(metadataRef(), data));
    });
  }

  it('refuse une création dont un champ a le mauvais type', async () => {
    await testEnv.clearFirestore();
    await assertFails(setDoc(metadataRef(), { enablePushNotification: 'oui' }, { merge: true }));
    await assertFails(setDoc(metadataRef(), { fcmToken: 42 }));
  });
});
