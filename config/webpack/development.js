process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const webpackConfig = require('./environment')

module.exports = webpackConfig
