/*
 * @namespace Util
 *
 * Various utility functions, used by Leaflet internally.
 */

// @function extend(dest: Object, src?: Object): Object
// Merges the properties of the `src` object (or multiple objects) into `dest` object and returns the latter. Has an `L.extend` shortcut.
export function extend(dest) {
    var i, j, len, src;

    for (j = 1, len = arguments.length; j < len; j++) {
        src = arguments[j];
        for (i in src) {
            dest[i] = src[i];
        }
    }
    return dest;
}

// @function create(proto: Object, properties?: Object): Object
// Compatibility polyfill for [Object.create](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Object/create)
export var create = Object.create || (function () {
    function F() {}
    return function (proto) {
        F.prototype = proto;
        return new F();
    };
})();

// @function bind(fn: Function, …): Function
// Returns a new function bound to the arguments passed, like [Function.prototype.bind](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Function/bind).
// Has a `L.bind()` shortcut.
export function bind(fn, obj) {
    var slice = Array.prototype.slice;

    if (fn.bind) {
        return fn.bind.apply(fn, slice.call(arguments, 1));
    }

    var args = slice.call(arguments, 2);

    return function () {
        return fn.apply(obj, args.length ? args.concat(slice.call(arguments)) : arguments);
    };
}

// @property lastId: Number
// Last unique ID used by [`stamp()`](#util-stamp)
export var lastId = 0;

// @function stamp(obj: Object): Number
// Returns the unique ID of an object, assiging it one if it doesn't have it.
export function stamp(obj) {
    /*eslint-disable */
    obj._cozy_id = obj._cozy_id || ++lastId;
    return obj._cozy_id; /* not leaflet */
    /*eslint-enable */
}

// @function throttle(fn: Function, time: Number, context: Object): Function
// Returns a function which executes function `fn` with the given scope `context`
// (so that the `this` keyword refers to `context` inside `fn`'s code). The function
// `fn` will be called no more than one time per given amount of `time`. The arguments
// received by the bound function will be any arguments passed when binding the
// function, followed by any arguments passed when invoking the bound function.
// Has an `L.throttle` shortcut.
export function throttle(fn, time, context) {
    var lock, args, wrapperFn, later;

    later = function () {
        // reset lock and call if queued
        lock = false;
        if (args) {
            wrapperFn.apply(context, args);
            args = false;
        }
    };

    wrapperFn = function () {
        if (lock) {
            // called too soon, queue to call later
            args = arguments;

        } else {
            // call and lock until later
            fn.apply(context, arguments);
            setTimeout(later, time);
            lock = true;
        }
    };

    return wrapperFn;
}

// @function wrapNum(num: Number, range: Number[], includeMax?: Boolean): Number
// Returns the number `num` modulo `range` in such a way so it lies within
// `range[0]` and `range[1]`. The returned value will be always smaller than
// `range[1]` unless `includeMax` is set to `true`.
export function wrapNum(x, range, includeMax) {
    var max = range[1],
        min = range[0],
        d = max - min;
    return x === max && includeMax ? x : ((x - min) % d + d) % d + min;
}

// @function falseFn(): Function
// Returns a function which always returns `false`.
export function falseFn() { return false; }

// @function formatNum(num: Number, digits?: Number): Number
// Returns the number `num` rounded to `digits` decimals, or to 5 decimals by default.
export function formatNum(num, digits) {
    var pow = Math.pow(10, digits || 5);
    return Math.round(num * pow) / pow;
}

// @function isNumeric(num: Number): Boolean
// Returns whether num is actually numeric
export function isNumeric(num) {
  return !isNaN(parseFloat(num)) && isFinite(num);
}

// @function trim(str: String): String
// Compatibility polyfill for [String.prototype.trim](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/String/Trim)
export function trim(str) {
    return str.trim ? str.trim() : str.replace(/^\s+|\s+$/g, '');
}

// @function splitWords(str: String): String[]
// Trims and splits the string on whitespace and returns the array of parts.
export function splitWords(str) {
    return trim(str).split(/\s+/);
}

// @function setOptions(obj: Object, options: Object): Object
// Merges the given properties to the `options` of the `obj` object, returning the resulting options. See `Class options`. Has an `L.setOptions` shortcut.
export function setOptions(obj, options) {
    if (!obj.hasOwnProperty('options')) {
        obj.options = obj.options ? create(obj.options) : {};
    }
    for (var i in options) {
        obj.options[i] = options[i];
    }
    return obj.options;
}

