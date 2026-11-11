# vuepress-boilerplate — implementation plan

Three milestones, each one reviewed pull request (VP0 follows the
repository's first commit), each green before it merges.

## VP0 — the spec (VP-1)

The repository is born: `intent.yaml` with the placeholder workspace
`ws_CHANGE_ME`, `ci.yml` (byte for byte gatsby-boilerplate's,
turso-starter's but for one comment, which plans nothing until the
workspace is set), the shared TypeScript and ESLint configuration, the spec
index, this doc set and the task contracts.

## VP1 — the site on Workers (VP-2)

- The template in `apps/web` on VuePress 1.9.7: `src/index.md`,
  `src/guide/README.md`, `src/guide/using-vue.md` and `src/config/README.md`
  as they are; `src/.vuepress/config.js` restoring the live demo's title
  (the name seam, `SITE_NAME`), head tags, navbar and the guide's sidebar.
- `worker/index.ts` and `wrangler.jsonc`: the Worker in front of
  `src/.vuepress/dist`, files served at the address they are named by, a
  folder answered with its `index.html`, VuePress's 404 page for anything
  else.
- `component.yaml`: the deploy contract and its smoke over the home page,
  its app script, the guide's two addresses and a missing page's 404.
- Tests (`tests/web`): the name seam and the config, the build, the Worker's
  addresses and its config, the template's pages, and the built site.
- The README's "How it maps to Vercel".

## VP2 — a baseline (VP-3)

gatsby-boilerplate's machinery, renamed: `blueprint.yaml`,
`repo-blueprint.yaml`, `.baseline/` (identity, product README, task
contracts), `tooling/rebrand` (the same engine and rules, the seam at
`apps/web/src/.vuepress/config.js`), `tooling/bootstrap`,
`hooks/render-deployment-docs.sh` (probing `/`, the guide and each
`SITE_URL`, with the standard library only), `docs/phases/`, the context
pack, `testing/` (the leak and placement gates on this tree's files,
placement also failing on the template's name left in the site or the
framework's own names renamed; the e2e tier building the site in the stage
lane's staged tree, checking every page is titled with the product's name,
and reading every address Vercel's live example answers) and
`baseline.yml` / `tag.yml`.
