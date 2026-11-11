# vuepress-boilerplate — operating contract (for humans and agents)

This is the standing guide to how this site is deployed and operated.
Instance facts (live URLs, workspace, the secrets it uses) live in
[deployment.md](deployment.md), rendered from probed reality by the
bootstrap's `03-docs` phase; this file is the contract that stays true
between deployments. It is written to give an agent with repository read
access enough context to reason about and operate the site without any
other source.

## What this system is

A VuePress docs site on Cloudflare alone, expressed as an Orun
component-native desired-state repo.

- **`apps/web`** — the site: VuePress 1, built fully static. `vuepress build
  src` writes an HTML file per page (`index.html`, `guide/index.html`,
  `guide/using-vue.html`, `config/index.html`, `404.html`) and the hashed
  JavaScript and CSS the Vue app hydrates with to `src/.vuepress/dist`,
  which deploys as Workers Static Assets behind one small Worker
  (`worker/index.ts`). The assets serve each file at the address it is
  named by (`html_handling: none`); the Worker answers a folder with its
  `index.html` (`/guide/`, `/guide`), and anything else that matches no
  file is answered with VuePress's 404 page and a 404 status
  (`not_found_handling: 404-page`). There is no database, no server
  rendering and no runtime secret.
- **`tests/web`** — the site-identity, config, build, Worker, template-page
  and built-site tests (vitest), verified on the `dev` rung.
- **`tooling/*`** — shared TypeScript and ESLint configuration, and the
  deploy-time wrangler renderer for workers that take wiring.

Environments: **`stage`** and **`prod`** are deployed; **`dev` is
verify-only by design** — lanes build and test, nothing deploys.

## Identity and tenancy

Every remote operation runs against ONE Orun workspace, declared in
`intent.yaml` under `execution.state.workspace` — committed, enforced, and
what CI uses. Do not remove it; headless credentials depend on it. If it
reads `ws_SET_ME`, the bootstrap had no workspace to write: set the real one
before anything else.

## How deployment works

1. Merge (or push) to `main`.
2. CI (`.github/workflows/ci.yml`) runs `orun plan --changed` — only
   components whose files changed are planned — then runs each planned lane
   with `orun run --remote-state`, authenticated by GitHub OIDC (the
   exchange resolves this repository's linked workspace server-side).
3. `apps/web` builds once per environment (`vuepress build src`; the site
   bakes in no origin), then `wrangler deploy` ships
   `vuepress-boilerplate-web-<env>` with `src/.vuepress/dist` as its assets,
   and a smoke test fetches `/` (VuePress's home page and the app script it
   names), `/guide/` and `/guide/using-vue.html`, and checks that a page
   that does not exist is the 404 page with a 404 status.
4. `prod` deploys after `stage` has converged on the same commit
   (`environments.prod.promotion` in intent.yaml).
5. **The convergence run is the deployment.** A green run means every
   planned lane applied. Failed lanes are retried with
   `gh run rerun --failed`, which resumes the same execution.

Caveats that matter:

- A push that touches no component files plans zero lanes — that run is
  green and deployed nothing. Never treat "latest run green" as "site
  converged"; probe the URLs instead.
- A change to `intent.yaml` alone maps to no component and redeploys nothing
  on its own. Land it with a change under `apps/web`.
- The build runs with its dependencies inside the job's own tree, as
  `intent.yaml`'s stack-tectonic 0.19.0 pin plans it (its comment says why).
  Do not bump it without building `apps/web` in a job tree staged the way
  the new composition plans it.
- Every page is a file, served at the address VuePress links it by. A page
  added as `apps/web/src/guide/deploy.md` is `/guide/deploy.html`; a folder's
  `README.md` is the folder (`/about/`, and `/about` too). A page that does
  not exist — `/guide/deploy` without its `.html` included — is the 404 page
  with a 404 status, never the home page. List a new page in the sidebar in
  `apps/web/src/.vuepress/config.js`, and change the smoke in
  `apps/web/component.yaml` if you replace the guide it reads.
- The build bakes in no origin. Setting `SITE_URL` for an environment in
  `intent.yaml` changes nothing the site serves; the deployment record
  probes it.

## Secrets model

- **Brokered provider secrets**: `CLOUDFLARE_API_TOKEN` (Workers deploy
  scope) and `CLOUDFLARE_ACCOUNT_ID` — pointers minted per run from the
  workspace's Cloudflare connection. No long-lived values at rest; nothing
  to rotate by hand.
- Inspect by NAME only: `orun secrets list --org <ws> --project` and
  `--env stage|prod`. No tooling in this repository prints a secret value,
  and no document in `ai/context/` may contain one.
- The site needs no runtime secret.

## Verifying the system

```bash
# the site on each environment (also recorded, probed, in deployment.md)
curl -s -o /dev/null -w '%{http_code}\n' https://vuepress-boilerplate-web-stage.your-workers-subdomain.workers.dev/
curl -s -o /dev/null -w '%{http_code}\n' https://vuepress-boilerplate-web-prod.your-workers-subdomain.workers.dev/guide/using-vue.html
curl -s -o /dev/null -w '%{http_code}\n' https://vuepress-boilerplate-web-prod.your-workers-subdomain.workers.dev/no-such-page   # 404

# workspace readiness (integrations + repository link)
orun integrations list --org <ws> --json && orun cloud check --org <ws>
```

## Common operations

| task | how |
|---|---|
| add a page | add a file under `apps/web/src/pages/` (`about.js` → `/about/`), merge |
| add a plugin | add it to `plugins` in `apps/web/src/.vuepress/config.js` (and to `apps/web/package.json`), merge |
| rename the site | edit `apps/web/src/.vuepress/config.js` (`SITE_NAME`), merge |
| deploy a change | merge to `main`; watch the run; failed lanes → `gh run rerun --failed` |
| deploy by hand | Orunbase's Deploy button, or `gh workflow run ci.yml --ref main -f environment=<env> [-f component=<a,b>]` — the named components (blank: every one) run in that environment as a merge runs them; started off `main` it is refused |
| redeploy without a change | edit the last line of `apps/web/component.yaml` (`# orun: redeploy <reason> <stamp>`) and merge — it is a deploy trigger, nothing reads it |
| serve a custom domain | attach it to the Worker in Cloudflare and set `SITE_URL` for the environment in `intent.yaml` — the deployment record probes it (README, "Custom domain") — then replace the placeholder `vuepress-boilerplate.example.com` in `intent.yaml`'s `BASE_DOMAIN` (dev, stage and prod) with it |
| add a runtime secret | `orun secrets set <KEY> --org <ws> --env <env>` |
| headless credentials | `ORUN_TOKEN` (workspace-scoped) + `GITHUB_TOKEN` |

The deployment record is the bootstrap's `03-docs` phase. Re-running it (the
Orun console's Retry on that phase, or `orun new … --phase 03-docs`)
re-probes the URLs and re-renders [deployment.md](deployment.md); it is
idempotent.

## Evolution

A route the static site cannot answer (a redirect, an API, a header) goes in
`apps/web/worker/index.ts`, in front of the assets. Structural changes (a
second Worker, a data store) follow the same
contract that deployed the site: add a component under `apps/`, `infra/` or
`packages/` with a `component.yaml`, land it as a pull request, and the
convergence run applies it.
