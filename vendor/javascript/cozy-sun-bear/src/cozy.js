
// import {version} from '../package.json';
// export {version};

// // control
// export * from './control/index';

// // core
// export * from './core/index';

// // dom
// export * from './dom/index';

// // reader
// import {reader} from './reader/index';
// export * from './reader/index';

// misc

var oldCozy = window.cozy;
export function noConflict() {
  window.cozy = oldCozy;
  return this;
}



var cozy = {};
// cozy.reader = reader;

import {version} from '../package.json';
var control = require('./control/index');
var core = require('./core/index');
var dom = require('./dom/index');
var reader = require('./reader/index');

[ control, core, dom, reader ].forEach((m) => {
  Object.keys(m).forEach((key) => {
    cozy[key] = m[key];
  })
})

export default cozy;