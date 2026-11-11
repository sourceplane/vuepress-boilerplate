# vuepress-boilerplate — Vercel's VuePress template on Cloudflare Workers

**VuePress builds fully static, so the port is where the site is served —
`src/.vuepress/dist` as Cloudflare Workers Static Assets behind one small
Worker, every page at the address VuePress links it by and a missing one
VuePress's 404 page with a 404 status, address for address as Vercel answers
them, deployed by Orun to stage and prod on every merge — and then the
baseline that makes a copy of it somebody else's site in one landing.**

| | |
|---|---|
| Status | ✅ Shipped (`baseline-v1`) — proven offline in Baseline CI; not yet live (risk VP-A) |
| Upstream | [vercel/examples](https://github.com/vercel/examples) `framework-boilerplates/vuepress` (MIT), at `a4b4827` (2026-11-06; the folder last changed in `cb2643e`, 2025-12-12): VuePress 1.9.7 on Vue 2.7 |
| Reference | [gatsby-boilerplate](https://github.com/sourceplane/gatsby-boilerplate) — the same `vercel/examples` framework boilerplate, a static site behind one Worker, its tests and its bootstrap; [docusaurus](https://github.com/sourceplane/docusaurus) — a docs site built the same way |
| Key | `VP` |

## Read in this order

1. [design.md](design.md) — the template and the config its live demo runs,
   VuePress 1 on Node 22, how each Vercel piece maps to Cloudflare, why each
   page is served at its own address, the site's name, the repository, and
   the alternatives rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and
   what each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream template.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| VP0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | VP-1 |
| VP1 — the site on Workers | the template in `apps/web` with its live demo's config, built static by `vuepress build`, served as assets behind one Worker at Vercel's addresses, with its tests | VP-2 |
| VP2 — a baseline | the console card, the build document, the context pack and the baseline's tests | VP-3 |
