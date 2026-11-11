import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";

// The template's own pages, ported as they were: vercel/examples'
// framework-boilerplates/vuepress at cb2643e, byte for byte — the home page,
// the two-page guide and the config reference, all Markdown.
const appDir = path.resolve(__dirname, "../../../apps/web");
const read = (rel: string) => fs.readFileSync(path.join(appDir, rel), "utf8");

describe("the home page (apps/web/src/index.md)", () => {
  const page = read("src/index.md");

  it("is VuePress's home layout with the template's hero", () => {
    expect(page).toMatch(/^---\nhome: true\n/);
    expect(page).toContain("heroImage: https://v1.vuepress.vuejs.org/hero.png");
    expect(page).toContain("actionText: Quick Start →");
    expect(page).toContain("actionLink: /guide/");
  });

  it("keeps the template's three features and its footer", () => {
    for (const n of [1, 2, 3]) {
      expect(page).toContain(`  - title: Feature ${n} Title\n    details: Feature ${n} Description`);
    }
    expect(page).toContain("footer: Made by  with ❤️");
  });
});

describe("the guide (apps/web/src/guide)", () => {
  it("opens with the introduction to VuePress", () => {
    const page = read("src/guide/README.md");
    expect(page.startsWith("# Introduction\n")).toBe(true);
    expect(page).toContain("VuePress is composed of two parts");
  });

  it("has the page on Vue in Markdown, as the template ships it", () => {
    const page = read("src/guide/using-vue.md");
    expect(page.startsWith("# Using Vue in Markdown\n")).toBe(true);
    expect(page).toContain("## Browser API Access Restrictions");
    expect(page).toContain("`<ClientOnly>`");
  });
});

describe("the config reference (apps/web/src/config/README.md)", () => {
  const page = read("src/config/README.md");

  it("builds its own sidebar from its headings", () => {
    expect(page).toMatch(/^---\nsidebar: auto\n---\n/);
    expect(page).toContain("## foo");
    expect(page).toContain("## bar");
  });
});

describe("the licence", () => {
  it("is the template's MIT licence, © Vercel", () => {
    const licence = read("LICENSE.md");
    expect(licence).toContain("The MIT License (MIT)");
    expect(licence).toContain("Copyright (c) 2023 Vercel, Inc.");
  });
});
