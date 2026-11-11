# apps/web — the VuePress site

A VuePress 1 docs site — Vercel's VuePress example (MIT, `LICENSE.md`), with
the config of its live demo — built fully static by `vuepress build src` and
served as Cloudflare Workers + Static Assets:

- the home page in `src/index.md` — the hero image, the Quick Start action,
  the three features and the footer
- the guide in `src/guide/` — the introduction (`README.md`) and "Using Vue
  in Markdown" (`using-vue.md`), under the guide's sidebar
- the config reference in `src/config/README.md`, its sidebar built from its
  headings
- `src/.vuepress/config.js`: the site's name (`SITE_NAME`, the title of every
  page, the navbar's and the home page's heading), the head tags, the navbar
  (Guide, Config, VuePress) and the guide's sidebar

`vuepress build src` writes an HTML file per page and the hashed JavaScript
and CSS to `src/.vuepress/dist`. The assets serve each file at the address
it is named by (`html_handling: "none"` in `wrangler.jsonc`), and
`worker/index.ts` sits in front: a folder is answered with its `index.html`
(`/guide/`, `/guide`), and anything else that matches no file is answered
with VuePress's 404 page and a 404 status (`not_found_handling: "404-page"`).

```bash
pnpm dev        # vuepress dev on http://localhost:3000
pnpm build      # vuepress build src → src/.vuepress/dist
pnpm preview    # wrangler dev over the built site, behind worker/index.ts
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
