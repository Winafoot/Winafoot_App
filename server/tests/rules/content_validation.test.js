/**
 * Règles Firestore — validation du contenu écrit par le CLIENT : joueurs (mise à jour), matchs,
 * compositions personnalisées, maillots. Chaque sous-collection n'accepte que les champs du modèle
 * de l'app, avec leur type et leur taille.
 *
 * Les écritures AUTORISÉES ci-dessous reproduisent ce que l'app envoie réellement, chacune avec
 * sa source (app/lib/...). Si l'app ajoute un champ à l'un de ces modèles, la règle doit
 * suivre : le test « écritures légitimes » correspondant l'indiquera.
 */

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
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
const sub = (name, id, uid = UID) => doc(db(uid), `users/${UID}/${name}/${id}`);

async function seed(path, data) {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${UID}`), { id: UID, email: 'a@club.test', teamFormat: 11, playerCount: 1 });
    if (path) await setDoc(doc(ctx.firestore(), path), data);
  });
}

const rep = (n, v = 'x') => Array.from({ length: n }, () => v);
const repMap = (n, v) => Object.fromEntries(Array.from({ length: n }, (_, i) => [`k${i}`, v]));

// ------------------------------------------------------------------ joueurs

const PLAYER = { firstName: 'Karim', lastName: 'Benzema', strongFoot: 'droit', position: 'attaquant' };

describe('players/{id} — mise à jour (PlayerRepository.updatePlayer = Player.toJson)', () => {
  beforeEach(() => seed(`users/${UID}/players/p0`, { ...PLAYER, order: 0 }));

  it('accepte les quatre champs du modèle', async () => {
    await assertSucceeds(updateDoc(sub('players', 'p0'), PLAYER));
  });

  it('refuse un champ inconnu', async () => {
    await assertFails(updateDoc(sub('players', 'p0'), { ...PLAYER, isAdmin: true }));
  });

  it('refuse de toucher à order ou createdAt (posés par le serveur)', async () => {
    await assertFails(updateDoc(sub('players', 'p0'), { order: 99 }));
    await assertFails(updateDoc(sub('players', 'p0'), { createdAt: serverTimestamp() }));
  });

  it('refuse un nom trop long ou d\'un autre type', async () => {
    await assertFails(updateDoc(sub('players', 'p0'), { lastName: 'x'.repeat(61) }));
    await assertFails(updateDoc(sub('players', 'p0'), { firstName: 12 }));
    await assertFails(updateDoc(sub('players', 'p0'), { position: { a: 1 } }));
  });
});

// -------------------------------------------------------------------- matchs

/** GameMatch.toJson (game_match.dart:255) + les horodatages de MatchRepository.saveDraft. */
const OPPONENT = { name: 'FC Voisin', category: 'u13', division: 'd2', jerseyColor: 'rouge' };
const COMPOSITION = {
  formationLabel: '4-4-2',
  playerCount: 11,
  slots: [{ role: 'gardien', x: 0.5, y: 0.9 }, { role: 'defenseur', x: 0.2, y: 0.7 }],
  assignments: ['p0', null],
  numbers: { p0: 1 },
  captainId: null,
  substituteIds: ['p5'],
  name: null,
};
const draft = () => ({
  opponent: OPPONENT,
  ownJersey: { name: 'Domicile', color: 'bleu' },
  composition: COMPOSITION,
  compositions: [COMPOSITION],
  enabledStatKeys: ['goal', 'assist'],
  status: 'draft',
  updatedAt: serverTimestamp(),
  createdAt: serverTimestamp(),
});

/** MatchRepository.finishedPayload (match_repository.dart:84) + finishedAt. */
const finished = () => ({
  status: 'finished',
  scoreUs: 3,
  scoreThem: 2,
  elapsedSeconds: 3600,
  playerStats: { p0: { goal: 2, assist: 1 }, p5: { goal: 1 } },
  enabledStatKeys: ['goal', 'assist'],
  half: 2,
  firstHalfStats: { p0: { goal: 1 } },
  firstHalfStatKeys: ['goal'],
  finishedAt: serverTimestamp(),
});

describe('matches/{id} — écritures légitimes de l\'app', () => {
  beforeEach(() => seed());

  it('saveDraft : création d\'un brouillon (add)', async () => {
    await assertSucceeds(addDoc(collection(db(), `users/${UID}/matches`), draft()));
  });

  it('saveDraft : brouillon minimal, adversaire sans catégorie ni couleur, sans composition', async () => {
    await assertSucceeds(
      addDoc(collection(db(), `users/${UID}/matches`), {
        opponent: { name: '', category: null, division: null, jerseyColor: null },
        ownJersey: null,
        composition: null,
        enabledStatKeys: [],
        status: 'draft',
        updatedAt: serverTimestamp(),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('saveDraft : mise à jour (set merge) d\'un brouillon existant', async () => {
    await seed(`users/${UID}/matches/m1`, { opponent: OPPONENT, status: 'draft' });
    await assertSucceeds(setDoc(sub('matches', 'm1'), draft(), { merge: true }));
  });

  it('finishMatch : score, statistiques et mi-temps (set merge)', async () => {
    await seed(`users/${UID}/matches/m1`, { opponent: OPPONENT, status: 'draft', enabledStatKeys: ['goal'] });
    await assertSucceeds(setDoc(sub('matches', 'm1'), finished(), { merge: true }));
  });

  it('suppression d\'un match depuis l\'historique', async () => {
    await seed(`users/${UID}/matches/m1`, { status: 'finished' });
    await assertSucceeds(deleteDoc(sub('matches', 'm1')));
  });

  it('lecture par le propriétaire uniquement', async () => {
    await seed(`users/${UID}/matches/m1`, { status: 'finished' });
    await assertSucceeds(getDoc(sub('matches', 'm1')));
    await assertFails(getDoc(sub('matches', 'm1', OTHER_UID)));
  });
});

describe('matches/{id} — contenu refusé', () => {
  beforeEach(() => seed());
  const create = (data) => addDoc(collection(db(), `users/${UID}/matches`), data);

  it('un champ inconnu à la racine', async () => {
    await assertFails(create({ ...draft(), isAdmin: true }));
    await assertFails(create({ ...draft(), blob: 'x'.repeat(1000) }));
  });

  it('un score, une durée ou une mi-temps hors bornes ou d\'un autre type', async () => {
    await assertFails(create({ ...draft(), ...finished(), scoreUs: '3' }));
    await assertFails(create({ ...draft(), ...finished(), scoreUs: 1000 }));
    await assertFails(create({ ...draft(), ...finished(), scoreThem: -1 }));
    await assertFails(create({ ...draft(), ...finished(), elapsedSeconds: -5 }));
    await assertFails(create({ ...draft(), ...finished(), elapsedSeconds: 10 ** 7 }));
    await assertFails(create({ ...draft(), ...finished(), half: 3 }));
  });

  it('un statut trop long ou d\'un autre type', async () => {
    await assertFails(create({ ...draft(), status: 'x'.repeat(31) }));
    await assertFails(create({ ...draft(), status: { a: 1 } }));
  });

  it('un adversaire mal formé', async () => {
    await assertFails(create({ ...draft(), opponent: { ...OPPONENT, name: 'x'.repeat(101) } }));
    await assertFails(create({ ...draft(), opponent: { ...OPPONENT, extra: 1 } }));
    await assertFails(create({ ...draft(), opponent: 'FC Voisin' }));
    await assertFails(create({ ...draft(), opponent: { ...OPPONENT, category: 12 } }));
  });

  it('un maillot mal formé', async () => {
    await assertFails(create({ ...draft(), ownJersey: { name: 'x'.repeat(61), color: 'bleu' } }));
    await assertFails(create({ ...draft(), ownJersey: { name: 'A', color: 'bleu', extra: 1 } }));
  });

  it('une composition mal formée', async () => {
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, extra: 1 } }));
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, slots: rep(31, { role: 'milieu', x: 0.5, y: 0.5 }) } }));
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, assignments: rep(31, 'p0') } }));
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, numbers: repMap(41, 1) } }));
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, formationLabel: 'x'.repeat(31) } }));
    await assertFails(create({ ...draft(), composition: { ...COMPOSITION, playerCount: 'onze' } }));
    await assertFails(create({ ...draft(), composition: 'tout' }));
    await assertFails(create({ ...draft(), compositions: rep(21, COMPOSITION) }));
  });

  it('des statistiques ou listes de clés démesurées', async () => {
    await assertFails(create({ ...draft(), ...finished(), playerStats: repMap(61, { goal: 1 }) }));
    await assertFails(create({ ...draft(), ...finished(), firstHalfStats: repMap(61, { goal: 1 }) }));
    await assertFails(create({ ...draft(), enabledStatKeys: rep(61) }));
    await assertFails(create({ ...draft(), ...finished(), firstHalfStatKeys: rep(61) }));
    await assertFails(create({ ...draft(), enabledStatKeys: 'goal' }));
  });

  it('un set merge qui rendrait le document invalide', async () => {
    await seed(`users/${UID}/matches/m1`, { opponent: OPPONENT, status: 'draft' });
    await assertFails(setDoc(sub('matches', 'm1'), { scoreUs: 'beaucoup' }, { merge: true }));
  });

  it('refuse d\'écrire dans le match d\'un autre', async () => {
    await assertFails(addDoc(collection(db(OTHER_UID), `users/${UID}/matches`), draft()));
  });
});

// ------------------------------------------------------------- compositions

/** CustomComposition.toJson (custom_composition.dart:76) + horodatages de CompositionRepository. */
const CUSTOM = {
  name: 'Mon 4-4-2',
  type: 'custom',
  playerCount: 11,
  formationLabel: '4-4-2',
  isFavorite: false,
  slots: [{ role: 'gardien', x: 0.5, y: 0.9 }],
};

describe('compositions/{id} — écritures légitimes de l\'app', () => {
  beforeEach(() => seed());

  it('addComposition', async () => {
    await assertSucceeds(addDoc(collection(db(), `users/${UID}/compositions`), { ...CUSTOM, createdAt: serverTimestamp() }));
  });

  it('updateComposition : set merge avec updatedAt', async () => {
    await seed(`users/${UID}/compositions/c1`, { ...CUSTOM });
    await assertSucceeds(setDoc(sub('compositions', 'c1'), { ...CUSTOM, name: 'Renommée', updatedAt: serverTimestamp() }, { merge: true }));
  });

  it('setFavorite', async () => {
    await seed(`users/${UID}/compositions/c1`, { ...CUSTOM });
    await assertSucceeds(updateDoc(sub('compositions', 'c1'), { isFavorite: true }));
  });

  it('deleteComposition', async () => {
    await seed(`users/${UID}/compositions/c1`, { ...CUSTOM });
    await assertSucceeds(deleteDoc(sub('compositions', 'c1')));
  });
});

describe('compositions/{id} — contenu refusé', () => {
  beforeEach(() => seed());
  const create = (data) => addDoc(collection(db(), `users/${UID}/compositions`), data);

  it('un champ inconnu', async () => {
    await assertFails(create({ ...CUSTOM, isAdmin: true }));
  });

  it('un nom, un libellé ou un type trop longs ou d\'un autre type', async () => {
    await assertFails(create({ ...CUSTOM, name: 'x'.repeat(101) }));
    await assertFails(create({ ...CUSTOM, name: 12 }));
    await assertFails(create({ ...CUSTOM, formationLabel: 'x'.repeat(31) }));
    await assertFails(create({ ...CUSTOM, type: 'x'.repeat(21) }));
  });

  it('un effectif ou un favori d\'un autre type, trop d\'emplacements', async () => {
    await assertFails(create({ ...CUSTOM, playerCount: '11' }));
    await assertFails(create({ ...CUSTOM, playerCount: 500 }));
    await assertFails(create({ ...CUSTOM, isFavorite: 'oui' }));
    await assertFails(create({ ...CUSTOM, slots: rep(31, { role: 'milieu', x: 0.5, y: 0.5 }) }));
  });

  it('refuse d\'écrire chez un autre coach', async () => {
    await assertFails(addDoc(collection(db(OTHER_UID), `users/${UID}/compositions`), CUSTOM));
  });
});

// ------------------------------------------------------------------ maillots

describe('jerseys/{id} — écritures légitimes de l\'app', () => {
  beforeEach(() => seed());

  it('addJerseys : batch de maillots avec order et createdAt (coach_profile_repository.dart:78)', async () => {
    const d = db();
    const batch = writeBatch(d);
    for (let i = 0; i < 3; i++) {
      batch.set(doc(collection(d, `users/${UID}/jerseys`)), { name: `Maillot ${i}`, color: 'bleu', order: i, createdAt: serverTimestamp() });
    }
    await assertSucceeds(batch.commit());
  });

  it('updateJersey : nom et couleur', async () => {
    await seed(`users/${UID}/jerseys/j1`, { name: 'A', color: 'bleu', order: 0 });
    await assertSucceeds(updateDoc(sub('jerseys', 'j1'), { name: 'Extérieur', color: 'rouge' }));
  });

  it('deleteJersey', async () => {
    await seed(`users/${UID}/jerseys/j1`, { name: 'A', color: 'bleu', order: 0 });
    await assertSucceeds(deleteDoc(sub('jerseys', 'j1')));
  });
});

describe('jerseys/{id} — contenu refusé', () => {
  beforeEach(() => seed());
  const create = (data) => addDoc(collection(db(), `users/${UID}/jerseys`), data);

  it('un champ inconnu', async () => {
    await assertFails(create({ name: 'A', color: 'bleu', order: 0, isAdmin: true }));
  });

  it('un nom ou une couleur trop longs ou d\'un autre type', async () => {
    await assertFails(create({ name: 'x'.repeat(61), color: 'bleu', order: 0 }));
    await assertFails(create({ name: 12, color: 'bleu', order: 0 }));
    await assertFails(create({ name: 'A', color: 'x'.repeat(31), order: 0 }));
    await assertFails(create({ name: 'A', color: { r: 1 }, order: 0 }));
  });

  it('un ordre négatif, fractionnaire ou démesuré', async () => {
    await assertFails(create({ name: 'A', color: 'bleu', order: -1 }));
    await assertFails(create({ name: 'A', color: 'bleu', order: 1.5 }));
    await assertFails(create({ name: 'A', color: 'bleu', order: 10 ** 6 }));
  });

  it('refuse d\'écrire chez un autre coach', async () => {
    await assertFails(addDoc(collection(db(OTHER_UID), `users/${UID}/jerseys`), { name: 'A', color: 'bleu', order: 0 }));
  });
});
