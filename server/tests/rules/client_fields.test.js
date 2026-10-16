/**
 * Règles Firestore — listes blanches de champs écrits par le CLIENT sur
 * users/{uid} (document racine) et users/{uid}/metadata/security.
 *
 * Le serveur et le back-office se fient aux autres champs : `lastVerifEmailAt` (délai entre deux
 * e-mails de vérification), `email`/`firstname` posés par createCoach, `disabled`/`userType`
 * (affichés par le back-office), `invitedByAdmin` (pas d'e-mail de bienvenue), `teamFormat` et
 * `playerCount` (effectif) : le client ne peut ni les écrire ni les retirer.
 *
 * Les écritures AUTORISÉES ci-dessous viennent de l'inventaire des écritures des clients (app,
 * paquets du socle), chacune avec sa source.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const UID = 'coach-alice';
const OTHER_UID = 'coach-bob';
const PORT = Number(process.env.FIRESTORE_EMULATOR_PORT || 8080);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-wina',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: PORT,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

const db = (uid = UID) => testEnv.authenticatedContext(uid).firestore();
const userRef = (uid = UID) => doc(db(uid), `users/${uid}`);
const securityRef = (uid = UID) => doc(db(uid), `users/${uid}/metadata/security`);

/** Fiche et document de sécurité tels que les crée createCoach (Admin SDK). */
async function seedCoach() {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${UID}`), {
      id: UID,
      email: 'a@club.test',
      firstname: 'Alice',
      userType: 'client',
      invitedByAdmin: true,
      createdByAdmin: 'admin1',
      cguAccepted: false,
      profilCompleted: false,
      disabled: false,
      teamFormat: 8,
      playerCount: 3,
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(ctx.firestore(), `users/${UID}/metadata/security`), {
      email: 'a@club.test',
      profilCompleted: false,
      cguAccepted: false,
      isFirstLogin: true,
      lastVerifEmailAt: Timestamp.now(), // posé par sendEmailVerification (serveur)
      createdAt: Timestamp.now(),
    });
  });
}

/** Seul le compte `UID` existe : ni sa fiche ni son document de sécurité. */
async function seedNothing() {
  await testEnv.clearFirestore();
}

describe('users/{uid} — écritures légitimes de l\'app (chacune a une source)', () => {
  beforeEach(seedCoach);

  it('écran « Finalisez votre profil » : set merge de coachName, teamName, category, division', async () => {
    // app/lib/data/coach_profile_repository.dart:24 (saveTeamInfo)
    await assertSucceeds(
      setDoc(
        userRef(),
        { coachName: 'Zidane', teamName: 'FC Wina', category: 'u13', division: 'd2' },
        { merge: true },
      ),
    );
  });

  it('réglages : changement d\'e-mail, update({email})', async () => {
    // app/lib/view/page/settings/settings_page.dart:586
    await assertSucceeds(updateDoc(userRef(), { email: 'nouveau@club.test' }));
  });

  it('CGU : update({cguAccepted, cguAcceptedDate}) avec un Timestamp côté client', async () => {
    // packages/skeleton/lib/controller/user_controller.dart:158 (acceptCgu)
    await assertSucceeds(updateDoc(userRef(), { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));
  });

  it('présence : update({online: false, lastOnline: serverTimestamp()})', async () => {
    // core_kosmos user_firestore_controller.dart:34 (setOnline), appelé à chaque
    // changement de cycle de vie : un refus serait avalé en silence.
    await assertSucceeds(updateDoc(userRef(), { online: false, lastOnline: serverTimestamp() }));
    await assertSucceeds(updateDoc(userRef(), { online: true, lastOnline: null }));
  });

  it('ajout du téléphone : update({phone, phoneNumber}) (flux du socle, écrans non routés aujourd\'hui)', async () => {
    // packages/skeleton/lib/view/page/auth/set_phone_page.dart:398-408 (carte de PhoneNumberConverter)
    await assertSucceeds(
      updateDoc(userRef(), {
        phone: '+33600000000',
        phoneNumber: { phoneNumber: '+33600000000', isoCode: 'FR', dialCode: '+33' },
      }),
    );
  });

  it('un set() sans merge qui conserve tous les champs reste accepté', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${UID}`), {
        id: UID,
        email: 'a@club.test',
        teamFormat: 8,
        playerCount: 3,
      });
    });
    await assertSucceeds(
      setDoc(userRef(), { id: UID, email: 'a@club.test', teamFormat: 8, playerCount: 3, coachName: 'Zidane' }),
    );
  });
});

