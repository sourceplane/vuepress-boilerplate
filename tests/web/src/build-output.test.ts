import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";

// What `vuepress build src` wrote to apps/web/src/.vuepress/dist — the files
// the Worker's assets serve. turbo builds the app before this package's tests
// (it is a dependency), so a missing file here is a build that did not
// produce it.
const appDir = path.resolve(__dirname, "../../../apps/web");
const dist = path.join(appDir, "src/.vuepress/dist");
const read = (rel: string) => fs.readFileSync(path.join(dist, rel), "utf8");
const SITE_NAME = /^const SITE_NAME = "([^"]+)";$/m.exec(
  fs.readFileSync(path.join(appDir, "src/.vuepress/config.js"), "utf8"),
)![1]!;

// HTML text as a reader sees it: the entities VuePress's renderer escapes.
const decode = (s: string) =>
  s.replace(/&#39;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");
const title = (html: string) => decode(/<title>([^<]*)<\/title>/.exec(html)?.[1] ?? "");

describe("the built site (apps/web/src/.vuepress/dist)", () => {
  it("has the home page, titled with the site's name, its hero and features", () => {
    const html = read("index.html");
    expect(title(html)).toBe(SITE_NAME);
    expect(html).toContain('<meta name="generator" content="VuePress 1.9.7">');
    expect(decode(/<h1 id="main-title">([^<]*)<\/h1>/.exec(html)![1]!).trim()).toBe(SITE_NAME);
    expect(html).toContain('<img src="https://v1.vuepress.vuejs.org/hero.png" alt="hero">');
    expect(html).toContain("Quick Start →");
    for (const n of [1, 2, 3]) expect(html).toContain(`<h2>Feature ${n} Title</h2>`);
  });

  it("puts the site's name in the navbar, beside the guide, the config and VuePress's docs", () => {
    const html = read("index.html");
    expect(decode(/<span class="site-name">([^<]*)<\/span>/.exec(html)![1]!)).toBe(SITE_NAME);
    for (const link of ['href="/guide/"', 'href="/config/"', 'href="https://v1.vuepress.vuejs.org"']) {
      expect(html).toContain(link);
    }
  });

  it("has the guide's two pages, each its own file, under the guide's sidebar", () => {
    const intro = read("guide/index.html");
    expect(title(intro)).toBe(`Introduction | ${SITE_NAME}`);
    expect(intro).toContain('class="sidebar-heading open"');
    expect(intro).toContain('href="/guide/using-vue.html"');
    const vue = read("guide/using-vue.html");
    expect(title(vue)).toBe(`Using Vue in Markdown | ${SITE_NAME}`);
    expect(vue).toContain("Browser API Access Restrictions");
  });

  it("has the config reference, its sidebar built from its headings", () => {
    const html = read("config/index.html");
    expect(title(html)).toBe(`Config | ${SITE_NAME}`);
    expect(html).toContain('href="/config/#foo"');
    expect(html).toContain('href="/config/#bar"');
  });

  it("has the 404 page the assets answer a missing page with", () => {
    const html = read("404.html");
    expect(html).toContain("<h1>404</h1>");
    expect(html).toContain("Take me home.");
  });

  it("links only scripts and stylesheets it built", () => {
    for (const page of ["index.html", "guide/index.html", "guide/using-vue.html", "config/index.html", "404.html"]) {
      const html = read(page);
      const files = [
        ...[...html.matchAll(/<script src="\/([^"]+\.js)"/g)].map((m) => m[1]!),
        ...[...html.matchAll(/<link rel="stylesheet" href="\/([^"]+\.css)"/g)].map((m) => m[1]!),
      ];
      expect(files.length, page).toBeGreaterThan(1);
      for (const file of files) expect(fs.existsSync(path.join(dist, file)), `${page} → ${file}`).toBe(true);
    }
  });
});
