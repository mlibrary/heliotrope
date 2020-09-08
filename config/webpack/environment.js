const { environment } = require('@rails/webpacker')

// To avoid having to import $ from 'jquery' in every file that uses jQuery, make the following change to config/webpack/environment.js:
const webpack = require('webpack')
environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Cookies: 'js-cookie'
}))

module.exports = environment
