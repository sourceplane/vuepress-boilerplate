// The site's Worker. `vuepress build` writes the whole site as static files
// in src/.vuepress/dist — an HTML file per page, the hashed JavaScript and
// CSS the Vue app hydrates and navigates with — uploaded as Workers Static
// Assets, served exactly as they are named (`html_handling: "none"` in
// wrangler.jsonc):
//
//   - a request that matches a file is served from the assets, and never
//     reaches this Worker (`/`, `/guide/using-vue.html`, `/assets/js/…`);
//   - a request for a folder reaches it — a browser's navigation too
//     (`assets_navigation_has_no_effect` in wrangler.jsonc) — and is
//     answered with the folder's index.html, with or without its trailing
//     slash (`/guide/`, `/guide`), as Vercel answers it;
//   - anything else is handed to the assets, which answer it with VuePress's
//     404 page and a 404 status (`not_found_handling: "404-page"`): a missing
//     page, a page's address without its `.html`, a missing chunk alike.
//
// It is also the place a redirect, a header or an API route goes when the
// site needs one.
interface Env {
  ASSETS: { fetch(request: Request): Promise<Response> };
}

// A folder's page: the address's last segment names no file (it has no
// extension), and the folder holds an index.html.
function folderIndex(url: URL): URL | null {
  const last = url.pathname.split("/").pop() ?? "";
  if (last.includes(".")) return null;
  const index = new URL(url);
  index.pathname = url.pathname.endsWith("/") ? `${url.pathname}index.html` : `${url.pathname}/index.html`;
  return index;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const index = folderIndex(new URL(request.url));
    if (index) {
      const page = await env.ASSETS.fetch(new Request(index, request));
      if (page.status === 200) return page;
    }
    return env.ASSETS.fetch(request);
  },
};
