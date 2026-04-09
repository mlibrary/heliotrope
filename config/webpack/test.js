process.env.NODE_ENV = process.env.NODE_ENV || 'test'

const webpackConfig = require('./environment')

module.exports = webpackConfig
