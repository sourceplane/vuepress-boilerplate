# vuepress-boilerplate — implementation status

| Milestone | State | Landed |
|---|---|---|
| VP0 — the spec | ✅ | the repository's first commit and VP-1 |
| VP1 — the site on Workers | ✅ | VP-2 |
| VP2 — a baseline | planned | VP-3 |

## Departures from the upstream template

Everything not listed here is the template as it is in vercel/examples at
`a4b4827` (`framework-boilerplates/vuepress`, last changed in `cb2643e`):
`src/index.md`, `src/guide/README.md`, `src/guide/using-vue.md` and
`src/config/README.md` are byte for byte upstream's, and `vuepress` stays
pinned at 1.9.7.

| # | What | Why |
|---|---|---|
| 1 | New `src/.vuepress/config.js`: the live demo's title as `SITE_NAME` ("Vuepress Docs Boilerplate", one literal at the top of the file), its three head tags, its navbar (Guide, Config, VuePress) and its "Guide" sidebar | The template's source ships no config, so it builds a site titled "VuePress" with no navbar or sidebar; Vercel's live example runs create-vuepress-site's config. One rename seam (risk VP-C) |
| 2 | Upgrading to VuePress 2 is out of scope | A different framework under the same name; the port keeps the template's VuePress 1 |
| 3 | The package is `@app/web`; `vuepress` stays a devDependency at 1.9.7; `build` stays `vuepress build src`, `dev` gains `--port 3000`, and `preview` (`wrangler dev`), `typecheck` (`tsc` over the Worker) and `lint` (`eslint .`) are added | The workspace's `dev` / `typecheck` / `lint` / `test` / `build` contract |
| 4 | No `NODE_OPTIONS=--openssl-legacy-provider` | webpack 4.47.0 hashes with its own md4 when OpenSSL 3 refuses it (risk VP-B) |
| 5 | `wrangler.jsonc` names the Worker `<repo>-web`, with `main: ./worker/index.ts`, the `ASSETS` binding over `src/.vuepress/dist`, `html_handling: "none"`, `not_found_handling: "404-page"` and the `assets_navigation_has_no_effect` compatibility flag; `worker/index.ts` answers a folder with its `index.html` and hands everything else to the assets | Every address answered as Vercel's live example answers it: `.html` pages and folders 200, an address that matches nothing VuePress's 404 page with a 404 — for a browser's navigation too, which the assets would otherwise answer with the 404 page before the Worker sees it |
| 6 | `eslint.config.mjs`: the shared TypeScript config over the Worker; `src/.vuepress/config.js` parsed as CommonJS, with no rules added | The template ships no lint config; a syntax error still fails `pnpm lint` |
| 7 | Tests: `tests/web` (vitest) — the name seam and the config, the build scripts, the Worker's addresses, the wrangler config, the template's pages, the licence, and the site `vuepress build` wrote (its pages and titles, the navbar and sidebars, the scripts and stylesheets its pages name, the 404 page) | The template ships no tests |
| 8 | `apps/web/src/.vuepress/dist/`, `.temp/` and `.cache/` are ignored by git, the blueprint and the leak gate | What a build generates is a build's, not the site's |
| 9 | pnpm 10.12.1 and a committed lockfile; the template has neither a lockfile nor a package manager pin | The lockfile records what the site was proven on (webpack 4.47.0 among it) |
