const { generateWebpackConfig } = require('shakapacker')

// Shakapacker 9.x auto-wires the CSS and SCSS rules (css-loader + sass-loader +
// mini-css-extract-plugin's loader) whenever css-loader/sass-loader are present,
// and registers MiniCssExtractPlugin so stylesheet_pack_tag resolves the extracted
// CSS. We rely on that built-in behavior rather than hand-rolling our own style
// rules: the previous custom rules double-processed SCSS (a second scss rule ran
// alongside Shakapacker's) and dropped the extracted CSS entry from the manifest.
const config = generateWebpackConfig()

for (const rule of config.module.rules) {
  for (const loader of rule.use || []) {
    if (typeof loader === 'object' && loader.loader?.includes('sass-loader')) {
      loader.options ||= {}
      loader.options.api = 'modern'
      loader.options.sassOptions ||= {}
      // Prevent Dart Sass from emitting a BOM in extracted CSS; an internal BOM breaks the Open Iconic @font-face rule.
      loader.options.sassOptions.charset = false
    }
  }
}

module.exports = config
