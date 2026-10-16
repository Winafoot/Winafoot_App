/**
 * Règles Firestore — documents réels relevés en ligne sur les comptes de test (matchs,
 * compositions, maillots), tels que l'app les a écrits. Ils doivent passer le validateur de contenu
 * tels quels : c'est la preuve que les listes de clés et les bornes de firestore.rules n'écartent
 * aucun document que l'app produit réellement. Identifiants de joueurs conservés (identifiants
 * Firestore aléatoires, sans donnée personnelle).
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, doc, setDoc, updateDoc } from 'firebase/firestore';

const UID = 'coach-reel';
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
const at = (iso) => Timestamp.fromDate(new Date(iso));

const SLOTS_2_1_1 = [
  { role: 'gardien', x: 0.5, y: 0.9 },
  { role: 'defenseur', x: 0.14, y: 0.72 },
  { role: 'defenseur', x: 0.86, y: 0.72 },
  { role: 'milieu', x: 0.5, y: 0.45999999999999996 },
  { role: 'attaquant', x: 0.5, y: 0.19999999999999996 },
];
const COMPOSITION_REELLE = {
  assignments: ['pYYpaGyMpcAQNNjPtyz2', 'ulPZp2OqRWjlDDxH6WaO', 'CgTcGW34X43opXCsWanl', 'VqmYDXOYHvgfNioMdDXc', 'rJ0pu0ErFeOCrXYkRywX'],
  captainId: 'ulPZp2OqRWjlDDxH6WaO',
  formationLabel: '2-1-1',
  name: null,
  numbers: {
    '8HVT58yWeijjVPXIlCUo': 7, BmwQ5RBpJ79F3JjCi9LN: 10, CgTcGW34X43opXCsWanl: 5, OfVStjmUsDzOMnhXKfeO: 8,
    T03GRcOYtXfcH9iMCBQV: 6, VqmYDXOYHvgfNioMdDXc: 3, cjbZarw4fRHmvJm4K1hr: 33, pYYpaGyMpcAQNNjPtyz2: 1,
    rJ0pu0ErFeOCrXYkRywX: 2, ulPZp2OqRWjlDDxH6WaO: 4,
  },
  playerCount: 5,
  slots: SLOTS_2_1_1,
  substituteIds: ['BmwQ5RBpJ79F3JjCi9LN', 'cjbZarw4fRHmvJm4K1hr', '8HVT58yWeijjVPXIlCUo', 'T03GRcOYtXfcH9iMCBQV', 'OfVStjmUsDzOMnhXKfeO'],
};
const STATS_ACTIVEES = [
  'interceptions', 'recuperations', 'passesManquees', 'totalPasses', 'pourcentagePasses', 'pertesBallons', 'tirsCadres',
  'tirsNonCadres', 'tirsSubisHors', 'tirsSubisDans', 'totalTirsSubis', 'controleReussi', 'controleManque', 'coupsFrancsSubis',
  'penaltysCrees', 'coupsFrancsCrees', 'nombreTouches', 'nombreCentres', 'passesProfondeur', 'duelsDefGagnes',
  'duelsDefPerdus', 'duelsOffGagnes', 'duelsOffPerdus', 'degagements', 'fautesCommises', 'fautesSubies', 'cartonsJaunes',
  'cartonsRouges', 'butsSubis', 'butsMarques',
];

describe('documents réels de production, tels que l\'app les a écrits', () => {
  it('match TERMINÉ avec composition, statistiques par joueur et durée', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/matches/4X453Nl2NEJXG4z7ZoAl`), {
        composition: COMPOSITION_REELLE,
        createdAt: at('2026-09-21T08:27:05.617Z'),
        elapsedSeconds: 227,
        enabledStatKeys: STATS_ACTIVEES,
        finishedAt: at('2026-09-21T08:36:25.551Z'),
        opponent: { category: 'u19', division: 'd2', jerseyColor: 'gris', name: 'FC test' },
        ownJersey: { color: 'rouge', name: 'Domicile' },
        playerStats: {
          VqmYDXOYHvgfNioMdDXc: { cartonsJaunes: 2, cartonsRouges: 1, interceptions: 1, passesManquees: 1, recuperations: 1, tirsCadres: 1, tirsSubisDans: 0, tirsSubisHors: 1 },
          rJ0pu0ErFeOCrXYkRywX: { butsMarques: 2, butsSubis: 1 },
        },
        scoreThem: 1,
        scoreUs: 2,
        status: 'finished',
        updatedAt: at('2026-09-21T08:31:32.260Z'),
      }),
    );
  });

  it('match ABANDONNÉ, statistiques vides', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/matches/2rTE4vNpoBOzNfQYW9ta`), {
        composition: COMPOSITION_REELLE,
        createdAt: at('2026-09-21T13:10:43.750Z'),
        enabledStatKeys: [...STATS_ACTIVEES, 'duelsAeriensPerdus'],
        opponent: { category: 'u19', division: 'd2', jerseyColor: 'bleu', name: 'RecetteLotA' },
        ownJersey: { color: 'rouge', name: 'Domicile' },
        status: 'abandoned',
        updatedAt: at('2026-09-21T13:15:56.900Z'),
      }),
    );
  });

  it('match BROUILLON sans composition (écrit par l\'émulateur de test le 01/10)', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/matches/bFbSSllf3PrzxCLmxRNp`), {
        composition: null,
        createdAt: at('2026-10-01T11:25:54.946Z'),
        enabledStatKeys: [],
        opponent: { category: 'u17', division: 'd3', jerseyColor: 'vert', name: 'Test' },
        ownJersey: { color: 'jaune', name: 'TEst' },
        status: 'draft',
        updatedAt: at('2026-10-01T11:25:54.946Z'),
      }),
    );
  });

  it('composition personnalisée avec coordonnées décimales issues d\'un placement à la main', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/compositions/V4KyCxTMIrogExqycSfO`), {
        createdAt: at('2026-09-21T08:58:32.410Z'),
        formationLabel: '4-3-3',
        isFavorite: false,
        name: 'Offensive (copie)',
        playerCount: 11,
        slots: [
          { role: 'gardien', x: 0.5, y: 0.9 },
          { role: 'defenseur', x: 0.2038276143790855, y: 0.829507257873314 },
          { role: 'defenseur', x: 0.3766809640522876, y: 0.8637805217878606 },
          { role: 'defenseur', x: 0.6101705473856209, y: 0.8752185066211369 },
          { role: 'defenseur', x: 0.7945128676470588, y: 0.8592107532659219 },
          { role: 'milieu', x: 0.30505821078431355, y: 0.49878730355207407 },
          { role: 'milieu', x: 0.5, y: 0.45999999999999996 },
          { role: 'milieu', x: 0.6819209558823536, y: 0.4975612680949685 },
          { role: 'attaquant', x: 0.22157169117647063, y: 0.19086046295612047 },
          { role: 'attaquant', x: 0.49348958333333354, y: 0.29826551055933304 },
          { role: 'attaquant', x: 0.774981617647059, y: 0.19425992490536834 },
        ],
        type: 'custom',
      }),
    );
  });

  it('composition favorite avec updatedAt', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/compositions/27JPOLT9kNwemNPq99I5`), {
        createdAt: at('2026-09-18T14:26:22.840Z'),
        formationLabel: '3-5-2',
        isFavorite: true,
        name: 'Bloc compact',
        playerCount: 11,
        slots: SLOTS_2_1_1,
        type: 'custom',
        updatedAt: at('2026-09-18T14:26:46.937Z'),
      }),
    );
  });

  it('maillot', async () => {
    await assertSucceeds(
      setDoc(doc(db(), `users/${UID}/jerseys/Kl15Y3fmac4RZuC07Gxo`), {
        color: 'jaune',
        createdAt: at('2026-10-01T11:25:42.995Z'),
        name: 'TEst',
        order: 0,
      }),
    );
  });
});

/**
 * Fiches des comptes de test relevées en ligne le 15/10/2026 (types et présence des champs
 * seulement, valeurs remplacées) : chaque champ de la liste blanche, réécrit par son propriétaire
 * sous la forme relevée, passe les contrôles de type et de taille. Le relevé complet (4 fiches,
 * 4 documents metadata/security, 4 documents metadata/metadata) ne trouve aucune valeur hors norme.
 */
