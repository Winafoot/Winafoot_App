import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../src/database/admin_audit/admin_audit_repository";

describe("AdminAuditRepository", () => {
  it("records a success entry with a server timestamp", async () => {
    await AdminAuditRepository.instance.record({
      action: "create",
      targetUid: "coach1",
      targetEmail: "coach@club.test",
      adminUid: "admin1",
      adminEmail: "staff@wina.test",
      outcome: "success",
    });

    const snap = await firestore().collection("admin_audit").get();
    expect(snap.size).toBe(1);
    const entry = snap.docs[0].data();
    expect(entry.action).toBe("create");
    expect(entry.targetUid).toBe("coach1");
    expect(entry.adminUid).toBe("admin1");
    expect(entry.outcome).toBe("success");
    expect(entry.at).toBeDefined();
    expect(entry.error).toBeNull();
  });

  it("records a failure entry carrying the error text", async () => {
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: "coach2",
      adminUid: "admin1",
      outcome: "failure",
      error: "boom",
    });

    const snap = await firestore().collection("admin_audit").get();
    const entry = snap.docs[0].data();
    expect(entry.outcome).toBe("failure");
    expect(entry.error).toBe("boom");
    expect(entry.targetEmail).toBeNull();
    expect(entry.adminEmail).toBeNull();
  });
});