describe('users/{uid} — ce que le client ne doit plus pouvoir écrire', () => {
  beforeEach(seedCoach);

  // Chaque champ est lu par le serveur ou le back-office comme une donnée fiable.
  for (const [field, value] of [
    ['userType', 'admin'],
    ['disabled', true],
    ['invitedByAdmin', false], // ferait envoyer le mail de bienvenue
    ['createdByAdmin', 'quelquun'],
    ['lastInviteSentAt', Timestamp.now()],
    ['profilCompleted', true], // recopié depuis metadata/security par un trigger serveur
    ['firstname', '<a href="https://evil.test">cliquez ici</a>'],
    ['lastname', 'X'],
    ['id', 'autre'],
    ['createdAt', Timestamp.now()],
    ['teamFormat', 11],
    ['playerCount', 0], // réservé aux callables createPlayer / deletePlayer (plafond d'effectif)
    ['admin', true],
    ['isAdmin', true],
  ]) {
    it(`refuse d'écrire « ${field} »`, async () => {
      await assertFails(updateDoc(userRef(), { [field]: value }));
    });
  }

  it('refuse un champ interdit mélangé à des champs légitimes', async () => {
    await assertFails(updateDoc(userRef(), { coachName: 'Zidane', userType: 'admin' }));
  });

  it('refuse de bouger le compteur d\'effectif, même d\'une unité (ancien +/-1 du client)', async () => {
    await assertFails(updateDoc(userRef(), { playerCount: increment(1) }));
    await assertFails(updateDoc(userRef(), { playerCount: increment(-1) }));
    await assertFails(setDoc(userRef(), { playerCount: 0 }, { merge: true }));
  });

  it('refuse un set merge qui ajoute un champ interdit', async () => {
    await assertFails(setDoc(userRef(), { disabled: true }, { merge: true }));
  });

  it('refuse de retirer un champ serveur (deleteField)', async () => {
    await assertFails(updateDoc(userRef(), { createdByAdmin: deleteField() }));
  });

  it('refuse un set() sans merge qui réécrit la fiche sans ses champs serveur', async () => {
    await assertFails(setDoc(userRef(), { id: UID, email: 'a@club.test', teamFormat: 8, playerCount: 3 }));
  });

  it('refuse la suppression de la fiche', async () => {
    await assertFails(deleteDoc(userRef()));
  });

  it('refuse à un autre coach d\'écrire cette fiche', async () => {
    await assertFails(updateDoc(doc(db(OTHER_UID), `users/${UID}`), { coachName: 'Pirate' }));
  });
});

describe('users/{uid} — création de la fiche par le client', () => {
  beforeEach(seedNothing);

  // La fiche est créée par createCoach ou par createPlayer (Admin SDK) : plus jamais par le client.
  // Avant, { playerCount: 1 } passait pour le premier joueur d'un compte sans fiche.
  it('refuse toute création, y compris { playerCount: 1 } (ancien premier joueur)', async () => {
    await assertFails(setDoc(userRef(), { playerCount: increment(1) }, { merge: true }));
    await assertFails(setDoc(userRef(), { playerCount: 1 }));
  });

  it('refuse un playerCount négatif (annulerait le plafond d\'effectif)', async () => {
    await assertFails(setDoc(userRef(), { playerCount: -1000000 }));
  });

  it('refuse une fiche créée avec d\'autres champs (userType, email, invitedByAdmin...)', async () => {
    await assertFails(setDoc(userRef(), { playerCount: 1, userType: 'client' }));
    await assertFails(setDoc(userRef(), { email: 'victime@club.test', firstname: 'X' }));
    await assertFails(setDoc(userRef(), { invitedByAdmin: true }));
  });

  // Parcours qui n'existe pas : un compte sans fiche est renvoyé à l'écran de
  // connexion avant d'atteindre « Finalisez votre profil » (UserProvider.init).
  it('refuse saveTeamInfo (set merge) sur un document absent', async () => {
    await assertFails(
      setDoc(userRef(), { coachName: 'Zidane', teamName: 'FC Wina', category: 'u13', division: 'd2' }, { merge: true }),
    );
  });

  it('refuse de créer la fiche d\'un autre', async () => {
    await assertFails(setDoc(doc(db(OTHER_UID), `users/${UID}`), { playerCount: 1 }));
  });
});

/** Fiche, sécurité et métadonnées EXACTEMENT comme create_coach.ts les crée :
 * ni playerCount, ni lastVerifEmailAt, ni fcmToken. */
async function seedFreshCoach() {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, `users/${UID}`), {
      id: UID,
      email: 'a@club.test',
      firstname: 'Alice',
      userType: 'client',
      createdAt: Timestamp.now(),
      createdByAdmin: 'admin1',
      invitedByAdmin: true,
      cguAccepted: false,
      profilCompleted: false,
      disabled: false,
      teamFormat: 8,
    });
    await setDoc(doc(fs, `users/${UID}/metadata/security`), {
      email: 'a@club.test',
      profilCompleted: false,
      cguAccepted: false,
      isFirstLogin: true,
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(fs, `users/${UID}/metadata/metadata`), {
      cguAccepted: false,
      enablePushNotification: false,
      enableEmailNotification: false,
      createdAt: Timestamp.now(),
    });
  });
}