describe('fiches réelles : formes relevées en ligne, réécrites par leur propriétaire', () => {
  before(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, `users/${UID}`), { id: UID, email: 'coach@club.test', userType: 'client', teamFormat: 11 });
      await setDoc(doc(fs, `users/${UID}/metadata/security`), { email: 'coach@club.test', profilCompleted: false });
      await setDoc(doc(fs, `users/${UID}/metadata/metadata`), { createdAt: at('2026-09-18T14:00:00Z') });
    });
  });

  it('users/{uid} : textes, e-mail, CGU, présence (lastOnline null) et téléphone', async () => {
    await assertSucceeds(
      updateDoc(doc(db(), `users/${UID}`), {
        category: 'u13',
        cguAccepted: true,
        cguAcceptedDate: at('2026-09-18T14:26:22.840Z'),
        coachName: 'Nom du coach',
        division: 'd2',
        email: 'coach@club.test',
        lastOnline: null,
        online: true,
        phone: '+33600000000',
        teamName: 'Nom de l\'équipe',
      }),
    );
  });

  it('metadata/security : profil complété et CGU', async () => {
    await assertSucceeds(
      updateDoc(doc(db(), `users/${UID}/metadata/security`), {
        cguAccepted: true,
        cguAcceptedDate: at('2026-09-18T14:26:22.840Z'),
        profilCompleted: true,
      }),
    );
  });

  it('metadata/metadata : notifications, jeton null, drapeaux et CGU', async () => {
    await assertSucceeds(
      updateDoc(doc(db(), `users/${UID}/metadata/metadata`), {
        authorized_push_notif_1: true,
        authorized_push_notif_3: true,
        authorized_push_notif_5: true,
        cguAccepted: true,
        cguAcceptedDate: at('2026-09-18T14:26:22.840Z'),
        enableEmailNotification: false,
        enablePushNotification: false,
        fcmToken: null,
        permissionLaunched: true,
      }),
    );
  });
});
