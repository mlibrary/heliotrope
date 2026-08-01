
// Config file for running Rollup in "watch" mode
// This adds a sanity check to help ourselves to run 'rollup -w' as needed.

// Needed to create files loadable by IE8
import rollupGitVersion from 'rollup-plugin-git-version'
import commonjs from 'rollup-plugin-commonjs'
import nodeResolve from 'rollup-plugin-node-resolve'

import gitRev from 'git-rev-sync'

const branch = gitRev.branch();
const rev = gitRev.short();

const version = require('../package.json').version + '+' + branch + '.' + rev;

const now = (new Date()).getTime();
const limit = now + 5 * 60 * 1000;  // 5 minutes, in milliseconds
const yyyy = (new Date()).getYear() + 1900;

const banner = `/*
 * Cozy Sun Bear ` + version + `, a JS library for interactive books. http://github.com/mlibrary/cozy-sun-bar
 * (c) ${yyyy} Regents of the University of Michigan
 */`;

export default {
  format: 'umd',
  moduleName: 'cozy',
  banner: banner,
  entry: 'src/cozy.js',
  dest: 'dist/cozy-sun-bear.js',
  plugins: [
    rollupGitVersion(),
    nodeResolve({ jsnext: true, main: true }),
    commonjs({
      
    })
  ],
  globals: {
    xxepubjs: 'epubjs'
  },
  sourceMap: true,
  legacy: true // Needed to create files loadable by IE8
};
