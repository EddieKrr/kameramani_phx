// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/kameramani_phx.ex",
    "../lib/kameramani_phx_web/**/*.*ex",
  ], 
  theme: {
    extend: {
      fontFamily: {
        sans: ["Raleway", "sans-serif"],
        heading: ["Space Grotesk", "sans-serif"],
        title: ["Bitcount Grid Double", "system-ui"],
        title2: ["Bebas Neue", "system-ui"],
      },
     
      colors: {
        // Surfaces
        brand: "#1E40AF",
        "brand-light": "#3B82F6",
        "brand-dark": "#1E3A8A",
        "background": "#F9FAFB",
        "surface": "#FFFFFF",
      },
    },
  },

  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
  ],
};