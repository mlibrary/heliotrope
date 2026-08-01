// Needed to create files loadable by IE8
const commonjs = require('rollup-plugin-commonjs');
const nodeResolve = require('rollup-plugin-node-resolve');
const babel = require('rollup-plugin-babel');
const polyfill = require('rollup-plugin-polyfill');

// --- rollupGitVersion doesn't fit our workflow at the moment;
// import rollupGitVersion from 'rollup-plugin-git-version'
const json = require('rollup-plugin-json');

const gitRev = require('git-rev-sync');

// const branch = gitRev.branch();
const rev = gitRev.short();

// this explicit version doesn't seem useful at this point
// const version = require('../package.json').version + '+' + branch + '.' + rev;
const version = require('../package.json').version + rev;

const now = (new Date()).getTime();
const limit = now + 5 * 60 * 1000;  // 5 minutes, in milliseconds
const yyyy = (new Date()).getYear() + 1900;

const banner = `/*
 * Cozy Sun Bear ` + version + `, a JS library for interactive books. http://github.com/mlibrary/cozy-sun-bear
 * (c) ${yyyy} Regents of the University of Michigan
 */`;

module.exports = {
  input: 'src/cozy.js',
  output: {
    file: 'dist/cozy-sun-bear.js',
    name: 'cozy',
    format: 'umd',
    sourcemap: true,
    banner: banner
  },
  plugins: [
    // rollupGitVersion(),
    json({
        // exclude: 'package.json' // uncomment this if we enable rollupGitVersion
    }),
    nodeResolve({ jsnext: true, main: true }),
    babel({
      babelrc: false,
      runtimeHelpers: true,
      externalHelpers: false,
      presets: [
        [
          "env",
          {
            "modules": false
          }
        ],
      ],
      exclude: [ 'node_modules/**' ]
      // adding epubjs/** here causes the import to fail
      // , include: [ 'src/**' ]
    }),
    commonjs({
    }),
    polyfill('src/cozy.js', ['url-polyfill', 'classlist-polyfill', 'intersection-observer'])
  ]
};
