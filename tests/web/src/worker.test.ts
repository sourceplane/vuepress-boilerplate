import { describe, expect, it, vi } from "vitest";

import worker from "@/worker/index";

// What reaches the Worker is a request no file matched (the assets serve
// files at the address they are named by, `html_handling: "none"`). A folder
// is answered with its index.html; anything else is handed to the assets,
// which answer with VuePress's 404 page and a 404 status.
const FILES: Record<string, string> = {
  "/index.html": "<title>Home</title>",
  "/guide/index.html": "<title>Introduction</title>",
  "/config/index.html": "<title>Config</title>",
  "/guide/using-vue.html": "<title>Using Vue in Markdown</title>",
};

function assets() {
  return {
    fetch: vi.fn(async (req: Request) => {
      const body = FILES[new URL(req.url).pathname];
      return body
        ? new Response(body, { status: 200, headers: { "content-type": "text/html" } })
        : new Response("<h1>404</h1>", { status: 404, headers: { "content-type": "text/html" } });
    }),
  };
}
const asked = (ASSETS: ReturnType<typeof assets>) => ASSETS.fetch.mock.calls.map(([r]) => new URL(r.url).pathname);

describe("the Worker", () => {
  it("answers a folder with its index.html, with or without the trailing slash", async () => {
    for (const [path, want] of [["/guide/", "Introduction"], ["/guide", "Introduction"], ["/config/", "Config"], ["/", "Home"]] as const) {
      const ASSETS = assets();
      const res = await worker.fetch(new Request(`https://site.example${path}`), { ASSETS });
      expect(res.status, path).toBe(200);
      expect(await res.text(), path).toContain(want);
      expect(asked(ASSETS), path).toEqual([path.endsWith("/") ? `${path}index.html` : `${path}/index.html`]);
    }
  });

  it("hands a file's address to the assets as it is, once", async () => {
    const ASSETS = assets();
    const req = new Request("https://site.example/guide/using-vue.html");
    const res = await worker.fetch(req, { ASSETS });
    expect(ASSETS.fetch).toHaveBeenCalledOnce();
    expect(ASSETS.fetch).toHaveBeenCalledWith(req);
    expect(res.status).toBe(200);
  });

  it("answers a missing page with the assets' 404 page and its status", async () => {
    for (const path of ["/no-such-page", "/no-such-folder/", "/a/b/c/d"]) {
      const ASSETS = assets();
      const req = new Request(`https://site.example${path}`);
      const res = await worker.fetch(req, { ASSETS });
      expect(res.status, path).toBe(404);
      expect(await res.text(), path).toContain("<h1>404</h1>");
      expect(ASSETS.fetch, path).toHaveBeenLastCalledWith(req);
    }
  });

  it("does not guess a page's .html: an extension-less page address is missing, as on Vercel", async () => {
    const ASSETS = assets();
    const res = await worker.fetch(new Request("https://site.example/guide/using-vue"), { ASSETS });
    expect(res.status).toBe(404);
    expect(asked(ASSETS)).toEqual(["/guide/using-vue/index.html", "/guide/using-vue"]);
  });

  it("answers a missing file with the 404 page without asking for a folder", async () => {
    const ASSETS = assets();
    const res = await worker.fetch(new Request("https://site.example/assets/js/missing.js"), { ASSETS });
    expect(res.status).toBe(404);
    expect(asked(ASSETS)).toEqual(["/assets/js/missing.js"]);
  });

  it("keeps the request's query and method when it asks for a folder's index", async () => {
    const ASSETS = assets();
    await worker.fetch(new Request("https://site.example/guide/?v=1", { method: "HEAD" }), { ASSETS });
    const [req] = ASSETS.fetch.mock.calls[0]!;
    expect(new URL(req.url).search).toBe("?v=1");
    expect(req.method).toBe("HEAD");
  });
});
