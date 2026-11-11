# vuepress-boilerplate

Vercel's [VuePress](https://github.com/vercel/examples/tree/main/framework-boilerplates/vuepress)
template — a VuePress 1 docs site: the home page with its hero and three
features, a two-page guide under its sidebar and a config reference, under
the navbar — running on **Cloudflare Workers + Static Assets**, deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (VP2).

VuePress builds fully static: `vuepress build src` writes an HTML file for
every page (`index.html`, `guide/index.html`, `guide/using-vue.html`,
`config/index.html`, `404.html`) and the hashed JavaScript and CSS the Vue
app hydrates and navigates with to `src/.vuepress/dist`. That folder is
uploaded as Workers Static Assets with one small Worker in front: every file
is served at the address VuePress links it by (a `.html` page at its
`.html`), a folder at its `index.html` with or without the slash, and a
request that matches nothing — a missing page, an extension-less page
address, a missing chunk — is answered with VuePress's 404 page and a 404
status, address for address as Vercel answers them. The pages do not change;
the site's name is one literal in `src/.vuepress/config.js`. See [`specs/epics/vuepress-boilerplate`](specs/epics/vuepress-boilerplate/README.md)
for the design, the milestones and the as-built status.

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name, head tags, navbar and the guide's sidebar | `apps/web/src/.vuepress/config.js` |
| The home page, the guide and the config reference (the template's, byte for byte) | `apps/web/src/index.md`, `apps/web/src/guide/`, `apps/web/src/config/README.md` |
| The Worker in front of the assets, its config, deploy contract | `apps/web/worker/index.ts`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests (the name seam and the config, the build, the Worker's addresses, the template's pages, the built site) | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck        # tsc: the Worker
pnpm lint             # eslint: the Worker, and the site's config parsed
pnpm test             # vitest (tests/web), after vuepress build
pnpm build            # vuepress build src → apps/web/src/.vuepress/dist
```

```bash
pnpm --filter @app/web dev        # vuepress dev on http://localhost:3000
pnpm --filter @app/web preview    # wrangler dev over the built site and its Worker
```

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Static output on Vercel's CDN, from its VuePress framework preset | Workers Static Assets: `src/.vuepress/dist` uploaded with the Worker `<repo>-web-<env>` (`apps/web/wrangler.jsonc`) |
| The template's build (`vuepress build src`) | `vuepress build src` (VuePress 1.9.7, Vue 2.7, webpack 4.47) through turbo, on Node 22 with no OpenSSL legacy flag |
| Each file served at its own address (`/guide/using-vue.html` is that page, not a redirect) | `html_handling: "none"`: the assets serve each file exactly as it is named |
| A folder answered with its `index.html`, with or without the slash (`/guide/`, `/guide`) | The Worker (`apps/web/worker/index.ts`): an address with no extension tries the folder's `index.html`; `assets_navigation_has_no_effect` lets a browser's navigation reach it too |
| Vercel serving VuePress's `404.html` for an address that matches nothing (including `/guide/using-vue`) | `not_found_handling: "404-page"`: VuePress's 404 page with a 404 status, for a page, a folder or a chunk |
| The site title, navbar and sidebar of Vercel's live example (its config is not in the template's source) | `src/.vuepress/config.js`, restored from the live example, its title the `SITE_NAME` seam |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |

## Credits

The site is Vercel's VuePress example
([vercel/examples](https://github.com/vercel/examples),
`framework-boilerplates/vuepress`, © 2023 Vercel, MIT — `apps/web/LICENSE.md`)
at vercel/examples `a4b4827` (the folder last changed in `cb2643e`). Its
`src/.vuepress/config.js` restores the config of Vercel's live example,
which create-vuepress-site generates.
