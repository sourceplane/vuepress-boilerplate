# vuepress-boilerplate

Vercel's [VuePress](https://github.com/vercel/examples/tree/main/framework-boilerplates/vuepress)
template — a VuePress 1 docs site: the home page with its hero and three
features, a two-page guide under its sidebar and a config reference, under
the navbar — running on **Cloudflare Workers + Static Assets**, and packaged
as an **Orun baseline**: one command takes a new VuePress site from nothing
to live on stage and prod, in its own repository, under its own name.

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
the site's name is one literal in `src/.vuepress/config.js`. What the
baseline adds is everything needed to make a copy of it somebody else's —
built the way [cirrus-baseline](https://github.com/sourceplane/cirrus-baseline)
is. See [`specs/epics/vuepress-boilerplate`](specs/epics/vuepress-boilerplate/README.md)
for the design, the milestones and the as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/vuepress-boilerplate
cd vuepress-boilerplate
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-docs --run-hooks --resume \
  --set reponame=acme-docs --set productname="Acme Docs" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`vuepress-boilerplate` → Build). Two phases — `01-product` (the repository
created, then the whole site in one pull request, deployed to stage and prod
and smoke-tested) and `03-docs` (the live deployment recorded) — each landing
one pull request in the new repository. **[BOOTSTRAP.md](BOOTSTRAP.md)** is
the operator guide; [docs/phases/](docs/phases/README.md) has a page per
phase.

The new repository receives the **site only** — the site and its tests, its
CI, its tooling, a README of its own and its operating contract — renamed
throughout to the site's name, repository and Cloudflare Worker. None of this
repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README and context pack | `.baseline/product/README.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

The framework's name is not the site's: VuePress's package (`vuepress`), its
CLI (`vuepress build src`), its folder (`src/.vuepress`) and the navbar's link
to its documentation spell `vuepress` but never this repository's slug, so
the rename engine has nothing of the framework's to mask — even for a site
whose own slug contains the word. The site's display name is one literal,
`SITE_NAME` in `apps/web/src/.vuepress/config.js` ("Vuepress Docs
Boilerplate", the title of Vercel's live example), which VuePress puts in
every page's `<title>`, the navbar and the home page's heading; the
placement tier fails on any placed site that spells it anywhere else, or
whose build or navbar no longer names VuePress.

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
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built in a staged job tree, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |

## Credits

The site is Vercel's VuePress example
([vercel/examples](https://github.com/vercel/examples),
`framework-boilerplates/vuepress`, © 2023 Vercel, MIT — `apps/web/LICENSE.md`)
at vercel/examples `a4b4827` (the folder last changed in `cb2643e`). Its
`src/.vuepress/config.js` restores the config of Vercel's live example,
which create-vuepress-site generates.