// @function getParamString(obj: Object, existingUrl?: String, uppercase?: Boolean): String
// Converts an object into a parameter URL string, e.g. `{a: "foo", b: "bar"}`
// translates to `'?a=foo&b=bar'`. If `existingUrl` is set, the parameters will
// be appended at the end. If `uppercase` is `true`, the parameter names will
// be uppercased (e.g. `'?A=foo&B=bar'`)
export function getParamString(obj, existingUrl, uppercase) {
    var params = [];
    for (var i in obj) {
        params.push(encodeURIComponent(uppercase ? i.toUpperCase() : i) + '=' + encodeURIComponent(obj[i]));
    }
    return ((!existingUrl || existingUrl.indexOf('?') === -1) ? '?' : '&') + params.join('&');
}

var templateRe = /\{ *([\w_\-]+) *\}/g;

// @function template(str: String, data: Object): String
// Simple templating facility, accepts a template string of the form `'Hello {a}, {b}'`
// and a data object like `{a: 'foo', b: 'bar'}`, returns evaluated string
// `('Hello foo, bar')`. You can also specify functions instead of strings for
// data values — they will be evaluated passing `data` as an argument.
export function template(str, data) {
    return str.replace(templateRe, function (str, key) {
        var value = data[key];

        if (value === undefined) {
            throw new Error('No value provided for variable ' + str);

        } else if (typeof value === 'function') {
            value = value(data);
        }
        return value;
    });
}

// @function isArray(obj): Boolean
// Compatibility polyfill for [Array.isArray](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray)
export var isArray = Array.isArray || function (obj) {
    return (Object.prototype.toString.call(obj) === '[object Array]');
};

// @function indexOf(array: Array, el: Object): Number
// Compatibility polyfill for [Array.prototype.indexOf](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf)
export function indexOf(array, el) {
    for (var i = 0; i < array.length; i++) {
        if (array[i] === el) { return i; }
    }
    return -1;
}

// @property emptyImageUrl: String
// Data URI string containing a base64-encoded empty GIF image.
// Used as a hack to free memory from unused images on WebKit-powered
// mobile devices (by setting image `src` to this string).
export var emptyImageUrl = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=';

// inspired by http://paulirish.com/2011/requestanimationframe-for-smart-animating/

function getPrefixed(name) {
    return window['webkit' + name] || window['moz' + name] || window['ms' + name];
}

var lastTime = 0;

// fallback for IE 7-8
function timeoutDefer(fn) {
    var time = +new Date(),
        timeToCall = Math.max(0, 16 - (time - lastTime));

    lastTime = time + timeToCall;
    return window.setTimeout(fn, timeToCall);
}

export var requestFn = window.requestAnimationFrame || getPrefixed('RequestAnimationFrame') || timeoutDefer;
export var cancelFn = window.cancelAnimationFrame || getPrefixed('CancelAnimationFrame') ||
        getPrefixed('CancelRequestAnimationFrame') || function (id) { window.clearTimeout(id); };

// @function requestAnimFrame(fn: Function, context?: Object, immediate?: Boolean): Number
// Schedules `fn` to be executed when the browser repaints. `fn` is bound to
// `context` if given. When `immediate` is set, `fn` is called immediately if
// the browser doesn't have native support for
// [`window.requestAnimationFrame`](https://developer.mozilla.org/docs/Web/API/window/requestAnimationFrame),
// otherwise it's delayed. Returns a request ID that can be used to cancel the request.
export function requestAnimFrame(fn, context, immediate) {
    if (immediate && requestFn === timeoutDefer) {
        fn.call(context);
    } else {
        return requestFn.call(window, bind(fn, context));
    }
}

// @function cancelAnimFrame(id: Number): undefined
// Cancels a previous `requestAnimFrame`. See also [window.cancelAnimationFrame](https://developer.mozilla.org/docs/Web/API/window/cancelAnimationFrame).
export function cancelAnimFrame(id) {
    if (id) {
        cancelFn.call(window, id);
    }
}

