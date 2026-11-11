# vuepress-boilerplate — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted and resolved ones, is
`specs/epics/vuepress-boilerplate/risks-and-open-questions.md`; this page lists
only what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| VP-A | `baseline-v1` is not yet proven live | OPEN | One console bootstrap from `baseline-v1` |
| VP-D | The home page's hero image is served by VuePress v1's documentation site | WATCH | A product replacing the hero, or the image vendored into `src/.vuepress/public/` |

Accepted, and worth knowing before you change them: VP-B (VuePress 1 and
webpack 4 on the runners' Node, with no OpenSSL legacy flag), VP-C (the
site's config is the live demo's, restored), VP-E (pnpm 10 skips VuePress's
dependencies' install scripts, which the build does not need), VP-G (an
extension-less page address is a 404, as on Vercel), VP-H (VuePress 1's
build toolchain carries known advisories; none of it ships), VP-I (pnpm's
unused `@vue/compiler-sfc` 3 peer).
