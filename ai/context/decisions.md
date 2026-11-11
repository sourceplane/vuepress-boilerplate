# vuepress-boilerplate — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | A static build served as Workers Static Assets behind one Worker; no adapter, no server rendering | VuePress builds every page at `vuepress build`; nothing renders at request time | design.md, "How it maps to Cloudflare" |
| 2 | VuePress 1.9.7 (Vue 2.7, webpack 4.47), as the template pins it; no OpenSSL legacy flag | webpack 4.47 hashes with its own md4 on OpenSSL 3, so it builds on Node 22 unchanged; VuePress 2 is another framework | design.md, "VuePress 1 on Node 22"; risk VP-B |
| 3 | `html_handling: "none"`, and a Worker that answers a folder with its `index.html`; `assets_navigation_has_no_effect` so a browser's navigation reaches it | VuePress links every page by its file (`/guide/using-vue.html`); Vercel answers each address as named, a folder with or without its slash, and no redirect; without the flag a navigation to `/guide/` is the 404 page | design.md, "Every page at the address VuePress links it by" |
| 4 | `not_found_handling: "404-page"`, not single-page-app fallback | A request matching no page is a missing page: VuePress's 404 page with a 404 status, as Vercel serves it; `/guide/using-vue` included | design.md; risk VP-G |
| 5 | The live demo's config restored in `src/.vuepress/config.js` (title, head tags, navbar, sidebar) | The template's source ships none; the demo Vercel's template page shows runs create-vuepress-site's | IMPLEMENTATION-STATUS, departure 1; risk VP-C |
| 6 | The site's name is one seam, `SITE_NAME` in `apps/web/src/.vuepress/config.js` ("Vuepress Docs Boilerplate", the demo's title) | One place a product's identity is written; VuePress puts it in every title, the navbar and the home heading | IMPLEMENTATION-STATUS, departure 1 |
| 7 | The build reads no origin | VuePress 1 writes every link as a path under `/`; the same build serves workers.dev and a custom domain | design.md, "The site's name" |
| 8 | No infra root: the site binds nothing | Nothing to provision; `infra/` and `packages/` stay as empty discovery roots | README |
| 9 | One landing (`01-product`) then the record (`03-docs`); each bootstrap pull request checked in the box | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the site for real (docusaurus, cirrus-baseline baseline-v22) | `repo-blueprint.yaml` |
| 10 | stack-tectonic 0.19.0, not 0.20.0 | The siblings' pin; 0.20.0's lane-shared install is a layout this build has not been verified in | risk VP-F |
| 11 | Component docs are generated from the manifests and checked in CI | A hand-written copy of the component's facts drifts silently | `tooling/catalog/gen-component-docs.py` |
