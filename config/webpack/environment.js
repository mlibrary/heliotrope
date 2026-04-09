const { generateWebpackConfig } = require('shakapacker')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

// Generate base config
const webpackConfig = generateWebpackConfig()

// Find and remove any existing CSS rules to avoid conflicts
webpackConfig.module.rules = webpackConfig.module.rules.filter(rule => {
  // Remove any rule whose test regex matches a plain .css file
  if (rule.test instanceof RegExp && rule.test.test('test.css')) return false
  return true
})

// Add our CSS handling rule — always extract to files so stylesheet_pack_tag works in all environments
webpackConfig.module.rules.push({
  test: /\.css$/i,
  use: [
    MiniCssExtractPlugin.loader,
    {
      loader: 'css-loader',
      options: {
        importLoaders: 0,
        modules: false
      }
    }
  ]
})

// Remove any existing MiniCssExtractPlugin instances and add our configured one
webpackConfig.plugins = webpackConfig.plugins.filter(
  plugin => !(plugin instanceof MiniCssExtractPlugin)
)
webpackConfig.plugins.push(new MiniCssExtractPlugin({
  filename: 'css/[name]-[contenthash:8].css',
  chunkFilename: 'css/[name]-[contenthash:8].chunk.css'
}))

module.exports = webpackConfig