export function inVp(elem, threshold = {}, container = null) {

    if ( threshold instanceof HTMLElement ) {
        container = threshold;
        threshold = {};
    }

    threshold = Object.assign({
        top: 0,
        right: 0,
        bottom: 0,
        left: 0
    }, threshold);

    container = container || document.documentElement;

    // Get the viewport dimensions
    const vp = {
        width: container.clientWidth,
        height: container.clientHeight
    };

    // Get the viewport offset and size of the element.
    // Normailze right and bottom to show offset from their
    // respective edges istead of the top-left edges.
    const box = elem.getBoundingClientRect();
    const {
        top,
        left,
        width,
        height
    } = box;
    const right = vp.width - box.right;
    const bottom = vp.height - box.bottom;

    // Calculate which sides of the element are cut-off
    // by the viewport.
    const cutOff = {
        top: top < threshold.top,
        left: left < threshold.left,
        bottom: bottom < threshold.bottom,
        right: right < threshold.right
    };

    // Calculate which sides of the element are partially shown
    const partial = {
        top: cutOff.top && top > -height + threshold.top,
        left: cutOff.left && left > -width + threshold.left,
        bottom: cutOff.bottom && bottom > -height + threshold.bottom,
        right: cutOff.right && right > -width + threshold.right
    };

    const isFullyVisible = top >= threshold.top &&
        right >= threshold.right &&
        bottom >= threshold.bottom &&
        left >= threshold.left;

    const isPartiallyVisible = partial.top ||
        partial.right ||
        partial.bottom ||
        partial.left;


    var elH = elem.offsetHeight;
    var H = container.offsetHeight;
    var percentage = Math.max(0, top > 0 ? Math.min(elH, H - top) : (box.bottom < H ? box.bottom : H));

    // Calculate which edge of the element are visible.
    // Every edge can have three states:
    // - 'fully':     The edge is completely visible.
    // - 'partially': Some part of the edge can be seen.
    // - false:       The edge is not visible at all.
    const edges = {
        top: !isFullyVisible && !isPartiallyVisible ? false : ((!cutOff.top && !cutOff.left && !cutOff.right) && 'fully') ||
            (!cutOff.top && 'partially') ||
            false,
        right: !isFullyVisible && !isPartiallyVisible ? false : ((!cutOff.right && !cutOff.top && !cutOff.bottom) && 'fully') ||
            (!cutOff.right && 'partially') ||
            false,
        bottom: !isFullyVisible && !isPartiallyVisible ? false : ((!cutOff.bottom && !cutOff.left && !cutOff.right) && 'fully') ||
            (!cutOff.bottom && 'partially') ||
            false,
        left: !isFullyVisible && !isPartiallyVisible ? false : ((!cutOff.left && !cutOff.top && !cutOff.bottom) && 'fully') ||
            (!cutOff.left && 'partially') ||
            false,
        percentage: percentage
    };

    return {
        fully: isFullyVisible,
        partially: isPartiallyVisible,
        edges
    };
}

export var loader = {
    js: function(url) {
        var handler = { _resolved: false };
        handler.callbacks = [];
        handler.error = [];
        handler.then = function(cb) {
            handler.callbacks.push(cb);
            if ( handler._resolved ) { return handler.resolve(); }
            return handler;
        }
        handler.catch = function(cb) {
            handler.error.push(cb);
            if ( handler._resolved ) { return handler.reject(); }
            return handler;
        }
        handler.resolve = function(_argv) {
            // var _argv;
            handler._resolved = true;
            while ( handler.callbacks.length ) {
                var cb = handler.callbacks.shift();
                var retval;
                try {
                    _argv = cb(_argv);
                } catch(e) {
                    console.log(e);
                    handler.reject(e);
                    break;
                }
            }
            return handler;
        }

        handler.reject = function(e) {
            while ( handler.error.length ) {
                var cb = handler.error.shift();
                cb(e);
            }
            console.log(e);
            console.trace();
            return handler;
        }

        if ( url == undefined ) {
            handler._resolved = true;
            return handler;
        }

        var element = document.createElement('script');

        element.onload = function() {
          handler.resolve(url);
        };
        element.onerror = function() {
          handler.catch.apply(arguments);
        };

        element.async = true;
        var parent = 'body';
        var attr = 'src';
        element[attr] = url;
        document[parent].appendChild(element);

        console.log("AHOY APPENDED", url);

        return handler;
    }
}