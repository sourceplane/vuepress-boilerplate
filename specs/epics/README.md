# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`vuepress-boilerplate/`](./vuepress-boilerplate/) | **VP** | In progress (VP1: the site on Workers) | Vercel's VuePress template — a VuePress 1 docs site, with its live demo's config — built static and served as Cloudflare Workers Static Assets behind one Worker, every page at the address VuePress links it by and a missing one VuePress's 404 page, and an Orun baseline that instantiates it (VP2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
