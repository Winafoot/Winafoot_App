import { describe, expect, it } from "vitest";
import { withHeaderImage, wrapEmailLayout } from "../../src/template/_email_layout";

const URL = "https://winafoot.fr/mail/header.jpg";

describe("withHeaderImage", () => {
  const html = wrapEmailLayout("", "<p>contenu</p>", "Wina");

  it("remplace le bandeau vert par l'image quand l'URL est en https", () => {
    const out = withHeaderImage(html, URL, "Wina");
    expect(out).toContain(`src="${URL}"`);
    expect(out).not.toContain("letter-spacing: 0.5px");
    expect(out).toContain("<p>contenu</p>");
    expect(out.match(/<table class="header"/g)).toHaveLength(1);
  });

  it("laisse le HTML intact sans URL, ou avec une URL non https", () => {
    expect(withHeaderImage(html, undefined, "Wina")).toBe(html);
    expect(withHeaderImage(html, "", "Wina")).toBe(html);
    expect(withHeaderImage(html, "http://winafoot.fr/h.jpg", "Wina")).toBe(html);
    expect(withHeaderImage(html, 'https://x.fr/a"onerror="x', "Wina")).toBe(html);
  });

  it("ne casse pas un HTML sans bandeau", () => {
    expect(withHeaderImage("<p>x</p>", URL, "Wina")).toBe("<p>x</p>");
  });
});
