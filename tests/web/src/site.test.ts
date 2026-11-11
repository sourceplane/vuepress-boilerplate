import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { createRequire } from "node:module";

const appDir = path.resolve(__dirname, "../../../apps/web");
const read = (rel: string) => fs.readFileSync(path.join(appDir, rel), "utf8");
const require = createRequire(import.meta.url);
const configPath = path.join(appDir, "src/.vuepress/config.js");

type NavItem = { text: string; link: string };
type SidebarGroup = { title: string; collapsable: boolean; children: string[] };
type VuePressConfig = {
  title: string;
  head: [string, Record<string, string>][];
  themeConfig: { nav: NavItem[]; sidebar: Record<string, SidebarGroup[]> };
};

function loadConfig(): VuePressConfig {
  delete require.cache[require.resolve(configPath)];
  return require(configPath) as VuePressConfig;
}

const SEAM = /^const SITE_NAME = "([^"]+)";$/m;

describe("site identity (apps/web/src/.vuepress/config.js)", () => {
  it("is a literal the rename seam can find", () => {
    expect(read("src/.vuepress/config.js")).toMatch(SEAM);
  });

  it("is what VuePress titles the site with", () => {
    const literal = SEAM.exec(read("src/.vuepress/config.js"))![1];
    expect(loadConfig().title).toBe(literal);
  });

  it("is spelled nowhere else in the app", () => {
    const literal = SEAM.exec(read("src/.vuepress/config.js"))![1]!;
    for (const file of ["src/index.md", "src/guide/README.md", "src/guide/using-vue.md", "src/config/README.md", "worker/index.ts"]) {
      expect(read(file)).not.toContain(literal);
    }
  });
});

describe("the site's config, as Vercel's live example runs it", () => {
  const config = loadConfig();

  it("carries the example's head tags", () => {
    expect(config.head).toEqual([
      ["meta", { name: "theme-color", content: "#3eaf7c" }],
      ["meta", { name: "apple-mobile-web-app-capable", content: "yes" }],
      ["meta", { name: "apple-mobile-web-app-status-bar-style", content: "black" }],
    ]);
  });

  it("has the example's navbar: the guide, the config reference and VuePress's documentation", () => {
    expect(config.themeConfig.nav).toEqual([
      { text: "Guide", link: "/guide/" },
      { text: "Config", link: "/config/" },
      { text: "VuePress", link: "https://v1.vuepress.vuejs.org" },
    ]);
  });

  it("has the guide's sidebar: one open group, its two pages", () => {
    expect(config.themeConfig.sidebar).toEqual({
      "/guide/": [{ title: "Guide", collapsable: false, children: ["", "using-vue"] }],
    });
  });

  it("names no Vercel host and sets no base (the site lives at its origin's root)", () => {
    const text = read("src/.vuepress/config.js");
    expect(text).not.toContain("vercel.app");
    expect(text).not.toMatch(/^\s*base:/m);
  });
});

describe("the build (apps/web/package.json)", () => {
  const pkg = JSON.parse(read("package.json")) as {
    scripts: Record<string, string>;
    devDependencies: Record<string, string>;
  };

  it("is the template's vuepress build, over src", () => {
    expect(pkg.scripts.build).toBe("vuepress build src");
    expect(pkg.scripts.dev).toBe("vuepress dev src --port 3000");
  });

  it("is VuePress 1.9.7, pinned as the template pins it", () => {
    expect(pkg.devDependencies.vuepress).toBe("1.9.7");
  });

  it("needs no OpenSSL legacy provider (webpack 4.47 hashes without md4 from OpenSSL)", () => {
    for (const script of Object.values(pkg.scripts)) expect(script).not.toContain("openssl-legacy-provider");
  });
});

describe("the Worker and its assets (apps/web/wrangler.jsonc)", () => {
  const wrangler = read("wrangler.jsonc");

  it("serves VuePress's output behind the Worker", () => {
    expect(wrangler).toContain('"main": "./worker/index.ts"');
    expect(wrangler).toContain('"directory": "./src/.vuepress/dist"');
    expect(wrangler).toContain('"binding": "ASSETS"');
  });

  it("answers a missing page with VuePress's 404 page, not the home page", () => {
    expect(wrangler).toContain('"not_found_handling": "404-page"');
    expect(wrangler).not.toContain("single-page-application");
  });

  it("serves each file at the address it is named by, as VuePress links it", () => {
    expect(wrangler).toContain('"html_handling": "none"');
  });

  it("lets a browser's navigation to a folder reach the Worker, not the 404 page", () => {
    expect(wrangler).toMatch(/"compatibility_flags": \[[^\]]*"assets_navigation_has_no_effect"/);
  });
});
