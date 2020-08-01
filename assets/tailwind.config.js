module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {
      colors: {
        gray: {
          600: "#718096",
          700: "#333333",
          800: "#202020"
        }
      }
    },
  },
  variants: {},
  plugins: [],
}
