import shared from "../../tooling/eslint/index.js";

// The shared config lints TypeScript: here, the Worker. The site's config
// (src/.vuepress/config.js) is CommonJS, as VuePress 1 loads it; it is
// parsed (a syntax error fails lint) with no rules of ours on top. The
// template's pages are Markdown, which ESLint does not read. VuePress's build
// output (src/.vuepress/dist) is not a source.
export default [
  ...shared,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: { module: "writable", require: "readonly" },
    },
  },
  { ignores: ["src/.vuepress/dist/**"] },
];
