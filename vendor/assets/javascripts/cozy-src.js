/*
 * Cozy Sun Bear 1.0.0+sass.e5a9a73, a JS library for interactive books. http://github.com/mlibrary/cozy-sun-bar
 * (c) 2017 Regents of the University of Michigan
 */
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
	typeof define === 'function' && define.amd ? define(['exports'], factory) :
	(factory((global.cozy = global.cozy || {})));
}(this, (function (exports) { 'use strict';

var version = "1.0.0+sass.e5a9a73";

/*
 * @namespace Util
 *
 * Various utility functions, used by Leaflet internally.
 */

// @function extend(dest: Object, src?: Object): Object
// Merges the properties of the `src` object (or multiple objects) into `dest` object and returns the latter. Has an `L.extend` shortcut.
function extend(dest) {
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
var create = Object.create || (function () {
    function F() {}
    return function (proto) {
        F.prototype = proto;
        return new F();
    };
})();

// @function bind(fn: Function, …): Function
// Returns a new function bound to the arguments passed, like [Function.prototype.bind](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Function/bind).
// Has a `L.bind()` shortcut.
function bind(fn, obj) {
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
var lastId = 0;

// @function stamp(obj: Object): Number
// Returns the unique ID of an object, assiging it one if it doesn't have it.
function stamp(obj) {
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
function throttle(fn, time, context) {
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
function wrapNum(x, range, includeMax) {
    var max = range[1],
        min = range[0],
        d = max - min;
    return x === max && includeMax ? x : ((x - min) % d + d) % d + min;
}

// @function falseFn(): Function
// Returns a function which always returns `false`.
function falseFn() { return false; }

// @function formatNum(num: Number, digits?: Number): Number
// Returns the number `num` rounded to `digits` decimals, or to 5 decimals by default.
function formatNum(num, digits) {
    var pow = Math.pow(10, digits || 5);
    return Math.round(num * pow) / pow;
}

// @function trim(str: String): String
// Compatibility polyfill for [String.prototype.trim](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/String/Trim)
function trim(str) {
    return str.trim ? str.trim() : str.replace(/^\s+|\s+$/g, '');
}

// @function splitWords(str: String): String[]
// Trims and splits the string on whitespace and returns the array of parts.
function splitWords(str) {
    return trim(str).split(/\s+/);
}

// @function setOptions(obj: Object, options: Object): Object
// Merges the given properties to the `options` of the `obj` object, returning the resulting options. See `Class options`. Has an `L.setOptions` shortcut.
function setOptions(obj, options) {
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
function getParamString(obj, existingUrl, uppercase) {
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
function template(str, data) {
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
var isArray = Array.isArray || function (obj) {
    return (Object.prototype.toString.call(obj) === '[object Array]');
};

// @function indexOf(array: Array, el: Object): Number
// Compatibility polyfill for [Array.prototype.indexOf](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf)
function indexOf(array, el) {
    for (var i = 0; i < array.length; i++) {
        if (array[i] === el) { return i; }
    }
    return -1;
}

// @property emptyImageUrl: String
// Data URI string containing a base64-encoded empty GIF image.
// Used as a hack to free memory from unused images on WebKit-powered
// mobile devices (by setting image `src` to this string).
var emptyImageUrl = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=';

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

var requestFn = window.requestAnimationFrame || getPrefixed('RequestAnimationFrame') || timeoutDefer;
var cancelFn = window.cancelAnimationFrame || getPrefixed('CancelAnimationFrame') ||
        getPrefixed('CancelRequestAnimationFrame') || function (id) { window.clearTimeout(id); };

// @function requestAnimFrame(fn: Function, context?: Object, immediate?: Boolean): Number
// Schedules `fn` to be executed when the browser repaints. `fn` is bound to
// `context` if given. When `immediate` is set, `fn` is called immediately if
// the browser doesn't have native support for
// [`window.requestAnimationFrame`](https://developer.mozilla.org/docs/Web/API/window/requestAnimationFrame),
// otherwise it's delayed. Returns a request ID that can be used to cancel the request.
function requestAnimFrame(fn, context, immediate) {
    if (immediate && requestFn === timeoutDefer) {
        fn.call(context);
    } else {
        return requestFn.call(window, bind(fn, context));
    }
}

// @function cancelAnimFrame(id: Number): undefined
// Cancels a previous `requestAnimFrame`. See also [window.cancelAnimationFrame](https://developer.mozilla.org/docs/Web/API/window/cancelAnimationFrame).
function cancelAnimFrame(id) {
    if (id) {
        cancelFn.call(window, id);
    }
}


var Util = (Object.freeze || Object)({
	extend: extend,
	create: create,
	bind: bind,
	lastId: lastId,
	stamp: stamp,
	throttle: throttle,
	wrapNum: wrapNum,
	falseFn: falseFn,
	formatNum: formatNum,
	trim: trim,
	splitWords: splitWords,
	setOptions: setOptions,
	getParamString: getParamString,
	template: template,
	isArray: isArray,
	indexOf: indexOf,
	emptyImageUrl: emptyImageUrl,
	requestFn: requestFn,
	cancelFn: cancelFn,
	requestAnimFrame: requestAnimFrame,
	cancelAnimFrame: cancelAnimFrame
});

// @class Class
// @aka L.Class

// @section
// @uninheritable

// Thanks to John Resig and Dean Edwards for inspiration!

function Class() {}

Class.extend = function (props) {

	// @function extend(props: Object): Function
	// [Extends the current class](#class-inheritance) given the properties to be included.
	// Returns a Javascript function that is a class constructor (to be called with `new`).
	var NewClass = function () {

		// call the constructor
		if (this.initialize) {
			this.initialize.apply(this, arguments);
		}

		// call all constructor hooks
		this.callInitHooks();
	};

	var parentProto = NewClass.__super__ = this.prototype;

	var proto = create(parentProto);
	proto.constructor = NewClass;

	NewClass.prototype = proto;

	// inherit parent's statics
	for (var i in this) {
		if (this.hasOwnProperty(i) && i !== 'prototype') {
			NewClass[i] = this[i];
		}
	}

	// mix static properties into the class
	if (props.statics) {
		extend(NewClass, props.statics);
		delete props.statics;
	}

	// mix includes into the prototype
	if (props.includes) {
		checkDeprecatedMixinEvents(props.includes);
		extend.apply(null, [proto].concat(props.includes));
		delete props.includes;
	}

	// merge options
	if (proto.options) {
		props.options = extend(create(proto.options), props.options);
	}

	// mix given properties into the prototype
	extend(proto, props);
	
	proto._initHooks = [];

	// add method for calling all hooks
	proto.callInitHooks = function () {

		if (this._initHooksCalled) { return; }

		if (parentProto.callInitHooks) {
			parentProto.callInitHooks.call(this);
		}

		this._initHooksCalled = true;

		for (var i = 0, len = proto._initHooks.length; i < len; i++) {
			proto._initHooks[i].call(this);
		}
	};

	return NewClass;
};


// @function include(properties: Object): this
// [Includes a mixin](#class-includes) into the current class.
Class.include = function (props) {
	extend(this.prototype, props);
	return this;
};

// @function mergeOptions(options: Object): this
// [Merges `options`](#class-options) into the defaults of the class.
Class.mergeOptions = function (options) {
	extend(this.prototype.options, options);
	return this;
};

// @function addInitHook(fn: Function): this
// Adds a [constructor hook](#class-constructor-hooks) to the class.
Class.addInitHook = function (fn) { // (Function) || (String, args...)
	var args = Array.prototype.slice.call(arguments, 1);

	var init = typeof fn === 'function' ? fn : function () {
		this[fn].apply(this, args);
	};

	this.prototype._initHooks = this.prototype._initHooks || [];
	this.prototype._initHooks.push(init);
	return this;
};

function checkDeprecatedMixinEvents(includes) {
	if (!L || !L.Mixin) { return; }

	includes = L.Util.isArray(includes) ? includes : [includes];

	for (var i = 0; i < includes.length; i++) {
		if (includes[i] === L.Mixin.Events) {
			console.warn('Deprecated include of L.Mixin.Events: ' +
				'this property will be removed in future releases, ' +
				'please inherit from L.Evented instead.', new Error().stack);
		}
	}
}

/*
 * @class Evented
 * @aka L.Evented
 * @inherits Class
 *
 * A set of methods shared between event-powered classes (like `Map` and `Marker`). Generally, events allow you to execute some function when something happens with an object (e.g. the user clicks on the map, causing the map to fire `'click'` event).
 *
 * @example
 *
 * ```js
 * map.on('click', function(e) {
 * 	alert(e.latlng);
 * } );
 * ```
 *
 * Leaflet deals with event listeners by reference, so if you want to add a listener and then remove it, define it as a function:
 *
 * ```js
 * function onClick(e) { ... }
 *
 * map.on('click', onClick);
 * map.off('click', onClick);
 * ```
 */

var Evented = Class.extend({

	/* @method on(type: String, fn: Function, context?: Object): this
	 * Adds a listener function (`fn`) to a particular event type of the object. You can optionally specify the context of the listener (object the this keyword will point to). You can also pass several space-separated types (e.g. `'click dblclick'`).
	 *
	 * @alternative
	 * @method on(eventMap: Object): this
	 * Adds a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`
	 */
	on: function (types, fn, context) {

		// types can be a map of types/handlers
		if (typeof types === 'object') {
			for (var type in types) {
				// we don't process space-separated events here for performance;
				// it's a hot path since Layer uses the on(obj) syntax
				this._on(type, types[type], fn);
			}

		} else {
			// types can be a string of space-separated words
			types = splitWords(types);

			for (var i = 0, len = types.length; i < len; i++) {
				this._on(types[i], fn, context);
			}
		}

		return this;
	},

	/* @method off(type: String, fn?: Function, context?: Object): this
	 * Removes a previously added listener function. If no function is specified, it will remove all the listeners of that particular event from the object. Note that if you passed a custom context to `on`, you must pass the same context to `off` in order to remove the listener.
	 *
	 * @alternative
	 * @method off(eventMap: Object): this
	 * Removes a set of type/listener pairs.
	 *
	 * @alternative
	 * @method off: this
	 * Removes all listeners to all events on the object.
	 */
	off: function (types, fn, context) {

		if (!types) {
			// clear all listeners if called without arguments
			delete this._events;

		} else if (typeof types === 'object') {
			for (var type in types) {
				this._off(type, types[type], fn);
			}

		} else {
			types = splitWords(types);

			for (var i = 0, len = types.length; i < len; i++) {
				this._off(types[i], fn, context);
			}
		}

		return this;
	},

	// attach listener (without syntactic sugar now)
	_on: function (type, fn, context) {
		this._events = this._events || {};

		/* get/init listeners for type */
		var typeListeners = this._events[type];
		if (!typeListeners) {
			typeListeners = [];
			this._events[type] = typeListeners;
		}

		if (context === this) {
			// Less memory footprint.
			context = undefined;
		}
		var newListener = {fn: fn, ctx: context},
		    listeners = typeListeners;

		// check if fn already there
		for (var i = 0, len = listeners.length; i < len; i++) {
			if (listeners[i].fn === fn && listeners[i].ctx === context) {
				return;
			}
		}

		listeners.push(newListener);
	},

	_off: function (type, fn, context) {
		var listeners,
		    i,
		    len;

		if (!this._events) { return; }

		listeners = this._events[type];

		if (!listeners) {
			return;
		}

		if (!fn) {
			// Set all removed listeners to noop so they are not called if remove happens in fire
			for (i = 0, len = listeners.length; i < len; i++) {
				listeners[i].fn = falseFn;
			}
			// clear all listeners for a type if function isn't specified
			delete this._events[type];
			return;
		}

		if (context === this) {
			context = undefined;
		}

		if (listeners) {

			// find fn and remove it
			for (i = 0, len = listeners.length; i < len; i++) {
				var l = listeners[i];
				if (l.ctx !== context) { continue; }
				if (l.fn === fn) {

					// set the removed listener to noop so that's not called if remove happens in fire
					l.fn = falseFn;

					if (this._firingCount) {
						/* copy array in case events are being fired */
						this._events[type] = listeners = listeners.slice();
					}
					listeners.splice(i, 1);

					return;
				}
			}
		}
	},

	// @method fire(type: String, data?: Object, propagate?: Boolean): this
	// Fires an event of the specified type. You can optionally provide an data
	// object — the first argument of the listener function will contain its
	// properties. The event can optionally be propagated to event parents.
	fire: function (type, data, propagate) {
		if (!this.listens(type, propagate)) { return this; }

		var event = extend({}, data, {type: type, target: this});

		if (this._events) {
			var listeners = this._events[type];

			if (listeners) {
				this._firingCount = (this._firingCount + 1) || 1;
				for (var i = 0, len = listeners.length; i < len; i++) {
					var l = listeners[i];
					l.fn.call(l.ctx || this, event);
				}

				this._firingCount--;
			}
		}

		if (propagate) {
			// propagate the event to parents (set with addEventParent)
			this._propagateEvent(event);
		}

		return this;
	},

	// @method listens(type: String): Boolean
	// Returns `true` if a particular event type has any listeners attached to it.
	listens: function (type, propagate) {
		var listeners = this._events && this._events[type];
		if (listeners && listeners.length) { return true; }

		if (propagate) {
			// also check parents for listeners if event propagates
			for (var id in this._eventParents) {
				if (this._eventParents[id].listens(type, propagate)) { return true; }
			}
		}
		return false;
	},

	// @method once(…): this
	// Behaves as [`on(…)`](#evented-on), except the listener will only get fired once and then removed.
	once: function (types, fn, context) {

		if (typeof types === 'object') {
			for (var type in types) {
				this.once(type, types[type], fn);
			}
			return this;
		}

		var handler = bind(function () {
			this
			    .off(types, fn, context)
			    .off(types, handler, context);
		}, this);

		// add a listener that's executed once and removed after that
		return this
		    .on(types, fn, context)
		    .on(types, handler, context);
	},

	// @method addEventParent(obj: Evented): this
	// Adds an event parent - an `Evented` that will receive propagated events
	addEventParent: function (obj) {
		this._eventParents = this._eventParents || {};
		this._eventParents[stamp(obj)] = obj;
		return this;
	},

	// @method removeEventParent(obj: Evented): this
	// Removes an event parent, so it will stop receiving propagated events
	removeEventParent: function (obj) {
		if (this._eventParents) {
			delete this._eventParents[stamp(obj)];
		}
		return this;
	},

	_propagateEvent: function (e) {
		for (var id in this._eventParents) {
			this._eventParents[id].fire(e.type, extend({layer: e.target}, e), true);
		}
	}
});

var proto = Evented.prototype;

// aliases; we should ditch those eventually

// @method addEventListener(…): this
// Alias to [`on(…)`](#evented-on)
proto.addEventListener = proto.on;

// @method removeEventListener(…): this
// Alias to [`off(…)`](#evented-off)

// @method clearAllEventListeners(…): this
// Alias to [`off()`](#evented-off)
proto.removeEventListener = proto.clearAllEventListeners = proto.off;

// @method addOneTimeEventListener(…): this
// Alias to [`once(…)`](#evented-once)
proto.addOneTimeEventListener = proto.once;

// @method fireEvent(…): this
// Alias to [`fire(…)`](#evented-fire)
proto.fireEvent = proto.fire;

// @method hasEventListeners(…): Boolean
// Alias to [`listens(…)`](#evented-listens)
proto.hasEventListeners = proto.listens;

/*
 * @namespace Browser
 * @aka L.Browser
 *
 * A namespace with static properties for browser/feature detection used by Leaflet internally.
 *
 * @example
 *
 * ```js
 * if (L.Browser.ielt9) {
 *   alert('Upgrade your browser, dude!');
 * }
 * ```
 */

var style$1 = document.documentElement.style;

// @property ie: Boolean; `true` for all Internet Explorer versions (not Edge).
var ie = 'ActiveXObject' in window;

// @property ielt9: Boolean; `true` for Internet Explorer versions less than 9.
var ielt9 = ie && !document.addEventListener;

// @property edge: Boolean; `true` for the Edge web browser.
var edge = 'msLaunchUri' in navigator && !('documentMode' in document);

// @property webkit: Boolean;
// `true` for webkit-based browsers like Chrome and Safari (including mobile versions).
var webkit = userAgentContains('webkit');

// @property android: Boolean
// `true` for any browser running on an Android platform.
var android = userAgentContains('android');

// @property android23: Boolean; `true` for browsers running on Android 2 or Android 3.
var android23 = userAgentContains('android 2') || userAgentContains('android 3');

// @property opera: Boolean; `true` for the Opera browser
var opera = !!window.opera;

// @property chrome: Boolean; `true` for the Chrome browser.
var chrome = userAgentContains('chrome');

// @property gecko: Boolean; `true` for gecko-based browsers like Firefox.
var gecko = userAgentContains('gecko') && !webkit && !opera && !ie;

// @property safari: Boolean; `true` for the Safari browser.
var safari = !chrome && userAgentContains('safari');

var phantom = userAgentContains('phantom');

// @property opera12: Boolean
// `true` for the Opera browser supporting CSS transforms (version 12 or later).
var opera12 = 'OTransition' in style$1;

// @property win: Boolean; `true` when the browser is running in a Windows platform
var win = navigator.platform.indexOf('Win') === 0;

// @property ie3d: Boolean; `true` for all Internet Explorer versions supporting CSS transforms.
var ie3d = ie && ('transition' in style$1);

// @property webkit3d: Boolean; `true` for webkit-based browsers supporting CSS transforms.
var webkit3d = ('WebKitCSSMatrix' in window) && ('m11' in new window.WebKitCSSMatrix()) && !android23;

// @property gecko3d: Boolean; `true` for gecko-based browsers supporting CSS transforms.
var gecko3d = 'MozPerspective' in style$1;

// @property any3d: Boolean
// `true` for all browsers supporting CSS transforms.
var any3d = !window.L_DISABLE_3D && (ie3d || webkit3d || gecko3d) && !opera12 && !phantom;

// @property mobile: Boolean; `true` for all browsers running in a mobile device.
var mobile = typeof orientation !== 'undefined' || userAgentContains('mobile');

// @property mobileWebkit: Boolean; `true` for all webkit-based browsers in a mobile device.
var mobileWebkit = mobile && webkit;

// @property mobileWebkit3d: Boolean
// `true` for all webkit-based browsers in a mobile device supporting CSS transforms.
var mobileWebkit3d = mobile && webkit3d;

// @property msPointer: Boolean
// `true` for browsers implementing the Microsoft touch events model (notably IE10).
var msPointer = !window.PointerEvent && window.MSPointerEvent;

// @property pointer: Boolean
// `true` for all browsers supporting [pointer events](https://msdn.microsoft.com/en-us/library/dn433244%28v=vs.85%29.aspx).
var pointer = !!(window.PointerEvent || msPointer);

// @property touch: Boolean
// `true` for all browsers supporting [touch events](https://developer.mozilla.org/docs/Web/API/Touch_events).
// This does not necessarily mean that the browser is running in a computer with
// a touchscreen, it only means that the browser is capable of understanding
// touch events.
var touch = !window.L_NO_TOUCH && (pointer || 'ontouchstart' in window ||
        (window.DocumentTouch && document instanceof window.DocumentTouch));

// @property mobileOpera: Boolean; `true` for the Opera browser in a mobile device.
var mobileOpera = mobile && opera;

// @property mobileGecko: Boolean
// `true` for gecko-based browsers running in a mobile device.
var mobileGecko = mobile && gecko;

// @property retina: Boolean
// `true` for browsers on a high-resolution "retina" screen.
var retina = (window.devicePixelRatio || (window.screen.deviceXDPI / window.screen.logicalXDPI)) > 1;


// @property canvas: Boolean
// `true` when the browser supports [`<canvas>`](https://developer.mozilla.org/docs/Web/API/Canvas_API).
var canvas = (function () {
    return !!document.createElement('canvas').getContext;
}());

// @property svg: Boolean
// `true` when the browser supports [SVG](https://developer.mozilla.org/docs/Web/SVG).
// export var svg = !!(document.createElementNS && svgCreate('svg').createSVGRect);
var svg = true;

// @property vml: Boolean
// `true` if the browser supports [VML](https://en.wikipedia.org/wiki/Vector_Markup_Language).
var vml = !svg && (function () {
    try {
        var div = document.createElement('div');
        div.innerHTML = '<v:shape adj="1"/>';

        var shape = div.firstChild;
        shape.style.behavior = 'url(#default#VML)';

        return shape && (typeof shape.adj === 'object');

    } catch (e) {
        return false;
    }
}());


function userAgentContains(str) {
    return navigator.userAgent.toLowerCase().indexOf(str) >= 0;
}


var Browser = (Object.freeze || Object)({
	ie: ie,
	ielt9: ielt9,
	edge: edge,
	webkit: webkit,
	android: android,
	android23: android23,
	opera: opera,
	chrome: chrome,
	gecko: gecko,
	safari: safari,
	phantom: phantom,
	opera12: opera12,
	win: win,
	ie3d: ie3d,
	webkit3d: webkit3d,
	gecko3d: gecko3d,
	any3d: any3d,
	mobile: mobile,
	mobileWebkit: mobileWebkit,
	mobileWebkit3d: mobileWebkit3d,
	msPointer: msPointer,
	pointer: pointer,
	touch: touch,
	mobileOpera: mobileOpera,
	mobileGecko: mobileGecko,
	retina: retina,
	canvas: canvas,
	svg: svg,
	vml: vml
});

/*
 * @class Point
 * @aka L.Point
 *
 * Represents a point with `x` and `y` coordinates in pixels.
 *
 * @example
 *
 * ```js
 * var point = L.point(200, 300);
 * ```
 *
 * All Leaflet methods and options that accept `Point` objects also accept them in a simple Array form (unless noted otherwise), so these lines are equivalent:
 *
 * ```js
 * map.panBy([200, 300]);
 * map.panBy(L.point(200, 300));
 * ```
 */

function Point(x, y, round) {
	// @property x: Number; The `x` coordinate of the point
	this.x = (round ? Math.round(x) : x);
	// @property y: Number; The `y` coordinate of the point
	this.y = (round ? Math.round(y) : y);
}

Point.prototype = {

	// @method clone(): Point
	// Returns a copy of the current point.
	clone: function () {
		return new Point(this.x, this.y);
	},

	// @method add(otherPoint: Point): Point
	// Returns the result of addition of the current and the given points.
	add: function (point) {
		// non-destructive, returns a new point
		return this.clone()._add(toPoint(point));
	},

	_add: function (point) {
		// destructive, used directly for performance in situations where it's safe to modify existing point
		this.x += point.x;
		this.y += point.y;
		return this;
	},

	// @method subtract(otherPoint: Point): Point
	// Returns the result of subtraction of the given point from the current.
	subtract: function (point) {
		return this.clone()._subtract(toPoint(point));
	},

	_subtract: function (point) {
		this.x -= point.x;
		this.y -= point.y;
		return this;
	},

	// @method divideBy(num: Number): Point
	// Returns the result of division of the current point by the given number.
	divideBy: function (num) {
		return this.clone()._divideBy(num);
	},

	_divideBy: function (num) {
		this.x /= num;
		this.y /= num;
		return this;
	},

	// @method multiplyBy(num: Number): Point
	// Returns the result of multiplication of the current point by the given number.
	multiplyBy: function (num) {
		return this.clone()._multiplyBy(num);
	},

	_multiplyBy: function (num) {
		this.x *= num;
		this.y *= num;
		return this;
	},

	// @method scaleBy(scale: Point): Point
	// Multiply each coordinate of the current point by each coordinate of
	// `scale`. In linear algebra terms, multiply the point by the
	// [scaling matrix](https://en.wikipedia.org/wiki/Scaling_%28geometry%29#Matrix_representation)
	// defined by `scale`.
	scaleBy: function (point) {
		return new Point(this.x * point.x, this.y * point.y);
	},

	// @method unscaleBy(scale: Point): Point
	// Inverse of `scaleBy`. Divide each coordinate of the current point by
	// each coordinate of `scale`.
	unscaleBy: function (point) {
		return new Point(this.x / point.x, this.y / point.y);
	},

	// @method round(): Point
	// Returns a copy of the current point with rounded coordinates.
	round: function () {
		return this.clone()._round();
	},

	_round: function () {
		this.x = Math.round(this.x);
		this.y = Math.round(this.y);
		return this;
	},

	// @method floor(): Point
	// Returns a copy of the current point with floored coordinates (rounded down).
	floor: function () {
		return this.clone()._floor();
	},

	_floor: function () {
		this.x = Math.floor(this.x);
		this.y = Math.floor(this.y);
		return this;
	},

	// @method ceil(): Point
	// Returns a copy of the current point with ceiled coordinates (rounded up).
	ceil: function () {
		return this.clone()._ceil();
	},

	_ceil: function () {
		this.x = Math.ceil(this.x);
		this.y = Math.ceil(this.y);
		return this;
	},

	// @method distanceTo(otherPoint: Point): Number
	// Returns the cartesian distance between the current and the given points.
	distanceTo: function (point) {
		point = toPoint(point);

		var x = point.x - this.x,
		    y = point.y - this.y;

		return Math.sqrt(x * x + y * y);
	},

	// @method equals(otherPoint: Point): Boolean
	// Returns `true` if the given point has the same coordinates.
	equals: function (point) {
		point = toPoint(point);

		return point.x === this.x &&
		       point.y === this.y;
	},

	// @method contains(otherPoint: Point): Boolean
	// Returns `true` if both coordinates of the given point are less than the corresponding current point coordinates (in absolute values).
	contains: function (point) {
		point = toPoint(point);

		return Math.abs(point.x) <= Math.abs(this.x) &&
		       Math.abs(point.y) <= Math.abs(this.y);
	},

	// @method toString(): String
	// Returns a string representation of the point for debugging purposes.
	toString: function () {
		return 'Point(' +
		        formatNum(this.x) + ', ' +
		        formatNum(this.y) + ')';
	}
};

// @factory L.point(x: Number, y: Number, round?: Boolean)
// Creates a Point object with the given `x` and `y` coordinates. If optional `round` is set to true, rounds the `x` and `y` values.

// @alternative
// @factory L.point(coords: Number[])
// Expects an array of the form `[x, y]` instead.

// @alternative
// @factory L.point(coords: Object)
// Expects a plain object of the form `{x: Number, y: Number}` instead.
function toPoint(x, y, round) {
	if (x instanceof Point) {
		return x;
	}
	if (isArray(x)) {
		return new Point(x[0], x[1]);
	}
	if (x === undefined || x === null) {
		return x;
	}
	if (typeof x === 'object' && 'x' in x && 'y' in x) {
		return new Point(x.x, x.y);
	}
	return new Point(x, y, round);
}

/*
 * Extends L.DomEvent to provide touch support for Internet Explorer and Windows-based devices.
 */


var POINTER_DOWN =   msPointer ? 'MSPointerDown'   : 'pointerdown';
var POINTER_MOVE =   msPointer ? 'MSPointerMove'   : 'pointermove';
var POINTER_UP =     msPointer ? 'MSPointerUp'     : 'pointerup';
var POINTER_CANCEL = msPointer ? 'MSPointerCancel' : 'pointercancel';
var TAG_WHITE_LIST = ['INPUT', 'SELECT', 'OPTION'];
var _pointers = {};
var _pointerDocListener = false;

// DomEvent.DoubleTap needs to know about this
var _pointersCount = 0;

// Provides a touch events wrapper for (ms)pointer events.
// ref http://www.w3.org/TR/pointerevents/ https://www.w3.org/Bugs/Public/show_bug.cgi?id=22890

function addPointerListener(obj, type, handler, id) {
	if (type === 'touchstart') {
		_addPointerStart(obj, handler, id);

	} else if (type === 'touchmove') {
		_addPointerMove(obj, handler, id);

	} else if (type === 'touchend') {
		_addPointerEnd(obj, handler, id);
	}

	return this;
}

function removePointerListener(obj, type, id) {
	var handler = obj['_leaflet_' + type + id];

	if (type === 'touchstart') {
		obj.removeEventListener(POINTER_DOWN, handler, false);

	} else if (type === 'touchmove') {
		obj.removeEventListener(POINTER_MOVE, handler, false);

	} else if (type === 'touchend') {
		obj.removeEventListener(POINTER_UP, handler, false);
		obj.removeEventListener(POINTER_CANCEL, handler, false);
	}

	return this;
}

function _addPointerStart(obj, handler, id) {
	var onDown = bind(function (e) {
		if (e.pointerType !== 'mouse' && e.pointerType !== e.MSPOINTER_TYPE_MOUSE && e.pointerType !== e.MSPOINTER_TYPE_MOUSE) {
			// In IE11, some touch events needs to fire for form controls, or
			// the controls will stop working. We keep a whitelist of tag names that
			// need these events. For other target tags, we prevent default on the event.
			if (TAG_WHITE_LIST.indexOf(e.target.tagName) < 0) {
				preventDefault(e);
			} else {
				return;
			}
		}

		_handlePointer(e, handler);
	});

	obj['_leaflet_touchstart' + id] = onDown;
	obj.addEventListener(POINTER_DOWN, onDown, false);

	// need to keep track of what pointers and how many are active to provide e.touches emulation
	if (!_pointerDocListener) {
		// we listen documentElement as any drags that end by moving the touch off the screen get fired there
		document.documentElement.addEventListener(POINTER_DOWN, _globalPointerDown, true);
		document.documentElement.addEventListener(POINTER_MOVE, _globalPointerMove, true);
		document.documentElement.addEventListener(POINTER_UP, _globalPointerUp, true);
		document.documentElement.addEventListener(POINTER_CANCEL, _globalPointerUp, true);

		_pointerDocListener = true;
	}
}

function _globalPointerDown(e) {
	_pointers[e.pointerId] = e;
	_pointersCount++;
}

function _globalPointerMove(e) {
	if (_pointers[e.pointerId]) {
		_pointers[e.pointerId] = e;
	}
}

function _globalPointerUp(e) {
	delete _pointers[e.pointerId];
	_pointersCount--;
}

function _handlePointer(e, handler) {
	e.touches = [];
	for (var i in _pointers) {
		e.touches.push(_pointers[i]);
	}
	e.changedTouches = [e];

	handler(e);
}

function _addPointerMove(obj, handler, id) {
	var onMove = function (e) {
		// don't fire touch moves when mouse isn't down
		if ((e.pointerType === e.MSPOINTER_TYPE_MOUSE || e.pointerType === 'mouse') && e.buttons === 0) { return; }

		_handlePointer(e, handler);
	};

	obj['_leaflet_touchmove' + id] = onMove;
	obj.addEventListener(POINTER_MOVE, onMove, false);
}

function _addPointerEnd(obj, handler, id) {
	var onUp = function (e) {
		_handlePointer(e, handler);
	};

	obj['_leaflet_touchend' + id] = onUp;
	obj.addEventListener(POINTER_UP, onUp, false);
	obj.addEventListener(POINTER_CANCEL, onUp, false);
}

/*
 * Extends the event handling code with double tap support for mobile browsers.
 */

var _touchstart = msPointer ? 'MSPointerDown' : pointer ? 'pointerdown' : 'touchstart';
var _touchend = msPointer ? 'MSPointerUp' : pointer ? 'pointerup' : 'touchend';
var _pre = '_leaflet_';

// inspired by Zepto touch code by Thomas Fuchs
function addDoubleTapListener(obj, handler, id) {
	var last, touch$$1,
	    doubleTap = false,
	    delay = 250;

	function onTouchStart(e) {
		var count;

		if (pointer) {
			if ((!edge) || e.pointerType === 'mouse') { return; }
			count = _pointersCount;
		} else {
			count = e.touches.length;
		}

		if (count > 1) { return; }

		var now = Date.now(),
		    delta = now - (last || now);

		touch$$1 = e.touches ? e.touches[0] : e;
		doubleTap = (delta > 0 && delta <= delay);
		last = now;
	}

	function onTouchEnd(e) {
		if (doubleTap && !touch$$1.cancelBubble) {
			if (pointer) {
				if ((!edge) || e.pointerType === 'mouse') { return; }
				// work around .type being readonly with MSPointer* events
				var newTouch = {},
				    prop, i;

				for (i in touch$$1) {
					prop = touch$$1[i];
					newTouch[i] = prop && prop.bind ? prop.bind(touch$$1) : prop;
				}
				touch$$1 = newTouch;
			}
			touch$$1.type = 'dblclick';
			handler(touch$$1);
			last = null;
		}
	}

	obj[_pre + _touchstart + id] = onTouchStart;
	obj[_pre + _touchend + id] = onTouchEnd;
	obj[_pre + 'dblclick' + id] = handler;

	obj.addEventListener(_touchstart, onTouchStart, false);
	obj.addEventListener(_touchend, onTouchEnd, false);

	// On some platforms (notably, chrome<55 on win10 + touchscreen + mouse),
	// the browser doesn't fire touchend/pointerup events but does fire
	// native dblclicks. See #4127.
	// Edge 14 also fires native dblclicks, but only for pointerType mouse, see #5180.
	obj.addEventListener('dblclick', handler, false);

	return this;
}

function removeDoubleTapListener(obj, id) {
	var touchstart = obj[_pre + _touchstart + id],
	    touchend = obj[_pre + _touchend + id],
	    dblclick = obj[_pre + 'dblclick' + id];

	obj.removeEventListener(_touchstart, touchstart, false);
	obj.removeEventListener(_touchend, touchend, false);
	if (!edge) {
		obj.removeEventListener('dblclick', dblclick, false);
	}

	return this;
}

/*
 * @namespace DomEvent
 * Utility functions to work with the [DOM events](https://developer.mozilla.org/docs/Web/API/Event), used by Leaflet internally.
 */

// Inspired by John Resig, Dean Edwards and YUI addEvent implementations.

// @function on(el: HTMLElement, types: String, fn: Function, context?: Object): this
// Adds a listener function (`fn`) to a particular DOM event type of the
// element `el`. You can optionally specify the context of the listener
// (object the `this` keyword will point to). You can also pass several
// space-separated types (e.g. `'click dblclick'`).

// @alternative
// @function on(el: HTMLElement, eventMap: Object, context?: Object): this
// Adds a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`
function on(obj, types, fn, context) {

	if (typeof types === 'object') {
		for (var type in types) {
			addOne(obj, type, types[type], fn);
		}
	} else {
		types = splitWords(types);

		for (var i = 0, len = types.length; i < len; i++) {
			addOne(obj, types[i], fn, context);
		}
	}

	return this;
}

var eventsKey = '_leaflet_events';

// @function off(el: HTMLElement, types: String, fn: Function, context?: Object): this
// Removes a previously added listener function. If no function is specified,
// it will remove all the listeners of that particular DOM event from the element.
// Note that if you passed a custom context to on, you must pass the same
// context to `off` in order to remove the listener.

// @alternative
// @function off(el: HTMLElement, eventMap: Object, context?: Object): this
// Removes a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`

// @alternative
// @function off(el: HTMLElement): this
// Removes all known event listeners
function off(obj, types, fn, context) {

	if (typeof types === 'object') {
		for (var type in types) {
			removeOne(obj, type, types[type], fn);
		}
	} else if (types) {
		types = splitWords(types);

		for (var i = 0, len = types.length; i < len; i++) {
			removeOne(obj, types[i], fn, context);
		}
	} else {
		for (var j in obj[eventsKey]) {
			removeOne(obj, j, obj[eventsKey][j]);
		}
		delete obj[eventsKey];
	}
}

function addOne(obj, type, fn, context) {
	var id = type + stamp(fn) + (context ? '_' + stamp(context) : '');

	if (obj[eventsKey] && obj[eventsKey][id]) { return this; }

	var handler = function (e) {
		return fn.call(context || obj, e || window.event);
	};

	var originalHandler = handler;

	if (pointer && type.indexOf('touch') === 0) {
		// Needs DomEvent.Pointer.js
		addPointerListener(obj, type, handler, id);

	} else if (touch && (type === 'dblclick') && addDoubleTapListener &&
	           !(pointer && chrome)) {
		// Chrome >55 does not need the synthetic dblclicks from addDoubleTapListener
		// See #5180
		addDoubleTapListener(obj, handler, id);

	} else if ('addEventListener' in obj) {

		if (type === 'mousewheel') {
			obj.addEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);

		} else if ((type === 'mouseenter') || (type === 'mouseleave')) {
			handler = function (e) {
				e = e || window.event;
				if (isExternalTarget(obj, e)) {
					originalHandler(e);
				}
			};
			obj.addEventListener(type === 'mouseenter' ? 'mouseover' : 'mouseout', handler, false);

		} else {
			if (type === 'click' && android) {
				handler = function (e) {
					filterClick(e, originalHandler);
				};
			}
			obj.addEventListener(type, handler, false);
		}

	} else if ('attachEvent' in obj) {
		obj.attachEvent('on' + type, handler);
	}

	obj[eventsKey] = obj[eventsKey] || {};
	obj[eventsKey][id] = handler;
}

function removeOne(obj, type, fn, context) {

	var id = type + stamp(fn) + (context ? '_' + stamp(context) : ''),
	    handler = obj[eventsKey] && obj[eventsKey][id];

	if (!handler) { return this; }

	if (pointer && type.indexOf('touch') === 0) {
		removePointerListener(obj, type, id);

	} else if (touch && (type === 'dblclick') && removeDoubleTapListener) {
		removeDoubleTapListener(obj, id);

	} else if ('removeEventListener' in obj) {

		if (type === 'mousewheel') {
			obj.removeEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);

		} else {
			obj.removeEventListener(
				type === 'mouseenter' ? 'mouseover' :
				type === 'mouseleave' ? 'mouseout' : type, handler, false);
		}

	} else if ('detachEvent' in obj) {
		obj.detachEvent('on' + type, handler);
	}

	obj[eventsKey][id] = null;
}

// @function stopPropagation(ev: DOMEvent): this
// Stop the given event from propagation to parent elements. Used inside the listener functions:
// ```js
// L.DomEvent.on(div, 'click', function (ev) {
// 	L.DomEvent.stopPropagation(ev);
// });
// ```
function stopPropagation(e) {

	if (e.stopPropagation) {
		e.stopPropagation();
	} else if (e.originalEvent) {  // In case of Leaflet event.
		e.originalEvent._stopped = true;
	} else {
		e.cancelBubble = true;
	}
	skipped(e);

	return this;
}

// @function disableScrollPropagation(el: HTMLElement): this
// Adds `stopPropagation` to the element's `'mousewheel'` events (plus browser variants).
function disableScrollPropagation(el) {
	return addOne(el, 'mousewheel', stopPropagation);
}

// @function disableClickPropagation(el: HTMLElement): this
// Adds `stopPropagation` to the element's `'click'`, `'doubleclick'`,
// `'mousedown'` and `'touchstart'` events (plus browser variants).
function disableClickPropagation(el) {
	on(el, 'mousedown touchstart dblclick', stopPropagation);
	addOne(el, 'click', fakeStop);
	return this;
}

// @function preventDefault(ev: DOMEvent): this
// Prevents the default action of the DOM Event `ev` from happening (such as
// following a link in the href of the a element, or doing a POST request
// with page reload when a `<form>` is submitted).
// Use it inside listener functions.
function preventDefault(e) {
	if (e.preventDefault) {
		e.preventDefault();
	} else {
		e.returnValue = false;
	}
	return this;
}

// @function stop(ev): this
// Does `stopPropagation` and `preventDefault` at the same time.
function stop(e) {
	preventDefault(e);
	stopPropagation(e);
	return this;
}

// @function getMousePosition(ev: DOMEvent, container?: HTMLElement): Point
// Gets normalized mouse position from a DOM event relative to the
// `container` or to the whole page if not specified.
function getMousePosition(e, container) {
	if (!container) {
		return new Point(e.clientX, e.clientY);
	}

	var rect = container.getBoundingClientRect();

	return new Point(
		e.clientX - rect.left - container.clientLeft,
		e.clientY - rect.top - container.clientTop);
}

// Chrome on Win scrolls double the pixels as in other platforms (see #4538),
// and Firefox scrolls device pixels, not CSS pixels
var wheelPxFactor =
	(win && chrome) ? 2 :
	gecko ? window.devicePixelRatio : 1;

// @function getWheelDelta(ev: DOMEvent): Number
// Gets normalized wheel delta from a mousewheel DOM event, in vertical
// pixels scrolled (negative if scrolling down).
// Events from pointing devices without precise scrolling are mapped to
// a best guess of 60 pixels.
function getWheelDelta(e) {
	return (edge) ? e.wheelDeltaY / 2 : // Don't trust window-geometry-based delta
	       (e.deltaY && e.deltaMode === 0) ? -e.deltaY / wheelPxFactor : // Pixels
	       (e.deltaY && e.deltaMode === 1) ? -e.deltaY * 20 : // Lines
	       (e.deltaY && e.deltaMode === 2) ? -e.deltaY * 60 : // Pages
	       (e.deltaX || e.deltaZ) ? 0 :	// Skip horizontal/depth wheel events
	       e.wheelDelta ? (e.wheelDeltaY || e.wheelDelta) / 2 : // Legacy IE pixels
	       (e.detail && Math.abs(e.detail) < 32765) ? -e.detail * 20 : // Legacy Moz lines
	       e.detail ? e.detail / -32765 * 60 : // Legacy Moz pages
	       0;
}

var skipEvents = {};

function fakeStop(e) {
	// fakes stopPropagation by setting a special event flag, checked/reset with skipped(e)
	skipEvents[e.type] = true;
}

function skipped(e) {
	var events = skipEvents[e.type];
	// reset when checking, as it's only used in map container and propagates outside of the map
	skipEvents[e.type] = false;
	return events;
}

// check if element really left/entered the event target (for mouseenter/mouseleave)
function isExternalTarget(el, e) {

	var related = e.relatedTarget;

	if (!related) { return true; }

	try {
		while (related && (related !== el)) {
			related = related.parentNode;
		}
	} catch (err) {
		return false;
	}
	return (related !== el);
}

var lastClick;

// this is a horrible workaround for a bug in Android where a single touch triggers two click events
function filterClick(e, handler) {
	var timeStamp = (e.timeStamp || (e.originalEvent && e.originalEvent.timeStamp)),
	    elapsed = lastClick && (timeStamp - lastClick);

	// are they closer together than 500ms yet more than 100ms?
	// Android typically triggers them ~300ms apart while multiple listeners
	// on the same event should be triggered far faster;
	// or check if click is simulated on the element, and if it is, reject any non-simulated events

	if ((elapsed && elapsed > 100 && elapsed < 500) || (e.target._simulatedClick && !e._simulated)) {
		stop(e);
		return;
	}
	lastClick = timeStamp;

	handler(e);
}




var DomEvent = (Object.freeze || Object)({
	on: on,
	off: off,
	stopPropagation: stopPropagation,
	disableScrollPropagation: disableScrollPropagation,
	disableClickPropagation: disableClickPropagation,
	preventDefault: preventDefault,
	stop: stop,
	getMousePosition: getMousePosition,
	getWheelDelta: getWheelDelta,
	fakeStop: fakeStop,
	skipped: skipped,
	isExternalTarget: isExternalTarget,
	addListener: on,
	removeListener: off
});

/*
 * @namespace DomUtil
 *
 * Utility functions to work with the [DOM](https://developer.mozilla.org/docs/Web/API/Document_Object_Model)
 * tree, used by Leaflet internally.
 *
 * Most functions expecting or returning a `HTMLElement` also work for
 * SVG elements. The only difference is that classes refer to CSS classes
 * in HTML and SVG classes in SVG.
 */


// @property TRANSFORM: String
// Vendor-prefixed fransform style name (e.g. `'webkitTransform'` for WebKit).
var TRANSFORM = testProp(
    ['transform', 'WebkitTransform', 'OTransform', 'MozTransform', 'msTransform']);

// webkitTransition comes first because some browser versions that drop vendor prefix don't do
// the same for the transitionend event, in particular the Android 4.1 stock browser

// @property TRANSITION: String
// Vendor-prefixed transform style name.
var TRANSITION = testProp(
    ['webkitTransition', 'transition', 'OTransition', 'MozTransition', 'msTransition']);

var TRANSITION_END =
    TRANSITION === 'webkitTransition' || TRANSITION === 'OTransition' ? TRANSITION + 'End' : 'transitionend';


// @function get(id: String|HTMLElement): HTMLElement
// Returns an element given its DOM id, or returns the element itself
// if it was passed directly.
function get(id) {
    return typeof id === 'string' ? document.getElementById(id) : id;
}

// @function getStyle(el: HTMLElement, styleAttrib: String): String
// Returns the value for a certain style attribute on an element,
// including computed values or values set through CSS.
function getStyle(el, style) {
    var value = el.style[style] || (el.currentStyle && el.currentStyle[style]);

    if ((!value || value === 'auto') && document.defaultView) {
        var css = document.defaultView.getComputedStyle(el, null);
        value = css ? css[style] : null;
    }
    return value === 'auto' ? null : value;
}

// @function create(tagName: String, className?: String, container?: HTMLElement): HTMLElement
// Creates an HTML element with `tagName`, sets its class to `className`, and optionally appends it to `container` element.
function create$1(tagName, className, container) {
    var el = document.createElement(tagName);
    el.className = className || '';

    if (container) {
        container.appendChild(el);
    }
    return el;
}

// @function remove(el: HTMLElement)
// Removes `el` from its parent element
function remove(el) {
    var parent = el.parentNode;
    if (parent) {
        parent.removeChild(el);
    }
}

// @function empty(el: HTMLElement)
// Removes all of `el`'s children elements from `el`
function empty(el) {
    while (el.firstChild) {
        el.removeChild(el.firstChild);
    }
}

// @function toFront(el: HTMLElement)
// Makes `el` the last child of its parent, so it renders in front of the other children.
function toFront(el) {
    el.parentNode.appendChild(el);
}

// @function toBack(el: HTMLElement)
// Makes `el` the first child of its parent, so it renders behind the other children.
function toBack(el) {
    var parent = el.parentNode;
    parent.insertBefore(el, parent.firstChild);
}

// @function hasClass(el: HTMLElement, name: String): Boolean
// Returns `true` if the element's class attribute contains `name`.
function hasClass(el, name) {
    if (el.classList !== undefined) {
        return el.classList.contains(name);
    }
    var className = getClass(el);
    return className.length > 0 && new RegExp('(^|\\s)' + name + '(\\s|$)').test(className);
}

// @function addClass(el: HTMLElement, name: String)
// Adds `name` to the element's class attribute.
function addClass(el, name) {
    if (el.classList !== undefined) {
        var classes = splitWords(name);
        for (var i = 0, len = classes.length; i < len; i++) {
            el.classList.add(classes[i]);
        }
    } else if (!hasClass(el, name)) {
        var className = getClass(el);
        setClass(el, (className ? className + ' ' : '') + name);
    }
}

// @function removeClass(el: HTMLElement, name: String)
// Removes `name` from the element's class attribute.
function removeClass(el, name) {
    if (el.classList !== undefined) {
        el.classList.remove(name);
    } else {
        setClass(el, trim((' ' + getClass(el) + ' ').replace(' ' + name + ' ', ' ')));
    }
}

// @function setClass(el: HTMLElement, name: String)
// Sets the element's class.
function setClass(el, name) {
    if (el.className.baseVal === undefined) {
        el.className = name;
    } else {
        // in case of SVG element
        el.className.baseVal = name;
    }
}

// @function getClass(el: HTMLElement): String
// Returns the element's class.
function getClass(el) {
    return el.className.baseVal === undefined ? el.className : el.className.baseVal;
}

// @function setOpacity(el: HTMLElement, opacity: Number)
// Set the opacity of an element (including old IE support).
// `opacity` must be a number from `0` to `1`.
function setOpacity(el, value) {
    if ('opacity' in el.style) {
        el.style.opacity = value;
    } else if ('filter' in el.style) {
        _setOpacityIE(el, value);
    }
}

function _setOpacityIE(el, value) {
    var filter = false,
        filterName = 'DXImageTransform.Microsoft.Alpha';

    // filters collection throws an error if we try to retrieve a filter that doesn't exist
    try {
        filter = el.filters.item(filterName);
    } catch (e) {
        // don't set opacity to 1 if we haven't already set an opacity,
        // it isn't needed and breaks transparent pngs.
        if (value === 1) { return; }
    }

    value = Math.round(value * 100);

    if (filter) {
        filter.Enabled = (value !== 100);
        filter.Opacity = value;
    } else {
        el.style.filter += ' progid:' + filterName + '(opacity=' + value + ')';
    }
}

// @function testProp(props: String[]): String|false
// Goes through the array of style names and returns the first name
// that is a valid style name for an element. If no such name is found,
// it returns false. Useful for vendor-prefixed styles like `transform`.
function testProp(props) {
    var style = document.documentElement.style;

    for (var i = 0; i < props.length; i++) {
        if (props[i] in style) {
            return props[i];
        }
    }
    return false;
}

// @function setTransform(el: HTMLElement, offset: Point, scale?: Number)
// Resets the 3D CSS transform of `el` so it is translated by `offset` pixels
// and optionally scaled by `scale`. Does not have an effect if the
// browser doesn't support 3D CSS transforms.
function setTransform(el, offset, scale) {
    var pos = offset || new Point(0, 0);

    el.style[TRANSFORM] =
        (ie3d ?
            'translate(' + pos.x + 'px,' + pos.y + 'px)' :
            'translate3d(' + pos.x + 'px,' + pos.y + 'px,0)') +
        (scale ? ' scale(' + scale + ')' : '');
}

// @function setPosition(el: HTMLElement, position: Point)
// Sets the position of `el` to coordinates specified by `position`,
// using CSS translate or top/left positioning depending on the browser
// (used by Leaflet internally to position its layers).
function setPosition(el, point) {

    /*eslint-disable */
    el._leaflet_pos = point;
    /*eslint-enable */

    if (any3d) {
        setTransform(el, point);
    } else {
        el.style.left = point.x + 'px';
        el.style.top = point.y + 'px';
    }
}

// @function getPosition(el: HTMLElement): Point
// Returns the coordinates of an element previously positioned with setPosition.
function getPosition(el) {
    // this method is only used for elements previously positioned using setPosition,
    // so it's safe to cache the position for performance

    return el._leaflet_pos || new Point(0, 0);
}

// @function disableTextSelection()
// Prevents the user from generating `selectstart` DOM events, usually generated
// when the user drags the mouse through a page with text. Used internally
// by Leaflet to override the behaviour of any click-and-drag interaction on
// the map. Affects drag interactions on the whole document.

// @function enableTextSelection()
// Cancels the effects of a previous [`L.DomUtil.disableTextSelection`](#domutil-disabletextselection).
var disableTextSelection;
var enableTextSelection;
var _userSelect;
if ('onselectstart' in document) {
    disableTextSelection = function () {
        on(window, 'selectstart', preventDefault);
    };
    enableTextSelection = function () {
        off(window, 'selectstart', preventDefault);
    };
} else {
    var userSelectProperty = testProp(
        ['userSelect', 'WebkitUserSelect', 'OUserSelect', 'MozUserSelect', 'msUserSelect']);

    disableTextSelection = function () {
        if (userSelectProperty) {
            var style = document.documentElement.style;
            _userSelect = style[userSelectProperty];
            style[userSelectProperty] = 'none';
        }
    };
    enableTextSelection = function () {
        if (userSelectProperty) {
            document.documentElement.style[userSelectProperty] = _userSelect;
            _userSelect = undefined;
        }
    };
}

// @function disableImageDrag()
// As [`L.DomUtil.disableTextSelection`](#domutil-disabletextselection), but
// for `dragstart` DOM events, usually generated when the user drags an image.
function disableImageDrag() {
    on(window, 'dragstart', preventDefault);
}

// @function enableImageDrag()
// Cancels the effects of a previous [`L.DomUtil.disableImageDrag`](#domutil-disabletextselection).
function enableImageDrag() {
    off(window, 'dragstart', preventDefault);
}

var _outlineElement;
var _outlineStyle;
// @function preventOutline(el: HTMLElement)
// Makes the [outline](https://developer.mozilla.org/docs/Web/CSS/outline)
// of the element `el` invisible. Used internally by Leaflet to prevent
// focusable elements from displaying an outline when the user performs a
// drag interaction on them.
function preventOutline(element) {
    while (element.tabIndex === -1) {
        element = element.parentNode;
    }
    if (!element || !element.style) { return; }
    restoreOutline();
    _outlineElement = element;
    _outlineStyle = element.style.outline;
    element.style.outline = 'none';
    on(window, 'keydown', restoreOutline);
}

// @function restoreOutline()
// Cancels the effects of a previous [`L.DomUtil.preventOutline`]().
function restoreOutline() {
    if (!_outlineElement) { return; }
    _outlineElement.style.outline = _outlineStyle;
    _outlineElement = undefined;
    _outlineStyle = undefined;
    off(window, 'keydown', restoreOutline);
}


var DomUtil = (Object.freeze || Object)({
	TRANSFORM: TRANSFORM,
	TRANSITION: TRANSITION,
	TRANSITION_END: TRANSITION_END,
	get: get,
	getStyle: getStyle,
	create: create$1,
	remove: remove,
	empty: empty,
	toFront: toFront,
	toBack: toBack,
	hasClass: hasClass,
	addClass: addClass,
	removeClass: removeClass,
	setClass: setClass,
	getClass: getClass,
	setOpacity: setOpacity,
	testProp: testProp,
	setTransform: setTransform,
	setPosition: setPosition,
	getPosition: getPosition,
	disableTextSelection: disableTextSelection,
	enableTextSelection: enableTextSelection,
	disableImageDrag: disableImageDrag,
	enableImageDrag: enableImageDrag,
	preventOutline: preventOutline,
	restoreOutline: restoreOutline
});

// import {Class} from '../core/Class';
/*
 * @class Reader
 * @aka cozy.Map
 * @inherits Evented
 *
 * The central class of the API — it is used to create a book on a page and manipulate it.
 *
 * @example
 *
 * ```js
 * // initialize the map on the "map" div with a given center and zoom
 * var map = L.map('map', {
 *  center: [51.505, -0.09],
 *  zoom: 13
 * });
 * ```
 *
 */

var _padding = 1.0;
var Reader = Evented.extend({
  options: {
    regions: [
      'header',
      'toolbar.top',
      'toolbar.left',
      'main',
      'toolbar.right',
      'toolbar.bottom',
      'footer'
    ],
    flow: 'auto',
    engine: 'epubjs',
    trackResize: true
  },

  initialize: function(id, options) {
    var self = this;

    options = setOptions(this, options);

    this._initContainer(id);
    this._initLayout();

    // hack for https://github.com/Leaflet/Leaflet/issues/1980
    this._onResize = bind(this._onResize, this);

    this._initEvents();

    this.callInitHooks();

    this._mode = this.options.mode;
  },

  start: function(target) {
    var self = this;
    var panes = self._panes;

    self.setBookPanelSize();

    var x = panes['book-cover']; var xx = panes['book'];

    this.open();

    this.draw(target || 0);
    this._loaded = true;
  },

  switch: function(flow, target) {
    var target = target || this.currentLocation();
    console.log("AHOY SWITCH", target.start);
    if ( flow === undefined ) {
      flow = ( this.options.flow == 'auto' ) ? 'scrolled-doc' : 'auto';
    }
    this.options.flow = flow;
    this.destroy();
    this.draw(target);
  },

  draw: function(target) {
    // NOOP
  },

  next: function() {
    // NOOP
  },

  prev: function() {
    // NOOP
  },

  display: function(index) {
    // NOOP
  },

  gotoPage: function(target) {
    // NOOP
  },

  _initContainer: function (id) {
    var container = this._container = get(id);

    if (!container) {
      throw new Error('Reader container not found.');
    } else if (container._cozy_id) {
      throw new Error('Reader container is already initialized.');
    }

    on(container, 'scroll', this._onScroll, this);
    this._containerId = stamp(container);
  },

  _initLayout: function () {
    var container = this._container;

    this._fadeAnimated = this.options.fadeAnimation && any3d;

    addClass(container, 'cozy-container' +
      (touch ? ' cozy-touch' : '') +
      (retina ? ' cozy-retina' : '') +
      (ielt9 ? ' cozy-oldie' : '') +
      (safari ? ' cozy-safari' : '') +
      (this._fadeAnimated ? ' cozy-fade-anim' : ''));

    var position = getStyle(container, 'position');

    if (position !== 'absolute' && position !== 'relative' && position !== 'fixed') {
      container.style.position = 'relative';
    }

    this._initPanes();

    // if (this._initControlPos) {
    //   this._initControlPos();
    // }
  },

  _initPanes: function () {
    var self = this;

    var panes = this._panes = {};

    var l = 'cozy-';
    var container = this._container;

    var prefix = 'cozy-module-';

    addClass(container, 'cozy-container');
    panes['top'] = create$1('div', prefix + 'top', container);
    panes['main'] = create$1('div', prefix + 'main', container);
    panes['bottom'] = create$1('div', prefix + 'bottom', container);

    panes['left'] = create$1('div', prefix + 'left', panes['main']);
    panes['book-cover'] = create$1('div', prefix + 'book-cover', panes['main']);
    panes['right'] = create$1('div', prefix + 'right', panes['main']);
    panes['book'] = create$1('div', prefix + 'book', panes['book-cover']);
  },

  _checkIfLoaded: function () {
    if (!this._loaded) {
      throw new Error('Set map center and zoom first.');
    }
  },

  // DOM event handling

  // @section Interaction events
  _initEvents: function (remove$$1) {
    this._targets = {};
    this._targets[stamp(this._container)] = this;

    var onOff = remove$$1 ? off : on;

    // @event click: MouseEvent
    // Fired when the user clicks (or taps) the map.
    // @event dblclick: MouseEvent
    // Fired when the user double-clicks (or double-taps) the map.
    // @event mousedown: MouseEvent
    // Fired when the user pushes the mouse button on the map.
    // @event mouseup: MouseEvent
    // Fired when the user releases the mouse button on the map.
    // @event mouseover: MouseEvent
    // Fired when the mouse enters the map.
    // @event mouseout: MouseEvent
    // Fired when the mouse leaves the map.
    // @event mousemove: MouseEvent
    // Fired while the mouse moves over the map.
    // @event contextmenu: MouseEvent
    // Fired when the user pushes the right mouse button on the map, prevents
    // default browser context menu from showing if there are listeners on
    // this event. Also fired on mobile when the user holds a single touch
    // for a second (also called long press).
    // @event keypress: KeyboardEvent
    // Fired when the user presses a key from the keyboard while the map is focused.
    // onOff(this._container, 'click dblclick mousedown mouseup ' +
    //   'mouseover mouseout mousemove contextmenu keypress', this._handleDOMEvent, this);

    if (this.options.trackResize) {
      onOff(window, 'resize', this._onResize, this);
    }

    if (any3d && this.options.transform3DLimit) {
      (remove$$1 ? this.off : this.on).call(this, 'moveend', this._onMoveEnd);
    }
  },

  // _onResize: function () {
  //   Util.cancelAnimFrame(this._resizeRequest);
  //   this._resizeRequest = Util.requestAnimFrame(
  //           function () { this.invalidateSize({debounceMoveend: true}); }, this);
  // },

  _onResize: function() {
    if ( ! this._resizeRequest ) {
      this._resizeRequest = requestAnimFrame(function() {
        this.invalidateSize({});
      }, this);
    }
  },

  _onScroll: function () {
    this._container.scrollTop  = 0;
    this._container.scrollLeft = 0;
  },

  _handleDOMEvent: function (e) {
    if (!this._loaded || skipped(e)) { return; }

    var type = e.type === 'keypress' && e.keyCode === 13 ? 'click' : e.type;

    if (type === 'mousedown') {
      // prevents outline when clicking on keyboard-focusable element
      preventOutline(e.target || e.srcElement);
    }

    this._fireDOMEvent(e, type);
  },

  _fireDOMEvent: function (e, type, targets) {

    if (e.type === 'click') {
      // Fire a synthetic 'preclick' event which propagates up (mainly for closing popups).
      // @event preclick: MouseEvent
      // Fired before mouse click on the map (sometimes useful when you
      // want something to happen on click before any existing click
      // handlers start running).
      var synth = extend({}, e);
      synth.type = 'preclick';
      this._fireDOMEvent(synth, synth.type, targets);
    }

    if (e._stopped) { return; }

    // Find the layer the event is propagating from and its parents.
    targets = (targets || []).concat(this._findEventTargets(e, type));

    if (!targets.length) { return; }

    var target = targets[0];
    if (type === 'contextmenu' && target.listens(type, true)) {
      preventDefault(e);
    }

    var data = {
      originalEvent: e
    };

    if (e.type !== 'keypress') {
      var isMarker = (target.options && 'icon' in target.options);
      data.containerPoint = isMarker ?
          this.latLngToContainerPoint(target.getLatLng()) : this.mouseEventToContainerPoint(e);
      data.layerPoint = this.containerPointToLayerPoint(data.containerPoint);
      data.latlng = isMarker ? target.getLatLng() : this.layerPointToLatLng(data.layerPoint);
    }

    for (var i = 0; i < targets.length; i++) {
      targets[i].fire(type, data, true);
      if (data.originalEvent._stopped ||
        (targets[i].options.nonBubblingEvents && indexOf(targets[i].options.nonBubblingEvents, type) !== -1)) { return; }
    }
  },

  setBookPanelSize: function() {
    var panes = this._panes;

    panes['book'].style.height = (panes['book-cover'].offsetHeight * _padding) + 'px';
    panes['book'].style.width = (panes['book-cover'].offsetWidth * _padding) + 'px';
    panes['book'].style.display = 'block';
  },

  invalidateSize: function(options) {
    var self = this;

    cancelAnimFrame(this._resizeRequest);
    this._resizeRequest = null;

    if (! this._loaded) { return this; }


    var target = this.currentLocation();

    var panes = this._panes;
    panes['book'].style.display = 'none';

    setTimeout(function() {
      self.setBookPanelSize();

      if ( self._triggerRedraw ) {
        clearTimeout(self._triggerRedraw);
      }

      self._triggerRedraw = setTimeout(function() {
        self.destroy();
        self.draw(target);
      }, 150);


    }, 0);
    


  },

  EOT: true
});

/*
 * @class Control
 * @aka L.Control
 * @inherits Class
 *
 * L.Control is a base class for implementing reader controls. Handles regioning.
 * All other controls extend from this class.
 */

var Control = Class.extend({
    // @section
    // @aka Control options
    options: {
        // @option region: String = 'topright'
        // The region of the control (one of the reader corners). Possible values are `'topleft'`,
        // `'topright'`, `'bottomleft'` or `'bottomright'`
    },

    initialize: function (options) {
        setOptions(this, options);
        if ( options.container ) {
            this._container = options.container;
            this._locked = true;
        }
    },

    /* @section
     * Classes extending L.Control will inherit the following methods:
     *
     * @method getRegion: string
     * Returns the region of the control.
     */
    getRegion: function () {
        return this.options.region;
    },

    // @method setRegion(region: string): this
    // Sets the region of the control.
    setRegion: function (region) {
        var reader = this._reader;

        if (reader) {
            reader.removeControl(this);
        }

        this.options.region = region;

        if (reader) {
            reader.addControl(this);
        }

        return this;
    },

    // @method getContainer: HTMLElement
    // Returns the HTMLElement that contains the control.
    getContainer: function () {
        return this._container;
    },

    // @method addTo(reader: Map): this
    // Adds the control to the given reader.
    addTo: function (reader) {
        this.remove();
        this._reader = reader;

        var container = this._container = this.onAdd(reader);

        addClass(container, 'cozy-control');

        if ( ! this._locked ) {
            var region = this.getRegion();
            var area = reader.getControlRegion(region);
            area.appendChild(container);
        }

        return this;
    },

    // @method remove: this
    // Removes the control from the reader it is currently active on.
    remove: function () {
        if (!this._reader) {
            return this;
        }

        if (! this._container) {
            return this;
        }

console.log("AHOY REMOVE", this._locked);
        if ( ! this._locked ) {
            remove(this._container);
        }

        if (this.onRemove) {
            this.onRemove(this._reader);
        }

        this._reader = null;

        return this;
    },

    _refocusOnMap: function (e) {
        // if reader exists and event is not a keyboard event
        if (this._reader && e && e.screenX > 0 && e.screenY > 0) {
            this._reader.getContainer().focus();
        }
    },

    _className: function(widget) {
        var className = [ 'cozy-control' ];
        if ( this.options.direction ) {
            className.push('cozy-control-' + this.options.direction);
        }
        if ( widget ) {
            className.push('cozy-control-' + widget);
        }
        return className.join(' ');
    }
});

var control = function (options) {
    return new Control(options);
};

/* @section Extension methods
 * @uninheritable
 *
 * Every control should extend from `L.Control` and (re-)implement the following methods.
 *
 * @method onAdd(reader: Map): HTMLElement
 * Should return the container DOM element for the control and add listeners on relevant reader events. Called on [`control.addTo(reader)`](#control-addTo).
 *
 * @method onRemove(reader: Map)
 * Optional method. Should contain all clean up code that removes the listeners previously added in [`onAdd`](#control-onadd). Called on [`control.remove()`](#control-remove).
 */

/* @namespace Map
 * @section Methods for Layers and Controls
 */
Reader.include({
    // @method addControl(control: Control): this
    // Adds the given control to the reader
    addControl: function (control) {
        control.addTo(this);
        return this;
    },

    // @method removeControl(control: Control): this
    // Removes the given control from the reader
    removeControl: function (control) {
        control.remove();
        return this;
    },

    getControlContainer: function() {
        var l = 'cozy-';
        if ( ! this._controlContainer ) {
            this._controlContainer =
                create$1('div', l + 'control-container', this._container);
        }
        return this._controlContainer;
    },

    getControlRegion: function (target) {

        if ( ! this._panes[target] ) {
            // target is dot-delimited string
            // first dot is the panel
            var parts = target.split('.');
            var tmp = [];
            var parent = this._container;
            var x = 0;
            while ( parts.length ) {
                var slug = parts.shift();
                tmp.push(slug);
                var panel = tmp.join(".");
                var className = 'cozy-panel-' + slug;
                if ( ! this._panes[panel] ) {
                    this._panes[panel] = create$1('div', className, parent);
                }
                parent = this._panes[panel];
                x += 1;
                if ( x > 100 ) { break; }
            }
        }
        return this._panes[target];
    },

    getControlRegion_1: function (target) {

        var tmp = target.split('.');
        var region = tmp.shift();
        var slot = tmp.pop() || '-slot';

        var container = this._panes[region];
        if ( ! this._panes[target] ) {
            var className = 'cozy-' + region + '--item cozy-slot-' + slot;
            if ( ! this._panes[region + '.' + slot] ) {
                var div = create$1('div', className);
                if ( slot == 'left' || slot == 'bottom' ) {
                    var childElement = this._panes[region].firstChild;
                    this._panes[region].insertBefore(div, childElement);
                } else {
                    this._panes[region].appendChild(div);
                }
                this._panes[region + '.' + slot] = div;
            }
            className = this._classify(tmp);
            this._panes[target] = create$1('div', className, this._panes[region + '.' + slot]);
        }

        return this._panes[target];
    },

    _classify: function(tmp) {
        var l = 'cozy-';
        var className = [];
        for(var i in tmp) {
            className.push(l + tmp[i]);
        }
        className = className.join(' ');
        return className;
    },

    _clearControlRegion: function () {
        for (var i in this._controlRegions) {
            remove(this._controlRegions[i]);
        }
        remove(this._controlContainer);
        delete this._controlRegions;
        delete this._controlContainer;
    }
});

var PageControl = Control.extend({
  onAdd: function(reader) {
    var container = this._container;
    if ( container ) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {

      var className = this._className(),
          options = this.options;
      container = create$1('div', className),

      this._control  = this._createButton(options.html || options.label, options.label,
              className, container);
    }
    this._bindEvents();

    return container;
  },

  _createButton: function (html, title, className, container) {
    var link = create$1('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;

    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    return link;
  },

  _bindEvents: function() {
    disableClickPropagation(this._control);
    on(this._control, 'click', stop);
    on(this._control, 'click', this._action, this);
  },

  EOT: true
});

var PagePrevious = PageControl.extend({
  options: {
    region: 'edge.left',
    direction: 'previous',
    label: 'Prevous Page'
  },

  _action: function(e) {
    this._reader.prev();
  }
});

var PageNext = PageControl.extend({
  options: {
    region: 'edge.right',
    direction: 'next',
    label: 'Next Page'
  },

  _action: function(e) {
    this._reader.next();
  }
});

var PageFirst = PageControl.extend({
  options: {
    direction: 'first',
    label: 'First Page'
  },
  _action: function(e) {
      this._reader.first();
  }
});

var PageLast = PageControl.extend({
  options: {
    direction: 'last',
    label: 'Last Page'
  },
  _action: function(e) {
      this._reader.last();
  }
});

var pageNext = function(options) {
  return new PageNext(options);
};

var pagePrevious = function(options) {
  return new PagePrevious(options);
};

var pageFirst = function(options) {
  return new PageFirst(options);
};

var pageLast = function(options) {
  return new PageLast(options);
};

var Contents = Control.extend({

  defaultTemplate: `<button data-toggle="dropdown">Contents <span>&#9660;</span></button><ul class="cozy-dropdown-menu" data-target="menu"></ul>`,

  onAdd: function(reader) {
    var self = this;

    var container = this._container;
    if ( container ) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {

      var className = this._className(),
          options = this.options;

      container = create$1('div', className);

      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;
      while ( body.children.length ) {
        container.appendChild(body.children[0]);
      }
    }

    this._control = container.querySelector("[data-toggle=dropdown]");
    this._menu = container.querySelector("[data-target=menu]");
    this._menu.style.display = 'none';
    container.style.position = 'relative';

    on(this._control, 'click', function(event) {
      event.preventDefault();
      this._menu.style.display = 'block';
    }, this);

    on(this._menu, 'click', function(event) {
      event.preventDefault();
      var target = event.target;
      target = target.getAttribute('href');
      this._reader.gotoPage(target);
      this._menu.style.display = 'none';
    }, this);

    this._reader.on('update-contents', function(data) {
      var s = data.toc.filter(function(value) { return value.parent == null }).map(function(value) { return [ value, 0, self._menu ] });
      while ( s.length ) {
        var tuple = s.shift();
        var chapter = tuple[0];
        var tabindex = tuple[1];
        var parent = tuple[2];

        var option = self._createOption(chapter, tabindex, parent);
        data.toc.filter(function(value) { return value.parent == chapter.id }).reverse().forEach(function(chapter_) {
          s.unshift([chapter_, tabindex + 1, option]);
        });
      }
    });

    return container;
  },

  _createOption(chapter, tabindex, parent) {
    
    var option = create$1('li');
    var anchor = create$1('a', null, option);
    anchor.textContent = chapter.label;
    // var tab = pad('', tabindex); tab = tab.length ? tab + ' ' : '';
    // option.textContent = tab + chapter.label;
    anchor.setAttribute('href', chapter.href);

    if ( parent.tagName == 'LI' ) {
      // need to nest
      var tmp = parent.querySelector('ul');
      if ( ! tmp ) {
        tmp = create$1('ul', null, parent);
      }
      parent = tmp;
    }

    parent.appendChild(option);
    return option;
  },

  EOT: true
});

var contents = function(options) {
  return new Contents(options);
};

// Title + Chapter

var Title = Control.extend({
  onAdd: function(reader) {
    var self = this;
    var className = this._className(),
        container = create$1('div', className),
        options = this.options;

    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

    var h1 = create$1('h1', 'cozy-h1', container);
    this._title = create$1('span', 'cozy-title', h1);
    this._divider = create$1('span', 'cozy-divider', h1);
    this._divider.textContent = " / ";
    this._section = create$1('span', 'cozy-section', h1);

    this._reader.on('update-section', function(data) {
      console.log("AHOY UPDATE SECTION", data, arguments);
      if ( data && data.label ) {
        self._section.textContent = data.label;
        setOpacity(self._section, 1.0);
        setOpacity(self._divider, 1.0);
      } else {
        setOpacity(self._section, 0);
        setOpacity(self._divider, 0);
      }
    });

    this._reader.on('update-title', function(data) {
      console.log("UPDATE TITLE", data);
      if ( data ) {
        self._title.textContent = data.title;
        setOpacity(self._section, 0);
        setOpacity(self._divider, 0);
      }
    });

    return container;
  },

  _createButton: function (html, title, className, container, fn) {
    var link = create$1('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;

    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    disableClickPropagation(link);
    on(link, 'click', stop);
    on(link, 'click', fn, this);
    // DomEvent.on(link, 'click', this._refocusOnMap, this);

    return link;
  },

  EOT: true
});

var title = function(options) {
  return new Title(options);
};

// Title + Chapter

var PublicationMetadata = Control.extend({
  onAdd: function(reader) {
    var self = this;
    var className = this._className(),
        container = create$1('div', className),
        options = this.options;

    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

    this._publisher = create$1('div', 'cozy-publisher', container);
    this._rights = create$1('div', 'cozy-rights', container);

    this._reader.on('update-title', function(data) {
      if ( data ) {
        self._publisher.textContent = data.publisher;
        self._rights.textContent = data.rights;
      }
    });

    return container;
  },

  _createButton: function (html, title, className, container, fn) {
    var link = create$1('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;

    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    disableClickPropagation(link);
    on(link, 'click', stop);
    on(link, 'click', fn, this);
    // DomEvent.on(link, 'click', this._refocusOnMap, this);

    return link;
  },

  EOT: true
});

var publicationMetadata = function(options) {
  return new PublicationMetadata(options);
};

var Preferences = Control.extend({
  options: {
    label: 'Preferences'
  },

  onAdd: function(reader) {
    var self = this;
    var className = this._className('preferences'),
        container = create$1('div', className),
        options = this.options;

    this._activated = false;
    this._control = this._createButton(options.html || options.label, options.label,
            className, container, this._action);

    this._createPanel();

    return container;
  },

  _action: function() {
    this._panel.style.display = 'block';
  },

  _createButton: function (html, title, className, container, fn) {
    var link = create$1('button', className, container);
    link.innerHTML = html;
    link.title = title;

    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    disableClickPropagation(link);
    on(link, 'click', stop);
    on(link, 'click', fn, this);

    return link;
  },

  _createPanel: function() {
    var template = `<div class="cozy-modal cozy-preferences-modal" style="position: fixed; width: 300px; margin-left: -150px; left: 50%; top: 50%; transform: translateY(-50%); z-index: 9000; display: none">
      <header>
        <h2>Preferences</h2>
      </header>
      <article>
        <form>
          <fieldset>
            <legend>Flow</legend>
            <label><input name="flow" type="radio" id="preferences-input-reflowable" value="auto" /> Auto</label>
            <label><input name="flow" type="radio" id="preferences-input-scrollable" value="scrolled-doc" /> Scroll</label>
          </fieldset>
        </form>
      </article>
      <footer>
      </footer>
    </div>`;
    this._panel = new DOMParser().parseFromString(template, "text/html").body.firstChild;
    this._reader._container.appendChild(this._panel);

    var input_id = "preferences-input-" + ( this._reader.options.flow == 'scrollable' ? 'scrollable' : 'reflowable' );
    var input = this._panel.querySelector("#" + input_id);
    input.checked = true;

    var footer = this._panel.querySelector("footer");
    this._cancelButton = this._createButton('Cancel', 'Cancel Preferences', 'btn btn-default', footer, this._cancelAction);
    this._saveButton = this._createButton('Save', 'Save Preferences', 'btn btn-primary', footer, this._saveAction);
  },

  _cancelAction: function() {
    this._panel.style.display = 'none';
  },

  _saveAction: function() {
    var input = this._panel.querySelector("input[type=radio]:checked");
    var flow = input.value;
    this._panel.style.display = 'none';
    this._reader.switch(flow);
  },

  EOT: true
});

var preferences = function(options) {
  return new Preferences(options);
};

var Widget = Control.extend({

  defaultTemplate: `<button data-toggle="button" data-slot="title"></button>`,

  options: {
      // @option region: String = 'topright'
      // The region of the control (one of the reader corners). Possible values are `'topleft'`,
      // `'topright'`, `'bottomleft'` or `'bottomright'`
  },

  onAdd: function(reader) {
    var container = this._container;
    if ( container ) {
      // NOOP
    } else {

      var className = this._className(),
          options = this.options;

      container = create$1('div', className);

      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;
      while ( body.children.length ) {
        container.appendChild(body.children[0]);
      }

      this.state(this.options.states[0].stateName, container);

    }

    this._bindEvents(container);

    return container;
  },

  state: function(stateName, container) {
    container = container || this._container;
    this._resetState();
    this._state = this.options.states.filter(function(s) { return s.stateName == stateName })[0];
    if ( this._state.className ) {
      addClass(container, this._state.className);
    }
    if ( this._state.title ) {
      var element = container.querySelector("[data-slot=title]");
      element.innerHTML = this._state.title;
    }
  },

  _resetState: function() {
    if ( ! this._state ) { return; }
    if ( this._state.className ) {
      removeClass(this._container, this._state.className);
    }
  },

  _bindEvents: function(container) {
    var control$$1 = container.querySelector("[data-toggle=button]");
    if ( ! control$$1 ) { return ; }
    disableClickPropagation(control$$1);
    on(control$$1, 'click', stop);
    on(control$$1, 'click', this._action, this);
  },

  _action: function() {
    this._state.onClick(this, this._reader);
  },

  EOT: true
});

var widget = function(options) {
  return new Widget(options);
};

// import {Zoom, zoom} from './Control.Zoom';
// import {Attribution, attribution} from './Control.Attribution';

Control.PageNext = PageNext;
Control.PagePrevious = PagePrevious;
Control.PageFirst = PageFirst;
Control.PageLast = PageLast;
control.pagePrevious = pagePrevious;
control.pageNext = pageNext;
control.pageFirst = pageFirst;
control.pageLast = pageLast;

Control.Contents = Contents;
control.contents = contents;

Control.Title = Title;
control.title = title;

Control.PublicationMetadata = PublicationMetadata;
control.publicationMetadata = publicationMetadata;

Control.Preferences = Preferences;
control.preferences = preferences;

Control.Widget = Widget;
control.widget = widget;

var Bus = Evented.extend({
});

var instance;
var bus = function() {
  return instance || ( instance = new Bus() );
};

var Mixin = {Events: Evented.prototype};

var ePub = window.ePub;

Reader.EpubJS = Reader.extend({

  initialize: function(id, options) {
    Reader.prototype.initialize.apply(this, arguments);
  },

  open: function() {
    var self = this;
    this._book = ePub(this.options.href);
    this._book.loaded.navigation.then(function(toc) {
      self._contents = toc;
      self.fire('update-contents', toc);
      self.fire('update-title', self._book.package.metadata);
    });
  },

  draw: function(target, callback) {
    var self = this;
    this.settings = { flow: this.options.flow };
    this.settings.height = '100%';
    // this.settings.width = '100%';
    if ( this.options.flow == 'auto' ) {
      this._panes['book'].style.overflow = 'hidden';
    } else {
      this._panes['book'].style.overflow = 'auto';
    }
    // have to set this to prevent scrolling issues
    // this.settings.height = this._panes['book'].clientHeight;
    // this.settings.width = this._panes['book'].clientWidth;

    // start the rendition after all the epub parts 
    // have been loaded
    this._book.ready.then(function() {
      self._rendition = self._book.renderTo(self._panes['book'], self.settings);
      self._bindEvents();

      if ( target && target.start ) { target = target.start; }
      self._rendition.display(target).then(function() {
        if ( callback ) { callback(); }
      });
    });
  },

  next: function() {
    this._rendition.next();
  },

  prev: function() {
    this._rendition.prev();
  },

  first: function() {
    this._rendition.display(0);
  },

  last: function() {
    var self = this;
    var target = this._book.spine.length - 1;
    this._rendition.display(target);
    return;

    var target = 0.9999999;
    var promise;
    // epub.js looks for floats, but Javascript treats 100.0 === 100
    if ( this._book.locations.total == 0 ) {
      promise = this._book.locations.generate(); 
    } else {
      promise = new Promise(function(fullfill){ fullfill();});
    }
    promise.then(function() { self._rendition.display(target); });
  },

  gotoPage: function(target) {
    if ( typeof(target) == "string" && target.substr(0, 3) == '../' ) {
      while ( target.substr(0, 3) == '../' ) {
        target = target.substr(3);
      }
    }
    this._rendition.display(target);
  },

  destroy: function() {
    if ( this._rendition ) {
      this._rendition.destroy();
    }
    this._rendition = null;
  },

  currentLocation: function() {
    if ( this._rendition ) { 
      return this._rendition.currentLocation();
    }
    return null;
  },

  _bindEvents: function() {
    var self = this;

    // add a stylesheet to stop images from breaking their columns
    var add_max_img_styles = false;
    if ( this._book.package.metadata.layout == 'pre-paginated' ) {
      // NOOP
    } else if ( this.options.flow == 'auto' || this.options.flow == 'reflowable' ) {
      add_max_img_styles = true;
    }
    if ( add_max_img_styles ) {
      this._rendition.hooks.content.register(function(view) {
        view.addStylesheetRules([ [ 'img', [ 'max-height', '100%' ], [ 'max-width', '100%'] ] ]);
      });
    }
    this._rendition.on("locationChanged", function(location) {
      var view = this.manager.current();
      var section = view.section;
      var current = this.book.navigation.get(section.href);
      self.fire("update-section", current);
    });
  },

  EOT: true

});

function createReader$1(id, options) {
  return new Reader.EpubJS(id, options);
}

var engines = {
  epubjs: createReader$1
};

var reader = function(id, options) {
  var engine = options.engine || 'epubjs';
  return engines[engine].apply(this, arguments);
};

// misc

var oldCozy = window.cozy;
function noConflict() {
  window.cozy = oldCozy;
  return this;
}

exports.version = version;
exports.noConflict = noConflict;
exports.Control = Control;
exports.control = control;
exports.Browser = Browser;
exports.Evented = Evented;
exports.Mixin = Mixin;
exports.Util = Util;
exports.Class = Class;
exports.extend = extend;
exports.bind = bind;
exports.stamp = stamp;
exports.setOptions = setOptions;
exports.bus = bus;
exports.DomEvent = DomEvent;
exports.DomUtil = DomUtil;
exports.reader = reader;

})));
//# sourceMappingURL=cozy-src.js.map
