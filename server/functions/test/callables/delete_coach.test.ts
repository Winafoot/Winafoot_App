import { describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedAdmin, seedCoach } from "../helpers";
import deleteCoach from "../../src/callables/admin/delete_coach";
import { DeletedUserRepositoryRepository } from "../../src/database/deleted_users/deleted_user_repository";

const CALLER = { uid: "admin1", email: "staff@wina.test" };

/** seedCoach + les sous-collections dont ce test vérifie la suppression. */
async function seedCoachWithData(email: string): Promise<string> {
  const uid = await seedCoach(email);
  const ref = firestore().collection("users").doc(uid);
  await ref.collection("players").doc("p1").set({ name: "Zidane" });
  await ref.collection("metadata").doc("security").set({ profilCompleted: true });
  return uid;
}

describe("deleteCoach", () => {
  it("deletes the Auth user and the whole document tree", async () => {
    const uid = await seedCoachWithData("gone@club.test");

    const result = await deleteCoach({ uid }, CALLER);

    expect(result).toEqual({ deleted: true });
    await expect(auth().getUser(uid)).rejects.toThrowError();
    expect((await firestore().collection("users").doc(uid).get()).exists).toBe(false);
    expect((await firestore().collection("users").doc(uid).collection("players").get()).empty).toBe(true);
  });

  it("deletes the linked team accounts of a deleted coach", async () => {
    const owner = await seedCoachWithData("boss@club.test");
    const team = await auth().createUser({ email: "u15-b@equipes.wina.invalid" });
    await firestore().doc(`users/${team.uid}`).set({ ownerUid: owner, teamIndex: 2 });

    await deleteCoach({ uid: owner }, CALLER);

    await expect(auth().getUser(team.uid)).rejects.toThrowError();
    expect((await firestore().doc(`users/${team.uid}`).get()).exists).toBe(false);
  });

  it("archives the account before deleting it", async () => {
    const uid = await seedCoachWithData("archived@club.test");

    await deleteCoach({ uid }, CALLER);

    const archived = await firestore().collection("deleted_users").get();
    expect(archived.size).toBeGreaterThan(0);
  });

  it("records an audit entry naming the admin", async () => {
    const uid = await seedCoachWithData("tracked@club.test");

    await deleteCoach({ uid }, CALLER);

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("action")).toBe("delete");
    expect(audit.docs[0].get("adminUid")).toBe("admin1");
    expect(audit.docs[0].get("targetEmail")).toBe("tracked@club.test");
  });

  it("rejects an unknown account", async () => {
    await expect(deleteCoach({ uid: "nope" }, CALLER)).rejects.toThrowError(/introuvable/i);
  });

  // Sans ce refus, deleteCoach contournerait les garde-fous de deleteAdmin (dernier administrateur, soi-même).
  it("refuses an administrator account, keeps it, and audits the attempt", async () => {
    const uid = await seedAdmin("boss@wina.test");

    await expect(deleteCoach({ uid }, CALLER)).rejects.toMatchObject({ code: "failed-precondition", message: expect.stringMatching(/Administrateurs/) });

    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
    expect((await firestore().collection("deleted_users").get()).size).toBe(0);
  });

  it("records a failure audit entry for an unknown account", async () => {
    await expect(deleteCoach({ uid: "nope" }, CALLER)).rejects.toThrow();

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("action")).toBe("delete");
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });

  it("records whether the Storage purge completed, alongside a success outcome", async () => {
    // Aucun storageBucket n'est configuré dans l'environnement de test : la
    // purge Storage échoue systématiquement (voir le commentaire dans
    // delete_coach.ts), mais la suppression doit tout de même aboutir.
    const uid = await seedCoachWithData("storage@club.test");

    await deleteCoach({ uid }, CALLER);

    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("success");
    expect(audit.docs[0].get("storagePurged")).toBe(false);
  });

  it("distinguishes an archive failure: nothing is deleted and it's safe to retry", async () => {
    const uid = await seedCoachWithData("archive-fail@club.test");
    const spy = vi
      .spyOn(DeletedUserRepositoryRepository.instance, "addFromUserRecord")
      .mockRejectedValueOnce(new Error("archive boom"));

    try {
      await expect(deleteCoach({ uid }, CALLER)).rejects.toThrowError(
        "L'archivage du compte a échoué, rien n'a été supprimé, réessayez."
      );
    } finally {
      spy.mockRestore();
    }

    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    expect((await firestore().collection("users").doc(uid).get()).exists).toBe(true);

    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
    expect(audit.docs[0].get("failedStage")).toBe("archive");
  });

  it("distinguishes an Auth-deletion failure: nothing is deleted and it's safe to retry", async () => {
    const uid = await seedCoachWithData("auth-fail@club.test");
    const spy = vi.spyOn(auth(), "deleteUser").mockRejectedValueOnce(new Error("auth boom"));

    try {
      await expect(deleteCoach({ uid }, CALLER)).rejects.toThrowError(
        "La suppression du compte d'authentification a échoué, rien n'a été supprimé, réessayez."
      );
    } finally {
      spy.mockRestore();
    }

    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    expect((await firestore().collection("users").doc(uid).get()).exists).toBe(true);

    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
    expect(audit.docs[0].get("failedStage")).toBe("auth_delete");
  });

  it("distinguishes the dangerous partial state: Auth is gone but Firestore cleanup failed", async () => {
    const uid = await seedCoachWithData("partial@club.test");
    const spy = vi.spyOn(firestore(), "recursiveDelete").mockRejectedValueOnce(new Error("bulkwriter boom"));

    try {
      await expect(deleteCoach({ uid }, CALLER)).rejects.toThrowError(
        "Le compte a été supprimé mais ses données n'ont pas pu être entièrement effacées, ne réessayez pas : contactez un développeur."
      );
    } finally {
      spy.mockRestore();
    }

    // Le compte Auth est bien parti : c'est précisément ce qui rend l'état dangereux.
    await expect(auth().getUser(uid)).rejects.toThrowError();

    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
    expect(audit.docs[0].get("failedStage")).toBe("firestore_delete");
  });
});
