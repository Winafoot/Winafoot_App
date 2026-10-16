/**
 * Règles Firestore — users/{uid}.teamFormat (format du club : 5, 8 ou 11).
 *
 * Le champ fixe le plafond d'effectif et n'est posé que par le callable
 * createCoach (Admin SDK, qui contourne les règles). Le coach, propriétaire du
 * document, ne doit pouvoir ni le créer, ni le modifier, ni le supprimer — sans
 * quoi il relèverait lui-même son plafond — tout en gardant les écritures
 * légitimes de l'app sur sa propre fiche.
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
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const UID = 'coach-alice';
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

/** Fiche coach telle que la crée createCoach ; `format` null = compte existant
 * sans teamFormat. */
async function seedCoach(format = 8) {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${UID}`), {
      id: UID,
      email: 'a@club.test',
      userType: 'client',
      invitedByAdmin: true,
      profilCompleted: false,
      playerCount: 3,
      ...(format === null ? {} : { teamFormat: format }),
    });
  });
}

function coachDb() {
  return testEnv.authenticatedContext(UID).firestore();
}

describe('users/{uid}.teamFormat — immuable pour le coach', () => {
  beforeEach(() => seedCoach());

  it('refuse de le modifier (set merge)', async () => {
    await assertFails(setDoc(doc(coachDb(), `users/${UID}`), { teamFormat: 11 }, { merge: true }));
  });

  it('refuse de le modifier (update)', async () => {
    await assertFails(updateDoc(doc(coachDb(), `users/${UID}`), { teamFormat: 11 }));
  });

  it('refuse de le retirer (deleteField)', async () => {
    await assertFails(updateDoc(doc(coachDb(), `users/${UID}`), { teamFormat: deleteField() }));
  });

  it('refuse un set() sans merge qui réécrit la fiche sans lui', async () => {
    // Un set() sans merge remplace tout le document : le champ disparaît.
    await assertFails(setDoc(doc(coachDb(), `users/${UID}`), { email: 'a@club.test', playerCount: 3 }));
  });

  it('refuse de le retirer en mélangeant des champs légitimes', async () => {
    await assertFails(
      updateDoc(doc(coachDb(), `users/${UID}`), { coachName: 'Zizou', teamFormat: deleteField() }),
    );
  });

  it('refuse d\'ajouter le champ à une fiche qui n\'en a pas', async () => {
    await seedCoach(null);
    await assertFails(setDoc(doc(coachDb(), `users/${UID}`), { teamFormat: 5 }, { merge: true }));
  });

  it('refuse de créer la fiche avec le champ', async () => {
    await testEnv.clearFirestore();
    await assertFails(setDoc(doc(coachDb(), `users/${UID}`), { playerCount: 1, teamFormat: 5 }));
  });

  it('refuse la suppression de la fiche', async () => {
    await assertFails(deleteDoc(doc(coachDb(), `users/${UID}`)));
  });
});

describe('users/{uid} — écritures légitimes de l\'app, teamFormat présent', () => {
  beforeEach(() => seedCoach());

  it('création de la fiche par le client : refusée (le premier joueur passe par le callable createPlayer)', async () => {
    await testEnv.clearFirestore();
    await assertFails(setDoc(doc(coachDb(), `users/${UID}`), { playerCount: 1 }, { merge: true }));
  });

  it('CoachProfileRepository.saveTeamInfo : set merge des quatre champs de profil', async () => {
    await assertSucceeds(
      setDoc(
        doc(coachDb(), `users/${UID}`),
        { coachName: 'Zinedine Zidane', teamName: 'FC Wina', category: 'u13', division: 'r1' },
        { merge: true },
      ),
    );
  });

  it('changement d\'e-mail des réglages : update({email})', async () => {
    await assertSucceeds(updateDoc(doc(coachDb(), `users/${UID}`), { email: 'b@club.test' }));
  });

  it('acceptation des CGU : update({cguAccepted, cguAcceptedDate})', async () => {
    await assertSucceeds(
      updateDoc(doc(coachDb(), `users/${UID}`), {
        cguAccepted: true,
        cguAcceptedDate: Timestamp.now(),
      }),
    );
  });

  it('ajout du téléphone : update({phone, phoneNumber})', async () => {
    await assertSucceeds(
      updateDoc(doc(coachDb(), `users/${UID}`), {
        phone: '+33612345678',
        phoneNumber: { phoneNumber: '+33612345678', isoCode: 'FR', dialCode: '+33' },
      }),
    );
  });

  // Un set() sans merge qui supprimerait des champs posés par le serveur
  // (userType, invitedByAdmin...) est refusé : voir client_fields.test.js.
  it('set() sans merge qui conserve le même teamFormat et les champs serveur', async () => {
    await assertSucceeds(
      setDoc(doc(coachDb(), `users/${UID}`), {
        id: UID,
        email: 'a@club.test',
        userType: 'client',
        invitedByAdmin: true,
        profilCompleted: false,
        playerCount: 3,
        teamFormat: 8,
      }),
    );
  });
});
