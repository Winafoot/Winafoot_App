/**
 * Règles Firestore — users/{coach}/liveMatch/current (match en direct partagé avec l'adjoint)
 *
 * Le document est publié par le téléphone du coach (app/lib/providers/live_match_coach_sync.dart) avec
 * `LiveMatchSnapshot.toJson` (app/lib/models/live_match_sync.dart). La liste de champs des règles doit
 * suivre ce `toJson` : un champ en trop ou en moins fait refuser la publication, et l'adjoint ne voit
 * alors jamais le match.
 */

import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';

const COACH = 'coach-alice';
const ASSISTANT = 'assistant-1';
const OTHER = 'coach-bob';

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

const coachDb = () => testEnv.authenticatedContext(COACH).firestore();
const assistantDb = () => testEnv.authenticatedContext(ASSISTANT, { assistantOf: COACH }).firestore();
const otherDb = () => testEnv.authenticatedContext(OTHER).firestore();

/** Les champs de `LiveMatchSnapshot.toJson`, plus `updatedAt` posé par `publish`. */
function snapshot(extra = {}) {
  return {
    matchId: 'm1',
    status: 'live',
    half: 1,
    elapsedSeconds: 120,
    scoreUs: 0,
    scoreThem: 0,
    formationLabel: '4-3-3',
    slots: [{ role: 'gk', x: 0.5, y: 0.9 }],
    assignments: ['p1'],
    numbers: { p1: 1 },
    captainId: 'p1',
    substituteIds: [],
    enabledStatKeys: ['passes_reussies'],
    halfTimeStatKeys: [],
    swapSides: false,
    playerStats: {},
    events: [],
    players: {},
    kit: 'red',
    opponentName: 'AS Lions',
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

describe('users/{coach}/liveMatch/current', () => {
  it('le coach publie l\'état complet, capitaine compris', async () => {
    await assertSucceeds(setDoc(doc(coachDb(), `users/${COACH}/liveMatch/current`), snapshot()));
  });

  it('le coach publie sans capitaine (captainId nul)', async () => {
    await assertSucceeds(
      setDoc(doc(coachDb(), `users/${COACH}/liveMatch/current`), snapshot({ captainId: null })),
    );
  });

  it('un champ inconnu est refusé', async () => {
    await assertFails(
      setDoc(doc(coachDb(), `users/${COACH}/liveMatch/current`), snapshot({ inconnu: true })),
    );
  });

  it('l\'adjoint lit le match de son coach, pas celui d\'un autre', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${COACH}/liveMatch/current`), { status: 'live' });
      await setDoc(doc(ctx.firestore(), `users/${OTHER}/liveMatch/current`), { status: 'live' });
    });
    await assertSucceeds(getDoc(doc(assistantDb(), `users/${COACH}/liveMatch/current`)));
    await assertFails(getDoc(doc(assistantDb(), `users/${OTHER}/liveMatch/current`)));
    await assertFails(getDoc(doc(otherDb(), `users/${COACH}/liveMatch/current`)));
  });

  it('l\'adjoint ne publie jamais l\'état', async () => {
    await assertFails(setDoc(doc(assistantDb(), `users/${COACH}/liveMatch/current`), snapshot()));
  });
});
