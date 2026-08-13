const { generateWebpackConfig } = require('shakapacker')

// Shakapacker 9.x auto-wires the CSS and SCSS rules (css-loader + sass-loader +
// mini-css-extract-plugin's loader) whenever css-loader/sass-loader are present,
// and registers MiniCssExtractPlugin so stylesheet_pack_tag resolves the extracted
// CSS. We rely on that built-in behavior rather than hand-rolling our own style
// rules: the previous custom rules double-processed SCSS (a second scss rule ran
// alongside Shakapacker's) and dropped the extracted CSS entry from the manifest.
module.exports = generateWebpackConfig()
