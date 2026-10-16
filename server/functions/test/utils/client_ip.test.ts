import { describe, expect, it } from "vitest";
import { clientIp } from "../../src/utils/client_ip";

// Google ajoute l'IP réelle à la FIN de X-Forwarded-For ; ce qui la précède est
// fourni par le client et ne doit pas servir de clé de limitation.
describe("clientIp", () => {
  it("takes the last X-Forwarded-For entry, ignoring client-supplied ones before it", () => {
    expect(clientIp({ headers: { "x-forwarded-for": "6.6.6.6, 7.7.7.7, 198.51.100.4" } })).toBe("198.51.100.4");
  });

  it("works with a single entry and with spaces", () => {
    expect(clientIp({ headers: { "x-forwarded-for": "  198.51.100.4  " } })).toBe("198.51.100.4");
  });

  it("reads the header through get() when headers is absent", () => {
    expect(clientIp({ get: (name: string) => (name === "x-forwarded-for" ? "1.1.1.1, 2.2.2.2" : undefined) })).toBe("2.2.2.2");
  });

  it("falls back to req.ip, then to a constant", () => {
    expect(clientIp({ headers: {}, ip: "192.0.2.9" })).toBe("192.0.2.9");
    expect(clientIp({ headers: {} })).toBe("unknown");
    expect(clientIp(undefined)).toBe("unknown");
  });

  it("ignores an empty or non-string header", () => {
    expect(clientIp({ headers: { "x-forwarded-for": "" }, ip: "192.0.2.9" })).toBe("192.0.2.9");
    expect(clientIp({ headers: { "x-forwarded-for": ["1.1.1.1"] as any }, ip: "192.0.2.9" })).toBe("192.0.2.9");
  });
});

// Un VPS reçoit un /64 IPv6 entier (2^64 adresses) : une clé par adresse complète
// offrirait un compteur neuf à chaque requête.
describe("clientIp — IPv6 and proxy hops", () => {
  const ip = (value: string) => clientIp({ headers: { "x-forwarded-for": value } });

  it("collapses every address of the same /64 onto one key", () => {
    expect(ip("2001:db8:aa:bb::1")).toBe(ip("2001:db8:aa:bb::ffff"));
    expect(ip("2001:db8:aa:bb:1:2:3:4")).toBe(ip("2001:0DB8:00aa:00bb::9"));
  });

  it("keeps distinct /64 networks apart", () => {
    expect(ip("2001:db8:aa:bb::1")).not.toBe(ip("2001:db8:aa:bc::1"));
  });

  it("expands the :: shorthand before taking the prefix", () => {
    expect(ip("2001:db8::1")).toBe(ip("2001:db8:0:0:0:0:0:2"));
    expect(ip("::1")).toBe(ip("0:0:0:0:0:0:0:2"));
  });

  it("maps an IPv4-mapped IPv6 address back to its IPv4", () => {
    expect(ip("::ffff:198.51.100.4")).toBe("198.51.100.4");
  });

  it("tolerates brackets and a zone identifier", () => {
    expect(ip("[2001:db8:aa:bb::1]")).toBe(ip("2001:db8:aa:bb::1"));
    expect(ip("fe80::1%eth0")).toBe(ip("fe80::2"));
  });

  it("leaves IPv4 and unparseable values untouched", () => {
    expect(ip("198.51.100.4")).toBe("198.51.100.4");
    expect(ip("not-an-ip")).toBe("not-an-ip");
    expect(ip("1:2:3:4:5:6:7:8:9")).toBe("1:2:3:4:5:6:7:8:9");
    expect(ip("1::2::3")).toBe("1::2::3");
  });

  // Réglage à relever si un load balancer ou un proxy est placé devant les fonctions.
  it("skips trusted proxy hops from the right", () => {
    const header = { headers: { "x-forwarded-for": "6.6.6.6, 198.51.100.4, 35.191.0.1" } };

    expect(clientIp(header, 0)).toBe("35.191.0.1");
    expect(clientIp(header, 1)).toBe("198.51.100.4");
    expect(clientIp(header, 5)).toBe("6.6.6.6"); // jamais en dehors de la liste
  });
});