describe('premier login d\'un coach créé par createCoach — la séquence réelle de l\'app', () => {
  beforeEach(seedFreshCoach);

  it('enchaîne présence, CGU, profil, effectif, e-mail et déconnexion sans aucun refus', async () => {
    const d = db();
    const metadataRef = doc(d, `users/${UID}/metadata/metadata`);

    // core_kosmos setOnline, au démarrage
    await assertSucceeds(updateDoc(userRef(), { online: true, lastOnline: null }));

    // UserController.acceptCgu : fiche, metadata/metadata puis metadata/security
    await assertSucceeds(updateDoc(userRef(), { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));
    await assertSucceeds(updateDoc(metadataRef, { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));
    await assertSucceeds(updateDoc(securityRef(), { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));

    // CoachProfileRepository.saveTeamInfo, à la création puis en mode édition
    const team = { coachName: 'Zidane', teamName: 'FC Wina', category: 'u13', division: 'd2' };
    await assertSucceeds(setDoc(userRef(), team, { merge: true }));
    await assertSucceeds(setDoc(userRef(), team, { merge: true }));

    // CoachProfileRepository.markProfilCompleted
    await assertSucceeds(updateDoc(securityRef(), { profilCompleted: true }));

    // L'effectif (PlayerRepository.addPlayer / deletePlayer) passe par les callables
    // createPlayer / deletePlayer : plus aucune écriture client sur players ni sur playerCount.

    // Réglages : changement d'e-mail ; déconnexion : fcmToken remis à null
    await assertSucceeds(updateDoc(userRef(), { email: 'nouveau@club.test' }));
    await assertSucceeds(updateDoc(metadataRef, { fcmToken: null }));
  });
});

describe('users/{uid}/metadata/security — écritures légitimes', () => {
  beforeEach(seedCoach);

  it('markProfilCompleted : update({profilCompleted: true})', async () => {
    // app/lib/data/coach_profile_repository.dart:131
    await assertSucceeds(updateDoc(securityRef(), { profilCompleted: true }));
  });

  it('acceptation des CGU : update({cguAccepted, cguAcceptedDate})', async () => {
    // packages/skeleton/lib/controller/user_controller.dart:171
    await assertSucceeds(updateDoc(securityRef(), { cguAccepted: true, cguAcceptedDate: Timestamp.now() }));
  });

  it('lecture par le propriétaire', async () => {
    await assertSucceeds(getDoc(securityRef()));
  });
});

describe('users/{uid}/metadata/security — ce que le client ne doit plus pouvoir écrire', () => {
  beforeEach(seedCoach);

  it('refuse de réécrire lastVerifEmailAt (anti-rejeu de sendEmailVerification)', async () => {
    await assertFails(updateDoc(securityRef(), { lastVerifEmailAt: Timestamp.fromMillis(0) }));
  });

  it('refuse de supprimer lastVerifEmailAt', async () => {
    await assertFails(updateDoc(securityRef(), { lastVerifEmailAt: deleteField() }));
  });

  // Les valeurs diffèrent de celles du document seedé : écrire une valeur
  // identique ne change aucune clé et serait accepté sans que ce soit un test.
  for (const [field, value] of [
    ['isFirstLogin', false],
    ['email', 'autre@club.test'],
    ['phone', '+33600000000'],
    ['enableBiometricLogin', true],
    ['lastPasswordUpdate', Timestamp.now()],
    ['whatever', true],
  ]) {
    it(`refuse d'écrire « ${field} »`, async () => {
      await assertFails(updateDoc(securityRef(), { [field]: value }));
    });
  }

  it('refuse un champ interdit mélangé à un champ légitime', async () => {
    await assertFails(updateDoc(securityRef(), { profilCompleted: true, lastVerifEmailAt: Timestamp.fromMillis(0) }));
  });

  it('refuse de supprimer le document', async () => {
    await assertFails(deleteDoc(securityRef()));
  });

  it('refuse de le créer (createCoach le crée côté serveur)', async () => {
    await seedNothing();
    await assertFails(setDoc(securityRef(), { profilCompleted: true }));
  });

  it('refuse à un autre coach de l\'écrire', async () => {
    await assertFails(updateDoc(doc(db(OTHER_UID), `users/${UID}/metadata/security`), { profilCompleted: true }));
  });

  it('refuse une écriture non authentifiée', async () => {
    const anonymous = testEnv.unauthenticatedContext().firestore();
    await assertFails(updateDoc(doc(anonymous, `users/${UID}/metadata/security`), { profilCompleted: true }));
  });
});
