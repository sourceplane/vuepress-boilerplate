# vuepress-boilerplate — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's VuePress template — a VuePress 1 docs site, with the config of its
live demo restored — built fully static by `vuepress build` and served as
Cloudflare Workers Static Assets behind one Worker, every page at the
address VuePress links it by and a missing one VuePress's 404 page,
packaged as an Orun baseline: `orun new
--blueprint repo-blueprint.yaml` builds a new VuePress site in its own
repository and takes it to live on stage and prod in one landing
(`01-product`), then records what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — VP0–VP2: the template on Workers, and the baseline |
| Proven live | No — proven offline in Baseline CI only (risk VP-A) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/vuepress-boilerplate/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/vuepress-boilerplate/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/vuepress-boilerplate/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/web/docs/`, `tests/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Bootstrap one site from `baseline-v1` from the console, and record its
   timings against the 5-minute estimate (closes VP-A).
