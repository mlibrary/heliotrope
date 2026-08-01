var path = require("path");
var os = require("os");

var webpackConfig = require('./webpack.config.js');
webpackConfig.output = {
   filename: '[name].js',
   sourceMapFilename: '[name].map.js',
   library: "cozy",
   libraryTarget: "umd",
   libraryExport: "default",
};

function getSpecs(specList) {
  if (specList) {
    return specList.split(',')
  } else {
    return ['spec/**/*Spec.js'] // whatever your default glob is
  }
}

// Karma configuration
module.exports = function (config) {
  var files = [
    //"node_modules/sinon/pkg/sinon.js",
    "node_modules/expect.js/index.js",
    "node_modules/happen/happen.js",
    //"node_modules/prosthetic-hand/dist/prosthetic-hand.js",
    "spec/SpecHelper.js",
    {pattern: 'spec/fixtures/**/*', watched: false, included: false, served: true},
    {pattern: 'vendor/**/*', watched: false, included: false, served: true},
  ];

  if ( process.env.KARMA_USE_DIST ) {
    files.unshift("dist/cozy-sun-bear.js");
  } else {
    files.unshift("src/cozy.js");
  }

  var exclude = [
  ];

  config.set({
    // base path, that will be used to resolve files and exclude
    basePath: '',

    // plugins
    plugins: [
      'karma-webpack',
      'karma-mocha',
      'karma-coverage',
      'karma-coveralls',
      'karma-sourcemap-loader',
      'karma-chrome-launcher',
      'karma-safari-launcher',
      'karma-firefox-launcher'],

    // frameworks to use
    frameworks: ['mocha', 'webpack'],

    // list of files / patterns to load in the browser
    files: files.concat(getSpecs(process.env.KARMA_SPECS)),

    // list of files / patterns to exclude from invoking
    exclude: exclude,

    // Rollup the ES6 Cozy sources into just one ES5 file, before tests
    preprocessors: {
      'src/cozy.js': ['webpack', 'sourcemap'],
    },

    webpack: webpackConfig,

    // test results reporter(s) to use possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['dots', 'coverage', 'coveralls', 'progress'],
    coverageReporter: {
      type: 'lcov',
      dir: 'coverage/'
    },

    // web server port
    port: 9876,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    // logLevel: config.LOG_INFO,
    logLevel: process.env.LOG_LEVEL ? config[process.env.LOG_LEVEL] : config.LOG_INFO,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: false,

    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera
    // - Safari (only Mac)
    // - PhantomJS
    // - IE (only Windows)
    // browsers: ['PhantomJSCustom'],
    browsers: ['ChromeHeadless'],
    customLaunchers: {
      // 'PhantomJSCustom': {
      //  base: 'PhantomJS',
      //  flags: ['--load-images=true'],
      //  options: {
      //    onCallback: function (data) {
      //      if (data.render) {
      //        page.render(data.render);
      //      }
      //    }
      //  }
      // }
    },

    browserConsoleLogOptions: {
          level: 'log',
          format: '%b %T: %m',
          terminal: process.env.USE_CONSOLE ? true : false
    },

    client: {
      captureConsole: process.env.USE_CONSOLE ? true : false,
      mocha: {
        bail: true
      }
    },

    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 100000,

    // Workaround for PhantomJS random DISCONNECTED error
    browserDisconnectTimeout: 100000, // default 2000
    browserDisconnectTolerance: 1, // default 0

    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: true
  });
};
