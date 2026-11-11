# vuepress-boilerplate — design

## The template

Vercel's VuePress example (`framework-boilerplates/vuepress` in
[vercel/examples](https://github.com/vercel/examples)) is a VuePress 1.9.7
docs site (Vue 2.7, webpack 4) of four Markdown pages under `src/`:
`index.md`, the home layout (`home: true`) with VuePress v1's hero image, a
"Quick Start →" action into the guide, three placeholder features and the
footer "Made by  with ❤️"; `guide/README.md`, an introduction to VuePress;
`guide/using-vue.md`, the start of VuePress's page on Vue in Markdown (it
ends at an empty heading, as upstream ships it); and `config/README.md`, a
two-option reference whose sidebar VuePress builds from its headings
(`sidebar: auto`). `package.json` pins `vuepress` 1.9.7 and asks for Node
22. There are no tests and no lockfile.

**The source has no `.vuepress/config.js`.** It was never committed —
neither in vercel/examples nor in the vercel/vercel example it came from —
so the source builds a site titled "VuePress" (VuePress's own default) with
no navbar links and no sidebar. Vercel's live example
(vuepress-starter-template.vercel.app), which the template page shows, runs
the config create-vuepress-site generates: the title "Vuepress Docs
Boilerplate", three head tags (theme colour and Apple web-app metas), a
navbar of Guide, Config and VuePress (VuePress v1's documentation), and an
open "Guide" sidebar over the guide's two pages. Its compiled site data says
so. The port restores those parts of it — what changes the site — in
`src/.vuepress/config.js`, the title through the rename seam; the rest of
that config restates VuePress's defaults (`repo: ""`, `editLinks: false`,
`lastUpdated: false` …), and its demo components (`.vuepress/components`)
are used by no page the template ships, so neither comes back.

## VuePress 1 on Node 22

The runners' Node is 22. VuePress 1 builds with webpack 4, which hashes
module ids with md4, and OpenSSL 3 (Node 17 and later) refuses md4 unless
Node runs with `--openssl-legacy-provider`. webpack 4.47.0 — what
VuePress 1.9.7 resolves — falls back to its own WebAssembly md4 when
OpenSSL refuses it, so `vuepress build src` succeeds with no flag: the spike
built it on Node 26, where `crypto.createHash("md4")` throws
`ERR_OSSL_EVP_UNSUPPORTED`, in about six seconds (Server 2.3 s, Client
3.4 s), and the runners' Node 22 builds it in Baseline CI. pnpm 10.12.1
installs it (about 1,200 packages); the install scripts it blocks (core-js,
highlight.js, vuepress) print notices, and the build needs none of them.
Nothing is bumped: VuePress 1.9.7 as the template pins it. VuePress 2 is a
different framework (Vue 3, Vite) with a different config and theme; moving
to it is a product's choice, not a port's.

## How it maps to Cloudflare

| Vercel | Here | Why |
|---|---|---|
| Static output on Vercel's CDN | `src/.vuepress/dist` as Workers Static Assets, uploaded with `<repo>-web-<env>` | The site is static; the assets are the site |
| Each file at its own address | `html_handling: "none"` | VuePress links every page by its file: `/guide/using-vue.html` |
| A folder at its `index.html`, with or without the slash | One Worker, `apps/web/worker/index.ts` | `/guide/` and `/guide` both answer 200 on Vercel |
| VuePress's `404.html` for an address that matches nothing | `not_found_handling: "404-page"` | A missing page is a 404, never the home page |
| `vuepress build src` | `vuepress build src` through turbo | Unchanged |
| The live demo's title, navbar and sidebar | `src/.vuepress/config.js`, restored | The template's source lacks it |

## Every page at the address VuePress links it by

VuePress writes a folder's `README.md` as `<folder>/index.html` and every
other page as `<name>.html`, and every link it writes — the navbar, the
sidebar, the router's own — names that file: `/guide/`,
`/guide/using-vue.html`. Vercel's live example answers, for each address
(probed on 2026-11-12): `/`, `/index.html`, `/guide/`, `/guide`,
`/guide/index.html`, `/guide/using-vue.html` and `/config/` with 200, and
`/guide/using-vue`, `/no-such-page`, `/no-such.js` and
`/assets/js/missing.js` with 404 and VuePress's 404 page.

Workers Static Assets' default, `auto-trailing-slash`, would redirect every
`.html` address VuePress links to its extension-less form (307,
`/guide/using-vue.html` → `/guide/using-vue`) and `/guide` to `/guide/` —
a redirect on every link a reader shares, for an address that is not
VuePress's. So the assets serve files exactly as they are named
(`html_handling: "none"`), and the Worker answers what no file matches: an
address whose last segment has no extension is a folder, answered with its
`index.html` if it has one (`/guide/` and `/guide` alike; `/` is
`/index.html`); everything else — a missing page, an extension-less page
address (`/guide/using-vue`, which Vercel does not guess either), a missing
chunk — is handed to the assets, which answer with VuePress's `404.html`
and a 404 status (`not_found_handling: "404-page"`). VuePress's router has
no route for `/guide/using-vue` either (it redirects only `/index.html`,
`/guide/index.html` and `/config/index.html` to their folders), so the
server and the client agree.

One more switch makes the Worker see those requests at all. Since the
2025-04-01 compatibility date, a browser's navigation (`Sec-Fetch-Mode:
navigate`) that matches no file is answered by the assets' 404 page without
reaching the Worker (`assets_navigation_prefers_asset_serving`), so `/guide/`
clicked or typed in a browser would be a 404 while a bare `curl` got the
page — the first e2e run caught exactly that. `wrangler.jsonc` turns it off
(`assets_navigation_has_no_effect`), and the deploy's smoke fetches the home
page and the guide as a navigation, so a deploy that regressed it would fail
its smoke. The spike and the e2e tier read
every address of that list under `wrangler dev` and get Vercel's answer for
each.

## The site's name

The live example's title is "Vuepress Docs Boilerplate". It becomes
`SITE_NAME`, one literal at the top of `src/.vuepress/config.js`: the
rename seam a product's name is written into, which VuePress puts in every
page's `<title>` ("Introduction | <name>"), beside the navbar's home link and
as the home page's heading. VuePress 1 bakes no origin into the site — every
link is a path under its base, `/` — so the build reads nothing from the
environment, and the same build serves every workers.dev address and a
custom domain.

## The repository

gatsby-boilerplate's shape, the same static site behind one Worker from the
same `vercel/examples` family: `apps/web` (the pages, the config, the
Worker, the deploy contract), `tests/web` (vitest, over the sources and over
the built site — it depends on the app so turbo builds it first), the shared
TypeScript and ESLint configuration, the wrangler renderer, `ci.yml` byte for
byte gatsby-boilerplate's (turso-starter's but for one comment). The rename
engine is the same: the `<framework>-boilerplate` slug, which VuePress's
package, CLI and folder spell only as `vuepress`, so nothing of the
framework's needs masking, even for a product whose own slug contains the
word; the seam is `SITE_NAME` in `apps/web/src/.vuepress/config.js`.

## The alternatives rejected

**`auto-trailing-slash` and no Worker logic.** The simplest config, and the
one gatsby-boilerplate uses: but VuePress, unlike Gatsby, links pages by
their `.html`, so every shared link would be a 307 to an address VuePress
does not use, and `/guide/using-vue` — a 404 on Vercel — would answer 200.

**VuePress 2.** A newer framework under the same name (Vue 3, Vite or
webpack 5, a different config and default theme). The template is
VuePress 1; porting it to VuePress 2 would be a rewrite of its config and
theme, not a move to Cloudflare.
