// The site's name — the one place it is spelled. SITE_NAME is the rename
// seam: a product built from this baseline gets its own display name written
// here, and VuePress puts it in every page's <title>, beside the logo in the
// navbar and as the home page's heading.
//
// The template's source ships no .vuepress/config.js: built as it is, the
// site is titled "VuePress" (VuePress's own default), with no navbar links
// and no sidebar. Vercel's live example of the template runs the config
// create-vuepress-site generates; this file restores the parts of it that
// change the site — its title, its head tags, the navbar and the guide's
// sidebar. (The rest of that config only restates VuePress's defaults.)
const SITE_NAME = "Vuepress Docs Boilerplate";

module.exports = {
  title: SITE_NAME,
  head: [
    ["meta", { name: "theme-color", content: "#3eaf7c" }],
    ["meta", { name: "apple-mobile-web-app-capable", content: "yes" }],
    ["meta", { name: "apple-mobile-web-app-status-bar-style", content: "black" }],
  ],
  themeConfig: {
    nav: [
      { text: "Guide", link: "/guide/" },
      { text: "Config", link: "/config/" },
      { text: "VuePress", link: "https://v1.vuepress.vuejs.org" },
    ],
    sidebar: {
      "/guide/": [
        {
          title: "Guide",
          collapsable: false,
          children: ["", "using-vue"],
        },
      ],
    },
  },
};
