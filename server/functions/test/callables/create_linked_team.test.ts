import { afterEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedCoach } from "../helpers";
import createLinkedTeam from "../../src/callables/billing/create_linked_team";
import { slotRef } from "../../src/billing/linked_teams";

const PASSWORD = "Wina!2345";
const DAY = 86_400_000;

async function seedOwner(options: { teamsAllowed?: 1 | 2 | 3; status?: string; expiresInMs?: number } = {}): Promise<string> {
  const teamsAllowed = options.teamsAllowed ?? 3;
  const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });
  const expiresAt = firestore.Timestamp.fromMillis(Date.now() + (options.expiresInMs ?? 30 * DAY));
  await firestore().doc(`users/${uid}`).set(
    {
      coachName: "Ibrahim Coach",
      subscription: {
        productId: `wina_team${teamsAllowed}_yearly`,
        period: "yearly",
        teamsAllowed,
        status: options.status ?? "active",
        trialEnd: null,
        expiresAt,
        store: "app_store",
        lastEventMs: Date.now(),
        updatedAt: firestore.Timestamp.now(),
      },
      access: { active: true, until: expiresAt },
    },
    { merge: true },
  );
  return uid;
}

const caller = (uid: string) => ({ uid, token: {} as Record<string, unknown> });

function payload(overrides: Record<string, unknown> = {}) {
  return { identifier: "u15-lyon", password: PASSWORD, teamName: "U15 Lyon", category: "u15", division: "d2", teamFormat: 11, ...overrides } as any;
}

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e: any) {
    return e.code === "failed-precondition" || e.code === "already-exists" ? `${e.code}:${e.message}` : e.code;
  }
  return "no-error";
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("createLinkedTeam", () => {
  it("creates the Auth account with the technical address and the documents the app expects", async () => {
    const owner = await seedOwner();

    const { uid, teamIndex } = await createLinkedTeam(payload(), caller(owner));

    expect(teamIndex).toBe(2);
    const record = await auth().getUser(uid);
    expect(record.email).toBe("u15-lyon@equipes.wina.invalid");
    expect(record.emailVerified).toBe(true);

    const doc = (await firestore().doc(`users/${uid}`).get()).data()!;
    expect(doc).toMatchObject({
      id: uid,
      email: "u15-lyon@equipes.wina.invalid",
      firstname: "Ibrahim",
      coachName: "Ibrahim Coach",
      teamName: "U15 Lyon",
      category: "u15",
      division: "d2",
      teamFormat: 11,
      userType: "client",
      cguAccepted: true,
      profilCompleted: true,
      disabled: false,
      ownerUid: owner,
      teamIndex: 2,
    });
    expect(doc.access.active).toBe(true);

    expect((await firestore().doc(`users/${uid}/metadata/security`).get()).get("profilCompleted")).toBe(true);
    expect((await firestore().doc(`users/${uid}/metadata/metadata`).get()).exists).toBe(true);
    expect((await slotRef(owner, 2).get()).get("ownerUid")).toBe(owner);
  });

  it("gives the next free index to the next team and stops at the formula", async () => {
    const owner = await seedOwner({ teamsAllowed: 3 });

    expect((await createLinkedTeam(payload({ identifier: "u15-a" }), caller(owner))).teamIndex).toBe(2);
    expect((await createLinkedTeam(payload({ identifier: "u15-b" }), caller(owner))).teamIndex).toBe(3);
    expect(await codeOf(createLinkedTeam(payload({ identifier: "u15-c" }), caller(owner)))).toBe("failed-precondition:team-quota-reached");
  });

  it("allows no extra team on a one-team formula", async () => {
    const owner = await seedOwner({ teamsAllowed: 1 });
    expect(await codeOf(createLinkedTeam(payload(), caller(owner)))).toBe("failed-precondition:team-quota-reached");
  });

  it("refuses without an active subscription", async () => {
    expect(await codeOf(createLinkedTeam(payload(), caller(await seedOwner({ status: "expired" }))))).toBe("failed-precondition:no-active-subscription");
  });

  it("refuses once the period is over", async () => {
    expect(await codeOf(createLinkedTeam(payload(), caller(await seedOwner({ expiresInMs: -1000 }))))).toBe("failed-precondition:no-active-subscription");
  });

  it("refuses a linked account as caller", async () => {
    const owner = await seedOwner();
    const { uid } = await createLinkedTeam(payload({ identifier: "u15-a" }), caller(owner));
    expect(await codeOf(createLinkedTeam(payload({ identifier: "u15-b" }), caller(uid)))).toBe("permission-denied");
  });

  it("refuses a taken identifier and gives the slot back", async () => {
    const owner = await seedOwner();
    await createLinkedTeam(payload({ identifier: "u15-a" }), caller(owner));

    expect(await codeOf(createLinkedTeam(payload({ identifier: "u15-a" }), caller(owner)))).toBe("already-exists:identifier-taken");

    expect((await slotRef(owner, 3).get()).exists).toBe(false);
    expect((await createLinkedTeam(payload({ identifier: "u15-b" }), caller(owner))).teamIndex).toBe(3);
  });

  it.each([
    ["identifier", "Ab"],
    ["identifier", "UPPER CASE"],
    ["password", "faible"],
    ["teamName", ""],
    ["teamName", "x".repeat(101)],
    ["category", "u 15"],
    ["division", 3],
    ["teamFormat", 7],
  ])("rejects an invalid %s (%j)", async (field, value) => {
    const owner = await seedOwner();
    expect(await codeOf(createLinkedTeam(payload({ [field]: value }), caller(owner)))).toBe("invalid-argument");
    expect((await slotRef(owner, 2).get()).exists).toBe(false);
  });

  it("never lets two simultaneous calls take the same last place", async () => {
    const owner = await seedOwner({ teamsAllowed: 2 });

    const results = await Promise.allSettled([
      createLinkedTeam(payload({ identifier: "u15-a" }), caller(owner)),
      createLinkedTeam(payload({ identifier: "u15-b" }), caller(owner)),
    ]);

    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    expect((await firestore().collection("users").where("ownerUid", "==", owner).get()).size).toBe(1);
  });

  it("leaves nothing behind when the Auth account cannot be created", async () => {
    const owner = await seedOwner();
    vi.spyOn(auth(), "createUser").mockRejectedValueOnce({ code: "auth/internal-error" });

    expect(await codeOf(createLinkedTeam(payload(), caller(owner)))).toBe("internal");

    expect((await slotRef(owner, 2).get()).exists).toBe(false);
    expect((await firestore().collection("users").where("ownerUid", "==", owner).get()).size).toBe(0);
  });
});
