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
        blue: {
          100: "#cedbf2",
          600: "#718096",
          700: "#4a5568",
          800: "#2d3748"
        },
        gray: {
          700: "#595959",
          800: "#333333",
          900: "#202020"
        }
      }
    },
  },
  variants: {},
  plugins: [],
}
