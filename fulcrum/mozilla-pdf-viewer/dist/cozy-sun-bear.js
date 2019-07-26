/*
 * Cozy Sun Bear 1.0.0e6cd8ae, a JS library for interactive books. http://github.com/mlibrary/cozy-sun-bear
 * (c) 2019 Regents of the University of Michigan
 */
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
	typeof define === 'function' && define.amd ? define(['exports'], factory) :
	(factory((global.cozy = {})));
}(this, (function (exports) { 'use strict';

	var commonjsGlobal = typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	(function(global) {
	  /**
	   * Polyfill URLSearchParams
	   *
	   * Inspired from : https://github.com/WebReflection/url-search-params/blob/master/src/url-search-params.js
	   */

	  var checkIfIteratorIsSupported = function() {
	    try {
	      return !!Symbol.iterator;
	    } catch(error) {
	      return false;
	    }
	  };


	  var iteratorSupported = checkIfIteratorIsSupported();

	  var createIterator = function(items) {
	    var iterator = {
	      next: function() {
	        var value = items.shift();
	        return { done: value === void 0, value: value };
	      }
	    };

	    if(iteratorSupported) {
	      iterator[Symbol.iterator] = function() {
	        return iterator;
	      };
	    }

	    return iterator;
	  };

	  /**
	   * Search param name and values should be encoded according to https://url.spec.whatwg.org/#urlencoded-serializing
	   * encodeURIComponent() produces the same result except encoding spaces as `%20` instead of `+`.
	   */
	  var serializeParam = function(value) {
	    return encodeURIComponent(value).replace(/%20/g, '+');
	  };

	  var deserializeParam = function(value) {
	    return decodeURIComponent(value).replace(/\+/g, ' ');
	  };

	  var polyfillURLSearchParams= function() {

	    var URLSearchParams = function(searchString) {
	      Object.defineProperty(this, '_entries', { value: {} });

	      if(typeof searchString === 'string') {
	        if(searchString !== '') {
	          searchString = searchString.replace(/^\?/, '');
	          var attributes = searchString.split('&');
	          var attribute;
	          for(var i = 0; i < attributes.length; i++) {
	            attribute = attributes[i].split('=');
	            this.append(
	              deserializeParam(attribute[0]),
	              (attribute.length > 1) ? deserializeParam(attribute[1]) : ''
	            );
	          }
	        }
	      } else if(searchString instanceof URLSearchParams) {
	        var _this = this;
	        searchString.forEach(function(value, name) {
	          _this.append(value, name);
	        });
	      }
	    };

	    var proto = URLSearchParams.prototype;

	    proto.append = function(name, value) {
	      if(name in this._entries) {
	        this._entries[name].push(value.toString());
	      } else {
	        this._entries[name] = [value.toString()];
	      }
	    };

	    proto.delete = function(name) {
	      delete this._entries[name];
	    };

	    proto.get = function(name) {
	      return (name in this._entries) ? this._entries[name][0] : null;
	    };

	    proto.getAll = function(name) {
	      return (name in this._entries) ? this._entries[name].slice(0) : [];
	    };

	    proto.has = function(name) {
	      return (name in this._entries);
	    };

	    proto.set = function(name, value) {
	      this._entries[name] = [value.toString()];
	    };

	    proto.forEach = function(callback, thisArg) {
	      var entries;
	      for(var name in this._entries) {
	        if(this._entries.hasOwnProperty(name)) {
	          entries = this._entries[name];
	          for(var i = 0; i < entries.length; i++) {
	            callback.call(thisArg, entries[i], name, this);
	          }
	        }
	      }
	    };

	    proto.keys = function() {
	      var items = [];
	      this.forEach(function(value, name) { items.push(name); });
	      return createIterator(items);
	    };

	    proto.values = function() {
	      var items = [];
	      this.forEach(function(value) { items.push(value); });
	      return createIterator(items);
	    };

	    proto.entries = function() {
	      var items = [];
	      this.forEach(function(value, name) { items.push([name, value]); });
	      return createIterator(items);
	    };

	    if(iteratorSupported) {
	      proto[Symbol.iterator] = proto.entries;
	    }

	    proto.toString = function() {
	      var searchString = '';
	      this.forEach(function(value, name) {
	        if(searchString.length > 0) searchString+= '&';
	        searchString += serializeParam(name) + '=' + serializeParam(value);
	      });
	      return searchString;
	    };

	    global.URLSearchParams = URLSearchParams;
	  };

	  if(!('URLSearchParams' in global) || (new URLSearchParams('?a=1').toString() !== 'a=1')) {
	    polyfillURLSearchParams();
	  }

	  // HTMLAnchorElement

	})(
	  (typeof commonjsGlobal !== 'undefined') ? commonjsGlobal
	    : ((typeof window !== 'undefined') ? window
	    : ((typeof self !== 'undefined') ? self : commonjsGlobal))
	);

	(function(global) {
	  /**
	   * Polyfill URL
	   *
	   * Inspired from : https://github.com/arv/DOM-URL-Polyfill/blob/master/src/url.js
	   */

	  var checkIfURLIsSupported = function() {
	    try {
	      var u = new URL('b', 'http://a');
	      u.pathname = 'c%20d';
	      return (u.href === 'http://a/c%20d') && u.searchParams;
	    } catch(e) {
	      return false;
	    }
	  };


	  var polyfillURL = function() {
	    var _URL = global.URL;

	    var URL = function(url, base) {
	      if(typeof url !== 'string') url = String(url);

	      var doc = document.implementation.createHTMLDocument('');
	      window.doc = doc;
	      if(base) {
	        var baseElement = doc.createElement('base');
	        baseElement.href = base;
	        doc.head.appendChild(baseElement);
	      }

	      var anchorElement = doc.createElement('a');
	      anchorElement.href = url;
	      doc.body.appendChild(anchorElement);
	      anchorElement.href = anchorElement.href; // force href to refresh

	      if(anchorElement.protocol === ':' || !/:/.test(anchorElement.href)) {
	        throw new TypeError('Invalid URL');
	      }

	      Object.defineProperty(this, '_anchorElement', {
	        value: anchorElement
	      });
	    };

	    var proto = URL.prototype;

	    var linkURLWithAnchorAttribute = function(attributeName) {
	      Object.defineProperty(proto, attributeName, {
	        get: function() {
	          return this._anchorElement[attributeName];
	        },
	        set: function(value) {
	          this._anchorElement[attributeName] = value;
	        },
	        enumerable: true
	      });
	    };

	    ['hash', 'host', 'hostname', 'port', 'protocol', 'search']
	    .forEach(function(attributeName) {
	      linkURLWithAnchorAttribute(attributeName);
	    });

	    Object.defineProperties(proto, {

	      'toString': {
	        get: function() {
	          var _this = this;
	          return function() {
	            return _this.href;
	          };
	        }
	      },

	      'href' : {
	        get: function() {
	          return this._anchorElement.href.replace(/\?$/,'');
	        },
	        set: function(value) {
	          this._anchorElement.href = value;
	        },
	        enumerable: true
	      },

	      'pathname' : {
	        get: function() {
	          return this._anchorElement.pathname.replace(/(^\/?)/,'/');
	        },
	        set: function(value) {
	          this._anchorElement.pathname = value;
	        },
	        enumerable: true
	      },

	      'origin': {
	        get: function() {
	          // get expected port from protocol
	          var expectedPort = {'http:': 80, 'https:': 443, 'ftp:': 21}[this._anchorElement.protocol];
	          // add port to origin if, expected port is different than actual port
	          // and it is not empty f.e http://foo:8080
	          // 8080 != 80 && 8080 != ''
	          var addPortToOrigin = this._anchorElement.port != expectedPort &&
	            this._anchorElement.port !== '';

	          return this._anchorElement.protocol +
	            '//' +
	            this._anchorElement.hostname +
	            (addPortToOrigin ? (':' + this._anchorElement.port) : '');
	        },
	        enumerable: true
	      },

	      'password': { // TODO
	        get: function() {
	          return '';
	        },
	        set: function(value) {
	        },
	        enumerable: true
	      },

	      'username': { // TODO
	        get: function() {
	          return '';
	        },
	        set: function(value) {
	        },
	        enumerable: true
	      },

	      'searchParams': {
	        get: function() {
	          var searchParams = new URLSearchParams(this.search);
	          var _this = this;
	          ['append', 'delete', 'set'].forEach(function(methodName) {
	            var method = searchParams[methodName];
	            searchParams[methodName] = function() {
	              method.apply(searchParams, arguments);
	              _this.search = searchParams.toString();
	            };
	          });
	          return searchParams;
	        },
	        enumerable: true
	      }
	    });

	    URL.createObjectURL = function(blob) {
	      return _URL.createObjectURL.apply(_URL, arguments);
	    };

	    URL.revokeObjectURL = function(url) {
	      return _URL.revokeObjectURL.apply(_URL, arguments);
	    };

	    global.URL = URL;

	  };

	  if(!checkIfURLIsSupported()) {
	    polyfillURL();
	  }

	  if((global.location !== void 0) && !('origin' in global.location)) {
	    var getOrigin = function() {
	      return global.location.protocol + '//' + global.location.hostname + (global.location.port ? (':' + global.location.port) : '');
	    };

	    try {
	      Object.defineProperty(global.location, 'origin', {
	        get: getOrigin,
	        enumerable: true
	      });
	    } catch(e) {
	      setInterval(function() {
	        global.location.origin = getOrigin();
	      }, 100);
	    }
	  }

	})(
	  (typeof commonjsGlobal !== 'undefined') ? commonjsGlobal
	    : ((typeof window !== 'undefined') ? window
	    : ((typeof self !== 'undefined') ? self : commonjsGlobal))
	);

	/*
	 * classList.js: Cross-browser full element.classList implementation.
	 * 1.1.20170427
	 *
	 * By Eli Grey, http://eligrey.com
	 * License: Dedicated to the public domain.
	 *   See https://github.com/eligrey/classList.js/blob/master/LICENSE.md
	 */

	/*global self, document, DOMException */

	/*! @source http://purl.eligrey.com/github/classList.js/blob/master/classList.js */

	if ("document" in window.self) {

	// Full polyfill for browsers with no classList support
	// Including IE < Edge missing SVGElement.classList
	if (!("classList" in document.createElement("_")) 
		|| document.createElementNS && !("classList" in document.createElementNS("http://www.w3.org/2000/svg","g"))) {

	(function (view) {

	if (!('Element' in view)) return;

	var
		  classListProp = "classList"
		, protoProp = "prototype"
		, elemCtrProto = view.Element[protoProp]
		, objCtr = Object
		, strTrim = String[protoProp].trim || function () {
			return this.replace(/^\s+|\s+$/g, "");
		}
		, arrIndexOf = Array[protoProp].indexOf || function (item) {
			var
				  i = 0
				, len = this.length
			;
			for (; i < len; i++) {
				if (i in this && this[i] === item) {
					return i;
				}
			}
			return -1;
		}
		// Vendors: please allow content code to instantiate DOMExceptions
		, DOMEx = function (type, message) {
			this.name = type;
			this.code = DOMException[type];
			this.message = message;
		}
		, checkTokenAndGetIndex = function (classList, token) {
			if (token === "") {
				throw new DOMEx(
					  "SYNTAX_ERR"
					, "An invalid or illegal string was specified"
				);
			}
			if (/\s/.test(token)) {
				throw new DOMEx(
					  "INVALID_CHARACTER_ERR"
					, "String contains an invalid character"
				);
			}
			return arrIndexOf.call(classList, token);
		}
		, ClassList = function (elem) {
			var
				  trimmedClasses = strTrim.call(elem.getAttribute("class") || "")
				, classes = trimmedClasses ? trimmedClasses.split(/\s+/) : []
				, i = 0
				, len = classes.length
			;
			for (; i < len; i++) {
				this.push(classes[i]);
			}
			this._updateClassName = function () {
				elem.setAttribute("class", this.toString());
			};
		}
		, classListProto = ClassList[protoProp] = []
		, classListGetter = function () {
			return new ClassList(this);
		}
	;
	// Most DOMException implementations don't allow calling DOMException's toString()
	// on non-DOMExceptions. Error's toString() is sufficient here.
	DOMEx[protoProp] = Error[protoProp];
	classListProto.item = function (i) {
		return this[i] || null;
	};
	classListProto.contains = function (token) {
		token += "";
		return checkTokenAndGetIndex(this, token) !== -1;
	};
	classListProto.add = function () {
		var
			  tokens = arguments
			, i = 0
			, l = tokens.length
			, token
			, updated = false
		;
		do {
			token = tokens[i] + "";
			if (checkTokenAndGetIndex(this, token) === -1) {
				this.push(token);
				updated = true;
			}
		}
		while (++i < l);

		if (updated) {
			this._updateClassName();
		}
	};
	classListProto.remove = function () {
		var
			  tokens = arguments
			, i = 0
			, l = tokens.length
			, token
			, updated = false
			, index
		;
		do {
			token = tokens[i] + "";
			index = checkTokenAndGetIndex(this, token);
			while (index !== -1) {
				this.splice(index, 1);
				updated = true;
				index = checkTokenAndGetIndex(this, token);
			}
		}
		while (++i < l);

		if (updated) {
			this._updateClassName();
		}
	};
	classListProto.toggle = function (token, force) {
		token += "";

		var
			  result = this.contains(token)
			, method = result ?
				force !== true && "remove"
			:
				force !== false && "add"
		;

		if (method) {
			this[method](token);
		}

		if (force === true || force === false) {
			return force;
		} else {
			return !result;
		}
	};
	classListProto.toString = function () {
		return this.join(" ");
	};

	if (objCtr.defineProperty) {
		var classListPropDesc = {
			  get: classListGetter
			, enumerable: true
			, configurable: true
		};
		try {
			objCtr.defineProperty(elemCtrProto, classListProp, classListPropDesc);
		} catch (ex) { // IE 8 doesn't support enumerable:true
			// adding undefined to fight this issue https://github.com/eligrey/classList.js/issues/36
			// modernie IE8-MSW7 machine has IE8 8.0.6001.18702 and is affected
			if (ex.number === undefined || ex.number === -0x7FF5EC54) {
				classListPropDesc.enumerable = false;
				objCtr.defineProperty(elemCtrProto, classListProp, classListPropDesc);
			}
		}
	} else if (objCtr[protoProp].__defineGetter__) {
		elemCtrProto.__defineGetter__(classListProp, classListGetter);
	}

	}(window.self));

	}

	// There is full or partial native classList support, so just check if we need
	// to normalize the add/remove and toggle APIs.

	(function () {

		var testElement = document.createElement("_");

		testElement.classList.add("c1", "c2");

		// Polyfill for IE 10/11 and Firefox <26, where classList.add and
		// classList.remove exist but support only one argument at a time.
		if (!testElement.classList.contains("c2")) {
			var createMethod = function(method) {
				var original = DOMTokenList.prototype[method];

				DOMTokenList.prototype[method] = function(token) {
					var i, len = arguments.length;

					for (i = 0; i < len; i++) {
						token = arguments[i];
						original.call(this, token);
					}
				};
			};
			createMethod('add');
			createMethod('remove');
		}

		testElement.classList.toggle("c3", false);

		// Polyfill for IE 10 and Firefox <24, where classList.toggle does not
		// support the second argument.
		if (testElement.classList.contains("c3")) {
			var _toggle = DOMTokenList.prototype.toggle;

			DOMTokenList.prototype.toggle = function(token, force) {
				if (1 in arguments && !this.contains(token) === !force) {
					return force;
				} else {
					return _toggle.call(this, token);
				}
			};

		}

		testElement = null;
	}());

	}

	/**
	 * Copyright 2016 Google Inc. All Rights Reserved.
	 *
	 * Licensed under the W3C SOFTWARE AND DOCUMENT NOTICE AND LICENSE.
	 *
	 *  https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
	 *
	 */

	(function(window, document) {


	// Exits early if all IntersectionObserver and IntersectionObserverEntry
	// features are natively supported.
	if ('IntersectionObserver' in window &&
	    'IntersectionObserverEntry' in window &&
	    'intersectionRatio' in window.IntersectionObserverEntry.prototype) {

	  // Minimal polyfill for Edge 15's lack of `isIntersecting`
	  // See: https://github.com/w3c/IntersectionObserver/issues/211
	  if (!('isIntersecting' in window.IntersectionObserverEntry.prototype)) {
	    Object.defineProperty(window.IntersectionObserverEntry.prototype,
	      'isIntersecting', {
	      get: function () {
	        return this.intersectionRatio > 0;
	      }
	    });
	  }
	  return;
	}


	/**
	 * Creates the global IntersectionObserverEntry constructor.
	 * https://w3c.github.io/IntersectionObserver/#intersection-observer-entry
	 * @param {Object} entry A dictionary of instance properties.
	 * @constructor
	 */
	function IntersectionObserverEntry(entry) {
	  this.time = entry.time;
	  this.target = entry.target;
	  this.rootBounds = entry.rootBounds;
	  this.boundingClientRect = entry.boundingClientRect;
	  this.intersectionRect = entry.intersectionRect || getEmptyRect();
	  this.isIntersecting = !!entry.intersectionRect;

	  // Calculates the intersection ratio.
	  var targetRect = this.boundingClientRect;
	  var targetArea = targetRect.width * targetRect.height;
	  var intersectionRect = this.intersectionRect;
	  var intersectionArea = intersectionRect.width * intersectionRect.height;

	  // Sets intersection ratio.
	  if (targetArea) {
	    // Round the intersection ratio to avoid floating point math issues:
	    // https://github.com/w3c/IntersectionObserver/issues/324
	    this.intersectionRatio = Number((intersectionArea / targetArea).toFixed(4));
	  } else {
	    // If area is zero and is intersecting, sets to 1, otherwise to 0
	    this.intersectionRatio = this.isIntersecting ? 1 : 0;
	  }
	}


	/**
	 * Creates the global IntersectionObserver constructor.
	 * https://w3c.github.io/IntersectionObserver/#intersection-observer-interface
	 * @param {Function} callback The function to be invoked after intersection
	 *     changes have queued. The function is not invoked if the queue has
	 *     been emptied by calling the `takeRecords` method.
	 * @param {Object=} opt_options Optional configuration options.
	 * @constructor
	 */
	function IntersectionObserver(callback, opt_options) {

	  var options = opt_options || {};

	  if (typeof callback != 'function') {
	    throw new Error('callback must be a function');
	  }

	  if (options.root && options.root.nodeType != 1) {
	    throw new Error('root must be an Element');
	  }

	  // Binds and throttles `this._checkForIntersections`.
	  this._checkForIntersections = throttle(
	      this._checkForIntersections.bind(this), this.THROTTLE_TIMEOUT);

	  // Private properties.
	  this._callback = callback;
	  this._observationTargets = [];
	  this._queuedEntries = [];
	  this._rootMarginValues = this._parseRootMargin(options.rootMargin);

	  // Public properties.
	  this.thresholds = this._initThresholds(options.threshold);
	  this.root = options.root || null;
	  this.rootMargin = this._rootMarginValues.map(function(margin) {
	    return margin.value + margin.unit;
	  }).join(' ');
	}


	/**
	 * The minimum interval within which the document will be checked for
	 * intersection changes.
	 */
	IntersectionObserver.prototype.THROTTLE_TIMEOUT = 100;


	/**
	 * The frequency in which the polyfill polls for intersection changes.
	 * this can be updated on a per instance basis and must be set prior to
	 * calling `observe` on the first target.
	 */
	IntersectionObserver.prototype.POLL_INTERVAL = null;

	/**
	 * Use a mutation observer on the root element
	 * to detect intersection changes.
	 */
	IntersectionObserver.prototype.USE_MUTATION_OBSERVER = true;


	/**
	 * Starts observing a target element for intersection changes based on
	 * the thresholds values.
	 * @param {Element} target The DOM element to observe.
	 */
	IntersectionObserver.prototype.observe = function(target) {
	  var isTargetAlreadyObserved = this._observationTargets.some(function(item) {
	    return item.element == target;
	  });

	  if (isTargetAlreadyObserved) {
	    return;
	  }

	  if (!(target && target.nodeType == 1)) {
	    throw new Error('target must be an Element');
	  }

	  this._registerInstance();
	  this._observationTargets.push({element: target, entry: null});
	  this._monitorIntersections();
	  this._checkForIntersections();
	};


	/**
	 * Stops observing a target element for intersection changes.
	 * @param {Element} target The DOM element to observe.
	 */
	IntersectionObserver.prototype.unobserve = function(target) {
	  this._observationTargets =
	      this._observationTargets.filter(function(item) {

	    return item.element != target;
	  });
	  if (!this._observationTargets.length) {
	    this._unmonitorIntersections();
	    this._unregisterInstance();
	  }
	};


	/**
	 * Stops observing all target elements for intersection changes.
	 */
	IntersectionObserver.prototype.disconnect = function() {
	  this._observationTargets = [];
	  this._unmonitorIntersections();
	  this._unregisterInstance();
	};


	/**
	 * Returns any queue entries that have not yet been reported to the
	 * callback and clears the queue. This can be used in conjunction with the
	 * callback to obtain the absolute most up-to-date intersection information.
	 * @return {Array} The currently queued entries.
	 */
	IntersectionObserver.prototype.takeRecords = function() {
	  var records = this._queuedEntries.slice();
	  this._queuedEntries = [];
	  return records;
	};


	/**
	 * Accepts the threshold value from the user configuration object and
	 * returns a sorted array of unique threshold values. If a value is not
	 * between 0 and 1 and error is thrown.
	 * @private
	 * @param {Array|number=} opt_threshold An optional threshold value or
	 *     a list of threshold values, defaulting to [0].
	 * @return {Array} A sorted list of unique and valid threshold values.
	 */
	IntersectionObserver.prototype._initThresholds = function(opt_threshold) {
	  var threshold = opt_threshold || [0];
	  if (!Array.isArray(threshold)) threshold = [threshold];

	  return threshold.sort().filter(function(t, i, a) {
	    if (typeof t != 'number' || isNaN(t) || t < 0 || t > 1) {
	      throw new Error('threshold must be a number between 0 and 1 inclusively');
	    }
	    return t !== a[i - 1];
	  });
	};


	/**
	 * Accepts the rootMargin value from the user configuration object
	 * and returns an array of the four margin values as an object containing
	 * the value and unit properties. If any of the values are not properly
	 * formatted or use a unit other than px or %, and error is thrown.
	 * @private
	 * @param {string=} opt_rootMargin An optional rootMargin value,
	 *     defaulting to '0px'.
	 * @return {Array<Object>} An array of margin objects with the keys
	 *     value and unit.
	 */
	IntersectionObserver.prototype._parseRootMargin = function(opt_rootMargin) {
	  var marginString = opt_rootMargin || '0px';
	  var margins = marginString.split(/\s+/).map(function(margin) {
	    var parts = /^(-?\d*\.?\d+)(px|%)$/.exec(margin);
	    if (!parts) {
	      throw new Error('rootMargin must be specified in pixels or percent');
	    }
	    return {value: parseFloat(parts[1]), unit: parts[2]};
	  });

	  // Handles shorthand.
	  margins[1] = margins[1] || margins[0];
	  margins[2] = margins[2] || margins[0];
	  margins[3] = margins[3] || margins[1];

	  return margins;
	};


	/**
	 * Starts polling for intersection changes if the polling is not already
	 * happening, and if the page's visibility state is visible.
	 * @private
	 */
	IntersectionObserver.prototype._monitorIntersections = function() {
	  if (!this._monitoringIntersections) {
	    this._monitoringIntersections = true;

	    // If a poll interval is set, use polling instead of listening to
	    // resize and scroll events or DOM mutations.
	    if (this.POLL_INTERVAL) {
	      this._monitoringInterval = setInterval(
	          this._checkForIntersections, this.POLL_INTERVAL);
	    }
	    else {
	      addEvent(window, 'resize', this._checkForIntersections, true);
	      addEvent(document, 'scroll', this._checkForIntersections, true);

	      if (this.USE_MUTATION_OBSERVER && 'MutationObserver' in window) {
	        this._domObserver = new MutationObserver(this._checkForIntersections);
	        this._domObserver.observe(document, {
	          attributes: true,
	          childList: true,
	          characterData: true,
	          subtree: true
	        });
	      }
	    }
	  }
	};


	/**
	 * Stops polling for intersection changes.
	 * @private
	 */
	IntersectionObserver.prototype._unmonitorIntersections = function() {
	  if (this._monitoringIntersections) {
	    this._monitoringIntersections = false;

	    clearInterval(this._monitoringInterval);
	    this._monitoringInterval = null;

	    removeEvent(window, 'resize', this._checkForIntersections, true);
	    removeEvent(document, 'scroll', this._checkForIntersections, true);

	    if (this._domObserver) {
	      this._domObserver.disconnect();
	      this._domObserver = null;
	    }
	  }
	};


	/**
	 * Scans each observation target for intersection changes and adds them
	 * to the internal entries queue. If new entries are found, it
	 * schedules the callback to be invoked.
	 * @private
	 */
	IntersectionObserver.prototype._checkForIntersections = function() {
	  var rootIsInDom = this._rootIsInDom();
	  var rootRect = rootIsInDom ? this._getRootRect() : getEmptyRect();

	  this._observationTargets.forEach(function(item) {
	    var target = item.element;
	    var targetRect = getBoundingClientRect(target);
	    var rootContainsTarget = this._rootContainsTarget(target);
	    var oldEntry = item.entry;
	    var intersectionRect = rootIsInDom && rootContainsTarget &&
	        this._computeTargetAndRootIntersection(target, rootRect);

	    var newEntry = item.entry = new IntersectionObserverEntry({
	      time: now(),
	      target: target,
	      boundingClientRect: targetRect,
	      rootBounds: rootRect,
	      intersectionRect: intersectionRect
	    });

	    if (!oldEntry) {
	      this._queuedEntries.push(newEntry);
	    } else if (rootIsInDom && rootContainsTarget) {
	      // If the new entry intersection ratio has crossed any of the
	      // thresholds, add a new entry.
	      if (this._hasCrossedThreshold(oldEntry, newEntry)) {
	        this._queuedEntries.push(newEntry);
	      }
	    } else {
	      // If the root is not in the DOM or target is not contained within
	      // root but the previous entry for this target had an intersection,
	      // add a new record indicating removal.
	      if (oldEntry && oldEntry.isIntersecting) {
	        this._queuedEntries.push(newEntry);
	      }
	    }
	  }, this);

	  if (this._queuedEntries.length) {
	    this._callback(this.takeRecords(), this);
	  }
	};


	/**
	 * Accepts a target and root rect computes the intersection between then
	 * following the algorithm in the spec.
	 * TODO(philipwalton): at this time clip-path is not considered.
	 * https://w3c.github.io/IntersectionObserver/#calculate-intersection-rect-algo
	 * @param {Element} target The target DOM element
	 * @param {Object} rootRect The bounding rect of the root after being
	 *     expanded by the rootMargin value.
	 * @return {?Object} The final intersection rect object or undefined if no
	 *     intersection is found.
	 * @private
	 */
	IntersectionObserver.prototype._computeTargetAndRootIntersection =
	    function(target, rootRect) {

	  // If the element isn't displayed, an intersection can't happen.
	  if (window.getComputedStyle(target).display == 'none') return;

	  var targetRect = getBoundingClientRect(target);
	  var intersectionRect = targetRect;
	  var parent = getParentNode(target);
	  var atRoot = false;

	  while (!atRoot) {
	    var parentRect = null;
	    var parentComputedStyle = parent.nodeType == 1 ?
	        window.getComputedStyle(parent) : {};

	    // If the parent isn't displayed, an intersection can't happen.
	    if (parentComputedStyle.display == 'none') return;

	    if (parent == this.root || parent == document) {
	      atRoot = true;
	      parentRect = rootRect;
	    } else {
	      // If the element has a non-visible overflow, and it's not the <body>
	      // or <html> element, update the intersection rect.
	      // Note: <body> and <html> cannot be clipped to a rect that's not also
	      // the document rect, so no need to compute a new intersection.
	      if (parent != document.body &&
	          parent != document.documentElement &&
	          parentComputedStyle.overflow != 'visible') {
	        parentRect = getBoundingClientRect(parent);
	      }
	    }

	    // If either of the above conditionals set a new parentRect,
	    // calculate new intersection data.
	    if (parentRect) {
	      intersectionRect = computeRectIntersection(parentRect, intersectionRect);

	      if (!intersectionRect) break;
	    }
	    parent = getParentNode(parent);
	  }
	  return intersectionRect;
	};


	/**
	 * Returns the root rect after being expanded by the rootMargin value.
	 * @return {Object} The expanded root rect.
	 * @private
	 */
	IntersectionObserver.prototype._getRootRect = function() {
	  var rootRect;
	  if (this.root) {
	    rootRect = getBoundingClientRect(this.root);
	  } else {
	    // Use <html>/<body> instead of window since scroll bars affect size.
	    var html = document.documentElement;
	    var body = document.body;
	    rootRect = {
	      top: 0,
	      left: 0,
	      right: html.clientWidth || body.clientWidth,
	      width: html.clientWidth || body.clientWidth,
	      bottom: html.clientHeight || body.clientHeight,
	      height: html.clientHeight || body.clientHeight
	    };
	  }
	  return this._expandRectByRootMargin(rootRect);
	};


	/**
	 * Accepts a rect and expands it by the rootMargin value.
	 * @param {Object} rect The rect object to expand.
	 * @return {Object} The expanded rect.
	 * @private
	 */
	IntersectionObserver.prototype._expandRectByRootMargin = function(rect) {
	  var margins = this._rootMarginValues.map(function(margin, i) {
	    return margin.unit == 'px' ? margin.value :
	        margin.value * (i % 2 ? rect.width : rect.height) / 100;
	  });
	  var newRect = {
	    top: rect.top - margins[0],
	    right: rect.right + margins[1],
	    bottom: rect.bottom + margins[2],
	    left: rect.left - margins[3]
	  };
	  newRect.width = newRect.right - newRect.left;
	  newRect.height = newRect.bottom - newRect.top;

	  return newRect;
	};


	/**
	 * Accepts an old and new entry and returns true if at least one of the
	 * threshold values has been crossed.
	 * @param {?IntersectionObserverEntry} oldEntry The previous entry for a
	 *    particular target element or null if no previous entry exists.
	 * @param {IntersectionObserverEntry} newEntry The current entry for a
	 *    particular target element.
	 * @return {boolean} Returns true if a any threshold has been crossed.
	 * @private
	 */
	IntersectionObserver.prototype._hasCrossedThreshold =
	    function(oldEntry, newEntry) {

	  // To make comparing easier, an entry that has a ratio of 0
	  // but does not actually intersect is given a value of -1
	  var oldRatio = oldEntry && oldEntry.isIntersecting ?
	      oldEntry.intersectionRatio || 0 : -1;
	  var newRatio = newEntry.isIntersecting ?
	      newEntry.intersectionRatio || 0 : -1;

	  // Ignore unchanged ratios
	  if (oldRatio === newRatio) return;

	  for (var i = 0; i < this.thresholds.length; i++) {
	    var threshold = this.thresholds[i];

	    // Return true if an entry matches a threshold or if the new ratio
	    // and the old ratio are on the opposite sides of a threshold.
	    if (threshold == oldRatio || threshold == newRatio ||
	        threshold < oldRatio !== threshold < newRatio) {
	      return true;
	    }
	  }
	};


	/**
	 * Returns whether or not the root element is an element and is in the DOM.
	 * @return {boolean} True if the root element is an element and is in the DOM.
	 * @private
	 */
	IntersectionObserver.prototype._rootIsInDom = function() {
	  return !this.root || containsDeep(document, this.root);
	};


	/**
	 * Returns whether or not the target element is a child of root.
	 * @param {Element} target The target element to check.
	 * @return {boolean} True if the target element is a child of root.
	 * @private
	 */
	IntersectionObserver.prototype._rootContainsTarget = function(target) {
	  return containsDeep(this.root || document, target);
	};


	/**
	 * Adds the instance to the global IntersectionObserver registry if it isn't
	 * already present.
	 * @private
	 */
	IntersectionObserver.prototype._registerInstance = function() {
	};


	/**
	 * Removes the instance from the global IntersectionObserver registry.
	 * @private
	 */
	IntersectionObserver.prototype._unregisterInstance = function() {
	};


	/**
	 * Returns the result of the performance.now() method or null in browsers
	 * that don't support the API.
	 * @return {number} The elapsed time since the page was requested.
	 */
	function now() {
	  return window.performance && performance.now && performance.now();
	}


	/**
	 * Throttles a function and delays its execution, so it's only called at most
	 * once within a given time period.
	 * @param {Function} fn The function to throttle.
	 * @param {number} timeout The amount of time that must pass before the
	 *     function can be called again.
	 * @return {Function} The throttled function.
	 */
	function throttle(fn, timeout) {
	  var timer = null;
	  return function () {
	    if (!timer) {
	      timer = setTimeout(function() {
	        fn();
	        timer = null;
	      }, timeout);
	    }
	  };
	}


	/**
	 * Adds an event handler to a DOM node ensuring cross-browser compatibility.
	 * @param {Node} node The DOM node to add the event handler to.
	 * @param {string} event The event name.
	 * @param {Function} fn The event handler to add.
	 * @param {boolean} opt_useCapture Optionally adds the even to the capture
	 *     phase. Note: this only works in modern browsers.
	 */
	function addEvent(node, event, fn, opt_useCapture) {
	  if (typeof node.addEventListener == 'function') {
	    node.addEventListener(event, fn, opt_useCapture || false);
	  }
	  else if (typeof node.attachEvent == 'function') {
	    node.attachEvent('on' + event, fn);
	  }
	}


	/**
	 * Removes a previously added event handler from a DOM node.
	 * @param {Node} node The DOM node to remove the event handler from.
	 * @param {string} event The event name.
	 * @param {Function} fn The event handler to remove.
	 * @param {boolean} opt_useCapture If the event handler was added with this
	 *     flag set to true, it should be set to true here in order to remove it.
	 */
	function removeEvent(node, event, fn, opt_useCapture) {
	  if (typeof node.removeEventListener == 'function') {
	    node.removeEventListener(event, fn, opt_useCapture || false);
	  }
	  else if (typeof node.detatchEvent == 'function') {
	    node.detatchEvent('on' + event, fn);
	  }
	}


	/**
	 * Returns the intersection between two rect objects.
	 * @param {Object} rect1 The first rect.
	 * @param {Object} rect2 The second rect.
	 * @return {?Object} The intersection rect or undefined if no intersection
	 *     is found.
	 */
	function computeRectIntersection(rect1, rect2) {
	  var top = Math.max(rect1.top, rect2.top);
	  var bottom = Math.min(rect1.bottom, rect2.bottom);
	  var left = Math.max(rect1.left, rect2.left);
	  var right = Math.min(rect1.right, rect2.right);
	  var width = right - left;
	  var height = bottom - top;

	  return (width >= 0 && height >= 0) && {
	    top: top,
	    bottom: bottom,
	    left: left,
	    right: right,
	    width: width,
	    height: height
	  };
	}


	/**
	 * Shims the native getBoundingClientRect for compatibility with older IE.
	 * @param {Element} el The element whose bounding rect to get.
	 * @return {Object} The (possibly shimmed) rect of the element.
	 */
	function getBoundingClientRect(el) {
	  var rect;

	  try {
	    rect = el.getBoundingClientRect();
	  } catch (err) {
	    // Ignore Windows 7 IE11 "Unspecified error"
	    // https://github.com/w3c/IntersectionObserver/pull/205
	  }

	  if (!rect) return getEmptyRect();

	  // Older IE
	  if (!(rect.width && rect.height)) {
	    rect = {
	      top: rect.top,
	      right: rect.right,
	      bottom: rect.bottom,
	      left: rect.left,
	      width: rect.right - rect.left,
	      height: rect.bottom - rect.top
	    };
	  }
	  return rect;
	}


	/**
	 * Returns an empty rect object. An empty rect is returned when an element
	 * is not in the DOM.
	 * @return {Object} The empty rect.
	 */
	function getEmptyRect() {
	  return {
	    top: 0,
	    bottom: 0,
	    left: 0,
	    right: 0,
	    width: 0,
	    height: 0
	  };
	}

	/**
	 * Checks to see if a parent element contains a child element (including inside
	 * shadow DOM).
	 * @param {Node} parent The parent element.
	 * @param {Node} child The child element.
	 * @return {boolean} True if the parent node contains the child node.
	 */
	function containsDeep(parent, child) {
	  var node = child;
	  while (node) {
	    if (node == parent) return true;

	    node = getParentNode(node);
	  }
	  return false;
	}


	/**
	 * Gets the parent node of an element or its host element if the parent node
	 * is a shadow root.
	 * @param {Node} node The node whose parent to get.
	 * @return {Node|null} The parent node or null if no parent exists.
	 */
	function getParentNode(node) {
	  var parent = node.parentNode;

	  if (parent && parent.nodeType == 11 && parent.host) {
	    // If the parent is a shadow root, return the host element.
	    return parent.host;
	  }
	  return parent;
	}


	// Exposes the constructors globally.
	window.IntersectionObserver = IntersectionObserver;
	window.IntersectionObserverEntry = IntersectionObserverEntry;

	}(window, document));

	var version = "1.0.0";

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
	var create = Object.create || function () {
	    function F() {}
	    return function (proto) {
	        F.prototype = proto;
	        return new F();
	    };
	}();

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

	    later = function later() {
	        // reset lock and call if queued
	        lock = false;
	        if (args) {
	            wrapperFn.apply(context, args);
	            args = false;
	        }
	    };

	    wrapperFn = function wrapperFn() {
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
	function falseFn() {
	    return false;
	}

	// @function formatNum(num: Number, digits?: Number): Number
	// Returns the number `num` rounded to `digits` decimals, or to 5 decimals by default.
	function formatNum(num, digits) {
	    var pow = Math.pow(10, digits || 5);
	    return Math.round(num * pow) / pow;
	}

	// @function isNumeric(num: Number): Boolean
	// Returns whether num is actually numeric
	function isNumeric(num) {
	    return !isNaN(parseFloat(num)) && isFinite(num);
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
	    return (!existingUrl || existingUrl.indexOf('?') === -1 ? '?' : '&') + params.join('&');
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
	    return Object.prototype.toString.call(obj) === '[object Array]';
	};

	// @function indexOf(array: Array, el: Object): Number
	// Compatibility polyfill for [Array.prototype.indexOf](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf)
	function indexOf(array, el) {
	    for (var i = 0; i < array.length; i++) {
	        if (array[i] === el) {
	            return i;
	        }
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
	var cancelFn = window.cancelAnimationFrame || getPrefixed('CancelAnimationFrame') || getPrefixed('CancelRequestAnimationFrame') || function (id) {
	    window.clearTimeout(id);
	};

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

	function inVp(elem) {
	    var threshold = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
	    var container = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;


	    if (threshold instanceof HTMLElement) {
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
	    var vp = {
	        width: container.clientWidth,
	        height: container.clientHeight
	    };

	    // Get the viewport offset and size of the element.
	    // Normailze right and bottom to show offset from their
	    // respective edges istead of the top-left edges.
	    var box = elem.getBoundingClientRect();
	    var top = box.top,
	        left = box.left,
	        width = box.width,
	        height = box.height;

	    var right = vp.width - box.right;
	    var bottom = vp.height - box.bottom;

	    // Calculate which sides of the element are cut-off
	    // by the viewport.
	    var cutOff = {
	        top: top < threshold.top,
	        left: left < threshold.left,
	        bottom: bottom < threshold.bottom,
	        right: right < threshold.right
	    };

	    // Calculate which sides of the element are partially shown
	    var partial = {
	        top: cutOff.top && top > -height + threshold.top,
	        left: cutOff.left && left > -width + threshold.left,
	        bottom: cutOff.bottom && bottom > -height + threshold.bottom,
	        right: cutOff.right && right > -width + threshold.right
	    };

	    var isFullyVisible = top >= threshold.top && right >= threshold.right && bottom >= threshold.bottom && left >= threshold.left;

	    var isPartiallyVisible = partial.top || partial.right || partial.bottom || partial.left;

	    var elH = elem.offsetHeight;
	    var H = container.offsetHeight;
	    var percentage = Math.max(0, top > 0 ? Math.min(elH, H - top) : box.bottom < H ? box.bottom : H);

	    // Calculate which edge of the element are visible.
	    // Every edge can have three states:
	    // - 'fully':     The edge is completely visible.
	    // - 'partially': Some part of the edge can be seen.
	    // - false:       The edge is not visible at all.
	    var edges = {
	        top: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.top && !cutOff.left && !cutOff.right && 'fully' || !cutOff.top && 'partially' || false,
	        right: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.right && !cutOff.top && !cutOff.bottom && 'fully' || !cutOff.right && 'partially' || false,
	        bottom: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.bottom && !cutOff.left && !cutOff.right && 'fully' || !cutOff.bottom && 'partially' || false,
	        left: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.left && !cutOff.top && !cutOff.bottom && 'fully' || !cutOff.left && 'partially' || false,
	        percentage: percentage
	    };

	    return {
	        fully: isFullyVisible,
	        partially: isPartiallyVisible,
	        edges: edges
	    };
	}

	var loader = {
	    js: function js(url) {
	        var handler = { _resolved: false };
	        handler.callbacks = [];
	        handler.error = [];
	        handler.then = function (cb) {
	            handler.callbacks.push(cb);
	            if (handler._resolved) {
	                return handler.resolve();
	            }
	            return handler;
	        };
	        handler.catch = function (cb) {
	            handler.error.push(cb);
	            if (handler._resolved) {
	                return handler.reject();
	            }
	            return handler;
	        };
	        handler.resolve = function (_argv) {
	            // var _argv;
	            handler._resolved = true;
	            while (handler.callbacks.length) {
	                var cb = handler.callbacks.shift();
	                try {
	                    _argv = cb(_argv);
	                } catch (e) {
	                    console.log(e);
	                    handler.reject(e);
	                    break;
	                }
	            }
	            return handler;
	        };

	        handler.reject = function (e) {
	            while (handler.error.length) {
	                var cb = handler.error.shift();
	                cb(e);
	            }
	            console.log(e);
	            console.trace();
	            return handler;
	        };

	        if (url == undefined) {
	            handler._resolved = true;
	            return handler;
	        }

	        var element = document.createElement('script');

	        element.onload = function () {
	            handler.resolve(url);
	        };
	        element.onerror = function () {
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
	};

	var Util = /*#__PURE__*/Object.freeze({
		extend: extend,
		create: create,
		bind: bind,
		get lastId () { return lastId; },
		stamp: stamp,
		throttle: throttle,
		wrapNum: wrapNum,
		falseFn: falseFn,
		formatNum: formatNum,
		isNumeric: isNumeric,
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
		cancelAnimFrame: cancelAnimFrame,
		inVp: inVp,
		loader: loader
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
		var NewClass = function NewClass() {

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

			if (this._initHooksCalled) {
				return;
			}

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
	Class.addInitHook = function (fn) {
		// (Function) || (String, args...)
		var args = Array.prototype.slice.call(arguments, 1);

		var init = typeof fn === 'function' ? fn : function () {
			this[fn].apply(this, args);
		};

		this.prototype._initHooks = this.prototype._initHooks || [];
		this.prototype._initHooks.push(init);
		return this;
	};

	function checkDeprecatedMixinEvents(includes) {
		if (!cozy || !cozy.Mixin) {
			return;
		}

		includes = cozy.Util.isArray(includes) ? includes : [includes];

		// for (var i = 0; i < includes.length; i++) {
		// 	if (includes[i] === cozy.Mixin.Events) {
		// 		console.warn('Deprecated include of cozy.Mixin.Events: ' +
		// 			'this property will be removed in future releases, ' +
		// 			'please inherit from cozy.Evented instead.', new Error().stack);
		// 	}
		// }
	}

	var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

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
		on: function on(types, fn, context) {

			// types can be a map of types/handlers
			if ((typeof types === 'undefined' ? 'undefined' : _typeof(types)) === 'object') {
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
		off: function off(types, fn, context) {

			if (!types) {
				// clear all listeners if called without arguments
				delete this._events;
			} else if ((typeof types === 'undefined' ? 'undefined' : _typeof(types)) === 'object') {
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
		_on: function _on(type, fn, context) {
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
			var newListener = { fn: fn, ctx: context },
			    listeners = typeListeners;

			// check if fn already there
			for (var i = 0, len = listeners.length; i < len; i++) {
				if (listeners[i].fn === fn && listeners[i].ctx === context) {
					return;
				}
			}

			listeners.push(newListener);
		},

		_off: function _off(type, fn, context) {
			var listeners, i, len;

			if (!this._events) {
				return;
			}

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
					if (l.ctx !== context) {
						continue;
					}
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
		fire: function fire(type, data, propagate) {
			if (!this.listens(type, propagate)) {
				return this;
			}

			var event = extend({}, data, { type: type, target: this });

			if (this._events) {
				var listeners = this._events[type];

				if (listeners) {
					this._firingCount = this._firingCount + 1 || 1;
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
		listens: function listens(type, propagate) {
			var listeners = this._events && this._events[type];
			if (listeners && listeners.length) {
				return true;
			}

			if (propagate) {
				// also check parents for listeners if event propagates
				for (var id in this._eventParents) {
					if (this._eventParents[id].listens(type, propagate)) {
						return true;
					}
				}
			}
			return false;
		},

		// @method once(…): this
		// Behaves as [`on(…)`](#evented-on), except the listener will only get fired once and then removed.
		once: function once(types, fn, context) {

			if ((typeof types === 'undefined' ? 'undefined' : _typeof(types)) === 'object') {
				for (var type in types) {
					this.once(type, types[type], fn);
				}
				return this;
			}

			var handler = bind(function () {
				this.off(types, fn, context).off(types, handler, context);
			}, this);

			// add a listener that's executed once and removed after that
			return this.on(types, fn, context).on(types, handler, context);
		},

		// @method addEventParent(obj: Evented): this
		// Adds an event parent - an `Evented` that will receive propagated events
		addEventParent: function addEventParent(obj) {
			this._eventParents = this._eventParents || {};
			this._eventParents[stamp(obj)] = obj;
			return this;
		},

		// @method removeEventParent(obj: Evented): this
		// Removes an event parent, so it will stop receiving propagated events
		removeEventParent: function removeEventParent(obj) {
			if (this._eventParents) {
				delete this._eventParents[stamp(obj)];
			}
			return this;
		},

		_propagateEvent: function _propagateEvent(e) {
			for (var id in this._eventParents) {
				this._eventParents[id].fire(e.type, extend({ layer: e.target }, e), true);
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

	var _typeof$1 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

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
	var ie3d = ie && 'transition' in style$1;

	// @property webkit3d: Boolean; `true` for webkit-based browsers supporting CSS transforms.
	var webkit3d = 'WebKitCSSMatrix' in window && 'm11' in new window.WebKitCSSMatrix() && !android23;

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
	var touch = !window.L_NO_TOUCH && (pointer || 'ontouchstart' in window || window.DocumentTouch && document instanceof window.DocumentTouch);

	// @property mobileOpera: Boolean; `true` for the Opera browser in a mobile device.
	var mobileOpera = mobile && opera;

	// @property mobileGecko: Boolean
	// `true` for gecko-based browsers running in a mobile device.
	var mobileGecko = mobile && gecko;

	// @property retina: Boolean
	// `true` for browsers on a high-resolution "retina" screen.
	var retina = (window.devicePixelRatio || window.screen.deviceXDPI / window.screen.logicalXDPI) > 1;

	// @property canvas: Boolean
	// `true` when the browser supports [`<canvas>`](https://developer.mozilla.org/docs/Web/API/Canvas_API).
	var canvas = function () {
	    return !!document.createElement('canvas').getContext;
	}();

	// @property svg: Boolean
	// `true` when the browser supports [SVG](https://developer.mozilla.org/docs/Web/SVG).
	// export var svg = !!(document.createElementNS && svgCreate('svg').createSVGRect);
	var svg = true;

	// @property vml: Boolean
	// `true` if the browser supports [VML](https://en.wikipedia.org/wiki/Vector_Markup_Language).
	var vml = !svg && function () {
	    try {
	        var div = document.createElement('div');
	        div.innerHTML = '<v:shape adj="1"/>';

	        var shape = div.firstChild;
	        shape.style.behavior = 'url(#default#VML)';

	        return shape && _typeof$1(shape.adj) === 'object';
	    } catch (e) {
	        return false;
	    }
	}();

	var columnCount = 'columnCount' in style$1;
	var classList = document.documentElement.classList !== undefined;

	function userAgentContains(str) {
	    return navigator.userAgent.toLowerCase().indexOf(str) >= 0;
	}

	var Browser = /*#__PURE__*/Object.freeze({
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
		vml: vml,
		columnCount: columnCount,
		classList: classList
	});

	var _typeof$2 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

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
		this.x = round ? Math.round(x) : x;
		// @property y: Number; The `y` coordinate of the point
		this.y = round ? Math.round(y) : y;
	}

	Point.prototype = {

		// @method clone(): Point
		// Returns a copy of the current point.
		clone: function clone() {
			return new Point(this.x, this.y);
		},

		// @method add(otherPoint: Point): Point
		// Returns the result of addition of the current and the given points.
		add: function add(point) {
			// non-destructive, returns a new point
			return this.clone()._add(toPoint(point));
		},

		_add: function _add(point) {
			// destructive, used directly for performance in situations where it's safe to modify existing point
			this.x += point.x;
			this.y += point.y;
			return this;
		},

		// @method subtract(otherPoint: Point): Point
		// Returns the result of subtraction of the given point from the current.
		subtract: function subtract(point) {
			return this.clone()._subtract(toPoint(point));
		},

		_subtract: function _subtract(point) {
			this.x -= point.x;
			this.y -= point.y;
			return this;
		},

		// @method divideBy(num: Number): Point
		// Returns the result of division of the current point by the given number.
		divideBy: function divideBy(num) {
			return this.clone()._divideBy(num);
		},

		_divideBy: function _divideBy(num) {
			this.x /= num;
			this.y /= num;
			return this;
		},

		// @method multiplyBy(num: Number): Point
		// Returns the result of multiplication of the current point by the given number.
		multiplyBy: function multiplyBy(num) {
			return this.clone()._multiplyBy(num);
		},

		_multiplyBy: function _multiplyBy(num) {
			this.x *= num;
			this.y *= num;
			return this;
		},

		// @method scaleBy(scale: Point): Point
		// Multiply each coordinate of the current point by each coordinate of
		// `scale`. In linear algebra terms, multiply the point by the
		// [scaling matrix](https://en.wikipedia.org/wiki/Scaling_%28geometry%29#Matrix_representation)
		// defined by `scale`.
		scaleBy: function scaleBy(point) {
			return new Point(this.x * point.x, this.y * point.y);
		},

		// @method unscaleBy(scale: Point): Point
		// Inverse of `scaleBy`. Divide each coordinate of the current point by
		// each coordinate of `scale`.
		unscaleBy: function unscaleBy(point) {
			return new Point(this.x / point.x, this.y / point.y);
		},

		// @method round(): Point
		// Returns a copy of the current point with rounded coordinates.
		round: function round() {
			return this.clone()._round();
		},

		_round: function _round() {
			this.x = Math.round(this.x);
			this.y = Math.round(this.y);
			return this;
		},

		// @method floor(): Point
		// Returns a copy of the current point with floored coordinates (rounded down).
		floor: function floor() {
			return this.clone()._floor();
		},

		_floor: function _floor() {
			this.x = Math.floor(this.x);
			this.y = Math.floor(this.y);
			return this;
		},

		// @method ceil(): Point
		// Returns a copy of the current point with ceiled coordinates (rounded up).
		ceil: function ceil() {
			return this.clone()._ceil();
		},

		_ceil: function _ceil() {
			this.x = Math.ceil(this.x);
			this.y = Math.ceil(this.y);
			return this;
		},

		// @method distanceTo(otherPoint: Point): Number
		// Returns the cartesian distance between the current and the given points.
		distanceTo: function distanceTo(point) {
			point = toPoint(point);

			var x = point.x - this.x,
			    y = point.y - this.y;

			return Math.sqrt(x * x + y * y);
		},

		// @method equals(otherPoint: Point): Boolean
		// Returns `true` if the given point has the same coordinates.
		equals: function equals(point) {
			point = toPoint(point);

			return point.x === this.x && point.y === this.y;
		},

		// @method contains(otherPoint: Point): Boolean
		// Returns `true` if both coordinates of the given point are less than the corresponding current point coordinates (in absolute values).
		contains: function contains(point) {
			point = toPoint(point);

			return Math.abs(point.x) <= Math.abs(this.x) && Math.abs(point.y) <= Math.abs(this.y);
		},

		// @method toString(): String
		// Returns a string representation of the point for debugging purposes.
		toString: function toString() {
			return 'Point(' + formatNum(this.x) + ', ' + formatNum(this.y) + ')';
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
		if ((typeof x === 'undefined' ? 'undefined' : _typeof$2(x)) === 'object' && 'x' in x && 'y' in x) {
			return new Point(x.x, x.y);
		}
		return new Point(x, y, round);
	}

	/*
	 * Extends L.DomEvent to provide touch support for Internet Explorer and Windows-based devices.
	 */

	var POINTER_DOWN = msPointer ? 'MSPointerDown' : 'pointerdown',
	    POINTER_MOVE = msPointer ? 'MSPointerMove' : 'pointermove',
	    POINTER_UP = msPointer ? 'MSPointerUp' : 'pointerup',
	    POINTER_CANCEL = msPointer ? 'MSPointerCancel' : 'pointercancel',
	    TAG_WHITE_LIST = ['INPUT', 'SELECT', 'OPTION'],
	    _pointers = {},
	    _pointerDocListener = false;

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
		var onMove = function onMove(e) {
			// don't fire touch moves when mouse isn't down
			if ((e.pointerType === e.MSPOINTER_TYPE_MOUSE || e.pointerType === 'mouse') && e.buttons === 0) {
				return;
			}

			_handlePointer(e, handler);
		};

		obj['_leaflet_touchmove' + id] = onMove;
		obj.addEventListener(POINTER_MOVE, onMove, false);
	}

	function _addPointerEnd(obj, handler, id) {
		var onUp = function onUp(e) {
			_handlePointer(e, handler);
		};

		obj['_leaflet_touchend' + id] = onUp;
		obj.addEventListener(POINTER_UP, onUp, false);
		obj.addEventListener(POINTER_CANCEL, onUp, false);
	}

	/*
	 * Extends the event handling code with double tap support for mobile browsers.
	 */

	var _touchstart = msPointer ? 'MSPointerDown' : pointer ? 'pointerdown' : 'touchstart',
	    _touchend = msPointer ? 'MSPointerUp' : pointer ? 'pointerup' : 'touchend',
	    _pre = '_leaflet_';

	// inspired by Zepto touch code by Thomas Fuchs
	function addDoubleTapListener(obj, handler, id) {
		var last,
		    touch$$1,
		    doubleTap = false,
		    delay = 250;

		function onTouchStart(e) {
			var count;

			if (pointer) {
				if (!edge || e.pointerType === 'mouse') {
					return;
				}
				count = _pointersCount;
			} else {
				count = e.touches.length;
			}

			if (count > 1) {
				return;
			}

			var now = Date.now(),
			    delta = now - (last || now);

			touch$$1 = e.touches ? e.touches[0] : e;
			doubleTap = delta > 0 && delta <= delay;
			last = now;
		}

		function onTouchEnd(e) {
			if (doubleTap && !touch$$1.cancelBubble) {
				if (pointer) {
					if (!edge || e.pointerType === 'mouse') {
						return;
					}
					// work around .type being readonly with MSPointer* events
					var newTouch = {},
					    prop,
					    i;

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

	var _typeof$3 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

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

		if ((typeof types === 'undefined' ? 'undefined' : _typeof$3(types)) === 'object') {
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

		if ((typeof types === 'undefined' ? 'undefined' : _typeof$3(types)) === 'object') {
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

		if (obj[eventsKey] && obj[eventsKey][id]) {
			return this;
		}

		var handler = function handler(e) {
			return fn.call(context || obj, e || window.event);
		};

		var originalHandler = handler;

		if (pointer && type.indexOf('touch') === 0) {
			// Needs DomEvent.Pointer.js
			addPointerListener(obj, type, handler, id);
		} else if (touch && type === 'dblclick' && addDoubleTapListener && !(pointer && chrome)) {
			// Chrome >55 does not need the synthetic dblclicks from addDoubleTapListener
			// See #5180
			addDoubleTapListener(obj, handler, id);
		} else if ('addEventListener' in obj) {

			if (type === 'mousewheel') {
				obj.addEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);
			} else if (type === 'mouseenter' || type === 'mouseleave') {
				handler = function handler(e) {
					e = e || window.event;
					if (isExternalTarget(obj, e)) {
						originalHandler(e);
					}
				};
				obj.addEventListener(type === 'mouseenter' ? 'mouseover' : 'mouseout', handler, false);
			} else {
				if (type === 'click' && android) {
					handler = function handler(e) {
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

		if (!handler) {
			return this;
		}

		if (pointer && type.indexOf('touch') === 0) {
			removePointerListener(obj, type, id);
		} else if (touch && type === 'dblclick' && removeDoubleTapListener) {
			removeDoubleTapListener(obj, id);
		} else if ('removeEventListener' in obj) {

			if (type === 'mousewheel') {
				obj.removeEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);
			} else {
				obj.removeEventListener(type === 'mouseenter' ? 'mouseover' : type === 'mouseleave' ? 'mouseout' : type, handler, false);
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
		} else if (e.originalEvent) {
			// In case of Leaflet event.
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

		return new Point(e.clientX - rect.left - container.clientLeft, e.clientY - rect.top - container.clientTop);
	}

	// Chrome on Win scrolls double the pixels as in other platforms (see #4538),
	// and Firefox scrolls device pixels, not CSS pixels
	var wheelPxFactor = win && chrome ? 2 : gecko ? window.devicePixelRatio : 1;

	// @function getWheelDelta(ev: DOMEvent): Number
	// Gets normalized wheel delta from a mousewheel DOM event, in vertical
	// pixels scrolled (negative if scrolling down).
	// Events from pointing devices without precise scrolling are mapped to
	// a best guess of 60 pixels.
	function getWheelDelta(e) {
		return edge ? e.wheelDeltaY / 2 : // Don't trust window-geometry-based delta
		e.deltaY && e.deltaMode === 0 ? -e.deltaY / wheelPxFactor : // Pixels
		e.deltaY && e.deltaMode === 1 ? -e.deltaY * 20 : // Lines
		e.deltaY && e.deltaMode === 2 ? -e.deltaY * 60 : // Pages
		e.deltaX || e.deltaZ ? 0 : // Skip horizontal/depth wheel events
		e.wheelDelta ? (e.wheelDeltaY || e.wheelDelta) / 2 : // Legacy IE pixels
		e.detail && Math.abs(e.detail) < 32765 ? -e.detail * 20 : // Legacy Moz lines
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

		if (!related) {
			return true;
		}

		try {
			while (related && related !== el) {
				related = related.parentNode;
			}
		} catch (err) {
			return false;
		}
		return related !== el;
	}

	var lastClick;

	// this is a horrible workaround for a bug in Android where a single touch triggers two click events
	function filterClick(e, handler) {
		var timeStamp = e.timeStamp || e.originalEvent && e.originalEvent.timeStamp,
		    elapsed = lastClick && timeStamp - lastClick;

		// are they closer together than 500ms yet more than 100ms?
		// Android typically triggers them ~300ms apart while multiple listeners
		// on the same event should be triggered far faster;
		// or check if click is simulated on the element, and if it is, reject any non-simulated events

		if (elapsed && elapsed > 100 && elapsed < 500 || e.target._simulatedClick && !e._simulated) {
			stop(e);
			return;
		}
		lastClick = timeStamp;

		handler(e);
	}

	var DomEvent = /*#__PURE__*/Object.freeze({
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

	if (!Element.prototype.matches) {
	    var ep = Element.prototype;

	    if (ep.webkitMatchesSelector) // Chrome <34, SF<7.1, iOS<8
	        ep.matches = ep.webkitMatchesSelector;

	    if (ep.msMatchesSelector) // IE9/10/11 & Edge
	        ep.matches = ep.msMatchesSelector;

	    if (ep.mozMatchesSelector) // FF<34
	        ep.matches = ep.mozMatchesSelector;
	}

	// @property TRANSFORM: String
	// Vendor-prefixed fransform style name (e.g. `'webkitTransform'` for WebKit).
	var TRANSFORM = testProp(['transform', 'WebkitTransform', 'OTransform', 'MozTransform', 'msTransform']);

	// webkitTransition comes first because some browser versions that drop vendor prefix don't do
	// the same for the transitionend event, in particular the Android 4.1 stock browser

	// @property TRANSITION: String
	// Vendor-prefixed transform style name.
	var TRANSITION = testProp(['webkitTransition', 'transition', 'OTransition', 'MozTransition', 'msTransition']);

	var TRANSITION_END = TRANSITION === 'webkitTransition' || TRANSITION === 'OTransition' ? TRANSITION + 'End' : 'transitionend';

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
	    var value = el.style[style] || el.currentStyle && el.currentStyle[style];

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
	        if (value === 1) {
	            return;
	        }
	    }

	    value = Math.round(value * 100);

	    if (filter) {
	        filter.Enabled = value !== 100;
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

	function isPropertySupported(prop) {
	    var style = document.documentElement.style;
	    return prop in style;
	}

	// @function setTransform(el: HTMLElement, offset: Point, scale?: Number)
	// Resets the 3D CSS transform of `el` so it is translated by `offset` pixels
	// and optionally scaled by `scale`. Does not have an effect if the
	// browser doesn't support 3D CSS transforms.
	function setTransform(el, offset, scale) {
	    var pos = offset || new Point(0, 0);

	    el.style[TRANSFORM] = (ie3d ? 'translate(' + pos.x + 'px,' + pos.y + 'px)' : 'translate3d(' + pos.x + 'px,' + pos.y + 'px,0)') + (scale ? ' scale(' + scale + ')' : '');
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
	    disableTextSelection = function disableTextSelection() {
	        on(window, 'selectstart', preventDefault);
	    };
	    enableTextSelection = function enableTextSelection() {
	        off(window, 'selectstart', preventDefault);
	    };
	} else {
	    var userSelectProperty = testProp(['userSelect', 'WebkitUserSelect', 'OUserSelect', 'MozUserSelect', 'msUserSelect']);

	    disableTextSelection = function disableTextSelection() {
	        if (userSelectProperty) {
	            var style = document.documentElement.style;
	            _userSelect = style[userSelectProperty];
	            style[userSelectProperty] = 'none';
	        }
	    };
	    enableTextSelection = function enableTextSelection() {
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

	var _outlineElement, _outlineStyle;
	// @function preventOutline(el: HTMLElement)
	// Makes the [outline](https://developer.mozilla.org/docs/Web/CSS/outline)
	// of the element `el` invisible. Used internally by Leaflet to prevent
	// focusable elements from displaying an outline when the user performs a
	// drag interaction on them.
	function preventOutline(element) {
	    while (element.tabIndex === -1) {
	        element = element.parentNode;
	    }
	    if (!element || !element.style) {
	        return;
	    }
	    restoreOutline();
	    _outlineElement = element;
	    _outlineStyle = element.style.outline;
	    element.style.outline = 'none';
	    on(window, 'keydown', restoreOutline);
	}

	// @function restoreOutline()
	// Cancels the effects of a previous [`L.DomUtil.preventOutline`]().
	function restoreOutline() {
	    if (!_outlineElement) {
	        return;
	    }
	    _outlineElement.style.outline = _outlineStyle;
	    _outlineElement = undefined;
	    _outlineStyle = undefined;
	    off(window, 'keydown', restoreOutline);
	}

	var DomUtil = /*#__PURE__*/Object.freeze({
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
		isPropertySupported: isPropertySupported,
		setTransform: setTransform,
		setPosition: setPosition,
		getPosition: getPosition,
		get disableTextSelection () { return disableTextSelection; },
		get enableTextSelection () { return enableTextSelection; },
		disableImageDrag: disableImageDrag,
		enableImageDrag: enableImageDrag,
		preventOutline: preventOutline,
		restoreOutline: restoreOutline
	});

	/**
	 * Checks if `value` is the
	 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
	 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
	 * @example
	 *
	 * _.isObject({});
	 * // => true
	 *
	 * _.isObject([1, 2, 3]);
	 * // => true
	 *
	 * _.isObject(_.noop);
	 * // => true
	 *
	 * _.isObject(null);
	 * // => false
	 */
	function isObject(value) {
	  var type = typeof value;
	  return value != null && (type == 'object' || type == 'function');
	}

	var isObject_1 = isObject;

	/** Detect free variable `global` from Node.js. */
	var freeGlobal = typeof commonjsGlobal == 'object' && commonjsGlobal && commonjsGlobal.Object === Object && commonjsGlobal;

	var _freeGlobal = freeGlobal;

	/** Detect free variable `self`. */
	var freeSelf = typeof self == 'object' && self && self.Object === Object && self;

	/** Used as a reference to the global object. */
	var root = _freeGlobal || freeSelf || Function('return this')();

	var _root = root;

	/**
	 * Gets the timestamp of the number of milliseconds that have elapsed since
	 * the Unix epoch (1 January 1970 00:00:00 UTC).
	 *
	 * @static
	 * @memberOf _
	 * @since 2.4.0
	 * @category Date
	 * @returns {number} Returns the timestamp.
	 * @example
	 *
	 * _.defer(function(stamp) {
	 *   console.log(_.now() - stamp);
	 * }, _.now());
	 * // => Logs the number of milliseconds it took for the deferred invocation.
	 */
	var now = function() {
	  return _root.Date.now();
	};

	var now_1 = now;

	/** Built-in value references. */
	var Symbol$1 = _root.Symbol;

	var _Symbol = Symbol$1;

	/** Used for built-in method references. */
	var objectProto = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty = objectProto.hasOwnProperty;

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var nativeObjectToString = objectProto.toString;

	/** Built-in value references. */
	var symToStringTag = _Symbol ? _Symbol.toStringTag : undefined;

	/**
	 * A specialized version of `baseGetTag` which ignores `Symbol.toStringTag` values.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {string} Returns the raw `toStringTag`.
	 */
	function getRawTag(value) {
	  var isOwn = hasOwnProperty.call(value, symToStringTag),
	      tag = value[symToStringTag];

	  try {
	    value[symToStringTag] = undefined;
	  } catch (e) {}

	  var result = nativeObjectToString.call(value);
	  {
	    if (isOwn) {
	      value[symToStringTag] = tag;
	    } else {
	      delete value[symToStringTag];
	    }
	  }
	  return result;
	}

	var _getRawTag = getRawTag;

	/** Used for built-in method references. */
	var objectProto$1 = Object.prototype;

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var nativeObjectToString$1 = objectProto$1.toString;

	/**
	 * Converts `value` to a string using `Object.prototype.toString`.
	 *
	 * @private
	 * @param {*} value The value to convert.
	 * @returns {string} Returns the converted string.
	 */
	function objectToString(value) {
	  return nativeObjectToString$1.call(value);
	}

	var _objectToString = objectToString;

	/** `Object#toString` result references. */
	var nullTag = '[object Null]',
	    undefinedTag = '[object Undefined]';

	/** Built-in value references. */
	var symToStringTag$1 = _Symbol ? _Symbol.toStringTag : undefined;

	/**
	 * The base implementation of `getTag` without fallbacks for buggy environments.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {string} Returns the `toStringTag`.
	 */
	function baseGetTag(value) {
	  if (value == null) {
	    return value === undefined ? undefinedTag : nullTag;
	  }
	  return (symToStringTag$1 && symToStringTag$1 in Object(value))
	    ? _getRawTag(value)
	    : _objectToString(value);
	}

	var _baseGetTag = baseGetTag;

	/**
	 * Checks if `value` is object-like. A value is object-like if it's not `null`
	 * and has a `typeof` result of "object".
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
	 * @example
	 *
	 * _.isObjectLike({});
	 * // => true
	 *
	 * _.isObjectLike([1, 2, 3]);
	 * // => true
	 *
	 * _.isObjectLike(_.noop);
	 * // => false
	 *
	 * _.isObjectLike(null);
	 * // => false
	 */
	function isObjectLike(value) {
	  return value != null && typeof value == 'object';
	}

	var isObjectLike_1 = isObjectLike;

	/** `Object#toString` result references. */
	var symbolTag = '[object Symbol]';

	/**
	 * Checks if `value` is classified as a `Symbol` primitive or object.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a symbol, else `false`.
	 * @example
	 *
	 * _.isSymbol(Symbol.iterator);
	 * // => true
	 *
	 * _.isSymbol('abc');
	 * // => false
	 */
	function isSymbol(value) {
	  return typeof value == 'symbol' ||
	    (isObjectLike_1(value) && _baseGetTag(value) == symbolTag);
	}

	var isSymbol_1 = isSymbol;

	/** Used as references for various `Number` constants. */
	var NAN = 0 / 0;

	/** Used to match leading and trailing whitespace. */
	var reTrim = /^\s+|\s+$/g;

	/** Used to detect bad signed hexadecimal string values. */
	var reIsBadHex = /^[-+]0x[0-9a-f]+$/i;

	/** Used to detect binary string values. */
	var reIsBinary = /^0b[01]+$/i;

	/** Used to detect octal string values. */
	var reIsOctal = /^0o[0-7]+$/i;

	/** Built-in method references without a dependency on `root`. */
	var freeParseInt = parseInt;

	/**
	 * Converts `value` to a number.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to process.
	 * @returns {number} Returns the number.
	 * @example
	 *
	 * _.toNumber(3.2);
	 * // => 3.2
	 *
	 * _.toNumber(Number.MIN_VALUE);
	 * // => 5e-324
	 *
	 * _.toNumber(Infinity);
	 * // => Infinity
	 *
	 * _.toNumber('3.2');
	 * // => 3.2
	 */
	function toNumber(value) {
	  if (typeof value == 'number') {
	    return value;
	  }
	  if (isSymbol_1(value)) {
	    return NAN;
	  }
	  if (isObject_1(value)) {
	    var other = typeof value.valueOf == 'function' ? value.valueOf() : value;
	    value = isObject_1(other) ? (other + '') : other;
	  }
	  if (typeof value != 'string') {
	    return value === 0 ? value : +value;
	  }
	  value = value.replace(reTrim, '');
	  var isBinary = reIsBinary.test(value);
	  return (isBinary || reIsOctal.test(value))
	    ? freeParseInt(value.slice(2), isBinary ? 2 : 8)
	    : (reIsBadHex.test(value) ? NAN : +value);
	}

	var toNumber_1 = toNumber;

	/** Error message constants. */
	var FUNC_ERROR_TEXT = 'Expected a function';

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeMax = Math.max,
	    nativeMin = Math.min;

	/**
	 * Creates a debounced function that delays invoking `func` until after `wait`
	 * milliseconds have elapsed since the last time the debounced function was
	 * invoked. The debounced function comes with a `cancel` method to cancel
	 * delayed `func` invocations and a `flush` method to immediately invoke them.
	 * Provide `options` to indicate whether `func` should be invoked on the
	 * leading and/or trailing edge of the `wait` timeout. The `func` is invoked
	 * with the last arguments provided to the debounced function. Subsequent
	 * calls to the debounced function return the result of the last `func`
	 * invocation.
	 *
	 * **Note:** If `leading` and `trailing` options are `true`, `func` is
	 * invoked on the trailing edge of the timeout only if the debounced function
	 * is invoked more than once during the `wait` timeout.
	 *
	 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
	 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
	 *
	 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
	 * for details over the differences between `_.debounce` and `_.throttle`.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Function
	 * @param {Function} func The function to debounce.
	 * @param {number} [wait=0] The number of milliseconds to delay.
	 * @param {Object} [options={}] The options object.
	 * @param {boolean} [options.leading=false]
	 *  Specify invoking on the leading edge of the timeout.
	 * @param {number} [options.maxWait]
	 *  The maximum time `func` is allowed to be delayed before it's invoked.
	 * @param {boolean} [options.trailing=true]
	 *  Specify invoking on the trailing edge of the timeout.
	 * @returns {Function} Returns the new debounced function.
	 * @example
	 *
	 * // Avoid costly calculations while the window size is in flux.
	 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
	 *
	 * // Invoke `sendMail` when clicked, debouncing subsequent calls.
	 * jQuery(element).on('click', _.debounce(sendMail, 300, {
	 *   'leading': true,
	 *   'trailing': false
	 * }));
	 *
	 * // Ensure `batchLog` is invoked once after 1 second of debounced calls.
	 * var debounced = _.debounce(batchLog, 250, { 'maxWait': 1000 });
	 * var source = new EventSource('/stream');
	 * jQuery(source).on('message', debounced);
	 *
	 * // Cancel the trailing debounced invocation.
	 * jQuery(window).on('popstate', debounced.cancel);
	 */
	function debounce(func, wait, options) {
	  var lastArgs,
	      lastThis,
	      maxWait,
	      result,
	      timerId,
	      lastCallTime,
	      lastInvokeTime = 0,
	      leading = false,
	      maxing = false,
	      trailing = true;

	  if (typeof func != 'function') {
	    throw new TypeError(FUNC_ERROR_TEXT);
	  }
	  wait = toNumber_1(wait) || 0;
	  if (isObject_1(options)) {
	    leading = !!options.leading;
	    maxing = 'maxWait' in options;
	    maxWait = maxing ? nativeMax(toNumber_1(options.maxWait) || 0, wait) : maxWait;
	    trailing = 'trailing' in options ? !!options.trailing : trailing;
	  }

	  function invokeFunc(time) {
	    var args = lastArgs,
	        thisArg = lastThis;

	    lastArgs = lastThis = undefined;
	    lastInvokeTime = time;
	    result = func.apply(thisArg, args);
	    return result;
	  }

	  function leadingEdge(time) {
	    // Reset any `maxWait` timer.
	    lastInvokeTime = time;
	    // Start the timer for the trailing edge.
	    timerId = setTimeout(timerExpired, wait);
	    // Invoke the leading edge.
	    return leading ? invokeFunc(time) : result;
	  }

	  function remainingWait(time) {
	    var timeSinceLastCall = time - lastCallTime,
	        timeSinceLastInvoke = time - lastInvokeTime,
	        timeWaiting = wait - timeSinceLastCall;

	    return maxing
	      ? nativeMin(timeWaiting, maxWait - timeSinceLastInvoke)
	      : timeWaiting;
	  }

	  function shouldInvoke(time) {
	    var timeSinceLastCall = time - lastCallTime,
	        timeSinceLastInvoke = time - lastInvokeTime;

	    // Either this is the first call, activity has stopped and we're at the
	    // trailing edge, the system time has gone backwards and we're treating
	    // it as the trailing edge, or we've hit the `maxWait` limit.
	    return (lastCallTime === undefined || (timeSinceLastCall >= wait) ||
	      (timeSinceLastCall < 0) || (maxing && timeSinceLastInvoke >= maxWait));
	  }

	  function timerExpired() {
	    var time = now_1();
	    if (shouldInvoke(time)) {
	      return trailingEdge(time);
	    }
	    // Restart the timer.
	    timerId = setTimeout(timerExpired, remainingWait(time));
	  }

	  function trailingEdge(time) {
	    timerId = undefined;

	    // Only invoke if we have `lastArgs` which means `func` has been
	    // debounced at least once.
	    if (trailing && lastArgs) {
	      return invokeFunc(time);
	    }
	    lastArgs = lastThis = undefined;
	    return result;
	  }

	  function cancel() {
	    if (timerId !== undefined) {
	      clearTimeout(timerId);
	    }
	    lastInvokeTime = 0;
	    lastArgs = lastCallTime = lastThis = timerId = undefined;
	  }

	  function flush() {
	    return timerId === undefined ? result : trailingEdge(now_1());
	  }

	  function debounced() {
	    var time = now_1(),
	        isInvoking = shouldInvoke(time);

	    lastArgs = arguments;
	    lastThis = this;
	    lastCallTime = time;

	    if (isInvoking) {
	      if (timerId === undefined) {
	        return leadingEdge(lastCallTime);
	      }
	      if (maxing) {
	        // Handle invocations in a tight loop.
	        timerId = setTimeout(timerExpired, wait);
	        return invokeFunc(lastCallTime);
	      }
	    }
	    if (timerId === undefined) {
	      timerId = setTimeout(timerExpired, wait);
	    }
	    return result;
	  }
	  debounced.cancel = cancel;
	  debounced.flush = flush;
	  return debounced;
	}

	var debounce_1 = debounce;

	/** `Object#toString` result references. */
	var asyncTag = '[object AsyncFunction]',
	    funcTag = '[object Function]',
	    genTag = '[object GeneratorFunction]',
	    proxyTag = '[object Proxy]';

	/**
	 * Checks if `value` is classified as a `Function` object.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a function, else `false`.
	 * @example
	 *
	 * _.isFunction(_);
	 * // => true
	 *
	 * _.isFunction(/abc/);
	 * // => false
	 */
	function isFunction(value) {
	  if (!isObject_1(value)) {
	    return false;
	  }
	  // The use of `Object#toString` avoids issues with the `typeof` operator
	  // in Safari 9 which returns 'object' for typed arrays and other constructors.
	  var tag = _baseGetTag(value);
	  return tag == funcTag || tag == genTag || tag == asyncTag || tag == proxyTag;
	}

	var isFunction_1 = isFunction;

	/** Used to detect overreaching core-js shims. */
	var coreJsData = _root['__core-js_shared__'];

	var _coreJsData = coreJsData;

	/** Used to detect methods masquerading as native. */
	var maskSrcKey = (function() {
	  var uid = /[^.]+$/.exec(_coreJsData && _coreJsData.keys && _coreJsData.keys.IE_PROTO || '');
	  return uid ? ('Symbol(src)_1.' + uid) : '';
	}());

	/**
	 * Checks if `func` has its source masked.
	 *
	 * @private
	 * @param {Function} func The function to check.
	 * @returns {boolean} Returns `true` if `func` is masked, else `false`.
	 */
	function isMasked(func) {
	  return !!maskSrcKey && (maskSrcKey in func);
	}

	var _isMasked = isMasked;

	/** Used for built-in method references. */
	var funcProto = Function.prototype;

	/** Used to resolve the decompiled source of functions. */
	var funcToString = funcProto.toString;

	/**
	 * Converts `func` to its source code.
	 *
	 * @private
	 * @param {Function} func The function to convert.
	 * @returns {string} Returns the source code.
	 */
	function toSource(func) {
	  if (func != null) {
	    try {
	      return funcToString.call(func);
	    } catch (e) {}
	    try {
	      return (func + '');
	    } catch (e) {}
	  }
	  return '';
	}

	var _toSource = toSource;

	/**
	 * Used to match `RegExp`
	 * [syntax characters](http://ecma-international.org/ecma-262/7.0/#sec-patterns).
	 */
	var reRegExpChar = /[\\^$.*+?()[\]{}|]/g;

	/** Used to detect host constructors (Safari). */
	var reIsHostCtor = /^\[object .+?Constructor\]$/;

	/** Used for built-in method references. */
	var funcProto$1 = Function.prototype,
	    objectProto$2 = Object.prototype;

	/** Used to resolve the decompiled source of functions. */
	var funcToString$1 = funcProto$1.toString;

	/** Used to check objects for own properties. */
	var hasOwnProperty$1 = objectProto$2.hasOwnProperty;

	/** Used to detect if a method is native. */
	var reIsNative = RegExp('^' +
	  funcToString$1.call(hasOwnProperty$1).replace(reRegExpChar, '\\$&')
	  .replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g, '$1.*?') + '$'
	);

	/**
	 * The base implementation of `_.isNative` without bad shim checks.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a native function,
	 *  else `false`.
	 */
	function baseIsNative(value) {
	  if (!isObject_1(value) || _isMasked(value)) {
	    return false;
	  }
	  var pattern = isFunction_1(value) ? reIsNative : reIsHostCtor;
	  return pattern.test(_toSource(value));
	}

	var _baseIsNative = baseIsNative;

	/**
	 * Gets the value at `key` of `object`.
	 *
	 * @private
	 * @param {Object} [object] The object to query.
	 * @param {string} key The key of the property to get.
	 * @returns {*} Returns the property value.
	 */
	function getValue(object, key) {
	  return object == null ? undefined : object[key];
	}

	var _getValue = getValue;

	/**
	 * Gets the native function at `key` of `object`.
	 *
	 * @private
	 * @param {Object} object The object to query.
	 * @param {string} key The key of the method to get.
	 * @returns {*} Returns the function if it's native, else `undefined`.
	 */
	function getNative(object, key) {
	  var value = _getValue(object, key);
	  return _baseIsNative(value) ? value : undefined;
	}

	var _getNative = getNative;

	var defineProperty = (function() {
	  try {
	    var func = _getNative(Object, 'defineProperty');
	    func({}, '', {});
	    return func;
	  } catch (e) {}
	}());

	var _defineProperty = defineProperty;

	/**
	 * The base implementation of `assignValue` and `assignMergeValue` without
	 * value checks.
	 *
	 * @private
	 * @param {Object} object The object to modify.
	 * @param {string} key The key of the property to assign.
	 * @param {*} value The value to assign.
	 */
	function baseAssignValue(object, key, value) {
	  if (key == '__proto__' && _defineProperty) {
	    _defineProperty(object, key, {
	      'configurable': true,
	      'enumerable': true,
	      'value': value,
	      'writable': true
	    });
	  } else {
	    object[key] = value;
	  }
	}

	var _baseAssignValue = baseAssignValue;

	/**
	 * Performs a
	 * [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
	 * comparison between two values to determine if they are equivalent.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to compare.
	 * @param {*} other The other value to compare.
	 * @returns {boolean} Returns `true` if the values are equivalent, else `false`.
	 * @example
	 *
	 * var object = { 'a': 1 };
	 * var other = { 'a': 1 };
	 *
	 * _.eq(object, object);
	 * // => true
	 *
	 * _.eq(object, other);
	 * // => false
	 *
	 * _.eq('a', 'a');
	 * // => true
	 *
	 * _.eq('a', Object('a'));
	 * // => false
	 *
	 * _.eq(NaN, NaN);
	 * // => true
	 */
	function eq(value, other) {
	  return value === other || (value !== value && other !== other);
	}

	var eq_1 = eq;

	/** Used for built-in method references. */
	var objectProto$3 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$2 = objectProto$3.hasOwnProperty;

	/**
	 * Assigns `value` to `key` of `object` if the existing value is not equivalent
	 * using [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
	 * for equality comparisons.
	 *
	 * @private
	 * @param {Object} object The object to modify.
	 * @param {string} key The key of the property to assign.
	 * @param {*} value The value to assign.
	 */
	function assignValue(object, key, value) {
	  var objValue = object[key];
	  if (!(hasOwnProperty$2.call(object, key) && eq_1(objValue, value)) ||
	      (value === undefined && !(key in object))) {
	    _baseAssignValue(object, key, value);
	  }
	}

	var _assignValue = assignValue;

	/**
	 * Copies properties of `source` to `object`.
	 *
	 * @private
	 * @param {Object} source The object to copy properties from.
	 * @param {Array} props The property identifiers to copy.
	 * @param {Object} [object={}] The object to copy properties to.
	 * @param {Function} [customizer] The function to customize copied values.
	 * @returns {Object} Returns `object`.
	 */
	function copyObject(source, props, object, customizer) {
	  var isNew = !object;
	  object || (object = {});

	  var index = -1,
	      length = props.length;

	  while (++index < length) {
	    var key = props[index];

	    var newValue = customizer
	      ? customizer(object[key], source[key], key, object, source)
	      : undefined;

	    if (newValue === undefined) {
	      newValue = source[key];
	    }
	    if (isNew) {
	      _baseAssignValue(object, key, newValue);
	    } else {
	      _assignValue(object, key, newValue);
	    }
	  }
	  return object;
	}

	var _copyObject = copyObject;

	/**
	 * This method returns the first argument it receives.
	 *
	 * @static
	 * @since 0.1.0
	 * @memberOf _
	 * @category Util
	 * @param {*} value Any value.
	 * @returns {*} Returns `value`.
	 * @example
	 *
	 * var object = { 'a': 1 };
	 *
	 * console.log(_.identity(object) === object);
	 * // => true
	 */
	function identity(value) {
	  return value;
	}

	var identity_1 = identity;

	/**
	 * A faster alternative to `Function#apply`, this function invokes `func`
	 * with the `this` binding of `thisArg` and the arguments of `args`.
	 *
	 * @private
	 * @param {Function} func The function to invoke.
	 * @param {*} thisArg The `this` binding of `func`.
	 * @param {Array} args The arguments to invoke `func` with.
	 * @returns {*} Returns the result of `func`.
	 */
	function apply(func, thisArg, args) {
	  switch (args.length) {
	    case 0: return func.call(thisArg);
	    case 1: return func.call(thisArg, args[0]);
	    case 2: return func.call(thisArg, args[0], args[1]);
	    case 3: return func.call(thisArg, args[0], args[1], args[2]);
	  }
	  return func.apply(thisArg, args);
	}

	var _apply = apply;

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeMax$1 = Math.max;

	/**
	 * A specialized version of `baseRest` which transforms the rest array.
	 *
	 * @private
	 * @param {Function} func The function to apply a rest parameter to.
	 * @param {number} [start=func.length-1] The start position of the rest parameter.
	 * @param {Function} transform The rest array transform.
	 * @returns {Function} Returns the new function.
	 */
	function overRest(func, start, transform) {
	  start = nativeMax$1(start === undefined ? (func.length - 1) : start, 0);
	  return function() {
	    var args = arguments,
	        index = -1,
	        length = nativeMax$1(args.length - start, 0),
	        array = Array(length);

	    while (++index < length) {
	      array[index] = args[start + index];
	    }
	    index = -1;
	    var otherArgs = Array(start + 1);
	    while (++index < start) {
	      otherArgs[index] = args[index];
	    }
	    otherArgs[start] = transform(array);
	    return _apply(func, this, otherArgs);
	  };
	}

	var _overRest = overRest;

	/**
	 * Creates a function that returns `value`.
	 *
	 * @static
	 * @memberOf _
	 * @since 2.4.0
	 * @category Util
	 * @param {*} value The value to return from the new function.
	 * @returns {Function} Returns the new constant function.
	 * @example
	 *
	 * var objects = _.times(2, _.constant({ 'a': 1 }));
	 *
	 * console.log(objects);
	 * // => [{ 'a': 1 }, { 'a': 1 }]
	 *
	 * console.log(objects[0] === objects[1]);
	 * // => true
	 */
	function constant(value) {
	  return function() {
	    return value;
	  };
	}

	var constant_1 = constant;

	/**
	 * The base implementation of `setToString` without support for hot loop shorting.
	 *
	 * @private
	 * @param {Function} func The function to modify.
	 * @param {Function} string The `toString` result.
	 * @returns {Function} Returns `func`.
	 */
	var baseSetToString = !_defineProperty ? identity_1 : function(func, string) {
	  return _defineProperty(func, 'toString', {
	    'configurable': true,
	    'enumerable': false,
	    'value': constant_1(string),
	    'writable': true
	  });
	};

	var _baseSetToString = baseSetToString;

	/** Used to detect hot functions by number of calls within a span of milliseconds. */
	var HOT_COUNT = 800,
	    HOT_SPAN = 16;

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeNow = Date.now;

	/**
	 * Creates a function that'll short out and invoke `identity` instead
	 * of `func` when it's called `HOT_COUNT` or more times in `HOT_SPAN`
	 * milliseconds.
	 *
	 * @private
	 * @param {Function} func The function to restrict.
	 * @returns {Function} Returns the new shortable function.
	 */
	function shortOut(func) {
	  var count = 0,
	      lastCalled = 0;

	  return function() {
	    var stamp = nativeNow(),
	        remaining = HOT_SPAN - (stamp - lastCalled);

	    lastCalled = stamp;
	    if (remaining > 0) {
	      if (++count >= HOT_COUNT) {
	        return arguments[0];
	      }
	    } else {
	      count = 0;
	    }
	    return func.apply(undefined, arguments);
	  };
	}

	var _shortOut = shortOut;

	/**
	 * Sets the `toString` method of `func` to return `string`.
	 *
	 * @private
	 * @param {Function} func The function to modify.
	 * @param {Function} string The `toString` result.
	 * @returns {Function} Returns `func`.
	 */
	var setToString = _shortOut(_baseSetToString);

	var _setToString = setToString;

	/**
	 * The base implementation of `_.rest` which doesn't validate or coerce arguments.
	 *
	 * @private
	 * @param {Function} func The function to apply a rest parameter to.
	 * @param {number} [start=func.length-1] The start position of the rest parameter.
	 * @returns {Function} Returns the new function.
	 */
	function baseRest(func, start) {
	  return _setToString(_overRest(func, start, identity_1), func + '');
	}

	var _baseRest = baseRest;

	/** Used as references for various `Number` constants. */
	var MAX_SAFE_INTEGER = 9007199254740991;

	/**
	 * Checks if `value` is a valid array-like length.
	 *
	 * **Note:** This method is loosely based on
	 * [`ToLength`](http://ecma-international.org/ecma-262/7.0/#sec-tolength).
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a valid length, else `false`.
	 * @example
	 *
	 * _.isLength(3);
	 * // => true
	 *
	 * _.isLength(Number.MIN_VALUE);
	 * // => false
	 *
	 * _.isLength(Infinity);
	 * // => false
	 *
	 * _.isLength('3');
	 * // => false
	 */
	function isLength(value) {
	  return typeof value == 'number' &&
	    value > -1 && value % 1 == 0 && value <= MAX_SAFE_INTEGER;
	}

	var isLength_1 = isLength;

	/**
	 * Checks if `value` is array-like. A value is considered array-like if it's
	 * not a function and has a `value.length` that's an integer greater than or
	 * equal to `0` and less than or equal to `Number.MAX_SAFE_INTEGER`.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is array-like, else `false`.
	 * @example
	 *
	 * _.isArrayLike([1, 2, 3]);
	 * // => true
	 *
	 * _.isArrayLike(document.body.children);
	 * // => true
	 *
	 * _.isArrayLike('abc');
	 * // => true
	 *
	 * _.isArrayLike(_.noop);
	 * // => false
	 */
	function isArrayLike(value) {
	  return value != null && isLength_1(value.length) && !isFunction_1(value);
	}

	var isArrayLike_1 = isArrayLike;

	/** Used as references for various `Number` constants. */
	var MAX_SAFE_INTEGER$1 = 9007199254740991;

	/** Used to detect unsigned integer values. */
	var reIsUint = /^(?:0|[1-9]\d*)$/;

	/**
	 * Checks if `value` is a valid array-like index.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @param {number} [length=MAX_SAFE_INTEGER] The upper bounds of a valid index.
	 * @returns {boolean} Returns `true` if `value` is a valid index, else `false`.
	 */
	function isIndex(value, length) {
	  var type = typeof value;
	  length = length == null ? MAX_SAFE_INTEGER$1 : length;

	  return !!length &&
	    (type == 'number' ||
	      (type != 'symbol' && reIsUint.test(value))) &&
	        (value > -1 && value % 1 == 0 && value < length);
	}

	var _isIndex = isIndex;

	/**
	 * Checks if the given arguments are from an iteratee call.
	 *
	 * @private
	 * @param {*} value The potential iteratee value argument.
	 * @param {*} index The potential iteratee index or key argument.
	 * @param {*} object The potential iteratee object argument.
	 * @returns {boolean} Returns `true` if the arguments are from an iteratee call,
	 *  else `false`.
	 */
	function isIterateeCall(value, index, object) {
	  if (!isObject_1(object)) {
	    return false;
	  }
	  var type = typeof index;
	  if (type == 'number'
	        ? (isArrayLike_1(object) && _isIndex(index, object.length))
	        : (type == 'string' && index in object)
	      ) {
	    return eq_1(object[index], value);
	  }
	  return false;
	}

	var _isIterateeCall = isIterateeCall;

	/**
	 * Creates a function like `_.assign`.
	 *
	 * @private
	 * @param {Function} assigner The function to assign values.
	 * @returns {Function} Returns the new assigner function.
	 */
	function createAssigner(assigner) {
	  return _baseRest(function(object, sources) {
	    var index = -1,
	        length = sources.length,
	        customizer = length > 1 ? sources[length - 1] : undefined,
	        guard = length > 2 ? sources[2] : undefined;

	    customizer = (assigner.length > 3 && typeof customizer == 'function')
	      ? (length--, customizer)
	      : undefined;

	    if (guard && _isIterateeCall(sources[0], sources[1], guard)) {
	      customizer = length < 3 ? undefined : customizer;
	      length = 1;
	    }
	    object = Object(object);
	    while (++index < length) {
	      var source = sources[index];
	      if (source) {
	        assigner(object, source, index, customizer);
	      }
	    }
	    return object;
	  });
	}

	var _createAssigner = createAssigner;

	/** Used for built-in method references. */
	var objectProto$4 = Object.prototype;

	/**
	 * Checks if `value` is likely a prototype object.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a prototype, else `false`.
	 */
	function isPrototype(value) {
	  var Ctor = value && value.constructor,
	      proto = (typeof Ctor == 'function' && Ctor.prototype) || objectProto$4;

	  return value === proto;
	}

	var _isPrototype = isPrototype;

	/**
	 * The base implementation of `_.times` without support for iteratee shorthands
	 * or max array length checks.
	 *
	 * @private
	 * @param {number} n The number of times to invoke `iteratee`.
	 * @param {Function} iteratee The function invoked per iteration.
	 * @returns {Array} Returns the array of results.
	 */
	function baseTimes(n, iteratee) {
	  var index = -1,
	      result = Array(n);

	  while (++index < n) {
	    result[index] = iteratee(index);
	  }
	  return result;
	}

	var _baseTimes = baseTimes;

	/** `Object#toString` result references. */
	var argsTag = '[object Arguments]';

	/**
	 * The base implementation of `_.isArguments`.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
	 */
	function baseIsArguments(value) {
	  return isObjectLike_1(value) && _baseGetTag(value) == argsTag;
	}

	var _baseIsArguments = baseIsArguments;

	/** Used for built-in method references. */
	var objectProto$5 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$3 = objectProto$5.hasOwnProperty;

	/** Built-in value references. */
	var propertyIsEnumerable = objectProto$5.propertyIsEnumerable;

	/**
	 * Checks if `value` is likely an `arguments` object.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
	 *  else `false`.
	 * @example
	 *
	 * _.isArguments(function() { return arguments; }());
	 * // => true
	 *
	 * _.isArguments([1, 2, 3]);
	 * // => false
	 */
	var isArguments = _baseIsArguments(function() { return arguments; }()) ? _baseIsArguments : function(value) {
	  return isObjectLike_1(value) && hasOwnProperty$3.call(value, 'callee') &&
	    !propertyIsEnumerable.call(value, 'callee');
	};

	var isArguments_1 = isArguments;

	/**
	 * Checks if `value` is classified as an `Array` object.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is an array, else `false`.
	 * @example
	 *
	 * _.isArray([1, 2, 3]);
	 * // => true
	 *
	 * _.isArray(document.body.children);
	 * // => false
	 *
	 * _.isArray('abc');
	 * // => false
	 *
	 * _.isArray(_.noop);
	 * // => false
	 */
	var isArray$1 = Array.isArray;

	var isArray_1 = isArray$1;

	/**
	 * This method returns `false`.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.13.0
	 * @category Util
	 * @returns {boolean} Returns `false`.
	 * @example
	 *
	 * _.times(2, _.stubFalse);
	 * // => [false, false]
	 */
	function stubFalse() {
	  return false;
	}

	var stubFalse_1 = stubFalse;

	var isBuffer_1 = createCommonjsModule(function (module, exports) {
	/** Detect free variable `exports`. */
	var freeExports = exports && !exports.nodeType && exports;

	/** Detect free variable `module`. */
	var freeModule = freeExports && 'object' == 'object' && module && !module.nodeType && module;

	/** Detect the popular CommonJS extension `module.exports`. */
	var moduleExports = freeModule && freeModule.exports === freeExports;

	/** Built-in value references. */
	var Buffer = moduleExports ? _root.Buffer : undefined;

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeIsBuffer = Buffer ? Buffer.isBuffer : undefined;

	/**
	 * Checks if `value` is a buffer.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.3.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a buffer, else `false`.
	 * @example
	 *
	 * _.isBuffer(new Buffer(2));
	 * // => true
	 *
	 * _.isBuffer(new Uint8Array(2));
	 * // => false
	 */
	var isBuffer = nativeIsBuffer || stubFalse_1;

	module.exports = isBuffer;
	});

	/** `Object#toString` result references. */
	var argsTag$1 = '[object Arguments]',
	    arrayTag = '[object Array]',
	    boolTag = '[object Boolean]',
	    dateTag = '[object Date]',
	    errorTag = '[object Error]',
	    funcTag$1 = '[object Function]',
	    mapTag = '[object Map]',
	    numberTag = '[object Number]',
	    objectTag = '[object Object]',
	    regexpTag = '[object RegExp]',
	    setTag = '[object Set]',
	    stringTag = '[object String]',
	    weakMapTag = '[object WeakMap]';

	var arrayBufferTag = '[object ArrayBuffer]',
	    dataViewTag = '[object DataView]',
	    float32Tag = '[object Float32Array]',
	    float64Tag = '[object Float64Array]',
	    int8Tag = '[object Int8Array]',
	    int16Tag = '[object Int16Array]',
	    int32Tag = '[object Int32Array]',
	    uint8Tag = '[object Uint8Array]',
	    uint8ClampedTag = '[object Uint8ClampedArray]',
	    uint16Tag = '[object Uint16Array]',
	    uint32Tag = '[object Uint32Array]';

	/** Used to identify `toStringTag` values of typed arrays. */
	var typedArrayTags = {};
	typedArrayTags[float32Tag] = typedArrayTags[float64Tag] =
	typedArrayTags[int8Tag] = typedArrayTags[int16Tag] =
	typedArrayTags[int32Tag] = typedArrayTags[uint8Tag] =
	typedArrayTags[uint8ClampedTag] = typedArrayTags[uint16Tag] =
	typedArrayTags[uint32Tag] = true;
	typedArrayTags[argsTag$1] = typedArrayTags[arrayTag] =
	typedArrayTags[arrayBufferTag] = typedArrayTags[boolTag] =
	typedArrayTags[dataViewTag] = typedArrayTags[dateTag] =
	typedArrayTags[errorTag] = typedArrayTags[funcTag$1] =
	typedArrayTags[mapTag] = typedArrayTags[numberTag] =
	typedArrayTags[objectTag] = typedArrayTags[regexpTag] =
	typedArrayTags[setTag] = typedArrayTags[stringTag] =
	typedArrayTags[weakMapTag] = false;

	/**
	 * The base implementation of `_.isTypedArray` without Node.js optimizations.
	 *
	 * @private
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
	 */
	function baseIsTypedArray(value) {
	  return isObjectLike_1(value) &&
	    isLength_1(value.length) && !!typedArrayTags[_baseGetTag(value)];
	}

	var _baseIsTypedArray = baseIsTypedArray;

	/**
	 * The base implementation of `_.unary` without support for storing metadata.
	 *
	 * @private
	 * @param {Function} func The function to cap arguments for.
	 * @returns {Function} Returns the new capped function.
	 */
	function baseUnary(func) {
	  return function(value) {
	    return func(value);
	  };
	}

	var _baseUnary = baseUnary;

	var _nodeUtil = createCommonjsModule(function (module, exports) {
	/** Detect free variable `exports`. */
	var freeExports = exports && !exports.nodeType && exports;

	/** Detect free variable `module`. */
	var freeModule = freeExports && 'object' == 'object' && module && !module.nodeType && module;

	/** Detect the popular CommonJS extension `module.exports`. */
	var moduleExports = freeModule && freeModule.exports === freeExports;

	/** Detect free variable `process` from Node.js. */
	var freeProcess = moduleExports && _freeGlobal.process;

	/** Used to access faster Node.js helpers. */
	var nodeUtil = (function() {
	  try {
	    // Use `util.types` for Node.js 10+.
	    var types = freeModule && freeModule.require && freeModule.require('util').types;

	    if (types) {
	      return types;
	    }

	    // Legacy `process.binding('util')` for Node.js < 10.
	    return freeProcess && freeProcess.binding && freeProcess.binding('util');
	  } catch (e) {}
	}());

	module.exports = nodeUtil;
	});

	/* Node.js helper references. */
	var nodeIsTypedArray = _nodeUtil && _nodeUtil.isTypedArray;

	/**
	 * Checks if `value` is classified as a typed array.
	 *
	 * @static
	 * @memberOf _
	 * @since 3.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
	 * @example
	 *
	 * _.isTypedArray(new Uint8Array);
	 * // => true
	 *
	 * _.isTypedArray([]);
	 * // => false
	 */
	var isTypedArray = nodeIsTypedArray ? _baseUnary(nodeIsTypedArray) : _baseIsTypedArray;

	var isTypedArray_1 = isTypedArray;

	/** Used for built-in method references. */
	var objectProto$6 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$4 = objectProto$6.hasOwnProperty;

	/**
	 * Creates an array of the enumerable property names of the array-like `value`.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @param {boolean} inherited Specify returning inherited property names.
	 * @returns {Array} Returns the array of property names.
	 */
	function arrayLikeKeys(value, inherited) {
	  var isArr = isArray_1(value),
	      isArg = !isArr && isArguments_1(value),
	      isBuff = !isArr && !isArg && isBuffer_1(value),
	      isType = !isArr && !isArg && !isBuff && isTypedArray_1(value),
	      skipIndexes = isArr || isArg || isBuff || isType,
	      result = skipIndexes ? _baseTimes(value.length, String) : [],
	      length = result.length;

	  for (var key in value) {
	    if ((inherited || hasOwnProperty$4.call(value, key)) &&
	        !(skipIndexes && (
	           // Safari 9 has enumerable `arguments.length` in strict mode.
	           key == 'length' ||
	           // Node.js 0.10 has enumerable non-index properties on buffers.
	           (isBuff && (key == 'offset' || key == 'parent')) ||
	           // PhantomJS 2 has enumerable non-index properties on typed arrays.
	           (isType && (key == 'buffer' || key == 'byteLength' || key == 'byteOffset')) ||
	           // Skip index properties.
	           _isIndex(key, length)
	        ))) {
	      result.push(key);
	    }
	  }
	  return result;
	}

	var _arrayLikeKeys = arrayLikeKeys;

	/**
	 * Creates a unary function that invokes `func` with its argument transformed.
	 *
	 * @private
	 * @param {Function} func The function to wrap.
	 * @param {Function} transform The argument transform.
	 * @returns {Function} Returns the new function.
	 */
	function overArg(func, transform) {
	  return function(arg) {
	    return func(transform(arg));
	  };
	}

	var _overArg = overArg;

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeKeys = _overArg(Object.keys, Object);

	var _nativeKeys = nativeKeys;

	/** Used for built-in method references. */
	var objectProto$7 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$5 = objectProto$7.hasOwnProperty;

	/**
	 * The base implementation of `_.keys` which doesn't treat sparse arrays as dense.
	 *
	 * @private
	 * @param {Object} object The object to query.
	 * @returns {Array} Returns the array of property names.
	 */
	function baseKeys(object) {
	  if (!_isPrototype(object)) {
	    return _nativeKeys(object);
	  }
	  var result = [];
	  for (var key in Object(object)) {
	    if (hasOwnProperty$5.call(object, key) && key != 'constructor') {
	      result.push(key);
	    }
	  }
	  return result;
	}

	var _baseKeys = baseKeys;

	/**
	 * Creates an array of the own enumerable property names of `object`.
	 *
	 * **Note:** Non-object values are coerced to objects. See the
	 * [ES spec](http://ecma-international.org/ecma-262/7.0/#sec-object.keys)
	 * for more details.
	 *
	 * @static
	 * @since 0.1.0
	 * @memberOf _
	 * @category Object
	 * @param {Object} object The object to query.
	 * @returns {Array} Returns the array of property names.
	 * @example
	 *
	 * function Foo() {
	 *   this.a = 1;
	 *   this.b = 2;
	 * }
	 *
	 * Foo.prototype.c = 3;
	 *
	 * _.keys(new Foo);
	 * // => ['a', 'b'] (iteration order is not guaranteed)
	 *
	 * _.keys('hi');
	 * // => ['0', '1']
	 */
	function keys(object) {
	  return isArrayLike_1(object) ? _arrayLikeKeys(object) : _baseKeys(object);
	}

	var keys_1 = keys;

	/** Used for built-in method references. */
	var objectProto$8 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$6 = objectProto$8.hasOwnProperty;

	/**
	 * Assigns own enumerable string keyed properties of source objects to the
	 * destination object. Source objects are applied from left to right.
	 * Subsequent sources overwrite property assignments of previous sources.
	 *
	 * **Note:** This method mutates `object` and is loosely based on
	 * [`Object.assign`](https://mdn.io/Object/assign).
	 *
	 * @static
	 * @memberOf _
	 * @since 0.10.0
	 * @category Object
	 * @param {Object} object The destination object.
	 * @param {...Object} [sources] The source objects.
	 * @returns {Object} Returns `object`.
	 * @see _.assignIn
	 * @example
	 *
	 * function Foo() {
	 *   this.a = 1;
	 * }
	 *
	 * function Bar() {
	 *   this.c = 3;
	 * }
	 *
	 * Foo.prototype.b = 2;
	 * Bar.prototype.d = 4;
	 *
	 * _.assign({ 'a': 0 }, new Foo, new Bar);
	 * // => { 'a': 1, 'c': 3 }
	 */
	var assign = _createAssigner(function(object, source) {
	  if (_isPrototype(source) || isArrayLike_1(source)) {
	    _copyObject(source, keys_1(source), object);
	    return;
	  }
	  for (var key in source) {
	    if (hasOwnProperty$6.call(source, key)) {
	      _assignValue(object, key, source[key]);
	    }
	  }
	});

	var assign_1 = assign;

	var document$1 = typeof window !== 'undefined' && typeof window.document !== 'undefined' ? window.document : {};
	var keyboardAllowed = typeof Element !== 'undefined' && 'ALLOW_KEYBOARD_INPUT' in Element;

	var fn = function () {
	  var val;

	  var fnMap = [['requestFullscreen', 'exitFullscreen', 'fullscreenElement', 'fullscreenEnabled', 'fullscreenchange', 'fullscreenerror'],
	  // New WebKit
	  ['webkitRequestFullscreen', 'webkitExitFullscreen', 'webkitFullscreenElement', 'webkitFullscreenEnabled', 'webkitfullscreenchange', 'webkitfullscreenerror'],
	  // Old WebKit (Safari 5.1)
	  ['webkitRequestFullScreen', 'webkitCancelFullScreen', 'webkitCurrentFullScreenElement', 'webkitCancelFullScreen', 'webkitfullscreenchange', 'webkitfullscreenerror'], ['mozRequestFullScreen', 'mozCancelFullScreen', 'mozFullScreenElement', 'mozFullScreenEnabled', 'mozfullscreenchange', 'mozfullscreenerror'], ['msRequestFullscreen', 'msExitFullscreen', 'msFullscreenElement', 'msFullscreenEnabled', 'MSFullscreenChange', 'MSFullscreenError']];

	  var i = 0;
	  var l = fnMap.length;
	  var ret = {};

	  for (; i < l; i++) {
	    val = fnMap[i];
	    if (val && val[1] in document$1) {
	      for (i = 0; i < val.length; i++) {
	        ret[fnMap[0][i]] = val[i];
	      }
	      return ret;
	    }
	  }

	  return false;
	}();

	var eventNameMap = {
	  change: fn.fullscreenchange,
	  error: fn.fullscreenerror
	};

	var screenfull = {
	  request: function request(elem) {
	    var request = fn.requestFullscreen;

	    elem = elem || document$1.documentElement;

	    // Work around Safari 5.1 bug: reports support for
	    // keyboard in fullscreen even though it doesn't.
	    // Browser sniffing, since the alternative with
	    // setTimeout is even worse.
	    if (/5\.1[.\d]* Safari/.test(navigator.userAgent)) {
	      elem[request]();
	    } else {
	      elem[request](keyboardAllowed ? Element.ALLOW_KEYBOARD_INPUT : {});
	    }
	  },
	  exit: function exit() {
	    document$1[fn.exitFullscreen]();
	  },
	  toggle: function toggle(elem) {
	    if (this.isFullscreen) {
	      this.exit();
	    } else {
	      this.request(elem);
	    }
	  },
	  onchange: function onchange(callback) {
	    this.on('change', callback);
	  },
	  onerror: function onerror(callback) {
	    this.on('error', callback);
	  },
	  on: function on(event, callback) {
	    var eventName = eventNameMap[event];
	    if (eventName) {
	      document$1.addEventListener(eventName, callback, false);
	    }
	  },
	  off: function off(event, callback) {
	    var eventName = eventNameMap[event];
	    if (eventName) {
	      document$1.removeEventListener(eventName, callback, false);
	    }
	  },
	  raw: fn
	};

	Object.defineProperties(screenfull, {
	  isFullscreen: {
	    get: function get() {
	      return Boolean(document$1[fn.fullscreenElement]);
	    }
	  },
	  element: {
	    enumerable: true,
	    get: function get() {
	      return document$1[fn.fullscreenElement];
	    }
	  },
	  enabled: {
	    enumerable: true,
	    get: function get() {
	      // Coerce to boolean in case of old WebKit
	      return Boolean(document$1[fn.fullscreenEnabled]);
	    }
	  }
	});

	var Reader = Evented.extend({
	  options: {
	    regions: ['header', 'toolbar.top', 'toolbar.left', 'main', 'toolbar.right', 'toolbar.bottom', 'footer'],
	    metadata: {},
	    flow: 'auto',
	    engine: 'epubjs',
	    trackResize: true,
	    mobileMediaQuery: '(min-device-width : 300px) and (max-device-width : 600px)',
	    forceScrolledDocHeight: 1200,
	    rootfilePath: '',
	    text_size: 100,
	    scale: 100.0,
	    flowOptions: {},
	    theme: 'default',
	    themes: [],
	    injectStylesheet: null
	  },

	  initialize: function initialize(id, options) {
	    var self = this;

	    self._original_document_title = document.title;

	    this._cozyOptions = {};
	    if (localStorage.getItem('cozy.options')) {
	      this._cozyOptions = JSON.parse(localStorage.getItem('cozy.options'));
	      if (this._cozyOptions.theme) {
	        this.options.theme = this._cozyOptions.theme;
	      }
	      // if ( this._cozyOptions.flow ) {
	      //   this.options.flow = this._cozyOptions.flow;
	      // }
	    }

	    options = setOptions(this, options);

	    this._checkFeatureCompatibility();

	    this.metadata = this.options.metadata; // initial seed

	    this._initContainer(id);
	    this._initLayout();

	    if (this.options.themes && this.options.themes.length > 0) {
	      this.options.themes.forEach(function (theme) {
	        if (theme.href) {
	          return;
	        }
	        var klass = theme.klass;
	        var rules = {};
	        for (var rule in theme.rules) {
	          var new_rule = '.' + klass;
	          if (rule == 'body') {
	            new_rule = 'body' + new_rule;
	          } else {
	            new_rule += ' ' + rule;
	          }
	          rules[new_rule] = theme.rules[rule];
	        }
	        theme.rules = rules;
	      });
	    }

	    this._updateTheme();

	    // hack for https://github.com/Leaflet/Leaflet/issues/1980
	    // this._onResize = Util.bind(this._onResize, this);

	    this._initEvents();

	    this.callInitHooks();

	    this._mode = this.options.mode;
	  },

	  start: function start(target, cb) {
	    var self = this;

	    if (typeof target == 'function' && cb === undefined) {
	      cb = target;
	      target = undefined;
	    }

	    self._start(target, cb);

	    // Util.loader.js(this.options.engine_href).then(function() {
	    //   self._start(target, cb);
	    //   self._loaded = true;
	    // })
	  },

	  _start: function _start(target, cb) {
	    var self = this;
	    target = target || 0;

	    // self.open(function() {
	    //   self.draw(target, cb);
	    // });

	    self.open(target, cb);
	  },

	  reopen: function reopen(options, target) {
	    /* NOP */
	  },

	  saveOptions: function saveOptions(options) {
	    var saved_options = {};
	    assign_1(saved_options, options);
	    if (saved_options.flow == 'auto') {
	      // do not save
	      delete saved_options.flow;
	    }

	    // var key = `${this.flow}/${this.metadata.layout}`;
	    var key = this.metadata.layout;
	    if (saved_options.text_size || saved_options.scale) {
	      saved_options[key] = {};
	      if (saved_options.text_size) {
	        saved_options[key].text_size = saved_options.text_size;
	        delete saved_options.text_size;
	      }
	      if (saved_options.scale) {
	        saved_options[key].scale = saved_options.scale;
	        delete saved_options.scale;
	      }
	      if (saved_options.flow) {
	        saved_options[key].flow = saved_options.flow;
	        delete saved_options.flow;
	      }
	    }

	    // saved_options[this.flow] = {}
	    // if ( saved_options.text_size ) {
	    // }
	    localStorage.setItem('cozy.options', JSON.stringify(saved_options));
	    this._cozyOptions = saved_options;
	  },

	  _updateTheme: function _updateTheme() {
	    removeClass(this._container, 'cozy-theme-' + (this._container.dataset.theme || 'default'));
	    addClass(this._container, 'cozy-theme-' + this.options.theme);
	    this._container.dataset.theme = this.options.theme;
	  },

	  draw: function draw(target) {
	    // NOOP
	  },

	  next: function next() {
	    // NOOP
	  },

	  prev: function prev() {
	    // NOOP
	  },

	  display: function display(index) {
	    // NOOP
	  },

	  gotoPage: function gotoPage(target) {
	    // NOOP
	  },

	  goBack: function goBack() {
	    history.back();
	  },

	  goForward: function goForward() {
	    history.forward();
	  },

	  requestFullscreen: function requestFullscreen() {
	    if (screenfull.enabled) {
	      // this._preResize();
	      screenfull.toggle(this._container);
	    }
	  },

	  _preResize: function _preResize() {},

	  _initContainer: function _initContainer(id) {
	    var container = this._container = get(id);

	    if (!container) {
	      throw new Error('Reader container not found.');
	    } else if (container._cozy_id) {
	      throw new Error('Reader container is already initialized.');
	    }

	    on(container, 'scroll', this._onScroll, this);
	    this._containerId = stamp(container);
	  },

	  _initLayout: function _initLayout() {
	    var container = this._container;

	    this._fadeAnimated = this.options.fadeAnimation && any3d;

	    addClass(container, 'cozy-container' + (touch ? ' cozy-touch' : '') + (retina ? ' cozy-retina' : '') + (ielt9 ? ' cozy-oldie' : '') + (safari ? ' cozy-safari' : '') + (this._fadeAnimated ? ' cozy-fade-anim' : '') + ' cozy-engine-' + this.options.engine + ' cozy-theme-' + this.options.theme);

	    var position = getStyle(container, 'position');

	    this._initPanes();

	    if (!columnCount) {
	      this.options.flow = 'scrolled-doc';
	    }
	  },

	  _initPanes: function _initPanes() {

	    var panes = this._panes = {};
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
	    panes['loader'] = create$1('div', prefix + 'book-loading', panes['book']);
	    panes['epub'] = create$1('div', prefix + 'book-epub', panes['book']);
	    this._initBookLoader();
	  },

	  _checkIfLoaded: function _checkIfLoaded() {
	    if (!this._loaded) {
	      throw new Error('Set map center and zoom first.');
	    }
	  },

	  // DOM event handling

	  // @section Interaction events
	  _initEvents: function _initEvents(remove$$1) {
	    this._targets = {};
	    this._targets[stamp(this._container)] = this;

	    this.tracking = function (reader) {
	      var _action = [];
	      var _last_location_start;
	      var _last_scrollTop;
	      var _reader = reader;
	      return {
	        action: function action(v) {
	          if (v) {
	            _action = [v];
	            this.event(v);
	            // _reader.fire('trackAction', { action: v })
	          } else {
	            return _action.pop();
	          }
	        },

	        peek: function peek() {
	          return _action[0];
	        },

	        event: function event(action, data) {
	          if (data == null) {
	            data = {};
	          }
	          data.action = action;
	          _reader.fire("trackAction", data);
	        },

	        pageview: function pageview(location) {
	          var do_report = true;
	          if (_reader.settings.flow == 'scrolled-doc') {
	            var scrollTop = 0;
	            if (_reader._rendition.manager && _reader._rendition.manager.container) {
	              scrollTop = _reader._rendition.manager.container.scrollTop;
	              // console.log("AHOY CHECKING SCROLLTOP", _last_scrollTop, scrollTop, Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height);
	            }
	            if (_last_scrollTop && Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height) {
	              do_report = false;
	            } else {
	              _last_scrollTop = scrollTop;
	            }
	          }
	          if (location.start != _last_location_start && do_report) {
	            _last_location_start = location.start;
	            var tracking = { cfi: location.start, href: location.href, action: this.action() };
	            _reader.fire('trackPageview', tracking);
	            return tracking;
	          }
	          return false;
	        },

	        reset: function reset() {
	          if (_reader.settings.flow == 'scrolled-doc') {
	            _last_scrollTop = null;
	          }
	        }
	      };
	    }(this);

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

	    // if (this.options.trackResize) {
	    //   var self = this;
	    //   var fn = debounce(function(){ self.invalidateSize({}); }, 150);
	    //   onOff(window, 'resize', fn, this);
	    // }

	    if (any3d && this.options.transform3DLimit) {
	      (remove$$1 ? this.off : this.on).call(this, 'moveend', this._onMoveEnd);
	    }

	    var self = this;
	    if (screenfull.enabled) {
	      screenfull.on('change', function () {
	        // setTimeout(function() {
	        //   self.invalidateSize({});
	        // }, 100);
	        console.log('AHOY: Am I fullscreen?', screenfull.isFullscreen ? 'YES' : 'NO');
	      });
	    }

	    self.on("updateLocation", function (location) {
	      // possibly invoke a pageview event
	      var tracking;
	      if (tracking = self.tracking.pageview(location)) {
	        if (location.percentage) {
	          var p = Math.ceil(location.percentage * 100);
	          document.title = p + '% - ' + self._original_document_title;
	        }
	        var tmp_href = window.location.href.split("#");
	        tmp_href[1] = location.start.substr(8, location.start.length - 8 - 1);
	        var context = [{ cfi: location.start }, '', tmp_href.join('#')];

	        if (tracking.action && tracking.action.match(/\/go\/link/)) {
	          // console.log("AHOY ACTION", tracking.action, context[0].cfi);
	          history.pushState.apply(history, context);
	        } else {
	          history.replaceState.apply(history, context);
	        }
	      }
	    });

	    window.addEventListener('popstate', function (event) {
	      console.log("AHOY POP STATE", event);
	      if (event.isTrusted && event.state != null) {
	        if (event.state.cfi == self.__last_state_cfi) {
	          console.log("AHOY POP STATE IGNORE", self.__last_state_cfi);
	          event.preventDefault();
	          return;
	        }
	        self.__last_state_cfi = event.state.cfi;
	        if (event.state == null || event.state.cfi == null) {
	          $log.innerHTML += '<li>NULL</li>';
	          event.preventDefault();
	          return;
	        }
	        self.gotoPage(event.state.cfi);
	      }
	    });

	    document.addEventListener('keydown', function (event) {
	      var keyName = event.key;
	      var target = event.target;

	      // check if the activeElement is ".special-panel"
	      var check = document.activeElement;
	      while (check.localName != 'body') {
	        if (check.classList.contains('special-panel')) {
	          return;
	        }
	        check = check.parentElement;
	      }

	      var IGNORE_TARGETS = ['input', 'textarea'];
	      if (IGNORE_TARGETS.indexOf(target.localName) >= 0) {
	        return;
	      }

	      self.fire('keyDown', { keyName: keyName, shiftKey: event.shiftKey });
	    });

	    self.on('keyDown', function (data) {
	      switch (data.keyName) {
	        case 'ArrowRight':
	        case 'PageDown':
	          self.next();
	          break;
	        case 'ArrowLeft':
	        case 'PageUp':
	          self.prev();
	          break;
	        case 'Home':
	          self._scroll('HOME');
	          break;
	        case 'End':
	          self._scroll('END');
	          break;
	      }
	    });
	  },

	  // _onResize: function() {
	  //   if ( ! this._resizeRequest ) {
	  //     this._resizeRequest = Util.requestAnimFrame(function() {
	  //       this.invalidateSize({})
	  //     }, this);
	  //   }
	  // },

	  _onScroll: function _onScroll() {
	    this._container.scrollTop = 0;
	    this._container.scrollLeft = 0;
	  },

	  _handleDOMEvent: function _handleDOMEvent(e) {
	    if (!this._loaded || skipped(e)) {
	      return;
	    }

	    var type = e.type === 'keypress' && e.keyCode === 13 ? 'click' : e.type;

	    if (type === 'mousedown') {
	      // prevents outline when clicking on keyboard-focusable element
	      preventOutline(e.target || e.srcElement);
	    }

	    this._fireDOMEvent(e, type);
	  },

	  _fireDOMEvent: function _fireDOMEvent(e, type, targets) {

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

	    if (e._stopped) {
	      return;
	    }

	    // Find the layer the event is propagating from and its parents.
	    targets = (targets || []).concat(this._findEventTargets(e, type));

	    if (!targets.length) {
	      return;
	    }

	    var target = targets[0];
	    if (type === 'contextmenu' && target.listens(type, true)) {
	      preventDefault(e);
	    }

	    var data = {
	      originalEvent: e
	    };

	    if (e.type !== 'keypress') {
	      var isMarker = target.options && 'icon' in target.options;
	      data.containerPoint = isMarker ? this.latLngToContainerPoint(target.getLatLng()) : this.mouseEventToContainerPoint(e);
	      data.layerPoint = this.containerPointToLayerPoint(data.containerPoint);
	      data.latlng = isMarker ? target.getLatLng() : this.layerPointToLatLng(data.layerPoint);
	    }

	    for (var i = 0; i < targets.length; i++) {
	      targets[i].fire(type, data, true);
	      if (data.originalEvent._stopped || targets[i].options.nonBubblingEvents && indexOf(targets[i].options.nonBubblingEvents, type) !== -1) {
	        return;
	      }
	    }
	  },

	  getFixedBookPanelSize: function getFixedBookPanelSize() {
	    // have to make the book
	    var style = window.getComputedStyle(this._panes['book']);
	    var h = this._panes['book'].clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
	    var w = this._panes['book'].clientWidth - parseFloat(style.paddingRight) - parseFloat(style.paddingLeft);
	    return { height: Math.floor(h * 1.00), width: Math.floor(w * 1.00) };
	  },

	  invalidateSize: function invalidateSize(options) {
	    // TODO: IS THIS EVER USED?
	    var self = this;

	    if (!self._drawn) {
	      return;
	    }

	    cancelAnimFrame(this._resizeRequest);

	    if (!this._loaded) {
	      return this;
	    }

	    this.fire('resized');
	  },

	  _resizeBookPane: function _resizeBookPane() {},

	  _setupHooks: function _setupHooks() {},

	  _checkFeatureCompatibility: function _checkFeatureCompatibility() {
	    if (!isPropertySupported('columnCount') || this._checkMobileDevice()) {
	      // force
	      this.options.flow = 'scrolled-doc';
	    }
	    if (this._checkMobileDevice()) {
	      this.options.text_size = 120;
	    }
	  },

	  _checkMobileDevice: function _checkMobileDevice() {
	    if (this._isMobile === undefined) {
	      this._isMobile = false;
	      if (this.options.mobileMediaQuery) {
	        this._isMobile = window.matchMedia(this.options.mobileMediaQuery).matches;
	      }
	    }
	    return this._isMobile;
	  },

	  _enableBookLoader: function _enableBookLoader() {
	    var delay = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;

	    var self = this;
	    self._clearBookLoaderTimeout();
	    if (delay < 0) {
	      delay = 0;
	      self._force_progress = true;
	    }
	    self._loader_timeout = setTimeout(function () {
	      self._panes['loader'].style.display = 'block';
	    }, delay);
	  },

	  _disableBookLoader: function _disableBookLoader() {
	    var force = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

	    var self = this;
	    self._clearBookLoaderTimeout();
	    if (!self._force_progress || force) {
	      self._panes['loader'].style.display = 'none';
	      self._force_progress = false;
	      self._panes['loader-status'].innerHTML = '';
	    }
	  },

	  _clearBookLoaderTimeout: function _clearBookLoaderTimeout() {
	    var self = this;
	    if (self._loader_timeout) {
	      clearTimeout(self._loader_timeout);
	      self._loader_timeout = null;
	    }
	  },

	  _initBookLoader: function _initBookLoader() {
	    // is this not awesome?
	    var template$$1 = this.options.loader_template || this.loaderTemplate();

	    var body = new DOMParser().parseFromString(template$$1, "text/html").body;
	    while (body.children.length) {
	      this._panes['loader'].appendChild(body.children[0]);
	    }
	    this._panes['loader-status'] = create$1('div', 'cozy-module-book-loading-status', this._panes['loader']);
	  },

	  loaderTemplate: function loaderTemplate() {
	    return '<div class="cozy-loader-spinner">\n    <div class="spinner-backdrop spinner-backdrop--1"></div>\n    <div class="spinner-backdrop spinner-backdrop--2"></div>\n    <div class="spinner-backdrop spinner-backdrop--3"></div>\n    <div class="spinner-backdrop spinner-backdrop--4"></div>\n    <div class="spinner-quarter spinner-quarter--1"></div>\n    <div class="spinner-quarter spinner-quarter--2"></div>\n    <div class="spinner-quarter spinner-quarter--3"></div>\n    <div class="spinner-quarter spinner-quarter--4"></div>\n  </div>';
	  },

	  EOT: true
	});

	Object.defineProperty(Reader.prototype, 'metadata', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    return this._metadata;
	  },

	  set: function set(data) {
	    this._metadata = extend({}, data, this.options.metadata);
	  }
	});

	Object.defineProperty(Reader.prototype, 'flow', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    return this.options.flow == 'auto' ? 'paginated' : this.options.flow;
	  }
	});

	Object.defineProperty(Reader.prototype, 'flowOptions', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata

	    var flow = this.flow;
	    if (!this.options.flowOptions[flow]) {
	      this.options.flowOptions[flow] = {};
	    }
	    if (!this.options.flowOptions[flow].text_size) {
	      this.options.flowOptions[flow].text_size = this.options.text_size;
	    }
	    if (!this.options.flowOptions[flow].scale) {
	      this.options.flowOptions[flow].scale = this.options.scale;
	    }

	    return this.options.flowOptions[flow];
	  }
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

	    initialize: function initialize(options) {
	        setOptions(this, options);
	        if (options.container) {
	            this._container = options.container;
	            this._locked = true;
	        }
	        this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
	    },

	    /* @section
	     * Classes extending L.Control will inherit the following methods:
	     *
	     * @method getRegion: string
	     * Returns the region of the control.
	     */
	    getRegion: function getRegion() {
	        return this.options.region;
	    },

	    // @method setRegion(region: string): this
	    // Sets the region of the control.
	    setRegion: function setRegion(region) {
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
	    getContainer: function getContainer() {
	        return this._container;
	    },

	    // @method addTo(reader: Map): this
	    // Adds the control to the given reader.
	    addTo: function addTo(reader) {
	        this.remove();
	        this._reader = reader;

	        var container = this._container = this.onAdd(reader);

	        addClass(container, 'cozy-control');

	        if (!this._locked) {
	            var region = this.getRegion();
	            var area = reader.getControlRegion(region);
	            area.appendChild(container);
	        }

	        return this;
	    },

	    // @method remove: this
	    // Removes the control from the reader it is currently active on.
	    remove: function remove$$1() {
	        if (!this._reader) {
	            return this;
	        }

	        if (!this._container) {
	            return this;
	        }

	        if (!this._locked) {
	            remove(this._container);
	        }

	        if (this.onRemove) {
	            this.onRemove(this._reader);
	        }

	        this._reader = null;

	        return this;
	    },

	    _refocusOnMap: function _refocusOnMap(e) {
	        // if reader exists and event is not a keyboard event
	        if (this._reader && e && e.screenX > 0 && e.screenY > 0) {
	            this._reader.getContainer().focus();
	        }
	    },

	    _className: function _className(widget) {
	        var className = ['cozy-control'];
	        if (this.options.direction) {
	            className.push('cozy-control-' + this.options.direction);
	        }
	        if (widget) {
	            className.push('cozy-control-' + widget);
	        }
	        return className.join(' ');
	    }
	});

	var control = function control(options) {
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
	    addControl: function addControl(control) {
	        control.addTo(this);
	        return this;
	    },

	    // @method removeControl(control: Control): this
	    // Removes the given control from the reader
	    removeControl: function removeControl(control) {
	        control.remove();
	        return this;
	    },

	    getControlContainer: function getControlContainer() {
	        var l = 'cozy-';
	        if (!this._controlContainer) {
	            this._controlContainer = create$1('div', l + 'control-container', this._container);
	        }
	        return this._controlContainer;
	    },

	    getControlRegion: function getControlRegion(target) {

	        if (!this._panes[target]) {
	            // target is dot-delimited string
	            // first dot is the panel
	            var parts = target.split('.');
	            var tmp = [];
	            var parent = this._container;
	            var x = 0;
	            while (parts.length) {
	                var slug = parts.shift();
	                tmp.push(slug);
	                var panel = tmp.join(".");
	                var className = 'cozy-panel-' + slug;
	                if (!this._panes[panel]) {
	                    this._panes[panel] = create$1('div', className, parent);
	                }
	                parent = this._panes[panel];
	                x += 1;
	                if (x > 100) {
	                    break;
	                }
	            }
	        }
	        return this._panes[target];
	    },

	    getControlRegion_1: function getControlRegion_1(target) {

	        var tmp = target.split('.');
	        var region = tmp.shift();
	        var slot = tmp.pop() || '-slot';

	        var container = this._panes[region];
	        if (!this._panes[target]) {
	            var className = 'cozy-' + region + '--item cozy-slot-' + slot;
	            if (!this._panes[region + '.' + slot]) {
	                var div = create$1('div', className);
	                if (slot == 'left' || slot == 'bottom') {
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

	    _classify: function _classify(tmp) {
	        var l = 'cozy-';
	        var className = [];
	        for (var i in tmp) {
	            className.push(l + tmp[i]);
	        }
	        className = className.join(' ');
	        return className;
	    },

	    _clearControlRegion: function _clearControlRegion() {
	        for (var i in this._controlRegions) {
	            remove(this._controlRegions[i]);
	        }
	        remove(this._controlContainer);
	        delete this._controlRegions;
	        delete this._controlContainer;
	    }
	});

	var PageControl = Control.extend({
	  onAdd: function onAdd(reader) {
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;
	      container = create$1('div', className), this._control = this._createButton(this._fill(options.html || options.label), this._fill(options.label), className, container);
	    }
	    this._bindEvents();

	    return container;
	  },

	  _createButton: function _createButton(html, title, className, container) {
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

	  _bindEvents: function _bindEvents() {
	    var self = this;
	    disableClickPropagation(this._control);
	    on(this._control, 'click', stop);
	    on(this._control, 'click', this._action, this);

	    this._reader.on('reopen', function (data) {
	      // update the button text / titles
	      var html = self.options.html || self.options.label;
	      self._control.innerHTML = self._fill(html);
	      self._control.setAttribute('title', self._fill(self.options.label));
	      self._control.setAttribute('aria-label', self._fill(self.options.label));
	    });
	  },

	  _unit: function _unit() {
	    return this._reader.options.flow == 'scrolled-doc' ? 'Section' : 'Page';
	  },

	  _fill: function _fill(s) {
	    var unit = this._unit();
	    return s.replace(/\$\{unit\}/g, unit);
	  },

	  _label: function _label() {
	    return this.options.label + " " + (this._reader.options.flow == 'scrolled-doc') ? 'Section' : 'Page';
	  },

	  EOT: true
	});

	var PagePrevious = PageControl.extend({
	  options: {
	    region: 'edge.left',
	    direction: 'previous',
	    label: 'Previous ${unit}',
	    html: '<i class="icon-chevron-left oi" data-glyph="chevron-left" title="Previous ${unit}" aria-hidden="true"></i>'
	  },

	  _action: function _action(e) {
	    this._reader.prev();
	  }
	});

	var PageNext = PageControl.extend({
	  options: {
	    region: 'edge.right',
	    direction: 'next',
	    label: 'Next ${unit}',
	    html: '<i class="icon-chevron-right oi" data-glyph="chevron-right" title="Next ${unit}" aria-hidden="true"></i>'
	  },

	  _action: function _action(e) {
	    this._reader.next();
	  }
	});

	var PageFirst = PageControl.extend({
	  options: {
	    direction: 'first',
	    label: 'First ${unit}'
	  },
	  _action: function _action(e) {
	    this._reader.first();
	  }
	});

	var PageLast = PageControl.extend({
	  options: {
	    direction: 'last',
	    label: 'Last ${unit}'
	  },
	  _action: function _action(e) {
	    this._reader.last();
	  }
	});

	var pageNext = function pageNext(options) {
	  return new PageNext(options);
	};

	var pagePrevious = function pagePrevious(options) {
	  return new PagePrevious(options);
	};

	var pageFirst = function pageFirst(options) {
	  return new PageFirst(options);
	};

	var pageLast = function pageLast(options) {
	  return new PageLast(options);
	};

	var activeModal;

	// from https://github.com/ghosh/micromodal/blob/master/src/index.js
	var FOCUSABLE_ELEMENTS = ['a[href]', 'area[href]', 'input:not([disabled]):not([type="hidden"])', 'select:not([disabled])', 'textarea:not([disabled])', 'button:not([disabled])', 'iframe', 'object', 'embed', '[contenteditable]', '[tabindex]:not([tabindex^="-"])'];

	var ACTIONABLE_ELEMENTS = ['a[href]', 'area[href]', 'input[type="submit"]:not([disabled])', 'button:not([disabled])'];

	var Modal = Class.extend({
	  options: {
	    // @option region: String = 'topright'
	    // The region of the control (one of the reader edges). Possible values are `'left' ad 'right'`
	    region: 'left',
	    fraction: 0,
	    width: null,
	    className: {},
	    actions: null,
	    callbacks: { onShow: function onShow() {}, onClose: function onClose() {} },
	    handlers: {}
	  },

	  initialize: function initialize(options) {
	    options = setOptions(this, options);
	    this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
	    this._initializedEvents = false;
	    this.callbacks = assign_1({}, this.options.callbacks);
	    this.actions = this.options.actions ? assign_1({}, this.options.actions) : null;
	    this.handlers = assign_1({}, this.options.handlers);
	    if (typeof this.options.className == 'string') {
	      this.options.className = { container: this.options.className };
	    }
	  },

	  addTo: function addTo(reader) {
	    this._reader = reader;
	    var template$$1 = this.options.template;

	    var panelHTML = '<div class="cozy-modal modal-slide ' + (this.options.region || 'left') + '" id="modal-' + this._id + '" aria-labelledby="modal-' + this._id + '-title" role="dialog" aria-describedby="modal-' + this._id + '-content" aria-hidden="true">\n      <div class="modal__overlay" tabindex="-1" data-modal-close>\n        <div class="modal__container ' + (this.options.className.container ? this.options.className.container : '') + '" role="dialog" aria-modal="true" aria-labelledby="modal-' + this._id + '-title" aria-describedby="modal-' + this._id + '-content" id="modal-' + this._id + '-container">\n          <div role="document">\n            <header class="modal__header">\n              <h3 class="modal__title" id="modal-' + this._id + '-title">' + this.options.title + '</h3>\n              <button class="modal__close" aria-label="Close modal" aria-controls="modal-' + this._id + '-container" data-modal-close></button>\n            </header>\n            <main class="modal__content ' + (this.options.className.main ? this.options.className.main : '') + '" id="modal-' + this._id + '-content">\n              ' + template$$1 + '\n            </main>';

	    if (this.options.actions) {
	      panelHTML += '<footer class="modal__footer">';
	      for (var i in this.options.actions) {
	        var action = this.options.actions[i];
	        var button_cls = action.className || 'button--default';
	        panelHTML += '<button id="action-' + this._id + '-' + i + '" class="button button--lg ' + button_cls + '">' + action.label + '</button>';
	      }
	      panelHTML += '</footer>';
	    }

	    panelHTML += '</div></div></div></div>';

	    var body = new DOMParser().parseFromString(panelHTML, "text/html").body;

	    this.modal = reader._container.appendChild(body.children[0]);
	    this._container = this.modal; // compatibility

	    this.container = this.modal.querySelector('.modal__container');
	    this._bindEvents();
	    return this;
	  },

	  _bindEvents: function _bindEvents() {
	    var _this = this;

	    var self = this;
	    this.onClick = this.onClick.bind(this);
	    this.onKeydown = this.onKeydown.bind(this);
	    this.onModalTransition = this.onModalTransition.bind(this);

	    this.modal.addEventListener('transitionend', function () {}.bind(this));

	    // bind any actions
	    if (this.actions) {
	      var _loop = function _loop() {
	        var action = _this.actions[i];
	        var button_id = '#action-' + _this._id + '-' + i;
	        var button = _this.modal.querySelector(button_id);
	        if (button) {
	          on(button, 'click', function (event) {
	            event.preventDefault();
	            action.callback(event);
	            if (action.close) {
	              self.closeModal();
	            }
	          });
	        }
	      };

	      for (var i in this.actions) {
	        _loop();
	      }
	    }
	  },

	  deactivate: function deactivate() {
	    this.closeModal();
	  },

	  closeModal: function closeModal() {
	    this.modal.setAttribute('aria-hidden', 'true');
	    this.removeEventListeners();
	    if (this.activeElement) {
	      this.activeElement.focus();
	    }
	    this.callbacks.onClose(this.modal);
	  },

	  showModal: function showModal() {
	    this.activeElement = document.activeElement;
	    this._resize();
	    this.modal.setAttribute('aria-hidden', 'false');
	    this.setFocusToFirstNode();
	    this.addEventListeners();
	    this.callbacks.onShow(this.modal);
	  },

	  activate: function activate() {
	    return this.showModal();
	    var self = this;
	    activeModal = this;
	    addClass(self._reader._container, 'st-modal-activating');
	    this._resize();
	    addClass(this._reader._container, 'st-modal-open');
	    setTimeout(function () {
	      addClass(self._container, 'active');
	      removeClass(self._reader._container, 'st-modal-activating');
	      self._container.setAttribute('aria-hidden', 'false');
	      self.setFocusToFirstNode();
	    }, 25);
	  },

	  addEventListeners: function addEventListeners() {
	    // --- do we need touch listeners?
	    // this.modal.addEventListener('touchstart', this.onClick)
	    // this.modal.addEventListener('touchend', this.onClick)
	    this.modal.addEventListener('click', this.onClick);
	    document.addEventListener('keydown', this.onKeydown);
	    'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend'.split(' ').forEach(function (event) {
	      this.modal.addEventListener(event, this.onModalTransition);
	    }.bind(this));
	  },

	  removeEventListeners: function removeEventListeners() {
	    this.modal.removeEventListener('touchstart', this.onClick);
	    this.modal.removeEventListener('click', this.onClick);
	    'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend'.split(' ').forEach(function (event) {
	      this.modal.removeEventListener(event, this.onModalTransition);
	    }.bind(this));
	    document.removeEventListener('keydown', this.onKeydown);
	  },

	  _resize: function _resize() {
	    var container = this._reader._container;
	    this.container.style.height = container.offsetHeight + 'px';
	    // console.log("AHOY MODAL", this.container.style.height);
	    if (!this.options.className.container) {
	      this.container.style.width = this.options.width || parseInt(container.offsetWidth * this.options.fraction) + 'px';
	    }

	    var header = this.container.querySelector('header');
	    var footer = this.container.querySelector('footer');
	    var main = this.container.querySelector('main');
	    var height = this.container.clientHeight - header.clientHeight;
	    if (footer) {
	      height -= footer.clientHeight;
	    }
	    main.style.height = height + 'px';
	  },

	  getFocusableNodes: function getFocusableNodes() {
	    var nodes = this.modal.querySelectorAll(FOCUSABLE_ELEMENTS);
	    return Object.keys(nodes).map(function (key) {
	      return nodes[key];
	    });
	  },

	  setFocusToFirstNode: function setFocusToFirstNode() {
	    var focusableNodes = this.getFocusableNodes();
	    if (focusableNodes.length) {
	      focusableNodes[0].focus();
	    } else {
	      activeModal._container.focus();
	    }
	  },

	  getActionableNodes: function getActionableNodes() {
	    var nodes = this.modal.querySelectorAll(ACTIONABLE_ELEMENTS);
	    return Object.keys(nodes).map(function (key) {
	      return nodes[key];
	    });
	  },

	  onKeydown: function onKeydown(event) {
	    if (event.keyCode == 27) {
	      this.closeModal();
	    }
	    if (event.keyCode == 9) {
	      this.maintainFocus(event);
	    }
	  },

	  onClick: function onClick(event) {

	    var closeAfterAction = false;
	    var target = event.target;

	    // As far as I can tell, the code below isn't catching direct clicks on
	    // items with class='data-modal-close' as they're not ACTIONABLE_ELEMENTS.
	    // Adding them to ACTIONABLE_ELEMENTS causes undesirable behavior where
	    // their child items also close the modal thanks to the loop below.
	    // Children of .modal__overlay include the modal header, border area and
	    // padding. We don't want clicks on these closing the modal.
	    // Just close the modal now for direct clicks on a '.data-modal-close'.
	    if (target.hasAttribute('data-modal-close')) {
	      this.fire('closed');
	      this.closeModal();
	      return;
	    }

	    // if the target isn't an actionable type, walk the DOM until
	    // one is found
	    var actionableNodes = this.getActionableNodes();
	    while (actionableNodes.indexOf(target) < 0 && target != this.modal) {
	      target = target.parentElement;
	    }

	    // no target found, punt
	    if (actionableNodes.indexOf(target) < 0) {
	      return;
	    }

	    if (this.handlers.click) {
	      for (var selector in this.handlers.click) {
	        if (target.matches(selector)) {
	          closeAfterAction = this.handlers.click[selector](this, target);
	          break;
	        }
	      }
	    }

	    if (closeAfterAction || target.hasAttribute('data-modal-close')) this.closeModal();

	    event.preventDefault();
	  },

	  onModalTransition: function onModalTransition(event) {
	    if (this.modal.getAttribute('aria-hidden') == 'true') {
	      this._reader.fire('modal-closed');
	    } else {
	      this._reader.fire('modal-opened');
	    }
	  },

	  on: function on$$1(event, selector, handler) {
	    if (!this.handlers[event]) {
	      this.handlers[event] = {};
	    }
	    if (typeof selector == 'function') {
	      handler = selector;
	      selector = '*';
	    }
	    this.handlers[event][selector] = handler;
	  },

	  fire: function fire(event) {
	    if (this.handlers[event] && this.handlers[event]['*']) {
	      this.handlers[event]['*'](this);
	    }
	  },

	  maintainFocus: function maintainFocus(event) {
	    var focusableNodes = this.getFocusableNodes();
	    var focusedItemIndex = focusableNodes.indexOf(document.activeElement);
	    if (event.shiftKey && focusedItemIndex === 0) {
	      focusableNodes[focusableNodes.length - 1].focus();
	      event.preventDefault();
	    }

	    if (!event.shiftKey && focusedItemIndex === focusableNodes.length - 1) {
	      focusableNodes[0].focus();
	      event.preventDefault();
	    }
	  },

	  update: function update(options) {
	    if (options.title) {
	      this.options.title = options.title;
	      var titleEl = this.container.querySelector('.modal__title');
	      titleEl.innerText = options.title;
	    }

	    if (options.fraction) {
	      this.options.fraction = options.fraction;
	      this.container.style.width = parseInt(this.container.offsetWidth * this.options.fraction) + 'px';
	    }
	  },

	  EOT: true
	});

	Reader.include({
	  modal: function modal(options) {
	    var modal = new Modal(options);
	    return modal.addTo(this);
	    // return this;
	  },

	  popup: function popup(options) {
	    options = assign_1({ title: 'Info', fraction: 1.0 }, options);

	    if (!this._popupModal) {
	      this._popupModal = this.modal({
	        title: options.title,
	        region: 'full',
	        template: '<div style="height: 100%; width: 100%"></div>',
	        fraction: options.fraction || 1.0,
	        actions: [{ label: 'OK', callback: function callback(event) {}, close: true }]
	      });
	    } else {
	      this._popupModal.update({ title: options.title, fraction: options.fraction });
	    }

	    var iframe;
	    var modalDiv = this._popupModal.container.querySelector('main > div');
	    var iframe = modalDiv.querySelector('iframe');
	    if (iframe) {
	      modalDiv.removeChild(iframe);
	    }
	    iframe = document.createElement('iframe');
	    iframe.style.width = '100%';
	    iframe.style.height = '100%';
	    iframe = modalDiv.appendChild(iframe);

	    if (options.onLoad) {
	      iframe.addEventListener('load', function () {
	        options.onLoad(iframe.contentDocument, this._popupModal);
	      }.bind(this));
	    }

	    if (options.srcdoc) {
	      if ("srcdoc" in iframe) {
	        iframe.srcdoc = options.srcdoc;
	      } else {
	        iframe.contentDocument.open();
	        iframe.contentDocument.write(options.srcdoc);
	        iframe.contentDocument.close();
	      }
	    } else if (options.href) {
	      iframe.setAttribute('src', options.href);
	    }

	    this._popupModal.activate();
	  },

	  EOT: true
	});

	var Contents = Control.extend({

	  defaultTemplate: '<button class="button--sm" data-toggle="open" aria-label="Table of Contents"><i class="icon-menu oi" data-glyph="menu" title="Table of Contents" aria-hidden="true"></i></button>',

	  onAdd: function onAdd(reader) {
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;

	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._control = container.querySelector("[data-toggle=open]");
	    this._control.setAttribute('id', 'action-' + this._id);
	    container.style.position = 'relative';

	    this._bindEvents();

	    return container;
	  },

	  _bindEvents: function _bindEvents() {
	    this._reader.on('updateContents', function (data) {

	      on(this._control, 'click', function (event) {
	        event.preventDefault();
	        self._reader.tracking.action('contents/open');
	        self._modal.activate();
	      }, this);

	      this._modal = this._reader.modal({
	        template: '<ul></ul>',
	        title: 'Contents',
	        region: 'left',
	        className: 'cozy-modal-contents'
	      });

	      this._modal.on('click', 'a[href]', function (modal, target) {
	        target = target.getAttribute('data-href');
	        this._reader.tracking.action('contents/go/link');
	        this._reader.gotoPage(target);
	        return true;
	      }.bind(this));

	      this._modal.on('closed', function () {
	        self._reader.tracking.action('contents/close');
	      });

	      this._setupSkipLink();

	      var parent = self._modal._container.querySelector('ul');
	      // var s = data.toc.filter(function(value) { return value.parent == null }).map(function(value) { return [ value, 0, parent ] });
	      // while ( s.length ) {
	      //   var tuple = s.shift();
	      //   var chapter = tuple[0];
	      //   var tabindex = tuple[1];
	      //   var parent = tuple[2];

	      //   var option = self._createOption(chapter, tabindex, parent);
	      //   data.toc.filter(function(value) { return value.parent == chapter.id }).reverse().forEach(function(chapter_) {
	      //     s.unshift([chapter_, tabindex + 1, option]);
	      //   });
	      // }
	      var _process = function _process(items, tabindex, parent) {
	        items.forEach(function (item) {
	          var option = self._createOption(item, tabindex, parent);
	          if (item.subitems && item.subitems.length) {
	            _process(item.subitems, tabindex + 1, option);
	          }
	        });
	      };
	      _process(data.toc, 0, parent);
	    }.bind(this));
	  },
	  _createOption: function _createOption(chapter, tabindex, parent) {
	    var option = create$1('li');
	    if (chapter.href) {
	      var anchor = create$1('a', null, option);
	      if (chapter.html) {
	        anchor.innerHTML = chapter.html;
	      } else {
	        anchor.textContent = chapter.label;
	      }
	      // var tab = pad('', tabindex); tab = tab.length ? tab + ' ' : '';
	      // option.textContent = tab + chapter.label;
	      anchor.setAttribute('href', chapter.href);
	      anchor.setAttribute('data-href', chapter.href);
	    } else {
	      var span = create$1('span', null, option);
	      span.textContent = chapter.label;
	    }

	    if (parent.tagName == 'LI') {
	      // need to nest
	      var tmp = parent.querySelector('ul');
	      if (!tmp) {
	        tmp = create$1('ul', null, parent);
	      }
	      parent = tmp;
	    }

	    parent.appendChild(option);
	    return option;
	  },


	  _setupSkipLink: function _setupSkipLink() {
	    if (!this.options.skipLink) {
	      return;
	    }

	    var target = document.querySelector(this.options.skipLink);
	    if (!target) {
	      return;
	    }

	    var link = document.createElement('a');
	    link.textContent = 'Skip to contents';
	    link.setAttribute('href', '#action-' + this._id);

	    var ul = target.querySelector('ul');
	    if (ul) {
	      // add to list
	      target = document.createElement('li');
	      ul.appendChild(target);
	    }
	    target.appendChild(link);
	    link.addEventListener('click', function (event) {
	      event.preventDefault();
	      event.stopPropagation();
	      this._control.click();
	    }.bind(this));
	  },

	  EOT: true
	});

	var contents = function contents(options) {
	  return new Contents(options);
	};

	// Title + Chapter

	var Title = Control.extend({
	  onAdd: function onAdd(reader) {
	    var self = this;
	    var className = this._className(),
	        container = create$1('div', className),
	        options = this.options;

	    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
	    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

	    var h1 = create$1('h1', 'cozy-h1', container);
	    setOpacity(h1, 0);
	    this._title = create$1('span', 'cozy-title', h1);
	    this._divider = create$1('span', 'cozy-divider', h1);
	    this._divider.textContent = " · ";
	    this._section = create$1('span', 'cozy-section', h1);

	    // --- TODO: disable until we can work out how to 
	    // --- more reliably match the current section to the contents
	    // this._reader.on('updateSection', function(data) {
	    //   if ( data && data.label ) {
	    //     self._section.textContent = data.label;
	    //     DomUtil.setOpacity(self._section, 1.0);
	    //     DomUtil.setOpacity(self._divider, 1.0);
	    //   } else {
	    //     DomUtil.setOpacity(self._section, 0);
	    //     DomUtil.setOpacity(self._divider, 0);
	    //   }
	    // })

	    this._reader.on('updateTitle', function (data) {
	      if (data) {
	        self._title.textContent = data.title || data.bookTitle;
	        setOpacity(self._section, 0);
	        setOpacity(self._divider, 0);
	        setOpacity(h1, 1);
	      }
	    });

	    return container;
	  },

	  _createButton: function _createButton(html, title, className, container, fn) {
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

	var title = function title(options) {
	  return new Title(options);
	};

	// Title + Chapter

	var PublicationMetadata = Control.extend({
	  onAdd: function onAdd(reader) {
	    var self = this;
	    var className = this._className(),
	        container = create$1('div', className),
	        options = this.options;

	    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
	    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

	    this._publisher = create$1('div', 'cozy-publisher', container);
	    this._rights = create$1('div', 'cozy-rights', container);

	    this._reader.on('updateTitle', function (data) {
	      if (data) {
	        self._publisher.textContent = data.publisher;
	        self._rights.textContent = data.rights;
	      }
	    });

	    return container;
	  },

	  _createButton: function _createButton(html, title, className, container, fn) {
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

	var publicationMetadata = function publicationMetadata(options) {
	  return new PublicationMetadata(options);
	};

	var Preferences = Control.extend({
	  options: {
	    label: 'Preferences',
	    hasThemes: false,
	    html: '<i class="icon-cog oi" data-glyph="cog" title="Preferences and Settings" aria-hidden="true"></i>'
	  },

	  onAdd: function onAdd(reader) {
	    var self = this;
	    var className = this._className('preferences'),
	        container = create$1('div', className),
	        options = this.options;

	    this._activated = false;
	    this._control = this._createButton(options.html || options.label, options.label, className, container, this._action);

	    // self.initializeForm();
	    this._modal = this._reader.modal({
	      // template: '<form></form>',
	      title: 'Preferences',
	      className: 'cozy-modal-preferences',
	      actions: [{
	        label: 'Save Changes',
	        callback: function callback(event) {
	          self.updatePreferences(event);
	        }
	      }],
	      region: 'right'
	    });

	    return container;
	  },

	  _action: function _action() {
	    var self = this;
	    self.initializeForm();
	    self._modal.activate();
	  },

	  _createButton: function _createButton(html, title, className, container, fn) {
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

	  _createPanel: function _createPanel() {
	    if (this._modal._container.querySelector('form')) {
	      return;
	    }

	    var template$$1 = '';

	    var possible_fieldsets = [];
	    if (this._reader.metadata.layout == 'pre-paginated') {
	      // different panel
	      possible_fieldsets.push('Scale');
	    } else {
	      possible_fieldsets.push('TextSize');
	    }
	    possible_fieldsets.push('Display');

	    if (this._reader.rootfiles && this._reader.rootfiles.length > 1) {
	      // this.options.hasPackagePaths = true;
	      possible_fieldsets.push('Rendition');
	    }

	    if (this._reader.options.themes && this._reader.options.themes.length > 0) {
	      this.options.hasThemes = true;
	      possible_fieldsets.push('Theme');
	    }

	    this._fieldsets = [];
	    possible_fieldsets.forEach(function (cls) {
	      var fieldset = new Preferences.fieldset[cls](this);
	      template$$1 += fieldset.template();
	      this._fieldsets.push(fieldset);
	    }.bind(this));

	    if (this.options.fields) {
	      this.options.hasFields = true;
	      for (var i in this.options.fields) {
	        var field = this.options.fields[i];
	        template$$1 += '<fieldset class="custom-field">\n          <legend>' + field.label + '</legend>\n        ';
	        for (var j in field.inputs) {
	          var input = field.inputs[j];
	          var checked = input.value == field.value ? ' checked="checked"' : '';
	          template$$1 += '<label><input id="preferences-custom-' + i + '-' + j + '" type="radio" name="x' + field.name + '" value="' + input.value + '" ' + checked + '/>' + input.label + '</label>';
	        }
	        if (field.hint) {
	          template$$1 += '<p class="hint" style="font-size: 90%">' + field.hint + '</p>';
	        }
	      }
	    }

	    template$$1 = '<form>' + template$$1 + '</form>';

	    // this._modal = this._reader.modal({
	    //   template: template,
	    //   title: 'Preferences',
	    //   className: 'cozy-modal-preferences',
	    //   actions: [
	    //     {
	    //       label: 'Save Changes',
	    //       callback: function(event) {
	    //         self.updatePreferences(event);
	    //       }
	    //     }
	    //   ],
	    //   region: 'right'
	    // });

	    this._modal._container.querySelector('main').innerHTML = template$$1;
	    this._form = this._modal._container.querySelector('form');
	  },

	  initializeForm: function initializeForm() {
	    this._createPanel();
	    this._fieldsets.forEach(function (fieldset) {
	      fieldset.initializeForm(this._form);
	    }.bind(this));
	  },

	  updatePreferences: function updatePreferences(event) {
	    event.preventDefault();
	    var new_options = {};
	    var saveable_options = {};
	    this._fieldsets.forEach(function (fieldset) {
	      // doUpdate = doUpdate || fieldset.updateForm(this._form, new_options);
	      // assign(new_options, fieldset.updateForm(this._form));
	      fieldset.updateForm(this._form, new_options, saveable_options);
	    }.bind(this));

	    if (this.options.hasFields) {
	      for (var i in this.options.fields) {
	        var field = this.options.fields[i];
	        var input = this._form.querySelector('input[name="x' + field.name + '"]:checked');
	        if (input.value != field.value) {
	          field.value = input.value;
	          field.callback(field.value);
	        }
	      }
	    }

	    this._modal.deactivate();

	    setTimeout(function () {
	      this._reader.saveOptions(saveable_options);
	      this._reader.reopen(new_options);
	    }.bind(this), 100);
	  },

	  EOT: true
	});

	Preferences.fieldset = {};

	var Fieldset = Class.extend({

	  options: {},

	  initialize: function initialize(control$$1, options) {
	    setOptions(this, options);
	    this._control = control$$1;
	    this._current = {};
	    this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
	  },

	  template: function template$$1() {},

	  EOT: true

	});

	Preferences.fieldset.TextSize = Fieldset.extend({

	  initializeForm: function initializeForm(form) {
	    if (!this._input) {
	      this._input = form.querySelector('#x' + this._id + '-input');
	      this._output = form.querySelector('#x' + this._id + '-output');
	      this._preview = form.querySelector('#x' + this._id + '-preview');
	      this._actionReset = form.querySelector('#x' + this._id + '-reset');

	      this._input.addEventListener('input', this._updatePreview.bind(this));
	      this._input.addEventListener('change', this._updatePreview.bind(this));

	      this._actionReset.addEventListener('click', function (event) {
	        event.preventDefault();
	        this._input.value = 100;
	        this._updatePreview();
	      }.bind(this));
	    }

	    var text_size = this._control._reader.options.text_size || 100;
	    if (text_size == 'auto') {
	      text_size = 100;
	    }
	    this._current.text_size = text_size;
	    this._input.value = text_size;
	    this._updatePreview();
	  },

	  updateForm: function updateForm(form, options, saveable) {
	    // return { text_size: this._input.value };
	    options.text_size = saveable.text_size = this._input.value;
	    // options.text_size = this._input.value;
	    // return ( this._input.value != this._current.text_size );
	  },

	  template: function template$$1() {
	    return '<fieldset class="cozy-fieldset-text_size">\n        <legend>Text Size</legend>\n        <div class="preview--text_size" id="x' + this._id + '-preview">\n          \u2018Yes, that\u2019s it,\u2019 said the Hatter with a sigh: \u2018it\u2019s always tea-time, and we\u2019ve no time to wash the things between whiles.\u2019\n        </div>\n        <p style="white-space: no-wrap">\n          <span>T-</span>\n          <input name="text_size" type="range" id="x' + this._id + '-input" value="100" min="50" max="400" step="10" aria-valuemin="50" aria-valuemax="400" style="width: 75%; display: inline-block" />\n          <span>T+</span>\n        </p>\n        <p>\n          <span>Text Size: </span>\n          <span id="x' + this._id + '-output">100</span>\n          <button id="x' + this._id + '-reset" class="reset button--inline" style="margin-left: 8px">Reset</button> \n        </p>\n      </fieldset>';
	  },

	  _updatePreview: function _updatePreview() {
	    this._preview.style.fontSize = parseInt(this._input.value, 10) / 100 + 'em';
	    this._output.innerHTML = this._input.value + '%';
	    this._input.setAttribute('aria-valuenow', '' + this._input.value);
	    this._input.setAttribute('aria-valuetext', this._input.value + ' percent');
	  },

	  EOT: true

	});

	Preferences.fieldset.Display = Fieldset.extend({

	  initializeForm: function initializeForm(form) {
	    var flow = this._control._reader.options.flow || this._control._reader.metadata.flow || 'auto';
	    // if ( flow == 'auto' ) { flow = 'paginated'; }

	    var input = form.querySelector('#x' + this._id + '-input-' + flow);
	    input.checked = true;
	    this._current.flow = flow;
	  },

	  updateForm: function updateForm(form, options, saveable) {
	    var input = form.querySelector('input[name="x' + this._id + '-flow"]:checked');
	    options.flow = input.value;
	    if (options.flow != 'auto') {
	      saveable.flow = options.flow;
	    }
	    // if ( input.value == 'auto' ) {
	    //   // we do NOT want to save flow as a preference
	    //   return {};
	    // }
	    // return { flow: input.value };
	  },

	  template: function template$$1() {
	    var scrolled_help = '';
	    if (this._control._reader.metadata.layout != 'pre-paginated') {
	      scrolled_help = "<br /><small>This is an experimental feature that may cause display and loading issues for the book when enabled.</small>";
	    }
	    return '<fieldset>\n            <legend>Display</legend>\n            <label><input name="x' + this._id + '-flow" type="radio" id="x' + this._id + '-input-auto" value="auto" /> Auto<br /><small>Let the reader determine display mode based on your browser dimensions and the type of content you\'re reading</small></label>\n            <label><input name="x' + this._id + '-flow" type="radio" id="x' + this._id + '-input-paginated" value="paginated" /> Page-by-Page</label>\n            <label><input name="x' + this._id + '-flow" type="radio" id="x' + this._id + '-input-scrolled-doc" value="scrolled-doc" /> Scroll' + scrolled_help + '</label>\n          </fieldset>';
	  },

	  EOT: true

	});

	Preferences.fieldset.Theme = Fieldset.extend({

	  initializeForm: function initializeForm(form) {
	    var theme = this._control._reader.options.theme || 'default';

	    var input = form.querySelector('#x' + this._id + '-input-theme-' + theme);
	    input.checked = true;
	    this._current.theme = theme;
	  },

	  updateForm: function updateForm(form, options, saveable) {
	    var input = form.querySelector('input[name="x' + this._id + '-theme"]:checked');
	    options.theme = saveable.theme = input.value;
	    // return { theme: input.value };
	  },

	  template: function template$$1() {
	    var template$$1 = '<fieldset>\n            <legend>Theme</legend>\n            <label><input name="x' + this._id + '-theme" type="radio" id="x' + this._id + '-input-theme-default" value="default" />Default</label>';

	    this._control._reader.options.themes.forEach(function (theme) {
	      template$$1 += '<label><input name="x' + this._id + '-theme" type="radio" id="x' + this._id + '-input-theme-' + theme.klass + '" value="' + theme.klass + '" />' + theme.name + '</label>';
	    }.bind(this));

	    template$$1 += '</fieldset>';

	    return template$$1;
	  },

	  EOT: true

	});

	Preferences.fieldset.Rendition = Fieldset.extend({

	  initializeForm: function initializeForm(form) {
	    var rootfiles = this._control._reader.rootfiles;
	    var rootfilePath = this._control._reader.options.rootfilePath;
	    var expr = rootfilePath ? '[value="' + rootfilePath + '"]' : ":first-child";
	    var input = form.querySelector('input[name="x' + this._id + '-rootfilePath"]' + expr);
	    input.checked = true;
	    this._current.rootfilePath = rootfilePath || rootfiles[0].rootfilePath;
	  },

	  updateForm: function updateForm(form, options, saveable) {
	    var input = form.querySelector('input[name="x' + this._id + '-rootfilePath"]:checked');
	    if (input.value != this._current.rootfilePath) {
	      options.rootfilePath = input.value;
	      this._current.rootfilePath = input.value;
	    }
	  },

	  template: function template$$1() {
	    var template$$1 = '<fieldset>\n            <legend>Rendition</legend>\n    ';

	    this._control._reader.rootfiles.forEach(function (rootfile, i) {
	      template$$1 += '<label><input name="x' + this._id + '-rootfilePath" type="radio" id="x' + this._id + '-input-rootfilePath-' + i + '" value="' + rootfile.rootfilePath + '" />' + (rootfile.label || rootfile.accessMode || rootfile.rootfilePath) + '</label>';
	    }.bind(this));

	    template$$1 += '</fieldset>';

	    return template$$1;
	  },

	  EOT: true

	});

	Preferences.fieldset.Scale = Fieldset.extend({

	  initializeForm: function initializeForm(form) {
	    if (!this._input) {
	      this._input = form.querySelector('#x' + this._id + '-input');
	      this._output = form.querySelector('#x' + this._id + '-output');
	      this._preview = form.querySelector('#x' + this._id + '-preview > div');
	      this._actionReset = form.querySelector('#x' + this._id + '-reset');

	      this._input.addEventListener('input', this._updatePreview.bind(this));
	      this._input.addEventListener('change', this._updatePreview.bind(this));

	      this._actionReset.addEventListener('click', function (event) {
	        event.preventDefault();
	        this._input.value = 100;
	        this._updatePreview();
	      }.bind(this));
	    }

	    var scale = this._control._reader.options.scale || 100;
	    if (!scale) {
	      scale = 100;
	    }
	    this._current.scale = scale;
	    this._input.value = scale;
	    this._updatePreview();
	  },

	  updateForm: function updateForm(form, options, saveable) {
	    // return { text_size: this._input.value };
	    options.scale = saveable.scale = this._input.value;
	    // options.text_size = this._input.value;
	    // return ( this._input.value != this._current.text_size );
	  },

	  template: function template$$1() {
	    return '<fieldset class="cozy-fieldset-text_size">\n        <legend>Zoom In/Out</legend>\n        <div class="preview--scale" id="x' + this._id + '-preview" style="overflow: hidden; height: 5rem">\n          <div>\n            \u2018Yes, that\u2019s it,\u2019 said the Hatter with a sigh: \u2018it\u2019s always tea-time, and we\u2019ve no time to wash the things between whiles.\u2019\n          </div>\n        </div>\n        <p style="white-space: no-wrap">\n          <span style="font-size: 150%">\u2296<span class="u-screenreader"> Zoom Out</span></span>\n          <input name="scale" type="range" id="x' + this._id + '-input" value="100" min="50" max="400" step="10" style="width: 75%; display: inline-block" />\n          <span style="font-size: 150%">\u2295<span class="u-screenreader">Zoom In </span></span>\n        </p>\n        <p>\n          <span>Scale: </span>\n          <span id="x' + this._id + '-output">100</span>\n          <button id="x' + this._id + '-reset" class="reset button--inline" style="margin-left: 8px">Reset</button> \n        </p>\n      </fieldset>';
	  },

	  _updatePreview: function _updatePreview() {
	    this._preview.style.transform = 'scale(' + parseInt(this._input.value, 10) / 100 + ') translate(0,0)';
	    this._output.innerHTML = this._input.value + '%';
	  },

	  EOT: true

	});

	var preferences = function preferences(options) {
	  return new Preferences(options);
	};

	var Widget = Control.extend({

	  options: {
	    // @option region: String = 'topright'
	    // The region of the control (one of the reader corners). Possible values are `'topleft'`,
	    // `'topright'`, `'bottomleft'` or `'bottomright'`
	  },

	  onAdd: function onAdd(reader) {
	    var container = this._container;
	    if (container) ; else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;
	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._onAddExtra(container);
	    this._updateTemplate(container);
	    this._updateClass(container);
	    this._bindEvents(container);

	    return container;
	  },

	  _updateTemplate: function _updateTemplate(container) {
	    var data = this.data();
	    for (var slot in data) {
	      if (data.hasOwnProperty(slot)) {
	        var value = data[slot];
	        if (typeof value == "function") {
	          value = value();
	        }
	        var node = container.querySelector('[data-slot=' + slot + ']');
	        if (node) {
	          if (node.hasAttribute('value')) {
	            node.setAttribute('value', value);
	          } else {
	            node.innerHTML = value;
	          }
	        }
	      }
	    }
	  },

	  _updateClass: function _updateClass(container) {
	    if (this.options.className) {
	      addClass(container, this.options.className);
	    }
	  },

	  _onAddExtra: function _onAddExtra() {},

	  _bindEvents: function _bindEvents(container) {
	    var control$$1 = container.querySelector("[data-toggle=button]");
	    if (!control$$1) {
	      return;
	    }
	    disableClickPropagation(control$$1);
	    on(control$$1, 'click', stop);
	    on(control$$1, 'click', this._action, this);
	  },

	  _action: function _action() {},

	  data: function data() {
	    return this.options.data || {};
	  },

	  EOT: true
	});

	Widget.Button = Widget.extend({
	  defaultTemplate: '<button data-toggle="button" data-slot="label"></button>',

	  _action: function _action() {
	    this.options.onClick(this, this._reader);
	  },

	  EOT: true
	});

	Widget.Panel = Widget.extend({
	  defaultTemplate: '<div><span data-slot="text"></span></div>',

	  EOT: true
	});

	Widget.Toggle = Widget.extend({
	  defaultTemplate: '<button data-toggle="button" data-slot="label"></button>',

	  _onAddExtra: function _onAddExtra(container) {
	    this.state(this.options.states[0].stateName, container);

	    return container;
	  },

	  state: function state(stateName, container) {
	    container = container || this._container;
	    this._resetState(container);
	    this._state = this.options.states.filter(function (s) {
	      return s.stateName == stateName;
	    })[0];
	    this._updateClass(container);
	    this._updateTemplate(container);
	  },

	  _resetState: function _resetState(container) {
	    if (!this._state) {
	      return;
	    }
	    if (this._state.className) {
	      removeClass(container, this._state.className);
	    }
	  },

	  _updateClass: function _updateClass(container) {
	    if (this._state.className) {
	      addClass(container, this._state.className);
	    }
	  },

	  _action: function _action() {
	    this._state.onClick(this, this._reader);
	  },

	  data: function data() {
	    return this._state.data || {};
	  },

	  EOT: true
	});

	// export var widget = function(options) {
	//   return new Widget(options);
	// }

	var widget = {
	  button: function button(options) {
	    return new Widget.Button(options);
	  },
	  panel: function panel(options) {
	    return new Widget.Panel(options);
	  },
	  toggle: function toggle(options) {
	    return new Widget.Toggle(options);
	  }
	};

	var Citation = Control.extend({
	  options: {
	    label: 'Citation',
	    html: '<span class="citation" aria-label="Get Citation"></span>'
	  },

	  defaultTemplate: '<button class="button--sm cozy-citation citation" data-toggle="open" aria-label="Get Citation"></button>',

	  onAdd: function onAdd(reader) {
	    var self = this;
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;

	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._reader.on('updateContents', function (data) {
	      self._createPanel();
	    });

	    this._control = container.querySelector("[data-toggle=open]");
	    on(this._control, 'click', function (event) {
	      event.preventDefault();
	      self._modal.activate();
	    }, this);

	    return container;
	  },

	  _action: function _action() {
	    var self = this;
	    self._modal.activate();
	  },

	  _createButton: function _createButton(html, title, className, container, fn) {
	    var link = create$1('button', className, container);
	    link.innerHTML = html;
	    link.title = title;

	    link.setAttribute('role', 'button');
	    link.setAttribute('aria-label', title);

	    disableClickPropagation(link);
	    on(link, 'click', stop);
	    on(link, 'click', fn, this);

	    return link;
	  },

	  _createPanel: function _createPanel() {
	    var self = this;

	    var template = '<form>\n      <fieldset>\n        <legend>Select Citation Format</legend>\n      </fieldset>\n    </form>\n    <blockquote id="formatted" style="padding: 8px; border-left: 4px solid black; background-color: #fff"></blockquote>\n    <div class="alert alert-info" id="message" style="display: none"></div>';

	    this._modal = this._reader.modal({
	      template: template,
	      title: 'Copy Citation to Clipboard',
	      className: 'cozy-modal-citation',
	      actions: [{
	        label: 'Copy Citation',
	        callback: function callback(event) {
	          document.designMode = "on";
	          var formatted = self._modal._container.querySelector("#formatted");

	          var range = document.createRange();
	          range.selectNode(formatted);
	          var sel = window.getSelection();
	          sel.removeAllRanges();
	          sel.addRange(range);

	          // formatted.select();

	          try {
	            var flag = document.execCommand('copy');
	          } catch (err) {
	            console.log("AHOY COPY FAILED", err);
	          }

	          self._message.innerHTML = 'Success! Citation copied to your clipboard.';
	          self._message.style.display = 'block';
	          sel.removeAllRanges();
	          range.detach();
	          document.designMode = "off";
	        }
	      }],
	      region: 'left',
	      fraction: 1.0
	    });

	    this._form = this._modal._container.querySelector('form');
	    var fieldset = this._form.querySelector('fieldset');

	    var citations = this.options.citations || this._reader.metadata.citations;

	    citations.forEach(function (citation, index) {
	      var label = create$1('label', null, fieldset);
	      var input = create$1('input', null, label);
	      input.setAttribute('name', 'format');
	      input.setAttribute('value', citation.format);
	      input.setAttribute('type', 'radio');
	      if (index == 0) {
	        input.setAttribute('checked', 'checked');
	      }
	      var text = document.createTextNode(" " + citation.format);
	      label.appendChild(text);
	      input.setAttribute('data-text', citation.text);
	    });

	    this._formatted = this._modal._container.querySelector("#formatted");
	    this._message = this._modal._container.querySelector("#message");
	    on(this._form, 'change', function (event) {
	      var target = event.target;
	      if (target.tagName == 'INPUT') {
	        this._initializeForm();
	      }
	    }, this);

	    this._initializeForm();
	  },

	  _initializeForm: function _initializeForm() {
	    var formatted = this._formatCitation();
	    this._formatted.innerHTML = formatted;
	    this._message.style.display = 'none';
	    this._message.innerHTML = '';
	  },

	  _formatCitation: function _formatCitation(format) {
	    if (format == null) {
	      var selected = this._form.querySelector("input:checked");
	      format = selected.value;
	    }
	    var selected = this._form.querySelector("input[value=" + format + "]");
	    return selected.getAttribute('data-text');
	    // return selected.dataset.text;
	  },

	  EOT: true
	});

	var citation = function citation(options) {
	  return new Citation(options);
	};

	var Search = Control.extend({
	  options: {
	    label: 'Search',
	    html: '<span>Search</span>'
	  },

	  defaultTemplate: '<form class="search">\n    <label class="u-screenreader" for="cozy-search-string">Search in this text</label>\n    <input id="cozy-search-string" name="search" type="text" placeholder="Search in this text..."/>\n    <button class="button--sm" data-toggle="open" aria-label="Search"><i class="icon-magnifying-glass oi" data-glyph="magnifying-glass" title="Search" aria-hidden="true"></i></button>\n  </form>',

	  onAdd: function onAdd(reader) {
	    var self = this;
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;

	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._control = container.querySelector("[data-toggle=open]");
	    container.style.position = 'relative';

	    this._data = null;
	    this._canceled = false;
	    this._processing = false;

	    this._reader.on('ready', function () {

	      this._modal = this._reader.modal({
	        template: '<article></article>',
	        title: 'Search Results',
	        className: { container: 'cozy-modal-search' },
	        region: 'left'
	      });

	      this._modal.callbacks.onClose = function () {
	        if (self._processing) {
	          self._canceled = true;
	        }
	      };

	      this._article = this._modal._container.querySelector('article');

	      this._modal.on('click', 'a[href]', function (modal, target) {
	        target = target.getAttribute('href');
	        this._reader.tracking.action('search/go/link');
	        this._reader.gotoPage(target);
	        return true;
	      }.bind(this));

	      this._modal.on('closed', function () {
	        this._reader.tracking.action('contents/close');
	      }.bind(this));
	    }.bind(this));

	    on(this._control, 'click', function (event) {
	      event.preventDefault();

	      var searchString = this._container.querySelector("#cozy-search-string").value;
	      searchString = searchString.replace(/^\s*/, '').replace(/\s*$/, '');

	      if (!searchString) {
	        // just punt
	        return;
	      }

	      if (searchString == this.searchString) {
	        // cached results
	        self.openModalResults();
	      } else {
	        this.searchString = searchString;
	        self.openModalWaiting();
	        self.submitQuery();
	      }
	    }, this);

	    return container;
	  },

	  openModalWaiting: function openModalWaiting() {
	    this._processing = true;
	    this._emptyArticle();
	    var value = this.searchString;
	    this._article.innerHTML = '<p>Submitting query for <em>' + value + '</em>...</p>' + this._reader.loaderTemplate();
	    this._modal.activate();
	  },

	  openModalResults: function openModalResults() {
	    if (this._canceled) {
	      this._canceled = false;
	      return;
	    }
	    this._buildResults();
	    this._modal.activate();
	    this._reader.tracking.action("search/open");
	  },

	  submitQuery: function submitQuery() {
	    var self = this;

	    var url = this.options.searchUrl + encodeURIComponent(this.searchString);

	    var request = new XMLHttpRequest();
	    request.open('GET', url, true);

	    request.onload = function () {
	      if (this.status >= 200 && this.status < 400) {
	        // Success!
	        var data = JSON.parse(this.response);
	        console.log("SEARCH DATA", data);

	        self._data = data;
	      } else {
	        // We reached our target server, but it returned an error

	        self._data = null;
	        console.log(this.response);
	      }

	      self._reader.tracking.action("search/submitQuery");
	      self.openModalResults();
	    };

	    request.onerror = function () {
	      // There was a connection error of some sort
	      self._data = null;
	      self.openModalResults();
	    };

	    request.send();
	  },

	  _emptyArticle: function _emptyArticle() {
	    while (this._article && this._article.hasChildNodes()) {
	      this._article.removeChild(this._article.lastChild);
	    }
	  },

	  _buildResults: function _buildResults() {
	    var self = this;
	    var content;

	    this._processing = false;

	    self._emptyArticle();

	    var reader = this._reader;
	    reader.annotations.reset();

	    if (this._data) {
	      var highlight = true;
	      if (this._data.highlight_off == "yes") {
	        highlight = false;
	      }
	      if (this._data.search_results.length) {
	        content = create$1('ul');

	        this._data.search_results.forEach(function (result) {
	          var option = create$1('li');
	          var anchor = create$1('a', null, option);
	          var cfiRange = "epubcfi(" + result.cfi + ")";

	          if (result.snippet) {
	            if (result.title) {
	              var chapterTitle = create$1('i');
	              chapterTitle.textContent = result.title + ": ";
	              anchor.appendChild(chapterTitle);
	            }
	            anchor.appendChild(document.createTextNode(result.snippet));

	            anchor.setAttribute("href", cfiRange);
	            content.appendChild(option);
	          }
	          if (highlight) {
	            reader.annotations.highlight(cfiRange, {}, null, 'epubjs-search-hl');
	          }
	        });
	      } else {
	        content = create$1("p");
	        content.textContent = 'No results found for "' + self.searchString + '"';
	      }
	    } else {
	      content = create$1("p");
	      content.textContent = 'There was a problem processing this query.';
	    }

	    self._article.appendChild(content);
	  },

	  EOT: true
	});

	var search = function search(options) {
	  return new Search(options);
	};

	// Title + Chapter

	var BibliographicInformation = Control.extend({
	  options: {
	    label: 'Info',
	    direction: 'left',
	    html: '<span class="oi" data-glyph="info">Info</span>'
	  },

	  defaultTemplate: '<button class="button--sm cozy-bib-info oi" data-glyph="info" data-toggle="open" aria-label="Bibliographic Information"> Info</button>',

	  onAdd: function onAdd(reader) {
	    var self = this;
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;

	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._reader.on('updateContents', function (data) {
	      self._createPanel();
	    });

	    this._control = container.querySelector("[data-toggle=open]");
	    on(this._control, 'click', function (event) {
	      event.preventDefault();
	      self._modal.activate();
	    }, this);

	    return container;
	  },

	  _createPanel: function _createPanel() {

	    var template = '<dl>\n    </dl>';

	    this._modal = this._reader.modal({
	      template: template,
	      title: 'Info',
	      region: 'left',
	      fraction: 1.0
	    });

	    var dl = this._modal._container.querySelector('dl');

	    var metadata_fields = [['title', 'Title'], ['creator', 'Author'], ['pubdate', 'Publication Date'], ['modified_date', 'Modified Date'], ['publisher', 'Publisher'], ['rights', 'Rights'], ['doi', 'DOI'], ['description', 'Description']];

	    var metadata = this._reader.metadata;

	    for (var idx in metadata_fields) {
	      var key = metadata_fields[idx][0];
	      var label = metadata_fields[idx][1];
	      if (metadata[key]) {
	        var value = metadata[key];
	        if (key == 'pubdate' || key == 'modified_date') {
	          value = this._formatDate(value);
	          if (!value) {
	            continue;
	          }
	          // value = d.toISOString().slice(0,10); // for YYYY-MM-DD
	        }
	        var dt = create$1('dt', 'cozy-bib-info-label', dl);
	        dt.innerHTML = label;
	        var dd = create$1('dd', 'cozy-bib-info-value cozy-bib-info-value-' + key, dl);
	        dd.innerHTML = value;
	      }
	    }
	  },

	  _formatDate: function _formatDate(value) {
	    var match = value.match(/\d{4}/);
	    if (match) {
	      return match[0];
	    }
	    return null;
	  },

	  EOT: true
	});

	var bibliographicInformation = function bibliographicInformation(options) {
	  return new BibliographicInformation(options);
	};

	var Download = Control.extend({
	  options: {
	    label: 'Download Book',
	    html: '<span>Download Book</span>'
	  },

	  defaultTemplate: '<button class="button--sm cozy-download oi" data-toggle="open" data-glyph="data-transfer-download"> Download Book</button>',

	  onAdd: function onAdd(reader) {
	    var self = this;
	    var container = this._container;
	    if (container) {
	      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
	    } else {

	      var className = this._className(),
	          options = this.options;

	      container = create$1('div', className);

	      var template = this.options.template || this.defaultTemplate;

	      var body = new DOMParser().parseFromString(template, "text/html").body;
	      while (body.children.length) {
	        container.appendChild(body.children[0]);
	      }
	    }

	    this._reader.on('updateContents', function (data) {
	      self._createPanel();
	    });

	    this._control = container.querySelector("[data-toggle=open]");
	    on(this._control, 'click', function (event) {
	      event.preventDefault();
	      self._modal.activate();
	    }, this);

	    return container;
	  },

	  _createPanel: function _createPanel() {
	    var self = this;

	    var template = '<form>\n      <fieldset>\n        <legend>Choose File Format</legend>\n      </fieldset>\n    </form>';

	    this._modal = this._reader.modal({
	      template: template,
	      title: 'Download Book',
	      className: 'cozy-modal-download',
	      actions: [{
	        label: 'Download',
	        callback: function callback(event) {
	          var selected = self._form.querySelector("input:checked");
	          var href = selected.getAttribute('data-href');
	          self._configureDownloadForm(href);
	          self._form.submit();
	        }
	      }],
	      region: 'left',
	      fraction: 1.0
	    });

	    this._form = this._modal._container.querySelector('form');
	    var fieldset = this._form.querySelector('fieldset');
	    this._reader.options.download_links.forEach(function (link, index) {
	      var label = create$1('label', null, fieldset);
	      var input = create$1('input', null, label);
	      input.setAttribute('name', 'format');
	      input.setAttribute('value', link.format);
	      input.setAttribute('data-href', link.href);
	      input.setAttribute('type', 'radio');
	      if (index == 0) {
	        input.setAttribute('checked', 'checked');
	      }
	      var text = link.format;
	      if (link.size) {
	        text += " (" + link.size + ")";
	      }
	      var text = document.createTextNode(" " + text);
	      label.appendChild(text);
	    });
	  },

	  _configureDownloadForm: function _configureDownloadForm(href) {
	    var self = this;
	    self._form.setAttribute('method', 'GET');
	    self._form.setAttribute('action', href);
	    self._form.setAttribute('target', '_blank');
	  },

	  EOT: true
	});

	var download = function download(options) {
	  return new Download(options);
	};

	var Navigator = Control.extend({
	  onAdd: function onAdd(reader) {
	    var container = this._container;
	    if (container) ; else {

	      var className = this._className('navigator'),
	          options = this.options;

	      container = create$1('div', className);
	    }
	    this._setup(container);

	    this._reader.on('updateLocations', function (locations) {
	      // if ( ! this._reader.currentLocation() || ! this._reader.currentLocation().start ) {
	      //   console.log("AHOY updateLocations NO START", this._reader.currentLocation().then);
	      //   setTimeout(function() {
	      //     this._initializeNavigator(locations);
	      //   }.bind(this), 100);
	      //   return;
	      // }
	      this._initializeNavigator(locations);
	    }.bind(this));

	    return container;
	  },

	  _setup: function _setup(container) {
	    this._control = container.querySelector("input[type=range]");
	    if (!this._control) {
	      this._createControl(container);
	    }
	    this._background = container.querySelector(".cozy-navigator-range__background");
	    this._status = container.querySelector(".cozy-navigator-range__status");
	    this._spanCurrentPercentage = container.querySelector(".currentPercentage");
	    this._spanCurrentLocation = container.querySelector(".currentLocation");
	    this._spanTotalLocations = container.querySelector(".totalLocations");

	    this._bindEvents();
	  },

	  _createControl: function _createControl(container) {
	    var template = '<div class="cozy-navigator-range">\n        <label class="u-screenreader" for="cozy-navigator-range-input">Location: </label>\n        <input class="cozy-navigator-range__input" id="cozy-navigator-range-input" type="range" name="locations-range-value" min="0" max="100" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" aria-valuetext="0% \u2022\xA0Location 0 of ?" value="0" data-background-position="0" />\n        <div class="cozy-navigator-range__background"></div>\n      </div>\n      <div class="cozy-navigator-range__status"><span class="currentPercentage">0%</span> \u2022 Location <span class="currentLocation">0</span> of <span class="totalLocations">?</span></div>\n    ';

	    var body = new DOMParser().parseFromString(template, "text/html").body;
	    while (body.children.length) {
	      container.appendChild(body.children[0]);
	    }

	    this._control = container.querySelector("input[type=range]");
	  },

	  _bindEvents: function _bindEvents() {
	    var self = this;

	    this._control.addEventListener("input", function () {
	      self._update();
	    }, false);
	    this._control.addEventListener("change", function () {
	      self._action();
	    }, false);
	    this._control.addEventListener("mousedown", function () {
	      self._mouseDown = true;
	    }, false);
	    this._control.addEventListener("mouseup", function () {
	      self._mouseDown = false;
	    }, false);
	    this._control.addEventListener("keydown", function () {
	      self._mouseDown = true;
	    }, false);
	    this._control.addEventListener("keyup", function () {
	      self._mouseDown = false;
	    }, false);

	    this._reader.on('relocated', function (location) {
	      if (!self._initiated) {
	        return;
	      }
	      if (!self._mouseDown) {
	        self._control.value = Math.ceil(self._reader.locations.percentageFromCfi(self._reader.currentLocation().start.cfi) * 100);
	        self._update();
	      }
	    });
	  },

	  _action: function _action() {
	    var value = this._control.value;
	    var locations = this._reader.locations;
	    var cfi = locations.cfiFromPercentage(value / 100);
	    this._reader.tracking.action("navigator/go");
	    this._reader.gotoPage(cfi);
	  },

	  _update: function _update() {
	    var self = this;

	    var current = this._reader.currentLocation();
	    if (!current || !current.start) {
	      setTimeout(function () {
	        this._update();
	      }.bind(this), 100);
	    }

	    var rangeBg = this._background;
	    var range = self._control;

	    var value = parseInt(range.value, 10);
	    var percentage = value;

	    rangeBg.setAttribute('style', 'background-position: ' + -percentage + '% 0%, left top;');
	    self._control.setAttribute('data-background-position', Math.ceil(percentage));

	    this._spanCurrentPercentage.innerHTML = percentage + '%';
	    if (current && current.start) {
	      var current_location = this._reader.locations.locationFromCfi(current.start.cfi);
	      this._spanCurrentLocation.innerHTML = current_location;
	    }
	    self._last_delta = self._last_value > value;self._last_value = value;
	  },

	  _initializeNavigator: function _initializeNavigator(locations) {
	    console.log("AHOY updateLocations PROCESSING LOCATION");
	    this._initiated = true;
	    this._total = this._reader.locations.total;
	    if (this._reader.currentLocation() && this._reader.currentLocation().start) {
	      this._control.value = Math.ceil(this._reader.locations.percentageFromCfi(this._reader.currentLocation().start.cfi) * 100);
	      this._last_value = this._control.value;
	    } else {
	      this._last_value = this._control.value;
	    }

	    this._spanTotalLocations.innerHTML = this._total;

	    this._update();
	    setTimeout(function () {
	      addClass(this._container, 'initialized');
	    }.bind(this), 0);
	  },

	  EOT: true
	});

	var navigator$1 = function navigator(options) {
	  return new Navigator(options);
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

	Control.Citation = Citation;
	control.citation = citation;

	Control.Search = Search;
	control.search = search;

	Control.BibliographicInformation = BibliographicInformation;
	control.bibliographicInformation = bibliographicInformation;

	Control.Download = Download;
	control.download = download;

	Control.Navigator = Navigator;
	control.navigator = navigator$1;

	var Bus = Evented.extend({});

	var instance;
	var bus = function bus() {
	  return instance || (instance = new Bus());
	};

	var Mixin = { Events: Evented.prototype };

	var isImplemented = function () {
		var assign = Object.assign,
		    obj;
		if (typeof assign !== "function") return false;
		obj = { foo: "raz" };
		assign(obj, { bar: "dwa" }, { trzy: "trzy" });
		return obj.foo + obj.bar + obj.trzy === "razdwatrzy";
	};

	var isImplemented$1 = function () {
		try {
			return true;
		} catch (e) {
			return false;
		}
	};

	// eslint-disable-next-line no-empty-function

	var noop = function () {};

	var _undefined = noop(); // Support ES3 engines

	var isValue = function (val) {
	  return val !== _undefined && val !== null;
	};

	var keys$1 = Object.keys;

	var shim = function (object) {
		return keys$1(isValue(object) ? Object(object) : object);
	};

	var keys$2 = isImplemented$1() ? Object.keys : shim;

	var validValue = function (value) {
		if (!isValue(value)) throw new TypeError("Cannot use null or undefined");
		return value;
	};

	var max = Math.max;

	var shim$1 = function (dest, src /*, …srcn*/) {
		var error,
		    i,
		    length = max(arguments.length, 2),
		    assign;
		dest = Object(validValue(dest));
		assign = function assign(key) {
			try {
				dest[key] = src[key];
			} catch (e) {
				if (!error) error = e;
			}
		};
		for (i = 1; i < length; ++i) {
			src = arguments[i];
			keys$2(src).forEach(assign);
		}
		if (error !== undefined) throw error;
		return dest;
	};

	var assign$1 = isImplemented() ? Object.assign : shim$1;

	var forEach = Array.prototype.forEach,
	    create$2 = Object.create;

	var process = function process(src, obj) {
		var key;
		for (key in src) {
			obj[key] = src[key];
		}
	};

	// eslint-disable-next-line no-unused-vars
	var normalizeOptions = function (opts1 /*, …options*/) {
		var result = create$2(null);
		forEach.call(arguments, function (options) {
			if (!isValue(options)) return;
			process(Object(options), result);
		});
		return result;
	};

	// Deprecated

	var isCallable = function (obj) {
	  return typeof obj === "function";
	};

	var str = "razdwatrzy";

	var isImplemented$2 = function () {
		if (typeof str.contains !== "function") return false;
		return str.contains("dwa") === true && str.contains("foo") === false;
	};

	var indexOf$1 = String.prototype.indexOf;

	var shim$2 = function (searchString /*, position*/) {
		return indexOf$1.call(this, searchString, arguments[1]) > -1;
	};

	var contains = isImplemented$2() ? String.prototype.contains : shim$2;

	var d_1 = createCommonjsModule(function (module) {

	var d;

	d = module.exports = function (dscr, value /*, options*/) {
		var c, e, w, options, desc;
		if (arguments.length < 2 || typeof dscr !== 'string') {
			options = value;
			value = dscr;
			dscr = null;
		} else {
			options = arguments[2];
		}
		if (dscr == null) {
			c = w = true;
			e = false;
		} else {
			c = contains.call(dscr, 'c');
			e = contains.call(dscr, 'e');
			w = contains.call(dscr, 'w');
		}

		desc = { value: value, configurable: c, enumerable: e, writable: w };
		return !options ? desc : assign$1(normalizeOptions(options), desc);
	};

	d.gs = function (dscr, get, set /*, options*/) {
		var c, e, options, desc;
		if (typeof dscr !== 'string') {
			options = set;
			set = get;
			get = dscr;
			dscr = null;
		} else {
			options = arguments[3];
		}
		if (get == null) {
			get = undefined;
		} else if (!isCallable(get)) {
			options = get;
			get = set = undefined;
		} else if (set == null) {
			set = undefined;
		} else if (!isCallable(set)) {
			options = set;
			set = undefined;
		}
		if (dscr == null) {
			c = true;
			e = false;
		} else {
			c = contains.call(dscr, 'c');
			e = contains.call(dscr, 'e');
		}

		desc = { get: get, set: set, configurable: c, enumerable: e };
		return !options ? desc : assign$1(normalizeOptions(options), desc);
	};
	});

	var validCallable = function (fn) {
		if (typeof fn !== "function") throw new TypeError(fn + " is not a function");
		return fn;
	};

	var eventEmitter = createCommonjsModule(function (module, exports) {

	var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	var apply = Function.prototype.apply,
	    call = Function.prototype.call,
	    create = Object.create,
	    defineProperty = Object.defineProperty,
	    defineProperties = Object.defineProperties,
	    hasOwnProperty = Object.prototype.hasOwnProperty,
	    descriptor = { configurable: true, enumerable: false, writable: true },
	    on,
	    _once2,
	    off,
	    emit,
	    methods,
	    descriptors,
	    base;

	on = function on(type, listener) {
		var data;

		validCallable(listener);

		if (!hasOwnProperty.call(this, '__ee__')) {
			data = descriptor.value = create(null);
			defineProperty(this, '__ee__', descriptor);
			descriptor.value = null;
		} else {
			data = this.__ee__;
		}
		if (!data[type]) data[type] = listener;else if (_typeof(data[type]) === 'object') data[type].push(listener);else data[type] = [data[type], listener];

		return this;
	};

	_once2 = function once(type, listener) {
		var _once, self;

		validCallable(listener);
		self = this;
		on.call(this, type, _once = function once() {
			off.call(self, type, _once);
			apply.call(listener, this, arguments);
		});

		_once.__eeOnceListener__ = listener;
		return this;
	};

	off = function off(type, listener) {
		var data, listeners, candidate, i;

		validCallable(listener);

		if (!hasOwnProperty.call(this, '__ee__')) return this;
		data = this.__ee__;
		if (!data[type]) return this;
		listeners = data[type];

		if ((typeof listeners === 'undefined' ? 'undefined' : _typeof(listeners)) === 'object') {
			for (i = 0; candidate = listeners[i]; ++i) {
				if (candidate === listener || candidate.__eeOnceListener__ === listener) {
					if (listeners.length === 2) data[type] = listeners[i ? 0 : 1];else listeners.splice(i, 1);
				}
			}
		} else {
			if (listeners === listener || listeners.__eeOnceListener__ === listener) {
				delete data[type];
			}
		}

		return this;
	};

	emit = function emit(type) {
		var i, l, listener, listeners, args;

		if (!hasOwnProperty.call(this, '__ee__')) return;
		listeners = this.__ee__[type];
		if (!listeners) return;

		if ((typeof listeners === 'undefined' ? 'undefined' : _typeof(listeners)) === 'object') {
			l = arguments.length;
			args = new Array(l - 1);
			for (i = 1; i < l; ++i) {
				args[i - 1] = arguments[i];
			}listeners = listeners.slice();
			for (i = 0; listener = listeners[i]; ++i) {
				apply.call(listener, this, args);
			}
		} else {
			switch (arguments.length) {
				case 1:
					call.call(listeners, this);
					break;
				case 2:
					call.call(listeners, this, arguments[1]);
					break;
				case 3:
					call.call(listeners, this, arguments[1], arguments[2]);
					break;
				default:
					l = arguments.length;
					args = new Array(l - 1);
					for (i = 1; i < l; ++i) {
						args[i - 1] = arguments[i];
					}
					apply.call(listeners, this, args);
			}
		}
	};

	methods = {
		on: on,
		once: _once2,
		off: off,
		emit: emit
	};

	descriptors = {
		on: d_1(on),
		once: d_1(_once2),
		off: d_1(off),
		emit: d_1(emit)
	};

	base = defineProperties({}, descriptors);

	module.exports = exports = function exports(o) {
		return o == null ? create(base) : defineProperties(Object(o), descriptors);
	};
	exports.methods = methods;
	});
	var eventEmitter_1 = eventEmitter.methods;

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Core Utilities and Helpers
	 * @module Core
	*/

	/**
	 * Vendor prefixed requestAnimationFrame
	 * @returns {function} requestAnimationFrame
	 * @memberof Core
	 */
	var requestAnimationFrame$1 = typeof window != "undefined" ? window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame : false;
	var ELEMENT_NODE = 1;
	var TEXT_NODE = 3;
	var _URL = typeof URL != "undefined" ? URL : typeof window != "undefined" ? window.URL || window.webkitURL || window.mozURL : undefined;

	/**
	 * Generates a UUID
	 * based on: http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
	 * @returns {string} uuid
	 * @memberof Core
	 */
	function uuid() {
		var d = new Date().getTime();
		var uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
			var r = (d + Math.random() * 16) % 16 | 0;
			d = Math.floor(d / 16);
			return (c == "x" ? r : r & 0x7 | 0x8).toString(16);
		});
		return uuid;
	}

	/**
	 * Gets the height of a document
	 * @returns {number} height
	 * @memberof Core
	 */
	function documentHeight() {
		return Math.max(document.documentElement.clientHeight, document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight, document.documentElement.offsetHeight);
	}

	/**
	 * Checks if a node is an element
	 * @param {object} obj
	 * @returns {boolean}
	 * @memberof Core
	 */
	function isElement(obj) {
		return !!(obj && obj.nodeType == 1);
	}

	/**
	 * @param {any} n
	 * @returns {boolean}
	 * @memberof Core
	 */
	function isNumber(n) {
		return !isNaN(parseFloat(n)) && isFinite(n);
	}

	/**
	 * @param {any} n
	 * @returns {boolean}
	 * @memberof Core
	 */
	function isFloat(n) {
		var f = parseFloat(n);

		if (isNumber(n) === false) {
			return false;
		}

		if (typeof n === "string" && n.indexOf(".") > -1) {
			return true;
		}

		return Math.floor(f) !== f;
	}

	/**
	 * Get a prefixed css property
	 * @param {string} unprefixed
	 * @returns {string}
	 * @memberof Core
	 */
	function prefixed(unprefixed) {
		var vendors = ["Webkit", "webkit", "Moz", "O", "ms"];
		var prefixes = ["-webkit-", "-webkit-", "-moz-", "-o-", "-ms-"];
		var upper = unprefixed[0].toUpperCase() + unprefixed.slice(1);
		var length = vendors.length;

		if (typeof document === "undefined" || typeof document.body.style[unprefixed] != "undefined") {
			return unprefixed;
		}

		for (var i = 0; i < length; i++) {
			if (typeof document.body.style[vendors[i] + upper] != "undefined") {
				return prefixes[i] + unprefixed;
			}
		}

		return unprefixed;
	}

	/**
	 * Apply defaults to an object
	 * @param {object} obj
	 * @returns {object}
	 * @memberof Core
	 */
	function defaults(obj) {
		for (var i = 1, length = arguments.length; i < length; i++) {
			var source = arguments[i];
			for (var prop in source) {
				if (obj[prop] === void 0) obj[prop] = source[prop];
			}
		}
		return obj;
	}

	/**
	 * Extend properties of an object
	 * @param {object} target
	 * @returns {object}
	 * @memberof Core
	 */
	function extend$1(target) {
		var sources = [].slice.call(arguments, 1);
		sources.forEach(function (source) {
			if (!source) return;
			Object.getOwnPropertyNames(source).forEach(function (propName) {
				Object.defineProperty(target, propName, Object.getOwnPropertyDescriptor(source, propName));
			});
		});
		return target;
	}

	/**
	 * Fast quicksort insert for sorted array -- based on:
	 *  http://stackoverflow.com/questions/1344500/efficient-way-to-insert-a-number-into-a-sorted-array-of-numbers
	 * @param {any} item
	 * @param {array} array
	 * @param {function} [compareFunction]
	 * @returns {number} location (in array)
	 * @memberof Core
	 */
	function insert(item, array, compareFunction) {
		var location = locationOf(item, array, compareFunction);
		array.splice(location, 0, item);

		return location;
	}

	/**
	 * Finds where something would fit into a sorted array
	 * @param {any} item
	 * @param {array} array
	 * @param {function} [compareFunction]
	 * @param {function} [_start]
	 * @param {function} [_end]
	 * @returns {number} location (in array)
	 * @memberof Core
	 */
	function locationOf(item, array, compareFunction, _start, _end) {
		var start = _start || 0;
		var end = _end || array.length;
		var pivot = parseInt(start + (end - start) / 2);
		var compared;
		if (!compareFunction) {
			compareFunction = function compareFunction(a, b) {
				if (a > b) return 1;
				if (a < b) return -1;
				if (a == b) return 0;
			};
		}
		if (end - start <= 0) {
			return pivot;
		}

		compared = compareFunction(array[pivot], item);
		if (end - start === 1) {
			return compared >= 0 ? pivot : pivot + 1;
		}
		if (compared === 0) {
			return pivot;
		}
		if (compared === -1) {
			return locationOf(item, array, compareFunction, pivot, end);
		} else {
			return locationOf(item, array, compareFunction, start, pivot);
		}
	}

	/**
	 * Finds index of something in a sorted array
	 * Returns -1 if not found
	 * @param {any} item
	 * @param {array} array
	 * @param {function} [compareFunction]
	 * @param {function} [_start]
	 * @param {function} [_end]
	 * @returns {number} index (in array) or -1
	 * @memberof Core
	 */
	function indexOfSorted(item, array, compareFunction, _start, _end) {
		var start = _start || 0;
		var end = _end || array.length;
		var pivot = parseInt(start + (end - start) / 2);
		var compared;
		if (!compareFunction) {
			compareFunction = function compareFunction(a, b) {
				if (a > b) return 1;
				if (a < b) return -1;
				if (a == b) return 0;
			};
		}
		if (end - start <= 0) {
			return -1; // Not found
		}

		compared = compareFunction(array[pivot], item);
		if (end - start === 1) {
			return compared === 0 ? pivot : -1;
		}
		if (compared === 0) {
			return pivot; // Found
		}
		if (compared === -1) {
			return indexOfSorted(item, array, compareFunction, pivot, end);
		} else {
			return indexOfSorted(item, array, compareFunction, start, pivot);
		}
	}
	/**
	 * Find the bounds of an element
	 * taking padding and margin into account
	 * @param {element} el
	 * @returns {{ width: Number, height: Number}}
	 * @memberof Core
	 */
	function bounds$1(el) {

		var style = window.getComputedStyle(el);
		var widthProps = ["width", "paddingRight", "paddingLeft", "marginRight", "marginLeft", "borderRightWidth", "borderLeftWidth"];
		var heightProps = ["height", "paddingTop", "paddingBottom", "marginTop", "marginBottom", "borderTopWidth", "borderBottomWidth"];

		var width = 0;
		var height = 0;

		widthProps.forEach(function (prop) {
			width += parseFloat(style[prop]) || 0;
		});

		heightProps.forEach(function (prop) {
			height += parseFloat(style[prop]) || 0;
		});

		return {
			height: height,
			width: width
		};
	}

	/**
	 * Find the bounds of an element
	 * taking padding, margin and borders into account
	 * @param {element} el
	 * @returns {{ width: Number, height: Number}}
	 * @memberof Core
	 */
	function borders(el) {

		var style = window.getComputedStyle(el);
		var widthProps = ["paddingRight", "paddingLeft", "marginRight", "marginLeft", "borderRightWidth", "borderLeftWidth"];
		var heightProps = ["paddingTop", "paddingBottom", "marginTop", "marginBottom", "borderTopWidth", "borderBottomWidth"];

		var width = 0;
		var height = 0;

		widthProps.forEach(function (prop) {
			width += parseFloat(style[prop]) || 0;
		});

		heightProps.forEach(function (prop) {
			height += parseFloat(style[prop]) || 0;
		});

		return {
			height: height,
			width: width
		};
	}

	/**
	 * Find the bounds of any node
	 * allows for getting bounds of text nodes by wrapping them in a range
	 * @param {node} node
	 * @returns {BoundingClientRect}
	 * @memberof Core
	 */
	function nodeBounds(node) {
		var elPos = void 0;
		var doc = node.ownerDocument;
		if (node.nodeType == Node.TEXT_NODE) {
			var elRange = doc.createRange();
			elRange.selectNodeContents(node);
			elPos = elRange.getBoundingClientRect();
		} else {
			elPos = node.getBoundingClientRect();
		}
		return elPos;
	}

	/**
	 * Find the equivelent of getBoundingClientRect of a browser window
	 * @returns {{ width: Number, height: Number, top: Number, left: Number, right: Number, bottom: Number }}
	 * @memberof Core
	 */
	function windowBounds() {

		var width = window.innerWidth;
		var height = window.innerHeight;

		return {
			top: 0,
			left: 0,
			right: width,
			bottom: height,
			width: width,
			height: height
		};
	}

	/**
	 * Gets the index of a node in its parent
	 * @param {Node} node
	 * @param {string} typeId
	 * @return {number} index
	 * @memberof Core
	 */
	function indexOfNode(node, typeId) {
		var parent = node.parentNode;
		var children = parent.childNodes;
		var sib;
		var index = -1;
		for (var i = 0; i < children.length; i++) {
			sib = children[i];
			if (sib.nodeType === typeId) {
				index++;
			}
			if (sib == node) break;
		}

		return index;
	}

	/**
	 * Gets the index of a text node in its parent
	 * @param {node} textNode
	 * @returns {number} index
	 * @memberof Core
	 */
	function indexOfTextNode(textNode) {
		return indexOfNode(textNode, TEXT_NODE);
	}

	/**
	 * Gets the index of an element node in its parent
	 * @param {element} elementNode
	 * @returns {number} index
	 * @memberof Core
	 */
	function indexOfElementNode(elementNode) {
		return indexOfNode(elementNode, ELEMENT_NODE);
	}

	/**
	 * Check if extension is xml
	 * @param {string} ext
	 * @returns {boolean}
	 * @memberof Core
	 */
	function isXml(ext) {
		return ["xml", "opf", "ncx"].indexOf(ext) > -1;
	}

	/**
	 * Create a new blob
	 * @param {any} content
	 * @param {string} mime
	 * @returns {Blob}
	 * @memberof Core
	 */
	function createBlob(content, mime) {
		return new Blob([content], { type: mime });
	}

	/**
	 * Create a new blob url
	 * @param {any} content
	 * @param {string} mime
	 * @returns {string} url
	 * @memberof Core
	 */
	function createBlobUrl(content, mime) {
		var tempUrl;
		var blob = createBlob(content, mime);

		tempUrl = _URL.createObjectURL(blob);

		return tempUrl;
	}

	/**
	 * Remove a blob url
	 * @param {string} url
	 * @memberof Core
	 */
	function revokeBlobUrl(url) {
		return _URL.revokeObjectURL(url);
	}

	/**
	 * Create a new base64 encoded url
	 * @param {any} content
	 * @param {string} mime
	 * @returns {string} url
	 * @memberof Core
	 */
	function createBase64Url(content, mime) {
		var data;
		var datauri;

		if (typeof content !== "string") {
			// Only handles strings
			return;
		}

		data = btoa(encodeURIComponent(content));

		datauri = "data:" + mime + ";base64," + data;

		return datauri;
	}

	/**
	 * Get type of an object
	 * @param {object} obj
	 * @returns {string} type
	 * @memberof Core
	 */
	function type(obj) {
		return Object.prototype.toString.call(obj).slice(8, -1);
	}

	/**
	 * Parse xml (or html) markup
	 * @param {string} markup
	 * @param {string} mime
	 * @param {boolean} forceXMLDom force using xmlDom to parse instead of native parser
	 * @returns {document} document
	 * @memberof Core
	 */
	function parse(markup, mime, forceXMLDom) {
		var doc;
		var Parser;

		if (typeof DOMParser === "undefined" || forceXMLDom) {
			Parser = require("xmldom").DOMParser;
		} else {
			Parser = DOMParser;
		}

		// Remove byte order mark before parsing
		// https://www.w3.org/International/questions/qa-byte-order-mark
		if (markup.charCodeAt(0) === 0xFEFF) {
			markup = markup.slice(1);
		}

		doc = new Parser().parseFromString(markup, mime);

		return doc;
	}

	/**
	 * querySelector polyfill
	 * @param {element} el
	 * @param {string} sel selector string
	 * @returns {element} element
	 * @memberof Core
	 */
	function qs(el, sel) {
		var elements;
		if (!el) {
			throw new Error("No Element Provided");
		}

		if (typeof el.querySelector != "undefined") {
			return el.querySelector(sel);
		} else {
			elements = el.getElementsByTagName(sel);
			if (elements.length) {
				return elements[0];
			}
		}
	}

	/**
	 * querySelectorAll polyfill
	 * @param {element} el
	 * @param {string} sel selector string
	 * @returns {element[]} elements
	 * @memberof Core
	 */
	function qsa(el, sel) {

		if (typeof el.querySelector != "undefined") {
			return el.querySelectorAll(sel);
		} else {
			return el.getElementsByTagName(sel);
		}
	}

	/**
	 * querySelector by property
	 * @param {element} el
	 * @param {string} sel selector string
	 * @param {object[]} props
	 * @returns {element[]} elements
	 * @memberof Core
	 */
	function qsp(el, sel, props) {
		var q, filtered;
		if (typeof el.querySelector != "undefined") {
			sel += "[";
			for (var prop in props) {
				sel += prop + "~='" + props[prop] + "'";
			}
			sel += "]";
			return el.querySelector(sel);
		} else {
			q = el.getElementsByTagName(sel);
			filtered = Array.prototype.slice.call(q, 0).filter(function (el) {
				for (var prop in props) {
					if (el.getAttribute(prop) === props[prop]) {
						return true;
					}
				}
				return false;
			});

			if (filtered) {
				return filtered[0];
			}
		}
	}

	/**
	 * Sprint through all text nodes in a document
	 * @memberof Core
	 * @param  {element} root element to start with
	 * @param  {function} func function to run on each element
	 */
	function sprint(root, func) {
		var doc = root.ownerDocument || root;
		if (typeof doc.createTreeWalker !== "undefined") {
			treeWalker(root, func, NodeFilter.SHOW_TEXT);
		} else {
			walk(root, function (node) {
				if (node && node.nodeType === 3) {
					// Node.TEXT_NODE
					func(node);
				}
			}, true);
		}
	}

	/**
	 * Create a treeWalker
	 * @memberof Core
	 * @param  {element} root element to start with
	 * @param  {function} func function to run on each element
	 * @param  {function | object} filter funtion or object to filter with
	 */
	function treeWalker(root, func, filter) {
		var treeWalker = document.createTreeWalker(root, filter, null, false);
		var node = void 0;
		while (node = treeWalker.nextNode()) {
			func(node);
		}
	}

	/**
	 * @memberof Core
	 * @param {node} node
	 * @param {callback} return false for continue,true for break inside callback
	 */
	function walk(node, callback) {
		if (callback(node)) {
			return true;
		}
		node = node.firstChild;
		if (node) {
			do {
				var walked = walk(node, callback);
				if (walked) {
					return true;
				}
				node = node.nextSibling;
			} while (node);
		}
	}

	/**
	 * Convert a blob to a base64 encoded string
	 * @param {Blog} blob
	 * @returns {string}
	 * @memberof Core
	 */
	function blob2base64(blob) {
		return new Promise(function (resolve, reject) {
			var reader = new FileReader();
			reader.readAsDataURL(blob);
			reader.onloadend = function () {
				resolve(reader.result);
			};
		});
	}

	/**
	 * Creates a new pending promise and provides methods to resolve or reject it.
	 * From: https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/Promise.jsm/Deferred#backwards_forwards_compatible
	 * @memberof Core
	 */
	function defer() {
		var _this = this;

		/* A method to resolve the associated Promise with the value passed.
	  * If the promise is already settled it does nothing.
	  *
	  * @param {anything} value : This value is used to resolve the promise
	  * If the value is a Promise then the associated promise assumes the state
	  * of Promise passed as value.
	  */
		this.resolve = null;

		/* A method to reject the assocaited Promise with the value passed.
	  * If the promise is already settled it does nothing.
	  *
	  * @param {anything} reason: The reason for the rejection of the Promise.
	  * Generally its an Error object. If however a Promise is passed, then the Promise
	  * itself will be the reason for rejection no matter the state of the Promise.
	  */
		this.reject = null;

		this.id = uuid();

		/* A newly created Pomise object.
	  * Initially in pending state.
	  */
		this.promise = new Promise(function (resolve, reject) {
			_this.resolve = resolve;
			_this.reject = reject;
		});
		Object.freeze(this);
	}

	/**
	 * querySelector with filter by epub type
	 * @param {element} html
	 * @param {string} element element type to find
	 * @param {string} type epub type to find
	 * @returns {element[]} elements
	 * @memberof Core
	 */
	function querySelectorByType(html, element, type) {
		var query;
		if (typeof html.querySelector != "undefined") {
			query = html.querySelector(element + "[*|type=\"" + type + "\"]");
		}
		// Handle IE not supporting namespaced epub:type in querySelector
		if (!query || query.length === 0) {
			query = qsa(html, element);
			for (var i = 0; i < query.length; i++) {
				if (query[i].getAttributeNS("http://www.idpf.org/2007/ops", "type") === type || query[i].getAttribute("epub:type") === type) {
					return query[i];
				}
			}
		} else {
			return query;
		}
	}

	/**
	 * Find direct decendents of an element
	 * @param {element} el
	 * @returns {element[]} children
	 * @memberof Core
	 */
	function findChildren(el) {
		var result = [];
		var childNodes = el.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var node = childNodes[i];
			if (node.nodeType === 1) {
				result.push(node);
			}
		}
		return result;
	}

	/**
	 * Find all parents (ancestors) of an element
	 * @param {element} node
	 * @returns {element[]} parents
	 * @memberof Core
	 */
	function parents(node) {
		var nodes = [node];
		for (; node; node = node.parentNode) {
			nodes.unshift(node);
		}
		return nodes;
	}

	/**
	 * Find all direct decendents of a specific type
	 * @param {element} el
	 * @param {string} nodeName
	 * @param {boolean} [single]
	 * @returns {element[]} children
	 * @memberof Core
	 */
	function filterChildren(el, nodeName, single) {
		var result = [];
		var childNodes = el.childNodes;
		for (var i = 0; i < childNodes.length; i++) {
			var node = childNodes[i];
			if (node.nodeType === 1 && node.nodeName.toLowerCase() === nodeName) {
				if (single) {
					return node;
				} else {
					result.push(node);
				}
			}
		}
		if (!single) {
			return result;
		}
	}

	/**
	 * Filter all parents (ancestors) with tag name
	 * @param {element} node
	 * @param {string} tagname
	 * @returns {element[]} parents
	 * @memberof Core
	 */
	function getParentByTagName(node, tagname) {
		var parent = void 0;
		if (node === null || tagname === '') return;
		parent = node.parentNode;
		while (parent.nodeType === 1) {
			if (parent.tagName.toLowerCase() === tagname) {
				return parent;
			}
			parent = parent.parentNode;
		}
	}

	/**
	 * Lightweight Polyfill for DOM Range
	 * @class
	 * @memberof Core
	 */
	var RangeObject = function () {
		function RangeObject() {
			_classCallCheck(this, RangeObject);

			this.collapsed = false;
			this.commonAncestorContainer = undefined;
			this.endContainer = undefined;
			this.endOffset = undefined;
			this.startContainer = undefined;
			this.startOffset = undefined;
		}

		_createClass(RangeObject, [{
			key: "setStart",
			value: function setStart(startNode, startOffset) {
				this.startContainer = startNode;
				this.startOffset = startOffset;

				if (!this.endContainer) {
					this.collapse(true);
				} else {
					this.commonAncestorContainer = this._commonAncestorContainer();
				}

				this._checkCollapsed();
			}
		}, {
			key: "setEnd",
			value: function setEnd(endNode, endOffset) {
				this.endContainer = endNode;
				this.endOffset = endOffset;

				if (!this.startContainer) {
					this.collapse(false);
				} else {
					this.collapsed = false;
					this.commonAncestorContainer = this._commonAncestorContainer();
				}

				this._checkCollapsed();
			}
		}, {
			key: "collapse",
			value: function collapse(toStart) {
				this.collapsed = true;
				if (toStart) {
					this.endContainer = this.startContainer;
					this.endOffset = this.startOffset;
					this.commonAncestorContainer = this.startContainer.parentNode;
				} else {
					this.startContainer = this.endContainer;
					this.startOffset = this.endOffset;
					this.commonAncestorContainer = this.endOffset.parentNode;
				}
			}
		}, {
			key: "selectNode",
			value: function selectNode(referenceNode) {
				var parent = referenceNode.parentNode;
				var index = Array.prototype.indexOf.call(parent.childNodes, referenceNode);
				this.setStart(parent, index);
				this.setEnd(parent, index + 1);
			}
		}, {
			key: "selectNodeContents",
			value: function selectNodeContents(referenceNode) {
				var end = referenceNode.childNodes[referenceNode.childNodes - 1];
				var endIndex = referenceNode.nodeType === 3 ? referenceNode.textContent.length : parent.childNodes.length;
				this.setStart(referenceNode, 0);
				this.setEnd(referenceNode, endIndex);
			}
		}, {
			key: "_commonAncestorContainer",
			value: function _commonAncestorContainer(startContainer, endContainer) {
				var startParents = parents(startContainer || this.startContainer);
				var endParents = parents(endContainer || this.endContainer);

				if (startParents[0] != endParents[0]) return undefined;

				for (var i = 0; i < startParents.length; i++) {
					if (startParents[i] != endParents[i]) {
						return startParents[i - 1];
					}
				}
			}
		}, {
			key: "_checkCollapsed",
			value: function _checkCollapsed() {
				if (this.startContainer === this.endContainer && this.startOffset === this.endOffset) {
					this.collapsed = true;
				} else {
					this.collapsed = false;
				}
			}
		}, {
			key: "toString",
			value: function toString() {
				// TODO: implement walking between start and end to find text
			}
		}]);

		return RangeObject;
	}();

	var utils = /*#__PURE__*/Object.freeze({
		requestAnimationFrame: requestAnimationFrame$1,
		uuid: uuid,
		documentHeight: documentHeight,
		isElement: isElement,
		isNumber: isNumber,
		isFloat: isFloat,
		prefixed: prefixed,
		defaults: defaults,
		extend: extend$1,
		insert: insert,
		locationOf: locationOf,
		indexOfSorted: indexOfSorted,
		bounds: bounds$1,
		borders: borders,
		nodeBounds: nodeBounds,
		windowBounds: windowBounds,
		indexOfNode: indexOfNode,
		indexOfTextNode: indexOfTextNode,
		indexOfElementNode: indexOfElementNode,
		isXml: isXml,
		createBlob: createBlob,
		createBlobUrl: createBlobUrl,
		revokeBlobUrl: revokeBlobUrl,
		createBase64Url: createBase64Url,
		type: type,
		parse: parse,
		qs: qs,
		qsa: qsa,
		qsp: qsp,
		sprint: sprint,
		treeWalker: treeWalker,
		walk: walk,
		blob2base64: blob2base64,
		defer: defer,
		querySelectorByType: querySelectorByType,
		findChildren: findChildren,
		parents: parents,
		filterChildren: filterChildren,
		getParentByTagName: getParentByTagName,
		RangeObject: RangeObject
	});

	var _typeof$4 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	if (!process$1) {
	  var process$1 = {
	    "cwd": function cwd() {
	      return '/';
	    }
	  };
	}

	function assertPath(path) {
	  if (typeof path !== 'string') {
	    throw new TypeError('Path must be a string. Received ' + path);
	  }
	}

	// Resolves . and .. elements in a path with directory names
	function normalizeStringPosix(path, allowAboveRoot) {
	  var res = '';
	  var lastSlash = -1;
	  var dots = 0;
	  var code;
	  for (var i = 0; i <= path.length; ++i) {
	    if (i < path.length) code = path.charCodeAt(i);else if (code === 47 /*/*/) break;else code = 47 /*/*/;
	    if (code === 47 /*/*/) {
	        if (lastSlash === i - 1 || dots === 1) ; else if (lastSlash !== i - 1 && dots === 2) {
	          if (res.length < 2 || res.charCodeAt(res.length - 1) !== 46 /*.*/ || res.charCodeAt(res.length - 2) !== 46 /*.*/) {
	              if (res.length > 2) {
	                var start = res.length - 1;
	                var j = start;
	                for (; j >= 0; --j) {
	                  if (res.charCodeAt(j) === 47 /*/*/) break;
	                }
	                if (j !== start) {
	                  if (j === -1) res = '';else res = res.slice(0, j);
	                  lastSlash = i;
	                  dots = 0;
	                  continue;
	                }
	              } else if (res.length === 2 || res.length === 1) {
	                res = '';
	                lastSlash = i;
	                dots = 0;
	                continue;
	              }
	            }
	          if (allowAboveRoot) {
	            if (res.length > 0) res += '/..';else res = '..';
	          }
	        } else {
	          if (res.length > 0) res += '/' + path.slice(lastSlash + 1, i);else res = path.slice(lastSlash + 1, i);
	        }
	        lastSlash = i;
	        dots = 0;
	      } else if (code === 46 /*.*/ && dots !== -1) {
	      ++dots;
	    } else {
	      dots = -1;
	    }
	  }
	  return res;
	}

	function _format(sep, pathObject) {
	  var dir = pathObject.dir || pathObject.root;
	  var base = pathObject.base || (pathObject.name || '') + (pathObject.ext || '');
	  if (!dir) {
	    return base;
	  }
	  if (dir === pathObject.root) {
	    return dir + base;
	  }
	  return dir + sep + base;
	}

	var posix = {
	  // path.resolve([from ...], to)
	  resolve: function resolve() {
	    var resolvedPath = '';
	    var resolvedAbsolute = false;
	    var cwd;

	    for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
	      var path;
	      if (i >= 0) path = arguments[i];else {
	        if (cwd === undefined) cwd = process$1.cwd();
	        path = cwd;
	      }

	      assertPath(path);

	      // Skip empty entries
	      if (path.length === 0) {
	        continue;
	      }

	      resolvedPath = path + '/' + resolvedPath;
	      resolvedAbsolute = path.charCodeAt(0) === 47 /*/*/;
	    }

	    // At this point the path should be resolved to a full absolute path, but
	    // handle relative paths to be safe (might happen when process.cwd() fails)

	    // Normalize the path
	    resolvedPath = normalizeStringPosix(resolvedPath, !resolvedAbsolute);

	    if (resolvedAbsolute) {
	      if (resolvedPath.length > 0) return '/' + resolvedPath;else return '/';
	    } else if (resolvedPath.length > 0) {
	      return resolvedPath;
	    } else {
	      return '.';
	    }
	  },

	  normalize: function normalize(path) {
	    assertPath(path);

	    if (path.length === 0) return '.';

	    var isAbsolute = path.charCodeAt(0) === 47 /*/*/;
	    var trailingSeparator = path.charCodeAt(path.length - 1) === 47 /*/*/;

	    // Normalize the path
	    path = normalizeStringPosix(path, !isAbsolute);

	    if (path.length === 0 && !isAbsolute) path = '.';
	    if (path.length > 0 && trailingSeparator) path += '/';

	    if (isAbsolute) return '/' + path;
	    return path;
	  },

	  isAbsolute: function isAbsolute(path) {
	    assertPath(path);
	    return path.length > 0 && path.charCodeAt(0) === 47 /*/*/;
	  },

	  join: function join() {
	    if (arguments.length === 0) return '.';
	    var joined;
	    for (var i = 0; i < arguments.length; ++i) {
	      var arg = arguments[i];
	      assertPath(arg);
	      if (arg.length > 0) {
	        if (joined === undefined) joined = arg;else joined += '/' + arg;
	      }
	    }
	    if (joined === undefined) return '.';
	    return posix.normalize(joined);
	  },

	  relative: function relative(from, to) {
	    assertPath(from);
	    assertPath(to);

	    if (from === to) return '';

	    from = posix.resolve(from);
	    to = posix.resolve(to);

	    if (from === to) return '';

	    // Trim any leading backslashes
	    var fromStart = 1;
	    for (; fromStart < from.length; ++fromStart) {
	      if (from.charCodeAt(fromStart) !== 47 /*/*/) break;
	    }
	    var fromEnd = from.length;
	    var fromLen = fromEnd - fromStart;

	    // Trim any leading backslashes
	    var toStart = 1;
	    for (; toStart < to.length; ++toStart) {
	      if (to.charCodeAt(toStart) !== 47 /*/*/) break;
	    }
	    var toEnd = to.length;
	    var toLen = toEnd - toStart;

	    // Compare paths to find the longest common path from root
	    var length = fromLen < toLen ? fromLen : toLen;
	    var lastCommonSep = -1;
	    var i = 0;
	    for (; i <= length; ++i) {
	      if (i === length) {
	        if (toLen > length) {
	          if (to.charCodeAt(toStart + i) === 47 /*/*/) {
	              // We get here if `from` is the exact base path for `to`.
	              // For example: from='/foo/bar'; to='/foo/bar/baz'
	              return to.slice(toStart + i + 1);
	            } else if (i === 0) {
	            // We get here if `from` is the root
	            // For example: from='/'; to='/foo'
	            return to.slice(toStart + i);
	          }
	        } else if (fromLen > length) {
	          if (from.charCodeAt(fromStart + i) === 47 /*/*/) {
	              // We get here if `to` is the exact base path for `from`.
	              // For example: from='/foo/bar/baz'; to='/foo/bar'
	              lastCommonSep = i;
	            } else if (i === 0) {
	            // We get here if `to` is the root.
	            // For example: from='/foo'; to='/'
	            lastCommonSep = 0;
	          }
	        }
	        break;
	      }
	      var fromCode = from.charCodeAt(fromStart + i);
	      var toCode = to.charCodeAt(toStart + i);
	      if (fromCode !== toCode) break;else if (fromCode === 47 /*/*/) lastCommonSep = i;
	    }

	    var out = '';
	    // Generate the relative path based on the path difference between `to`
	    // and `from`
	    for (i = fromStart + lastCommonSep + 1; i <= fromEnd; ++i) {
	      if (i === fromEnd || from.charCodeAt(i) === 47 /*/*/) {
	          if (out.length === 0) out += '..';else out += '/..';
	        }
	    }

	    // Lastly, append the rest of the destination (`to`) path that comes after
	    // the common path parts
	    if (out.length > 0) return out + to.slice(toStart + lastCommonSep);else {
	      toStart += lastCommonSep;
	      if (to.charCodeAt(toStart) === 47 /*/*/) ++toStart;
	      return to.slice(toStart);
	    }
	  },

	  _makeLong: function _makeLong(path) {
	    return path;
	  },

	  dirname: function dirname(path) {
	    assertPath(path);
	    if (path.length === 0) return '.';
	    var code = path.charCodeAt(0);
	    var hasRoot = code === 47 /*/*/;
	    var end = -1;
	    var matchedSlash = true;
	    for (var i = path.length - 1; i >= 1; --i) {
	      code = path.charCodeAt(i);
	      if (code === 47 /*/*/) {
	          if (!matchedSlash) {
	            end = i;
	            break;
	          }
	        } else {
	        // We saw the first non-path separator
	        matchedSlash = false;
	      }
	    }

	    if (end === -1) return hasRoot ? '/' : '.';
	    if (hasRoot && end === 1) return '//';
	    return path.slice(0, end);
	  },

	  basename: function basename(path, ext) {
	    if (ext !== undefined && typeof ext !== 'string') throw new TypeError('"ext" argument must be a string');
	    assertPath(path);

	    var start = 0;
	    var end = -1;
	    var matchedSlash = true;
	    var i;

	    if (ext !== undefined && ext.length > 0 && ext.length <= path.length) {
	      if (ext.length === path.length && ext === path) return '';
	      var extIdx = ext.length - 1;
	      var firstNonSlashEnd = -1;
	      for (i = path.length - 1; i >= 0; --i) {
	        var code = path.charCodeAt(i);
	        if (code === 47 /*/*/) {
	            // If we reached a path separator that was not part of a set of path
	            // separators at the end of the string, stop now
	            if (!matchedSlash) {
	              start = i + 1;
	              break;
	            }
	          } else {
	          if (firstNonSlashEnd === -1) {
	            // We saw the first non-path separator, remember this index in case
	            // we need it if the extension ends up not matching
	            matchedSlash = false;
	            firstNonSlashEnd = i + 1;
	          }
	          if (extIdx >= 0) {
	            // Try to match the explicit extension
	            if (code === ext.charCodeAt(extIdx)) {
	              if (--extIdx === -1) {
	                // We matched the extension, so mark this as the end of our path
	                // component
	                end = i;
	              }
	            } else {
	              // Extension does not match, so our result is the entire path
	              // component
	              extIdx = -1;
	              end = firstNonSlashEnd;
	            }
	          }
	        }
	      }

	      if (start === end) end = firstNonSlashEnd;else if (end === -1) end = path.length;
	      return path.slice(start, end);
	    } else {
	      for (i = path.length - 1; i >= 0; --i) {
	        if (path.charCodeAt(i) === 47 /*/*/) {
	            // If we reached a path separator that was not part of a set of path
	            // separators at the end of the string, stop now
	            if (!matchedSlash) {
	              start = i + 1;
	              break;
	            }
	          } else if (end === -1) {
	          // We saw the first non-path separator, mark this as the end of our
	          // path component
	          matchedSlash = false;
	          end = i + 1;
	        }
	      }

	      if (end === -1) return '';
	      return path.slice(start, end);
	    }
	  },

	  extname: function extname(path) {
	    assertPath(path);
	    var startDot = -1;
	    var startPart = 0;
	    var end = -1;
	    var matchedSlash = true;
	    // Track the state of characters (if any) we see before our first dot and
	    // after any path separator we find
	    var preDotState = 0;
	    for (var i = path.length - 1; i >= 0; --i) {
	      var code = path.charCodeAt(i);
	      if (code === 47 /*/*/) {
	          // If we reached a path separator that was not part of a set of path
	          // separators at the end of the string, stop now
	          if (!matchedSlash) {
	            startPart = i + 1;
	            break;
	          }
	          continue;
	        }
	      if (end === -1) {
	        // We saw the first non-path separator, mark this as the end of our
	        // extension
	        matchedSlash = false;
	        end = i + 1;
	      }
	      if (code === 46 /*.*/) {
	          // If this is our first dot, mark it as the start of our extension
	          if (startDot === -1) startDot = i;else if (preDotState !== 1) preDotState = 1;
	        } else if (startDot !== -1) {
	        // We saw a non-dot and non-path separator before our dot, so we should
	        // have a good chance at having a non-empty extension
	        preDotState = -1;
	      }
	    }

	    if (startDot === -1 || end === -1 ||
	    // We saw a non-dot character immediately before the dot
	    preDotState === 0 ||
	    // The (right-most) trimmed path component is exactly '..'
	    preDotState === 1 && startDot === end - 1 && startDot === startPart + 1) {
	      return '';
	    }
	    return path.slice(startDot, end);
	  },

	  format: function format(pathObject) {
	    if (pathObject === null || (typeof pathObject === 'undefined' ? 'undefined' : _typeof$4(pathObject)) !== 'object') {
	      throw new TypeError('Parameter "pathObject" must be an object, not ' + (typeof pathObject === 'undefined' ? 'undefined' : _typeof$4(pathObject)));
	    }
	    return _format('/', pathObject);
	  },

	  parse: function parse(path) {
	    assertPath(path);

	    var ret = { root: '', dir: '', base: '', ext: '', name: '' };
	    if (path.length === 0) return ret;
	    var code = path.charCodeAt(0);
	    var isAbsolute = code === 47 /*/*/;
	    var start;
	    if (isAbsolute) {
	      ret.root = '/';
	      start = 1;
	    } else {
	      start = 0;
	    }
	    var startDot = -1;
	    var startPart = 0;
	    var end = -1;
	    var matchedSlash = true;
	    var i = path.length - 1;

	    // Track the state of characters (if any) we see before our first dot and
	    // after any path separator we find
	    var preDotState = 0;

	    // Get non-dir info
	    for (; i >= start; --i) {
	      code = path.charCodeAt(i);
	      if (code === 47 /*/*/) {
	          // If we reached a path separator that was not part of a set of path
	          // separators at the end of the string, stop now
	          if (!matchedSlash) {
	            startPart = i + 1;
	            break;
	          }
	          continue;
	        }
	      if (end === -1) {
	        // We saw the first non-path separator, mark this as the end of our
	        // extension
	        matchedSlash = false;
	        end = i + 1;
	      }
	      if (code === 46 /*.*/) {
	          // If this is our first dot, mark it as the start of our extension
	          if (startDot === -1) startDot = i;else if (preDotState !== 1) preDotState = 1;
	        } else if (startDot !== -1) {
	        // We saw a non-dot and non-path separator before our dot, so we should
	        // have a good chance at having a non-empty extension
	        preDotState = -1;
	      }
	    }

	    if (startDot === -1 || end === -1 ||
	    // We saw a non-dot character immediately before the dot
	    preDotState === 0 ||
	    // The (right-most) trimmed path component is exactly '..'
	    preDotState === 1 && startDot === end - 1 && startDot === startPart + 1) {
	      if (end !== -1) {
	        if (startPart === 0 && isAbsolute) ret.base = ret.name = path.slice(1, end);else ret.base = ret.name = path.slice(startPart, end);
	      }
	    } else {
	      if (startPart === 0 && isAbsolute) {
	        ret.name = path.slice(1, startDot);
	        ret.base = path.slice(1, end);
	      } else {
	        ret.name = path.slice(startPart, startDot);
	        ret.base = path.slice(startPart, end);
	      }
	      ret.ext = path.slice(startDot, end);
	    }

	    if (startPart > 0) ret.dir = path.slice(0, startPart - 1);else if (isAbsolute) ret.dir = '/';

	    return ret;
	  },

	  sep: '/',
	  delimiter: ':',
	  posix: null
	};

	var path = posix;

	var _createClass$1 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$1(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Creates a Path object for parsing and manipulation of a path strings
	 *
	 * Uses a polyfill for Nodejs path: https://nodejs.org/api/path.html
	 * @param	{string} pathString	a url string (relative or absolute)
	 * @class
	 */

	var Path = function () {
		function Path(pathString) {
			_classCallCheck$1(this, Path);

			var protocol;
			var parsed;

			protocol = pathString.indexOf("://");
			if (protocol > -1) {
				pathString = new URL(pathString).pathname;
			}

			parsed = this.parse(pathString);

			this.path = pathString;

			if (this.isDirectory(pathString)) {
				this.directory = pathString;
			} else {
				this.directory = parsed.dir + "/";
			}

			this.filename = parsed.base;
			this.extension = parsed.ext.slice(1);
		}

		/**
	  * Parse the path: https://nodejs.org/api/path.html#path_path_parse_path
	  * @param	{string} what
	  * @returns {object}
	  */


		_createClass$1(Path, [{
			key: "parse",
			value: function parse(what) {
				return path.parse(what);
			}

			/**
	   * @param	{string} what
	   * @returns {boolean}
	   */

		}, {
			key: "isAbsolute",
			value: function isAbsolute(what) {
				return path.isAbsolute(what || this.path);
			}

			/**
	   * Check if path ends with a directory
	   * @param	{string} what
	   * @returns {boolean}
	   */

		}, {
			key: "isDirectory",
			value: function isDirectory(what) {
				return what.charAt(what.length - 1) === "/";
			}

			/**
	   * Resolve a path against the directory of the Path
	   *
	   * https://nodejs.org/api/path.html#path_path_resolve_paths
	   * @param	{string} what
	   * @returns {string} resolved
	   */

		}, {
			key: "resolve",
			value: function resolve(what) {
				return path.resolve(this.directory, what);
			}

			/**
	   * Resolve a path relative to the directory of the Path
	   *
	   * https://nodejs.org/api/path.html#path_path_relative_from_to
	   * @param	{string} what
	   * @returns {string} relative
	   */

		}, {
			key: "relative",
			value: function relative(what) {
				var isAbsolute = what && what.indexOf("://") > -1;

				if (isAbsolute) {
					return what;
				}

				return path.relative(this.directory, what);
			}
		}, {
			key: "splitPath",
			value: function splitPath(filename) {
				return this.splitPathRe.exec(filename).slice(1);
			}

			/**
	   * Return the path string
	   * @returns {string} path
	   */

		}, {
			key: "toString",
			value: function toString() {
				return this.path;
			}
		}]);

		return Path;
	}();

	var _createClass$2 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$2(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * creates a Url object for parsing and manipulation of a url string
	 * @param	{string} urlString	a url string (relative or absolute)
	 * @param	{string} [baseString] optional base for the url,
	 * default to window.location.href
	 */

	var Url = function () {
		function Url(urlString, baseString) {
			_classCallCheck$2(this, Url);

			var absolute = urlString.indexOf("://") > -1;
			var pathname = urlString;
			var basePath;

			this.Url = undefined;
			this.href = urlString;
			this.protocol = "";
			this.origin = "";
			this.hash = "";
			this.hash = "";
			this.search = "";
			this.base = baseString;

			if (!absolute && baseString !== false && typeof baseString !== "string" && window && window.location) {
				this.base = window.location.href;
			}

			// URL Polyfill doesn't throw an error if base is empty
			if (absolute || this.base) {
				try {
					if (this.base) {
						// Safari doesn't like an undefined base
						this.Url = new URL(urlString, this.base);
					} else {
						this.Url = new URL(urlString);
					}
					this.href = this.Url.href;

					this.protocol = this.Url.protocol;
					this.origin = this.Url.origin;
					this.hash = this.Url.hash;
					this.search = this.Url.search;

					pathname = this.Url.pathname;
				} catch (e) {
					// Skip URL parsing
					this.Url = undefined;
					// resolve the pathname from the base
					if (this.base) {
						basePath = new Path(this.base);
						pathname = basePath.resolve(pathname);
					}
				}
			}

			this.Path = new Path(pathname);

			this.directory = this.Path.directory;
			this.filename = this.Path.filename;
			this.extension = this.Path.extension;
		}

		/**
	  * @returns {Path}
	  */


		_createClass$2(Url, [{
			key: "path",
			value: function path$$1() {
				return this.Path;
			}

			/**
	   * Resolves a relative path to a absolute url
	   * @param {string} what
	   * @returns {string} url
	   */

		}, {
			key: "resolve",
			value: function resolve(what) {
				var isAbsolute = what.indexOf("://") > -1;
				var fullpath;

				if (isAbsolute) {
					return what;
				}

				fullpath = path.resolve(this.directory, what);
				return this.origin + fullpath;
			}

			/**
	   * Resolve a path relative to the url
	   * @param {string} what
	   * @returns {string} path
	   */

		}, {
			key: "relative",
			value: function relative(what) {
				return path.relative(what, this.directory);
			}

			/**
	   * @returns {string}
	   */

		}, {
			key: "toString",
			value: function toString() {
				return this.href;
			}
		}]);

		return Url;
	}();

	var _typeof$5 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	var _createClass$3 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$3(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var ELEMENT_NODE$1 = 1;
	var TEXT_NODE$1 = 3;
	var DOCUMENT_NODE$1 = 9;

	/**
		* Parsing and creation of EpubCFIs: http://www.idpf.org/epub/linking/cfi/epub-cfi.html

		* Implements:
		* - Character Offset: epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/2/1:3)
		* - Simple Ranges : epubcfi(/6/4[chap01ref]!/4[body01]/10[para05],/2/1:1,/3:4)

		* Does Not Implement:
		* - Temporal Offset (~)
		* - Spatial Offset (@)
		* - Temporal-Spatial Offset (~ + @)
		* - Text Location Assertion ([)
		* @class
		@param {string | Range | Node } [cfiFrom]
		@param {string | object} [base]
		@param {string} [ignoreClass] class to ignore when parsing DOM
	*/

	var EpubCFI = function () {
		function EpubCFI(cfiFrom, base, ignoreClass) {
			_classCallCheck$3(this, EpubCFI);

			var type$$1;

			this.str = "";

			this.base = {};
			this.spinePos = 0; // For compatibility

			this.range = false; // true || false;

			this.path = {};
			this.start = null;
			this.end = null;

			// Allow instantiation without the "new" keyword
			if (!(this instanceof EpubCFI)) {
				return new EpubCFI(cfiFrom, base, ignoreClass);
			}

			if (typeof base === "string") {
				this.base = this.parseComponent(base);
			} else if ((typeof base === "undefined" ? "undefined" : _typeof$5(base)) === "object" && base.steps) {
				this.base = base;
			}

			type$$1 = this.checkType(cfiFrom);

			if (type$$1 === "string") {
				this.str = cfiFrom;
				return extend$1(this, this.parse(cfiFrom));
			} else if (type$$1 === "range") {
				return extend$1(this, this.fromRange(cfiFrom, this.base, ignoreClass));
			} else if (type$$1 === "node") {
				return extend$1(this, this.fromNode(cfiFrom, this.base, ignoreClass));
			} else if (type$$1 === "EpubCFI" && cfiFrom.path) {
				return cfiFrom;
			} else if (!cfiFrom) {
				return this;
			} else {
				throw new TypeError("not a valid argument for EpubCFI");
			}
		}

		/**
	  * Check the type of constructor input
	  * @private
	  */


		_createClass$3(EpubCFI, [{
			key: "checkType",
			value: function checkType(cfi) {

				if (this.isCfiString(cfi)) {
					return "string";
					// Is a range object
				} else if (cfi && (typeof cfi === "undefined" ? "undefined" : _typeof$5(cfi)) === "object" && (type(cfi) === "Range" || typeof cfi.startContainer != "undefined")) {
					return "range";
				} else if (cfi && (typeof cfi === "undefined" ? "undefined" : _typeof$5(cfi)) === "object" && typeof cfi.nodeType != "undefined") {
					// || typeof cfi === "function"
					return "node";
				} else if (cfi && (typeof cfi === "undefined" ? "undefined" : _typeof$5(cfi)) === "object" && cfi instanceof EpubCFI) {
					return "EpubCFI";
				} else {
					return false;
				}
			}

			/**
	   * Parse a cfi string to a CFI object representation
	   * @param {string} cfiStr
	   * @returns {object} cfi
	   */

		}, {
			key: "parse",
			value: function parse$$1(cfiStr) {
				var cfi = {
					spinePos: -1,
					range: false,
					base: {},
					path: {},
					start: null,
					end: null
				};
				var baseComponent, pathComponent, range;

				if (typeof cfiStr !== "string") {
					return { spinePos: -1 };
				}

				if (cfiStr.indexOf("epubcfi(") === 0 && cfiStr[cfiStr.length - 1] === ")") {
					// Remove intial epubcfi( and ending )
					cfiStr = cfiStr.slice(8, cfiStr.length - 1);
				}

				baseComponent = this.getChapterComponent(cfiStr);

				// Make sure this is a valid cfi or return
				if (!baseComponent) {
					return { spinePos: -1 };
				}

				cfi.base = this.parseComponent(baseComponent);

				pathComponent = this.getPathComponent(cfiStr);
				cfi.path = this.parseComponent(pathComponent);

				range = this.getRange(cfiStr);

				if (range) {
					cfi.range = true;
					cfi.start = this.parseComponent(range[0]);
					cfi.end = this.parseComponent(range[1]);
				}

				// Get spine node position
				// cfi.spineSegment = cfi.base.steps[1];

				// Chapter segment is always the second step
				cfi.spinePos = cfi.base.steps[1].index;

				return cfi;
			}
		}, {
			key: "parseComponent",
			value: function parseComponent(componentStr) {
				var component = {
					steps: [],
					terminal: {
						offset: null,
						assertion: null
					}
				};
				var parts = componentStr.split(":");
				var steps = parts[0].split("/");
				var terminal;

				if (parts.length > 1) {
					terminal = parts[1];
					component.terminal = this.parseTerminal(terminal);
				}

				if (steps[0] === "") {
					steps.shift(); // Ignore the first slash
				}

				component.steps = steps.map(function (step) {
					return this.parseStep(step);
				}.bind(this));

				return component;
			}
		}, {
			key: "parseStep",
			value: function parseStep(stepStr) {
				var type$$1, num, index, has_brackets, id;

				has_brackets = stepStr.match(/\[(.*)\]/);
				if (has_brackets && has_brackets[1]) {
					id = has_brackets[1];
				}

				//-- Check if step is a text node or element
				num = parseInt(stepStr);

				if (isNaN(num)) {
					return;
				}

				if (num % 2 === 0) {
					// Even = is an element
					type$$1 = "element";
					index = num / 2 - 1;
				} else {
					type$$1 = "text";
					index = (num - 1) / 2;
				}

				return {
					"type": type$$1,
					"index": index,
					"id": id || null
				};
			}
		}, {
			key: "parseTerminal",
			value: function parseTerminal(termialStr) {
				var characterOffset, textLocationAssertion;
				var assertion = termialStr.match(/\[(.*)\]/);

				if (assertion && assertion[1]) {
					characterOffset = parseInt(termialStr.split("[")[0]);
					textLocationAssertion = assertion[1];
				} else {
					characterOffset = parseInt(termialStr);
				}

				if (!isNumber(characterOffset)) {
					characterOffset = null;
				}

				return {
					"offset": characterOffset,
					"assertion": textLocationAssertion
				};
			}
		}, {
			key: "getChapterComponent",
			value: function getChapterComponent(cfiStr) {

				var indirection = cfiStr.split("!");

				return indirection[0];
			}
		}, {
			key: "getPathComponent",
			value: function getPathComponent(cfiStr) {

				var indirection = cfiStr.split("!");

				if (indirection[1]) {
					var ranges = indirection[1].split(",");
					return ranges[0];
				}
			}
		}, {
			key: "getRange",
			value: function getRange(cfiStr) {

				var ranges = cfiStr.split(",");

				if (ranges.length === 3) {
					return [ranges[1], ranges[2]];
				}

				return false;
			}
		}, {
			key: "getCharecterOffsetComponent",
			value: function getCharecterOffsetComponent(cfiStr) {
				var splitStr = cfiStr.split(":");
				return splitStr[1] || "";
			}
		}, {
			key: "joinSteps",
			value: function joinSteps(steps) {
				if (!steps) {
					return "";
				}

				return steps.map(function (part) {
					var segment = "";

					if (part.type === "element") {
						segment += (part.index + 1) * 2;
					}

					if (part.type === "text") {
						segment += 1 + 2 * part.index; // TODO: double check that this is odd
					}

					if (part.id) {
						segment += "[" + part.id + "]";
					}

					return segment;
				}).join("/");
			}
		}, {
			key: "segmentString",
			value: function segmentString(segment) {
				var segmentString = "/";

				segmentString += this.joinSteps(segment.steps);

				if (segment.terminal && segment.terminal.offset != null) {
					segmentString += ":" + segment.terminal.offset;
				}

				if (segment.terminal && segment.terminal.assertion != null) {
					segmentString += "[" + segment.terminal.assertion + "]";
				}

				return segmentString;
			}

			/**
	   * Convert CFI to a epubcfi(...) string
	   * @returns {string} epubcfi
	   */

		}, {
			key: "toString",
			value: function toString() {
				var cfiString = "epubcfi(";

				cfiString += this.segmentString(this.base);

				cfiString += "!";
				cfiString += this.segmentString(this.path);

				// Add Range, if present
				if (this.range && this.start) {
					cfiString += ",";
					cfiString += this.segmentString(this.start);
				}

				if (this.range && this.end) {
					cfiString += ",";
					cfiString += this.segmentString(this.end);
				}

				cfiString += ")";

				return cfiString;
			}

			/**
	   * Compare which of two CFIs is earlier in the text
	   * @returns {number} First is earlier = -1, Second is earlier = 1, They are equal = 0
	   */

		}, {
			key: "compare",
			value: function compare(cfiOne, cfiTwo) {
				var stepsA, stepsB;
				var terminalA, terminalB;

				if (typeof cfiOne === "string") {
					cfiOne = new EpubCFI(cfiOne);
				}
				if (typeof cfiTwo === "string") {
					cfiTwo = new EpubCFI(cfiTwo);
				}
				// Compare Spine Positions
				if (cfiOne.spinePos > cfiTwo.spinePos) {
					return 1;
				}
				if (cfiOne.spinePos < cfiTwo.spinePos) {
					return -1;
				}

				if (cfiOne.range) {
					stepsA = cfiOne.path.steps.concat(cfiOne.start.steps);
					terminalA = cfiOne.start.terminal;
				} else {
					stepsA = cfiOne.path.steps;
					terminalA = cfiOne.path.terminal;
				}

				if (cfiTwo.range) {
					stepsB = cfiTwo.path.steps.concat(cfiTwo.start.steps);
					terminalB = cfiTwo.start.terminal;
				} else {
					stepsB = cfiTwo.path.steps;
					terminalB = cfiTwo.path.terminal;
				}

				// Compare Each Step in the First item
				for (var i = 0; i < stepsA.length; i++) {
					if (!stepsA[i]) {
						return -1;
					}
					if (!stepsB[i]) {
						return 1;
					}
					if (stepsA[i].index > stepsB[i].index) {
						return 1;
					}
					if (stepsA[i].index < stepsB[i].index) {
						return -1;
					}
					// Otherwise continue checking
				}

				// All steps in First equal to Second and First is Less Specific
				if (stepsA.length < stepsB.length) {
					return 1;
				}

				// Compare the charecter offset of the text node
				if (terminalA.offset > terminalB.offset) {
					return 1;
				}
				if (terminalA.offset < terminalB.offset) {
					return -1;
				}

				// CFI's are equal
				return 0;
			}
		}, {
			key: "step",
			value: function step(node) {
				var nodeType = node.nodeType === TEXT_NODE$1 ? "text" : "element";

				return {
					"id": node.id,
					"tagName": node.tagName,
					"type": nodeType,
					"index": this.position(node)
				};
			}
		}, {
			key: "filteredStep",
			value: function filteredStep(node, ignoreClass) {
				var filteredNode = this.filter(node, ignoreClass);
				var nodeType;

				// Node filtered, so ignore
				if (!filteredNode) {
					return;
				}

				// Otherwise add the filter node in
				nodeType = filteredNode.nodeType === TEXT_NODE$1 ? "text" : "element";

				return {
					"id": filteredNode.id,
					"tagName": filteredNode.tagName,
					"type": nodeType,
					"index": this.filteredPosition(filteredNode, ignoreClass)
				};
			}
		}, {
			key: "pathTo",
			value: function pathTo(node, offset, ignoreClass) {
				var segment = {
					steps: [],
					terminal: {
						offset: null,
						assertion: null
					}
				};
				var currentNode = node;
				var step;

				while (currentNode && currentNode.parentNode && currentNode.parentNode.nodeType != DOCUMENT_NODE$1) {

					if (ignoreClass) {
						step = this.filteredStep(currentNode, ignoreClass);
					} else {
						step = this.step(currentNode);
					}

					if (step) {
						segment.steps.unshift(step);
					}

					currentNode = currentNode.parentNode;
				}

				if (offset != null && offset >= 0) {

					segment.terminal.offset = offset;

					// Make sure we are getting to a textNode if there is an offset
					if (segment.steps[segment.steps.length - 1].type != "text") {
						segment.steps.push({
							"type": "text",
							"index": 0
						});
					}
				}

				return segment;
			}
		}, {
			key: "equalStep",
			value: function equalStep(stepA, stepB) {
				if (!stepA || !stepB) {
					return false;
				}

				if (stepA.index === stepB.index && stepA.id === stepB.id && stepA.type === stepB.type) {
					return true;
				}

				return false;
			}

			/**
	   * Create a CFI object from a Range
	   * @param {Range} range
	   * @param {string | object} base
	   * @param {string} [ignoreClass]
	   * @returns {object} cfi
	   */

		}, {
			key: "fromRange",
			value: function fromRange(range, base, ignoreClass) {
				var cfi = {
					range: false,
					base: {},
					path: {},
					start: null,
					end: null
				};

				var start = range.startContainer;
				var end = range.endContainer;

				var startOffset = range.startOffset;
				var endOffset = range.endOffset;

				var needsIgnoring = false;

				if (ignoreClass) {
					// Tell pathTo if / what to ignore
					needsIgnoring = start.ownerDocument.querySelector("." + ignoreClass) != null;
				}

				if (typeof base === "string") {
					cfi.base = this.parseComponent(base);
					cfi.spinePos = cfi.base.steps[1].index;
				} else if ((typeof base === "undefined" ? "undefined" : _typeof$5(base)) === "object") {
					cfi.base = base;
				}

				if (range.collapsed) {
					if (needsIgnoring) {
						startOffset = this.patchOffset(start, startOffset, ignoreClass);
					}
					cfi.path = this.pathTo(start, startOffset, ignoreClass);
				} else {
					cfi.range = true;

					if (needsIgnoring) {
						startOffset = this.patchOffset(start, startOffset, ignoreClass);
					}

					cfi.start = this.pathTo(start, startOffset, ignoreClass);
					if (needsIgnoring) {
						endOffset = this.patchOffset(end, endOffset, ignoreClass);
					}

					cfi.end = this.pathTo(end, endOffset, ignoreClass);

					// Create a new empty path
					cfi.path = {
						steps: [],
						terminal: null
					};

					// Push steps that are shared between start and end to the common path
					var len = cfi.start.steps.length;
					var i;

					for (i = 0; i < len; i++) {
						if (this.equalStep(cfi.start.steps[i], cfi.end.steps[i])) {
							if (i === len - 1) {
								// Last step is equal, check terminals
								if (cfi.start.terminal === cfi.end.terminal) {
									// CFI's are equal
									cfi.path.steps.push(cfi.start.steps[i]);
									// Not a range
									cfi.range = false;
								}
							} else {
								cfi.path.steps.push(cfi.start.steps[i]);
							}
						} else {
							break;
						}
					}

					cfi.start.steps = cfi.start.steps.slice(cfi.path.steps.length);
					cfi.end.steps = cfi.end.steps.slice(cfi.path.steps.length);

					// TODO: Add Sanity check to make sure that the end if greater than the start
				}

				return cfi;
			}

			/**
	   * Create a CFI object from a Node
	   * @param {Node} anchor
	   * @param {string | object} base
	   * @param {string} [ignoreClass]
	   * @returns {object} cfi
	   */

		}, {
			key: "fromNode",
			value: function fromNode(anchor, base, ignoreClass) {
				var cfi = {
					range: false,
					base: {},
					path: {},
					start: null,
					end: null
				};

				if (typeof base === "string") {
					cfi.base = this.parseComponent(base);
					cfi.spinePos = cfi.base.steps[1].index;
				} else if ((typeof base === "undefined" ? "undefined" : _typeof$5(base)) === "object") {
					cfi.base = base;
				}

				cfi.path = this.pathTo(anchor, null, ignoreClass);

				return cfi;
			}
		}, {
			key: "filter",
			value: function filter(anchor, ignoreClass) {
				var needsIgnoring;
				var sibling; // to join with
				var parent, previousSibling, nextSibling;
				var isText = false;

				if (anchor.nodeType === TEXT_NODE$1) {
					isText = true;
					parent = anchor.parentNode;
					needsIgnoring = anchor.parentNode.classList.contains(ignoreClass);
				} else {
					isText = false;
					needsIgnoring = anchor.classList.contains(ignoreClass);
				}

				if (needsIgnoring && isText) {
					previousSibling = parent.previousSibling;
					nextSibling = parent.nextSibling;

					// If the sibling is a text node, join the nodes
					if (previousSibling && previousSibling.nodeType === TEXT_NODE$1) {
						sibling = previousSibling;
					} else if (nextSibling && nextSibling.nodeType === TEXT_NODE$1) {
						sibling = nextSibling;
					}

					if (sibling) {
						return sibling;
					} else {
						// Parent will be ignored on next step
						return anchor;
					}
				} else if (needsIgnoring && !isText) {
					// Otherwise just skip the element node
					return false;
				} else {
					// No need to filter
					return anchor;
				}
			}
		}, {
			key: "patchOffset",
			value: function patchOffset(anchor, offset, ignoreClass) {
				if (anchor.nodeType != TEXT_NODE$1) {
					throw new Error("Anchor must be a text node");
				}

				var curr = anchor;
				var totalOffset = offset;

				// If the parent is a ignored node, get offset from it's start
				if (anchor.parentNode.classList.contains(ignoreClass)) {
					curr = anchor.parentNode;
				}

				while (curr.previousSibling) {
					if (curr.previousSibling.nodeType === ELEMENT_NODE$1) {
						// Originally a text node, so join
						if (curr.previousSibling.classList.contains(ignoreClass)) {
							totalOffset += curr.previousSibling.textContent.length;
						} else {
							break; // Normal node, dont join
						}
					} else {
						// If the previous sibling is a text node, join the nodes
						totalOffset += curr.previousSibling.textContent.length;
					}

					curr = curr.previousSibling;
				}

				return totalOffset;
			}
		}, {
			key: "normalizedMap",
			value: function normalizedMap(children, nodeType, ignoreClass) {
				var output = {};
				var prevIndex = -1;
				var i,
				    len = children.length;
				var currNodeType;
				var prevNodeType;

				for (i = 0; i < len; i++) {

					currNodeType = children[i].nodeType;

					// Check if needs ignoring
					if (currNodeType === ELEMENT_NODE$1 && children[i].classList.contains(ignoreClass)) {
						currNodeType = TEXT_NODE$1;
					}

					if (i > 0 && currNodeType === TEXT_NODE$1 && prevNodeType === TEXT_NODE$1) {
						// join text nodes
						output[i] = prevIndex;
					} else if (nodeType === currNodeType) {
						prevIndex = prevIndex + 1;
						output[i] = prevIndex;
					}

					prevNodeType = currNodeType;
				}

				return output;
			}
		}, {
			key: "position",
			value: function position(anchor) {
				var children, index;
				if (anchor.nodeType === ELEMENT_NODE$1) {
					children = anchor.parentNode.children;
					if (!children) {
						children = findChildren(anchor.parentNode);
					}
					index = Array.prototype.indexOf.call(children, anchor);
				} else {
					children = this.textNodes(anchor.parentNode);
					index = children.indexOf(anchor);
				}

				return index;
			}
		}, {
			key: "filteredPosition",
			value: function filteredPosition(anchor, ignoreClass) {
				var children, index, map;

				if (anchor.nodeType === ELEMENT_NODE$1) {
					children = anchor.parentNode.children;
					map = this.normalizedMap(children, ELEMENT_NODE$1, ignoreClass);
				} else {
					children = anchor.parentNode.childNodes;
					// Inside an ignored node
					if (anchor.parentNode.classList.contains(ignoreClass)) {
						anchor = anchor.parentNode;
						children = anchor.parentNode.childNodes;
					}
					map = this.normalizedMap(children, TEXT_NODE$1, ignoreClass);
				}

				index = Array.prototype.indexOf.call(children, anchor);

				return map[index];
			}
		}, {
			key: "stepsToXpath",
			value: function stepsToXpath(steps) {
				var xpath = [".", "*"];

				steps.forEach(function (step) {
					var position = step.index + 1;

					if (step.id) {
						xpath.push("*[position()=" + position + " and @id='" + step.id + "']");
					} else if (step.type === "text") {
						xpath.push("text()[" + position + "]");
					} else {
						xpath.push("*[" + position + "]");
					}
				});

				return xpath.join("/");
			}

			/*
	  	To get the last step if needed:
	  	// Get the terminal step
	  lastStep = steps[steps.length-1];
	  // Get the query string
	  query = this.stepsToQuery(steps);
	  // Find the containing element
	  startContainerParent = doc.querySelector(query);
	  // Find the text node within that element
	  if(startContainerParent && lastStep.type == "text") {
	  	container = startContainerParent.childNodes[lastStep.index];
	  }
	  */

		}, {
			key: "stepsToQuerySelector",
			value: function stepsToQuerySelector(steps) {
				var query = ["html"];

				steps.forEach(function (step) {
					var position = step.index + 1;

					if (step.id) {
						query.push("#" + step.id);
					} else if (step.type === "text") ; else {
						query.push("*:nth-child(" + position + ")");
					}
				});

				return query.join(">");
			}
		}, {
			key: "textNodes",
			value: function textNodes(container, ignoreClass) {
				return Array.prototype.slice.call(container.childNodes).filter(function (node) {
					if (node.nodeType === TEXT_NODE$1) {
						return true;
					} else if (ignoreClass && node.classList.contains(ignoreClass)) {
						return true;
					}
					return false;
				});
			}
		}, {
			key: "walkToNode",
			value: function walkToNode(steps, _doc, ignoreClass) {
				var doc = _doc || document;
				var container = doc.documentElement;
				var children;
				var step;
				var len = steps.length;
				var i;

				for (i = 0; i < len; i++) {
					step = steps[i];

					if (step.type === "element") {
						//better to get a container using id as some times step.index may not be correct
						//For ex.https://github.com/futurepress/epub.js/issues/561
						if (step.id) {
							container = doc.getElementById(step.id);
						} else {
							children = container.children || findChildren(container);
							container = children[step.index];
						}
					} else if (step.type === "text") {
						container = this.textNodes(container, ignoreClass)[step.index];
					}
					if (!container) {
						//Break the for loop as due to incorrect index we can get error if
						//container is undefined so that other functionailties works fine
						//like navigation
						break;
					}
				}

				return container;
			}
		}, {
			key: "findNode",
			value: function findNode(steps, _doc, ignoreClass) {
				var doc = _doc || document;
				var container;
				var xpath;

				if (!ignoreClass && typeof doc.evaluate != "undefined") {
					xpath = this.stepsToXpath(steps);
					container = doc.evaluate(xpath, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
				} else if (ignoreClass) {
					container = this.walkToNode(steps, doc, ignoreClass);
				} else {
					container = this.walkToNode(steps, doc);
				}

				return container;
			}
		}, {
			key: "fixMiss",
			value: function fixMiss(steps, offset, _doc, ignoreClass) {
				var container = this.findNode(steps.slice(0, -1), _doc, ignoreClass);
				var children = container.childNodes;
				var map = this.normalizedMap(children, TEXT_NODE$1, ignoreClass);
				var child;
				var len;
				var lastStepIndex = steps[steps.length - 1].index;

				for (var childIndex in map) {
					if (!map.hasOwnProperty(childIndex)) return;

					if (map[childIndex] === lastStepIndex) {
						child = children[childIndex];
						len = child.textContent.length;
						if (offset > len) {
							offset = offset - len;
						} else {
							if (child.nodeType === ELEMENT_NODE$1) {
								container = child.childNodes[0];
							} else {
								container = child;
							}
							break;
						}
					}
				}

				return {
					container: container,
					offset: offset
				};
			}

			/**
	   * Creates a DOM range representing a CFI
	   * @param {document} _doc document referenced in the base
	   * @param {string} [ignoreClass]
	   * @return {Range}
	   */

		}, {
			key: "toRange",
			value: function toRange(_doc, ignoreClass) {
				var doc = _doc || document;
				var range;
				var start, end, startContainer, endContainer;
				var cfi = this;
				var startSteps, endSteps;
				var needsIgnoring = ignoreClass ? doc.querySelector("." + ignoreClass) != null : false;
				var missed;

				if (typeof doc.createRange !== "undefined") {
					range = doc.createRange();
				} else {
					range = new RangeObject();
				}

				if (cfi.range) {
					start = cfi.start;
					startSteps = cfi.path.steps.concat(start.steps);
					startContainer = this.findNode(startSteps, doc, needsIgnoring ? ignoreClass : null);
					end = cfi.end;
					endSteps = cfi.path.steps.concat(end.steps);
					endContainer = this.findNode(endSteps, doc, needsIgnoring ? ignoreClass : null);
				} else {
					start = cfi.path;
					startSteps = cfi.path.steps;
					startContainer = this.findNode(cfi.path.steps, doc, needsIgnoring ? ignoreClass : null);
				}

				if (startContainer) {
					try {

						if (start.terminal.offset != null) {
							range.setStart(startContainer, start.terminal.offset);
						} else {
							range.setStart(startContainer, 0);
						}
					} catch (e) {
						missed = this.fixMiss(startSteps, start.terminal.offset, doc, needsIgnoring ? ignoreClass : null);
						range.setStart(missed.container, missed.offset);
					}
				} else {
					console.log("No startContainer found for", this.toString());
					// No start found
					return null;
				}

				if (endContainer) {
					try {

						if (end.terminal.offset != null) {
							range.setEnd(endContainer, end.terminal.offset);
						} else {
							range.setEnd(endContainer, 0);
						}
					} catch (e) {
						missed = this.fixMiss(endSteps, cfi.end.terminal.offset, doc, needsIgnoring ? ignoreClass : null);
						range.setEnd(missed.container, missed.offset);
					}
				}

				// doc.defaultView.getSelection().addRange(range);
				return range;
			}

			/**
	   * Check if a string is wrapped with "epubcfi()"
	   * @param {string} str
	   * @returns {boolean}
	   */

		}, {
			key: "isCfiString",
			value: function isCfiString(str) {
				if (typeof str === "string" && str.indexOf("epubcfi(") === 0 && str[str.length - 1] === ")") {
					return true;
				}

				return false;
			}
		}, {
			key: "generateChapterComponent",
			value: function generateChapterComponent(_spineNodeIndex, _pos, id) {
				var pos = parseInt(_pos),
				    spineNodeIndex = (_spineNodeIndex + 1) * 2,
				    cfi = "/" + spineNodeIndex + "/";

				cfi += (pos + 1) * 2;

				if (id) {
					cfi += "[" + id + "]";
				}

				return cfi;
			}

			/**
	   * Collapse a CFI Range to a single CFI Position
	   * @param {boolean} [toStart=false]
	   */

		}, {
			key: "collapse",
			value: function collapse(toStart) {
				if (!this.range) {
					return;
				}

				this.range = false;

				if (toStart) {
					this.path.steps = this.path.steps.concat(this.start.steps);
					this.path.terminal = this.start.terminal;
				} else {
					this.path.steps = this.path.steps.concat(this.end.steps);
					this.path.terminal = this.end.terminal;
				}
			}
		}]);

		return EpubCFI;
	}();

	var _createClass$4 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$4(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Hooks allow for injecting functions that must all complete in order before finishing
	 * They will execute in parallel but all must finish before continuing
	 * Functions may return a promise if they are asycn.
	 * @param {any} context scope of this
	 * @example this.content = new EPUBJS.Hook(this);
	 */
	var Hook = function () {
		function Hook(context) {
			_classCallCheck$4(this, Hook);

			this.context = context || this;
			this.hooks = [];
		}

		/**
	  * Adds a function to be run before a hook completes
	  * @example this.content.register(function(){...});
	  */


		_createClass$4(Hook, [{
			key: "register",
			value: function register() {
				for (var i = 0; i < arguments.length; ++i) {
					if (typeof arguments[i] === "function") {
						this.hooks.push(arguments[i]);
					} else {
						// unpack array
						for (var j = 0; j < arguments[i].length; ++j) {
							this.hooks.push(arguments[i][j]);
						}
					}
				}
			}

			/**
	   * Removes a function
	   * @example this.content.deregister(function(){...});
	   */

		}, {
			key: "deregister",
			value: function deregister(func) {
				var hook = void 0;
				for (var i = 0; i < this.hooks.length; i++) {
					hook = this.hooks[i];
					if (hook === func) {
						this.hooks.splice(i, 1);
						break;
					}
				}
			}

			/**
	   * Triggers a hook to run all functions
	   * @example this.content.trigger(args).then(function(){...});
	   */

		}, {
			key: "trigger",
			value: function trigger() {
				var args = arguments;
				var context = this.context;
				var promises = [];

				this.hooks.forEach(function (task) {
					var executing = task.apply(context, args);

					if (executing && typeof executing["then"] === "function") {
						// Task is a function that returns a promise
						promises.push(executing);
					}
					// Otherwise Task resolves immediately, continue
				});

				return Promise.all(promises);
			}

			// Adds a function to be run before a hook completes

		}, {
			key: "list",
			value: function list() {
				return this.hooks;
			}
		}, {
			key: "clear",
			value: function clear() {
				return this.hooks = [];
			}
		}]);

		return Hook;
	}();

	function replaceBase(doc, section) {
		var base;
		var head;
		var url = section.url;
		var absolute = url.indexOf("://") > -1;

		if (!doc) {
			return;
		}

		head = qs(doc, "head");
		base = qs(head, "base");

		if (!base) {
			base = doc.createElement("base");
			head.insertBefore(base, head.firstChild);
		}

		// Fix for Safari crashing if the url doesn't have an origin
		if (!absolute && window && window.location) {
			url = window.location.origin + url;
		}

		base.setAttribute("href", url);
	}

	function replaceCanonical(doc, section) {
		var head;
		var link;
		var url = section.canonical;

		if (!doc) {
			return;
		}

		head = qs(doc, "head");
		link = qs(head, "link[rel='canonical']");

		if (link) {
			link.setAttribute("href", url);
		} else {
			link = doc.createElement("link");
			link.setAttribute("rel", "canonical");
			link.setAttribute("href", url);
			head.appendChild(link);
		}
	}

	function replaceMeta(doc, section) {
		var head;
		var meta;
		var id = section.idref;
		if (!doc) {
			return;
		}

		head = qs(doc, "head");
		meta = qs(head, "link[property='dc.identifier']");

		if (meta) {
			meta.setAttribute("content", id);
		} else {
			meta = doc.createElement("meta");
			meta.setAttribute("name", "dc.identifier");
			meta.setAttribute("content", id);
			head.appendChild(meta);
		}
	}

	// TODO: move me to Contents
	function replaceLinks(contents, fn) {

		var links = contents.querySelectorAll("a[href]");

		if (!links.length) {
			return;
		}

		var base = qs(contents.ownerDocument, "base");
		var location = base ? base.getAttribute("href") : undefined;
		var replaceLink = function (link) {
			var href = link.getAttribute("href");

			if (href.indexOf("mailto:") === 0) {
				return;
			}

			var absolute = href.indexOf("://") > -1;

			if (absolute) {

				link.setAttribute("target", "_blank");
			} else {
				var linkUrl;
				try {
					linkUrl = new Url(href, location);
				} catch (error) {
					// NOOP
				}

				link.onclick = function () {

					if (linkUrl && linkUrl.hash) {
						fn(linkUrl.Path.path + linkUrl.hash);
					} else if (linkUrl) {
						fn(linkUrl.Path.path);
					} else {
						fn(href);
					}

					return false;
				};
			}
		}.bind(this);

		for (var i = 0; i < links.length; i++) {
			replaceLink(links[i]);
		}
	}

	function substitute(content, urls, replacements) {
		urls.forEach(function (url, i) {
			if (url && replacements[i]) {
				content = content.replace(new RegExp(url, "g"), replacements[i]);
			}
		});
		return content;
	}

	var _createClass$5 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$5(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Represents a Section of the Book
	 *
	 * In most books this is equivelent to a Chapter
	 * @param {object} item  The spine item representing the section
	 * @param {object} hooks hooks for serialize and content
	 */

	var Section = function () {
		function Section(item, hooks) {
			_classCallCheck$5(this, Section);

			this.idref = item.idref;
			this.linear = item.linear === "yes";
			this.properties = item.properties;
			this.index = item.index;
			this.href = item.href;
			this.url = item.url;
			this.canonical = item.canonical;
			this.next = item.next;
			this.prev = item.prev;

			this.cfiBase = item.cfiBase;

			if (hooks) {
				this.hooks = hooks;
			} else {
				this.hooks = {};
				this.hooks.serialize = new Hook(this);
				this.hooks.content = new Hook(this);
			}

			this.document = undefined;
			this.contents = undefined;
			this.output = undefined;
		}

		/**
	  * Load the section from its url
	  * @param  {method} [_request] a request method to use for loading
	  * @return {document} a promise with the xml document
	  */


		_createClass$5(Section, [{
			key: "load",
			value: function load(_request) {
				var request = _request || this.request || require("./utils/request");
				var loading = new defer();
				var loaded = loading.promise;

				if (this.contents) {
					loading.resolve(this.contents);
				} else {
					request(this.url).then(function (xml) {
						// var directory = new Url(this.url).directory;

						this.document = xml;
						this.contents = xml.documentElement;

						return this.hooks.content.trigger(this.document, this);
					}.bind(this)).then(function () {
						loading.resolve(this.contents);
					}.bind(this)).catch(function (error) {
						loading.reject(error);
					});
				}

				return loaded;
			}

			/**
	   * Adds a base tag for resolving urls in the section
	   * @private
	   */

		}, {
			key: "base",
			value: function base() {
				return replaceBase(this.document, this);
			}

			/**
	   * Render the contents of a section
	   * @param  {method} [_request] a request method to use for loading
	   * @return {string} output a serialized XML Document
	   */

		}, {
			key: "render",
			value: function render(_request) {
				var rendering = new defer();
				var rendered = rendering.promise;
				this.output; // TODO: better way to return this from hooks?

				this.load(_request).then(function (contents) {
					var userAgent = typeof navigator !== 'undefined' && navigator.userAgent || '';
					var isIE = userAgent.indexOf('Trident') >= 0;
					var Serializer;
					{
						Serializer = XMLSerializer;
					}
					var serializer = new Serializer();
					this.output = serializer.serializeToString(contents);
					return this.output;
				}.bind(this)).then(function () {
					return this.hooks.serialize.trigger(this.output, this);
				}.bind(this)).then(function () {
					rendering.resolve(this.output);
				}.bind(this)).catch(function (error) {
					rendering.reject(error);
				});

				return rendered;
			}

			/**
	   * Find a string in a section
	   * @param  {string} _query The query string to find
	   * @return {object[]} A list of matches, with form {cfi, excerpt}
	   */

		}, {
			key: "find",
			value: function find(_query) {
				var section = this;
				var matches = [];
				var query = _query.toLowerCase();
				var find = function find(node) {
					var text = node.textContent.toLowerCase();
					var range = section.document.createRange();
					var cfi;
					var pos;
					var last = -1;
					var excerpt;
					var limit = 150;

					while (pos != -1) {
						// Search for the query
						pos = text.indexOf(query, last + 1);

						if (pos != -1) {
							// We found it! Generate a CFI
							range = section.document.createRange();
							range.setStart(node, pos);
							range.setEnd(node, pos + query.length);

							cfi = section.cfiFromRange(range);

							// Generate the excerpt
							if (node.textContent.length < limit) {
								excerpt = node.textContent;
							} else {
								excerpt = node.textContent.substring(pos - limit / 2, pos + limit / 2);
								excerpt = "..." + excerpt + "...";
							}

							// Add the CFI to the matches list
							matches.push({
								cfi: cfi,
								excerpt: excerpt
							});
						}

						last = pos;
					}
				};

				sprint(section.document, function (node) {
					find(node);
				});

				return matches;
			}
		}, {
			key: "reconcileLayoutSettings",


			/**
	  * Reconciles the current chapters layout properies with
	  * the global layout properities.
	  * @param {object} globalLayout  The global layout settings object, chapter properties string
	  * @return {object} layoutProperties Object with layout properties
	  */
			value: function reconcileLayoutSettings(globalLayout) {
				//-- Get the global defaults
				var settings = {
					layout: globalLayout.layout,
					spread: globalLayout.spread,
					orientation: globalLayout.orientation
				};

				//-- Get the chapter's display type
				this.properties.forEach(function (prop) {
					var rendition = prop.replace("rendition:", "");
					var split = rendition.indexOf("-");
					var property, value;

					if (split != -1) {
						property = rendition.slice(0, split);
						value = rendition.slice(split + 1);

						settings[property] = value;
					}
				});
				return settings;
			}

			/**
	   * Get a CFI from a Range in the Section
	   * @param  {range} _range
	   * @return {string} cfi an EpubCFI string
	   */

		}, {
			key: "cfiFromRange",
			value: function cfiFromRange(_range) {
				return new EpubCFI(_range, this.cfiBase).toString();
			}

			/**
	   * Get a CFI from an Element in the Section
	   * @param  {element} el
	   * @return {string} cfi an EpubCFI string
	   */

		}, {
			key: "cfiFromElement",
			value: function cfiFromElement(el) {
				return new EpubCFI(el, this.cfiBase).toString();
			}

			/**
	   * Unload the section document
	   */

		}, {
			key: "unload",
			value: function unload() {
				this.document = undefined;
				this.contents = undefined;
				this.output = undefined;
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.unload();
				this.hooks.serialize.clear();
				this.hooks.content.clear();

				this.hooks = undefined;
				this.idref = undefined;
				this.linear = undefined;
				this.properties = undefined;
				this.index = undefined;
				this.href = undefined;
				this.url = undefined;
				this.next = undefined;
				this.prev = undefined;

				this.cfiBase = undefined;
			}
		}]);

		return Section;
	}();

	var _createClass$6 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$6(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * A collection of Spine Items
	 */

	var Spine = function () {
		function Spine() {
			_classCallCheck$6(this, Spine);

			this.spineItems = [];
			this.spineByHref = {};
			this.spineById = {};

			this.hooks = {};
			this.hooks.serialize = new Hook();
			this.hooks.content = new Hook();

			// Register replacements
			this.hooks.content.register(replaceBase);
			this.hooks.content.register(replaceCanonical);
			this.hooks.content.register(replaceMeta);

			this.epubcfi = new EpubCFI();

			this.loaded = false;

			this.items = undefined;
			this.manifest = undefined;
			this.spineNodeIndex = undefined;
			this.baseUrl = undefined;
			this.length = undefined;
		}

		/**
	  * Unpack items from a opf into spine items
	  * @param  {Packaging} _package
	  * @param  {method} resolver URL resolver
	  * @param  {method} canonical Resolve canonical url
	  */


		_createClass$6(Spine, [{
			key: "unpack",
			value: function unpack(_package, resolver, canonical) {
				var _this = this;

				this.items = _package.spine;
				this.manifest = _package.manifest;
				this.spineNodeIndex = _package.spineNodeIndex;
				this.baseUrl = _package.baseUrl || _package.basePath || "";
				this.length = this.items.length;

				this.items.forEach(function (item, index) {
					var manifestItem = _this.manifest[item.idref];
					var spineItem;

					item.index = index;
					item.cfiBase = _this.epubcfi.generateChapterComponent(_this.spineNodeIndex, item.index, item.idref);

					if (item.href) {
						item.url = resolver(item.href, true);
						item.canonical = canonical(item.href);
					}

					if (manifestItem) {
						item.href = manifestItem.href;
						item.url = resolver(item.href, true);
						item.canonical = canonical(item.href);

						if (manifestItem.properties.length) {
							item.properties.push.apply(item.properties, manifestItem.properties);
						}
					}

					if (item.linear === "yes") {
						item.prev = function () {
							var prevIndex = item.index;
							while (prevIndex > 0) {
								var prev = this.get(prevIndex - 1);
								if (prev && prev.linear) {
									return prev;
								}
								prevIndex -= 1;
							}
							return;
						}.bind(_this);
						item.next = function () {
							var nextIndex = item.index;
							while (nextIndex < this.spineItems.length - 1) {
								var next = this.get(nextIndex + 1);
								if (next && next.linear) {
									return next;
								}
								nextIndex += 1;
							}
							return;
						}.bind(_this);
					} else {
						item.prev = function () {
							return;
						};
						item.next = function () {
							return;
						};
					}

					spineItem = new Section(item, _this.hooks);

					_this.append(spineItem);
				});

				this.loaded = true;
			}

			/**
	   * Get an item from the spine
	   * @param  {string|number} [target]
	   * @return {Section} section
	   * @example spine.get();
	   * @example spine.get(1);
	   * @example spine.get("chap1.html");
	   * @example spine.get("#id1234");
	   */

		}, {
			key: "get",
			value: function get(target) {
				var index = 0;

				if (typeof target === "undefined") {
					while (index < this.spineItems.length) {
						var next = this.spineItems[index];
						if (next && next.linear) {
							break;
						}
						index += 1;
					}
				} else if (this.epubcfi.isCfiString(target)) {
					var cfi = new EpubCFI(target);
					index = cfi.spinePos;
				} else if (typeof target === "number" || isNaN(target) === false) {
					index = target;
				} else if (typeof target === "string" && target.indexOf("#") === 0) {
					index = this.spineById[target.substring(1)];
				} else if (typeof target === "string") {
					// Remove fragments
					target = target.split("#")[0];
					index = this.spineByHref[target] || this.spineByHref[encodeURI(target)];
				}

				return this.spineItems[index] || null;
			}

			/**
	   * Append a Section to the Spine
	   * @private
	   * @param  {Section} section
	   */

		}, {
			key: "append",
			value: function append(section) {
				var index = this.spineItems.length;
				section.index = index;

				this.spineItems.push(section);

				// Encode and Decode href lookups
				// see pr for details: https://github.com/futurepress/epub.js/pull/358
				this.spineByHref[decodeURI(section.href)] = index;
				this.spineByHref[encodeURI(section.href)] = index;
				this.spineByHref[section.href] = index;

				this.spineById[section.idref] = index;

				return index;
			}

			/**
	   * Prepend a Section to the Spine
	   * @private
	   * @param  {Section} section
	   */

		}, {
			key: "prepend",
			value: function prepend(section) {
				// var index = this.spineItems.unshift(section);
				this.spineByHref[section.href] = 0;
				this.spineById[section.idref] = 0;

				// Re-index
				this.spineItems.forEach(function (item, index) {
					item.index = index;
				});

				return 0;
			}

			// insert(section, index) {
			//
			// };

			/**
	   * Remove a Section from the Spine
	   * @private
	   * @param  {Section} section
	   */

		}, {
			key: "remove",
			value: function remove(section) {
				var index = this.spineItems.indexOf(section);

				if (index > -1) {
					delete this.spineByHref[section.href];
					delete this.spineById[section.idref];

					return this.spineItems.splice(index, 1);
				}
			}

			/**
	   * Loop over the Sections in the Spine
	   * @return {method} forEach
	   */

		}, {
			key: "each",
			value: function each() {
				return this.spineItems.forEach.apply(this.spineItems, arguments);
			}

			/**
	   * Find the first Section in the Spine
	   * @return {Section} first section
	   */

		}, {
			key: "first",
			value: function first() {
				var index = 0;

				do {
					var next = this.get(index);

					if (next && next.linear) {
						return next;
					}
					index += 1;
				} while (index < this.spineItems.length);
			}

			/**
	   * Find the last Section in the Spine
	   * @return {Section} last section
	   */

		}, {
			key: "last",
			value: function last() {
				var index = this.spineItems.length - 1;

				do {
					var prev = this.get(index);
					if (prev && prev.linear) {
						return prev;
					}
					index -= 1;
				} while (index >= 0);
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.each(function (section) {
					return section.destroy();
				});

				this.spineItems = undefined;
				this.spineByHref = undefined;
				this.spineById = undefined;

				this.hooks.serialize.clear();
				this.hooks.content.clear();
				this.hooks = undefined;

				this.epubcfi = undefined;

				this.loaded = false;

				this.items = undefined;
				this.manifest = undefined;
				this.spineNodeIndex = undefined;
				this.baseUrl = undefined;
				this.length = undefined;
			}
		}]);

		return Spine;
	}();

	var _createClass$7 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$7(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Queue for handling tasks one at a time
	 * @class
	 * @param {scope} context what this will resolve to in the tasks
	 */

	var Queue = function () {
		function Queue(context) {
			_classCallCheck$7(this, Queue);

			this._q = [];
			this.context = context;
			this.tick = requestAnimationFrame$1;
			this.running = false;
			this.paused = false;
		}

		/**
	  * Add an item to the queue
	  * @return {Promise}
	  */


		_createClass$7(Queue, [{
			key: "enqueue",
			value: function enqueue() {
				var deferred, promise;
				var queued;
				var task = [].shift.call(arguments);
				var args = arguments;

				// Handle single args without context
				// if(args && !Array.isArray(args)) {
				//   args = [args];
				// }
				if (!task) {
					throw new Error("No Task Provided");
				}

				if (typeof task === "function") {

					deferred = new defer();
					promise = deferred.promise;

					queued = {
						"task": task,
						"args": args,
						//"context"  : context,
						"deferred": deferred,
						"promise": promise
					};
				} else {
					// Task is a promise
					queued = {
						"promise": task
					};
				}

				this._q.push(queued);

				// Wait to start queue flush
				if (this.paused == false && !this.running) {
					// setTimeout(this.flush.bind(this), 0);
					// this.tick.call(window, this.run.bind(this));
					this.run();
				}

				return queued.promise;
			}

			/**
	   * Run one item
	   * @return {Promise}
	   */

		}, {
			key: "dequeue",
			value: function dequeue() {
				var inwait, task, result;

				if (this._q.length && !this.paused) {
					inwait = this._q.shift();
					task = inwait.task;
					if (task) {
						// console.log(task)

						result = task.apply(this.context, inwait.args);

						if (result && typeof result["then"] === "function") {
							// Task is a function that returns a promise
							return result.then(function () {
								inwait.deferred.resolve.apply(this.context, arguments);
							}.bind(this), function () {
								inwait.deferred.reject.apply(this.context, arguments);
							}.bind(this));
						} else {
							// Task resolves immediately
							inwait.deferred.resolve.apply(this.context, result);
							return inwait.promise;
						}
					} else if (inwait.promise) {
						// Task is a promise
						return inwait.promise;
					}
				} else {
					inwait = new defer();
					inwait.deferred.resolve();
					return inwait.promise;
				}
			}

			// Run All Immediately

		}, {
			key: "dump",
			value: function dump() {
				while (this._q.length) {
					this.dequeue();
				}
			}

			/**
	   * Run all tasks sequentially, at convince
	   * @return {Promise}
	   */

		}, {
			key: "run",
			value: function run() {
				var _this = this;

				if (!this.running) {
					this.running = true;
					this.defered = new defer();
				}

				this.tick.call(window, function () {

					if (_this._q.length) {

						_this.dequeue().then(function () {
							this.run();
						}.bind(_this));
					} else {
						_this.defered.resolve();
						_this.running = undefined;
					}
				});

				// Unpause
				if (this.paused == true) {
					this.paused = false;
				}

				return this.defered.promise;
			}

			/**
	   * Flush all, as quickly as possible
	   * @return {Promise}
	   */

		}, {
			key: "flush",
			value: function flush() {

				if (this.running) {
					return this.running;
				}

				if (this._q.length) {
					this.running = this.dequeue().then(function () {
						this.running = undefined;
						return this.flush();
					}.bind(this));

					return this.running;
				}
			}

			/**
	   * Clear all items in wait
	   */

		}, {
			key: "clear",
			value: function clear() {
				this._q = [];
			}

			/**
	   * Get the number of tasks in the queue
	   * @return {number} tasks
	   */

		}, {
			key: "length",
			value: function length() {
				return this._q.length;
			}

			/**
	   * Pause a running queue
	   */

		}, {
			key: "pause",
			value: function pause() {
				this.paused = true;
			}

			/**
	   * End the queue
	   */

		}, {
			key: "stop",
			value: function stop() {
				this._q = [];
				this.running = false;
				this.paused = true;
			}
		}]);

		return Queue;
	}();

	var EPUBJS_VERSION = "0.3";

	// Dom events to listen for
	var DOM_EVENTS = ["keydown", "keyup", "keypressed", "mouseup", "mousedown", "click", "touchend", "touchstart", "touchmove"];

	var EVENTS = {
	  BOOK: {
	    OPEN_FAILED: "openFailed"
	  },
	  CONTENTS: {
	    EXPAND: "expand",
	    RESIZE: "resize",
	    SELECTED: "selected",
	    SELECTED_RANGE: "selectedRange",
	    LINK_CLICKED: "linkClicked"
	  },
	  LOCATIONS: {
	    CHANGED: "changed"
	  },
	  MANAGERS: {
	    RESIZE: "resize",
	    RESIZED: "resized",
	    ORIENTATION_CHANGE: "orientationchange",
	    ADDED: "added",
	    SCROLL: "scroll",
	    SCROLLED: "scrolled",
	    REMOVED: "removed"
	  },
	  VIEWS: {
	    AXIS: "axis",
	    LOAD_ERROR: "loaderror",
	    RENDERED: "rendered",
	    RESIZED: "resized",
	    DISPLAYED: "displayed",
	    SHOWN: "shown",
	    HIDDEN: "hidden",
	    MARK_CLICKED: "markClicked"
	  },
	  RENDITION: {
	    STARTED: "started",
	    ATTACHED: "attached",
	    DISPLAYED: "displayed",
	    DISPLAY_ERROR: "displayerror",
	    RENDERED: "rendered",
	    REMOVED: "removed",
	    RESIZED: "resized",
	    ORIENTATION_CHANGE: "orientationchange",
	    LOCATION_CHANGED: "locationChanged",
	    RELOCATED: "relocated",
	    MARK_CLICKED: "markClicked",
	    SELECTED: "selected",
	    LAYOUT: "layout"
	  },
	  LAYOUT: {
	    UPDATED: "updated"
	  }
	};

	var _createClass$8 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$8(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Find Locations for a Book
	 * @param {Spine} spine
	 * @param {request} request
	 * @param {number} [pause=100]
	 */

	var Locations = function () {
		function Locations(spine, request, pause) {
			_classCallCheck$8(this, Locations);

			this.spine = spine;
			this.request = request;
			this.pause = pause || 100;

			this.q = new Queue(this);
			this.epubcfi = new EpubCFI();

			this._locations = [];
			this.total = 0;

			this.break = 150;

			this._current = 0;

			this.currentLocation = '';
			this._currentCfi = '';
			this.processingTimeout = undefined;
		}

		/**
	  * Load all of sections in the book to generate locations
	  * @param  {int} chars how many chars to split on
	  * @return {object} locations
	  */


		_createClass$8(Locations, [{
			key: "generate",
			value: function generate(chars) {

				if (chars) {
					this.break = chars;
				}

				this.q.pause();

				this.spine.each(function (section) {
					if (section.linear) {
						this.q.enqueue(this.process.bind(this), section);
					}
				}.bind(this));

				return this.q.run().then(function () {
					this.total = this._locations.length - 1;

					if (this._currentCfi) {
						this.currentLocation = this._currentCfi;
					}

					return this._locations;
					// console.log(this.percentage(this.book.rendition.location.start), this.percentage(this.book.rendition.location.end));
				}.bind(this));
			}
		}, {
			key: "createRange",
			value: function createRange() {
				return {
					startContainer: undefined,
					startOffset: undefined,
					endContainer: undefined,
					endOffset: undefined
				};
			}
		}, {
			key: "process",
			value: function process(section) {

				return section.load(this.request).then(function (contents) {
					var completed = new defer();
					var locations = this.parse(contents, section.cfiBase);
					this._locations = this._locations.concat(locations);

					section.unload();

					this.processingTimeout = setTimeout(function () {
						return completed.resolve(locations);
					}, this.pause);
					return completed.promise;
				}.bind(this));
			}
		}, {
			key: "parse",
			value: function parse$$1(contents, cfiBase, chars) {
				var locations = [];
				var range;
				var doc = contents.ownerDocument;
				var body = qs(doc, "body");
				var counter = 0;
				var prev;
				var _break = chars || this.break;
				var parser = function parser(node) {
					var len = node.length;
					var dist;
					var pos = 0;

					if (node.textContent.trim().length === 0) {
						return false; // continue
					}

					// Start range
					if (counter == 0) {
						range = this.createRange();
						range.startContainer = node;
						range.startOffset = 0;
					}

					dist = _break - counter;

					// Node is smaller than a break,
					// skip over it
					if (dist > len) {
						counter += len;
						pos = len;
					}

					while (pos < len) {
						dist = _break - counter;

						if (counter === 0) {
							// Start new range
							pos += 1;
							range = this.createRange();
							range.startContainer = node;
							range.startOffset = pos;
						}

						// pos += dist;

						// Gone over
						if (pos + dist >= len) {
							// Continue counter for next node
							counter += len - pos;
							// break
							pos = len;
							// At End
						} else {
							// Advance pos
							pos += dist;

							// End the previous range
							range.endContainer = node;
							range.endOffset = pos;
							// cfi = section.cfiFromRange(range);
							var cfi = new EpubCFI(range, cfiBase).toString();
							locations.push(cfi);
							counter = 0;
						}
					}
					prev = node;
				};

				sprint(body, parser.bind(this));

				// Close remaining
				if (range && range.startContainer && prev) {
					range.endContainer = prev;
					range.endOffset = prev.length;
					var cfi = new EpubCFI(range, cfiBase).toString();
					locations.push(cfi);
					counter = 0;
				}

				return locations;
			}

			/**
	   * Get a location from an EpubCFI
	   * @param {EpubCFI} cfi
	   * @return {number}
	   */

		}, {
			key: "locationFromCfi",
			value: function locationFromCfi(cfi) {
				var loc = void 0;
				if (EpubCFI.prototype.isCfiString(cfi)) {
					cfi = new EpubCFI(cfi);
				}
				// Check if the location has not been set yet
				if (this._locations.length === 0) {
					return -1;
				}

				loc = locationOf(cfi, this._locations, this.epubcfi.compare);

				if (loc > this.total) {
					return this.total;
				}

				return loc;
			}

			/**
	   * Get a percentage position in locations from an EpubCFI
	   * @param {EpubCFI} cfi
	   * @return {number}
	   */

		}, {
			key: "percentageFromCfi",
			value: function percentageFromCfi(cfi) {
				if (this._locations.length === 0) {
					return null;
				}
				// Find closest cfi
				var loc = this.locationFromCfi(cfi);
				// Get percentage in total
				return this.percentageFromLocation(loc);
			}

			/**
	   * Get a percentage position from a location index
	   * @param {number} location
	   * @return {number}
	   */

		}, {
			key: "percentageFromLocation",
			value: function percentageFromLocation(loc) {
				if (!loc || !this.total) {
					return 0;
				}

				return loc / this.total;
			}

			/**
	   * Get an EpubCFI from location index
	   * @param {number} loc
	   * @return {EpubCFI} cfi
	   */

		}, {
			key: "cfiFromLocation",
			value: function cfiFromLocation(loc) {
				var cfi = -1;
				// check that pg is an int
				if (typeof loc != "number") {
					loc = parseInt(loc);
				}

				if (loc >= 0 && loc < this._locations.length) {
					cfi = this._locations[loc];
				}

				return cfi;
			}

			/**
	   * Get an EpubCFI from location percentage
	   * @param {number} percentage
	   * @return {EpubCFI} cfi
	   */

		}, {
			key: "cfiFromPercentage",
			value: function cfiFromPercentage(percentage) {
				var loc = void 0;
				if (percentage > 1) {
					console.warn("Normalize cfiFromPercentage value to between 0 - 1");
				}

				// Make sure 1 goes to very end
				if (percentage >= 1) {
					var cfi = new EpubCFI(this._locations[this.total]);
					cfi.collapse();
					return cfi.toString();
				}

				loc = Math.ceil(this.total * percentage);
				return this.cfiFromLocation(loc);
			}

			/**
	   * Load locations from JSON
	   * @param {json} locations
	   */

		}, {
			key: "load",
			value: function load(locations) {
				if (typeof locations === "string") {
					this._locations = JSON.parse(locations);
				} else {
					this._locations = locations;
				}
				this.total = this._locations.length - 1;
				return this._locations;
			}

			/**
	   * Save locations to JSON
	   * @return {json}
	   */

		}, {
			key: "save",
			value: function save() {
				return JSON.stringify(this._locations);
			}
		}, {
			key: "getCurrent",
			value: function getCurrent() {
				return this._current;
			}
		}, {
			key: "setCurrent",
			value: function setCurrent(curr) {
				var loc;

				if (typeof curr == "string") {
					this._currentCfi = curr;
				} else if (typeof curr == "number") {
					this._current = curr;
				} else {
					return;
				}

				if (this._locations.length === 0) {
					return;
				}

				if (typeof curr == "string") {
					loc = this.locationFromCfi(curr);
					this._current = loc;
				} else {
					loc = curr;
				}

				this.emit(EVENTS.LOCATIONS.CHANGED, {
					percentage: this.percentageFromLocation(loc)
				});
			}

			/**
	   * Get the current location
	   */

		}, {
			key: "length",


			/**
	   * Locations length
	   */
			value: function length() {
				return this._locations.length;
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.spine = undefined;
				this.request = undefined;
				this.pause = undefined;

				this.q.stop();
				this.q = undefined;
				this.epubcfi = undefined;

				this._locations = undefined;
				this.total = undefined;

				this.break = undefined;
				this._current = undefined;

				this.currentLocation = undefined;
				this._currentCfi = undefined;
				clearTimeout(this.processingTimeout);
			}
		}, {
			key: "currentLocation",
			get: function get() {
				return this._current;
			}

			/**
	   * Set the current location
	   */
			,
			set: function set(curr) {
				this.setCurrent(curr);
			}
		}]);

		return Locations;
	}();

	eventEmitter(Locations.prototype);

	var _createClass$9 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$9(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Handles Parsing and Accessing an Epub Container
	 * @class
	 * @param {document} [containerDocument] xml document
	 */

	var Container = function () {
		function Container(containerDocument) {
			_classCallCheck$9(this, Container);

			this.packagePath = '';
			this.directory = '';
			this.encoding = '';

			if (containerDocument) {
				this.parse(containerDocument);
			}
		}

		/**
	  * Parse the Container XML
	  * @param  {document} containerDocument
	  */


		_createClass$9(Container, [{
			key: "parse",
			value: function parse$$1(containerDocument) {
				//-- <rootfile full-path="OPS/package.opf" media-type="application/oebps-package+xml"/>
				var rootfile;

				if (!containerDocument) {
					throw new Error("Container File Not Found");
				}

				rootfile = qs(containerDocument, "rootfile");

				if (!rootfile) {
					throw new Error("No RootFile Found");
				}

				this.packagePath = rootfile.getAttribute("full-path");
				this.directory = path.dirname(this.packagePath);
				this.encoding = containerDocument.xmlEncoding;
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.packagePath = undefined;
				this.directory = undefined;
				this.encoding = undefined;
			}
		}]);

		return Container;
	}();

	var _createClass$a = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$a(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Open Packaging Format Parser
	 * @class
	 * @param {document} packageDocument OPF XML
	 */

	var Packaging = function () {
		function Packaging(packageDocument) {
			_classCallCheck$a(this, Packaging);

			this.manifest = {};
			this.navPath = '';
			this.ncxPath = '';
			this.coverPath = '';
			this.spineNodeIndex = 0;
			this.spine = [];
			this.metadata = {};

			if (packageDocument) {
				this.parse(packageDocument);
			}
		}

		/**
	  * Parse OPF XML
	  * @param  {document} packageDocument OPF XML
	  * @return {object} parsed package parts
	  */


		_createClass$a(Packaging, [{
			key: 'parse',
			value: function parse$$1(packageDocument) {
				var metadataNode, manifestNode, spineNode;

				if (!packageDocument) {
					throw new Error("Package File Not Found");
				}

				metadataNode = qs(packageDocument, "metadata");
				if (!metadataNode) {
					throw new Error("No Metadata Found");
				}

				manifestNode = qs(packageDocument, "manifest");
				if (!manifestNode) {
					throw new Error("No Manifest Found");
				}

				spineNode = qs(packageDocument, "spine");
				if (!spineNode) {
					throw new Error("No Spine Found");
				}

				this.manifest = this.parseManifest(manifestNode);
				this.navPath = this.findNavPath(manifestNode);
				this.ncxPath = this.findNcxPath(manifestNode, spineNode);
				this.coverPath = this.findCoverPath(packageDocument);

				this.spineNodeIndex = indexOfElementNode(spineNode);

				this.spine = this.parseSpine(spineNode, this.manifest);

				this.uniqueIdentifier = this.findUniqueIdentifier(packageDocument);
				this.metadata = this.parseMetadata(metadataNode);

				this.metadata.direction = spineNode.getAttribute("page-progression-direction");

				return {
					"metadata": this.metadata,
					"spine": this.spine,
					"manifest": this.manifest,
					"navPath": this.navPath,
					"ncxPath": this.ncxPath,
					"coverPath": this.coverPath,
					"spineNodeIndex": this.spineNodeIndex
				};
			}

			/**
	   * Parse Metadata
	   * @private
	   * @param  {node} xml
	   * @return {object} metadata
	   */

		}, {
			key: 'parseMetadata',
			value: function parseMetadata(xml) {
				var metadata = {};

				metadata.title = this.getElementText(xml, "title");
				metadata.creator = this.getElementText(xml, "creator");
				metadata.description = this.getElementText(xml, "description");

				metadata.pubdate = this.getElementText(xml, "date");

				metadata.publisher = this.getElementText(xml, "publisher");

				metadata.identifier = this.getElementText(xml, "identifier");
				metadata.language = this.getElementText(xml, "language");
				metadata.rights = this.getElementText(xml, "rights");

				metadata.modified_date = this.getPropertyText(xml, "dcterms:modified");

				metadata.layout = this.getPropertyText(xml, "rendition:layout");
				metadata.orientation = this.getPropertyText(xml, "rendition:orientation");
				metadata.flow = this.getPropertyText(xml, "rendition:flow");
				metadata.viewport = this.getPropertyText(xml, "rendition:viewport");
				metadata.media_active_class = this.getPropertyText(xml, "media:active-class");
				// metadata.page_prog_dir = packageXml.querySelector("spine").getAttribute("page-progression-direction");

				return metadata;
			}

			/**
	   * Parse Manifest
	   * @private
	   * @param  {node} manifestXml
	   * @return {object} manifest
	   */

		}, {
			key: 'parseManifest',
			value: function parseManifest(manifestXml) {
				var manifest = {};

				//-- Turn items into an array
				// var selected = manifestXml.querySelectorAll("item");
				var selected = qsa(manifestXml, "item");
				var items = Array.prototype.slice.call(selected);

				//-- Create an object with the id as key
				items.forEach(function (item) {
					var id = item.getAttribute("id"),
					    href = item.getAttribute("href") || "",
					    type$$1 = item.getAttribute("media-type") || "",
					    overlay = item.getAttribute("media-overlay") || "",
					    properties = item.getAttribute("properties") || "";

					manifest[id] = {
						"href": href,
						// "url" : href,
						"type": type$$1,
						"overlay": overlay,
						"properties": properties.length ? properties.split(" ") : []
					};
				});

				return manifest;
			}

			/**
	   * Parse Spine
	   * @private
	   * @param  {node} spineXml
	   * @param  {Packaging.manifest} manifest
	   * @return {object} spine
	   */

		}, {
			key: 'parseSpine',
			value: function parseSpine(spineXml, manifest) {
				var spine = [];

				var selected = qsa(spineXml, "itemref");
				var items = Array.prototype.slice.call(selected);

				// var epubcfi = new EpubCFI();

				//-- Add to array to mantain ordering and cross reference with manifest
				items.forEach(function (item, index) {
					var idref = item.getAttribute("idref");
					// var cfiBase = epubcfi.generateChapterComponent(spineNodeIndex, index, Id);
					var props = item.getAttribute("properties") || "";
					var propArray = props.length ? props.split(" ") : [];
					// var manifestProps = manifest[Id].properties;
					// var manifestPropArray = manifestProps.length ? manifestProps.split(" ") : [];

					var itemref = {
						"idref": idref,
						"linear": item.getAttribute("linear") || "yes",
						"properties": propArray,
						// "href" : manifest[Id].href,
						// "url" :  manifest[Id].url,
						"index": index
						// "cfiBase" : cfiBase
					};
					spine.push(itemref);
				});

				return spine;
			}

			/**
	   * Find Unique Identifier
	   * @private
	   * @param  {node} packageXml
	   * @return {string} Unique Identifier text
	   */

		}, {
			key: 'findUniqueIdentifier',
			value: function findUniqueIdentifier(packageXml) {
				var uniqueIdentifierId = packageXml.documentElement.getAttribute("unique-identifier");
				if (!uniqueIdentifierId) {
					return "";
				}
				var identifier = packageXml.getElementById(uniqueIdentifierId);
				if (!identifier) {
					return "";
				}

				if (identifier.localName === "identifier" && identifier.namespaceURI === "http://purl.org/dc/elements/1.1/") {
					return identifier.childNodes[0].nodeValue.trim();
				}

				return "";
			}

			/**
	   * Find TOC NAV
	   * @private
	   * @param {element} manifestNode
	   * @return {string}
	   */

		}, {
			key: 'findNavPath',
			value: function findNavPath(manifestNode) {
				// Find item with property "nav"
				// Should catch nav irregardless of order
				// var node = manifestNode.querySelector("item[properties$='nav'], item[properties^='nav '], item[properties*=' nav ']");
				var node = qsp(manifestNode, "item", { "properties": "nav" });
				return node ? node.getAttribute("href") : false;
			}

			/**
	   * Find TOC NCX
	   * media-type="application/x-dtbncx+xml" href="toc.ncx"
	   * @private
	   * @param {element} manifestNode
	   * @param {element} spineNode
	   * @return {string}
	   */

		}, {
			key: 'findNcxPath',
			value: function findNcxPath(manifestNode, spineNode) {
				// var node = manifestNode.querySelector("item[media-type='application/x-dtbncx+xml']");
				var node = qsp(manifestNode, "item", { "media-type": "application/x-dtbncx+xml" });
				var tocId;

				// If we can't find the toc by media-type then try to look for id of the item in the spine attributes as
				// according to http://www.idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#Section2.4.1.2,
				// "The item that describes the NCX must be referenced by the spine toc attribute."
				if (!node) {
					tocId = spineNode.getAttribute("toc");
					if (tocId) {
						// node = manifestNode.querySelector("item[id='" + tocId + "']");
						node = manifestNode.querySelector('#' + tocId);
					}
				}

				return node ? node.getAttribute("href") : false;
			}

			/**
	   * Find the Cover Path
	   * <item properties="cover-image" id="ci" href="cover.svg" media-type="image/svg+xml" />
	   * Fallback for Epub 2.0
	   * @private
	   * @param  {node} packageXml
	   * @return {string} href
	   */

		}, {
			key: 'findCoverPath',
			value: function findCoverPath(packageXml) {
				var pkg = qs(packageXml, "package");
				var epubVersion = pkg.getAttribute("version");

				if (epubVersion === "2.0") {
					var metaCover = qsp(packageXml, "meta", { "name": "cover" });
					if (metaCover) {
						var coverId = metaCover.getAttribute("content");
						// var cover = packageXml.querySelector("item[id='" + coverId + "']");
						var cover = packageXml.getElementById(coverId);
						return cover ? cover.getAttribute("href") : "";
					} else {
						return false;
					}
				} else {
					// var node = packageXml.querySelector("item[properties='cover-image']");
					var node = qsp(packageXml, "item", { "properties": "cover-image" });
					return node ? node.getAttribute("href") : "";
				}
			}

			/**
	   * Get text of a namespaced element
	   * @private
	   * @param  {node} xml
	   * @param  {string} tag
	   * @return {string} text
	   */

		}, {
			key: 'getElementText',
			value: function getElementText(xml, tag) {
				var found = xml.getElementsByTagNameNS("http://purl.org/dc/elements/1.1/", tag);
				var el;

				if (!found || found.length === 0) return "";

				el = found[0];

				if (el.childNodes.length) {
					return el.childNodes[0].nodeValue;
				}

				return "";
			}

			/**
	   * Get text by property
	   * @private
	   * @param  {node} xml
	   * @param  {string} property
	   * @return {string} text
	   */

		}, {
			key: 'getPropertyText',
			value: function getPropertyText(xml, property) {
				var el = qsp(xml, "meta", { "property": property });

				if (el && el.childNodes.length) {
					return el.childNodes[0].nodeValue;
				}

				return "";
			}

			/**
	   * Load JSON Manifest
	   * @param  {document} packageDocument OPF XML
	   * @return {object} parsed package parts
	   */

		}, {
			key: 'load',
			value: function load(json) {
				var _this = this;

				this.metadata = json.metadata;

				var spine = json.readingOrder || json.spine;
				this.spine = spine.map(function (item, index) {
					item.index = index;
					return item;
				});

				json.resources.forEach(function (item, index) {
					_this.manifest[index] = item;

					if (item.rel && item.rel[0] === "cover") {
						_this.coverPath = item.href;
					}
				});

				this.spineNodeIndex = 0;

				this.toc = json.toc.map(function (item, index) {
					item.label = item.title;
					return item;
				});

				return {
					"metadata": this.metadata,
					"spine": this.spine,
					"manifest": this.manifest,
					"navPath": this.navPath,
					"ncxPath": this.ncxPath,
					"coverPath": this.coverPath,
					"spineNodeIndex": this.spineNodeIndex,
					"toc": this.toc
				};
			}
		}, {
			key: 'destroy',
			value: function destroy() {
				this.manifest = undefined;
				this.navPath = undefined;
				this.ncxPath = undefined;
				this.coverPath = undefined;
				this.spineNodeIndex = undefined;
				this.spine = undefined;
				this.metadata = undefined;
			}
		}]);

		return Packaging;
	}();

	var _createClass$b = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$b(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Navigation Parser
	 * @param {document} xml navigation html / xhtml / ncx
	 */

	var Navigation = function () {
		function Navigation(xml) {
			_classCallCheck$b(this, Navigation);

			this.toc = [];
			this.tocByHref = {};
			this.tocById = {};

			this.landmarks = [];
			this.landmarksByType = {};

			this.length = 0;
			if (xml) {
				this.parse(xml);
			}
		}

		/**
	  * Parse out the navigation items
	  * @param {document} xml navigation html / xhtml / ncx
	  */


		_createClass$b(Navigation, [{
			key: "parse",
			value: function parse$$1(xml) {
				var isXml$$1 = xml.nodeType;
				var html = void 0;
				var ncx = void 0;

				if (isXml$$1) {
					html = qs(xml, "html");
					ncx = qs(xml, "ncx");
				}

				if (!isXml$$1) {
					this.toc = this.load(xml);
				} else if (html) {
					this.toc = this.parseNav(xml);
					this.landmarks = this.parseLandmarks(xml);
				} else if (ncx) {
					this.toc = this.parseNcx(xml);
				}

				this.length = 0;

				this.unpack(this.toc);
			}

			/**
	   * Unpack navigation items
	   * @private
	   * @param  {array} toc
	   */

		}, {
			key: "unpack",
			value: function unpack(toc) {
				var item;

				for (var i = 0; i < toc.length; i++) {
					item = toc[i];

					if (item.href) {
						this.tocByHref[item.href] = i;
					}

					if (item.id) {
						this.tocById[item.id] = i;
					}

					this.length++;

					if (item.subitems.length) {
						this.unpack(item.subitems);
					}
				}
			}

			/**
	   * Get an item from the navigation
	   * @param  {string} target
	   * @return {object} navItem
	   */

		}, {
			key: "get",
			value: function get(target) {
				var index;

				if (!target) {
					return this.toc;
				}

				if (target.indexOf("#") === 0) {
					index = this.tocById[target.substring(1)];
				} else if (target in this.tocByHref) {
					index = this.tocByHref[target];
				}

				return this.toc[index];
			}

			/**
	   * Get a landmark by type
	   * List of types: https://idpf.github.io/epub-vocabs/structure/
	   * @param  {string} type
	   * @return {object} landmarkItem
	   */

		}, {
			key: "landmark",
			value: function landmark(type$$1) {
				var index;

				if (!type$$1) {
					return this.landmarks;
				}

				index = this.landmarksByType[type$$1];

				return this.landmarks[index];
			}

			/**
	   * Parse toc from a Epub > 3.0 Nav
	   * @private
	   * @param  {document} navHtml
	   * @return {array} navigation list
	   */

		}, {
			key: "parseNav",
			value: function parseNav(navHtml) {
				var navElement = querySelectorByType(navHtml, "nav", "toc");
				var navItems = navElement ? qsa(navElement, "li") : [];
				var length = navItems.length;
				var i;
				var toc = {};
				var list = [];
				var item, parent;

				if (!navItems || length === 0) return list;

				for (i = 0; i < length; ++i) {
					item = this.navItem(navItems[i]);
					if (item) {
						toc[item.id] = item;
						if (!item.parent) {
							list.push(item);
						} else {
							parent = toc[item.parent];
							parent.subitems.push(item);
						}
					}
				}

				return list;
			}

			/**
	   * Create a navItem
	   * @private
	   * @param  {element} item
	   * @return {object} navItem
	   */

		}, {
			key: "navItem",
			value: function navItem(item) {
				var id = item.getAttribute("id") || undefined;
				var content = filterChildren(item, "a", true);

				if (!content) {
					return;
				}

				var src = content.getAttribute("href") || "";

				if (!id) {
					id = src;
				}
				var text = content.textContent || "";
				var html = content.innerHTML;
				var subitems = [];
				var parentItem = getParentByTagName(item, "li");
				var parent = void 0;

				if (parentItem) {
					parent = parentItem.getAttribute("id");
					if (!parent) {
						var parentContent = filterChildren(parentItem, "a", true);
						parent = parentContent && parentContent.getAttribute("href");
					}
				}

				while (!parent && parentItem) {
					parentItem = getParentByTagName(parentItem, "li");
					if (parentItem) {
						parent = parentItem.getAttribute("id");
						if (!parent) {
							var _parentContent = filterChildren(parentItem, "a", true);
							parent = _parentContent && _parentContent.getAttribute("href");
						}
					}
				}

				return {
					"id": id,
					"href": src,
					"label": text,
					"html": html,
					"subitems": subitems,
					"parent": parent
				};
			}

			/**
	   * Parse landmarks from a Epub > 3.0 Nav
	   * @private
	   * @param  {document} navHtml
	   * @return {array} landmarks list
	   */

		}, {
			key: "parseLandmarks",
			value: function parseLandmarks(navHtml) {
				var navElement = querySelectorByType(navHtml, "nav", "landmarks");
				var navItems = navElement ? qsa(navElement, "li") : [];
				var length = navItems.length;
				var i;
				var list = [];
				var item;

				if (!navItems || length === 0) return list;

				for (i = 0; i < length; ++i) {
					item = this.landmarkItem(navItems[i]);
					if (item) {
						list.push(item);
						this.landmarksByType[item.type] = i;
					}
				}

				return list;
			}

			/**
	   * Create a landmarkItem
	   * @private
	   * @param  {element} item
	   * @return {object} landmarkItem
	   */

		}, {
			key: "landmarkItem",
			value: function landmarkItem(item) {
				var content = filterChildren(item, "a", true);

				if (!content) {
					return;
				}

				var type$$1 = content.getAttributeNS("http://www.idpf.org/2007/ops", "type") || undefined;
				var href = content.getAttribute("href") || "";
				var text = content.textContent || "";

				return {
					"href": href,
					"label": text,
					"type": type$$1
				};
			}

			/**
	   * Parse from a Epub > 3.0 NC
	   * @private
	   * @param  {document} navHtml
	   * @return {array} navigation list
	   */

		}, {
			key: "parseNcx",
			value: function parseNcx(tocXml) {
				var navPoints = qsa(tocXml, "navPoint");
				var length = navPoints.length;
				var i;
				var toc = {};
				var list = [];
				var item, parent;

				if (!navPoints || length === 0) return list;

				for (i = 0; i < length; ++i) {
					item = this.ncxItem(navPoints[i]);
					toc[item.id] = item;
					if (!item.parent) {
						list.push(item);
					} else {
						parent = toc[item.parent];
						parent.subitems.push(item);
					}
				}

				return list;
			}

			/**
	   * Create a ncxItem
	   * @private
	   * @param  {element} item
	   * @return {object} ncxItem
	   */

		}, {
			key: "ncxItem",
			value: function ncxItem(item) {
				var id = item.getAttribute("id") || false,
				    content = qs(item, "content"),
				    src = content.getAttribute("src"),
				    navLabel = qs(item, "navLabel"),
				    text = navLabel.textContent ? navLabel.textContent : "",
				    subitems = [],
				    parentNode = item.parentNode,
				    parent;

				if (parentNode && (parentNode.nodeName === "navPoint" || parentNode.nodeName.split(':').slice(-1)[0] === "navPoint")) {
					parent = parentNode.getAttribute("id");
				}

				return {
					"id": id,
					"href": src,
					"label": text,
					"subitems": subitems,
					"parent": parent
				};
			}

			/**
	   * Load Spine Items
	   * @param  {object} json the items to be loaded
	   * @return {Array} navItems
	   */

		}, {
			key: "load",
			value: function load(json) {
				var _this = this;

				return json.map(function (item) {
					item.label = item.title;
					item.subitems = item.children ? _this.load(item.children) : [];
					return item;
				});
			}

			/**
	   * forEach pass through
	   * @param  {Function} fn function to run on each item
	   * @return {method} forEach loop
	   */

		}, {
			key: "forEach",
			value: function forEach(fn) {
				return this.toc.forEach(fn);
			}
		}]);

		return Navigation;
	}();

	/*
	 From Zip.js, by Gildas Lormeau
	edited down
	 */

	var table = {
		"application": {
			"ecmascript": ["es", "ecma"],
			"javascript": "js",
			"ogg": "ogx",
			"pdf": "pdf",
			"postscript": ["ps", "ai", "eps", "epsi", "epsf", "eps2", "eps3"],
			"rdf+xml": "rdf",
			"smil": ["smi", "smil"],
			"xhtml+xml": ["xhtml", "xht"],
			"xml": ["xml", "xsl", "xsd", "opf", "ncx"],
			"zip": "zip",
			"x-httpd-eruby": "rhtml",
			"x-latex": "latex",
			"x-maker": ["frm", "maker", "frame", "fm", "fb", "book", "fbdoc"],
			"x-object": "o",
			"x-shockwave-flash": ["swf", "swfl"],
			"x-silverlight": "scr",
			"epub+zip": "epub",
			"font-tdpfr": "pfr",
			"inkml+xml": ["ink", "inkml"],
			"json": "json",
			"jsonml+json": "jsonml",
			"mathml+xml": "mathml",
			"metalink+xml": "metalink",
			"mp4": "mp4s",
			// "oebps-package+xml" : "opf",
			"omdoc+xml": "omdoc",
			"oxps": "oxps",
			"vnd.amazon.ebook": "azw",
			"widget": "wgt",
			// "x-dtbncx+xml" : "ncx",
			"x-dtbook+xml": "dtb",
			"x-dtbresource+xml": "res",
			"x-font-bdf": "bdf",
			"x-font-ghostscript": "gsf",
			"x-font-linux-psf": "psf",
			"x-font-otf": "otf",
			"x-font-pcf": "pcf",
			"x-font-snf": "snf",
			"x-font-ttf": ["ttf", "ttc"],
			"x-font-type1": ["pfa", "pfb", "pfm", "afm"],
			"x-font-woff": "woff",
			"x-mobipocket-ebook": ["prc", "mobi"],
			"x-mspublisher": "pub",
			"x-nzb": "nzb",
			"x-tgif": "obj",
			"xaml+xml": "xaml",
			"xml-dtd": "dtd",
			"xproc+xml": "xpl",
			"xslt+xml": "xslt",
			"internet-property-stream": "acx",
			"x-compress": "z",
			"x-compressed": "tgz",
			"x-gzip": "gz"
		},
		"audio": {
			"flac": "flac",
			"midi": ["mid", "midi", "kar", "rmi"],
			"mpeg": ["mpga", "mpega", "mp2", "mp3", "m4a", "mp2a", "m2a", "m3a"],
			"mpegurl": "m3u",
			"ogg": ["oga", "ogg", "spx"],
			"x-aiff": ["aif", "aiff", "aifc"],
			"x-ms-wma": "wma",
			"x-wav": "wav",
			"adpcm": "adp",
			"mp4": "mp4a",
			"webm": "weba",
			"x-aac": "aac",
			"x-caf": "caf",
			"x-matroska": "mka",
			"x-pn-realaudio-plugin": "rmp",
			"xm": "xm",
			"mid": ["mid", "rmi"]
		},
		"image": {
			"gif": "gif",
			"ief": "ief",
			"jpeg": ["jpeg", "jpg", "jpe"],
			"pcx": "pcx",
			"png": "png",
			"svg+xml": ["svg", "svgz"],
			"tiff": ["tiff", "tif"],
			"x-icon": "ico",
			"bmp": "bmp",
			"webp": "webp",
			"x-pict": ["pic", "pct"],
			"x-tga": "tga",
			"cis-cod": "cod"
		},
		"text": {
			"cache-manifest": ["manifest", "appcache"],
			"css": "css",
			"csv": "csv",
			"html": ["html", "htm", "shtml", "stm"],
			"mathml": "mml",
			"plain": ["txt", "text", "brf", "conf", "def", "list", "log", "in", "bas"],
			"richtext": "rtx",
			"tab-separated-values": "tsv",
			"x-bibtex": "bib"
		},
		"video": {
			"mpeg": ["mpeg", "mpg", "mpe", "m1v", "m2v", "mp2", "mpa", "mpv2"],
			"mp4": ["mp4", "mp4v", "mpg4"],
			"quicktime": ["qt", "mov"],
			"ogg": "ogv",
			"vnd.mpegurl": ["mxu", "m4u"],
			"x-flv": "flv",
			"x-la-asf": ["lsf", "lsx"],
			"x-mng": "mng",
			"x-ms-asf": ["asf", "asx", "asr"],
			"x-ms-wm": "wm",
			"x-ms-wmv": "wmv",
			"x-ms-wmx": "wmx",
			"x-ms-wvx": "wvx",
			"x-msvideo": "avi",
			"x-sgi-movie": "movie",
			"x-matroska": ["mpv", "mkv", "mk3d", "mks"],
			"3gpp2": "3g2",
			"h261": "h261",
			"h263": "h263",
			"h264": "h264",
			"jpeg": "jpgv",
			"jpm": ["jpm", "jpgm"],
			"mj2": ["mj2", "mjp2"],
			"vnd.ms-playready.media.pyv": "pyv",
			"vnd.uvvu.mp4": ["uvu", "uvvu"],
			"vnd.vivo": "viv",
			"webm": "webm",
			"x-f4v": "f4v",
			"x-m4v": "m4v",
			"x-ms-vob": "vob",
			"x-smv": "smv"
		}
	};

	var mimeTypes = function () {
		var type,
		    subtype,
		    val,
		    index,
		    mimeTypes = {};
		for (type in table) {
			if (table.hasOwnProperty(type)) {
				for (subtype in table[type]) {
					if (table[type].hasOwnProperty(subtype)) {
						val = table[type][subtype];
						if (typeof val == "string") {
							mimeTypes[val] = type + "/" + subtype;
						} else {
							for (index = 0; index < val.length; index++) {
								mimeTypes[val[index]] = type + "/" + subtype;
							}
						}
					}
				}
			}
		}
		return mimeTypes;
	}();

	var defaultValue = "text/plain"; //"application/octet-stream";

	function lookup(filename) {
		return filename && mimeTypes[filename.split(".").pop().toLowerCase()] || defaultValue;
	}
	var mime = {
		'lookup': lookup
	};

	var _createClass$c = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$c(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Handle Package Resources
	 * @class
	 * @param {Manifest} manifest
	 * @param {object} [options]
	 * @param {string} [options.replacements="base64"]
	 * @param {Archive} [options.archive]
	 * @param {method} [options.resolver]
	 */

	var Resources = function () {
		function Resources(manifest, options) {
			_classCallCheck$c(this, Resources);

			this.settings = {
				replacements: options && options.replacements || "base64",
				archive: options && options.archive,
				resolver: options && options.resolver,
				request: options && options.request
			};

			this.process(manifest);
		}

		/**
	  * Process resources
	  * @param {Manifest} manifest
	  */


		_createClass$c(Resources, [{
			key: "process",
			value: function process(manifest) {
				this.manifest = manifest;
				this.resources = Object.keys(manifest).map(function (key) {
					return manifest[key];
				});

				this.replacementUrls = [];

				this.html = [];
				this.assets = [];
				this.css = [];

				this.urls = [];
				this.cssUrls = [];

				this.split();
				this.splitUrls();
			}

			/**
	   * Split resources by type
	   * @private
	   */

		}, {
			key: "split",
			value: function split() {

				// HTML
				this.html = this.resources.filter(function (item) {
					if (item.type === "application/xhtml+xml" || item.type === "text/html") {
						return true;
					}
				});

				// Exclude HTML
				this.assets = this.resources.filter(function (item) {
					if (item.type !== "application/xhtml+xml" && item.type !== "text/html") {
						return true;
					}
				});

				// Only CSS
				this.css = this.resources.filter(function (item) {
					if (item.type === "text/css") {
						return true;
					}
				});
			}

			/**
	   * Convert split resources into Urls
	   * @private
	   */

		}, {
			key: "splitUrls",
			value: function splitUrls() {

				// All Assets Urls
				this.urls = this.assets.map(function (item) {
					return item.href;
				}.bind(this));

				// Css Urls
				this.cssUrls = this.css.map(function (item) {
					return item.href;
				});
			}

			/**
	   * Create a url to a resource
	   * @param {string} url
	   * @return {Promise<string>} Promise resolves with url string
	   */

		}, {
			key: "createUrl",
			value: function createUrl(url) {
				var parsedUrl = new Url(url);
				var mimeType = mime.lookup(parsedUrl.filename);

				if (this.settings.archive) {
					return this.settings.archive.createUrl(url, { "base64": this.settings.replacements === "base64" });
				} else {
					if (this.settings.replacements === "base64") {
						return this.settings.request(url, 'blob').then(function (blob) {
							return blob2base64(blob);
						}).then(function (blob) {
							return createBase64Url(blob, mimeType);
						});
					} else {
						return this.settings.request(url, 'blob').then(function (blob) {
							return createBlobUrl(blob, mimeType);
						});
					}
				}
			}

			/**
	   * Create blob urls for all the assets
	   * @return {Promise}         returns replacement urls
	   */

		}, {
			key: "replacements",
			value: function replacements() {
				var _this = this;

				if (this.settings.replacements === "none") {
					return new Promise(function (resolve) {
						resolve(this.urls);
					}.bind(this));
				}

				var replacements = this.urls.map(function (url) {
					var absolute = _this.settings.resolver(url);

					return _this.createUrl(absolute).catch(function (err) {
						console.error(err);
						return null;
					});
				});

				return Promise.all(replacements).then(function (replacementUrls) {
					_this.replacementUrls = replacementUrls.filter(function (url) {
						return typeof url === "string";
					});
					return replacementUrls;
				});
			}

			/**
	   * Replace URLs in CSS resources
	   * @private
	   * @param  {Archive} [archive]
	   * @param  {method} [resolver]
	   * @return {Promise}
	   */

		}, {
			key: "replaceCss",
			value: function replaceCss(archive, resolver) {
				var replaced = [];
				archive = archive || this.settings.archive;
				resolver = resolver || this.settings.resolver;
				this.cssUrls.forEach(function (href) {
					var replacement = this.createCssFile(href, archive, resolver).then(function (replacementUrl) {
						// switch the url in the replacementUrls
						var indexInUrls = this.urls.indexOf(href);
						if (indexInUrls > -1) {
							this.replacementUrls[indexInUrls] = replacementUrl;
						}
					}.bind(this));

					replaced.push(replacement);
				}.bind(this));
				return Promise.all(replaced);
			}

			/**
	   * Create a new CSS file with the replaced URLs
	   * @private
	   * @param  {string} href the original css file
	   * @return {Promise}  returns a BlobUrl to the new CSS file or a data url
	   */

		}, {
			key: "createCssFile",
			value: function createCssFile(href) {
				var _this2 = this;

				var newUrl;

				if (path.isAbsolute(href)) {
					return new Promise(function (resolve) {
						resolve();
					});
				}

				var absolute = this.settings.resolver(href);

				// Get the text of the css file from the archive
				var textResponse;

				if (this.settings.archive) {
					textResponse = this.settings.archive.getText(absolute);
				} else {
					textResponse = this.settings.request(absolute, "text");
				}

				// Get asset links relative to css file
				var relUrls = this.urls.map(function (assetHref) {
					var resolved = _this2.settings.resolver(assetHref);
					var relative = new Path(absolute).relative(resolved);

					return relative;
				});

				if (!textResponse) {
					// file not found, don't replace
					return new Promise(function (resolve) {
						resolve();
					});
				}

				return textResponse.then(function (text) {
					// Replacements in the css text
					text = substitute(text, relUrls, _this2.replacementUrls);

					// Get the new url
					if (_this2.settings.replacements === "base64") {
						newUrl = createBase64Url(text, "text/css");
					} else {
						newUrl = createBlobUrl(text, "text/css");
					}

					return newUrl;
				}, function (err) {
					// handle response errors
					return new Promise(function (resolve) {
						resolve();
					});
				});
			}

			/**
	   * Resolve all resources URLs relative to an absolute URL
	   * @param  {string} absolute to be resolved to
	   * @param  {resolver} [resolver]
	   * @return {string[]} array with relative Urls
	   */

		}, {
			key: "relativeTo",
			value: function relativeTo(absolute, resolver) {
				resolver = resolver || this.settings.resolver;

				// Get Urls relative to current sections
				return this.urls.map(function (href) {
					var resolved = resolver(href);
					var relative = new Path(absolute).relative(resolved);
					return relative;
				}.bind(this));
			}

			/**
	   * Get a URL for a resource
	   * @param  {string} path
	   * @return {string} url
	   */

		}, {
			key: "get",
			value: function get(path$$1) {
				var indexInUrls = this.urls.indexOf(path$$1);
				if (indexInUrls === -1) {
					return;
				}
				if (this.replacementUrls.length) {
					return new Promise(function (resolve, reject) {
						resolve(this.replacementUrls[indexInUrls]);
					}.bind(this));
				} else {
					return this.createUrl(path$$1);
				}
			}

			/**
	   * Substitute urls in content, with replacements,
	   * relative to a url if provided
	   * @param  {string} content
	   * @param  {string} [url]   url to resolve to
	   * @return {string}         content with urls substituted
	   */

		}, {
			key: "substitute",
			value: function substitute$$1(content, url) {
				var relUrls;
				if (url) {
					relUrls = this.relativeTo(url);
				} else {
					relUrls = this.urls;
				}
				return substitute(content, relUrls, this.replacementUrls);
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.settings = undefined;
				this.manifest = undefined;
				this.resources = undefined;
				this.replacementUrls = undefined;
				this.html = undefined;
				this.assets = undefined;
				this.css = undefined;

				this.urls = undefined;
				this.cssUrls = undefined;
			}
		}]);

		return Resources;
	}();

	var _createClass$d = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$d(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Page List Parser
	 * @param {document} [xml]
	 */

	var PageList = function () {
		function PageList(xml) {
			_classCallCheck$d(this, PageList);

			this.pages = [];
			this.locations = [];
			this.epubcfi = new EpubCFI();

			this.firstPage = 0;
			this.lastPage = 0;
			this.totalPages = 0;

			this.toc = undefined;
			this.ncx = undefined;

			if (xml) {
				this.pageList = this.parse(xml);
			}

			if (this.pageList && this.pageList.length) {
				this.process(this.pageList);
			}
		}

		/**
	  * Parse PageList Xml
	  * @param  {document} xml
	  */


		_createClass$d(PageList, [{
			key: "parse",
			value: function parse$$1(xml) {
				var html = qs(xml, "html");
				var ncx = qs(xml, "ncx");

				if (html) {
					return this.parseNav(xml);
				} else if (ncx) {
					// Not supported
					// return this.parseNcx(xml);
					return;
				}
			}

			/**
	   * Parse a Nav PageList
	   * @private
	   * @param  {node} navHtml
	   * @return {PageList.item[]} list
	   */

		}, {
			key: "parseNav",
			value: function parseNav(navHtml) {
				var navElement = querySelectorByType(navHtml, "nav", "page-list");
				var navItems = navElement ? qsa(navElement, "li") : [];
				var length = navItems.length;
				var i;
				var list = [];
				var item;

				if (!navItems || length === 0) return list;

				for (i = 0; i < length; ++i) {
					item = this.item(navItems[i]);
					list.push(item);
				}

				return list;
			}

			/**
	   * Page List Item
	   * @private
	   * @param  {node} item
	   * @return {object} pageListItem
	   */

		}, {
			key: "item",
			value: function item(_item) {
				var content = qs(_item, "a"),
				    href = content.getAttribute("href") || "",
				    text = content.textContent || "",
				    page = parseInt(text),
				    isCfi = href.indexOf("epubcfi"),
				    split,
				    packageUrl,
				    cfi;

				if (isCfi != -1) {
					split = href.split("#");
					packageUrl = split[0];
					cfi = split.length > 1 ? split[1] : false;
					return {
						"cfi": cfi,
						"href": href,
						"packageUrl": packageUrl,
						"page": page
					};
				} else {
					return {
						"href": href,
						"page": page
					};
				}
			}

			/**
	   * Process pageList items
	   * @private
	   * @param  {array} pageList
	   */

		}, {
			key: "process",
			value: function process(pageList) {
				pageList.forEach(function (item) {
					this.pages.push(item.page);
					if (item.cfi) {
						this.locations.push(item.cfi);
					}
				}, this);
				this.firstPage = parseInt(this.pages[0]);
				this.lastPage = parseInt(this.pages[this.pages.length - 1]);
				this.totalPages = this.lastPage - this.firstPage;
			}

			/**
	   * Get a PageList result from a EpubCFI
	   * @param  {string} cfi EpubCFI String
	   * @return {number} page
	   */

		}, {
			key: "pageFromCfi",
			value: function pageFromCfi(cfi) {
				var pg = -1;

				// Check if the pageList has not been set yet
				if (this.locations.length === 0) {
					return -1;
				}

				// TODO: check if CFI is valid?

				// check if the cfi is in the location list
				// var index = this.locations.indexOf(cfi);
				var index = indexOfSorted(cfi, this.locations, this.epubcfi.compare);
				if (index != -1) {
					pg = this.pages[index];
				} else {
					// Otherwise add it to the list of locations
					// Insert it in the correct position in the locations page
					//index = EPUBJS.core.insert(cfi, this.locations, this.epubcfi.compare);
					index = locationOf(cfi, this.locations, this.epubcfi.compare);
					// Get the page at the location just before the new one, or return the first
					pg = index - 1 >= 0 ? this.pages[index - 1] : this.pages[0];
					if (pg !== undefined) ; else {
						pg = -1;
					}
				}
				return pg;
			}

			/**
	   * Get an EpubCFI from a Page List Item
	   * @param  {string | number} pg
	   * @return {string} cfi
	   */

		}, {
			key: "cfiFromPage",
			value: function cfiFromPage(pg) {
				var cfi = -1;
				// check that pg is an int
				if (typeof pg != "number") {
					pg = parseInt(pg);
				}

				// check if the cfi is in the page list
				// Pages could be unsorted.
				var index = this.pages.indexOf(pg);
				if (index != -1) {
					cfi = this.locations[index];
				}
				// TODO: handle pages not in the list
				return cfi;
			}

			/**
	   * Get a Page from Book percentage
	   * @param  {number} percent
	   * @return {number} page
	   */

		}, {
			key: "pageFromPercentage",
			value: function pageFromPercentage(percent) {
				var pg = Math.round(this.totalPages * percent);
				return pg;
			}

			/**
	   * Returns a value between 0 - 1 corresponding to the location of a page
	   * @param  {number} pg the page
	   * @return {number} percentage
	   */

		}, {
			key: "percentageFromPage",
			value: function percentageFromPage(pg) {
				var percentage = (pg - this.firstPage) / this.totalPages;
				return Math.round(percentage * 1000) / 1000;
			}

			/**
	   * Returns a value between 0 - 1 corresponding to the location of a cfi
	   * @param  {string} cfi EpubCFI String
	   * @return {number} percentage
	   */

		}, {
			key: "percentageFromCfi",
			value: function percentageFromCfi(cfi) {
				var pg = this.pageFromCfi(cfi);
				var percentage = this.percentageFromPage(pg);
				return percentage;
			}

			/**
	   * Destroy
	   */

		}, {
			key: "destroy",
			value: function destroy() {
				this.pages = undefined;
				this.locations = undefined;
				this.epubcfi = undefined;

				this.pageList = undefined;

				this.toc = undefined;
				this.ncx = undefined;
			}
		}]);

		return PageList;
	}();

	var _createClass$e = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$e(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Figures out the CSS values to apply for a layout
	 * @class
	 * @param {object} settings
	 * @param {string} [settings.layout='reflowable']
	 * @param {string} [settings.spread]
	 * @param {number} [settings.minSpreadWidth=800]
	 * @param {boolean} [settings.evenSpreads=false]
	 */

	var Layout = function () {
		function Layout(settings) {
			_classCallCheck$e(this, Layout);

			this.settings = settings;
			this.name = settings.layout || "reflowable";
			this._spread = settings.spread === "none" ? false : true;
			this._minSpreadWidth = settings.minSpreadWidth || 800;
			this._evenSpreads = settings.evenSpreads || false;

			if (settings.flow === "scrolled" || settings.flow === "scrolled-continuous" || settings.flow === "scrolled-doc") {
				this._flow = "scrolled";
			} else {
				this._flow = "paginated";
			}

			this.width = 0;
			this.height = 0;
			this.spreadWidth = 0;
			this.delta = 0;

			this.columnWidth = 0;
			this.gap = 0;
			this.divisor = 1;

			this.props = {
				name: this.name,
				spread: this._spread,
				flow: this._flow,
				width: 0,
				height: 0,
				spreadWidth: 0,
				delta: 0,
				columnWidth: 0,
				gap: 0,
				divisor: 1
			};
		}

		/**
	  * Switch the flow between paginated and scrolled
	  * @param  {string} flow paginated | scrolled
	  * @return {string} simplified flow
	  */


		_createClass$e(Layout, [{
			key: "flow",
			value: function flow(_flow) {
				if (typeof _flow != "undefined") {
					if (_flow === "scrolled" || _flow === "scrolled-continuous" || _flow === "scrolled-doc") {
						this._flow = "scrolled";
					} else {
						this._flow = "paginated";
					}
					// this.props.flow = this._flow;
					this.update({ flow: this._flow });
				}
				return this._flow;
			}

			/**
	   * Switch between using spreads or not, and set the
	   * width at which they switch to single.
	   * @param  {string} spread "none" | "always" | "auto"
	   * @param  {number} min integer in pixels
	   * @return {boolean} spread true | false
	   */

		}, {
			key: "spread",
			value: function spread(_spread, min) {

				if (_spread) {
					this._spread = _spread === "none" ? false : true;
					// this.props.spread = this._spread;
					this.update({ spread: this._spread });
				}

				if (min >= 0) {
					this._minSpreadWidth = min;
				}

				return this._spread;
			}

			/**
	   * Calculate the dimensions of the pagination
	   * @param  {number} _width  width of the rendering
	   * @param  {number} _height height of the rendering
	   * @param  {number} _gap    width of the gap between columns
	   */

		}, {
			key: "calculate",
			value: function calculate(_width, _height, _gap) {

				var divisor = 1;
				var gap = _gap || 0;

				//-- Check the width and create even width columns
				// var fullWidth = Math.floor(_width);
				var width = _width;
				var height = _height;

				var section = Math.floor(width / 12);

				var columnWidth;
				var spreadWidth;
				var pageWidth;
				var delta;

				if (this._spread && width >= this._minSpreadWidth) {
					divisor = 2;
				} else {
					divisor = 1;
				}

				if (this.name === "reflowable" && this._flow === "paginated" && !(_gap >= 0)) {
					gap = section % 2 === 0 ? section : section - 1;
				}

				if (this.name === "pre-paginated") {
					gap = 0;
				}

				//-- Double Page
				if (divisor > 1) {
					// width = width - gap;
					// columnWidth = (width - gap) / divisor;
					// gap = gap / divisor;
					columnWidth = width / divisor - gap;
					pageWidth = columnWidth + gap;
				} else {
					columnWidth = width;
					pageWidth = width;
				}

				if (this.name === "pre-paginated" && divisor > 1) {
					width = columnWidth;
				}

				spreadWidth = columnWidth * divisor + gap;

				delta = Math.ceil(width);

				this.width = width;
				this.height = height;
				this.spreadWidth = spreadWidth;
				this.pageWidth = pageWidth;
				this.delta = delta;

				this.columnWidth = columnWidth;
				this.gap = gap;
				this.divisor = divisor;

				// this.props.width = width;
				// this.props.height = _height;
				// this.props.spreadWidth = spreadWidth;
				// this.props.pageWidth = pageWidth;
				// this.props.delta = delta;
				//
				// this.props.columnWidth = colWidth;
				// this.props.gap = gap;
				// this.props.divisor = divisor;

				this.update({
					width: width,
					height: height,
					spreadWidth: spreadWidth,
					pageWidth: pageWidth,
					delta: delta,
					columnWidth: columnWidth,
					gap: gap,
					divisor: divisor
				});
			}

			/**
	   * Apply Css to a Document
	   * @param  {Contents} contents
	   * @return {Promise}
	   */

		}, {
			key: "format",
			value: function format(contents) {
				var formating;

				var viewport = contents.viewport();
				// console.log("AHOY contents.format VIEWPORT", this.name, viewport.height);
				if (this.name === "pre-paginated" && viewport.height != 'auto' && viewport.height != undefined) {
					// console.log("AHOY CONTENTS format", this.columnWidth, this.height);
					formating = contents.fit(this.columnWidth, this.height);
				} else if (this._flow === "paginated") {
					formating = contents.columns(this.width, this.height, this.columnWidth, this.gap);
				} else {
					// scrolled
					formating = contents.size(this.width, null);
					if (this.name === 'pre-paginated') {
						contents.content.style.overflow = 'auto';
						contents.addStylesheetRules({
							"body": {
								"margin": 0,
								"padding": "1em !important",
								"box-sizing": "border-box"
							}
						});
					}
				}

				return formating; // might be a promise in some View Managers
			}

			/**
	   * Count number of pages
	   * @param  {number} totalLength
	   * @param  {number} pageLength
	   * @return {{spreads: Number, pages: Number}}
	   */

		}, {
			key: "count",
			value: function count(totalLength, pageLength) {

				var spreads = void 0,
				    pages = void 0;

				if (this.name === "pre-paginated") {
					spreads = 1;
					pages = 1;
				} else if (this._flow === "paginated") {
					pageLength = pageLength || this.delta;
					spreads = Math.ceil(totalLength / pageLength);
					pages = spreads * this.divisor;
				} else {
					// scrolled
					pageLength = pageLength || this.height;
					spreads = Math.ceil(totalLength / pageLength);
					pages = spreads;
				}

				return {
					spreads: spreads,
					pages: pages
				};
			}

			/**
	   * Update props that have changed
	   * @private
	   * @param  {object} props
	   */

		}, {
			key: "update",
			value: function update(props) {
				var _this = this;

				// Remove props that haven't changed
				Object.keys(props).forEach(function (propName) {
					if (_this.props[propName] === props[propName]) {
						delete props[propName];
					}
				});

				if (Object.keys(props).length > 0) {
					var newProps = extend$1(this.props, props);
					this.emit(EVENTS.LAYOUT.UPDATED, newProps, props);
				}
			}
		}]);

		return Layout;
	}();

	eventEmitter(Layout.prototype);

	var _typeof$6 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	var _createClass$f = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$f(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Themes to apply to displayed content
	 * @class
	 * @param {Rendition} rendition
	 */

	var Themes = function () {
		function Themes(rendition) {
			_classCallCheck$f(this, Themes);

			this.rendition = rendition;
			this._themes = {
				"default": {
					"rules": {},
					"url": "",
					"serialized": ""
				}
			};
			this._overrides = {};
			this._current = "default";
			this._injected = [];
			this.rendition.hooks.content.register(this.inject.bind(this));
			this.rendition.hooks.content.register(this.overrides.bind(this));
		}

		/**
	  * Add themes to be used by a rendition
	  * @param {object | Array<object> | string}
	  * @example themes.register("light", "http://example.com/light.css")
	  * @example themes.register("light", { "body": { "color": "purple"}})
	  * @example themes.register({ "light" : {...}, "dark" : {...}})
	  */


		_createClass$f(Themes, [{
			key: "register",
			value: function register() {
				if (arguments.length === 0) {
					return;
				}
				if (arguments.length === 1 && _typeof$6(arguments[0]) === "object") {
					return this.registerThemes(arguments[0]);
				}
				if (arguments.length === 1 && typeof arguments[0] === "string") {
					return this.default(arguments[0]);
				}
				if (arguments.length === 2 && typeof arguments[1] === "string") {
					return this.registerUrl(arguments[0], arguments[1]);
				}
				if (arguments.length === 2 && _typeof$6(arguments[1]) === "object") {
					return this.registerRules(arguments[0], arguments[1]);
				}
			}

			/**
	   * Add a default theme to be used by a rendition
	   * @param {object | string} theme
	   * @example themes.register("http://example.com/default.css")
	   * @example themes.register({ "body": { "color": "purple"}})
	   */

		}, {
			key: "default",
			value: function _default(theme) {
				if (!theme) {
					return;
				}
				if (typeof theme === "string") {
					return this.registerUrl("default", theme);
				}
				if ((typeof theme === "undefined" ? "undefined" : _typeof$6(theme)) === "object") {
					return this.registerRules("default", theme);
				}
			}

			/**
	   * Register themes object
	   * @param {object} themes
	   */

		}, {
			key: "registerThemes",
			value: function registerThemes(themes) {
				for (var theme in themes) {
					if (themes.hasOwnProperty(theme)) {
						if (typeof themes[theme] === "string") {
							this.registerUrl(theme, themes[theme]);
						} else {
							this.registerRules(theme, themes[theme]);
						}
					}
				}
			}

			/**
	   * Register a url
	   * @param {string} name
	   * @param {string} input
	   */

		}, {
			key: "registerUrl",
			value: function registerUrl(name, input) {
				var url = new Url(input);
				this._themes[name] = { "url": url.toString() };
				if (this._injected[name]) {
					this.update(name);
				}
			}

			/**
	   * Register rule
	   * @param {string} name
	   * @param {object} rules
	   */

		}, {
			key: "registerRules",
			value: function registerRules(name, rules) {
				this._themes[name] = { "rules": rules };
				// TODO: serialize css rules
				if (this._injected[name]) {
					this.update(name);
				}
			}

			/**
	   * Select a theme
	   * @param {string} name
	   */

		}, {
			key: "select",
			value: function select(name) {
				var prev = this._current;
				var contents;

				this._current = name;
				this.update(name);

				contents = this.rendition.getContents();
				contents.forEach(function (content) {
					content.removeClass(prev);
					content.addClass(name);
				});
			}

			/**
	   * Update a theme
	   * @param {string} name
	   */

		}, {
			key: "update",
			value: function update(name) {
				var _this = this;

				var contents = this.rendition.getContents();
				contents.forEach(function (content) {
					_this.add(name, content);
				});
			}

			/**
	   * Inject all themes into contents
	   * @param {Contents} contents
	   */

		}, {
			key: "inject",
			value: function inject(contents) {
				var links = [];
				var themes = this._themes;
				var theme;

				for (var name in themes) {
					if (themes.hasOwnProperty(name) && (name === this._current || name === "default")) {
						theme = themes[name];
						if (theme.rules && Object.keys(theme.rules).length > 0 || theme.url && links.indexOf(theme.url) === -1) {
							this.add(name, contents);
						}
						this._injected.push(name);
					}
				}

				if (this._current != "default") {
					contents.addClass(this._current);
				}
			}

			/**
	   * Add Theme to contents
	   * @param {string} name
	   * @param {Contents} contents
	   */

		}, {
			key: "add",
			value: function add(name, contents) {
				var theme = this._themes[name];

				if (!theme || !contents) {
					return;
				}

				if (theme.url) {
					contents.addStylesheet(theme.url);
				} else if (theme.serialized) ; else if (theme.rules) {
					contents.addStylesheetRules(theme.rules);
					theme.injected = true;
				}
			}

			/**
	   * Add override
	   * @param {string} name
	   * @param {string} value
	   * @param {boolean} priority
	   */

		}, {
			key: "override",
			value: function override(name, value, priority) {
				var _this2 = this;

				var contents = this.rendition.getContents();

				this._overrides[name] = {
					value: value,
					priority: priority === true
				};

				contents.forEach(function (content) {
					content.css(name, _this2._overrides[name].value, _this2._overrides[name].priority);
				});
			}

			/**
	   * Add all overrides
	   * @param {Content} content
	   */

		}, {
			key: "overrides",
			value: function overrides(contents) {
				var overrides = this._overrides;

				for (var rule in overrides) {
					if (overrides.hasOwnProperty(rule)) {
						contents.css(rule, overrides[rule].value, overrides[rule].priority);
					}
				}
			}

			/**
	   * Adjust the font size of a rendition
	   * @param {number} size
	   */

		}, {
			key: "fontSize",
			value: function fontSize(size) {
				this.override("font-size", size);
			}

			/**
	   * Adjust the font-family of a rendition
	   * @param {string} f
	   */

		}, {
			key: "font",
			value: function font(f) {
				this.override("font-family", f, true);
			}
		}, {
			key: "destroy",
			value: function destroy() {
				this.rendition = undefined;
				this._themes = undefined;
				this._overrides = undefined;
				this._current = undefined;
				this._injected = undefined;
			}
		}]);

		return Themes;
	}();

	var _createClass$g = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$g(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Map text locations to CFI ranges
	 * @class
	 * @param {Layout} layout Layout to apply
	 * @param {string} [direction="ltr"] Text direction
	 * @param {string} [axis="horizontal"] vertical or horizontal axis
	 * @param {boolean} [dev] toggle developer highlighting
	 */

	var Mapping = function () {
		function Mapping(layout, direction, axis, dev) {
			_classCallCheck$g(this, Mapping);

			this.layout = layout;
			this.horizontal = axis === "horizontal" ? true : false;
			this.direction = direction || "ltr";
			this._dev = dev;
		}

		/**
	  * Find CFI pairs for entire section at once
	  */


		_createClass$g(Mapping, [{
			key: "section",
			value: function section(view) {
				var ranges = this.findRanges(view);
				var map = this.rangeListToCfiList(view.section.cfiBase, ranges);

				return map;
			}

			/**
	   * Find CFI pairs for a page
	   * @param {Contents} contents Contents from view
	   * @param {string} cfiBase string of the base for a cfi
	   * @param {number} start position to start at
	   * @param {number} end position to end at
	   */

		}, {
			key: "page",
			value: function page(contents, cfiBase, start, end) {
				var root = contents && contents.document ? contents.document.body : false;
				var result;

				if (!root) {
					return;
				}

				result = this.rangePairToCfiPair(cfiBase, {
					start: this.findStart(root, start, end),
					end: this.findEnd(root, start, end)
				});

				if (this._dev === true) {
					var doc = contents.document;
					var startRange = new EpubCFI(result.start).toRange(doc);
					var endRange = new EpubCFI(result.end).toRange(doc);

					var selection = doc.defaultView.getSelection();
					var r = doc.createRange();
					selection.removeAllRanges();
					r.setStart(startRange.startContainer, startRange.startOffset);
					r.setEnd(endRange.endContainer, endRange.endOffset);
					selection.addRange(r);
				}

				return result;
			}

			/**
	   * Walk a node, preforming a function on each node it finds
	   * @private
	   * @param {Node} root Node to walkToNode
	   * @param {function} func walk function
	   * @return {*} returns the result of the walk function
	   */

		}, {
			key: "walk",
			value: function walk$$1(root, func) {
				// IE11 has strange issue, if root is text node IE throws exception on
				// calling treeWalker.nextNode(), saying
				// Unexpected call to method or property access instead of returing null value
				if (root && root.nodeType === Node.TEXT_NODE) {
					return;
				}
				// safeFilter is required so that it can work in IE as filter is a function for IE
				// and for other browser filter is an object.
				var filter = {
					acceptNode: function acceptNode(node) {
						if (node.data.trim().length > 0) {
							return NodeFilter.FILTER_ACCEPT;
						} else {
							return NodeFilter.FILTER_REJECT;
						}
					}
				};
				var safeFilter = filter.acceptNode;
				safeFilter.acceptNode = filter.acceptNode;

				var treeWalker$$1 = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, safeFilter, false);
				var node;
				var result;
				while (node = treeWalker$$1.nextNode()) {
					result = func(node);
					if (result) break;
				}

				return result;
			}
		}, {
			key: "findRanges",
			value: function findRanges(view) {
				var columns = [];
				var scrollWidth = view.contents.scrollWidth();
				var spreads = Math.ceil(scrollWidth / this.layout.spreadWidth);
				var count = spreads * this.layout.divisor;
				var columnWidth = this.layout.columnWidth;
				var gap = this.layout.gap;
				var start, end;

				for (var i = 0; i < count.pages; i++) {
					start = (columnWidth + gap) * i;
					end = columnWidth * (i + 1) + gap * i;
					columns.push({
						start: this.findStart(view.document.body, start, end),
						end: this.findEnd(view.document.body, start, end)
					});
				}

				return columns;
			}

			/**
	   * Find Start Range
	   * @private
	   * @param {Node} root root node
	   * @param {number} start position to start at
	   * @param {number} end position to end at
	   * @return {Range}
	   */

		}, {
			key: "findStart",
			value: function findStart(root, start, end) {
				var _this = this;

				var stack = [root];
				var $el;
				var found;
				var $prev = root;

				while (stack.length) {

					$el = stack.shift();

					found = this.walk($el, function (node) {
						var left, right, top, bottom;
						var elPos;

						elPos = nodeBounds(node);

						if (_this.horizontal && _this.direction === "ltr") {

							left = _this.horizontal ? elPos.left : elPos.top;
							right = _this.horizontal ? elPos.right : elPos.bottom;

							if (left >= start && left <= end) {
								return node;
							} else if (right > start) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						} else if (_this.horizontal && _this.direction === "rtl") {

							left = elPos.left;
							right = elPos.right;

							if (right <= end && right >= start) {
								return node;
							} else if (left < end) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						} else {

							top = elPos.top;
							bottom = elPos.bottom;

							if (top >= start && top <= end) {
								return node;
							} else if (bottom > start) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						}
					});

					if (found) {
						return this.findTextStartRange(found, start, end);
					}
				}

				// Return last element
				return this.findTextStartRange($prev, start, end);
			}

			/**
	   * Find End Range
	   * @private
	   * @param {Node} root root node
	   * @param {number} start position to start at
	   * @param {number} end position to end at
	   * @return {Range}
	   */

		}, {
			key: "findEnd",
			value: function findEnd(root, start, end) {
				var _this2 = this;

				var stack = [root];
				var $el;
				var $prev = root;
				var found;

				while (stack.length) {

					$el = stack.shift();

					found = this.walk($el, function (node) {

						var left, right, top, bottom;
						var elPos;

						elPos = nodeBounds(node);

						if (_this2.horizontal && _this2.direction === "ltr") {

							left = Math.round(elPos.left);
							right = Math.round(elPos.right);

							if (left > end && $prev) {
								return $prev;
							} else if (right > end) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						} else if (_this2.horizontal && _this2.direction === "rtl") {

							left = Math.round(_this2.horizontal ? elPos.left : elPos.top);
							right = Math.round(_this2.horizontal ? elPos.right : elPos.bottom);

							if (right < start && $prev) {
								return $prev;
							} else if (left < start) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						} else {

							top = Math.round(elPos.top);
							bottom = Math.round(elPos.bottom);

							if (top > end && $prev) {
								return $prev;
							} else if (bottom > end) {
								return node;
							} else {
								$prev = node;
								stack.push(node);
							}
						}
					});

					if (found) {
						return this.findTextEndRange(found, start, end);
					}
				}

				// end of chapter
				return this.findTextEndRange($prev, start, end);
			}

			/**
	   * Find Text Start Range
	   * @private
	   * @param {Node} root root node
	   * @param {number} start position to start at
	   * @param {number} end position to end at
	   * @return {Range}
	   */

		}, {
			key: "findTextStartRange",
			value: function findTextStartRange(node, start, end) {
				var ranges = this.splitTextNodeIntoRanges(node);
				var range;
				var pos;
				var left, top, right;

				for (var i = 0; i < ranges.length; i++) {
					range = ranges[i];

					pos = range.getBoundingClientRect();

					if (this.horizontal && this.direction === "ltr") {

						left = pos.left;
						if (left >= start) {
							return range;
						}
					} else if (this.horizontal && this.direction === "rtl") {

						right = pos.right;
						if (right <= end) {
							return range;
						}
					} else {

						top = pos.top;
						if (top >= start) {
							return range;
						}
					}

					// prev = range;
				}

				return ranges[0];
			}

			/**
	   * Find Text End Range
	   * @private
	   * @param {Node} root root node
	   * @param {number} start position to start at
	   * @param {number} end position to end at
	   * @return {Range}
	   */

		}, {
			key: "findTextEndRange",
			value: function findTextEndRange(node, start, end) {
				var ranges = this.splitTextNodeIntoRanges(node);
				var prev;
				var range;
				var pos;
				var left, right, top, bottom;

				for (var i = 0; i < ranges.length; i++) {
					range = ranges[i];

					pos = range.getBoundingClientRect();

					if (this.horizontal && this.direction === "ltr") {

						left = pos.left;
						right = pos.right;

						if (left > end && prev) {
							return prev;
						} else if (right > end) {
							return range;
						}
					} else if (this.horizontal && this.direction === "rtl") {

						left = pos.left;
						right = pos.right;

						if (right < start && prev) {
							return prev;
						} else if (left < start) {
							return range;
						}
					} else {

						top = pos.top;
						bottom = pos.bottom;

						if (top > end && prev) {
							return prev;
						} else if (bottom > end) {
							return range;
						}
					}

					prev = range;
				}

				// Ends before limit
				return ranges[ranges.length - 1];
			}

			/**
	   * Split up a text node into ranges for each word
	   * @private
	   * @param {Node} root root node
	   * @param {string} [_splitter] what to split on
	   * @return {Range[]}
	   */

		}, {
			key: "splitTextNodeIntoRanges",
			value: function splitTextNodeIntoRanges(node, _splitter) {
				var ranges = [];
				var textContent = node.textContent || "";
				var text = textContent.trim();
				var range;
				var doc = node.ownerDocument;
				var splitter = _splitter || " ";

				var pos = text.indexOf(splitter);

				if (pos === -1 || node.nodeType != Node.TEXT_NODE) {
					range = doc.createRange();
					range.selectNodeContents(node);
					return [range];
				}

				range = doc.createRange();
				range.setStart(node, 0);
				range.setEnd(node, pos);
				ranges.push(range);
				range = false;

				while (pos != -1) {

					pos = text.indexOf(splitter, pos + 1);
					if (pos > 0) {

						if (range) {
							range.setEnd(node, pos);
							ranges.push(range);
						}

						range = doc.createRange();
						range.setStart(node, pos + 1);
					}
				}

				if (range) {
					range.setEnd(node, text.length);
					ranges.push(range);
				}

				return ranges;
			}

			/**
	   * Turn a pair of ranges into a pair of CFIs
	   * @private
	   * @param {string} cfiBase base string for an EpubCFI
	   * @param {object} rangePair { start: Range, end: Range }
	   * @return {object} { start: "epubcfi(...)", end: "epubcfi(...)" }
	   */

		}, {
			key: "rangePairToCfiPair",
			value: function rangePairToCfiPair(cfiBase, rangePair) {

				var startRange = rangePair.start;
				var endRange = rangePair.end;

				startRange.collapse(true);
				endRange.collapse(false);

				var startCfi = new EpubCFI(startRange, cfiBase).toString();
				var endCfi = new EpubCFI(endRange, cfiBase).toString();

				return {
					start: startCfi,
					end: endCfi
				};
			}
		}, {
			key: "rangeListToCfiList",
			value: function rangeListToCfiList(cfiBase, columns) {
				var map = [];
				var cifPair;

				for (var i = 0; i < columns.length; i++) {
					cifPair = this.rangePairToCfiPair(cfiBase, columns[i]);

					map.push(cifPair);
				}

				return map;
			}

			/**
	   * Set the axis for mapping
	   * @param {string} axis horizontal | vertical
	   * @return {boolean} is it horizontal?
	   */

		}, {
			key: "axis",
			value: function axis(_axis) {
				if (_axis) {
					this.horizontal = _axis === "horizontal" ? true : false;
				}
				return this.horizontal;
			}
		}]);

		return Mapping;
	}();

	var _createClass$h = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$h(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var hasNavigator = typeof navigator !== "undefined";

	var isChrome = hasNavigator && /Chrome/.test(navigator.userAgent);
	var isWebkit = hasNavigator && !isChrome && /AppleWebKit/.test(navigator.userAgent);

	var ELEMENT_NODE$2 = 1;

	/**
		* Handles DOM manipulation, queries and events for View contents
		* @class
		* @param {document} doc Document
		* @param {element} content Parent Element (typically Body)
		* @param {string} cfiBase Section component of CFIs
		* @param {number} sectionIndex Index in Spine of Conntent's Section
		*/

	var Contents$1 = function () {
		function Contents(doc, content, cfiBase, sectionIndex) {
			_classCallCheck$h(this, Contents);

			// Blank Cfi for Parsing
			this.epubcfi = new EpubCFI();

			this.document = doc;
			this.documentElement = this.document.documentElement;
			this.content = content || this.document.body;
			this.window = this.document.defaultView;

			this._size = {
				width: 0,
				height: 0
			};

			this.sectionIndex = sectionIndex || 0;
			this.cfiBase = cfiBase || "";

			this.epubReadingSystem("epub.js", EPUBJS_VERSION);

			this.setViewport();
			this.listeners();
		}

		/**
	 	* Get DOM events that are listened for and passed along
	 	*/


		_createClass$h(Contents, [{
			key: "width",


			/**
	  	* Get or Set width
	  	* @param {number} [w]
	  	* @returns {number} width
	  	*/
			value: function width(w) {
				// var frame = this.documentElement;
				var frame = this.content;

				if (w && isNumber(w)) {
					w = w + "px";
				}

				if (w) {
					frame.style.width = w;
					// this.content.style.width = w;
				}

				return this.window.getComputedStyle(frame)["width"];
			}

			/**
	  	* Get or Set height
	  	* @param {number} [h]
	  	* @returns {number} height
	  	*/

		}, {
			key: "height",
			value: function height(h) {
				// var frame = this.documentElement;
				var frame = this.content;

				if (h && isNumber(h)) {
					h = h + "px";
				}

				if (h) {
					frame.style.height = h;
					// this.content.style.height = h;
				}

				return this.window.getComputedStyle(frame)["height"];
			}

			/**
	  	* Get or Set width of the contents
	  	* @param {number} [w]
	  	* @returns {number} width
	  	*/

		}, {
			key: "contentWidth",
			value: function contentWidth(w) {

				var content = this.content || this.document.body;

				if (w && isNumber(w)) {
					w = w + "px";
				}

				if (w) {
					content.style.width = w;
				}

				return this.window.getComputedStyle(content)["width"];
			}

			/**
	  	* Get or Set height of the contents
	  	* @param {number} [h]
	  	* @returns {number} height
	  	*/

		}, {
			key: "contentHeight",
			value: function contentHeight(h) {

				var content = this.content || this.document.body;

				if (h && isNumber(h)) {
					h = h + "px";
				}

				if (h) {
					content.style.height = h;
				}

				return this.window.getComputedStyle(content)["height"];
			}

			/**
	  	* Get the width of the text using Range
	  	* @returns {number} width
	  	*/

		}, {
			key: "textWidth",
			value: function textWidth() {
				var viewport = this.$viewport;

				var rect = void 0;
				var width = void 0;
				var range = this.document.createRange();
				var content = this.content || this.document.body;
				var border = borders(content);

				// Select the contents of frame
				range.selectNodeContents(content);

				// get the width of the text content
				rect = range.getBoundingClientRect();
				width = rect.width;

				if (border && border.width) {
					width += border.width;
				}

				return Math.round(width);
			}

			/**
	  	* Get the height of the text using Range
	  	* @returns {number} height
	  	*/

		}, {
			key: "textHeight",
			value: function textHeight() {
				var viewport = this.$viewport;

				var rect = void 0;
				var height = void 0;
				var range = this.document.createRange();
				var content = this.content || this.document.body;
				var border = borders(content);

				range.selectNodeContents(content);

				rect = range.getBoundingClientRect();
				height = rect.height;

				if (height && border.height) {
					height += border.height;
				}

				if (height && rect.top) {
					height += rect.top;
				}

				return Math.round(height);
			}

			/**
	  	* Get documentElement scrollWidth
	  	* @returns {number} width
	  	*/

		}, {
			key: "scrollWidth",
			value: function scrollWidth() {
				var width = this.documentElement.scrollWidth;

				return width;
			}

			/**
	  	* Get documentElement scrollHeight
	  	* @returns {number} height
	  	*/

		}, {
			key: "scrollHeight",
			value: function scrollHeight() {
				var height = this.documentElement.scrollHeight;

				return height;
			}

			/**
	  	* Set overflow css style of the contents
	  	* @param {string} [overflow]
	  	*/

		}, {
			key: "overflow",
			value: function overflow(_overflow) {

				if (_overflow) {
					this.documentElement.style.overflow = _overflow;
				}

				return this.window.getComputedStyle(this.documentElement)["overflow"];
			}

			/**
	  	* Set overflowX css style of the documentElement
	  	* @param {string} [overflow]
	  	*/

		}, {
			key: "overflowX",
			value: function overflowX(overflow) {

				if (overflow) {
					this.documentElement.style.overflowX = overflow;
				}

				return this.window.getComputedStyle(this.documentElement)["overflowX"];
			}

			/**
	  	* Set overflowY css style of the documentElement
	  	* @param {string} [overflow]
	  	*/

		}, {
			key: "overflowY",
			value: function overflowY(overflow) {

				if (overflow) {
					this.documentElement.style.overflowY = overflow;
				}

				return this.window.getComputedStyle(this.documentElement)["overflowY"];
			}

			/**
	  	* Set Css styles on the contents element (typically Body)
	  	* @param {string} property
	  	* @param {string} value
	  	* @param {boolean} [priority] set as "important"
	  	*/

		}, {
			key: "css",
			value: function css(property, value, priority) {
				var content = this.content || this.document.body;

				if (value) {
					content.style.setProperty(property, value, priority ? "important" : "");
				}

				return this.window.getComputedStyle(content)[property];
			}

			/**
	  	* Get or Set the viewport element
	  	* @param {object} [options]
	  	* @param {string} [options.width]
	  	* @param {string} [options.height]
	  	* @param {string} [options.scale]
	  	* @param {string} [options.minimum]
	  	* @param {string} [options.maximum]
	  	* @param {string} [options.scalable]
	  	*/

		}, {
			key: "viewport",
			value: function viewport(options) {
				// var width, height, scale, minimum, maximum, scalable;
				var $viewport = this.document.querySelector("meta[name='viewport']");
				var parsed = {
					"width": undefined,
					"height": undefined,
					"scale": undefined,
					"minimum": undefined,
					"maximum": undefined,
					"scalable": undefined
				};
				var newContent = [];
				var settings = {};

				/*
	   * check for the viewport size
	   * <meta name="viewport" content="width=1024,height=697" />
	   */
				if ($viewport && $viewport.hasAttribute("content")) {
					var content = $viewport.getAttribute("content");
					var _width2 = content.match(/width\s*=\s*([^,]*)/);
					var _height2 = content.match(/height\s*=\s*([^,]*)/);
					var _scale2 = content.match(/initial-scale\s*=\s*([^,]*)/);
					var _minimum2 = content.match(/minimum-scale\s*=\s*([^,]*)/);
					var _maximum2 = content.match(/maximum-scale\s*=\s*([^,]*)/);
					var _scalable2 = content.match(/user-scalable\s*=\s*([^,]*)/);

					if (_width2 && _width2.length && typeof _width2[1] !== "undefined") {
						parsed.width = _width2[1];
					}
					if (_height2 && _height2.length && typeof _height2[1] !== "undefined") {
						parsed.height = _height2[1];
					}
					if (_scale2 && _scale2.length && typeof _scale2[1] !== "undefined") {
						parsed.scale = _scale2[1];
					}
					if (_minimum2 && _minimum2.length && typeof _minimum2[1] !== "undefined") {
						parsed.minimum = _minimum2[1];
					}
					if (_maximum2 && _maximum2.length && typeof _maximum2[1] !== "undefined") {
						parsed.maximum = _maximum2[1];
					}
					if (_scalable2 && _scalable2.length && typeof _scalable2[1] !== "undefined") {
						parsed.scalable = _scalable2[1];
					}
				}

				settings = defaults(options || {}, parsed);

				if (options) {
					if (settings.width) {
						newContent.push("width=" + settings.width);
					}

					if (settings.height) {
						newContent.push("height=" + settings.height);
					}

					if (settings.scale) {
						newContent.push("initial-scale=" + settings.scale);
					}

					if (settings.scalable === "no") {
						newContent.push("minimum-scale=" + settings.scale);
						newContent.push("maximum-scale=" + settings.scale);
						newContent.push("user-scalable=" + settings.scalable);
					} else {

						if (settings.scalable) {
							newContent.push("user-scalable=" + settings.scalable);
						}

						if (settings.minimum) {
							newContent.push("minimum-scale=" + settings.minimum);
						}

						if (settings.maximum) {
							newContent.push("minimum-scale=" + settings.maximum);
						}
					}

					if (!$viewport) {
						$viewport = this.document.createElement("meta");
						$viewport.setAttribute("name", "viewport");
						this.document.querySelector("head").appendChild($viewport);
					}

					$viewport.setAttribute("content", newContent.join(", "));

					this.window.scrollTo(0, 0);
				}

				return settings;
			}
		}, {
			key: "setViewport",
			value: function setViewport() {
				this.$viewport = { height: 'auto', width: 'auto' };
				var $viewport = this.document.querySelector("meta[name='viewport']");
				var parsed = {
					"width": undefined,
					"height": undefined,
					"scale": undefined,
					"minimum": undefined,
					"maximum": undefined,
					"scalable": undefined
				};

				/*
	   * check for the viewport size
	   * <meta name="viewport" content="width=1024,height=697" />
	   */
				if ($viewport && $viewport.hasAttribute("content")) {
					var content = $viewport.getAttribute("content");
					var _width = content.match(/width\s*=\s*([^,]*)/);
					var _height = content.match(/height\s*=\s*([^,]*)/);
					var _scale = content.match(/initial-scale\s*=\s*([^,]*)/);
					var _minimum = content.match(/minimum-scale\s*=\s*([^,]*)/);
					var _maximum = content.match(/maximum-scale\s*=\s*([^,]*)/);
					var _scalable = content.match(/user-scalable\s*=\s*([^,]*)/);

					if (_width && _width.length && typeof _width[1] !== "undefined") {
						parsed.width = _width[1];
					}
					if (_height && _height.length && typeof _height[1] !== "undefined") {
						parsed.height = _height[1];
					}
					if (_scale && _scale.length && typeof _scale[1] !== "undefined") {
						parsed.scale = _scale[1];
					}
					if (_minimum && _minimum.length && typeof _minimum[1] !== "undefined") {
						parsed.minimum = _minimum[1];
					}
					if (_maximum && _maximum.length && typeof _maximum[1] !== "undefined") {
						parsed.maximum = _maximum[1];
					}
					if (_scalable && _scalable.length && typeof _scalable[1] !== "undefined") {
						parsed.scalable = _scalable[1];
					}
				}
				this.$viewport.height = parseFloat(parsed.height) || 'auto';
				this.$viewport.width = parseFloat(parsed.width) || 'auto';
			}

			/**
	   * Event emitter for when the contents has expanded
	   * @private
	   */

		}, {
			key: "expand",
			value: function expand() {
				this.emit(EVENTS.CONTENTS.EXPAND);
			}

			/**
	   * Add DOM listeners
	   * @private
	   */

		}, {
			key: "listeners",
			value: function listeners() {

				this.imageLoadListeners();

				this.mediaQueryListeners();

				// this.fontLoadListeners();

				this.addEventListeners();

				this.addSelectionListeners();

				// this.transitionListeners();

				this.resizeListeners();

				// this.resizeObservers();

				this.linksHandler();
			}

			/**
	   * Remove DOM listeners
	   * @private
	   */

		}, {
			key: "removeListeners",
			value: function removeListeners() {

				this.removeEventListeners();

				this.removeSelectionListeners();

				clearTimeout(this.expanding);
			}

			/**
	   * Check if size of contents has changed and
	   * emit 'resize' event if it has.
	   * @private
	   */

		}, {
			key: "resizeCheck",
			value: function resizeCheck() {
				var width = this.textWidth();
				var height = this.textHeight();

				if (width != this._size.width || height != this._size.height) {

					this._size = {
						width: width,
						height: height
					};

					this.onResize && this.onResize(this._size);
					this.emit(EVENTS.CONTENTS.RESIZE, this._size);
				}
			}

			/**
	   * Poll for resize detection
	   * @private
	   */

		}, {
			key: "resizeListeners",
			value: function resizeListeners() {
				// Test size again
				clearTimeout(this.expanding);

				requestAnimationFrame(this.resizeCheck.bind(this));

				this.expanding = setTimeout(this.resizeListeners.bind(this), 350);
			}

			/**
	   * Use css transitions to detect resize
	   * @private
	   */

		}, {
			key: "transitionListeners",
			value: function transitionListeners() {
				var body = this.content;

				body.style['transitionProperty'] = "font, font-size, font-size-adjust, font-stretch, font-variation-settings, font-weight, width, height";
				body.style['transitionDuration'] = "0.001ms";
				body.style['transitionTimingFunction'] = "linear";
				body.style['transitionDelay'] = "0";

				this._resizeCheck = this.resizeCheck.bind(this);
				this.document.addEventListener('transitionend', this._resizeCheck);
			}

			/**
	   * Listen for media query changes and emit 'expand' event
	   * Adapted from: https://github.com/tylergaw/media-query-events/blob/master/js/mq-events.js
	   * @private
	   */

		}, {
			key: "mediaQueryListeners",
			value: function mediaQueryListeners() {
				var sheets = this.document.styleSheets;
				var mediaChangeHandler = function (m) {
					if (m.matches && !this._expanding) {
						setTimeout(this.expand.bind(this), 1);
					}
				}.bind(this);

				for (var i = 0; i < sheets.length; i += 1) {
					var rules;
					// Firefox errors if we access cssRules cross-domain
					try {
						rules = sheets[i].cssRules;
					} catch (e) {
						return;
					}
					if (!rules) return; // Stylesheets changed
					for (var j = 0; j < rules.length; j += 1) {
						//if (rules[j].constructor === CSSMediaRule) {
						if (rules[j].media) {
							var mql = this.window.matchMedia(rules[j].media.mediaText);
							mql.addListener(mediaChangeHandler);
							//mql.onchange = mediaChangeHandler;
						}
					}
				}
			}

			/**
	   * Use MutationObserver to listen for changes in the DOM and check for resize
	   * @private
	   */

		}, {
			key: "resizeObservers",
			value: function resizeObservers() {
				var _this = this;

				// create an observer instance
				this.observer = new MutationObserver(function (mutations) {
					_this.resizeCheck();
				});

				// configuration of the observer:
				var config = { attributes: true, childList: true, characterData: true, subtree: true };

				// pass in the target node, as well as the observer options
				this.observer.observe(this.document, config);
			}

			/**
	   * Test if images are loaded or add listener for when they load
	   * @private
	   */

		}, {
			key: "imageLoadListeners",
			value: function imageLoadListeners() {
				var images = this.document.querySelectorAll("img");
				var img;
				for (var i = 0; i < images.length; i++) {
					img = images[i];

					if (typeof img.naturalWidth !== "undefined" && img.naturalWidth === 0) {
						img.onload = this.expand.bind(this);
					}
				}
			}

			/**
	   * Listen for font load and check for resize when loaded
	   * @private
	   */

		}, {
			key: "fontLoadListeners",
			value: function fontLoadListeners() {
				if (!this.document || !this.document.fonts) {
					return;
				}

				this.document.fonts.ready.then(function () {
					this.resizeCheck();
				}.bind(this));
			}

			/**
	   * Get the documentElement
	   * @returns {element} documentElement
	   */

		}, {
			key: "root",
			value: function root() {
				if (!this.document) return null;
				return this.document.documentElement;
			}

			/**
	   * Get the location offset of a EpubCFI or an #id
	   * @param {string | EpubCFI} target
	   * @param {string} [ignoreClass] for the cfi
	   * @returns { {left: Number, top: Number }
	   */

		}, {
			key: "locationOf",
			value: function locationOf$$1(target, ignoreClass) {
				var position;
				var targetPos = { "left": 0, "top": 0 };

				if (!this.document) return targetPos;

				if (this.epubcfi.isCfiString(target)) {
					var range = new EpubCFI(target).toRange(this.document, ignoreClass);

					if (range) {
						if (range.startContainer.nodeType === Node.ELEMENT_NODE) {
							position = range.startContainer.getBoundingClientRect();
							targetPos.left = position.left;
							targetPos.top = position.top;
						} else {
							// Webkit does not handle collapsed range bounds correctly
							// https://bugs.webkit.org/show_bug.cgi?id=138949

							// Construct a new non-collapsed range
							if (isWebkit) {
								var container = range.startContainer;
								var newRange = new Range();
								try {
									if (container.nodeType === ELEMENT_NODE$2) {
										position = container.getBoundingClientRect();
									} else if (range.startOffset + 2 < container.length) {
										newRange.setStart(container, range.startOffset);
										newRange.setEnd(container, range.startOffset + 2);
										position = newRange.getBoundingClientRect();
									} else if (range.startOffset - 2 > 0) {
										newRange.setStart(container, range.startOffset - 2);
										newRange.setEnd(container, range.startOffset);
										position = newRange.getBoundingClientRect();
									} else {
										// empty, return the parent element
										position = container.parentNode.getBoundingClientRect();
									}
								} catch (e) {
									console.error(e, e.stack);
								}
							} else {
								position = range.getBoundingClientRect();
							}
						}
					}
				} else if (typeof target === "string" && target.indexOf("#") > -1) {

					var id = target.substring(target.indexOf("#") + 1);
					var el = this.document.getElementById(id);

					if (el) {
						position = el.getBoundingClientRect();
						if (position.top < 0) {
							var offsetEl = el.offsetTop ? el : el.offsetParent;
							position = { top: offsetEl.offsetTop, left: offsetEl.offsetLeft };
						}
					}
				}

				if (position) {
					targetPos.left = position.left;
					targetPos.top = position.top;
				}

				return targetPos;
			}

			/**
	   * Append a stylesheet link to the document head
	   * @param {string} src url
	   */

		}, {
			key: "addStylesheet",
			value: function addStylesheet(src) {
				return new Promise(function (resolve, reject) {
					var $stylesheet;
					var ready = false;

					if (!this.document) {
						resolve(false);
						return;
					}

					// Check if link already exists
					$stylesheet = this.document.querySelector("link[href='" + src + "']");
					if ($stylesheet) {
						resolve(true);
						return; // already present
					}

					$stylesheet = this.document.createElement("link");
					$stylesheet.type = "text/css";
					$stylesheet.rel = "stylesheet";
					$stylesheet.href = src;
					$stylesheet.onload = $stylesheet.onreadystatechange = function () {
						if (!ready && (!this.readyState || this.readyState == "complete")) {
							ready = true;
							// Let apply
							setTimeout(function () {
								resolve(true);
							}, 1);
						}
					};

					this.document.head.appendChild($stylesheet);
				}.bind(this));
			}

			/**
	   * Append stylesheet rules to a generate stylesheet
	   * Array: https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet/insertRule
	   * Object: https://github.com/desirable-objects/json-to-css
	   * @param {array | object} rules
	   */

		}, {
			key: "addStylesheetRules",
			value: function addStylesheetRules(rules) {
				var styleEl;
				var styleSheet;
				var key = "epubjs-inserted-css";

				if (!this.document || !rules || rules.length === 0) return;

				// Check if link already exists
				styleEl = this.document.getElementById(key);
				if (!styleEl) {
					styleEl = this.document.createElement("style");
					styleEl.id = key;
				}

				// Append style element to head
				this.document.head.appendChild(styleEl);

				// Grab style sheet
				styleSheet = styleEl.sheet;

				if (Object.prototype.toString.call(rules) === "[object Array]") {
					for (var i = 0, rl = rules.length; i < rl; i++) {
						var j = 1,
						    rule = rules[i],
						    selector = rules[i][0],
						    propStr = "";
						// If the second argument of a rule is an array of arrays, correct our variables.
						if (Object.prototype.toString.call(rule[1][0]) === "[object Array]") {
							rule = rule[1];
							j = 0;
						}

						for (var pl = rule.length; j < pl; j++) {
							var prop = rule[j];
							propStr += prop[0] + ":" + prop[1] + (prop[2] ? " !important" : "") + ";\n";
						}

						// Insert CSS Rule
						styleSheet.insertRule(selector + "{" + propStr + "}", styleSheet.cssRules.length);
					}
				} else {
					var selectors = Object.keys(rules);
					selectors.forEach(function (selector) {
						var definition = rules[selector];
						if (Array.isArray(definition)) {
							definition.forEach(function (item) {
								var _rules = Object.keys(item);
								var result = _rules.map(function (rule) {
									return rule + ":" + item[rule];
								}).join(';');
								styleSheet.insertRule(selector + "{" + result + "}", styleSheet.cssRules.length);
							});
						} else {
							var _rules = Object.keys(definition);
							var result = _rules.map(function (rule) {
								return rule + ":" + definition[rule];
							}).join(';');
							styleSheet.insertRule(selector + "{" + result + "}", styleSheet.cssRules.length);
						}
					});
				}
			}

			/**
	   * Append a script tag to the document head
	   * @param {string} src url
	   * @returns {Promise} loaded
	   */

		}, {
			key: "addScript",
			value: function addScript(src) {

				return new Promise(function (resolve, reject) {
					var $script;
					var ready = false;

					if (!this.document) {
						resolve(false);
						return;
					}

					$script = this.document.createElement("script");
					$script.type = "text/javascript";
					$script.async = true;
					$script.src = src;
					$script.onload = $script.onreadystatechange = function () {
						if (!ready && (!this.readyState || this.readyState == "complete")) {
							ready = true;
							setTimeout(function () {
								resolve(true);
							}, 1);
						}
					};

					this.document.head.appendChild($script);
				}.bind(this));
			}

			/**
	   * Add a class to the contents container
	   * @param {string} className
	   */

		}, {
			key: "addClass",
			value: function addClass(className) {
				var content;

				if (!this.document) return;

				content = this.content || this.document.body;

				if (content) {
					content.classList.add(className);
				}
			}

			/**
	   * Remove a class from the contents container
	   * @param {string} removeClass
	   */

		}, {
			key: "removeClass",
			value: function removeClass(className) {
				var content;

				if (!this.document) return;

				content = this.content || this.document.body;

				if (content) {
					content.classList.remove(className);
				}
			}

			/**
	   * Add DOM event listeners
	   * @private
	   */

		}, {
			key: "addEventListeners",
			value: function addEventListeners() {
				if (!this.document) {
					return;
				}

				this._triggerEvent = this.triggerEvent.bind(this);

				DOM_EVENTS.forEach(function (eventName) {
					this.document.addEventListener(eventName, this._triggerEvent, { passive: true });
				}, this);
			}

			/**
	   * Remove DOM event listeners
	   * @private
	   */

		}, {
			key: "removeEventListeners",
			value: function removeEventListeners() {
				if (!this.document) {
					return;
				}
				DOM_EVENTS.forEach(function (eventName) {
					this.document.removeEventListener(eventName, this._triggerEvent, { passive: true });
				}, this);
				this._triggerEvent = undefined;
			}

			/**
	   * Emit passed browser events
	   * @private
	   */

		}, {
			key: "triggerEvent",
			value: function triggerEvent(e) {
				this.emit(e.type, e);
			}

			/**
	   * Add listener for text selection
	   * @private
	   */

		}, {
			key: "addSelectionListeners",
			value: function addSelectionListeners() {
				if (!this.document) {
					return;
				}
				this._onSelectionChange = this.onSelectionChange.bind(this);
				this.document.addEventListener("selectionchange", this._onSelectionChange, { passive: true });
			}

			/**
	   * Remove listener for text selection
	   * @private
	   */

		}, {
			key: "removeSelectionListeners",
			value: function removeSelectionListeners() {
				if (!this.document) {
					return;
				}
				this.document.removeEventListener("selectionchange", this._onSelectionChange, { passive: true });
				this._onSelectionChange = undefined;
			}

			/**
	   * Handle getting text on selection
	   * @private
	   */

		}, {
			key: "onSelectionChange",
			value: function onSelectionChange(e) {
				if (this.selectionEndTimeout) {
					clearTimeout(this.selectionEndTimeout);
				}
				this.selectionEndTimeout = setTimeout(function () {
					var selection = this.window.getSelection();
					this.triggerSelectedEvent(selection);
				}.bind(this), 250);
			}

			/**
	   * Emit event on text selection
	   * @private
	   */

		}, {
			key: "triggerSelectedEvent",
			value: function triggerSelectedEvent(selection) {
				var range, cfirange;

				if (selection && selection.rangeCount > 0) {
					range = selection.getRangeAt(0);
					if (!range.collapsed) {
						// cfirange = this.section.cfiFromRange(range);
						cfirange = new EpubCFI(range, this.cfiBase).toString();
						this.emit(EVENTS.CONTENTS.SELECTED, cfirange);
						this.emit(EVENTS.CONTENTS.SELECTED_RANGE, range);
					}
				}
			}

			/**
	   * Get a Dom Range from EpubCFI
	   * @param {EpubCFI} _cfi
	   * @param {string} [ignoreClass]
	   * @returns {Range} range
	   */

		}, {
			key: "range",
			value: function range(_cfi, ignoreClass) {
				var cfi = new EpubCFI(_cfi);
				return cfi.toRange(this.document, ignoreClass);
			}

			/**
	   * Get an EpubCFI from a Dom Range
	   * @param {Range} range
	   * @param {string} [ignoreClass]
	   * @returns {EpubCFI} cfi
	   */

		}, {
			key: "cfiFromRange",
			value: function cfiFromRange(range, ignoreClass) {
				return new EpubCFI(range, this.cfiBase, ignoreClass).toString();
			}

			/**
	   * Get an EpubCFI from a Dom node
	   * @param {node} node
	   * @param {string} [ignoreClass]
	   * @returns {EpubCFI} cfi
	   */

		}, {
			key: "cfiFromNode",
			value: function cfiFromNode(node, ignoreClass) {
				return new EpubCFI(node, this.cfiBase, ignoreClass).toString();
			}

			// TODO: find where this is used - remove?

		}, {
			key: "map",
			value: function map(layout) {
				var map = new Mapping(layout);
				return map.section();
			}

			/**
	   * Size the contents to a given width and height
	   * @param {number} [width]
	   * @param {number} [height]
	   */

		}, {
			key: "size",
			value: function size(width, height) {
				var viewport = { scale: 1.0, scalable: "no" };

				this.layoutStyle("scrolling");

				if (width >= 0) {
					this.width(width);
					viewport.width = width;
					this.css("padding", "0 " + width / 12 + "px");
				}

				if (height >= 0) {
					this.height(height);
					viewport.height = height;
				}

				this.css("margin", "0");
				this.css("box-sizing", "border-box");

				this.viewport(viewport);
			}

			/**
	   * Apply columns to the contents for pagination
	   * @param {number} width
	   * @param {number} height
	   * @param {number} columnWidth
	   * @param {number} gap
	   */

		}, {
			key: "columns",
			value: function columns(width, height, columnWidth, gap) {
				var COLUMN_AXIS = prefixed("column-axis");
				var COLUMN_GAP = prefixed("column-gap");
				var COLUMN_WIDTH = prefixed("column-width");
				var COLUMN_FILL = prefixed("column-fill");

				var writingMode = this.writingMode();
				var axis = writingMode.indexOf("vertical") === 0 ? "vertical" : "horizontal";

				this.layoutStyle("paginated");

				// Fix body width issues if rtl is only set on body element
				if (this.content.dir === "rtl") {
					this.direction("rtl");
				}

				this.width(width);
				this.height(height);

				// Deal with Mobile trying to scale to viewport
				this.viewport({ width: width, height: height, scale: 1.0, scalable: "no" });

				// TODO: inline-block needs more testing
				// Fixes Safari column cut offs, but causes RTL issues
				// this.css("display", "inline-block");

				this.css("overflow-y", "hidden");
				this.css("margin", "0", true);

				if (axis === "vertical") {
					this.css("padding-top", gap / 2 + "px", true);
					this.css("padding-bottom", gap / 2 + "px", true);
					this.css("padding-left", "20px");
					this.css("padding-right", "20px");
				} else {
					this.css("padding-top", "20px");
					this.css("padding-bottom", "20px");
					this.css("padding-left", gap / 2 + "px", true);
					this.css("padding-right", gap / 2 + "px", true);
				}

				this.css("box-sizing", "border-box");
				this.css("max-width", "inherit");

				this.css(COLUMN_AXIS, "horizontal");
				this.css(COLUMN_FILL, "auto");

				this.css(COLUMN_GAP, gap + "px");
				this.css(COLUMN_WIDTH, columnWidth + "px");
			}

			/**
	   * Scale contents from center
	   * @param {number} scale
	   * @param {number} offsetX
	   * @param {number} offsetY
	   */

		}, {
			key: "scaler",
			value: function scaler(scale, offsetX, offsetY) {
				var scaleStr = "scale(" + scale + ")";
				var translateStr = "";
				// this.css("position", "absolute"));
				this.css("transform-origin", "top left");

				if (offsetX >= 0 || offsetY >= 0) {
					translateStr = " translate(" + (offsetX || 0) + "px, " + (offsetY || 0) + "px)";
					// } else if ( offsetX || offsetY ) {
					// 	translateStr = " translate(" + offsetX + "," + offsetY + ")";
				}

				this.css("transform", scaleStr + translateStr);
			}

			/**
	   * Fit contents into a fixed width and height
	   * @param {number} width
	   * @param {number} height
	   */

		}, {
			key: "fit",
			value: function fit(width, height) {
				var viewport = this.viewport();
				var viewportWidth;
				var viewportHeight;

				// var viewportWidth = parseInt(viewport.width);
				// var viewportHeight = parseInt(viewport.height);

				if (viewport.width == 'auto' && viewport.height == 'auto') {
					viewportWidth = width;
					viewportHeight = height; // this.textHeight(); // height;
					console.log("AHOY contents.fit", height, this.textHeight());
				} else {
					viewportWidth = parseInt(viewport.width);
					viewportHeight = parseInt(viewport.height);
				}

				var widthScale = width / viewportWidth;
				var heightScale = height / viewportHeight;
				var scale;
				if (this.axis == 'xxxvertical') {
					scale = widthScale > heightScale ? widthScale : heightScale;
				} else {
					scale = widthScale < heightScale ? widthScale : heightScale;
				}
				// console.log("AHOY contents.fit", width, height, ":", viewportWidth, viewportHeight, ":", scale);

				// the translate does not work as intended, elements can end up unaligned
				// var offsetY = (height - (viewportHeight * scale)) / 2;
				// var offsetX = 0;
				// if (this.sectionIndex % 2 === 1) {
				// 	offsetX = width - (viewportWidth * scale);
				// }

				this.layoutStyle("paginated");

				// scale needs width and height to be set
				this.width(viewportWidth);
				this.height(viewportHeight);
				this.overflow("hidden");

				if (viewport.width == 'auto' || viewport.height == 'auto') {
					this.content.style.overflow = 'auto';
					this.addStylesheetRules({
						"body": {
							"margin": 0,
							"padding": "1em",
							"box-sizing": "border-box"
						}
					});
				}

				// Scale to the correct size
				this.scaler(scale, 0, 0);
				// this.scaler(scale, offsetX > 0 ? offsetX : 0, offsetY);

				// background images are not scaled by transform
				this.css("background-size", viewportWidth * scale + "px " + viewportHeight * scale + "px");

				this.css("background-color", "transparent");
			}

			/**
	   * Set the direction of the text
	   * @param {string} [dir="ltr"] "rtl" | "ltr"
	   */

		}, {
			key: "direction",
			value: function direction(dir) {
				if (this.documentElement) {
					this.documentElement.style["direction"] = dir;
				}
			}
		}, {
			key: "mapPage",
			value: function mapPage(cfiBase, layout, start, end, dev) {
				var mapping = new Mapping(layout, dev);

				return mapping.page(this, cfiBase, start, end);
			}

			/**
	   * Emit event when link in content is clicked
	   * @private
	   */

		}, {
			key: "linksHandler",
			value: function linksHandler() {
				var _this2 = this;

				replaceLinks(this.content, function (href) {
					_this2.emit(EVENTS.CONTENTS.LINK_CLICKED, href);
				});
			}

			/**
	   * Set the writingMode of the text
	   * @param {string} [mode="horizontal-tb"] "horizontal-tb" | "vertical-rl" | "vertical-lr"
	   */

		}, {
			key: "writingMode",
			value: function writingMode(mode) {
				var WRITING_MODE = prefixed("writing-mode");

				if (mode && this.documentElement) {
					this.documentElement.style[WRITING_MODE] = mode;
				}

				return this.window.getComputedStyle(this.documentElement)[WRITING_MODE] || '';
			}

			/**
	   * Set the layoutStyle of the content
	   * @param {string} [style="paginated"] "scrolling" | "paginated"
	   * @private
	   */

		}, {
			key: "layoutStyle",
			value: function layoutStyle(style) {

				if (style) {
					this._layoutStyle = style;
					navigator.epubReadingSystem.layoutStyle = this._layoutStyle;
				}

				return this._layoutStyle || "paginated";
			}

			/**
	   * Add the epubReadingSystem object to the navigator
	   * @param {string} name
	   * @param {string} version
	   * @private
	   */

		}, {
			key: "epubReadingSystem",
			value: function epubReadingSystem(name, version) {
				navigator.epubReadingSystem = {
					name: name,
					version: version,
					layoutStyle: this.layoutStyle(),
					hasFeature: function hasFeature(feature) {
						switch (feature) {
							case "dom-manipulation":
								return true;
							case "layout-changes":
								return true;
							case "touch-events":
								return true;
							case "mouse-events":
								return true;
							case "keyboard-events":
								return true;
							case "spine-scripting":
								return false;
							default:
								return false;
						}
					}
				};
				return navigator.epubReadingSystem;
			}
		}, {
			key: "destroy",
			value: function destroy() {
				// Stop observing
				if (this.observer) {
					this.observer.disconnect();
				}

				this.document.removeEventListener('transitionend', this._resizeCheck);

				this.removeListeners();
			}
		}], [{
			key: "listenedEvents",
			get: function get() {
				return DOM_EVENTS;
			}
		}]);

		return Contents;
	}();

	eventEmitter(Contents$1.prototype);

	var _createClass$i = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$i(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
		* Handles managing adding & removing Annotations
		* @param {Rendition} rendition
		* @class
		*/

	var Annotations = function () {
		function Annotations(rendition) {
			_classCallCheck$i(this, Annotations);

			this.rendition = rendition;
			this.highlights = [];
			this.underlines = [];
			this.marks = [];
			this._annotations = {};
			this._annotationsBySectionIndex = {};

			this.rendition.hooks.render.register(this.inject.bind(this));
			this.rendition.hooks.unloaded.register(this.clear.bind(this));
		}

		/**
	  * Add an annotation to store
	  * @param {string} type Type of annotation to add: "highlight", "underline", "mark"
	  * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	  * @param {object} data Data to assign to annotation
	  * @param {function} [cb] Callback after annotation is added
	  * @param {string} className CSS class to assign to annotation
	  * @param {object} styles CSS styles to assign to annotation
	  * @returns {Annotation} annotation
	  */


		_createClass$i(Annotations, [{
			key: "add",
			value: function add(type, cfiRange, data, cb, className, styles) {
				var hash = encodeURI(cfiRange);
				var cfi = new EpubCFI(cfiRange);
				var sectionIndex = cfi.spinePos;
				var annotation = new Annotation({
					type: type,
					cfiRange: cfiRange,
					data: data,
					sectionIndex: sectionIndex,
					cb: cb,
					className: className,
					styles: styles
				});

				this._annotations[hash] = annotation;

				if (sectionIndex in this._annotationsBySectionIndex) {
					this._annotationsBySectionIndex[sectionIndex].push(hash);
				} else {
					this._annotationsBySectionIndex[sectionIndex] = [hash];
				}

				var views = this.rendition.views();

				views.forEach(function (view) {
					if (annotation.sectionIndex === view.index) {
						annotation.attach(view);
					}
				});

				return annotation;
			}

			/**
	   * Remove an annotation from store
	   * @param {EpubCFI} cfiRange EpubCFI range the annotation is attached to
	   * @param {string} type Type of annotation to add: "highlight", "underline", "mark"
	   */

		}, {
			key: "remove",
			value: function remove(cfiRange, type) {
				var _this = this;

				var hash = encodeURI(cfiRange);

				if (hash in this._annotations) {
					var annotation = this._annotations[hash];

					if (type && annotation.type !== type) {
						return;
					}

					var views = this.rendition.views();
					views.forEach(function (view) {
						_this._removeFromAnnotationBySectionIndex(annotation.sectionIndex, hash);
						if (annotation.sectionIndex === view.index) {
							annotation.detach(view);
						}
					});

					delete this._annotations[hash];
				}
			}

			/**
	   * Remove an annotations by Section Index
	   * @private
	   */

		}, {
			key: "_removeFromAnnotationBySectionIndex",
			value: function _removeFromAnnotationBySectionIndex(sectionIndex, hash) {
				this._annotationsBySectionIndex[sectionIndex] = this._annotationsAt(sectionIndex).filter(function (h) {
					return h !== hash;
				});
			}

			/**
	   * Get annotations by Section Index
	   * @private
	   */

		}, {
			key: "_annotationsAt",
			value: function _annotationsAt(index) {
				return this._annotationsBySectionIndex[index];
			}

			/**
	   * Add a highlight to the store
	   * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	   * @param {object} data Data to assign to annotation
	   * @param {function} cb Callback after annotation is added
	   * @param {string} className CSS class to assign to annotation
	   * @param {object} styles CSS styles to assign to annotation
	   */

		}, {
			key: "highlight",
			value: function highlight(cfiRange, data, cb, className, styles) {
				this.add("highlight", cfiRange, data, cb, className, styles);
			}

			/**
	   * Add a underline to the store
	   * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	   * @param {object} data Data to assign to annotation
	   * @param {function} cb Callback after annotation is added
	   * @param {string} className CSS class to assign to annotation
	   * @param {object} styles CSS styles to assign to annotation
	   */

		}, {
			key: "underline",
			value: function underline(cfiRange, data, cb, className, styles) {
				this.add("underline", cfiRange, data, cb, className, styles);
			}

			/**
	   * Add a mark to the store
	   * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	   * @param {object} data Data to assign to annotation
	   * @param {function} cb Callback after annotation is added
	   */

		}, {
			key: "mark",
			value: function mark(cfiRange, data, cb) {
				this.add("mark", cfiRange, data, cb);
			}

			/**
	   * iterate over annotations in the store
	   */

		}, {
			key: "each",
			value: function each() {
				return this._annotations.forEach.apply(this._annotations, arguments);
			}

			/**
	   * Hook for injecting annotation into a view
	   * @param {View} view
	   * @private
	   */

		}, {
			key: "inject",
			value: function inject(view) {
				var _this2 = this;

				var sectionIndex = view.index;
				if (sectionIndex in this._annotationsBySectionIndex) {
					var annotations = this._annotationsBySectionIndex[sectionIndex];
					annotations.forEach(function (hash) {
						var annotation = _this2._annotations[hash];
						annotation.attach(view);
					});
				}
			}

			/**
	   * Hook for removing annotation from a view
	   * @param {View} view
	   * @private
	   */

		}, {
			key: "clear",
			value: function clear(view) {
				var _this3 = this;

				var sectionIndex = view.index;
				if (sectionIndex in this._annotationsBySectionIndex) {
					var annotations = this._annotationsBySectionIndex[sectionIndex];
					annotations.forEach(function (hash) {
						var annotation = _this3._annotations[hash];
						annotation.detach(view);
					});
				}
			}

			/**
	   * [Not Implemented] Show annotations
	   * @TODO: needs implementation in View
	   */

		}, {
			key: "show",
			value: function show() {}

			/**
	   * [Not Implemented] Hide annotations
	   * @TODO: needs implementation in View
	   */

		}, {
			key: "hide",
			value: function hide() {}
		}]);

		return Annotations;
	}();

	/**
	 * Annotation object
	 * @class
	 * @param {object} options
	 * @param {string} options.type Type of annotation to add: "highlight", "underline", "mark"
	 * @param {EpubCFI} options.cfiRange EpubCFI range to attach annotation to
	 * @param {object} options.data Data to assign to annotation
	 * @param {int} options.sectionIndex Index in the Spine of the Section annotation belongs to
	 * @param {function} [options.cb] Callback after annotation is added
	 * @param {string} className CSS class to assign to annotation
	 * @param {object} styles CSS styles to assign to annotation
	 * @returns {Annotation} annotation
	 */


	var Annotation = function () {
		function Annotation(_ref) {
			var type = _ref.type,
			    cfiRange = _ref.cfiRange,
			    data = _ref.data,
			    sectionIndex = _ref.sectionIndex,
			    cb = _ref.cb,
			    className = _ref.className,
			    styles = _ref.styles;

			_classCallCheck$i(this, Annotation);

			this.type = type;
			this.cfiRange = cfiRange;
			this.data = data;
			this.sectionIndex = sectionIndex;
			this.mark = undefined;
			this.cb = cb;
			this.className = className;
			this.styles = styles;
		}

		/**
	  * Update stored data
	  * @param {object} data
	  */


		_createClass$i(Annotation, [{
			key: "update",
			value: function update(data) {
				this.data = data;
			}

			/**
	   * Add to a view
	   * @param {View} view
	   */

		}, {
			key: "attach",
			value: function attach(view) {
				var cfiRange = this.cfiRange,
				    data = this.data,
				    type = this.type,
				    mark = this.mark,
				    cb = this.cb,
				    className = this.className,
				    styles = this.styles;

				var result = void 0;

				if (type === "highlight") {
					result = view.highlight(cfiRange, data, cb, className, styles);
				} else if (type === "underline") {
					result = view.underline(cfiRange, data, cb, className, styles);
				} else if (type === "mark") {
					result = view.mark(cfiRange, data, cb);
				}

				this.mark = result;

				return result;
			}

			/**
	   * Remove from a view
	   * @param {View} view
	   */

		}, {
			key: "detach",
			value: function detach(view) {
				var cfiRange = this.cfiRange,
				    type = this.type;

				var result = void 0;

				if (view) {
					if (type === "highlight") {
						result = view.unhighlight(cfiRange);
					} else if (type === "underline") {
						result = view.ununderline(cfiRange);
					} else if (type === "mark") {
						result = view.unmark(cfiRange);
					}
				}

				this.mark = undefined;

				return result;
			}

			/**
	   * [Not Implemented] Get text of an annotation
	   * @TODO: needs implementation in contents
	   */

		}, {
			key: "text",
			value: function text() {}
		}]);

		return Annotation;
	}();

	eventEmitter(Annotation.prototype);

	function createElement(name) {
	    return document.createElementNS('http://www.w3.org/2000/svg', name);
	}

	var svg$1 = {
	    createElement: createElement
	};

	// import 'babelify/polyfill'; // needed for Object.assign

	var events = {
	    proxyMouse: proxyMouse
	};

	/**
	 * Start proxying all mouse events that occur on the target node to each node in
	 * a set of tracked nodes.
	 *
	 * The items in tracked do not strictly have to be DOM Nodes, but they do have
	 * to have dispatchEvent, getBoundingClientRect, and getClientRects methods.
	 *
	 * @param target {Node} The node on which to listen for mouse events.
	 * @param tracked {Node[]} A (possibly mutable) array of nodes to which to proxy
	 *                         events.
	 */
	function proxyMouse(target, tracked) {
	    function dispatch(e) {
	        // We walk through the set of tracked elements in reverse order so that
	        // events are sent to those most recently added first.
	        //
	        // This is the least surprising behaviour as it simulates the way the
	        // browser would work if items added later were drawn "on top of"
	        // earlier ones.
	        for (var i = tracked.length - 1; i >= 0; i--) {
	            var t = tracked[i];
	            var x = e.clientX;
	            var y = e.clientY;

	            if (e.touches && e.touches.length) {
	                x = e.touches[0].clientX;
	                y = e.touches[0].clientY;
	            }

	            if (!contains$1(t, target, x, y)) {
	                continue;
	            }

	            // The event targets this mark, so dispatch a cloned event:
	            t.dispatchEvent(clone(e));
	            // We only dispatch the cloned event to the first matching mark.
	            break;
	        }
	    }

	    if (target.nodeName === "iframe" || target.nodeName === "IFRAME") {

	        try {
	            // Try to get the contents if same domain
	            this.target = target.contentDocument;
	        } catch (err) {
	            this.target = target;
	        }
	    } else {
	        this.target = target;
	    }

	    var _arr = ['mouseup', 'mousedown', 'click', 'touchstart'];
	    for (var _i = 0; _i < _arr.length; _i++) {
	        var ev = _arr[_i];
	        this.target.addEventListener(ev, function (e) {
	            return dispatch(e);
	        }, false);
	    }
	}

	/**
	 * Clone a mouse event object.
	 *
	 * @param e {MouseEvent} A mouse event object to clone.
	 * @returns {MouseEvent}
	 */
	function clone(e) {
	    var opts = Object.assign({}, e, { bubbles: false });
	    try {
	        return new MouseEvent(e.type, opts);
	    } catch (err) {
	        // compat: webkit
	        var copy = document.createEvent('MouseEvents');
	        copy.initMouseEvent(e.type, false, opts.cancelable, opts.view, opts.detail, opts.screenX, opts.screenY, opts.clientX, opts.clientY, opts.ctrlKey, opts.altKey, opts.shiftKey, opts.metaKey, opts.button, opts.relatedTarget);
	        return copy;
	    }
	}

	/**
	 * Check if the item contains the point denoted by the passed coordinates
	 * @param item {Object} An object with getBoundingClientRect and getClientRects
	 *                      methods.
	 * @param x {Number}
	 * @param y {Number}
	 * @returns {Boolean}
	 */
	function contains$1(item, target, x, y) {
	    // offset
	    var offset = target.getBoundingClientRect();

	    function rectContains(r, x, y) {
	        var top = r.top - offset.top;
	        var left = r.left - offset.left;
	        var bottom = top + r.height;
	        var right = left + r.width;
	        return top <= y && left <= x && bottom > y && right > x;
	    }

	    // Check overall bounding box first
	    var rect = item.getBoundingClientRect();
	    if (!rectContains(rect, x, y)) {
	        return false;
	    }

	    // Then continue to check each child rect
	    var rects = item.getClientRects();
	    for (var i = 0, len = rects.length; i < len; i++) {
	        if (rectContains(rects[i], x, y)) {
	            return true;
	        }
	    }
	    return false;
	}

	var _get = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

	var _createClass$j = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	function _classCallCheck$j(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var Pane = function () {
	    function Pane(target) {
	        var container = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : document.body;

	        _classCallCheck$j(this, Pane);

	        this.target = target;
	        this.element = svg$1.createElement('svg');
	        this.marks = [];

	        // Match the coordinates of the target element
	        this.element.style.position = 'absolute';
	        // Disable pointer events
	        this.element.setAttribute('pointer-events', 'none');

	        // Set up mouse event proxying between the target element and the marks
	        events.proxyMouse(this.target, this.marks);

	        this.container = container;
	        this.container.appendChild(this.element);

	        this.render();
	    }

	    _createClass$j(Pane, [{
	        key: 'addMark',
	        value: function addMark(mark) {
	            var g = svg$1.createElement('g');
	            this.element.appendChild(g);
	            mark.bind(g, this.container);

	            this.marks.push(mark);

	            mark.render();
	            return mark;
	        }
	    }, {
	        key: 'removeMark',
	        value: function removeMark(mark) {
	            var idx = this.marks.indexOf(mark);
	            if (idx === -1) {
	                return;
	            }
	            var el = mark.unbind();
	            this.element.removeChild(el);
	            this.marks.splice(idx, 1);
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            setCoords(this.element, coords(this.target, this.container));
	            var _iteratorNormalCompletion = true;
	            var _didIteratorError = false;
	            var _iteratorError = undefined;

	            try {
	                for (var _iterator = this.marks[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
	                    var m = _step.value;

	                    m.render();
	                }
	            } catch (err) {
	                _didIteratorError = true;
	                _iteratorError = err;
	            } finally {
	                try {
	                    if (!_iteratorNormalCompletion && _iterator.return) {
	                        _iterator.return();
	                    }
	                } finally {
	                    if (_didIteratorError) {
	                        throw _iteratorError;
	                    }
	                }
	            }
	        }
	    }]);

	    return Pane;
	}();

	var Mark = function () {
	    function Mark() {
	        _classCallCheck$j(this, Mark);

	        this.element = null;
	    }

	    _createClass$j(Mark, [{
	        key: 'bind',
	        value: function bind(element, container) {
	            this.element = element;
	            this.container = container;
	        }
	    }, {
	        key: 'unbind',
	        value: function unbind() {
	            var el = this.element;
	            this.element = null;
	            return el;
	        }
	    }, {
	        key: 'render',
	        value: function render() {}
	    }, {
	        key: 'dispatchEvent',
	        value: function dispatchEvent(e) {
	            if (!this.element) return;
	            this.element.dispatchEvent(e);
	        }
	    }, {
	        key: 'getBoundingClientRect',
	        value: function getBoundingClientRect() {
	            return this.element.getBoundingClientRect();
	        }
	    }, {
	        key: 'getClientRects',
	        value: function getClientRects() {
	            var rects = [];
	            var el = this.element.firstChild;
	            while (el) {
	                rects.push(el.getBoundingClientRect());
	                el = el.nextSibling;
	            }
	            return rects;
	        }
	    }, {
	        key: 'filteredRanges',
	        value: function filteredRanges() {
	            var rects = Array.from(this.range.getClientRects());

	            // De-duplicate the boxes
	            return rects.filter(function (box) {
	                for (var i = 0; i < rects.length; i++) {
	                    if (rects[i] === box) {
	                        return true;
	                    }
	                    var contained = contains$2(rects[i], box);
	                    if (contained) {
	                        return false;
	                    }
	                }
	                return true;
	            });
	        }
	    }]);

	    return Mark;
	}();

	var Highlight = function (_Mark) {
	    _inherits(Highlight, _Mark);

	    function Highlight(range, className, data, attributes) {
	        _classCallCheck$j(this, Highlight);

	        var _this = _possibleConstructorReturn(this, (Highlight.__proto__ || Object.getPrototypeOf(Highlight)).call(this));

	        _this.range = range;
	        _this.className = className;
	        _this.data = data || {};
	        _this.attributes = attributes || {};
	        return _this;
	    }

	    _createClass$j(Highlight, [{
	        key: 'bind',
	        value: function bind(element, container) {
	            _get(Highlight.prototype.__proto__ || Object.getPrototypeOf(Highlight.prototype), 'bind', this).call(this, element, container);

	            for (var attr in this.data) {
	                if (this.data.hasOwnProperty(attr)) {
	                    this.element.dataset[attr] = this.data[attr];
	                }
	            }

	            for (var attr in this.attributes) {
	                if (this.attributes.hasOwnProperty(attr)) {
	                    this.element.setAttribute(attr, this.attributes[attr]);
	                }
	            }

	            if (this.className) {
	                this.element.classList.add(this.className);
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            // Empty element
	            while (this.element.firstChild) {
	                this.element.removeChild(this.element.firstChild);
	            }

	            var docFrag = this.element.ownerDocument.createDocumentFragment();
	            var filtered = this.filteredRanges();
	            var offset = this.element.getBoundingClientRect();
	            var container = this.container.getBoundingClientRect();
	            container = { top: container.top, left: container.left };
	            // take into account padding
	            var styles = window.getComputedStyle(this.container);
	            container.left += parseInt(styles.paddingLeft);
	            container.top += parseInt(styles.paddingTop);

	            for (var i = 0, len = filtered.length; i < len; i++) {
	                var r = filtered[i];
	                var el = svg$1.createElement('rect');
	                el.setAttribute('x', r.left - offset.left + container.left);
	                el.setAttribute('y', r.top - offset.top + container.top);
	                el.setAttribute('height', r.height);
	                el.setAttribute('width', r.width);
	                docFrag.appendChild(el);
	            }

	            this.element.appendChild(docFrag);
	        }
	    }]);

	    return Highlight;
	}(Mark);

	var Underline = function (_Highlight) {
	    _inherits(Underline, _Highlight);

	    function Underline(range, className, data, attributes) {
	        _classCallCheck$j(this, Underline);

	        return _possibleConstructorReturn(this, (Underline.__proto__ || Object.getPrototypeOf(Underline)).call(this, range, className, data, attributes));
	    }

	    _createClass$j(Underline, [{
	        key: 'render',
	        value: function render() {
	            // Empty element
	            while (this.element.firstChild) {
	                this.element.removeChild(this.element.firstChild);
	            }

	            var docFrag = this.element.ownerDocument.createDocumentFragment();
	            var filtered = this.filteredRanges();
	            var offset = this.element.getBoundingClientRect();
	            var container = this.container.getBoundingClientRect();

	            for (var i = 0, len = filtered.length; i < len; i++) {
	                var r = filtered[i];

	                var rect = svg$1.createElement('rect');
	                rect.setAttribute('x', r.left - offset.left + container.left);
	                rect.setAttribute('y', r.top - offset.top + container.top);
	                rect.setAttribute('height', r.height);
	                rect.setAttribute('width', r.width);
	                rect.setAttribute('fill', 'none');

	                var line = svg$1.createElement('line');
	                line.setAttribute('x1', r.left - offset.left + container.left);
	                line.setAttribute('x2', r.left - offset.left + container.left + r.width);
	                line.setAttribute('y1', r.top - offset.top + container.top + r.height - 1);
	                line.setAttribute('y2', r.top - offset.top + container.top + r.height - 1);

	                line.setAttribute('stroke-width', 1);
	                line.setAttribute('stroke', 'black'); //TODO: match text color?
	                line.setAttribute('stroke-linecap', 'square');

	                docFrag.appendChild(rect);

	                docFrag.appendChild(line);
	            }

	            this.element.appendChild(docFrag);
	        }
	    }]);

	    return Underline;
	}(Highlight);

	function coords(el, container) {
	    var offset = container.getBoundingClientRect();
	    var rect = el.getBoundingClientRect();

	    return {
	        top: rect.top - offset.top,
	        left: rect.left - offset.left,
	        height: el.scrollHeight,
	        width: el.scrollWidth
	    };
	}

	function setCoords(el, coords) {
	    el.style.setProperty('top', coords.top + 'px', 'important');
	    el.style.setProperty('left', coords.left + 'px', 'important');
	    el.style.setProperty('height', coords.height + 'px', 'important');
	    el.style.setProperty('width', coords.width + 'px', 'important');
	}

	function contains$2(rect1, rect2) {
	    return rect2.right <= rect1.right && rect2.left >= rect1.left && rect2.top >= rect1.top && rect2.bottom <= rect1.bottom;
	}

	var _createClass$k = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$k(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var IframeView = function () {
		function IframeView(section, options) {
			_classCallCheck$k(this, IframeView);

			this.settings = extend$1({
				ignoreClass: "",
				axis: options.layout && options.layout.props.flow === "scrolled" ? "vertical" : "horizontal",
				direction: undefined,
				width: 0,
				height: 0,
				layout: undefined,
				globalLayoutProperties: {},
				method: undefined
			}, options || {});

			this.id = "epubjs-view-" + uuid();
			this.section = section;
			this.index = section.index;

			this.element = this.container(this.settings.axis);

			this.added = false;
			this.displayed = false;
			this.rendered = false;

			// this.width  = this.settings.width;
			// this.height = this.settings.height;

			this.fixedWidth = 0;
			this.fixedHeight = 0;

			// Blank Cfi for Parsing
			this.epubcfi = new EpubCFI();

			this.layout = this.settings.layout;
			// console.log("AHOY iframe NEW", this.layout.height);
			// Dom events to listen for
			// this.listenedEvents = ["keydown", "keyup", "keypressed", "mouseup", "mousedown", "click", "touchend", "touchstart"];

			this.pane = undefined;
			this.highlights = {};
			this.underlines = {};
			this.marks = {};
		}

		_createClass$k(IframeView, [{
			key: "container",
			value: function container(axis) {
				var element = document.createElement("div");

				element.classList.add("epub-view");

				// this.element.style.minHeight = "100px";
				element.style.height = "0px";
				element.style.width = "0px";
				element.style.overflow = "hidden";
				element.style.position = "relative";
				element.style.display = "block";

				if (axis && axis == "horizontal") {
					element.style.flex = "none";
				} else {
					element.style.flex = "initial";
				}

				return element;
			}
		}, {
			key: "create",
			value: function create() {

				if (this.iframe) {
					return this.iframe;
				}

				if (!this.element) {
					this.element = this.createContainer();
				}

				this.iframe = document.createElement("iframe");
				this.iframe.id = this.id;
				this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations
				this.iframe.style.overflow = "hidden";
				this.iframe.seamless = "seamless";
				// Back up if seamless isn't supported
				this.iframe.style.border = "none";

				this.iframe.setAttribute("enable-annotation", "true");

				this.resizing = true;

				// this.iframe.style.display = "none";
				this.element.style.visibility = "hidden";
				this.iframe.style.visibility = "hidden";

				this.iframe.style.width = "0";
				this.iframe.style.height = "0";
				this._width = 0;
				this._height = 0;

				this.element.setAttribute("ref", this.index);

				this.added = true;

				this.elementBounds = bounds$1(this.element);

				// if(width || height){
				//   this.resize(width, height);
				// } else if(this.width && this.height){
				//   this.resize(this.width, this.height);
				// } else {
				//   this.iframeBounds = bounds(this.iframe);
				// }


				if ("srcdoc" in this.iframe) {
					this.supportsSrcdoc = true;
				} else {
					this.supportsSrcdoc = false;
				}

				if (!this.settings.method) {
					this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
				}

				return this.iframe;
			}
		}, {
			key: "render",
			value: function render(request, show) {

				// view.onLayout = this.layout.format.bind(this.layout);
				this.create();

				// Fit to size of the container, apply padding
				this.size();

				if (!this.sectionRender) {
					this.sectionRender = this.section.render(request);
				}

				// Render Chain
				return this.sectionRender.then(function (contents) {
					return this.load(contents);
				}.bind(this)).then(function () {
					var _this = this;

					// apply the layout function to the contents
					// console.log("AHOY IFRAME render", this.layout.height);
					this.layout.format(this.contents);

					// find and report the writingMode axis
					var writingMode = this.contents.writingMode();
					var axis = writingMode.indexOf("vertical") === 0 ? "vertical" : "horizontal";

					this.setAxis(axis);
					this.emit(EVENTS.VIEWS.AXIS, axis);

					// Listen for events that require an expansion of the iframe
					this.addListeners();

					return new Promise(function (resolve, reject) {
						// Expand the iframe to the full size of the content
						_this.expand();
						resolve();
					});
				}.bind(this), function (e) {
					this.emit(EVENTS.VIEWS.LOAD_ERROR, e);
					return new Promise(function (resolve, reject) {
						reject(e);
					});
				}.bind(this)).then(function () {
					this.emit(EVENTS.VIEWS.RENDERED, this.section);
				}.bind(this));
			}
		}, {
			key: "reset",
			value: function reset() {
				if (this.iframe) {
					this.iframe.style.width = "0";
					this.iframe.style.height = "0";
					this._width = 0;
					this._height = 0;
					this._textWidth = undefined;
					this._contentWidth = undefined;
					this._textHeight = undefined;
					this._contentHeight = undefined;
				}
				this._needsReframe = true;
			}

			// Determine locks base on settings

		}, {
			key: "size",
			value: function size(_width, _height) {
				var width = _width || this.settings.width;
				var height = _height || this.settings.height;

				if (this.layout.name === "pre-paginated") {
					this.lock("both", width, height);
					// console.log("AHOY IRAME size lock", width, height);
				} else if (this.settings.axis === "horizontal") {
					this.lock("height", width, height);
				} else {
					this.lock("width", width, height);
				}

				this.settings.width = width;
				this.settings.height = height;
			}

			// Lock an axis to element dimensions, taking borders into account

		}, {
			key: "lock",
			value: function lock(what, width, height) {
				var elBorders = borders(this.element);
				var iframeBorders;

				if (this.iframe) {
					iframeBorders = borders(this.iframe);
				} else {
					iframeBorders = { width: 0, height: 0 };
				}

				if (what == "width" && isNumber(width)) {
					this.lockedWidth = width - elBorders.width - iframeBorders.width;
					// this.resize(this.lockedWidth, width); //  width keeps ratio correct
				}

				if (what == "height" && isNumber(height)) {
					this.lockedHeight = height - elBorders.height - iframeBorders.height;
					// this.resize(width, this.lockedHeight);
				}

				if (what === "both" && isNumber(width) && isNumber(height)) {

					this.lockedWidth = width - elBorders.width - iframeBorders.width;
					this.lockedHeight = height - elBorders.height - iframeBorders.height;
					// this.resize(this.lockedWidth, this.lockedHeight);
				}

				if (this.displayed && this.iframe) {

					// this.contents.layout();
					this.expand();
				}
			}

			// Resize a single axis based on content dimensions

		}, {
			key: "expand",
			value: function expand(force) {
				var width = this.lockedWidth;
				var height = this.lockedHeight;
				var columns;

				if (!this.iframe || this._expanding) return;

				this._expanding = true;

				if (this.layout.name === 'pre-paginated' && this.settings.axis === 'vertical') {
					height = this.contents.textHeight();
					width = this.contents.textWidth();
					// width = this.layout.columnWidth;
				} else if (this.layout.name === "pre-paginated") {
					width = this.layout.columnWidth;
					height = this.layout.height;
				}
				// Expand Horizontally
				else if (this.settings.axis === "horizontal") {
						// Get the width of the text
						width = this.contents.textWidth();

						if (width % this.layout.pageWidth > 0) {
							width = Math.ceil(width / this.layout.pageWidth) * this.layout.pageWidth;
						}

						if (this.settings.forceEvenPages) {
							columns = width / this.layout.pageWidth;
							if (this.layout.divisor > 1 && this.layout.name === "reflowable" && columns % 2 > 0) {
								// add a blank page
								width += this.layout.pageWidth;
							}
						}
					} // Expand Vertically
					else if (this.settings.axis === "vertical") {
							height = this.contents.textHeight();
							// width = this.contents.textWidth();
							// console.log("AHOY AHOY expand", this.index, width, height, "/", this._width, this._height);
						}

				// Only Resize if dimensions have changed or
				// if Frame is still hidden, so needs reframing
				if (this._needsReframe || width != this._width || height != this._height) {
					this.reframe(width, height);
				}

				this._expanding = false;
			}
		}, {
			key: "reframe",
			value: function reframe(width, height) {
				var _this2 = this;

				var size;

				if (isNumber(width)) {
					this.element.style.width = width + "px";
					this.iframe.style.width = width + "px";
					this._width = width;
				}

				if (isNumber(height)) {
					this.element.style.height = height + "px";
					this.iframe.style.height = height + "px";
					this._height = height;
				}

				var widthDelta = this.prevBounds ? width - this.prevBounds.width : width;
				var heightDelta = this.prevBounds ? height - this.prevBounds.height : height;

				size = {
					width: width,
					height: height,
					widthDelta: widthDelta,
					heightDelta: heightDelta
				};

				this.pane && this.pane.render();

				requestAnimationFrame(function () {
					var mark = void 0;
					for (var m in _this2.marks) {
						if (_this2.marks.hasOwnProperty(m)) {
							mark = _this2.marks[m];
							_this2.placeMark(mark.element, mark.range);
						}
					}
				});

				this.onResize(this, size);

				this.emit(EVENTS.VIEWS.RESIZED, size);

				this.prevBounds = size;

				this.elementBounds = bounds$1(this.element);
			}
		}, {
			key: "load",
			value: function load(contents) {
				var loading = new defer();
				var loaded = loading.promise;

				if (!this.iframe) {
					loading.reject(new Error("No Iframe Available"));
					return loaded;
				}

				this.iframe.onload = function (event) {

					this.onLoad(event, loading);
				}.bind(this);

				if (this.settings.method === "blobUrl") {
					this.blobUrl = createBlobUrl(contents, "application/xhtml+xml");
					this.iframe.src = this.blobUrl;
					this.element.appendChild(this.iframe);
				} else if (this.settings.method === "srcdoc") {
					this.iframe.srcdoc = contents;
					this.element.appendChild(this.iframe);
				} else {

					this.element.appendChild(this.iframe);

					this.document = this.iframe.contentDocument;

					if (!this.document) {
						loading.reject(new Error("No Document Available"));
						return loaded;
					}

					this.iframe.contentDocument.open();
					this.iframe.contentDocument.write(contents);
					this.iframe.contentDocument.close();
				}

				return loaded;
			}
		}, {
			key: "onLoad",
			value: function onLoad(event, promise) {
				var _this3 = this;

				this.window = this.iframe.contentWindow;
				this.document = this.iframe.contentDocument;

				this.contents = new Contents$1(this.document, this.document.body, this.section.cfiBase, this.section.index);

				this.rendering = false;

				var link = this.document.querySelector("link[rel='canonical']");
				if (link) {
					link.setAttribute("href", this.section.canonical);
				} else {
					link = this.document.createElement("link");
					link.setAttribute("rel", "canonical");
					link.setAttribute("href", this.section.canonical);
					this.document.querySelector("head").appendChild(link);
				}

				this.contents.on(EVENTS.CONTENTS.EXPAND, function () {
					if (_this3.displayed && _this3.iframe) {
						_this3.expand();
						if (_this3.contents) {
							_this3.layout.format(_this3.contents);
						}
					}
				});

				this.contents.on(EVENTS.CONTENTS.RESIZE, function (e) {
					if (_this3.displayed && _this3.iframe) {
						_this3.expand();
						if (_this3.contents) {
							_this3.layout.format(_this3.contents);
						}
					}
				});

				promise.resolve(this.contents);
			}
		}, {
			key: "setLayout",
			value: function setLayout(layout) {
				this.layout = layout;

				if (this.contents) {
					this.layout.format(this.contents);
					this.expand();
				}
			}
		}, {
			key: "setAxis",
			value: function setAxis(axis) {

				// Force vertical for scrolled
				if (this.layout.props.flow === "scrolled") {
					axis = "vertical";
				}

				this.settings.axis = axis;

				if (axis == "horizontal") {
					this.element.style.flex = "none";
				} else {
					this.element.style.flex = "initial";
				}

				this.size();
			}
		}, {
			key: "addListeners",
			value: function addListeners() {
				//TODO: Add content listeners for expanding
			}
		}, {
			key: "removeListeners",
			value: function removeListeners(layoutFunc) {
				//TODO: remove content listeners for expanding
			}
		}, {
			key: "display",
			value: function display(request) {
				var displayed = new defer();

				if (!this.displayed) {

					this.render(request).then(function () {

						this.emit(EVENTS.VIEWS.DISPLAYED, this);
						this.onDisplayed(this);

						this.displayed = true;
						displayed.resolve(this);
					}.bind(this), function (err) {
						displayed.reject(err, this);
					});
				} else {
					displayed.resolve(this);
				}

				return displayed.promise;
			}
		}, {
			key: "show",
			value: function show() {

				this.element.style.visibility = "visible";

				if (this.iframe) {
					this.iframe.style.visibility = "visible";

					// Remind Safari to redraw the iframe
					this.iframe.style.transform = "translateZ(0)";
					this.iframe.offsetWidth;
					this.iframe.style.transform = null;
				}

				// console.log("AHOY VIEWS iframe show", this.index);
				this.emit(EVENTS.VIEWS.SHOWN, this);
			}
		}, {
			key: "hide",
			value: function hide() {
				// this.iframe.style.display = "none";
				this.element.style.visibility = "hidden";
				this.iframe.style.visibility = "hidden";

				this.stopExpanding = true;
				// console.log("AHOY VIEWS iframe hide", this.index);
				this.emit(EVENTS.VIEWS.HIDDEN, this);
			}
		}, {
			key: "offset",
			value: function offset() {
				return {
					top: this.element.offsetTop,
					left: this.element.offsetLeft
				};
			}
		}, {
			key: "width",
			value: function width() {
				return this._width;
			}
		}, {
			key: "height",
			value: function height() {
				return this._height;
			}
		}, {
			key: "position",
			value: function position() {
				return this.element.getBoundingClientRect();
			}
		}, {
			key: "locationOf",
			value: function locationOf$$1(target) {
				var parentPos = this.iframe.getBoundingClientRect();
				var targetPos = this.contents.locationOf(target, this.settings.ignoreClass);

				return {
					"left": targetPos.left,
					"top": targetPos.top
				};
			}
		}, {
			key: "onDisplayed",
			value: function onDisplayed(view) {
				// Stub, override with a custom functions
			}
		}, {
			key: "onResize",
			value: function onResize(view, e) {
				// Stub, override with a custom functions
			}
		}, {
			key: "bounds",
			value: function bounds$$1(force) {
				if (force || !this.elementBounds) {
					this.elementBounds = bounds$1(this.element);
				}

				return this.elementBounds;
			}
		}, {
			key: "highlight",
			value: function highlight(cfiRange) {
				var data = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
				var cb = arguments[2];

				var _this4 = this;

				var className = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : "epubjs-hl";
				var styles = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : {};

				if (!this.contents) {
					return;
				}
				var attributes = Object.assign({ "fill": "yellow", "fill-opacity": "0.3", "mix-blend-mode": "multiply" }, styles);
				var range = this.contents.range(cfiRange);

				var emitter = function emitter() {
					_this4.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
				};

				data["epubcfi"] = cfiRange;

				if (!this.pane) {
					this.pane = new Pane(this.iframe, this.element);
				}

				var m = new Highlight(range, className, data, attributes);
				var h = this.pane.addMark(m);

				this.highlights[cfiRange] = { "mark": h, "element": h.element, "listeners": [emitter, cb] };

				h.element.setAttribute("ref", className);
				h.element.addEventListener("click", emitter);
				h.element.addEventListener("touchstart", emitter);

				if (cb) {
					h.element.addEventListener("click", cb);
					h.element.addEventListener("touchstart", cb);
				}
				return h;
			}
		}, {
			key: "underline",
			value: function underline(cfiRange) {
				var data = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
				var cb = arguments[2];

				var _this5 = this;

				var className = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : "epubjs-ul";
				var styles = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : {};

				if (!this.contents) {
					return;
				}
				var attributes = Object.assign({ "stroke": "black", "stroke-opacity": "0.3", "mix-blend-mode": "multiply" }, styles);
				var range = this.contents.range(cfiRange);
				var emitter = function emitter() {
					_this5.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
				};

				data["epubcfi"] = cfiRange;

				if (!this.pane) {
					this.pane = new Pane(this.iframe, this.element);
				}

				var m = new Underline(range, className, data, attributes);
				var h = this.pane.addMark(m);

				this.underlines[cfiRange] = { "mark": h, "element": h.element, "listeners": [emitter, cb] };

				h.element.setAttribute("ref", className);
				h.element.addEventListener("click", emitter);
				h.element.addEventListener("touchstart", emitter);

				if (cb) {
					h.element.addEventListener("click", cb);
					h.element.addEventListener("touchstart", cb);
				}
				return h;
			}
		}, {
			key: "mark",
			value: function mark(cfiRange) {
				var _this6 = this;

				var data = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
				var cb = arguments[2];

				if (!this.contents) {
					return;
				}

				if (cfiRange in this.marks) {
					var item = this.marks[cfiRange];
					return item;
				}

				var range = this.contents.range(cfiRange);
				if (!range) {
					return;
				}
				var container = range.commonAncestorContainer;
				var parent = container.nodeType === 1 ? container : container.parentNode;

				var emitter = function emitter(e) {
					_this6.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
				};

				if (range.collapsed && container.nodeType === 1) {
					range = new Range();
					range.selectNodeContents(container);
				} else if (range.collapsed) {
					// Webkit doesn't like collapsed ranges
					range = new Range();
					range.selectNodeContents(parent);
				}

				var mark = this.document.createElement("a");
				mark.setAttribute("ref", "epubjs-mk");
				mark.style.position = "absolute";

				mark.dataset["epubcfi"] = cfiRange;

				if (data) {
					Object.keys(data).forEach(function (key) {
						mark.dataset[key] = data[key];
					});
				}

				if (cb) {
					mark.addEventListener("click", cb);
					mark.addEventListener("touchstart", cb);
				}

				mark.addEventListener("click", emitter);
				mark.addEventListener("touchstart", emitter);

				this.placeMark(mark, range);

				this.element.appendChild(mark);

				this.marks[cfiRange] = { "element": mark, "range": range, "listeners": [emitter, cb] };

				return parent;
			}
		}, {
			key: "placeMark",
			value: function placeMark(element, range) {
				var top = void 0,
				    right = void 0,
				    left = void 0;

				if (this.layout.name === "pre-paginated" || this.settings.axis !== "horizontal") {
					var pos = range.getBoundingClientRect();
					top = pos.top;
					right = pos.right;
				} else {
					// Element might break columns, so find the left most element
					var rects = range.getClientRects();

					var rect = void 0;
					for (var i = 0; i != rects.length; i++) {
						rect = rects[i];
						if (!left || rect.left < left) {
							left = rect.left;
							// right = rect.right;
							right = Math.ceil(left / this.layout.props.pageWidth) * this.layout.props.pageWidth - this.layout.gap / 2;
							top = rect.top;
						}
					}
				}

				element.style.top = top + "px";
				element.style.left = right + "px";
			}
		}, {
			key: "unhighlight",
			value: function unhighlight(cfiRange) {
				var item = void 0;
				if (cfiRange in this.highlights) {
					item = this.highlights[cfiRange];

					this.pane.removeMark(item.mark);
					item.listeners.forEach(function (l) {
						if (l) {
							item.element.removeEventListener("click", l);
							item.element.removeEventListener("touchstart", l);
						}				});
					delete this.highlights[cfiRange];
				}
			}
		}, {
			key: "ununderline",
			value: function ununderline(cfiRange) {
				var item = void 0;
				if (cfiRange in this.underlines) {
					item = this.underlines[cfiRange];
					this.pane.removeMark(item.mark);
					item.listeners.forEach(function (l) {
						if (l) {
							item.element.removeEventListener("click", l);
							item.element.removeEventListener("touchstart", l);
						}				});
					delete this.underlines[cfiRange];
				}
			}
		}, {
			key: "unmark",
			value: function unmark(cfiRange) {
				var item = void 0;
				if (cfiRange in this.marks) {
					item = this.marks[cfiRange];
					this.element.removeChild(item.element);
					item.listeners.forEach(function (l) {
						if (l) {
							item.element.removeEventListener("click", l);
							item.element.removeEventListener("touchstart", l);
						}				});
					delete this.marks[cfiRange];
				}
			}
		}, {
			key: "destroy",
			value: function destroy() {

				for (var cfiRange in this.highlights) {
					this.unhighlight(cfiRange);
				}

				for (var _cfiRange in this.underlines) {
					this.ununderline(_cfiRange);
				}

				for (var _cfiRange2 in this.marks) {
					this.unmark(_cfiRange2);
				}

				if (this.blobUrl) {
					revokeBlobUrl(this.blobUrl);
				}

				if (this.displayed) {
					this.displayed = false;

					this.removeListeners();

					this.stopExpanding = true;
					this.element.removeChild(this.iframe);

					this.iframe = undefined;
					this.contents = undefined;

					this._textWidth = null;
					this._textHeight = null;
					this._width = null;
					this._height = null;
				}

				// this.element.style.height = "0px";
				// this.element.style.width = "0px";
			}
		}]);

		return IframeView;
	}();

	eventEmitter(IframeView.prototype);

	var _typeof$7 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	/**
	 * Checks if `value` is the
	 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
	 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
	 * @example
	 *
	 * _.isObject({});
	 * // => true
	 *
	 * _.isObject([1, 2, 3]);
	 * // => true
	 *
	 * _.isObject(_.noop);
	 * // => true
	 *
	 * _.isObject(null);
	 * // => false
	 */
	function isObject$1(value) {
	  var type = typeof value === 'undefined' ? 'undefined' : _typeof$7(value);
	  return value != null && (type == 'object' || type == 'function');
	}

	var isObject_1$1 = isObject$1;

	var _typeof$8 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	/** Detect free variable `global` from Node.js. */
	var freeGlobal$1 = (typeof commonjsGlobal === 'undefined' ? 'undefined' : _typeof$8(commonjsGlobal)) == 'object' && commonjsGlobal && commonjsGlobal.Object === Object && commonjsGlobal;

	var _freeGlobal$1 = freeGlobal$1;

	var _typeof$9 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };



	/** Detect free variable `self`. */
	var freeSelf$1 = (typeof self === 'undefined' ? 'undefined' : _typeof$9(self)) == 'object' && self && self.Object === Object && self;

	/** Used as a reference to the global object. */
	var root$1 = _freeGlobal$1 || freeSelf$1 || Function('return this')();

	var _root$1 = root$1;

	/**
	 * Gets the timestamp of the number of milliseconds that have elapsed since
	 * the Unix epoch (1 January 1970 00:00:00 UTC).
	 *
	 * @static
	 * @memberOf _
	 * @since 2.4.0
	 * @category Date
	 * @returns {number} Returns the timestamp.
	 * @example
	 *
	 * _.defer(function(stamp) {
	 *   console.log(_.now() - stamp);
	 * }, _.now());
	 * // => Logs the number of milliseconds it took for the deferred invocation.
	 */
	var now$1 = function now() {
	  return _root$1.Date.now();
	};

	var now_1$1 = now$1;

	/** Built-in value references. */
	var _Symbol$1 = _root$1.Symbol;

	var _Symbol_1 = _Symbol$1;

	/** Used for built-in method references. */
	var objectProto$9 = Object.prototype;

	/** Used to check objects for own properties. */
	var hasOwnProperty$7 = objectProto$9.hasOwnProperty;

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var nativeObjectToString$2 = objectProto$9.toString;

	/** Built-in value references. */
	var symToStringTag$2 = _Symbol_1 ? _Symbol_1.toStringTag : undefined;

	/**
	 * A specialized version of `baseGetTag` which ignores `Symbol.toStringTag` values.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {string} Returns the raw `toStringTag`.
	 */
	function getRawTag$1(value) {
	  var isOwn = hasOwnProperty$7.call(value, symToStringTag$2),
	      tag = value[symToStringTag$2];

	  try {
	    value[symToStringTag$2] = undefined;
	  } catch (e) {}

	  var result = nativeObjectToString$2.call(value);
	  {
	    if (isOwn) {
	      value[symToStringTag$2] = tag;
	    } else {
	      delete value[symToStringTag$2];
	    }
	  }
	  return result;
	}

	var _getRawTag$1 = getRawTag$1;

	/** Used for built-in method references. */
	var objectProto$a = Object.prototype;

	/**
	 * Used to resolve the
	 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
	 * of values.
	 */
	var nativeObjectToString$3 = objectProto$a.toString;

	/**
	 * Converts `value` to a string using `Object.prototype.toString`.
	 *
	 * @private
	 * @param {*} value The value to convert.
	 * @returns {string} Returns the converted string.
	 */
	function objectToString$1(value) {
	  return nativeObjectToString$3.call(value);
	}

	var _objectToString$1 = objectToString$1;

	/** `Object#toString` result references. */
	var nullTag$1 = '[object Null]',
	    undefinedTag$1 = '[object Undefined]';

	/** Built-in value references. */
	var symToStringTag$3 = _Symbol_1 ? _Symbol_1.toStringTag : undefined;

	/**
	 * The base implementation of `getTag` without fallbacks for buggy environments.
	 *
	 * @private
	 * @param {*} value The value to query.
	 * @returns {string} Returns the `toStringTag`.
	 */
	function baseGetTag$1(value) {
	    if (value == null) {
	        return value === undefined ? undefinedTag$1 : nullTag$1;
	    }
	    return symToStringTag$3 && symToStringTag$3 in Object(value) ? _getRawTag$1(value) : _objectToString$1(value);
	}

	var _baseGetTag$1 = baseGetTag$1;

	var _typeof$a = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	/**
	 * Checks if `value` is object-like. A value is object-like if it's not `null`
	 * and has a `typeof` result of "object".
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
	 * @example
	 *
	 * _.isObjectLike({});
	 * // => true
	 *
	 * _.isObjectLike([1, 2, 3]);
	 * // => true
	 *
	 * _.isObjectLike(_.noop);
	 * // => false
	 *
	 * _.isObjectLike(null);
	 * // => false
	 */
	function isObjectLike$1(value) {
	  return value != null && (typeof value === 'undefined' ? 'undefined' : _typeof$a(value)) == 'object';
	}

	var isObjectLike_1$1 = isObjectLike$1;

	var _typeof$b = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };



	/** `Object#toString` result references. */
	var symbolTag$1 = '[object Symbol]';

	/**
	 * Checks if `value` is classified as a `Symbol` primitive or object.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to check.
	 * @returns {boolean} Returns `true` if `value` is a symbol, else `false`.
	 * @example
	 *
	 * _.isSymbol(Symbol.iterator);
	 * // => true
	 *
	 * _.isSymbol('abc');
	 * // => false
	 */
	function isSymbol$1(value) {
	    return (typeof value === 'undefined' ? 'undefined' : _typeof$b(value)) == 'symbol' || isObjectLike_1$1(value) && _baseGetTag$1(value) == symbolTag$1;
	}

	var isSymbol_1$1 = isSymbol$1;

	/** Used as references for various `Number` constants. */
	var NAN$1 = 0 / 0;

	/** Used to match leading and trailing whitespace. */
	var reTrim$1 = /^\s+|\s+$/g;

	/** Used to detect bad signed hexadecimal string values. */
	var reIsBadHex$1 = /^[-+]0x[0-9a-f]+$/i;

	/** Used to detect binary string values. */
	var reIsBinary$1 = /^0b[01]+$/i;

	/** Used to detect octal string values. */
	var reIsOctal$1 = /^0o[0-7]+$/i;

	/** Built-in method references without a dependency on `root`. */
	var freeParseInt$1 = parseInt;

	/**
	 * Converts `value` to a number.
	 *
	 * @static
	 * @memberOf _
	 * @since 4.0.0
	 * @category Lang
	 * @param {*} value The value to process.
	 * @returns {number} Returns the number.
	 * @example
	 *
	 * _.toNumber(3.2);
	 * // => 3.2
	 *
	 * _.toNumber(Number.MIN_VALUE);
	 * // => 5e-324
	 *
	 * _.toNumber(Infinity);
	 * // => Infinity
	 *
	 * _.toNumber('3.2');
	 * // => 3.2
	 */
	function toNumber$1(value) {
	  if (typeof value == 'number') {
	    return value;
	  }
	  if (isSymbol_1$1(value)) {
	    return NAN$1;
	  }
	  if (isObject_1$1(value)) {
	    var other = typeof value.valueOf == 'function' ? value.valueOf() : value;
	    value = isObject_1$1(other) ? other + '' : other;
	  }
	  if (typeof value != 'string') {
	    return value === 0 ? value : +value;
	  }
	  value = value.replace(reTrim$1, '');
	  var isBinary = reIsBinary$1.test(value);
	  return isBinary || reIsOctal$1.test(value) ? freeParseInt$1(value.slice(2), isBinary ? 2 : 8) : reIsBadHex$1.test(value) ? NAN$1 : +value;
	}

	var toNumber_1$1 = toNumber$1;

	/** Error message constants. */
	var FUNC_ERROR_TEXT$1 = 'Expected a function';

	/* Built-in method references for those with the same name as other `lodash` methods. */
	var nativeMax$2 = Math.max,
	    nativeMin$1 = Math.min;

	/**
	 * Creates a debounced function that delays invoking `func` until after `wait`
	 * milliseconds have elapsed since the last time the debounced function was
	 * invoked. The debounced function comes with a `cancel` method to cancel
	 * delayed `func` invocations and a `flush` method to immediately invoke them.
	 * Provide `options` to indicate whether `func` should be invoked on the
	 * leading and/or trailing edge of the `wait` timeout. The `func` is invoked
	 * with the last arguments provided to the debounced function. Subsequent
	 * calls to the debounced function return the result of the last `func`
	 * invocation.
	 *
	 * **Note:** If `leading` and `trailing` options are `true`, `func` is
	 * invoked on the trailing edge of the timeout only if the debounced function
	 * is invoked more than once during the `wait` timeout.
	 *
	 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
	 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
	 *
	 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
	 * for details over the differences between `_.debounce` and `_.throttle`.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Function
	 * @param {Function} func The function to debounce.
	 * @param {number} [wait=0] The number of milliseconds to delay.
	 * @param {Object} [options={}] The options object.
	 * @param {boolean} [options.leading=false]
	 *  Specify invoking on the leading edge of the timeout.
	 * @param {number} [options.maxWait]
	 *  The maximum time `func` is allowed to be delayed before it's invoked.
	 * @param {boolean} [options.trailing=true]
	 *  Specify invoking on the trailing edge of the timeout.
	 * @returns {Function} Returns the new debounced function.
	 * @example
	 *
	 * // Avoid costly calculations while the window size is in flux.
	 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
	 *
	 * // Invoke `sendMail` when clicked, debouncing subsequent calls.
	 * jQuery(element).on('click', _.debounce(sendMail, 300, {
	 *   'leading': true,
	 *   'trailing': false
	 * }));
	 *
	 * // Ensure `batchLog` is invoked once after 1 second of debounced calls.
	 * var debounced = _.debounce(batchLog, 250, { 'maxWait': 1000 });
	 * var source = new EventSource('/stream');
	 * jQuery(source).on('message', debounced);
	 *
	 * // Cancel the trailing debounced invocation.
	 * jQuery(window).on('popstate', debounced.cancel);
	 */
	function debounce$1(func, wait, options) {
	  var lastArgs,
	      lastThis,
	      maxWait,
	      result,
	      timerId,
	      lastCallTime,
	      lastInvokeTime = 0,
	      leading = false,
	      maxing = false,
	      trailing = true;

	  if (typeof func != 'function') {
	    throw new TypeError(FUNC_ERROR_TEXT$1);
	  }
	  wait = toNumber_1$1(wait) || 0;
	  if (isObject_1$1(options)) {
	    leading = !!options.leading;
	    maxing = 'maxWait' in options;
	    maxWait = maxing ? nativeMax$2(toNumber_1$1(options.maxWait) || 0, wait) : maxWait;
	    trailing = 'trailing' in options ? !!options.trailing : trailing;
	  }

	  function invokeFunc(time) {
	    var args = lastArgs,
	        thisArg = lastThis;

	    lastArgs = lastThis = undefined;
	    lastInvokeTime = time;
	    result = func.apply(thisArg, args);
	    return result;
	  }

	  function leadingEdge(time) {
	    // Reset any `maxWait` timer.
	    lastInvokeTime = time;
	    // Start the timer for the trailing edge.
	    timerId = setTimeout(timerExpired, wait);
	    // Invoke the leading edge.
	    return leading ? invokeFunc(time) : result;
	  }

	  function remainingWait(time) {
	    var timeSinceLastCall = time - lastCallTime,
	        timeSinceLastInvoke = time - lastInvokeTime,
	        timeWaiting = wait - timeSinceLastCall;

	    return maxing ? nativeMin$1(timeWaiting, maxWait - timeSinceLastInvoke) : timeWaiting;
	  }

	  function shouldInvoke(time) {
	    var timeSinceLastCall = time - lastCallTime,
	        timeSinceLastInvoke = time - lastInvokeTime;

	    // Either this is the first call, activity has stopped and we're at the
	    // trailing edge, the system time has gone backwards and we're treating
	    // it as the trailing edge, or we've hit the `maxWait` limit.
	    return lastCallTime === undefined || timeSinceLastCall >= wait || timeSinceLastCall < 0 || maxing && timeSinceLastInvoke >= maxWait;
	  }

	  function timerExpired() {
	    var time = now_1$1();
	    if (shouldInvoke(time)) {
	      return trailingEdge(time);
	    }
	    // Restart the timer.
	    timerId = setTimeout(timerExpired, remainingWait(time));
	  }

	  function trailingEdge(time) {
	    timerId = undefined;

	    // Only invoke if we have `lastArgs` which means `func` has been
	    // debounced at least once.
	    if (trailing && lastArgs) {
	      return invokeFunc(time);
	    }
	    lastArgs = lastThis = undefined;
	    return result;
	  }

	  function cancel() {
	    if (timerId !== undefined) {
	      clearTimeout(timerId);
	    }
	    lastInvokeTime = 0;
	    lastArgs = lastCallTime = lastThis = timerId = undefined;
	  }

	  function flush() {
	    return timerId === undefined ? result : trailingEdge(now_1$1());
	  }

	  function debounced() {
	    var time = now_1$1(),
	        isInvoking = shouldInvoke(time);

	    lastArgs = arguments;
	    lastThis = this;
	    lastCallTime = time;

	    if (isInvoking) {
	      if (timerId === undefined) {
	        return leadingEdge(lastCallTime);
	      }
	      if (maxing) {
	        // Handle invocations in a tight loop.
	        timerId = setTimeout(timerExpired, wait);
	        return invokeFunc(lastCallTime);
	      }
	    }
	    if (timerId === undefined) {
	      timerId = setTimeout(timerExpired, wait);
	    }
	    return result;
	  }
	  debounced.cancel = cancel;
	  debounced.flush = flush;
	  return debounced;
	}

	var debounce_1$1 = debounce$1;

	/** Error message constants. */
	var FUNC_ERROR_TEXT$2 = 'Expected a function';

	/**
	 * Creates a throttled function that only invokes `func` at most once per
	 * every `wait` milliseconds. The throttled function comes with a `cancel`
	 * method to cancel delayed `func` invocations and a `flush` method to
	 * immediately invoke them. Provide `options` to indicate whether `func`
	 * should be invoked on the leading and/or trailing edge of the `wait`
	 * timeout. The `func` is invoked with the last arguments provided to the
	 * throttled function. Subsequent calls to the throttled function return the
	 * result of the last `func` invocation.
	 *
	 * **Note:** If `leading` and `trailing` options are `true`, `func` is
	 * invoked on the trailing edge of the timeout only if the throttled function
	 * is invoked more than once during the `wait` timeout.
	 *
	 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
	 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
	 *
	 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
	 * for details over the differences between `_.throttle` and `_.debounce`.
	 *
	 * @static
	 * @memberOf _
	 * @since 0.1.0
	 * @category Function
	 * @param {Function} func The function to throttle.
	 * @param {number} [wait=0] The number of milliseconds to throttle invocations to.
	 * @param {Object} [options={}] The options object.
	 * @param {boolean} [options.leading=true]
	 *  Specify invoking on the leading edge of the timeout.
	 * @param {boolean} [options.trailing=true]
	 *  Specify invoking on the trailing edge of the timeout.
	 * @returns {Function} Returns the new throttled function.
	 * @example
	 *
	 * // Avoid excessively updating the position while scrolling.
	 * jQuery(window).on('scroll', _.throttle(updatePosition, 100));
	 *
	 * // Invoke `renewToken` when the click event is fired, but not more than once every 5 minutes.
	 * var throttled = _.throttle(renewToken, 300000, { 'trailing': false });
	 * jQuery(element).on('click', throttled);
	 *
	 * // Cancel the trailing throttled invocation.
	 * jQuery(window).on('popstate', throttled.cancel);
	 */
	function throttle$1(func, wait, options) {
	  var leading = true,
	      trailing = true;

	  if (typeof func != 'function') {
	    throw new TypeError(FUNC_ERROR_TEXT$2);
	  }
	  if (isObject_1$1(options)) {
	    leading = 'leading' in options ? !!options.leading : leading;
	    trailing = 'trailing' in options ? !!options.trailing : trailing;
	  }
	  return debounce_1$1(func, wait, {
	    'leading': leading,
	    'maxWait': wait,
	    'trailing': trailing
	  });
	}

	var throttle_1 = throttle$1;

	var _createClass$l = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$l(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var Stage = function () {
		function Stage(_options) {
			_classCallCheck$l(this, Stage);

			this.settings = _options || {};
			this.id = "epubjs-container-" + uuid();

			this.container = this.create(this.settings);

			if (this.settings.hidden) {
				this.wrapper = this.wrap(this.container);
			}
		}

		/*
	 * Creates an element to render to.
	 * Resizes to passed width and height or to the elements size
	 */


		_createClass$l(Stage, [{
			key: "create",
			value: function create(options) {
				var height = options.height; // !== false ? options.height : "100%";
				var width = options.width; // !== false ? options.width : "100%";
				var overflow = options.overflow || false;
				var axis = options.axis || "vertical";
				var direction = options.direction;
				var scale = options.scale || 1.0;

				if (options.height && isNumber(options.height)) {
					height = options.height + "px";
				}

				if (options.width && isNumber(options.width)) {
					width = options.width + "px";
				}

				// Create new container element
				var container = document.createElement("div");

				container.id = this.id;
				container.classList.add("epub-container");

				// Style Element
				// container.style.fontSize = "0";
				container.style.wordSpacing = "0";
				container.style.lineHeight = "0";
				container.style.verticalAlign = "top";
				container.style.position = "relative";

				if (axis === "horizontal") {
					// container.style.whiteSpace = "nowrap";
					container.style.display = "flex";
					container.style.flexDirection = "row";
					container.style.flexWrap = "nowrap";
				}

				if (width) {
					container.style.width = width;
				}

				if (height) {
					container.style.height = height;
				}

				if (overflow) {
					container.style.overflow = overflow;
				}

				if (direction) {
					container.dir = direction;
					container.style["direction"] = direction;
				}

				if (direction && this.settings.fullsize) {
					document.body.style["direction"] = direction;
				}

				if (scale && scale != 1.0) {
					container.style["transform-origin"] = "top left";
					container.style["transform"] = "scale(" + scale + ")";
					container.style.overflow = "auto"; // "visible" breaks something?
				} else {
					container.style["transform-origin"] = null;
					container.style["transform"] = null;
				}

				return container;
			}
		}, {
			key: "wrap",
			value: function wrap(container) {
				var wrapper = document.createElement("div");

				wrapper.style.visibility = "hidden";
				wrapper.style.overflow = "hidden";
				wrapper.style.width = "0";
				wrapper.style.height = "0";

				wrapper.appendChild(container);
				return wrapper;
			}
		}, {
			key: "getElement",
			value: function getElement(_element) {
				var element;

				if (isElement(_element)) {
					element = _element;
				} else if (typeof _element === "string") {
					element = document.getElementById(_element);
				}

				if (!element) {
					throw new Error("Not an Element");
				}

				return element;
			}
		}, {
			key: "attachTo",
			value: function attachTo(what) {

				var element = this.getElement(what);
				var base;

				if (!element) {
					return;
				}

				if (this.settings.hidden) {
					base = this.wrapper;
				} else {
					base = this.container;
				}

				element.appendChild(base);

				this.element = element;

				return element;
			}
		}, {
			key: "getContainer",
			value: function getContainer() {
				return this.container;
			}
		}, {
			key: "onResize",
			value: function onResize(func) {
				// Only listen to window for resize event if width and height are not fixed.
				// This applies if it is set to a percent or auto.
				if (!isNumber(this.settings.width) || !isNumber(this.settings.height)) {
					this.resizeFunc = throttle_1(func, 50);
					window.addEventListener("resize", this.resizeFunc, false);
				}
			}
		}, {
			key: "onOrientationChange",
			value: function onOrientationChange(func) {
				this.orientationChangeFunc = func;
				window.addEventListener("orientationchange", this.orientationChangeFunc, false);
			}
		}, {
			key: "size",
			value: function size(width, height) {
				var bounds;
				var _width = width || this.settings.width;
				var _height = height || this.settings.height;

				// If width or height are set to false, inherit them from containing element
				if (width === null) {
					bounds = this.element.getBoundingClientRect();

					if (bounds.width) {
						width = Math.floor(bounds.width);
						this.container.style.width = width + "px";
					}
				} else {
					if (isNumber(width)) {
						this.container.style.width = width + "px";
					} else {
						this.container.style.width = width;
					}
				}

				if (height === null) {
					bounds = bounds || this.element.getBoundingClientRect();

					if (bounds.height) {
						height = bounds.height;
						this.container.style.height = height + "px";
					}
				} else {
					if (isNumber(height)) {
						this.container.style.height = height + "px";
					} else {
						this.container.style.height = height;
					}
				}

				var _round = function _round(value) {
					return Math.round(value);

					// -- this calculates the closest even number to value
					var retval = 2 * Math.round(value / 2);
					if (retval > value) {
						retval -= 2;
					}
					return retval;
				};

				if (!isNumber(width)) {
					bounds = this.container.getBoundingClientRect();
					width = _round(bounds.width); // Math.floor(bounds.width);
					//height = bounds.height;
				}

				if (!isNumber(height)) {
					bounds = bounds || this.container.getBoundingClientRect();
					//width = bounds.width;
					height = _round(bounds.height); // bounds.height;
				}

				this.containerStyles = window.getComputedStyle(this.container);

				this.containerPadding = {
					left: parseFloat(this.containerStyles["padding-left"]) || 0,
					right: parseFloat(this.containerStyles["padding-right"]) || 0,
					top: parseFloat(this.containerStyles["padding-top"]) || 0,
					bottom: parseFloat(this.containerStyles["padding-bottom"]) || 0
				};

				// Bounds not set, get them from window
				var _windowBounds = windowBounds();
				var bodyStyles = window.getComputedStyle(document.body);
				var bodyPadding = {
					left: parseFloat(bodyStyles["padding-left"]) || 0,
					right: parseFloat(bodyStyles["padding-right"]) || 0,
					top: parseFloat(bodyStyles["padding-top"]) || 0,
					bottom: parseFloat(bodyStyles["padding-bottom"]) || 0
				};

				if (!_width) {
					width = _windowBounds.width - bodyPadding.left - bodyPadding.right;
				}

				if (this.settings.fullsize && !_height || !_height) {
					height = _windowBounds.height - bodyPadding.top - bodyPadding.bottom;
				}

				if (this.settings.scale) {
					width /= this.settings.scale;
					height /= this.settings.scale;
				}

				return {
					width: width - this.containerPadding.left - this.containerPadding.right,
					height: height - this.containerPadding.top - this.containerPadding.bottom
				};
			}
		}, {
			key: "bounds",
			value: function bounds() {
				var box = void 0;
				if (this.container.style.overflow !== "visible") {
					box = this.container && this.container.getBoundingClientRect();
				}

				if (!box || !box.width || !box.height) {
					return windowBounds();
				} else {
					return box;
				}
			}
		}, {
			key: "getSheet",
			value: function getSheet() {
				var style = document.createElement("style");

				// WebKit hack --> https://davidwalsh.name/add-rules-stylesheets
				style.appendChild(document.createTextNode(""));

				document.head.appendChild(style);

				return style.sheet;
			}
		}, {
			key: "addStyleRules",
			value: function addStyleRules(selector, rulesArray) {
				var scope = "#" + this.id + " ";
				var rules = "";

				if (!this.sheet) {
					this.sheet = this.getSheet();
				}

				rulesArray.forEach(function (set) {
					for (var prop in set) {
						if (set.hasOwnProperty(prop)) {
							rules += prop + ":" + set[prop] + ";";
						}
					}
				});

				this.sheet.insertRule(scope + selector + " {" + rules + "}", 0);
			}
		}, {
			key: "axis",
			value: function axis(_axis) {
				if (_axis === "horizontal") {
					this.container.style.display = "flex";
					this.container.style.flexDirection = "row";
					this.container.style.flexWrap = "nowrap";
				} else {
					this.container.style.display = "block";
				}
			}

			// orientation(orientation) {
			// 	if (orientation === "landscape") {
			//
			// 	} else {
			//
			// 	}
			//
			// 	this.orientation = orientation;
			// }

		}, {
			key: "direction",
			value: function direction(dir) {
				if (this.container) {
					this.container.dir = dir;
					this.container.style["direction"] = dir;
				}

				if (this.settings.fullsize) {
					document.body.style["direction"] = dir;
				}
			}
		}, {
			key: "overflow",
			value: function overflow(_overflow) {
				if (this.container) {
					this.container.style["overflow"] = _overflow;
				}
			}
		}, {
			key: "scale",
			value: function scale(s) {
				if (this.container) {
					if (s != 1.0) {
						this._originalOverflow = this.container.style.overflow;
						this.container.style["transform-origin"] = "top left";
						this.container.style["transform"] = "scale(" + s + ")";
						this.container.style.overflow = "auto"; // "visible"
					} else {
						this.container.style.overflow = this._originalOverflow;
						this.container.style["transform-origin"] = null;
						this.container.style["transform"] = null;
					}
					this.settings.scale = s;
				}
			}
		}, {
			key: "destroy",
			value: function destroy() {
				var base;

				if (this.element) {

					if (this.settings.hidden) {
						base = this.wrapper;
					} else {
						base = this.container;
					}

					if (this.element.contains(this.container)) {
						this.element.removeChild(this.container);
					}

					window.removeEventListener("resize", this.resizeFunc);
					window.removeEventListener("orientationChange", this.orientationChangeFunc);
				}
			}
		}]);

		return Stage;
	}();

	var _createClass$m = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$m(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var Views = function () {
		function Views(container) {
			_classCallCheck$m(this, Views);

			this.container = container;
			this._views = [];
			this.length = 0;
			this.hidden = false;
		}

		_createClass$m(Views, [{
			key: "all",
			value: function all() {
				return this._views;
			}
		}, {
			key: "first",
			value: function first() {
				return this._views[0];
			}
		}, {
			key: "last",
			value: function last() {
				return this._views[this._views.length - 1];
			}
		}, {
			key: "indexOf",
			value: function indexOf(view) {
				return this._views.indexOf(view);
			}
		}, {
			key: "slice",
			value: function slice() {
				return this._views.slice.apply(this._views, arguments);
			}
		}, {
			key: "get",
			value: function get(i) {
				return this._views[i];
			}
		}, {
			key: "append",
			value: function append(view) {
				this._views.push(view);
				if (this.container) {
					this.container.appendChild(view.element);
				}
				this.length++;
				return view;
			}
		}, {
			key: "prepend",
			value: function prepend(view) {
				this._views.unshift(view);
				if (this.container) {
					this.container.insertBefore(view.element, this.container.firstChild);
				}
				this.length++;
				return view;
			}
		}, {
			key: "insert",
			value: function insert(view, index) {
				this._views.splice(index, 0, view);

				if (this.container) {
					if (index < this.container.children.length) {
						this.container.insertBefore(view.element, this.container.children[index]);
					} else {
						this.container.appendChild(view.element);
					}
				}

				this.length++;
				return view;
			}
		}, {
			key: "remove",
			value: function remove(view) {
				var index = this._views.indexOf(view);

				if (index > -1) {
					this._views.splice(index, 1);
				}

				this.destroy(view);

				this.length--;
			}
		}, {
			key: "destroy",
			value: function destroy(view) {
				if (view.displayed) {
					view.destroy();
				}

				if (this.container) {
					this.container.removeChild(view.element);
				}
				view = null;
			}

			// Iterators

		}, {
			key: "forEach",
			value: function forEach() {
				return this._views.forEach.apply(this._views, arguments);
			}
		}, {
			key: "clear",
			value: function clear() {
				// Remove all views
				var view;
				var len = this.length;

				if (!this.length) return;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					this.destroy(view);
				}

				this._views = [];
				this.length = 0;
			}
		}, {
			key: "find",
			value: function find(section) {

				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed && view.section.index == section.index) {
						return view;
					}
				}
			}
		}, {
			key: "displayed",
			value: function displayed() {
				var displayed = [];
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						displayed.push(view);
					}
				}
				return displayed;
			}
		}, {
			key: "show",
			value: function show() {
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						view.show();
					}
				}
				this.hidden = false;
			}
		}, {
			key: "hide",
			value: function hide() {
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						view.hide();
					}
				}
				this.hidden = true;
			}
		}]);

		return Views;
	}();

	var _createClass$n = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$n(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var DefaultViewManager = function () {
		function DefaultViewManager(options) {
			_classCallCheck$n(this, DefaultViewManager);

			this.name = "default";
			this.optsSettings = options.settings;
			this.View = options.view;
			this.request = options.request;
			this.renditionQueue = options.queue;
			this.q = new Queue(this);

			this.settings = extend$1(this.settings || {}, {
				infinite: true,
				hidden: false,
				width: undefined,
				height: undefined,
				axis: undefined,
				flow: "scrolled",
				ignoreClass: "",
				fullsize: undefined
			});

			extend$1(this.settings, options.settings || {});

			this.viewSettings = {
				ignoreClass: this.settings.ignoreClass,
				axis: this.settings.axis,
				flow: this.settings.flow,
				layout: this.layout,
				method: this.settings.method, // srcdoc, blobUrl, write
				width: 0,
				height: 0,
				forceEvenPages: true
			};

			this.rendered = false;
		}

		_createClass$n(DefaultViewManager, [{
			key: "render",
			value: function render(element, size) {
				var tag = element.tagName;

				if (typeof this.settings.fullsize === "undefined" && tag && (tag.toLowerCase() == "body" || tag.toLowerCase() == "html")) {
					this.settings.fullsize = true;
				}

				if (this.settings.fullsize) {
					this.settings.overflow = "visible";
					this.overflow = this.settings.overflow;
				}

				this.settings.size = size;

				// Save the stage
				this.stage = new Stage({
					width: size.width,
					height: size.height,
					overflow: this.overflow,
					hidden: this.settings.hidden,
					axis: this.settings.axis,
					fullsize: this.settings.fullsize,
					direction: this.settings.direction,
					scale: this.settings.scale
				});

				this.stage.attachTo(element);

				// Get this stage container div
				this.container = this.stage.getContainer();

				// Views array methods
				this.views = new Views(this.container);

				// Calculate Stage Size
				this._bounds = this.bounds();
				this._stageSize = this.stage.size();

				// Set the dimensions for views
				this.viewSettings.width = this._stageSize.width;
				this.viewSettings.height = this._stageSize.height;

				// Function to handle a resize event.
				// Will only attach if width and height are both fixed.
				this.stage.onResize(this.onResized.bind(this));

				this.stage.onOrientationChange(this.onOrientationChange.bind(this));

				// Add Event Listeners
				this.addEventListeners();

				// Add Layout method
				// this.applyLayoutMethod();
				if (this.layout) {
					this.updateLayout();
				}

				this.rendered = true;
			}
		}, {
			key: "addEventListeners",
			value: function addEventListeners() {
				var scroller;

				window.addEventListener("unload", function (e) {
					this.destroy();
				}.bind(this));

				if (!this.settings.fullsize) {
					scroller = this.container;
				} else {
					scroller = window;
				}

				this._onScroll = this.onScroll.bind(this);
				scroller.addEventListener("scroll", this._onScroll);
			}
		}, {
			key: "removeEventListeners",
			value: function removeEventListeners() {
				var scroller;

				if (!this.settings.fullsize) {
					scroller = this.container;
				} else {
					scroller = window;
				}

				scroller.removeEventListener("scroll", this._onScroll);
				this._onScroll = undefined;
			}
		}, {
			key: "destroy",
			value: function destroy() {
				clearTimeout(this.orientationTimeout);
				clearTimeout(this.resizeTimeout);
				clearTimeout(this.afterScrolled);

				this.clear();

				this.removeEventListeners();

				this.stage.destroy();

				this.rendered = false;

				/*
	   		clearTimeout(this.trimTimeout);
	   	if(this.settings.hidden) {
	   		this.element.removeChild(this.wrapper);
	   	} else {
	   		this.element.removeChild(this.container);
	   	}
	   */
			}
		}, {
			key: "onOrientationChange",
			value: function onOrientationChange(e) {
				var _window = window,
				    orientation = _window.orientation;


				if (this.optsSettings.resizeOnOrientationChange) {
					this.resize();
				}

				// Per ampproject:
				// In IOS 10.3, the measured size of an element is incorrect if the
				// element size depends on window size directly and the measurement
				// happens in window.resize event. Adding a timeout for correct
				// measurement. See https://github.com/ampproject/amphtml/issues/8479
				clearTimeout(this.orientationTimeout);
				this.orientationTimeout = setTimeout(function () {
					this.orientationTimeout = undefined;

					if (this.optsSettings.resizeOnOrientationChange) {
						this.resize();
					}

					this.emit(EVENTS.MANAGERS.ORIENTATION_CHANGE, orientation);
				}.bind(this), 500);
			}
		}, {
			key: "onResized",
			value: function onResized(e) {
				this.resize();
			}
		}, {
			key: "resize",
			value: function resize(width, height) {
				var stageSize = this.stage.size(width, height);

				// For Safari, wait for orientation to catch up
				// if the window is a square
				this.winBounds = windowBounds();
				if (this.orientationTimeout && this.winBounds.width === this.winBounds.height) {
					// reset the stage size for next resize
					this._stageSize = undefined;
					return;
				}

				if (this._stageSize && this._stageSize.width === stageSize.width && this._stageSize.height === stageSize.height) {
					// Size is the same, no need to resize
					return;
				}

				this._stageSize = stageSize;

				this._bounds = this.bounds();

				// Clear current views
				this.clear();

				// Update for new views
				this.viewSettings.width = this._stageSize.width;
				this.viewSettings.height = this._stageSize.height;

				this.updateLayout();

				this.emit(EVENTS.MANAGERS.RESIZED, {
					width: this._stageSize.width,
					height: this._stageSize.height
				});
			}
		}, {
			key: "createView",
			value: function createView(section) {
				return new this.View(section, this.viewSettings);
			}
		}, {
			key: "display",
			value: function display(section, target) {

				var displaying = new defer();
				var displayed = displaying.promise;

				// Check if moving to target is needed
				if (target === section.href || isNumber(target)) {
					target = undefined;
				}

				// Check to make sure the section we want isn't already shown
				var visible = this.views.find(section);

				// View is already shown, just move to correct location in view
				if (visible && section) {
					var offset = visible.offset();

					if (this.settings.direction === "ltr") {
						this.scrollTo(offset.left, offset.top, true);
					} else {
						var width = visible.width();
						this.scrollTo(offset.left + width, offset.top, true);
					}

					if (target) {
						var _offset = visible.locationOf(target);
						this.moveTo(_offset);
					}

					displaying.resolve();
					return displayed;
				}

				// Hide all current views
				this.clear();

				this.add(section).then(function (view) {

					// Move to correct place within the section, if needed
					if (target) {
						var _offset2 = view.locationOf(target);
						this.moveTo(_offset2);
					}
				}.bind(this), function (err) {
					displaying.reject(err);
				}).then(function () {
					var next;
					if (this.layout.name === "pre-paginated" && this.layout.divisor > 1 && section.index > 0) {
						// First page (cover) should stand alone for pre-paginated books
						next = section.next();
						if (next) {
							return this.add(next);
						}
					}
				}.bind(this)).then(function () {

					this.views.show();

					displaying.resolve();
				}.bind(this));
				// .then(function(){
				// 	return this.hooks.display.trigger(view);
				// }.bind(this))
				// .then(function(){
				// 	this.views.show();
				// }.bind(this));
				return displayed;
			}
		}, {
			key: "afterDisplayed",
			value: function afterDisplayed(view) {
				this.emit(EVENTS.MANAGERS.ADDED, view);
			}
		}, {
			key: "afterResized",
			value: function afterResized(view) {
				this.emit(EVENTS.MANAGERS.RESIZE, view.section);
			}
		}, {
			key: "moveTo",
			value: function moveTo(offset) {
				var distX = 0,
				    distY = 0;

				if (!this.isPaginated) {
					distY = offset.top;
				} else {
					distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;

					if (distX + this.layout.delta > this.container.scrollWidth) {
						distX = this.container.scrollWidth - this.layout.delta;
					}
				}
				this.scrollTo(distX, distY, true);
			}
		}, {
			key: "add",
			value: function add(section) {
				var _this = this;

				var view = this.createView(section);

				this.views.append(view);

				// view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));
				view.onDisplayed = this.afterDisplayed.bind(this);
				view.onResize = this.afterResized.bind(this);

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this.updateAxis(axis);
				});

				return view.display(this.request);
			}
		}, {
			key: "append",
			value: function append(section) {
				var _this2 = this;

				var view = this.createView(section);
				this.views.append(view);

				view.onDisplayed = this.afterDisplayed.bind(this);
				view.onResize = this.afterResized.bind(this);

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this2.updateAxis(axis);
				});

				return view.display(this.request);
			}
		}, {
			key: "prepend",
			value: function prepend(section) {
				var _this3 = this;

				var view = this.createView(section);

				view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
					_this3.counter(bounds);
				});

				this.views.prepend(view);

				view.onDisplayed = this.afterDisplayed.bind(this);
				view.onResize = this.afterResized.bind(this);

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this3.updateAxis(axis);
				});

				return view.display(this.request);
			}
		}, {
			key: "counter",
			value: function counter(bounds) {
				if (this.settings.axis === "vertical") {
					this.scrollBy(0, bounds.heightDelta, true);
				} else {
					this.scrollBy(bounds.widthDelta, 0, true);
				}
			}

			// resizeView(view) {
			//
			// 	if(this.settings.globalLayoutProperties.layout === "pre-paginated") {
			// 		view.lock("both", this.bounds.width, this.bounds.height);
			// 	} else {
			// 		view.lock("width", this.bounds.width, this.bounds.height);
			// 	}
			//
			// };

		}, {
			key: "next",
			value: function next() {
				var next;
				var left;

				var dir = this.settings.direction;

				if (!this.views.length) return;

				if (this.isPaginated && this.settings.axis === "horizontal" && (!dir || dir === "ltr")) {

					this.scrollLeft = this.container.scrollLeft;

					left = this.container.scrollLeft + this.container.offsetWidth + this.layout.delta;

					if (left <= this.container.scrollWidth) {
						this.scrollBy(this.layout.delta, 0, true);
					} else {
						next = this.views.last().section.next();
					}
				} else if (this.isPaginated && this.settings.axis === "horizontal" && dir === "rtl") {

					this.scrollLeft = this.container.scrollLeft;

					left = this.container.scrollLeft;

					if (left > 0) {
						this.scrollBy(this.layout.delta, 0, true);
					} else {
						next = this.views.last().section.next();
					}
				} else if (this.isPaginated && this.settings.axis === "vertical") {

					this.scrollTop = this.container.scrollTop;

					var top = this.container.scrollTop + this.container.offsetHeight;

					if (top < this.container.scrollHeight) {
						this.scrollBy(0, this.layout.height, true);
					} else {
						next = this.views.last().section.next();
					}
				} else {
					next = this.views.last().section.next();
				}

				if (next) {
					this.clear();

					return this.append(next).then(function () {
						var right;
						if (this.layout.name === "pre-paginated" && this.layout.divisor > 1) {
							right = next.next();
							if (right) {
								return this.append(right);
							}
						}
					}.bind(this), function (err) {
						return err;
					}).then(function () {
						this.views.show();
					}.bind(this));
				}
			}
		}, {
			key: "prev",
			value: function prev() {
				var prev;
				var left;
				var dir = this.settings.direction;

				if (!this.views.length) return;

				if (this.isPaginated && this.settings.axis === "horizontal" && (!dir || dir === "ltr")) {

					this.scrollLeft = this.container.scrollLeft;

					left = this.container.scrollLeft;

					if (left > 0) {
						this.scrollBy(-this.layout.delta, 0, true);
					} else {
						prev = this.views.first().section.prev();
					}
				} else if (this.isPaginated && this.settings.axis === "horizontal" && dir === "rtl") {

					this.scrollLeft = this.container.scrollLeft;

					left = this.container.scrollLeft + this.container.offsetWidth + this.layout.delta;

					if (left <= this.container.scrollWidth) {
						this.scrollBy(-this.layout.delta, 0, true);
					} else {
						prev = this.views.first().section.prev();
					}
				} else if (this.isPaginated && this.settings.axis === "vertical") {

					this.scrollTop = this.container.scrollTop;

					var top = this.container.scrollTop;

					if (top > 0) {
						this.scrollBy(0, -this.layout.height, true);
					} else {
						prev = this.views.first().section.prev();
					}
				} else {

					prev = this.views.first().section.prev();
				}

				if (prev) {
					this.clear();

					return this.prepend(prev).then(function () {
						var left;
						if (this.layout.name === "pre-paginated" && this.layout.divisor > 1) {
							left = prev.prev();
							if (left) {
								return this.prepend(left);
							}
						}
					}.bind(this), function (err) {
						return err;
					}).then(function () {
						if (this.isPaginated && this.settings.axis === "horizontal") {
							if (this.settings.direction === "rtl") {
								this.scrollTo(0, 0, true);
							} else {
								this.scrollTo(this.container.scrollWidth - this.layout.delta, 0, true);
							}
						}
						this.views.show();
					}.bind(this));
				}
			}
		}, {
			key: "current",
			value: function current() {
				var visible = this.visible();
				if (visible.length) {
					// Current is the last visible view
					return visible[visible.length - 1];
				}
				return null;
			}
		}, {
			key: "clear",
			value: function clear() {

				// this.q.clear();

				if (this.views) {
					this.views.hide();
					this.scrollTo(0, 0, true);
					this.views.clear();
				}
			}
		}, {
			key: "currentLocation",
			value: function currentLocation() {

				if (this.settings.axis === "vertical") {
					this.location = this.scrolledLocation();
				} else {
					this.location = this.paginatedLocation();
				}
				return this.location;
			}
		}, {
			key: "scrolledLocation",
			value: function scrolledLocation() {
				var _this4 = this;

				var visible = this.visible();
				var container = this.container.getBoundingClientRect();
				var pageHeight = container.height < window.innerHeight ? container.height : window.innerHeight;

				var offset = 0;
				var used = 0;

				if (this.settings.fullsize) {
					offset = window.scrollY;
				}

				var sections = visible.map(function (view) {
					var _view$section = view.section,
					    index = _view$section.index,
					    href = _view$section.href;

					var position = view.position();
					var height = view.height();

					var startPos = offset + container.top - position.top + used;
					var endPos = startPos + pageHeight - used;
					if (endPos > height) {
						endPos = height;
						used = endPos - startPos;
					}

					var totalPages = _this4.layout.count(height, pageHeight).pages;

					var currPage = Math.ceil(startPos / pageHeight);
					var pages = [];
					var endPage = Math.ceil(endPos / pageHeight);

					pages = [];
					for (var i = currPage; i <= endPage; i++) {
						var pg = i + 1;
						pages.push(pg);
					}

					var mapping = _this4.mapping.page(view.contents, view.section.cfiBase, startPos, endPos);

					return {
						index: index,
						href: href,
						pages: pages,
						totalPages: totalPages,
						mapping: mapping
					};
				});

				return sections;
			}
		}, {
			key: "paginatedLocation",
			value: function paginatedLocation() {
				var _this5 = this;

				var visible = this.visible();
				var container = this.container.getBoundingClientRect();

				var left = 0;
				var used = 0;

				if (this.settings.fullsize) {
					left = window.scrollX;
				}

				var sections = visible.map(function (view) {
					var _view$section2 = view.section,
					    index = _view$section2.index,
					    href = _view$section2.href;

					var offset = view.offset().left;
					var position = view.position().left;
					var width = view.width();

					// Find mapping
					var start = left + container.left - position + used;
					var end = start + _this5.layout.width - used;

					var mapping = _this5.mapping.page(view.contents, view.section.cfiBase, start, end);

					// Find displayed pages
					//console.log("pre", end, offset + width);
					// if (end > offset + width) {
					// 	end = offset + width;
					// 	used = this.layout.pageWidth;
					// }
					// console.log("post", end);

					var totalPages = _this5.layout.count(width).pages;
					var startPage = Math.floor(start / _this5.layout.pageWidth);
					var pages = [];
					var endPage = Math.floor(end / _this5.layout.pageWidth);

					// start page should not be negative
					if (startPage < 0) {
						startPage = 0;
						endPage = endPage + 1;
					}

					// Reverse page counts for rtl
					if (_this5.settings.direction === "rtl") {
						var tempStartPage = startPage;
						startPage = totalPages - endPage;
						endPage = totalPages - tempStartPage;
					}

					for (var i = startPage + 1; i <= endPage; i++) {
						var pg = i;
						pages.push(pg);
					}

					return {
						index: index,
						href: href,
						pages: pages,
						totalPages: totalPages,
						mapping: mapping
					};
				});

				return sections;
			}
		}, {
			key: "isVisible",
			value: function isVisible(view, offsetPrev, offsetNext, _container) {
				var position = view.position();
				var container = _container || this.bounds();

				if (this.settings.axis === "horizontal" && position.right > container.left - offsetPrev && position.left < container.right + offsetNext) {

					return true;
				} else if (this.settings.axis === "vertical" && position.bottom > container.top - offsetPrev && position.top < container.bottom + offsetNext) {

					return true;
				}

				return false;
			}
		}, {
			key: "visible",
			value: function visible() {
				var container = this.bounds();
				var views = this.views.displayed();
				var viewsLength = views.length;
				var visible = [];
				var isVisible;
				var view;

				for (var i = 0; i < viewsLength; i++) {
					view = views[i];
					isVisible = this.isVisible(view, 0, 0, container);

					if (isVisible === true) {
						visible.push(view);
					}
				}
				return visible;
			}
		}, {
			key: "scrollBy",
			value: function scrollBy(x, y, silent) {
				var dir = this.settings.direction === "rtl" ? -1 : 1;

				if (silent) {
					this.ignore = true;
				}

				if (!this.settings.fullsize) {
					if (x) this.container.scrollLeft += x * dir;
					if (y) this.container.scrollTop += y;
				} else {
					window.scrollBy(x * dir, y * dir);
				}
				this.scrolled = true;
			}
		}, {
			key: "scrollTo",
			value: function scrollTo(x, y, silent) {
				if (silent) {
					this.ignore = true;
				}

				if (!this.settings.fullsize) {
					this.container.scrollLeft = x;
					this.container.scrollTop = y;
				} else {
					window.scrollTo(x, y);
				}
				this.scrolled = true;
			}
		}, {
			key: "onScroll",
			value: function onScroll() {
				var scrollTop = void 0;
				var scrollLeft = void 0;

				if (!this.settings.fullsize) {
					scrollTop = this.container.scrollTop;
					scrollLeft = this.container.scrollLeft;
				} else {
					scrollTop = window.scrollY;
					scrollLeft = window.scrollX;
				}

				this.scrollTop = scrollTop;
				this.scrollLeft = scrollLeft;

				if (!this.ignore) {
					this.emit(EVENTS.MANAGERS.SCROLL, {
						top: scrollTop,
						left: scrollLeft
					});

					clearTimeout(this.afterScrolled);
					this.afterScrolled = setTimeout(function () {
						this.emit(EVENTS.MANAGERS.SCROLLED, {
							top: this.scrollTop,
							left: this.scrollLeft
						});
					}.bind(this), 20);
				} else {
					this.ignore = false;
				}
			}
		}, {
			key: "bounds",
			value: function bounds() {
				var bounds;

				bounds = this.stage.bounds();

				return bounds;
			}
		}, {
			key: "applyLayout",
			value: function applyLayout(layout) {

				this.layout = layout;
				this.updateLayout();
				// this.manager.layout(this.layout.format);
			}
		}, {
			key: "updateLayout",
			value: function updateLayout() {

				if (!this.stage) {
					return;
				}

				this._stageSize = this.stage.size();

				if (!this.isPaginated) {
					this.layout.calculate(this._stageSize.width, this._stageSize.height);
				} else {
					this.layout.calculate(this._stageSize.width, this._stageSize.height, this.settings.gap);

					// Set the look ahead offset for what is visible
					this.settings.offset = this.layout.delta;

					// this.stage.addStyleRules("iframe", [{"margin-right" : this.layout.gap + "px"}]);
				}

				// Set the dimensions for views
				this.viewSettings.width = this.layout.width;
				this.viewSettings.height = this.layout.height;

				this.setLayout(this.layout);
			}
		}, {
			key: "setLayout",
			value: function setLayout(layout) {

				this.viewSettings.layout = layout;

				this.mapping = new Mapping(layout.props, this.settings.direction, this.settings.axis);

				if (this.views) {

					this.views.forEach(function (view) {
						if (view) {
							view.setLayout(layout);
						}
					});
				}
			}
		}, {
			key: "updateAxis",
			value: function updateAxis(axis, forceUpdate) {

				if (!this.isPaginated) {
					axis = "vertical";
				}

				if (!forceUpdate && axis === this.settings.axis) {
					return;
				}

				this.settings.axis = axis;

				this.stage && this.stage.axis(axis);

				this.viewSettings.axis = axis;

				if (this.mapping) {
					this.mapping = new Mapping(this.layout.props, this.settings.direction, this.settings.axis);
				}

				if (this.layout) {
					if (axis === "vertical") {
						this.layout.spread("none");
					} else {
						this.layout.spread(this.layout.settings.spread);
					}
				}
			}
		}, {
			key: "updateFlow",
			value: function updateFlow(flow) {
				var isPaginated = flow === "paginated" || flow === "auto";

				this.isPaginated = isPaginated;

				if (flow === "scrolled-doc" || flow === "scrolled-continuous" || flow === "scrolled") {
					this.updateAxis("vertical");
				} else {
					this.updateAxis("horizontal");
				}

				this.viewSettings.flow = flow;

				if (!this.settings.overflow) {
					this.overflow = isPaginated ? "hidden" : "auto";
				} else {
					this.overflow = this.settings.overflow;
				}

				this.stage && this.stage.overflow(this.overflow);

				this.updateLayout();
			}
		}, {
			key: "getContents",
			value: function getContents() {
				var contents = [];
				if (!this.views) {
					return contents;
				}
				this.views.forEach(function (view) {
					var viewContents = view && view.contents;
					if (viewContents) {
						contents.push(viewContents);
					}
				});
				return contents;
			}
		}, {
			key: "direction",
			value: function direction() {
				var dir = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : "ltr";

				this.settings.direction = dir;

				this.stage && this.stage.direction(dir);

				this.viewSettings.direction = dir;

				this.updateLayout();
			}
		}, {
			key: "isRendered",
			value: function isRendered() {
				return this.rendered;
			}
		}, {
			key: "scale",
			value: function scale(s) {
				if (s == null) {
					s = 1.0;
				}
				this.settings.scale = s;

				if (this.stage) {
					this.stage.scale(s);
				}
			}
		}]);

		return DefaultViewManager;
	}();

	//-- Enable binding events to Manager


	eventEmitter(DefaultViewManager.prototype);

	var _createClass$o = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$o(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	// easing equations from https://github.com/danro/easing-js/blob/master/easing.js
	var PI_D2 = Math.PI / 2;
	var EASING_EQUATIONS = {
		easeOutSine: function easeOutSine(pos) {
			return Math.sin(pos * PI_D2);
		},
		easeInOutSine: function easeInOutSine(pos) {
			return -0.5 * (Math.cos(Math.PI * pos) - 1);
		},
		easeInOutQuint: function easeInOutQuint(pos) {
			if ((pos /= 0.5) < 1) {
				return 0.5 * Math.pow(pos, 5);
			}
			return 0.5 * (Math.pow(pos - 2, 5) + 2);
		},
		easeInCubic: function easeInCubic(pos) {
			return Math.pow(pos, 3);
		}
	};

	var Snap = function () {
		function Snap(manager, options) {
			_classCallCheck$o(this, Snap);

			this.settings = extend$1({
				duration: 80,
				minVelocity: 0.2,
				minDistance: 10,
				easing: EASING_EQUATIONS['easeInCubic']
			}, options || {});

			this.supportsTouch = this.supportsTouch();

			if (this.supportsTouch) {
				this.setup(manager);
			}
		}

		_createClass$o(Snap, [{
			key: "setup",
			value: function setup(manager) {
				this.manager = manager;

				this.layout = this.manager.layout;

				this.fullsize = this.manager.settings.fullsize;
				if (this.fullsize) {
					this.element = this.manager.stage.element;
					this.scroller = window;
					this.disableScroll();
				} else {
					this.element = this.manager.stage.container;
					this.scroller = this.element;
					this.element.style["WebkitOverflowScrolling"] = "touch";
				}

				// this.overflow = this.manager.overflow;

				// set lookahead offset to page width
				this.manager.settings.offset = this.layout.width;
				this.manager.settings.afterScrolledTimeout = this.settings.duration * 2;

				this.isVertical = this.manager.settings.axis === "vertical";

				// disable snapping if not paginated or axis in not horizontal
				if (!this.manager.isPaginated || this.isVertical) {
					return;
				}

				this.touchCanceler = false;
				this.resizeCanceler = false;
				this.snapping = false;

				this.scrollLeft;
				this.scrollTop;

				this.startTouchX = undefined;
				this.startTouchY = undefined;
				this.startTime = undefined;
				this.endTouchX = undefined;
				this.endTouchY = undefined;
				this.endTime = undefined;

				this.addListeners();
			}
		}, {
			key: "supportsTouch",
			value: function supportsTouch() {
				if ('ontouchstart' in window || window.DocumentTouch && document instanceof DocumentTouch) {
					return true;
				}

				return false;
			}
		}, {
			key: "disableScroll",
			value: function disableScroll() {
				this.element.style.overflow = "hidden";
			}
		}, {
			key: "enableScroll",
			value: function enableScroll() {
				this.element.style.overflow = "";
			}
		}, {
			key: "addListeners",
			value: function addListeners() {
				this._onResize = this.onResize.bind(this);
				window.addEventListener('resize', this._onResize);

				this._onScroll = this.onScroll.bind(this);
				this.scroller.addEventListener('scroll', this._onScroll);

				this._onTouchStart = this.onTouchStart.bind(this);
				this.scroller.addEventListener('touchstart', this._onTouchStart, { passive: true });
				this.on('touchstart', this._onTouchStart);

				this._onTouchMove = this.onTouchMove.bind(this);
				this.scroller.addEventListener('touchmove', this._onTouchMove, { passive: true });
				this.on('touchmove', this._onTouchMove);

				this._onTouchEnd = this.onTouchEnd.bind(this);
				this.scroller.addEventListener('touchend', this._onTouchEnd, { passive: true });
				this.on('touchend', this._onTouchEnd);

				this._afterDisplayed = this.afterDisplayed.bind(this);
				this.manager.on(EVENTS.MANAGERS.ADDED, this._afterDisplayed);
			}
		}, {
			key: "removeListeners",
			value: function removeListeners() {
				window.removeEventListener('resize', this._onResize);
				this._onResize = undefined;

				this.scroller.removeEventListener('scroll', this._onScroll);
				this._onScroll = undefined;

				this.scroller.removeEventListener('touchstart', this._onTouchStart, { passive: true });
				this.off('touchstart', this._onTouchStart);
				this._onTouchStart = undefined;

				this.scroller.removeEventListener('touchmove', this._onTouchMove, { passive: true });
				this.off('touchmove', this._onTouchMove);
				this._onTouchMove = undefined;

				this.scroller.removeEventListener('touchend', this._onTouchEnd, { passive: true });
				this.off('touchend', this._onTouchEnd);
				this._onTouchEnd = undefined;

				this.manager.off(EVENTS.MANAGERS.ADDED, this._afterDisplayed);
				this._afterDisplayed = undefined;
			}
		}, {
			key: "afterDisplayed",
			value: function afterDisplayed(view) {
				var _this = this;

				var contents = view.contents;
				["touchstart", "touchmove", "touchend"].forEach(function (e) {
					contents.on(e, function (ev) {
						return _this.triggerViewEvent(ev, contents);
					});
				});
			}
		}, {
			key: "triggerViewEvent",
			value: function triggerViewEvent(e, contents) {
				this.emit(e.type, e, contents);
			}
		}, {
			key: "onScroll",
			value: function onScroll(e) {
				this.scrollLeft = this.fullsize ? window.scrollX : this.scroller.scrollLeft;
				this.scrollTop = this.fullsize ? window.scrollY : this.scroller.scrollTop;
			}
		}, {
			key: "onResize",
			value: function onResize(e) {
				this.resizeCanceler = true;
			}
		}, {
			key: "onTouchStart",
			value: function onTouchStart(e) {
				var _e$touches$ = e.touches[0],
				    screenX = _e$touches$.screenX,
				    screenY = _e$touches$.screenY;


				if (this.fullsize) {
					this.enableScroll();
				}

				this.touchCanceler = true;

				if (!this.startTouchX) {
					this.startTouchX = screenX;
					this.startTouchY = screenY;
					this.startTime = this.now();
				}

				this.endTouchX = screenX;
				this.endTouchY = screenY;
				this.endTime = this.now();
			}
		}, {
			key: "onTouchMove",
			value: function onTouchMove(e) {
				var _e$touches$2 = e.touches[0],
				    screenX = _e$touches$2.screenX,
				    screenY = _e$touches$2.screenY;

				var deltaY = Math.abs(screenY - this.endTouchY);

				this.touchCanceler = true;

				if (!this.fullsize && deltaY < 10) {
					this.element.scrollLeft -= screenX - this.endTouchX;
				}

				this.endTouchX = screenX;
				this.endTouchY = screenY;
				this.endTime = this.now();
			}
		}, {
			key: "onTouchEnd",
			value: function onTouchEnd(e) {
				if (this.fullsize) {
					this.disableScroll();
				}

				this.touchCanceler = false;

				var swipped = this.wasSwiped();

				if (swipped !== 0) {
					this.snap(swipped);
				} else {
					this.snap();
				}

				this.startTouchX = undefined;
				this.startTouchY = undefined;
				this.startTime = undefined;
				this.endTouchX = undefined;
				this.endTouchY = undefined;
				this.endTime = undefined;
			}
		}, {
			key: "wasSwiped",
			value: function wasSwiped() {
				var snapWidth = this.layout.pageWidth * this.layout.divisor;
				var distance = this.endTouchX - this.startTouchX;
				var absolute = Math.abs(distance);
				var time = this.endTime - this.startTime;
				var velocity = distance / time;
				var minVelocity = this.settings.minVelocity;

				if (absolute <= this.settings.minDistance || absolute >= snapWidth) {
					return 0;
				}

				if (velocity > minVelocity) {
					// previous
					return -1;
				} else if (velocity < -minVelocity) {
					// next
					return 1;
				}
			}
		}, {
			key: "needsSnap",
			value: function needsSnap() {
				var left = this.scrollLeft;
				var snapWidth = this.layout.pageWidth * this.layout.divisor;
				return left % snapWidth !== 0;
			}
		}, {
			key: "snap",
			value: function snap() {
				var howMany = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;

				var left = this.scrollLeft;
				var snapWidth = this.layout.pageWidth * this.layout.divisor;
				var snapTo = Math.round(left / snapWidth) * snapWidth;

				if (howMany) {
					snapTo += howMany * snapWidth;
				}

				return this.smoothScrollTo(snapTo);
			}
		}, {
			key: "smoothScrollTo",
			value: function smoothScrollTo(destination) {
				var deferred = new defer();
				var start = this.scrollLeft;
				var startTime = this.now();

				var duration = this.settings.duration;
				var easing = this.settings.easing;

				this.snapping = true;

				// add animation loop
				function tick() {
					var now = this.now();
					var time = Math.min(1, (now - startTime) / duration);
					var timeFunction = easing(time);

					if (this.touchCanceler || this.resizeCanceler) {
						this.resizeCanceler = false;
						this.snapping = false;
						deferred.resolve();
						return;
					}

					if (time < 1) {
						window.requestAnimationFrame(tick.bind(this));
						this.scrollTo(start + (destination - start) * time, 0);
					} else {
						this.scrollTo(destination, 0);
						this.snapping = false;
						deferred.resolve();
					}
				}

				tick.call(this);

				return deferred.promise;
			}
		}, {
			key: "scrollTo",
			value: function scrollTo() {
				var left = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
				var top = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;

				if (this.fullsize) {
					window.scroll(left, top);
				} else {
					this.scroller.scrollLeft = left;
					this.scroller.scrollTop = top;
				}
			}
		}, {
			key: "now",
			value: function now() {
				return 'now' in window.performance ? performance.now() : new Date().getTime();
			}
		}, {
			key: "destroy",
			value: function destroy() {
				if (!this.scroller) {
					return;
				}

				if (this.fullsize) {
					this.enableScroll();
				}

				this.removeListeners();

				this.scroller = undefined;
			}
		}]);

		return Snap;
	}();

	eventEmitter(Snap.prototype);

	var _typeof$c = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	var _createClass$p = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	var _get$1 = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

	function _classCallCheck$p(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn$1(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits$1(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var ContinuousViewManager = function (_DefaultViewManager) {
		_inherits$1(ContinuousViewManager, _DefaultViewManager);

		function ContinuousViewManager(options) {
			_classCallCheck$p(this, ContinuousViewManager);

			var _this = _possibleConstructorReturn$1(this, (ContinuousViewManager.__proto__ || Object.getPrototypeOf(ContinuousViewManager)).call(this, options));

			_this.name = "continuous";

			_this.settings = extend$1(_this.settings || {}, {
				infinite: true,
				overflow: undefined,
				axis: undefined,
				flow: "scrolled",
				offset: 500,
				offsetDelta: 250,
				width: undefined,
				height: undefined,
				snap: false,
				afterScrolledTimeout: 10
			});

			extend$1(_this.settings, options.settings || {});

			// Gap can be 0, but defaults doesn't handle that
			if (options.settings.gap != "undefined" && options.settings.gap === 0) {
				_this.settings.gap = options.settings.gap;
			}

			_this.viewSettings = {
				ignoreClass: _this.settings.ignoreClass,
				axis: _this.settings.axis,
				flow: _this.settings.flow,
				layout: _this.layout,
				width: 0,
				height: 0,
				forceEvenPages: false
			};

			_this.scrollTop = 0;
			_this.scrollLeft = 0;
			return _this;
		}

		_createClass$p(ContinuousViewManager, [{
			key: "display",
			value: function display(section, target) {
				return DefaultViewManager.prototype.display.call(this, section, target).then(function () {
					return this.fill();
				}.bind(this));
			}
		}, {
			key: "fill",
			value: function fill(_full) {
				var _this2 = this;

				var full = _full || new defer();

				this.q.enqueue(function () {
					return _this2.check();
				}).then(function (result) {
					if (result) {
						_this2.fill(full);
					} else {
						full.resolve();
					}
				});

				return full.promise;
			}
		}, {
			key: "moveTo",
			value: function moveTo(offset) {
				// var bounds = this.stage.bounds();
				// var dist = Math.floor(offset.top / bounds.height) * bounds.height;
				var distX = 0,
				    distY = 0;

				var offsetX = 0,
				    offsetY = 0;

				if (!this.isPaginated) {
					distY = offset.top;
					offsetY = offset.top + this.settings.offsetDelta;
				} else {
					distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;
					offsetX = distX + this.settings.offsetDelta;
				}

				if (distX > 0 || distY > 0) {
					this.scrollBy(distX, distY, true);
				}
			}
		}, {
			key: "afterResized",
			value: function afterResized(view) {
				this.emit(EVENTS.MANAGERS.RESIZE, view.section);
			}

			// Remove Previous Listeners if present

		}, {
			key: "removeShownListeners",
			value: function removeShownListeners(view) {

				// view.off("shown", this.afterDisplayed);
				// view.off("shown", this.afterDisplayedAbove);
				view.onDisplayed = function () {};
			}
		}, {
			key: "add",
			value: function add(section) {
				var _this3 = this;

				var view = this.createView(section);

				this.views.append(view);

				view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
					view.expanded = true;
				});

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this3.updateAxis(axis);
				});

				// view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));
				view.onDisplayed = this.afterDisplayed.bind(this);
				view.onResize = this.afterResized.bind(this);

				return view.display(this.request);
			}
		}, {
			key: "append",
			value: function append(section) {
				var _this4 = this;

				var view = this.createView(section);

				view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
					view.expanded = true;
				});

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this4.updateAxis(axis);
				});

				this.views.append(view);

				view.onDisplayed = this.afterDisplayed.bind(this);

				return view;
			}
		}, {
			key: "prepend",
			value: function prepend(section) {
				var _this5 = this;

				var view = this.createView(section);

				view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
					_this5.counter(bounds);
					view.expanded = true;
				});

				view.on(EVENTS.VIEWS.AXIS, function (axis) {
					_this5.updateAxis(axis);
				});

				this.views.prepend(view);

				view.onDisplayed = this.afterDisplayed.bind(this);

				return view;
			}
		}, {
			key: "counter",
			value: function counter(bounds) {
				if (this.settings.axis === "vertical") {
					this.scrollBy(0, bounds.heightDelta, true);
				} else {
					this.scrollBy(bounds.widthDelta, 0, true);
				}
			}
		}, {
			key: "update",
			value: function update(_offset) {
				var container = this.bounds();
				var views = this.views.all();
				var viewsLength = views.length;
				var offset = typeof _offset != "undefined" ? _offset : this.settings.offset || 0;
				var isVisible;
				var view;

				var updating = new defer();
				var promises = [];
				for (var i = 0; i < viewsLength; i++) {
					view = views[i];

					isVisible = this.isVisible(view, offset, offset, container);

					if (isVisible === true) {
						// console.log("visible " + view.index);

						if (!view.displayed) {
							var displayed = view.display(this.request).then(function (view) {
								view.show();
							}, function (err) {
								view.hide();
							});
							promises.push(displayed);
						} else {
							view.show();
						}
					} else {
						this.q.enqueue(view.destroy.bind(view));
						// console.log("hidden " + view.index);

						clearTimeout(this.trimTimeout);
						this.trimTimeout = setTimeout(function () {
							this.q.enqueue(this.trim.bind(this));
						}.bind(this), 250);
					}
				}

				if (promises.length) {
					return Promise.all(promises).catch(function (err) {
						updating.reject(err);
					});
				} else {
					updating.resolve();
					return updating.promise;
				}
			}
		}, {
			key: "check",
			value: function check(_offsetLeft, _offsetTop) {
				var _this6 = this;

				var checking = new defer();
				var newViews = [];

				var horizontal = this.settings.axis === "horizontal";
				var delta = this.settings.offset || 0;

				if (_offsetLeft && horizontal) {
					delta = _offsetLeft;
				}

				if (_offsetTop && !horizontal) {
					delta = _offsetTop;
				}

				var bounds = this._bounds; // bounds saved this until resize

				var rtl = this.settings.direction === "rtl";
				var dir = horizontal && rtl ? -1 : 1; //RTL reverses scrollTop

				var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
				var visibleLength = horizontal ? Math.floor(bounds.width) : bounds.height;
				var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

				var prepend = function prepend() {
					var first = _this6.views.first();
					var prev = first && first.section.prev();

					if (prev) {
						newViews.push(_this6.prepend(prev));
					}
				};

				var append = function append() {
					var last = _this6.views.last();
					var next = last && last.section.next();

					if (next) {
						newViews.push(_this6.append(next));
					}
				};

				if (offset + visibleLength + delta >= contentLength) {
					if (horizontal && rtl) {
						prepend();
					} else {
						append();
					}
				}

				if (offset - delta < 0) {
					if (horizontal && rtl) {
						append();
					} else {
						prepend();
					}
				}

				var promises = newViews.map(function (view) {
					return view.displayed;
				});

				if (newViews.length) {
					return Promise.all(promises).then(function () {
						if (_this6.layout.name === "pre-paginated" && _this6.layout.props.spread) {
							return _this6.check();
						}
					}).then(function () {
						// Check to see if anything new is on screen after rendering
						return _this6.update(delta);
					}, function (err) {
						return err;
					});
				} else {
					this.q.enqueue(function () {
						this.update();
					}.bind(this));
					checking.resolve(false);
					return checking.promise;
				}
			}
		}, {
			key: "trim",
			value: function trim() {
				var task = new defer();
				var displayed = this.views.displayed();
				var first = displayed[0];
				var last = displayed[displayed.length - 1];
				var firstIndex = this.views.indexOf(first);
				var lastIndex = this.views.indexOf(last);
				var above = this.views.slice(0, firstIndex);
				var below = this.views.slice(lastIndex + 1);

				// Erase all but last above
				for (var i = 0; i < above.length - 1; i++) {
					this.erase(above[i], above);
				}

				// Erase all except first below
				for (var j = 1; j < below.length; j++) {
					this.erase(below[j]);
				}

				task.resolve();
				return task.promise;
			}
		}, {
			key: "erase",
			value: function erase(view, above) {
				//Trim

				var prevTop;
				var prevLeft;

				if (!this.settings.fullsize) {
					prevTop = this.container.scrollTop;
					prevLeft = this.container.scrollLeft;
				} else {
					prevTop = window.scrollY;
					prevLeft = window.scrollX;
				}

				var bounds = view.bounds();

				this.views.remove(view);

				if (above) {
					if (this.settings.axis === "vertical") {
						this.scrollTo(0, prevTop - bounds.height, true);
					} else {
						this.scrollTo(prevLeft - Math.floor(bounds.width), 0, true);
					}
				}
			}
		}, {
			key: "addEventListeners",
			value: function addEventListeners(stage) {

				window.addEventListener("unload", function (e) {
					this.ignore = true;
					// this.scrollTo(0,0);
					this.destroy();
				}.bind(this));

				this.addScrollListeners();

				if (this.isPaginated && this.settings.snap) {
					this.snapper = new Snap(this, this.settings.snap && _typeof$c(this.settings.snap) === "object" && this.settings.snap);
				}
			}
		}, {
			key: "addScrollListeners",
			value: function addScrollListeners() {
				var scroller;

				this.tick = requestAnimationFrame$1;

				if (!this.settings.fullsize) {
					this.prevScrollTop = this.container.scrollTop;
					this.prevScrollLeft = this.container.scrollLeft;
				} else {
					this.prevScrollTop = window.scrollY;
					this.prevScrollLeft = window.scrollX;
				}

				this.scrollDeltaVert = 0;
				this.scrollDeltaHorz = 0;

				if (!this.settings.fullsize) {
					scroller = this.container;
					this.scrollTop = this.container.scrollTop;
					this.scrollLeft = this.container.scrollLeft;
				} else {
					scroller = window;
					this.scrollTop = window.scrollY;
					this.scrollLeft = window.scrollX;
				}

				this._onScroll = this.onScroll.bind(this);
				scroller.addEventListener("scroll", this._onScroll);
				this._scrolled = debounce_1$1(this.scrolled.bind(this), 30);
				// this.tick.call(window, this.onScroll.bind(this));

				this.didScroll = false;
			}
		}, {
			key: "removeEventListeners",
			value: function removeEventListeners() {
				var scroller;

				if (!this.settings.fullsize) {
					scroller = this.container;
				} else {
					scroller = window;
				}

				scroller.removeEventListener("scroll", this._onScroll);
				this._onScroll = undefined;
			}
		}, {
			key: "onScroll",
			value: function onScroll() {
				var scrollTop = void 0;
				var scrollLeft = void 0;
				var dir = this.settings.direction === "rtl" ? -1 : 1;

				if (!this.settings.fullsize) {
					scrollTop = this.container.scrollTop;
					scrollLeft = this.container.scrollLeft;
				} else {
					scrollTop = window.scrollY * dir;
					scrollLeft = window.scrollX * dir;
				}

				this.scrollTop = scrollTop;
				this.scrollLeft = scrollLeft;

				if (!this.ignore) {

					this._scrolled();
				} else {
					this.ignore = false;
				}

				this.scrollDeltaVert += Math.abs(scrollTop - this.prevScrollTop);
				this.scrollDeltaHorz += Math.abs(scrollLeft - this.prevScrollLeft);

				this.prevScrollTop = scrollTop;
				this.prevScrollLeft = scrollLeft;

				clearTimeout(this.scrollTimeout);
				this.scrollTimeout = setTimeout(function () {
					this.scrollDeltaVert = 0;
					this.scrollDeltaHorz = 0;
				}.bind(this), 150);

				clearTimeout(this.afterScrolled);

				this.didScroll = false;
			}
		}, {
			key: "scrolled",
			value: function scrolled() {

				this.q.enqueue(function () {
					this.check();
				}.bind(this));

				this.emit(EVENTS.MANAGERS.SCROLL, {
					top: this.scrollTop,
					left: this.scrollLeft
				});

				clearTimeout(this.afterScrolled);
				this.afterScrolled = setTimeout(function () {

					// Don't report scroll if we are about the snap
					if (this.snapper && this.snapper.supportsTouch && this.snapper.needsSnap()) {
						return;
					}

					this.emit(EVENTS.MANAGERS.SCROLLED, {
						top: this.scrollTop,
						left: this.scrollLeft
					});
				}.bind(this), this.settings.afterScrolledTimeout);
			}
		}, {
			key: "next",
			value: function next() {

				var dir = this.settings.direction;
				var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

				if (!this.views.length) return;

				if (this.isPaginated && this.settings.axis === "horizontal") {

					this.scrollBy(delta, 0, true);
				} else {

					this.scrollBy(0, this.layout.height, true);
				}

				this.q.enqueue(function () {
					this.check();
				}.bind(this));
			}
		}, {
			key: "prev",
			value: function prev() {

				var dir = this.settings.direction;
				var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

				if (!this.views.length) return;

				if (this.isPaginated && this.settings.axis === "horizontal") {

					this.scrollBy(-delta, 0, true);
				} else {

					this.scrollBy(0, -this.layout.height, true);
				}

				this.q.enqueue(function () {
					this.check();
				}.bind(this));
			}

			// updateAxis(axis, forceUpdate){
			//
			// 	super.updateAxis(axis, forceUpdate);
			//
			// 	if (axis === "vertical") {
			// 		this.settings.infinite = true;
			// 	} else {
			// 		this.settings.infinite = false;
			// 	}
			// }

		}, {
			key: "updateFlow",
			value: function updateFlow(flow) {
				if (this.rendered && this.snapper) {
					this.snapper.destroy();
					this.snapper = undefined;
				}

				_get$1(ContinuousViewManager.prototype.__proto__ || Object.getPrototypeOf(ContinuousViewManager.prototype), "updateFlow", this).call(this, flow);

				if (this.rendered && this.isPaginated && this.settings.snap) {
					this.snapper = new Snap(this, this.settings.snap && _typeof$c(this.settings.snap) === "object" && this.settings.snap);
				}
			}
		}, {
			key: "destroy",
			value: function destroy() {
				_get$1(ContinuousViewManager.prototype.__proto__ || Object.getPrototypeOf(ContinuousViewManager.prototype), "destroy", this).call(this);

				if (this.snapper) {
					this.snapper.destroy();
				}
			}
		}]);

		return ContinuousViewManager;
	}(DefaultViewManager);

	var _typeof$d = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	var _createClass$q = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$q(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Displays an Epub as a series of Views for each Section.
	 * Requires Manager and View class to handle specifics of rendering
	 * the section content.
	 * @class
	 * @param {Book} book
	 * @param {object} [options]
	 * @param {number} [options.width]
	 * @param {number} [options.height]
	 * @param {string} [options.ignoreClass] class for the cfi parser to ignore
	 * @param {string | function | object} [options.manager='default']
	 * @param {string | function} [options.view='iframe']
	 * @param {string} [options.layout] layout to force
	 * @param {string} [options.spread] force spread value
	 * @param {number} [options.minSpreadWidth] overridden by spread: none (never) / both (always)
	 * @param {string} [options.stylesheet] url of stylesheet to be injected
	 * @param {boolean} [options.resizeOnOrientationChange] false to disable orientation events
	 * @param {string} [options.script] url of script to be injected
	 * @param {boolean | object} [options.snap=false] use snap scrolling
	 */

	var Rendition = function () {
		function Rendition(book, options) {
			_classCallCheck$q(this, Rendition);

			this.settings = extend$1(this.settings || {}, {
				width: null,
				height: null,
				ignoreClass: "",
				manager: "default",
				view: "iframe",
				flow: null,
				layout: null,
				spread: null,
				minSpreadWidth: 800,
				stylesheet: null,
				resizeOnOrientationChange: true,
				script: null,
				snap: false
			});

			extend$1(this.settings, options);

			if (_typeof$d(this.settings.manager) === "object") {
				this.manager = this.settings.manager;
			}

			this.book = book;

			/**
	   * Adds Hook methods to the Rendition prototype
	   * @member {object} hooks
	   * @property {Hook} hooks.content
	   * @memberof Rendition
	   */
			this.hooks = {};
			this.hooks.display = new Hook(this);
			this.hooks.serialize = new Hook(this);
			this.hooks.content = new Hook(this);
			this.hooks.unloaded = new Hook(this);
			this.hooks.layout = new Hook(this);
			this.hooks.render = new Hook(this);
			this.hooks.show = new Hook(this);

			this.hooks.content.register(this.handleLinks.bind(this));
			this.hooks.content.register(this.passEvents.bind(this));
			this.hooks.content.register(this.adjustImages.bind(this));

			this.injected = {};
			this.injected['identifier'] = this.injectIdentifier.bind(this);
			this.book.spine.hooks.content.register(this.injected['identifier']);

			if (this.settings.stylesheet) {
				this.injected['stylesheet'] = this.injectStylesheet.bind(this);
				this.book.spine.hooks.content.register(this.injected['stylesheet']);
			}

			if (this.settings.script) {
				this.injected['script'] = this.injectScript.bind(this);
				this.book.spine.hooks.content.register(this.injected['script']);
			}

			/**
	   * @member {Themes} themes
	   * @memberof Rendition
	   */
			this.themes = new Themes(this);

			/**
	   * @member {Annotations} annotations
	   * @memberof Rendition
	   */
			this.annotations = new Annotations(this);

			this.epubcfi = new EpubCFI();

			this.q = new Queue(this);

			/**
	   * A Rendered Location Range
	   * @typedef location
	   * @type {Object}
	   * @property {object} start
	   * @property {string} start.index
	   * @property {string} start.href
	   * @property {object} start.displayed
	   * @property {EpubCFI} start.cfi
	   * @property {number} start.location
	   * @property {number} start.percentage
	   * @property {number} start.displayed.page
	   * @property {number} start.displayed.total
	   * @property {object} end
	   * @property {string} end.index
	   * @property {string} end.href
	   * @property {object} end.displayed
	   * @property {EpubCFI} end.cfi
	   * @property {number} end.location
	   * @property {number} end.percentage
	   * @property {number} end.displayed.page
	   * @property {number} end.displayed.total
	   * @property {boolean} atStart
	   * @property {boolean} atEnd
	   * @memberof Rendition
	   */
			this.location = undefined;

			// Hold queue until book is opened
			this.q.enqueue(this.book.opened);

			this.starting = new defer();
			/**
	   * @member {promise} started returns after the rendition has started
	   * @memberof Rendition
	   */
			this.started = this.starting.promise;
			// Block the queue until rendering is started
			this.q.enqueue(this.start);
		}

		/**
	  * Set the manager function
	  * @param {function} manager
	  */


		_createClass$q(Rendition, [{
			key: "setManager",
			value: function setManager(manager) {
				this.manager = manager;
			}

			/**
	   * Require the manager from passed string, or as a class function
	   * @param  {string|object} manager [description]
	   * @return {method}
	   */

		}, {
			key: "requireManager",
			value: function requireManager(manager) {
				var viewManager;

				// If manager is a string, try to load from imported managers
				if (typeof manager === "string" && manager === "default") {
					viewManager = DefaultViewManager;
				} else if (typeof manager === "string" && manager === "continuous") {
					viewManager = ContinuousViewManager;
				} else {
					// otherwise, assume we were passed a class function
					viewManager = manager;
				}

				return viewManager;
			}

			/**
	   * Require the view from passed string, or as a class function
	   * @param  {string|object} view
	   * @return {view}
	   */

		}, {
			key: "requireView",
			value: function requireView(view) {
				var View;

				// If view is a string, try to load from imported views,
				if (typeof view == "string" && view === "iframe") {
					View = IframeView;
				} else {
					// otherwise, assume we were passed a class function
					View = view;
				}

				return View;
			}

			/**
	   * Start the rendering
	   * @return {Promise} rendering has started
	   */

		}, {
			key: "start",
			value: function start() {

				if (!this.manager) {
					this.ViewManager = this.requireManager(this.settings.manager);
					this.View = this.requireView(this.settings.view);

					this.manager = new this.ViewManager({
						view: this.View,
						queue: this.q,
						request: this.book.load.bind(this.book),
						settings: this.settings
					});
				}

				this.direction(this.book.package.metadata.direction);

				// Parse metadata to get layout props
				this.settings.globalLayoutProperties = this.determineLayoutProperties(this.book.package.metadata);

				this.flow(this.settings.globalLayoutProperties.flow);

				this.layout(this.settings.globalLayoutProperties);

				// Listen for displayed views
				this.manager.on(EVENTS.MANAGERS.ADDED, this.afterDisplayed.bind(this));
				this.manager.on(EVENTS.MANAGERS.REMOVED, this.afterRemoved.bind(this));

				// Listen for resizing
				this.manager.on(EVENTS.MANAGERS.RESIZED, this.onResized.bind(this));

				// Listen for rotation
				this.manager.on(EVENTS.MANAGERS.ORIENTATION_CHANGE, this.onOrientationChange.bind(this));

				// Listen for scroll changes
				this.manager.on(EVENTS.MANAGERS.SCROLLED, this.reportLocation.bind(this));

				/**
	    * Emit that rendering has started
	    * @event started
	    * @memberof Rendition
	    */
				this.emit(EVENTS.RENDITION.STARTED);

				// Start processing queue
				this.starting.resolve();
			}

			/**
	   * Call to attach the container to an element in the dom
	   * Container must be attached before rendering can begin
	   * @param  {element} element to attach to
	   * @return {Promise}
	   */

		}, {
			key: "attachTo",
			value: function attachTo(element) {

				return this.q.enqueue(function () {

					// Start rendering
					this.manager.render(element, {
						"width": this.settings.width,
						"height": this.settings.height
					});

					/**
	     * Emit that rendering has attached to an element
	     * @event attached
	     * @memberof Rendition
	     */
					this.emit(EVENTS.RENDITION.ATTACHED);
				}.bind(this));
			}

			/**
	   * Display a point in the book
	   * The request will be added to the rendering Queue,
	   * so it will wait until book is opened, rendering started
	   * and all other rendering tasks have finished to be called.
	   * @param  {string} target Url or EpubCFI
	   * @return {Promise}
	   */

		}, {
			key: "display",
			value: function display(target) {
				if (this.displaying) {
					this.displaying.resolve();
				}
				return this.q.enqueue(this._display, target);
			}

			/**
	   * Tells the manager what to display immediately
	   * @private
	   * @param  {string} target Url or EpubCFI
	   * @return {Promise}
	   */

		}, {
			key: "_display",
			value: function _display(target) {
				var _this = this;

				if (!this.book) {
					return;
				}
				var isCfiString = this.epubcfi.isCfiString(target);
				var displaying = new defer();
				var displayed = displaying.promise;
				var section;

				this.displaying = displaying;

				// Check if this is a book percentage
				if (this.book.locations.length() && isFloat(target)) {
					target = this.book.locations.cfiFromPercentage(parseFloat(target));
				}

				section = this.book.spine.get(target);

				if (!section) {
					displaying.reject(new Error("No Section Found"));
					return displayed;
				}

				this.manager.display(section, target).then(function () {
					displaying.resolve(section);
					_this.displaying = undefined;

					/**
	     * Emit that a section has been displayed
	     * @event displayed
	     * @param {Section} section
	     * @memberof Rendition
	     */
					_this.emit(EVENTS.RENDITION.DISPLAYED, section);
					_this.reportLocation();
				}, function (err) {
					/**
	     * Emit that has been an error displaying
	     * @event displayError
	     * @param {Section} section
	     * @memberof Rendition
	     */
					_this.emit(EVENTS.RENDITION.DISPLAY_ERROR, err);
				});

				return displayed;
			}

			/*
	  render(view, show) {
	  		// view.onLayout = this.layout.format.bind(this.layout);
	  	view.create();
	  		// Fit to size of the container, apply padding
	  	this.manager.resizeView(view);
	  		// Render Chain
	  	return view.section.render(this.book.request)
	  		.then(function(contents){
	  			return view.load(contents);
	  		}.bind(this))
	  		.then(function(doc){
	  			return this.hooks.content.trigger(view, this);
	  		}.bind(this))
	  		.then(function(){
	  			this.layout.format(view.contents);
	  			return this.hooks.layout.trigger(view, this);
	  		}.bind(this))
	  		.then(function(){
	  			return view.display();
	  		}.bind(this))
	  		.then(function(){
	  			return this.hooks.render.trigger(view, this);
	  		}.bind(this))
	  		.then(function(){
	  			if(show !== false) {
	  				this.q.enqueue(function(view){
	  					view.show();
	  				}, view);
	  			}
	  			// this.map = new Map(view, this.layout);
	  			this.hooks.show.trigger(view, this);
	  			this.trigger("rendered", view.section);
	  			}.bind(this))
	  		.catch(function(e){
	  			this.trigger("loaderror", e);
	  		}.bind(this));
	  	}
	  */

			/**
	   * Report what section has been displayed
	   * @private
	   * @param  {*} view
	   */

		}, {
			key: "afterDisplayed",
			value: function afterDisplayed(view) {
				var _this2 = this;

				view.on(EVENTS.VIEWS.MARK_CLICKED, function (cfiRange, data) {
					return _this2.triggerMarkEvent(cfiRange, data, view);
				});

				this.hooks.render.trigger(view, this).then(function () {
					if (view.contents) {
						_this2.hooks.content.trigger(view.contents, _this2).then(function () {
							/**
	       * Emit that a section has been rendered
	       * @event rendered
	       * @param {Section} section
	       * @param {View} view
	       * @memberof Rendition
	       */
							_this2.emit(EVENTS.RENDITION.RENDERED, view.section, view);
						});
					} else {
						_this2.emit(EVENTS.RENDITION.RENDERED, view.section, view);
					}
				});
			}

			/**
	   * Report what has been removed
	   * @private
	   * @param  {*} view
	   */

		}, {
			key: "afterRemoved",
			value: function afterRemoved(view) {
				var _this3 = this;

				this.hooks.unloaded.trigger(view, this).then(function () {
					/**
	     * Emit that a section has been removed
	     * @event removed
	     * @param {Section} section
	     * @param {View} view
	     * @memberof Rendition
	     */
					_this3.emit(EVENTS.RENDITION.REMOVED, view.section, view);
				});
			}

			/**
	   * Report resize events and display the last seen location
	   * @private
	   */

		}, {
			key: "onResized",
			value: function onResized(size) {

				/**
	    * Emit that the rendition has been resized
	    * @event resized
	    * @param {number} width
	    * @param {height} height
	    * @memberof Rendition
	    */
				this.emit(EVENTS.RENDITION.RESIZED, {
					width: size.width,
					height: size.height
				});

				if (this.location && this.location.start) {
					this.display(this.location.start.cfi);
				}
			}

			/**
	   * Report orientation events and display the last seen location
	   * @private
	   */

		}, {
			key: "onOrientationChange",
			value: function onOrientationChange(orientation) {
				/**
	    * Emit that the rendition has been rotated
	    * @event orientationchange
	    * @param {string} orientation
	    * @memberof Rendition
	    */
				this.emit(EVENTS.RENDITION.ORIENTATION_CHANGE, orientation);
			}

			/**
	   * Move the Rendition to a specific offset
	   * Usually you would be better off calling display()
	   * @param {object} offset
	   */

		}, {
			key: "moveTo",
			value: function moveTo(offset) {
				this.manager.moveTo(offset);
			}

			/**
	   * Trigger a resize of the views
	   * @param {number} [width]
	   * @param {number} [height]
	   */

		}, {
			key: "resize",
			value: function resize(width, height) {
				if (width) {
					this.settings.width = width;
				}
				if (height) {
					this.settings.height = height;
				}
				this.manager.resize(width, height);
			}

			/**
	   * Clear all rendered views
	   */

		}, {
			key: "clear",
			value: function clear() {
				this.manager.clear();
			}

			/**
	   * Go to the next "page" in the rendition
	   * @return {Promise}
	   */

		}, {
			key: "next",
			value: function next() {
				return this.q.enqueue(this.manager.next.bind(this.manager)).then(this.reportLocation.bind(this));
			}

			/**
	   * Go to the previous "page" in the rendition
	   * @return {Promise}
	   */

		}, {
			key: "prev",
			value: function prev() {
				return this.q.enqueue(this.manager.prev.bind(this.manager)).then(this.reportLocation.bind(this));
			}

			//-- http://www.idpf.org/epub/301/spec/epub-publications.html#meta-properties-rendering
			/**
	   * Determine the Layout properties from metadata and settings
	   * @private
	   * @param  {object} metadata
	   * @return {object} properties
	   */

		}, {
			key: "determineLayoutProperties",
			value: function determineLayoutProperties(metadata) {
				var properties;
				var layout = this.settings.layout || metadata.layout || "reflowable";
				var spread = this.settings.spread || metadata.spread || "auto";
				var orientation = this.settings.orientation || metadata.orientation || "auto";
				var flow = this.settings.flow || metadata.flow || "auto";
				var viewport = metadata.viewport || "";
				var minSpreadWidth = this.settings.minSpreadWidth || metadata.minSpreadWidth || 800;
				var direction = this.settings.direction || metadata.direction || "ltr";

				if ((this.settings.width === 0 || this.settings.width > 0) && (this.settings.height === 0 || this.settings.height > 0)) ;

				properties = {
					layout: layout,
					spread: spread,
					orientation: orientation,
					flow: flow,
					viewport: viewport,
					minSpreadWidth: minSpreadWidth,
					direction: direction
				};

				return properties;
			}

			/**
	   * Adjust the flow of the rendition to paginated or scrolled
	   * (scrolled-continuous vs scrolled-doc are handled by different view managers)
	   * @param  {string} flow
	   */

		}, {
			key: "flow",
			value: function flow(_flow2) {
				var _flow = _flow2;
				if (_flow2 === "scrolled" || _flow2 === "scrolled-doc" || _flow2 === "scrolled-continuous") {
					_flow = "scrolled";
				}

				if (_flow2 === "auto" || _flow2 === "paginated") {
					_flow = "paginated";
				}

				this.settings.flow = _flow2;

				if (this._layout) {
					this._layout.flow(_flow);
				}

				if (this.manager && this._layout) {
					this.manager.applyLayout(this._layout);
				}

				if (this.manager) {
					this.manager.updateFlow(_flow);
				}

				if (this.manager && this.manager.isRendered() && this.location) {
					this.manager.clear();
					this.display(this.location.start.cfi);
				}
			}

			/**
	   * Adjust the layout of the rendition to reflowable or pre-paginated
	   * @param  {object} settings
	   */

		}, {
			key: "layout",
			value: function layout(settings) {
				var _this4 = this;

				if (settings) {
					this._layout = new Layout(settings);
					this._layout.spread(settings.spread, this.settings.minSpreadWidth);

					// this.mapping = new Mapping(this._layout.props);

					this._layout.on(EVENTS.LAYOUT.UPDATED, function (props, changed) {
						_this4.emit(EVENTS.RENDITION.LAYOUT, props, changed);
					});
				}

				if (this.manager && this._layout) {
					this.manager.applyLayout(this._layout);
				}

				return this._layout;
			}

			/**
	   * Adjust if the rendition uses spreads
	   * @param  {string} spread none | auto (TODO: implement landscape, portrait, both)
	   * @param  {int} [min] min width to use spreads at
	   */

		}, {
			key: "spread",
			value: function spread(_spread, min) {

				this.settings.spread = _spread;

				if (min) {
					this.settings.minSpreadWidth = min;
				}

				if (this._layout) {
					this._layout.spread(_spread, min);
				}

				if (this.manager && this.manager.isRendered()) {
					this.manager.updateLayout();
				}
			}

			/**
	   * Adjust the direction of the rendition
	   * @param  {string} dir
	   */

		}, {
			key: "direction",
			value: function direction(dir) {

				this.settings.direction = dir || "ltr";

				if (this.manager) {
					this.manager.direction(this.settings.direction);
				}

				if (this.manager && this.manager.isRendered() && this.location) {
					this.manager.clear();
					this.display(this.location.start.cfi);
				}
			}

			/**
	   * Report the current location
	   * @fires relocated
	   * @fires locationChanged
	   */

		}, {
			key: "reportLocation",
			value: function reportLocation() {
				return this.q.enqueue(function reportedLocation() {
					requestAnimationFrame(function reportedLocationAfterRAF() {
						var location = this.manager.currentLocation();
						if (location && location.then && typeof location.then === "function") {
							location.then(function (result) {
								var located = this.located(result);

								if (!located || !located.start || !located.end) {
									return;
								}

								this.location = located;

								this.emit(EVENTS.RENDITION.LOCATION_CHANGED, {
									index: this.location.start.index,
									href: this.location.start.href,
									start: this.location.start.cfi,
									end: this.location.end.cfi,
									percentage: this.location.start.percentage
								});

								this.emit(EVENTS.RENDITION.RELOCATED, this.location);
							}.bind(this));
						} else if (location) {
							var located = this.located(location);

							if (!located || !located.start || !located.end) {
								return;
							}

							this.location = located;

							/**
	       * @event locationChanged
	       * @deprecated
	       * @type {object}
	       * @property {number} index
	       * @property {string} href
	       * @property {EpubCFI} start
	       * @property {EpubCFI} end
	       * @property {number} percentage
	       * @memberof Rendition
	       */
							this.emit(EVENTS.RENDITION.LOCATION_CHANGED, {
								index: this.location.start.index,
								href: this.location.start.href,
								start: this.location.start.cfi,
								end: this.location.end.cfi,
								percentage: this.location.start.percentage
							});

							/**
	       * @event relocated
	       * @type {displayedLocation}
	       * @memberof Rendition
	       */
							this.emit(EVENTS.RENDITION.RELOCATED, this.location);
						}
					}.bind(this));
				}.bind(this));
			}

			/**
	   * Get the Current Location object
	   * @return {displayedLocation | promise} location (may be a promise)
	   */

		}, {
			key: "currentLocation",
			value: function currentLocation() {
				var location = this.manager.currentLocation();
				if (location && location.then && typeof location.then === "function") {
					location.then(function (result) {
						var located = this.located(result);
						return located;
					}.bind(this));
				} else if (location) {
					var located = this.located(location);
					return located;
				}
			}

			/**
	   * Creates a Rendition#locationRange from location
	   * passed by the Manager
	   * @returns {displayedLocation}
	   * @private
	   */

		}, {
			key: "located",
			value: function located(location) {
				if (!location.length) {
					return {};
				}
				var start = location[0];
				var end = location[location.length - 1];

				var located = {
					start: {
						index: start.index,
						href: start.href,
						cfi: start.mapping.start,
						displayed: {
							page: start.pages[0] || 1,
							total: start.totalPages
						}
					},
					end: {
						index: end.index,
						href: end.href,
						cfi: end.mapping.end,
						displayed: {
							page: end.pages[end.pages.length - 1] || 1,
							total: end.totalPages
						}
					}
				};

				var locationStart = this.book.locations.locationFromCfi(start.mapping.start);
				var locationEnd = this.book.locations.locationFromCfi(end.mapping.end);

				if (locationStart != null) {
					located.start.location = locationStart;
					located.start.percentage = this.book.locations.percentageFromLocation(locationStart);
				}
				if (locationEnd != null) {
					located.end.location = locationEnd;
					located.end.percentage = this.book.locations.percentageFromLocation(locationEnd);
				}

				var pageStart = this.book.pageList.pageFromCfi(start.mapping.start);
				var pageEnd = this.book.pageList.pageFromCfi(end.mapping.end);

				if (pageStart != -1) {
					located.start.page = pageStart;
				}
				if (pageEnd != -1) {
					located.end.page = pageEnd;
				}

				if (end.index === this.book.spine.last().index && located.end.displayed.page >= located.end.displayed.total) {
					located.atEnd = true;
				}

				if (start.index === this.book.spine.first().index && located.start.displayed.page === 1) {
					located.atStart = true;
				}

				return located;
			}

			/**
	   * Remove and Clean Up the Rendition
	   */

		}, {
			key: "destroy",
			value: function destroy() {
				// Clear the queue
				// this.q.clear();
				// this.q = undefined;

				this.manager && this.manager.destroy();
				this.book.spine.hooks.content.deregister(this.injected['identifier']);
				this.book.spine.hooks.content.deregister(this.injected['script']);
				this.book.spine.hooks.content.deregister(this.injected['stylesheet']);

				this.book = undefined;

				// this.views = null;

				// this.hooks.display.clear();
				// this.hooks.serialize.clear();
				// this.hooks.content.clear();
				// this.hooks.layout.clear();
				// this.hooks.render.clear();
				// this.hooks.show.clear();
				// this.hooks = {};

				// this.themes.destroy();
				// this.themes = undefined;

				// this.epubcfi = undefined;

				// this.starting = undefined;
				// this.started = undefined;

			}

			/**
	   * Pass the events from a view's Contents
	   * @private
	   * @param  {Contents} view contents
	   */

		}, {
			key: "passEvents",
			value: function passEvents(contents) {
				var _this5 = this;

				DOM_EVENTS.forEach(function (e) {
					contents.on(e, function (ev) {
						return _this5.triggerViewEvent(ev, contents);
					});
				});

				contents.on(EVENTS.CONTENTS.SELECTED, function (e) {
					return _this5.triggerSelectedEvent(e, contents);
				});
			}

			/**
	   * Emit events passed by a view
	   * @private
	   * @param  {event} e
	   */

		}, {
			key: "triggerViewEvent",
			value: function triggerViewEvent(e, contents) {
				this.emit(e.type, e, contents);
			}

			/**
	   * Emit a selection event's CFI Range passed from a a view
	   * @private
	   * @param  {EpubCFI} cfirange
	   */

		}, {
			key: "triggerSelectedEvent",
			value: function triggerSelectedEvent(cfirange, contents) {
				/**
	    * Emit that a text selection has occured
	    * @event selected
	    * @param {EpubCFI} cfirange
	    * @param {Contents} contents
	    * @memberof Rendition
	    */
				this.emit(EVENTS.RENDITION.SELECTED, cfirange, contents);
			}

			/**
	   * Emit a markClicked event with the cfiRange and data from a mark
	   * @private
	   * @param  {EpubCFI} cfirange
	   */

		}, {
			key: "triggerMarkEvent",
			value: function triggerMarkEvent(cfiRange, data, contents) {
				/**
	    * Emit that a mark was clicked
	    * @event markClicked
	    * @param {EpubCFI} cfirange
	    * @param {object} data
	    * @param {Contents} contents
	    * @memberof Rendition
	    */
				this.emit(EVENTS.RENDITION.MARK_CLICKED, cfiRange, data, contents);
			}

			/**
	   * Get a Range from a Visible CFI
	   * @param  {string} cfi EpubCfi String
	   * @param  {string} ignoreClass
	   * @return {range}
	   */

		}, {
			key: "getRange",
			value: function getRange(cfi, ignoreClass) {
				var _cfi = new EpubCFI(cfi);
				var found = this.manager.visible().filter(function (view) {
					if (_cfi.spinePos === view.index) return true;
				});

				// Should only every return 1 item
				if (found.length) {
					return found[0].contents.range(_cfi, ignoreClass);
				}
			}

			/**
	   * Hook to adjust images to fit in columns
	   * @param  {Contents} contents
	   * @private
	   */

		}, {
			key: "adjustImages",
			value: function adjustImages(contents) {

				if (this._layout.name === "pre-paginated") {
					return new Promise(function (resolve) {
						resolve();
					});
				}

				var computed = contents.window.getComputedStyle(contents.content, null);
				var height = (contents.content.offsetHeight - (parseFloat(computed.paddingTop) + parseFloat(computed.paddingBottom))) * .95;
				var verticalPadding = parseFloat(computed.verticalPadding);

				contents.addStylesheetRules({
					"img": {
						"max-width": (this._layout.columnWidth ? this._layout.columnWidth - verticalPadding + "px" : "100%") + "!important",
						"max-height": height + "px" + "!important",
						"object-fit": "contain",
						"page-break-inside": "avoid",
						"break-inside": "avoid",
						"box-sizing": "border-box"
					},
					"svg": {
						"max-width": (this._layout.columnWidth ? this._layout.columnWidth - verticalPadding + "px" : "100%") + "!important",
						"max-height": height + "px" + "!important",
						"page-break-inside": "avoid",
						"break-inside": "avoid"
					}
				});

				return new Promise(function (resolve, reject) {
					// Wait to apply
					setTimeout(function () {
						resolve();
					}, 1);
				});
			}

			/**
	   * Get the Contents object of each rendered view
	   * @returns {Contents[]}
	   */

		}, {
			key: "getContents",
			value: function getContents() {
				return this.manager ? this.manager.getContents() : [];
			}

			/**
	   * Get the views member from the manager
	   * @returns {Views}
	   */

		}, {
			key: "views",
			value: function views() {
				var views = this.manager ? this.manager.views : undefined;
				return views || [];
			}

			/**
	   * Hook to handle link clicks in rendered content
	   * @param  {Contents} contents
	   * @private
	   */

		}, {
			key: "handleLinks",
			value: function handleLinks(contents) {
				var _this6 = this;

				if (contents) {
					contents.on(EVENTS.CONTENTS.LINK_CLICKED, function (href) {
						var relative = _this6.book.path.relative(href);
						_this6.display(relative);
					});
				}
			}

			/**
	   * Hook to handle injecting stylesheet before
	   * a Section is serialized
	   * @param  {document} doc
	   * @param  {Section} section
	   * @private
	   */

		}, {
			key: "injectStylesheet",
			value: function injectStylesheet(doc, section) {
				var style = doc.createElement("link");
				style.setAttribute("type", "text/css");
				style.setAttribute("rel", "stylesheet");
				style.setAttribute("href", this.settings.stylesheet);
				doc.getElementsByTagName("head")[0].appendChild(style);
			}

			/**
	   * Hook to handle injecting scripts before
	   * a Section is serialized
	   * @param  {document} doc
	   * @param  {Section} section
	   * @private
	   */

		}, {
			key: "injectScript",
			value: function injectScript(doc, section) {
				var script = doc.createElement("script");
				script.setAttribute("type", "text/javascript");
				script.setAttribute("src", this.settings.script);
				script.textContent = " "; // Needed to prevent self closing tag
				doc.getElementsByTagName("head")[0].appendChild(script);
			}

			/**
	   * Hook to handle the document identifier before
	   * a Section is serialized
	   * @param  {document} doc
	   * @param  {Section} section
	   * @private
	   */

		}, {
			key: "injectIdentifier",
			value: function injectIdentifier(doc, section) {
				var ident = this.book.packaging.metadata.identifier;
				var meta = doc.createElement("meta");
				meta.setAttribute("name", "dc.relation.ispartof");
				if (ident) {
					meta.setAttribute("content", ident);
				}
				doc.getElementsByTagName("head")[0].appendChild(meta);
			}
		}, {
			key: "scale",
			value: function scale(s) {
				return this.manager && this.manager.scale(s);
			}
		}]);

		return Rendition;
	}();

	//-- Enable binding events to Renderer


	eventEmitter(Rendition.prototype);

	function request(url, type$$1, withCredentials, headers) {
		var supportsURL = typeof window != "undefined" ? window.URL : false; // TODO: fallback for url if window isn't defined
		var BLOB_RESPONSE = supportsURL ? "blob" : "arraybuffer";

		var deferred = new defer();

		var xhr = new XMLHttpRequest();

		//-- Check from PDF.js:
		//   https://github.com/mozilla/pdf.js/blob/master/web/compatibility.js
		var xhrPrototype = XMLHttpRequest.prototype;

		var header;

		if (!("overrideMimeType" in xhrPrototype)) {
			// IE10 might have response, but not overrideMimeType
			Object.defineProperty(xhrPrototype, "overrideMimeType", {
				value: function xmlHttpRequestOverrideMimeType() {}
			});
		}

		if (withCredentials) {
			xhr.withCredentials = true;
		}

		xhr.onreadystatechange = handler;
		xhr.onerror = err;

		xhr.open("GET", url, true);

		for (header in headers) {
			xhr.setRequestHeader(header, headers[header]);
		}

		if (type$$1 == "json") {
			xhr.setRequestHeader("Accept", "application/json");
		}

		// If type isn"t set, determine it from the file extension
		if (!type$$1) {
			type$$1 = new Path(url).extension;
		}

		if (type$$1 == "blob") {
			xhr.responseType = BLOB_RESPONSE;
		}

		if (isXml(type$$1)) {
			// xhr.responseType = "document";
			xhr.overrideMimeType("text/xml"); // for OPF parsing
		}

		if (type$$1 == "binary") {
			xhr.responseType = "arraybuffer";
		}

		xhr.send();

		function err(e) {
			deferred.reject(e);
		}

		function handler() {
			if (this.readyState === XMLHttpRequest.DONE) {
				var responseXML = false;

				if (this.responseType === "" || this.responseType === "document") {
					responseXML = this.responseXML;
				}

				if (this.status === 200 || this.status === 0 || responseXML) {
					//-- Firefox is reporting 0 for blob urls
					var r;

					if (!this.response && !responseXML) {
						deferred.reject({
							status: this.status,
							message: "Empty Response",
							stack: new Error().stack
						});
						return deferred.promise;
					}

					if (this.status === 403) {
						deferred.reject({
							status: this.status,
							response: this.response,
							message: "Forbidden",
							stack: new Error().stack
						});
						return deferred.promise;
					}
					if (responseXML) {
						r = this.responseXML;
					} else if (isXml(type$$1)) {
						// xhr.overrideMimeType("text/xml"); // for OPF parsing
						// If this.responseXML wasn't set, try to parse using a DOMParser from text
						r = parse(this.response, "text/xml");
					} else if (type$$1 == "xhtml") {
						r = parse(this.response, "application/xhtml+xml");
					} else if (type$$1 == "html" || type$$1 == "htm") {
						r = parse(this.response, "text/html");
					} else if (type$$1 == "json") {
						r = JSON.parse(this.response);
					} else if (type$$1 == "blob") {

						if (supportsURL) {
							r = this.response;
						} else {
							//-- Safari doesn't support responseType blob, so create a blob from arraybuffer
							r = new Blob([this.response]);
						}
					} else {
						r = this.response;
					}

					deferred.resolve(r);
				} else {

					deferred.reject({
						status: this.status,
						message: this.response,
						stack: new Error().stack
					});
				}
			}
		}

		return deferred.promise;
	}

	var _createClass$r = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$r(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Handles Unzipping a requesting files from an Epub Archive
	 * @class
	 */

	var Archive = function () {
		function Archive() {
			_classCallCheck$r(this, Archive);

			this.zip = undefined;
			this.urlCache = {};

			this.checkRequirements();
		}

		/**
	  * Checks to see if JSZip exists in global namspace,
	  * Requires JSZip if it isn't there
	  * @private
	  */


		_createClass$r(Archive, [{
			key: "checkRequirements",
			value: function checkRequirements() {
				try {
					if (typeof JSZip === "undefined") {
						var _JSZip = require("jszip");
						this.zip = new _JSZip();
					} else {
						this.zip = new JSZip();
					}
				} catch (e) {
					throw new Error("JSZip lib not loaded");
				}
			}

			/**
	   * Open an archive
	   * @param  {binary} input
	   * @param  {boolean} [isBase64] tells JSZip if the input data is base64 encoded
	   * @return {Promise} zipfile
	   */

		}, {
			key: "open",
			value: function open(input, isBase64) {
				return this.zip.loadAsync(input, { "base64": isBase64 });
			}

			/**
	   * Load and Open an archive
	   * @param  {string} zipUrl
	   * @param  {boolean} [isBase64] tells JSZip if the input data is base64 encoded
	   * @return {Promise} zipfile
	   */

		}, {
			key: "openUrl",
			value: function openUrl(zipUrl, isBase64) {
				return request(zipUrl, "binary").then(function (data) {
					return this.zip.loadAsync(data, { "base64": isBase64 });
				}.bind(this));
			}

			/**
	   * Request a url from the archive
	   * @param  {string} url  a url to request from the archive
	   * @param  {string} [type] specify the type of the returned result
	   * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	   */

		}, {
			key: "request",
			value: function request$$1(url, type$$1) {
				var deferred = new defer();
				var response;
				var path = new Path(url);

				// If type isn't set, determine it from the file extension
				if (!type$$1) {
					type$$1 = path.extension;
				}

				if (type$$1 == "blob") {
					response = this.getBlob(url);
				} else {
					response = this.getText(url);
				}

				if (response) {
					response.then(function (r) {
						var result = this.handleResponse(r, type$$1);
						deferred.resolve(result);
					}.bind(this));
				} else {
					deferred.reject({
						message: "File not found in the epub: " + url,
						stack: new Error().stack
					});
				}
				return deferred.promise;
			}

			/**
	   * Handle the response from request
	   * @private
	   * @param  {any} response
	   * @param  {string} [type]
	   * @return {any} the parsed result
	   */

		}, {
			key: "handleResponse",
			value: function handleResponse(response, type$$1) {
				var r;

				if (type$$1 == "json") {
					r = JSON.parse(response);
				} else if (isXml(type$$1)) {
					r = parse(response, "text/xml");
				} else if (type$$1 == "xhtml") {
					r = parse(response, "application/xhtml+xml");
				} else if (type$$1 == "html" || type$$1 == "htm") {
					r = parse(response, "text/html");
				} else {
					r = response;
				}

				return r;
			}

			/**
	   * Get a Blob from Archive by Url
	   * @param  {string} url
	   * @param  {string} [mimeType]
	   * @return {Blob}
	   */

		}, {
			key: "getBlob",
			value: function getBlob(url, mimeType) {
				var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
				var entry = this.zip.file(decodededUrl);

				if (entry) {
					mimeType = mimeType || mime.lookup(entry.name);
					return entry.async("uint8array").then(function (uint8array) {
						return new Blob([uint8array], { type: mimeType });
					});
				}
			}

			/**
	   * Get Text from Archive by Url
	   * @param  {string} url
	   * @param  {string} [encoding]
	   * @return {string}
	   */

		}, {
			key: "getText",
			value: function getText(url, encoding) {
				var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
				var entry = this.zip.file(decodededUrl);

				if (entry) {
					return entry.async("string").then(function (text) {
						return text;
					});
				}
			}

			/**
	   * Get a base64 encoded result from Archive by Url
	   * @param  {string} url
	   * @param  {string} [mimeType]
	   * @return {string} base64 encoded
	   */

		}, {
			key: "getBase64",
			value: function getBase64(url, mimeType) {
				var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
				var entry = this.zip.file(decodededUrl);

				if (entry) {
					mimeType = mimeType || mime.lookup(entry.name);
					return entry.async("base64").then(function (data) {
						return "data:" + mimeType + ";base64," + data;
					});
				}
			}

			/**
	   * Create a Url from an unarchived item
	   * @param  {string} url
	   * @param  {object} [options.base64] use base64 encoding or blob url
	   * @return {Promise} url promise with Url string
	   */

		}, {
			key: "createUrl",
			value: function createUrl(url, options) {
				var deferred = new defer();
				var _URL = window.URL || window.webkitURL || window.mozURL;
				var tempUrl;
				var response;
				var useBase64 = options && options.base64;

				if (url in this.urlCache) {
					deferred.resolve(this.urlCache[url]);
					return deferred.promise;
				}

				if (useBase64) {
					response = this.getBase64(url);

					if (response) {
						response.then(function (tempUrl) {

							this.urlCache[url] = tempUrl;
							deferred.resolve(tempUrl);
						}.bind(this));
					}
				} else {

					response = this.getBlob(url);

					if (response) {
						response.then(function (blob) {

							tempUrl = _URL.createObjectURL(blob);
							this.urlCache[url] = tempUrl;
							deferred.resolve(tempUrl);
						}.bind(this));
					}
				}

				if (!response) {
					deferred.reject({
						message: "File not found in the epub: " + url,
						stack: new Error().stack
					});
				}

				return deferred.promise;
			}

			/**
	   * Revoke Temp Url for a achive item
	   * @param  {string} url url of the item in the archive
	   */

		}, {
			key: "revokeUrl",
			value: function revokeUrl(url) {
				var _URL = window.URL || window.webkitURL || window.mozURL;
				var fromCache = this.urlCache[url];
				if (fromCache) _URL.revokeObjectURL(fromCache);
			}
		}, {
			key: "destroy",
			value: function destroy() {
				var _URL = window.URL || window.webkitURL || window.mozURL;
				for (var fromCache in this.urlCache) {
					_URL.revokeObjectURL(fromCache);
				}
				this.zip = undefined;
				this.urlCache = {};
			}
		}]);

		return Archive;
	}();

	var _createClass$s = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$s(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	/**
	 * Handles saving and requesting files from local storage
	 * @class
	 * @param {string} name This should be the name of the application for modals
	 * @param {function} [requester]
	 * @param {function} [resolver]
	 */

	var Store = function () {
		function Store(name, requester, resolver) {
			_classCallCheck$s(this, Store);

			this.urlCache = {};

			this.storage = undefined;

			this.name = name;
			this.requester = requester || request;
			this.resolver = resolver;

			this.online = true;

			this.checkRequirements();

			this.addListeners();
		}

		/**
	  * Checks to see if localForage exists in global namspace,
	  * Requires localForage if it isn't there
	  * @private
	  */


		_createClass$s(Store, [{
			key: "checkRequirements",
			value: function checkRequirements() {
				try {
					var store = void 0;
					if (typeof localforage === "undefined") {
						store = require("localforage");
					} else {
						store = localforage;
					}
					this.storage = store.createInstance({
						name: this.name
					});
				} catch (e) {
					throw new Error("localForage lib not loaded");
				}
			}

			/**
	   * Add online and offline event listeners
	   * @private
	   */

		}, {
			key: "addListeners",
			value: function addListeners() {
				this._status = this.status.bind(this);
				window.addEventListener('online', this._status);
				window.addEventListener('offline', this._status);
			}

			/**
	   * Remove online and offline event listeners
	   * @private
	   */

		}, {
			key: "removeListeners",
			value: function removeListeners() {
				window.removeEventListener('online', this._status);
				window.removeEventListener('offline', this._status);
				this._status = undefined;
			}

			/**
	   * Update the online / offline status
	   * @private
	   */

		}, {
			key: "status",
			value: function status(event) {
				var online = navigator.onLine;
				this.online = online;
				if (online) {
					this.emit("online", this);
				} else {
					this.emit("offline", this);
				}
			}

			/**
	   * Add all of a book resources to the store
	   * @param  {Resources} resources  book resources
	   * @param  {boolean} [force] force resaving resources
	   * @return {Promise<object>} store objects
	   */

		}, {
			key: "add",
			value: function add(resources, force) {
				var _this = this;

				var mapped = resources.resources.map(function (item) {
					var href = item.href;

					var url = _this.resolver(href);
					var encodedUrl = window.encodeURIComponent(url);

					return _this.storage.getItem(encodedUrl).then(function (item) {
						if (!item || force) {
							return _this.requester(url, "binary").then(function (data) {
								return _this.storage.setItem(encodedUrl, data);
							});
						} else {
							return item;
						}
					});
				});
				return Promise.all(mapped);
			}

			/**
	   * Put binary data from a url to storage
	   * @param  {string} url  a url to request from storage
	   * @param  {boolean} [withCredentials]
	   * @param  {object} [headers]
	   * @return {Promise<Blob>}
	   */

		}, {
			key: "put",
			value: function put(url, withCredentials, headers) {
				var _this2 = this;

				var encodedUrl = window.encodeURIComponent(url);

				return this.storage.getItem(encodedUrl).then(function (result) {
					if (!result) {
						return _this2.requester(url, "binary", withCredentials, headers).then(function (data) {
							return _this2.storage.setItem(encodedUrl, data);
						});
					}
					return result;
				});
			}

			/**
	   * Request a url
	   * @param  {string} url  a url to request from storage
	   * @param  {string} [type] specify the type of the returned result
	   * @param  {boolean} [withCredentials]
	   * @param  {object} [headers]
	   * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	   */

		}, {
			key: "request",
			value: function request$$1(url, type$$1, withCredentials, headers) {
				var _this3 = this;

				if (this.online) {
					// From network
					return this.requester(url, type$$1, withCredentials, headers).then(function (data) {
						// save to store if not present
						_this3.put(url);
						return data;
					});
				} else {
					// From store
					return this.retrieve(url, type$$1);
				}
			}

			/**
	   * Request a url from storage
	   * @param  {string} url  a url to request from storage
	   * @param  {string} [type] specify the type of the returned result
	   * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	   */

		}, {
			key: "retrieve",
			value: function retrieve(url, type$$1) {
				var _this4 = this;

				var deferred = new defer();
				var response;
				var path = new Path(url);

				// If type isn't set, determine it from the file extension
				if (!type$$1) {
					type$$1 = path.extension;
				}

				if (type$$1 == "blob") {
					response = this.getBlob(url);
				} else {
					response = this.getText(url);
				}

				return response.then(function (r) {
					var deferred = new defer();
					var result;
					if (r) {
						result = _this4.handleResponse(r, type$$1);
						deferred.resolve(result);
					} else {
						deferred.reject({
							message: "File not found in storage: " + url,
							stack: new Error().stack
						});
					}
					return deferred.promise;
				});
			}

			/**
	   * Handle the response from request
	   * @private
	   * @param  {any} response
	   * @param  {string} [type]
	   * @return {any} the parsed result
	   */

		}, {
			key: "handleResponse",
			value: function handleResponse(response, type$$1) {
				var r;

				if (type$$1 == "json") {
					r = JSON.parse(response);
				} else if (isXml(type$$1)) {
					r = parse(response, "text/xml");
				} else if (type$$1 == "xhtml") {
					r = parse(response, "application/xhtml+xml");
				} else if (type$$1 == "html" || type$$1 == "htm") {
					r = parse(response, "text/html");
				} else {
					r = response;
				}

				return r;
			}

			/**
	   * Get a Blob from Storage by Url
	   * @param  {string} url
	   * @param  {string} [mimeType]
	   * @return {Blob}
	   */

		}, {
			key: "getBlob",
			value: function getBlob(url, mimeType) {
				var encodedUrl = window.encodeURIComponent(url);

				return this.storage.getItem(encodedUrl).then(function (uint8array) {
					if (!uint8array) return;

					mimeType = mimeType || mime.lookup(url);

					return new Blob([uint8array], { type: mimeType });
				});
			}

			/**
	   * Get Text from Storage by Url
	   * @param  {string} url
	   * @param  {string} [mimeType]
	   * @return {string}
	   */

		}, {
			key: "getText",
			value: function getText(url, mimeType) {
				var encodedUrl = window.encodeURIComponent(url);

				mimeType = mimeType || mime.lookup(url);

				return this.storage.getItem(encodedUrl).then(function (uint8array) {
					var deferred = new defer();
					var reader = new FileReader();
					var blob;

					if (!uint8array) return;

					blob = new Blob([uint8array], { type: mimeType });

					reader.addEventListener("loadend", function () {
						deferred.resolve(reader.result);
					});

					reader.readAsText(blob, mimeType);

					return deferred.promise;
				});
			}

			/**
	   * Get a base64 encoded result from Storage by Url
	   * @param  {string} url
	   * @param  {string} [mimeType]
	   * @return {string} base64 encoded
	   */

		}, {
			key: "getBase64",
			value: function getBase64(url, mimeType) {
				var encodedUrl = window.encodeURIComponent(url);

				mimeType = mimeType || mime.lookup(url);

				return this.storage.getItem(encodedUrl).then(function (uint8array) {
					var deferred = new defer();
					var reader = new FileReader();
					var blob;

					if (!uint8array) return;

					blob = new Blob([uint8array], { type: mimeType });

					reader.addEventListener("loadend", function () {
						deferred.resolve(reader.result);
					});
					reader.readAsDataURL(blob, mimeType);

					return deferred.promise;
				});
			}

			/**
	   * Create a Url from a stored item
	   * @param  {string} url
	   * @param  {object} [options.base64] use base64 encoding or blob url
	   * @return {Promise} url promise with Url string
	   */

		}, {
			key: "createUrl",
			value: function createUrl(url, options) {
				var deferred = new defer();
				var _URL = window.URL || window.webkitURL || window.mozURL;
				var tempUrl;
				var response;
				var useBase64 = options && options.base64;

				if (url in this.urlCache) {
					deferred.resolve(this.urlCache[url]);
					return deferred.promise;
				}

				if (useBase64) {
					response = this.getBase64(url);

					if (response) {
						response.then(function (tempUrl) {

							this.urlCache[url] = tempUrl;
							deferred.resolve(tempUrl);
						}.bind(this));
					}
				} else {

					response = this.getBlob(url);

					if (response) {
						response.then(function (blob) {

							tempUrl = _URL.createObjectURL(blob);
							this.urlCache[url] = tempUrl;
							deferred.resolve(tempUrl);
						}.bind(this));
					}
				}

				if (!response) {
					deferred.reject({
						message: "File not found in storage: " + url,
						stack: new Error().stack
					});
				}

				return deferred.promise;
			}

			/**
	   * Revoke Temp Url for a achive item
	   * @param  {string} url url of the item in the store
	   */

		}, {
			key: "revokeUrl",
			value: function revokeUrl(url) {
				var _URL = window.URL || window.webkitURL || window.mozURL;
				var fromCache = this.urlCache[url];
				if (fromCache) _URL.revokeObjectURL(fromCache);
			}
		}, {
			key: "destroy",
			value: function destroy() {
				var _URL = window.URL || window.webkitURL || window.mozURL;
				for (var fromCache in this.urlCache) {
					_URL.revokeObjectURL(fromCache);
				}
				this.urlCache = {};
				this.removeListeners();
			}
		}]);

		return Store;
	}();

	eventEmitter(Store.prototype);

	var _createClass$t = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$t(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var CONTAINER_PATH = "META-INF/container.xml";

	var INPUT_TYPE = {
		BINARY: "binary",
		BASE64: "base64",
		EPUB: "epub",
		OPF: "opf",
		MANIFEST: "json",
		DIRECTORY: "directory"
	};

	/**
	 * An Epub representation with methods for the loading, parsing and manipulation
	 * of its contents.
	 * @class
	 * @param {string} [url]
	 * @param {object} [options]
	 * @param {method} [options.requestMethod] a request function to use instead of the default
	 * @param {boolean} [options.requestCredentials=undefined] send the xhr request withCredentials
	 * @param {object} [options.requestHeaders=undefined] send the xhr request headers
	 * @param {string} [options.encoding=binary] optional to pass 'binary' or base64' for archived Epubs
	 * @param {string} [options.replacements=none] use base64, blobUrl, or none for replacing assets in archived Epubs
	 * @param {method} [options.canonical] optional function to determine canonical urls for a path
	 * @param {string} [options.openAs] optional string to determine the input type
	 * @param {string} [options.store=false] cache the contents in local storage, value should be the name of the reader
	 * @returns {Book}
	 * @example new Book("/path/to/book.epub", {})
	 * @example new Book({ replacements: "blobUrl" })
	 */

	var Book = function () {
		function Book(url, options) {
			var _this = this;

			_classCallCheck$t(this, Book);

			// Allow passing just options to the Book
			if (typeof options === "undefined" && typeof url !== "string" && url instanceof Blob === false) {
				options = url;
				url = undefined;
			}

			this.settings = extend$1(this.settings || {}, {
				requestMethod: undefined,
				requestCredentials: undefined,
				requestHeaders: undefined,
				encoding: undefined,
				replacements: undefined,
				canonical: undefined,
				openAs: undefined,
				store: undefined
			});

			extend$1(this.settings, options);

			// Promises
			this.opening = new defer();
			/**
	   * @member {promise} opened returns after the book is loaded
	   * @memberof Book
	   */
			this.opened = this.opening.promise;
			this.isOpen = false;

			this.loading = {
				manifest: new defer(),
				spine: new defer(),
				metadata: new defer(),
				cover: new defer(),
				navigation: new defer(),
				pageList: new defer(),
				resources: new defer()
			};

			this.loaded = {
				manifest: this.loading.manifest.promise,
				spine: this.loading.spine.promise,
				metadata: this.loading.metadata.promise,
				cover: this.loading.cover.promise,
				navigation: this.loading.navigation.promise,
				pageList: this.loading.pageList.promise,
				resources: this.loading.resources.promise
			};

			/**
	   * @member {promise} ready returns after the book is loaded and parsed
	   * @memberof Book
	   * @private
	   */
			this.ready = Promise.all([this.loaded.manifest, this.loaded.spine, this.loaded.metadata, this.loaded.cover, this.loaded.navigation, this.loaded.resources]);

			// Queue for methods used before opening
			this.isRendered = false;
			// this._q = queue(this);

			/**
	   * @member {method} request
	   * @memberof Book
	   * @private
	   */
			this.request = this.settings.requestMethod || request;

			/**
	   * @member {Spine} spine
	   * @memberof Book
	   */
			this.spine = new Spine();

			/**
	   * @member {Locations} locations
	   * @memberof Book
	   */
			this.locations = new Locations(this.spine, this.load.bind(this));

			/**
	   * @member {Navigation} navigation
	   * @memberof Book
	   */
			this.navigation = undefined;

			/**
	   * @member {PageList} pagelist
	   * @memberof Book
	   */
			this.pageList = undefined;

			/**
	   * @member {Url} url
	   * @memberof Book
	   * @private
	   */
			this.url = undefined;

			/**
	   * @member {Path} path
	   * @memberof Book
	   * @private
	   */
			this.path = undefined;

			/**
	   * @member {boolean} archived
	   * @memberof Book
	   * @private
	   */
			this.archived = false;

			/**
	   * @member {Archive} archive
	   * @memberof Book
	   * @private
	   */
			this.archive = undefined;

			/**
	   * @member {Store} storage
	   * @memberof Book
	   * @private
	   */
			this.storage = undefined;

			/**
	   * @member {Resources} resources
	   * @memberof Book
	   * @private
	   */
			this.resources = undefined;

			/**
	   * @member {Rendition} rendition
	   * @memberof Book
	   * @private
	   */
			this.rendition = undefined;

			/**
	   * @member {Container} container
	   * @memberof Book
	   * @private
	   */
			this.container = undefined;

			/**
	   * @member {Packaging} packaging
	   * @memberof Book
	   * @private
	   */
			this.packaging = undefined;

			// this.toc = undefined;
			if (this.settings.store) {
				this.store(this.settings.store);
			}

			if (url) {
				this.open(url, this.settings.openAs).catch(function (error) {
					var err = new Error("Cannot load book at " + url);
					_this.emit(EVENTS.BOOK.OPEN_FAILED, err);
				});
			}
		}

		/**
	  * Open a epub or url
	  * @param {string | ArrayBuffer} input Url, Path or ArrayBuffer
	  * @param {string} [what="binary", "base64", "epub", "opf", "json", "directory"] force opening as a certain type
	  * @returns {Promise} of when the book has been loaded
	  * @example book.open("/path/to/book.epub")
	  */


		_createClass$t(Book, [{
			key: "open",
			value: function open(input, what) {
				var opening;
				var type$$1 = what || this.determineType(input);

				if (type$$1 === INPUT_TYPE.BINARY) {
					this.archived = true;
					this.url = new Url("/", "");
					opening = this.openEpub(input);
				} else if (type$$1 === INPUT_TYPE.BASE64) {
					this.archived = true;
					this.url = new Url("/", "");
					opening = this.openEpub(input, type$$1);
				} else if (type$$1 === INPUT_TYPE.EPUB) {
					this.archived = true;
					this.url = new Url("/", "");
					opening = this.request(input, "binary", this.settings.requestCredentials).then(this.openEpub.bind(this));
				} else if (type$$1 == INPUT_TYPE.OPF) {
					this.url = new Url(input);
					opening = this.openPackaging(this.url.Path.toString());
				} else if (type$$1 == INPUT_TYPE.MANIFEST) {
					this.url = new Url(input);
					opening = this.openManifest(this.url.Path.toString());
				} else {
					this.url = new Url(input);
					opening = this.openContainer(CONTAINER_PATH).then(this.openPackaging.bind(this));
				}

				return opening;
			}

			/**
	   * Open an archived epub
	   * @private
	   * @param  {binary} data
	   * @param  {string} [encoding]
	   * @return {Promise}
	   */

		}, {
			key: "openEpub",
			value: function openEpub(data, encoding) {
				var _this2 = this;

				return this.unarchive(data, encoding || this.settings.encoding).then(function () {
					return _this2.openContainer(CONTAINER_PATH);
				}).then(function (packagePath) {
					return _this2.openPackaging(packagePath);
				});
			}

			/**
	   * Open the epub container
	   * @private
	   * @param  {string} url
	   * @return {string} packagePath
	   */

		}, {
			key: "openContainer",
			value: function openContainer(url) {
				var _this3 = this;

				return this.load(url).then(function (xml) {
					_this3.container = new Container(xml);
					return _this3.resolve(_this3.settings.packagePath || _this3.container.packagePath);
					// return this.resolve(this.container.packagePath);
				});
			}

			/**
	   * Open the Open Packaging Format Xml
	   * @private
	   * @param  {string} url
	   * @return {Promise}
	   */

		}, {
			key: "openPackaging",
			value: function openPackaging(url) {
				var _this4 = this;

				this.path = new Path(url);
				return this.load(url).then(function (xml) {
					_this4.packaging = new Packaging(xml);
					return _this4.unpack(_this4.packaging);
				});
			}

			/**
	   * Open the manifest JSON
	   * @private
	   * @param  {string} url
	   * @return {Promise}
	   */

		}, {
			key: "openManifest",
			value: function openManifest(url) {
				var _this5 = this;

				this.path = new Path(url);
				return this.load(url).then(function (json) {
					_this5.packaging = new Packaging();
					_this5.packaging.load(json);
					return _this5.unpack(_this5.packaging);
				});
			}

			/**
	   * Load a resource from the Book
	   * @param  {string} path path to the resource to load
	   * @return {Promise}     returns a promise with the requested resource
	   */

		}, {
			key: "load",
			value: function load(path) {
				var resolved = this.resolve(path);
				if (this.archived) {
					return this.archive.request(resolved);
				} else {
					return this.request(resolved, null, this.settings.requestCredentials, this.settings.requestHeaders);
				}
			}

			/**
	   * Resolve a path to it's absolute position in the Book
	   * @param  {string} path
	   * @param  {boolean} [absolute] force resolving the full URL
	   * @return {string}          the resolved path string
	   */

		}, {
			key: "resolve",
			value: function resolve(path, absolute) {
				if (!path) {
					return;
				}
				var resolved = path;
				var isAbsolute = path.indexOf("://") > -1;

				if (isAbsolute) {
					return path;
				}

				if (this.path) {
					resolved = this.path.resolve(path);
				}

				if (absolute != false && this.url) {
					resolved = this.url.resolve(resolved);
				}

				return resolved;
			}

			/**
	   * Get a canonical link to a path
	   * @param  {string} path
	   * @return {string} the canonical path string
	   */

		}, {
			key: "canonical",
			value: function canonical(path) {
				var url = path;

				if (!path) {
					return "";
				}

				if (this.settings.canonical) {
					url = this.settings.canonical(path);
				} else {
					url = this.resolve(path, true);
				}

				return url;
			}

			/**
	   * Determine the type of they input passed to open
	   * @private
	   * @param  {string} input
	   * @return {string}  binary | directory | epub | opf
	   */

		}, {
			key: "determineType",
			value: function determineType(input) {
				var url;
				var path;
				var extension;

				if (this.settings.encoding === "base64") {
					return INPUT_TYPE.BASE64;
				}

				if (typeof input != "string") {
					return INPUT_TYPE.BINARY;
				}

				url = new Url(input);
				path = url.path();
				extension = path.extension;

				if (!extension) {
					return INPUT_TYPE.DIRECTORY;
				}

				if (extension === "epub") {
					return INPUT_TYPE.EPUB;
				}

				if (extension === "opf") {
					return INPUT_TYPE.OPF;
				}

				if (extension === "json") {
					return INPUT_TYPE.MANIFEST;
				}
			}

			/**
	   * unpack the contents of the Books packaging
	   * @private
	   * @param {Packaging} packaging object
	   */

		}, {
			key: "unpack",
			value: function unpack(packaging) {
				var _this6 = this;

				this.package = packaging; //TODO: deprecated this

				this.spine.unpack(this.packaging, this.resolve.bind(this), this.canonical.bind(this));

				this.resources = new Resources(this.packaging.manifest, {
					archive: this.archive,
					resolver: this.resolve.bind(this),
					request: this.request.bind(this),
					replacements: this.settings.replacements || (this.archived ? "blobUrl" : "base64")
				});

				this.loadNavigation(this.packaging).then(function () {
					// this.toc = this.navigation.toc;
					_this6.loading.navigation.resolve(_this6.navigation);
				});

				if (this.packaging.coverPath) {
					this.cover = this.resolve(this.packaging.coverPath);
				}
				// Resolve promises
				this.loading.manifest.resolve(this.packaging.manifest);
				this.loading.metadata.resolve(this.packaging.metadata);
				this.loading.spine.resolve(this.spine);
				this.loading.cover.resolve(this.cover);
				this.loading.resources.resolve(this.resources);
				this.loading.pageList.resolve(this.pageList);

				this.isOpen = true;

				if (this.archived || this.settings.replacements && this.settings.replacements != "none") {
					this.replacements().then(function () {
						_this6.opening.resolve(_this6);
					}).catch(function (err) {
						console.error(err);
					});
				} else {
					// Resolve book opened promise
					this.opening.resolve(this);
				}
			}

			/**
	   * Load Navigation and PageList from package
	   * @private
	   * @param {Packaging} packaging
	   */

		}, {
			key: "loadNavigation",
			value: function loadNavigation(packaging) {
				var _this7 = this;

				var navPath = packaging.navPath || packaging.ncxPath;
				var toc = packaging.toc;

				// From json manifest
				if (toc) {
					return new Promise(function (resolve, reject) {
						_this7.navigation = new Navigation(toc);

						if (packaging.pageList) {
							_this7.pageList = new PageList(packaging.pageList); // TODO: handle page lists from Manifest
						}

						resolve(_this7.navigation);
					});
				}

				if (!navPath) {
					return new Promise(function (resolve, reject) {
						_this7.navigation = new Navigation();
						_this7.pageList = new PageList();

						resolve(_this7.navigation);
					});
				}

				return this.load(navPath, "xml").then(function (xml) {
					_this7.navigation = new Navigation(xml);
					_this7.pageList = new PageList(xml);
					return _this7.navigation;
				});
			}

			/**
	   * Gets a Section of the Book from the Spine
	   * Alias for `book.spine.get`
	   * @param {string} target
	   * @return {Section}
	   */

		}, {
			key: "section",
			value: function section(target) {
				return this.spine.get(target);
			}

			/**
	   * Sugar to render a book to an element
	   * @param  {element | string} element element or string to add a rendition to
	   * @param  {object} [options]
	   * @return {Rendition}
	   */

		}, {
			key: "renderTo",
			value: function renderTo(element, options) {
				this.rendition = new Rendition(this, options);
				this.rendition.attachTo(element);

				return this.rendition;
			}

			/**
	   * Set if request should use withCredentials
	   * @param {boolean} credentials
	   */

		}, {
			key: "setRequestCredentials",
			value: function setRequestCredentials(credentials) {
				this.settings.requestCredentials = credentials;
			}

			/**
	   * Set headers request should use
	   * @param {object} headers
	   */

		}, {
			key: "setRequestHeaders",
			value: function setRequestHeaders(headers) {
				this.settings.requestHeaders = headers;
			}

			/**
	   * Unarchive a zipped epub
	   * @private
	   * @param  {binary} input epub data
	   * @param  {string} [encoding]
	   * @return {Archive}
	   */

		}, {
			key: "unarchive",
			value: function unarchive(input, encoding) {
				this.archive = new Archive();
				return this.archive.open(input, encoding);
			}

			/**
	   * Store the epubs contents
	   * @private
	   * @param  {binary} input epub data
	   * @param  {string} [encoding]
	   * @return {Store}
	   */

		}, {
			key: "store",
			value: function store(name) {
				var _this8 = this;

				// Use "blobUrl" or "base64" for replacements
				var replacementsSetting = this.settings.replacements && this.settings.replacements !== "none";
				// Save original url
				var originalUrl = this.url;
				// Save original request method
				var requester = this.settings.requestMethod || request.bind(this);
				// Create new Store
				this.storage = new Store(name, requester, this.resolve.bind(this));
				// Replace request method to go through store
				this.request = this.storage.request.bind(this.storage);

				this.opened.then(function () {
					if (_this8.archived) {
						_this8.storage.requester = _this8.archive.request.bind(_this8.archive);
					}
					// Substitute hook
					var substituteResources = function substituteResources(output, section) {
						section.output = _this8.resources.substitute(output, section.url);
					};

					// Set to use replacements
					_this8.resources.settings.replacements = replacementsSetting || "blobUrl";
					// Create replacement urls
					_this8.resources.replacements().then(function () {
						return _this8.resources.replaceCss();
					});

					_this8.storage.on("offline", function () {
						// Remove url to use relative resolving for hrefs
						_this8.url = new Url("/", "");
						// Add hook to replace resources in contents
						_this8.spine.hooks.serialize.register(substituteResources);
					});

					_this8.storage.on("online", function () {
						// Restore original url
						_this8.url = originalUrl;
						// Remove hook
						_this8.spine.hooks.serialize.deregister(substituteResources);
					});
				});

				return this.storage;
			}

			/**
	   * Get the cover url
	   * @return {string} coverUrl
	   */

		}, {
			key: "coverUrl",
			value: function coverUrl() {
				var _this9 = this;

				var retrieved = this.loaded.cover.then(function (url) {
					if (_this9.archived) {
						// return this.archive.createUrl(this.cover);
						return _this9.resources.get(_this9.cover);
					} else {
						return _this9.cover;
					}
				});

				return retrieved;
			}

			/**
	   * Load replacement urls
	   * @private
	   * @return {Promise} completed loading urls
	   */

		}, {
			key: "replacements",
			value: function replacements() {
				var _this10 = this;

				this.spine.hooks.serialize.register(function (output, section) {
					section.output = _this10.resources.substitute(output, section.url);
				});

				return this.resources.replacements().then(function () {
					return _this10.resources.replaceCss();
				});
			}

			/**
	   * Find a DOM Range for a given CFI Range
	   * @param  {EpubCFI} cfiRange a epub cfi range
	   * @return {Range}
	   */

		}, {
			key: "getRange",
			value: function getRange(cfiRange) {
				var cfi = new EpubCFI(cfiRange);
				var item = this.spine.get(cfi.spinePos);
				var _request = this.load.bind(this);
				if (!item) {
					return new Promise(function (resolve, reject) {
						reject("CFI could not be found");
					});
				}
				return item.load(_request).then(function (contents) {
					var range = cfi.toRange(item.document);
					return range;
				});
			}

			/**
	   * Generates the Book Key using the identifer in the manifest or other string provided
	   * @param  {string} [identifier] to use instead of metadata identifier
	   * @return {string} key
	   */

		}, {
			key: "key",
			value: function key(identifier) {
				var ident = identifier || this.packaging.metadata.identifier || this.url.filename;
				return "epubjs:" + EPUBJS_VERSION + ":" + ident;
			}

			/**
	   * Destroy the Book and all associated objects
	   */

		}, {
			key: "destroy",
			value: function destroy() {
				this.opened = undefined;
				this.loading = undefined;
				this.loaded = undefined;
				this.ready = undefined;

				this.isOpen = false;
				this.isRendered = false;

				this.spine && this.spine.destroy();
				this.locations && this.locations.destroy();
				this.pageList && this.pageList.destroy();
				this.archive && this.archive.destroy();
				this.resources && this.resources.destroy();
				this.container && this.container.destroy();
				this.packaging && this.packaging.destroy();
				this.rendition && this.rendition.destroy();

				this.spine = undefined;
				this.locations = undefined;
				this.pageList = undefined;
				this.archive = undefined;
				this.resources = undefined;
				this.container = undefined;
				this.packaging = undefined;
				this.rendition = undefined;

				this.navigation = undefined;
				this.url = undefined;
				this.path = undefined;
				this.archived = false;
			}
		}]);

		return Book;
	}();

	//-- Enable binding events to book


	eventEmitter(Book.prototype);

	var urlPolyfill$1 = createCommonjsModule(function (module) {

	var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

	(function (root, factory) {
	  // Fix for this being undefined in modules
	  if (!root) {
	    root = window || commonjsGlobal;
	  }
	  if ((_typeof(module)) === 'object' && module.exports) {
	    // Node
	    module.exports = factory(root);
	  } else {
	    // Browser globals (root is window)
	    root.URL = factory(root);
	  }
	})(commonjsGlobal, function (scope) {
	  // feature detect for URL constructor
	  var hasWorkingUrl = false;
	  if (!scope.forceJURL) {
	    try {
	      var u = new URL('b', 'http://a');
	      u.pathname = 'c%20d';
	      hasWorkingUrl = u.href === 'http://a/c%20d';
	    } catch (e) {}
	  }

	  if (hasWorkingUrl) return scope.URL;

	  var relative = Object.create(null);
	  relative['ftp'] = 21;
	  relative['file'] = 0;
	  relative['gopher'] = 70;
	  relative['http'] = 80;
	  relative['https'] = 443;
	  relative['ws'] = 80;
	  relative['wss'] = 443;

	  var relativePathDotMapping = Object.create(null);
	  relativePathDotMapping['%2e'] = '.';
	  relativePathDotMapping['.%2e'] = '..';
	  relativePathDotMapping['%2e.'] = '..';
	  relativePathDotMapping['%2e%2e'] = '..';

	  function isRelativeScheme(scheme) {
	    return relative[scheme] !== undefined;
	  }

	  function invalid() {
	    clear.call(this);
	    this._isInvalid = true;
	  }

	  function IDNAToASCII(h) {
	    if ('' == h) {
	      invalid.call(this);
	    }
	    // XXX
	    return h.toLowerCase();
	  }

	  function percentEscape(c) {
	    var unicode = c.charCodeAt(0);
	    if (unicode > 0x20 && unicode < 0x7F &&
	    // " # < > ? `
	    [0x22, 0x23, 0x3C, 0x3E, 0x3F, 0x60].indexOf(unicode) == -1) {
	      return c;
	    }
	    return encodeURIComponent(c);
	  }

	  function percentEscapeQuery(c) {
	    // XXX This actually needs to encode c using encoding and then
	    // convert the bytes one-by-one.

	    var unicode = c.charCodeAt(0);
	    if (unicode > 0x20 && unicode < 0x7F &&
	    // " # < > ` (do not escape '?')
	    [0x22, 0x23, 0x3C, 0x3E, 0x60].indexOf(unicode) == -1) {
	      return c;
	    }
	    return encodeURIComponent(c);
	  }

	  var EOF = undefined,
	      ALPHA = /[a-zA-Z]/,
	      ALPHANUMERIC = /[a-zA-Z0-9\+\-\.]/;

	  function parse(input, stateOverride, base) {

	    var state = stateOverride || 'scheme start',
	        cursor = 0,
	        buffer = '',
	        seenAt = false,
	        seenBracket = false;

	    loop: while ((input[cursor - 1] != EOF || cursor == 0) && !this._isInvalid) {
	      var c = input[cursor];
	      switch (state) {
	        case 'scheme start':
	          if (c && ALPHA.test(c)) {
	            buffer += c.toLowerCase(); // ASCII-safe
	            state = 'scheme';
	          } else if (!stateOverride) {
	            buffer = '';
	            state = 'no scheme';
	            continue;
	          } else {
	            break loop;
	          }
	          break;

	        case 'scheme':
	          if (c && ALPHANUMERIC.test(c)) {
	            buffer += c.toLowerCase(); // ASCII-safe
	          } else if (':' == c) {
	            this._scheme = buffer;
	            buffer = '';
	            if (stateOverride) {
	              break loop;
	            }
	            if (isRelativeScheme(this._scheme)) {
	              this._isRelative = true;
	            }
	            if ('file' == this._scheme) {
	              state = 'relative';
	            } else if (this._isRelative && base && base._scheme == this._scheme) {
	              state = 'relative or authority';
	            } else if (this._isRelative) {
	              state = 'authority first slash';
	            } else {
	              state = 'scheme data';
	            }
	          } else if (!stateOverride) {
	            buffer = '';
	            cursor = 0;
	            state = 'no scheme';
	            continue;
	          } else if (EOF == c) {
	            break loop;
	          } else {
	            break loop;
	          }
	          break;

	        case 'scheme data':
	          if ('?' == c) {
	            this._query = '?';
	            state = 'query';
	          } else if ('#' == c) {
	            this._fragment = '#';
	            state = 'fragment';
	          } else {
	            // XXX error handling
	            if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
	              this._schemeData += percentEscape(c);
	            }
	          }
	          break;

	        case 'no scheme':
	          if (!base || !isRelativeScheme(base._scheme)) {
	            invalid.call(this);
	          } else {
	            state = 'relative';
	            continue;
	          }
	          break;

	        case 'relative or authority':
	          if ('/' == c && '/' == input[cursor + 1]) {
	            state = 'authority ignore slashes';
	          } else {
	            state = 'relative';
	            continue;
	          }
	          break;

	        case 'relative':
	          this._isRelative = true;
	          if ('file' != this._scheme) this._scheme = base._scheme;
	          if (EOF == c) {
	            this._host = base._host;
	            this._port = base._port;
	            this._path = base._path.slice();
	            this._query = base._query;
	            this._username = base._username;
	            this._password = base._password;
	            break loop;
	          } else if ('/' == c || '\\' == c) {
	            state = 'relative slash';
	          } else if ('?' == c) {
	            this._host = base._host;
	            this._port = base._port;
	            this._path = base._path.slice();
	            this._query = '?';
	            this._username = base._username;
	            this._password = base._password;
	            state = 'query';
	          } else if ('#' == c) {
	            this._host = base._host;
	            this._port = base._port;
	            this._path = base._path.slice();
	            this._query = base._query;
	            this._fragment = '#';
	            this._username = base._username;
	            this._password = base._password;
	            state = 'fragment';
	          } else {
	            var nextC = input[cursor + 1];
	            var nextNextC = input[cursor + 2];
	            if ('file' != this._scheme || !ALPHA.test(c) || nextC != ':' && nextC != '|' || EOF != nextNextC && '/' != nextNextC && '\\' != nextNextC && '?' != nextNextC && '#' != nextNextC) {
	              this._host = base._host;
	              this._port = base._port;
	              this._username = base._username;
	              this._password = base._password;
	              this._path = base._path.slice();
	              this._path.pop();
	            }
	            state = 'relative path';
	            continue;
	          }
	          break;

	        case 'relative slash':
	          if ('/' == c || '\\' == c) {
	            if ('file' == this._scheme) {
	              state = 'file host';
	            } else {
	              state = 'authority ignore slashes';
	            }
	          } else {
	            if ('file' != this._scheme) {
	              this._host = base._host;
	              this._port = base._port;
	              this._username = base._username;
	              this._password = base._password;
	            }
	            state = 'relative path';
	            continue;
	          }
	          break;

	        case 'authority first slash':
	          if ('/' == c) {
	            state = 'authority second slash';
	          } else {
	            state = 'authority ignore slashes';
	            continue;
	          }
	          break;

	        case 'authority second slash':
	          state = 'authority ignore slashes';
	          if ('/' != c) {
	            continue;
	          }
	          break;

	        case 'authority ignore slashes':
	          if ('/' != c && '\\' != c) {
	            state = 'authority';
	            continue;
	          }
	          break;

	        case 'authority':
	          if ('@' == c) {
	            if (seenAt) {
	              buffer += '%40';
	            }
	            seenAt = true;
	            for (var i = 0; i < buffer.length; i++) {
	              var cp = buffer[i];
	              if ('\t' == cp || '\n' == cp || '\r' == cp) {
	                continue;
	              }
	              // XXX check URL code points
	              if (':' == cp && null === this._password) {
	                this._password = '';
	                continue;
	              }
	              var tempC = percentEscape(cp);
	              null !== this._password ? this._password += tempC : this._username += tempC;
	            }
	            buffer = '';
	          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
	            cursor -= buffer.length;
	            buffer = '';
	            state = 'host';
	            continue;
	          } else {
	            buffer += c;
	          }
	          break;

	        case 'file host':
	          if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
	            if (buffer.length == 2 && ALPHA.test(buffer[0]) && (buffer[1] == ':' || buffer[1] == '|')) {
	              state = 'relative path';
	            } else if (buffer.length == 0) {
	              state = 'relative path start';
	            } else {
	              this._host = IDNAToASCII.call(this, buffer);
	              buffer = '';
	              state = 'relative path start';
	            }
	            continue;
	          } else if ('\t' == c || '\n' == c || '\r' == c) ; else {
	            buffer += c;
	          }
	          break;

	        case 'host':
	        case 'hostname':
	          if (':' == c && !seenBracket) {
	            // XXX host parsing
	            this._host = IDNAToASCII.call(this, buffer);
	            buffer = '';
	            state = 'port';
	            if ('hostname' == stateOverride) {
	              break loop;
	            }
	          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
	            this._host = IDNAToASCII.call(this, buffer);
	            buffer = '';
	            state = 'relative path start';
	            if (stateOverride) {
	              break loop;
	            }
	            continue;
	          } else if ('\t' != c && '\n' != c && '\r' != c) {
	            if ('[' == c) {
	              seenBracket = true;
	            } else if (']' == c) {
	              seenBracket = false;
	            }
	            buffer += c;
	          }
	          break;

	        case 'port':
	          if (/[0-9]/.test(c)) {
	            buffer += c;
	          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c || stateOverride) {
	            if ('' != buffer) {
	              var temp = parseInt(buffer, 10);
	              if (temp != relative[this._scheme]) {
	                this._port = temp + '';
	              }
	              buffer = '';
	            }
	            if (stateOverride) {
	              break loop;
	            }
	            state = 'relative path start';
	            continue;
	          } else if ('\t' == c || '\n' == c || '\r' == c) ; else {
	            invalid.call(this);
	          }
	          break;

	        case 'relative path start':
	          state = 'relative path';
	          if ('/' != c && '\\' != c) {
	            continue;
	          }
	          break;

	        case 'relative path':
	          if (EOF == c || '/' == c || '\\' == c || !stateOverride && ('?' == c || '#' == c)) {
	            var tmp;
	            if (tmp = relativePathDotMapping[buffer.toLowerCase()]) {
	              buffer = tmp;
	            }
	            if ('..' == buffer) {
	              this._path.pop();
	              if ('/' != c && '\\' != c) {
	                this._path.push('');
	              }
	            } else if ('.' == buffer && '/' != c && '\\' != c) {
	              this._path.push('');
	            } else if ('.' != buffer) {
	              if ('file' == this._scheme && this._path.length == 0 && buffer.length == 2 && ALPHA.test(buffer[0]) && buffer[1] == '|') {
	                buffer = buffer[0] + ':';
	              }
	              this._path.push(buffer);
	            }
	            buffer = '';
	            if ('?' == c) {
	              this._query = '?';
	              state = 'query';
	            } else if ('#' == c) {
	              this._fragment = '#';
	              state = 'fragment';
	            }
	          } else if ('\t' != c && '\n' != c && '\r' != c) {
	            buffer += percentEscape(c);
	          }
	          break;

	        case 'query':
	          if (!stateOverride && '#' == c) {
	            this._fragment = '#';
	            state = 'fragment';
	          } else if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
	            this._query += percentEscapeQuery(c);
	          }
	          break;

	        case 'fragment':
	          if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
	            this._fragment += c;
	          }
	          break;
	      }

	      cursor++;
	    }
	  }

	  function clear() {
	    this._scheme = '';
	    this._schemeData = '';
	    this._username = '';
	    this._password = null;
	    this._host = '';
	    this._port = '';
	    this._path = [];
	    this._query = '';
	    this._fragment = '';
	    this._isInvalid = false;
	    this._isRelative = false;
	  }

	  // Does not process domain names or IP addresses.
	  // Does not handle encoding for the query parameter.
	  function jURL(url, base /* , encoding */) {
	    if (base !== undefined && !(base instanceof jURL)) base = new jURL(String(base));

	    this._url = url;
	    clear.call(this);

	    var input = url.replace(/^[ \t\r\n\f]+|[ \t\r\n\f]+$/g, '');
	    // encoding = encoding || 'utf-8'

	    parse.call(this, input, null, base);
	  }

	  jURL.prototype = {
	    toString: function toString() {
	      return this.href;
	    },
	    get href() {
	      if (this._isInvalid) return this._url;

	      var authority = '';
	      if ('' != this._username || null != this._password) {
	        authority = this._username + (null != this._password ? ':' + this._password : '') + '@';
	      }

	      return this.protocol + (this._isRelative ? '//' + authority + this.host : '') + this.pathname + this._query + this._fragment;
	    },
	    set href(href) {
	      clear.call(this);
	      parse.call(this, href);
	    },

	    get protocol() {
	      return this._scheme + ':';
	    },
	    set protocol(protocol) {
	      if (this._isInvalid) return;
	      parse.call(this, protocol + ':', 'scheme start');
	    },

	    get host() {
	      return this._isInvalid ? '' : this._port ? this._host + ':' + this._port : this._host;
	    },
	    set host(host) {
	      if (this._isInvalid || !this._isRelative) return;
	      parse.call(this, host, 'host');
	    },

	    get hostname() {
	      return this._host;
	    },
	    set hostname(hostname) {
	      if (this._isInvalid || !this._isRelative) return;
	      parse.call(this, hostname, 'hostname');
	    },

	    get port() {
	      return this._port;
	    },
	    set port(port) {
	      if (this._isInvalid || !this._isRelative) return;
	      parse.call(this, port, 'port');
	    },

	    get pathname() {
	      return this._isInvalid ? '' : this._isRelative ? '/' + this._path.join('/') : this._schemeData;
	    },
	    set pathname(pathname) {
	      if (this._isInvalid || !this._isRelative) return;
	      this._path = [];
	      parse.call(this, pathname, 'relative path start');
	    },

	    get search() {
	      return this._isInvalid || !this._query || '?' == this._query ? '' : this._query;
	    },
	    set search(search) {
	      if (this._isInvalid || !this._isRelative) return;
	      this._query = '?';
	      if ('?' == search[0]) search = search.slice(1);
	      parse.call(this, search, 'query');
	    },

	    get hash() {
	      return this._isInvalid || !this._fragment || '#' == this._fragment ? '' : this._fragment;
	    },
	    set hash(hash) {
	      if (this._isInvalid) return;
	      this._fragment = '#';
	      if ('#' == hash[0]) hash = hash.slice(1);
	      parse.call(this, hash, 'fragment');
	    },

	    get origin() {
	      var host;
	      if (this._isInvalid || !this._scheme) {
	        return '';
	      }
	      // javascript: Gecko returns String(""), WebKit/Blink String("null")
	      // Gecko throws error for "data://"
	      // data: Gecko returns "", Blink returns "data://", WebKit returns "null"
	      // Gecko returns String("") for file: mailto:
	      // WebKit/Blink returns String("SCHEME://") for file: mailto:
	      switch (this._scheme) {
	        case 'file':
	          return 'file://'; // EPUBJS Added
	        case 'data':
	        case 'javascript':
	        case 'mailto':
	          return 'null';
	      }
	      host = this.host;
	      if (!host) {
	        return '';
	      }
	      return this._scheme + '://' + host;
	    }
	  };

	  // Copy over the static methods
	  var OriginalURL = scope.URL;
	  if (OriginalURL) {
	    jURL.createObjectURL = function (blob) {
	      // IE extension allows a second optional options argument.
	      // http://msdn.microsoft.com/en-us/library/ie/hh772302(v=vs.85).aspx
	      return OriginalURL.createObjectURL.apply(OriginalURL, arguments);
	    };
	    jURL.revokeObjectURL = function (url) {
	      OriginalURL.revokeObjectURL(url);
	    };
	  }

	  return jURL;
	});
	});

	/**
	 * Creates a new Book
	 * @param {string|ArrayBuffer} url URL, Path or ArrayBuffer
	 * @param {object} options to pass to the book
	 * @returns {Book} a new Book object
	 * @example ePub("/path/to/book.epub", {})
	 */
	function ePub(url, options) {
	  return new Book(url, options);
	}

	ePub.VERSION = EPUBJS_VERSION;

	if (typeof global !== "undefined") {
	  global.EPUBJS_VERSION = EPUBJS_VERSION;
	}

	ePub.Book = Book;
	ePub.Rendition = Rendition;
	ePub.Contents = Contents$1;
	ePub.CFI = EpubCFI;
	ePub.utils = utils;

	if (!process$2) {
	  var process$2 = {
	    "cwd" : function () { return '/' }
	  };
	}

	function assertPath$1(path) {
	  if (typeof path !== 'string') {
	    throw new TypeError('Path must be a string. Received ' + path);
	  }
	}

	// Resolves . and .. elements in a path with directory names
	function normalizeStringPosix$1(path, allowAboveRoot) {
	  var res = '';
	  var lastSlash = -1;
	  var dots = 0;
	  var code;
	  for (var i = 0; i <= path.length; ++i) {
	    if (i < path.length)
	      code = path.charCodeAt(i);
	    else if (code === 47/*/*/)
	      break;
	    else
	      code = 47/*/*/;
	    if (code === 47/*/*/) {
	      if (lastSlash === i - 1 || dots === 1) ; else if (lastSlash !== i - 1 && dots === 2) {
	        if (res.length < 2 ||
	            res.charCodeAt(res.length - 1) !== 46/*.*/ ||
	            res.charCodeAt(res.length - 2) !== 46/*.*/) {
	          if (res.length > 2) {
	            var start = res.length - 1;
	            var j = start;
	            for (; j >= 0; --j) {
	              if (res.charCodeAt(j) === 47/*/*/)
	                break;
	            }
	            if (j !== start) {
	              if (j === -1)
	                res = '';
	              else
	                res = res.slice(0, j);
	              lastSlash = i;
	              dots = 0;
	              continue;
	            }
	          } else if (res.length === 2 || res.length === 1) {
	            res = '';
	            lastSlash = i;
	            dots = 0;
	            continue;
	          }
	        }
	        if (allowAboveRoot) {
	          if (res.length > 0)
	            res += '/..';
	          else
	            res = '..';
	        }
	      } else {
	        if (res.length > 0)
	          res += '/' + path.slice(lastSlash + 1, i);
	        else
	          res = path.slice(lastSlash + 1, i);
	      }
	      lastSlash = i;
	      dots = 0;
	    } else if (code === 46/*.*/ && dots !== -1) {
	      ++dots;
	    } else {
	      dots = -1;
	    }
	  }
	  return res;
	}

	function _format$1(sep, pathObject) {
	  var dir = pathObject.dir || pathObject.root;
	  var base = pathObject.base ||
	    ((pathObject.name || '') + (pathObject.ext || ''));
	  if (!dir) {
	    return base;
	  }
	  if (dir === pathObject.root) {
	    return dir + base;
	  }
	  return dir + sep + base;
	}

	var posix$1 = {
	  // path.resolve([from ...], to)
	  resolve: function resolve() {
	    var resolvedPath = '';
	    var resolvedAbsolute = false;
	    var cwd;

	    for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
	      var path;
	      if (i >= 0)
	        path = arguments[i];
	      else {
	        if (cwd === undefined)
	          cwd = process$2.cwd();
	        path = cwd;
	      }

	      assertPath$1(path);

	      // Skip empty entries
	      if (path.length === 0) {
	        continue;
	      }

	      resolvedPath = path + '/' + resolvedPath;
	      resolvedAbsolute = path.charCodeAt(0) === 47/*/*/;
	    }

	    // At this point the path should be resolved to a full absolute path, but
	    // handle relative paths to be safe (might happen when process.cwd() fails)

	    // Normalize the path
	    resolvedPath = normalizeStringPosix$1(resolvedPath, !resolvedAbsolute);

	    if (resolvedAbsolute) {
	      if (resolvedPath.length > 0)
	        return '/' + resolvedPath;
	      else
	        return '/';
	    } else if (resolvedPath.length > 0) {
	      return resolvedPath;
	    } else {
	      return '.';
	    }
	  },


	  normalize: function normalize(path) {
	    assertPath$1(path);

	    if (path.length === 0)
	      return '.';

	    var isAbsolute = path.charCodeAt(0) === 47/*/*/;
	    var trailingSeparator = path.charCodeAt(path.length - 1) === 47/*/*/;

	    // Normalize the path
	    path = normalizeStringPosix$1(path, !isAbsolute);

	    if (path.length === 0 && !isAbsolute)
	      path = '.';
	    if (path.length > 0 && trailingSeparator)
	      path += '/';

	    if (isAbsolute)
	      return '/' + path;
	    return path;
	  },


	  isAbsolute: function isAbsolute(path) {
	    assertPath$1(path);
	    return path.length > 0 && path.charCodeAt(0) === 47/*/*/;
	  },


	  join: function join() {
	    if (arguments.length === 0)
	      return '.';
	    var joined;
	    for (var i = 0; i < arguments.length; ++i) {
	      var arg = arguments[i];
	      assertPath$1(arg);
	      if (arg.length > 0) {
	        if (joined === undefined)
	          joined = arg;
	        else
	          joined += '/' + arg;
	      }
	    }
	    if (joined === undefined)
	      return '.';
	    return posix$1.normalize(joined);
	  },


	  relative: function relative(from, to) {
	    assertPath$1(from);
	    assertPath$1(to);

	    if (from === to)
	      return '';

	    from = posix$1.resolve(from);
	    to = posix$1.resolve(to);

	    if (from === to)
	      return '';

	    // Trim any leading backslashes
	    var fromStart = 1;
	    for (; fromStart < from.length; ++fromStart) {
	      if (from.charCodeAt(fromStart) !== 47/*/*/)
	        break;
	    }
	    var fromEnd = from.length;
	    var fromLen = (fromEnd - fromStart);

	    // Trim any leading backslashes
	    var toStart = 1;
	    for (; toStart < to.length; ++toStart) {
	      if (to.charCodeAt(toStart) !== 47/*/*/)
	        break;
	    }
	    var toEnd = to.length;
	    var toLen = (toEnd - toStart);

	    // Compare paths to find the longest common path from root
	    var length = (fromLen < toLen ? fromLen : toLen);
	    var lastCommonSep = -1;
	    var i = 0;
	    for (; i <= length; ++i) {
	      if (i === length) {
	        if (toLen > length) {
	          if (to.charCodeAt(toStart + i) === 47/*/*/) {
	            // We get here if `from` is the exact base path for `to`.
	            // For example: from='/foo/bar'; to='/foo/bar/baz'
	            return to.slice(toStart + i + 1);
	          } else if (i === 0) {
	            // We get here if `from` is the root
	            // For example: from='/'; to='/foo'
	            return to.slice(toStart + i);
	          }
	        } else if (fromLen > length) {
	          if (from.charCodeAt(fromStart + i) === 47/*/*/) {
	            // We get here if `to` is the exact base path for `from`.
	            // For example: from='/foo/bar/baz'; to='/foo/bar'
	            lastCommonSep = i;
	          } else if (i === 0) {
	            // We get here if `to` is the root.
	            // For example: from='/foo'; to='/'
	            lastCommonSep = 0;
	          }
	        }
	        break;
	      }
	      var fromCode = from.charCodeAt(fromStart + i);
	      var toCode = to.charCodeAt(toStart + i);
	      if (fromCode !== toCode)
	        break;
	      else if (fromCode === 47/*/*/)
	        lastCommonSep = i;
	    }

	    var out = '';
	    // Generate the relative path based on the path difference between `to`
	    // and `from`
	    for (i = fromStart + lastCommonSep + 1; i <= fromEnd; ++i) {
	      if (i === fromEnd || from.charCodeAt(i) === 47/*/*/) {
	        if (out.length === 0)
	          out += '..';
	        else
	          out += '/..';
	      }
	    }

	    // Lastly, append the rest of the destination (`to`) path that comes after
	    // the common path parts
	    if (out.length > 0)
	      return out + to.slice(toStart + lastCommonSep);
	    else {
	      toStart += lastCommonSep;
	      if (to.charCodeAt(toStart) === 47/*/*/)
	        ++toStart;
	      return to.slice(toStart);
	    }
	  },


	  _makeLong: function _makeLong(path) {
	    return path;
	  },


	  dirname: function dirname(path) {
	    assertPath$1(path);
	    if (path.length === 0)
	      return '.';
	    var code = path.charCodeAt(0);
	    var hasRoot = (code === 47/*/*/);
	    var end = -1;
	    var matchedSlash = true;
	    for (var i = path.length - 1; i >= 1; --i) {
	      code = path.charCodeAt(i);
	      if (code === 47/*/*/) {
	        if (!matchedSlash) {
	          end = i;
	          break;
	        }
	      } else {
	        // We saw the first non-path separator
	        matchedSlash = false;
	      }
	    }

	    if (end === -1)
	      return hasRoot ? '/' : '.';
	    if (hasRoot && end === 1)
	      return '//';
	    return path.slice(0, end);
	  },


	  basename: function basename(path, ext) {
	    if (ext !== undefined && typeof ext !== 'string')
	      throw new TypeError('"ext" argument must be a string');
	    assertPath$1(path);

	    var start = 0;
	    var end = -1;
	    var matchedSlash = true;
	    var i;

	    if (ext !== undefined && ext.length > 0 && ext.length <= path.length) {
	      if (ext.length === path.length && ext === path)
	        return '';
	      var extIdx = ext.length - 1;
	      var firstNonSlashEnd = -1;
	      for (i = path.length - 1; i >= 0; --i) {
	        var code = path.charCodeAt(i);
	        if (code === 47/*/*/) {
	          // If we reached a path separator that was not part of a set of path
	          // separators at the end of the string, stop now
	          if (!matchedSlash) {
	            start = i + 1;
	            break;
	          }
	        } else {
	          if (firstNonSlashEnd === -1) {
	            // We saw the first non-path separator, remember this index in case
	            // we need it if the extension ends up not matching
	            matchedSlash = false;
	            firstNonSlashEnd = i + 1;
	          }
	          if (extIdx >= 0) {
	            // Try to match the explicit extension
	            if (code === ext.charCodeAt(extIdx)) {
	              if (--extIdx === -1) {
	                // We matched the extension, so mark this as the end of our path
	                // component
	                end = i;
	              }
	            } else {
	              // Extension does not match, so our result is the entire path
	              // component
	              extIdx = -1;
	              end = firstNonSlashEnd;
	            }
	          }
	        }
	      }

	      if (start === end)
	        end = firstNonSlashEnd;
	      else if (end === -1)
	        end = path.length;
	      return path.slice(start, end);
	    } else {
	      for (i = path.length - 1; i >= 0; --i) {
	        if (path.charCodeAt(i) === 47/*/*/) {
	          // If we reached a path separator that was not part of a set of path
	          // separators at the end of the string, stop now
	          if (!matchedSlash) {
	            start = i + 1;
	            break;
	          }
	        } else if (end === -1) {
	          // We saw the first non-path separator, mark this as the end of our
	          // path component
	          matchedSlash = false;
	          end = i + 1;
	        }
	      }

	      if (end === -1)
	        return '';
	      return path.slice(start, end);
	    }
	  },


	  extname: function extname(path) {
	    assertPath$1(path);
	    var startDot = -1;
	    var startPart = 0;
	    var end = -1;
	    var matchedSlash = true;
	    // Track the state of characters (if any) we see before our first dot and
	    // after any path separator we find
	    var preDotState = 0;
	    for (var i = path.length - 1; i >= 0; --i) {
	      var code = path.charCodeAt(i);
	      if (code === 47/*/*/) {
	        // If we reached a path separator that was not part of a set of path
	        // separators at the end of the string, stop now
	        if (!matchedSlash) {
	          startPart = i + 1;
	          break;
	        }
	        continue;
	      }
	      if (end === -1) {
	        // We saw the first non-path separator, mark this as the end of our
	        // extension
	        matchedSlash = false;
	        end = i + 1;
	      }
	      if (code === 46/*.*/) {
	        // If this is our first dot, mark it as the start of our extension
	        if (startDot === -1)
	          startDot = i;
	        else if (preDotState !== 1)
	          preDotState = 1;
	      } else if (startDot !== -1) {
	        // We saw a non-dot and non-path separator before our dot, so we should
	        // have a good chance at having a non-empty extension
	        preDotState = -1;
	      }
	    }

	    if (startDot === -1 ||
	        end === -1 ||
	        // We saw a non-dot character immediately before the dot
	        preDotState === 0 ||
	        // The (right-most) trimmed path component is exactly '..'
	        (preDotState === 1 &&
	         startDot === end - 1 &&
	         startDot === startPart + 1)) {
	      return '';
	    }
	    return path.slice(startDot, end);
	  },


	  format: function format(pathObject) {
	    if (pathObject === null || typeof pathObject !== 'object') {
	      throw new TypeError(
	        'Parameter "pathObject" must be an object, not ' + typeof(pathObject)
	      );
	    }
	    return _format$1('/', pathObject);
	  },


	  parse: function parse(path) {
	    assertPath$1(path);

	    var ret = { root: '', dir: '', base: '', ext: '', name: '' };
	    if (path.length === 0)
	      return ret;
	    var code = path.charCodeAt(0);
	    var isAbsolute = (code === 47/*/*/);
	    var start;
	    if (isAbsolute) {
	      ret.root = '/';
	      start = 1;
	    } else {
	      start = 0;
	    }
	    var startDot = -1;
	    var startPart = 0;
	    var end = -1;
	    var matchedSlash = true;
	    var i = path.length - 1;

	    // Track the state of characters (if any) we see before our first dot and
	    // after any path separator we find
	    var preDotState = 0;

	    // Get non-dir info
	    for (; i >= start; --i) {
	      code = path.charCodeAt(i);
	      if (code === 47/*/*/) {
	        // If we reached a path separator that was not part of a set of path
	        // separators at the end of the string, stop now
	        if (!matchedSlash) {
	          startPart = i + 1;
	          break;
	        }
	        continue;
	      }
	      if (end === -1) {
	        // We saw the first non-path separator, mark this as the end of our
	        // extension
	        matchedSlash = false;
	        end = i + 1;
	      }
	      if (code === 46/*.*/) {
	        // If this is our first dot, mark it as the start of our extension
	        if (startDot === -1)
	          startDot = i;
	        else if (preDotState !== 1)
	          preDotState = 1;
	      } else if (startDot !== -1) {
	        // We saw a non-dot and non-path separator before our dot, so we should
	        // have a good chance at having a non-empty extension
	        preDotState = -1;
	      }
	    }

	    if (startDot === -1 ||
	        end === -1 ||
	        // We saw a non-dot character immediately before the dot
	        preDotState === 0 ||
	        // The (right-most) trimmed path component is exactly '..'
	        (preDotState === 1 &&
	         startDot === end - 1 &&
	         startDot === startPart + 1)) {
	      if (end !== -1) {
	        if (startPart === 0 && isAbsolute)
	          ret.base = ret.name = path.slice(1, end);
	        else
	          ret.base = ret.name = path.slice(startPart, end);
	      }
	    } else {
	      if (startPart === 0 && isAbsolute) {
	        ret.name = path.slice(1, startDot);
	        ret.base = path.slice(1, end);
	      } else {
	        ret.name = path.slice(startPart, startDot);
	        ret.base = path.slice(startPart, end);
	      }
	      ret.ext = path.slice(startDot, end);
	    }

	    if (startPart > 0)
	      ret.dir = path.slice(0, startPart - 1);
	    else if (isAbsolute)
	      ret.dir = '/';

	    return ret;
	  },


	  sep: '/',
	  delimiter: ':',
	  posix: null
	};


	var path$1 = posix$1;

	var _createClass$u = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$u(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	var PrefabViews = function () {
		function PrefabViews(container) {
			_classCallCheck$u(this, PrefabViews);

			this.container = container;
			this._views = [];
			this.length = 0;
			this.hidden = false;
		}

		_createClass$u(PrefabViews, [{
			key: 'all',
			value: function all() {
				return this._views;
			}
		}, {
			key: 'first',
			value: function first() {
				return this._views[0];
			}
		}, {
			key: 'last',
			value: function last() {
				return this._views[this._views.length - 1];
			}
		}, {
			key: 'indexOf',
			value: function indexOf(view) {
				return this._views.indexOf(view);
			}
		}, {
			key: 'slice',
			value: function slice() {
				return this._views.slice.apply(this._views, arguments);
			}
		}, {
			key: 'get',
			value: function get(i) {
				return this._views[i];
			}
		}, {
			key: 'append',
			value: function append(view) {
				var check = false;
				this.forEach(function (v) {
					if (v.section.href == view.section.href) {
						check = true;
					}
				});
				if (check) {
					return view;
				}
				// if ( check ) { console.log("AHOY views.append WUT", view.section.href)}
				this._views.push(view);
				this._views.sort(function (a, b) {
					return a.section.href > b.section.href ? 1 : b.section.href > a.section.href ? -1 : 0;
				});
				if (this.container && view.element.dataset.reused != 'true') {
					this.container.appendChild(view.element);
				}
				this.length++;
				return view;
			}
		}, {
			key: 'dump',
			value: function dump() {
				return this._views.map(function (v) {
					return v.section.href;
				});
			}
		}, {
			key: 'prepend',
			value: function prepend(view) {
				this._views.unshift(view);
				if (this.container && view.element.dataset.reused != 'true') {
					this.container.insertBefore(view.element, this.container.firstChild);
				}
				this.length++;
				return view;
			}
		}, {
			key: 'insert',
			value: function insert(view, index) {
				this._views.splice(index, 0, view);

				if (this.container && view.element.dataset.reused != 'true') {
					if (index < this.container.children.length) {
						this.container.insertBefore(view.element, this.container.children[index]);
					} else {
						this.container.appendChild(view.element);
					}
				}

				this.length++;
				return view;
			}
		}, {
			key: 'remove',
			value: function remove(view) {
				var index = this._views.indexOf(view);

				if (index > -1) {
					this._views.splice(index, 1);
				}

				this.destroy(view);

				this.length--;
			}
		}, {
			key: 'destroy',
			value: function destroy(view) {
				if (view.displayed) {
					view.destroy();
				}

				// if(this.container && view.element.dataset.reused != 'true'){
				// 	 this.container.removeChild(view.element);
				// }
				view = null;
			}

			// Iterators

		}, {
			key: 'forEach',
			value: function forEach() {
				return this._views.forEach.apply(this._views, arguments);
			}
		}, {
			key: 'clear',
			value: function clear() {
				// Remove all views
				var view;
				var len = this.length;

				if (!this.length) return;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					this.destroy(view);
				}

				this._views = [];
				this.length = 0;
			}
		}, {
			key: 'find',
			value: function find(section) {

				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed && view.section.index == section.index) {
						return view;
					}
				}
			}
		}, {
			key: 'displayed',
			value: function displayed() {
				var displayed = [];
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						displayed.push(view);
					}
				}
				return displayed;
			}
		}, {
			key: 'show',
			value: function show() {
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						view.show();
					}
				}
				this.hidden = false;
			}
		}, {
			key: 'hide',
			value: function hide() {
				var view;
				var len = this.length;

				for (var i = 0; i < len; i++) {
					view = this._views[i];
					if (view.displayed) {
						view.hide();
					}
				}
				this.hidden = true;
			}
		}]);

		return PrefabViews;
	}();

	var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

	var _createClass$v = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$v(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn$2(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits$2(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PrePaginatedContinuousViewManager = function (_ContinuousViewManage) {
	  _inherits$2(PrePaginatedContinuousViewManager, _ContinuousViewManage);

	  function PrePaginatedContinuousViewManager(options) {
	    _classCallCheck$v(this, PrePaginatedContinuousViewManager);

	    var _this = _possibleConstructorReturn$2(this, (PrePaginatedContinuousViewManager.__proto__ || Object.getPrototypeOf(PrePaginatedContinuousViewManager)).call(this, options));

	    _this.name = "prepaginated";

	    _this._manifest = null;
	    _this._spine = [];
	    _this.settings.scale = _this.settings.scale || 1.0;
	    return _this;
	  }

	  _createClass$v(PrePaginatedContinuousViewManager, [{
	    key: "render",
	    value: function render(element, size) {
	      var scale = this.settings.scale;
	      this.settings.scale = null; // we don't want the stage to scale
	      ContinuousViewManager.prototype.render.call(this, element, size);
	      // Views array methods
	      // use prefab views
	      this.settings.scale = scale;
	      this.views = new PrefabViews(this.container);
	    }
	  }, {
	    key: "onResized",
	    value: function onResized(e) {
	      if (this.resizeTimeout) {
	        clearTimeout(this.resizeTimeout);
	      }
	      console.log("AHOY PREPAGINATED onResized queued");
	      this.resizeTimeout = setTimeout(function () {
	        this.resize();
	        console.log("AHOY PREPAGINATED onResized actual");
	        this.resizeTimeout = null;
	      }.bind(this), 500);
	      // this.resize();
	    }
	  }, {
	    key: "resize",
	    value: function resize(width, height) {

	      ContinuousViewManager.prototype.resize.call(this, width, height);
	      this._redrawViews();
	    }
	  }, {
	    key: "_redrawViews",
	    value: function _redrawViews() {
	      var self = this;
	      for (var i = 0; i < self._spine.length; i++) {
	        var href = self._spine[i];
	        // // console.log("AHOY DRAWING", href);
	        var section_ = self._manifest[href];
	        // // var r = self.container.offsetWidth / section_.viewport.width;
	        // // var h = Math.floor(dim.height * r);
	        // var w = self.layout.columnWidth + ( self.layout.columnWidth * 0.10 );
	        // var r = w / section_.viewport.width;
	        // var h = Math.floor(section_.viewport.height * r);

	        var h, w;

	        var _self$sizeToViewport = self.sizeToViewport(section_);

	        var _self$sizeToViewport2 = _slicedToArray(_self$sizeToViewport, 2);

	        w = _self$sizeToViewport2[0];
	        h = _self$sizeToViewport2[1];


	        var div = self.container.querySelector("div.epub-view[ref=\"" + section_.index + "\"]");
	        div.style.width = w + "px";
	        div.style.height = h + "px";
	        div.setAttribute('original-height', h);
	        div.setAttribute('layout-height', h);

	        var view = this.views.find(section_);
	        if (view) {
	          view.size(w, h);
	        }
	      }
	    }

	    // RRE - debugging

	  }, {
	    key: "createView",
	    value: function createView(section) {

	      var view = this.views.find(section);
	      if (view) {
	        return view;
	      }

	      var w, h;

	      var _sizeToViewport = this.sizeToViewport(section);

	      var _sizeToViewport2 = _slicedToArray(_sizeToViewport, 2);

	      w = _sizeToViewport2[0];
	      h = _sizeToViewport2[1];

	      var viewSettings = Object.assign({}, this.viewSettings);
	      viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
	      viewSettings.layout.height = h;
	      viewSettings.layout.columnWidth = w;
	      var view = new this.View(section, viewSettings);
	      return view;
	    }
	  }, {
	    key: "display",
	    value: function display(section, target) {
	      var self = this;
	      var promises = [];

	      this.q.clear();
	      var display = new defer();
	      var promises = [];
	      this.faking = {};

	      if (!this._manifest) {
	        this.emit("building");
	        self._manifest = {};
	        var _buildManifest = function _buildManifest(section_) {
	          self._manifest[section_.href] = false;
	          if (self.settings.viewports && self.settings.viewports[section_.href]) {
	            section_.viewport = self.settings.viewports[section_.href];
	            self._manifest[section_.href] = section_;
	          } else {
	            self.q.enqueue(function () {
	              section_.load(self.request).then(function (contents) {
	                var meta = contents.querySelector('meta[name="viewport"]');
	                var value = meta.getAttribute('content');
	                var tmp = value.split(",");
	                var key = section_.href;
	                var idx = self._spine.indexOf(key);
	                self.emit("building", { index: idx + 1, total: self._spine.length });
	                section_.viewport = {};
	                self._manifest[key] = section_;
	                // self._manifest[key] = { viewport : {} };
	                // self._manifest[key].index = section_.index;
	                // self._manifest[key].href = section_.href;
	                var viewport_width = tmp[0].replace('width=', '');
	                var viewport_height = tmp[1].replace('height=', '');
	                if (!viewport_height.match(/^\d+$/)) {
	                  viewport_width = viewport_height = 'auto';
	                } else {
	                  viewport_width = parseInt(viewport_width, 10);
	                  viewport_height = parseInt(viewport_height, 10);
	                }
	                self._manifest[key].viewport.width = viewport_width;
	                self._manifest[key].viewport.height = viewport_height;
	                self.faking[key] = self._manifest[key].viewport;
	              });
	            });
	          }
	        };

	        // can we build a manifest here?
	        var prev_ = section.prev();
	        while (prev_) {
	          self._spine.unshift(prev_.href);
	          _buildManifest(prev_);
	          prev_ = prev_.prev();
	        }

	        self._spine.push(section.href);
	        _buildManifest(section);

	        var next_ = section.next();
	        while (next_) {
	          self._spine.push(next_.href);
	          _buildManifest(next_);
	          next_ = next_.next();
	        }

	        console.log("AHOY PRE-PAGINATED", promises.length);
	      }

	      var _display = function () {

	        var check = document.querySelector('.epub-view');
	        if (!check) {
	          self._max_height = self._max_viewport_height = 0;
	          self._max_width = self._max_viewport_width = 0;
	          console.log("AHOY DRAWING", self._spine.length);
	          for (var i = 0; i < self._spine.length; i++) {
	            var href = self._spine[i];
	            var section_ = self._manifest[href];
	            var w, h;

	            var _self$sizeToViewport3 = self.sizeToViewport(section_);

	            var _self$sizeToViewport4 = _slicedToArray(_self$sizeToViewport3, 2);

	            w = _self$sizeToViewport4[0];
	            h = _self$sizeToViewport4[1];


	            self.container.innerHTML += "<div class=\"epub-view\" ref=\"" + section_.index + "\" data-href=\"" + section_.href + "\" style=\"width: " + w + "px; height: " + h + "px; text-align: center; margin-left: auto; margin-right: auto\"></div>";
	            var div = self.container.querySelector("div.epub-view[ref=\"" + section_.index + "\"]");
	            // div.setAttribute('use-')
	            div.setAttribute('original-height', h);
	            div.setAttribute('layout-height', h);

	            if (window.debugManager) {
	              div.style.backgroundImage = "url(\"data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 32' width='300' height='32'%3e%3cstyle%3e.small %7b fill: rgba(0,0,0,0.3);%7d%3c/style%3e%3ctext x='0' y='25' class='small'%3e" + section_.href + "%3c/text%3e%3c/svg%3e\")";
	              var colorR = Math.floor(Math.random() * 100).toString();
	              var colorG = Math.floor(Math.random() * 100).toString();
	              var colorB = Math.floor(Math.random() * 100).toString();
	              div.style.backgroundColor = "#" + colorR + colorG + colorB;
	            }
	          }
	        }

	        // find the <div> with this section
	        // console.log("AHOY continuous.display START", section.href);
	        var div = self.container.querySelector("div.epub-view[ref=\"" + section.index + "\"]");
	        div.scrollIntoView();

	        // this.q.clear();
	        // return check ? this.update() : this.check();
	        // var retval = check ? this.update() : this.check();
	        var retval = this.check();
	        console.log("AHOY DISPLAY", check ? "UPDATE" : "CHECK", retval);
	        retval.then(function () {
	          this.q.clear();
	          console.log("AHOY MANAGER BUILT");
	          this.emit("built");
	          return display.resolve();
	        }.bind(this));

	        // return DefaultViewManager.prototype.display.call(this, section, target)
	        //  .then(function () {
	        //    return this.fill();
	        //  }.bind(this));

	        return retval;
	      }.bind(this);

	      // // promises.push(_display);
	      // while(promises.length) {
	      //  this.q.enqueue(promises.shift);
	      // }

	      // console.log("AHOY PREPAGINATED", this.q._q.length);
	      // this.q.enqueue().then((result) => {
	      //  display.resolve();
	      // })

	      var q = function () {
	        return this.q.enqueue(function (result) {
	          var waiting = 0;
	          for (var i = 0; i < self._spine.length; i++) {
	            var href = self._spine[i];
	            var has_section = self._manifest[href];
	            if (has_section == false) {
	              waiting += 1;
	            }
	          }
	          // console.log("AHOY PRE-PAGINATED WAITING", waiting);
	          if (waiting == 0) {
	            return _display();
	          } else {
	            q();
	          }
	        });
	      }.bind(this);

	      return q();

	      return display.promise;
	    }
	  }, {
	    key: "_checkStillLoading",
	    value: function _checkStillLoading() {
	      this.q.enqueue(function (result) {
	        var waiting = 0;
	        for (var i = 0; i < self._spine.length; i++) {
	          var href = self._spine[i];
	          var has_section = self._manifest[href];
	          if (has_section == false) {
	            waiting += 1;
	          }
	        }
	        console.log("AHOY PRE-PAGINATED WAITING", waiting);
	        if (waiting == 0) {
	          return _display();
	        } else {
	          q();
	        }
	      });
	    }
	  }, {
	    key: "fill",
	    value: function fill(_full) {
	      var _this2 = this;

	      var full = _full || new defer();

	      this.q.enqueue(function () {
	        return _this2._checkStillLoading();
	      }).then(function (result) {
	        if (result) {
	          _this2.fill(full);
	        } else {
	          full.resolve();
	        }
	      });

	      return full.promise;
	    }
	  }, {
	    key: "fillXX",
	    value: function fillXX(_full) {
	      var _this3 = this;

	      var full = _full || new defer();

	      this.q.enqueue(function () {
	        return _this3.check();
	      }).then(function (result) {
	        if (result) {
	          _this3.fill(full);
	        } else {
	          full.resolve();
	        }
	      });

	      return full.promise;
	    }
	  }, {
	    key: "moveTo",
	    value: function moveTo(offset) {
	      // var bounds = this.stage.bounds();
	      // var dist = Math.floor(offset.top / bounds.height) * bounds.height;
	      var distX = 0,
	          distY = 0;

	      var offsetX = 0,
	          offsetY = 0;

	      if (!this.isPaginated) {
	        distY = offset.top;
	        offsetY = offset.top + this.settings.offset;
	      } else {
	        distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;
	        offsetX = distX + this.settings.offset;
	      }

	      if (distX > 0 || distY > 0) {
	        this.scrollBy(distX, distY, true);
	      }
	    }
	  }, {
	    key: "afterResized",
	    value: function afterResized(view) {
	      this.emit(EVENTS.MANAGERS.RESIZE, view.section);
	    }

	    // Remove Previous Listeners if present

	  }, {
	    key: "removeShownListeners",
	    value: function removeShownListeners(view) {

	      // view.off("shown", this.afterDisplayed);
	      // view.off("shown", this.afterDisplayedAbove);
	      view.onDisplayed = function () {};
	    }
	  }, {
	    key: "add",
	    value: function add(section) {
	      var _this4 = this;

	      var view = this.createView(section);

	      this.views.append(view);

	      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
	        view.expanded = true;
	      });

	      view.on(EVENTS.VIEWS.AXIS, function (axis) {
	        _this4.updateAxis(axis);
	      });

	      // view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));
	      view.onDisplayed = this.afterDisplayed.bind(this);
	      view.onResize = this.afterResized.bind(this);

	      return view.display(this.request);
	    }
	  }, {
	    key: "append",
	    value: function append(section) {

	      var view = this.createView(section);

	      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
	        view.expanded = true;
	        // do not do this
	        // this.counter(bounds); // RRE
	      });

	      /*
	      view.on(EVENTS.VIEWS.AXIS, (axis) => {
	        this.updateAxis(axis);
	      });
	      */

	      this.views.append(view);

	      view.onDisplayed = this.afterDisplayed.bind(this);

	      return view;
	    }
	  }, {
	    key: "prepend",
	    value: function prepend(section) {
	      var _this5 = this;

	      var view = this.createView(section);

	      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
	        _this5.counter(bounds);
	        view.expanded = true;
	      });

	      /*
	      view.on(EVENTS.VIEWS.AXIS, (axis) => {
	        this.updateAxis(axis);
	      });
	      */

	      this.views.prepend(view);

	      view.onDisplayed = this.afterDisplayed.bind(this);

	      return view;
	    }
	  }, {
	    key: "counter",
	    value: function counter(bounds) {
	      // return;
	      if (this.settings.axis === "vertical") {
	        // if ( ! this._timer ) {
	        //  this._timer = setTimeout(function() {
	        //    this._timer = null;
	        //    console.log("AHOY USING counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
	        //    this.scrollBy(0, bounds.heightDelta, true);
	        //    this.x1(`COUNTER ${bounds.heightDelta}`);
	        //  }.bind(this), 500);
	        // } else {
	        //  console.log("AHOY SKIPPING counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
	        // }
	        // console.log("AHOY counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
	        this.scrollBy(0, bounds.heightDelta, true);
	      } else {
	        this.scrollBy(bounds.widthDelta, 0, true);
	      }
	    }
	  }, {
	    key: "updateXXX",
	    value: function updateXXX(_offset) {
	      var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
	      var visibleLength = horizontal ? bounds.width : bounds.height;
	      var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

	      var divs = document.querySelectorAll('.epub-view');
	      for (var i = 0; i < divs.length; i++) {
	        var div = divs[i];
	        var rect = div.getBoundingClientRect();
	        // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
	        // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {
	        if (offset < div.offsetTop + rect.height && offset + bounds.height > div.offsetTop) {
	          var section = this._manifest[div.dataset.href];
	          // if ( ! div.querySelector('iframe') ) {
	          //  newViews.push(this.append(section))
	          // }
	          // var idx = this._spine.indexOf(section.href);
	          // if ( idx > 0 ) {
	          //  visible.push(this._manifest[this._spine[idx - 1]]);
	          // }
	          // if ( idx < this._spine.length - 1 ) {
	          //  visible.push(this._manifest[this._spine[idx + 1]]);
	          // }
	        }
	        // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);
	      }
	    }
	  }, {
	    key: "update",
	    value: function update(_offset) {
	      var container = this.bounds();
	      var views = this.views.all();
	      var viewsLength = views.length;
	      var offset = typeof _offset != "undefined" ? _offset : this.settings.offset || 0;
	      var isVisible;
	      var view;

	      var updating = new defer();
	      var promises = [];
	      var queued = {};
	      for (var i = 0; i < viewsLength; i++) {
	        view = views[i];

	        isVisible = this.isVisible(view, offset, offset, container);
	        if (isVisible === true) {
	          queued[i] = true;
	        }
	      }

	      for (var i = 0; i < viewsLength; i++) {
	        view = views[i];
	        var isVisible = queued[i];
	        if (isVisible === true) {
	          // console.log("visible " + view.index);

	          if (!view.displayed) {
	            // console.log("AHOY continuous.update !displayed", view.section.href);
	            var displayed = view.display(this.request).then(function (view) {
	              view.show();
	            }, function (err) {
	              // console.log("AHOY continuous.update ERROR", err);
	              view.hide();
	            });
	            promises.push(displayed);
	          } else {
	            // console.log("AHOY continuous.update show", view.section.href);
	            view.show();
	          }
	        } else {
	          this.q.enqueue(view.destroy.bind(view));
	          // console.log("hidden " + view.index);

	          clearTimeout(this.trimTimeout);
	          this.trimTimeout = setTimeout(function () {
	            this.q.enqueue(this.trim.bind(this));
	          }.bind(this), 250);
	        }
	      }

	      if (promises.length) {
	        return Promise.all(promises).catch(function (err) {
	          updating.reject(err);
	        });
	      } else {
	        updating.resolve();
	        return updating.promise;
	      }
	    }
	  }, {
	    key: "check",
	    value: function check(_offsetLeft, _offsetTop) {
	      var _this6 = this;

	      var checking = new defer();
	      var newViews = [];

	      var horizontal = this.settings.axis === "horizontal";
	      var delta = this.settings.offset || 0;

	      if (_offsetLeft && horizontal) {
	        delta = _offsetLeft;
	      }

	      if (_offsetTop && !horizontal) {
	        delta = _offsetTop;
	      }

	      var bounds = this._bounds; // bounds saved this until resize

	      var rtl = this.settings.direction === "rtl";
	      var dir = horizontal && rtl ? -1 : 1; //RTL reverses scrollTop

	      var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
	      var visibleLength = horizontal ? bounds.width : bounds.height;
	      var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

	      var prePaginated = this.layout.props.name == 'pre-paginated';

	      var adjusted_top = offset - bounds.height * 8;
	      var adjusted_end = offset + bounds.height * 8;
	      // console.log("AHOY check", offset, "-", offset + bounds.height, "/", adjusted_top, "-", adjusted_end);

	      // need to figure out which divs are viewable
	      var divs = document.querySelectorAll('.epub-view');
	      var visible = [];
	      for (var i = 0; i < divs.length; i++) {
	        var div = divs[i];
	        var rect = div.getBoundingClientRect();
	        // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
	        // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {
	        if (offset < div.offsetTop + rect.height && offset + bounds.height > div.offsetTop) {
	          var section = this._manifest[div.dataset.href];
	          visible.push(section);
	          // if ( ! div.querySelector('iframe') ) {
	          //  newViews.push(this.append(section))
	          // }
	          // var idx = this._spine.indexOf(section.href);
	          // if ( idx > 0 ) {
	          //  visible.push(this._manifest[this._spine[idx - 1]]);
	          // }
	          // if ( idx < this._spine.length - 1 ) {
	          //  visible.push(this._manifest[this._spine[idx + 1]]);
	          // }
	        }
	        // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);
	      }

	      this.__check_visible = visible;

	      var section = visible[0];
	      if (section && section.index > 0) {
	        visible.unshift(this._manifest[this._spine[section.index - 1]]);
	      }
	      if (section) {
	        var tmp = this._spine[section.index + 1];
	        if (tmp) {
	          visible.push(this._manifest[tmp]);
	        }
	      }
	      // if ( section && section.prev() ) {
	      //  visible.unshift(section.prev());
	      // }
	      // section = visible[visible.length - 1];
	      // if (section && section.next() ) {
	      //  visible.push(section.next());
	      // }

	      for (var i = 0; i < visible.length; i++) {
	        var section = visible[i];
	        // var div = document.querySelector(`.epub-view[ref="${section.index}"]`);
	        // if ( div.querySelector('iframe') ) {
	        //  continue;
	        // }
	        newViews.push(this.append(section));
	      }

	      // let promises = newViews.map((view) => {
	      //  return view.displayed;
	      // });

	      var promises = [];
	      for (var i = 0; i < newViews.length; i++) {
	        if (newViews[i]) {
	          promises.push(newViews[i]);
	        }
	      }

	      if (newViews.length) {
	        return Promise.all(promises).then(function () {
	          // return this.check();
	          // if (this.layout.name === "pre-paginated" && this.layout.props.spread && this.layout.flow() != 'scrolled') {
	          //   // console.log("AHOY check again");
	          //   return this.check();
	          // }
	        }).then(function () {
	          // Check to see if anything new is on screen after rendering
	          // console.log("AHOY update again");
	          return _this6.update(delta);
	        }, function (err) {
	          return err;
	        });
	      } else {
	        this.q.enqueue(function () {
	          this.update();
	        }.bind(this));
	        checking.resolve(false);
	        return checking.promise;
	      }
	    }
	  }, {
	    key: "trim",
	    value: function trim() {
	      var task = new defer();
	      var displayed = this.views.displayed();
	      var first = displayed[0];
	      var last = displayed[displayed.length - 1];
	      var firstIndex = this.views.indexOf(first);
	      var lastIndex = this.views.indexOf(last);
	      var above = this.views.slice(0, firstIndex);
	      var below = this.views.slice(lastIndex + 1);

	      // Erase all but last above
	      for (var i = 0; i < above.length - 3; i++) {
	        if (above[i]) {
	          // console.log("AHOY trim > above", first.section.href, ":", above[i].section.href);
	          this.erase(above[i], above);
	        }
	      }

	      // Erase all except first below
	      for (var j = 3; j < below.length; j++) {
	        if (below[j]) {
	          // console.log("AHOY trim > below", last.section.href, ":", below[j].section.href);
	          this.erase(below[j]);
	        }
	      }

	      task.resolve();
	      return task.promise;
	    }
	  }, {
	    key: "erase",
	    value: function erase(view, above) {
	      //Trim

	      var prevTop;
	      var prevLeft;

	      if (this.settings.height) {
	        prevTop = this.container.scrollTop;
	        prevLeft = this.container.scrollLeft;
	      } else {
	        prevTop = window.scrollY;
	        prevLeft = window.scrollX;
	      }

	      var bounds = view.bounds();

	      // console.log("AHOY erase", view.section.href, above);
	      this.views.remove(view);

	      if (above) {
	        if (this.settings.axis === "vertical") ; else {
	          this.scrollTo(prevLeft - bounds.width, 0, true);
	        }
	      }
	    }
	  }, {
	    key: "addEventListeners",
	    value: function addEventListeners(stage) {

	      window.addEventListener("unload", function (e) {
	        this.ignore = true;
	        // this.scrollTo(0,0);
	        this.destroy();
	      }.bind(this));

	      this.addScrollListeners();
	    }
	  }, {
	    key: "addScrollListeners",
	    value: function addScrollListeners() {
	      var scroller;

	      this.tick = requestAnimationFrame$1;

	      if (this.settings.height) {
	        this.prevScrollTop = this.container.scrollTop;
	        this.prevScrollLeft = this.container.scrollLeft;
	      } else {
	        this.prevScrollTop = window.scrollY;
	        this.prevScrollLeft = window.scrollX;
	      }

	      this.scrollDeltaVert = 0;
	      this.scrollDeltaHorz = 0;

	      if (this.settings.height) {
	        scroller = this.container;
	        this.scrollTop = this.container.scrollTop;
	        this.scrollLeft = this.container.scrollLeft;
	      } else {
	        scroller = window;
	        this.scrollTop = window.scrollY;
	        this.scrollLeft = window.scrollX;
	      }

	      scroller.addEventListener("scroll", this.onScroll.bind(this));
	      this._scrolled = debounce_1(this.scrolled.bind(this), 30);
	      // this.tick.call(window, this.onScroll.bind(this));

	      this.didScroll = false;
	    }
	  }, {
	    key: "removeEventListeners",
	    value: function removeEventListeners() {
	      var scroller;

	      if (this.settings.height) {
	        scroller = this.container;
	      } else {
	        scroller = window;
	      }

	      scroller.removeEventListener("scroll", this.onScroll.bind(this));
	    }
	  }, {
	    key: "onScroll",
	    value: function onScroll() {
	      var scrollTop = void 0;
	      var scrollLeft = void 0;
	      var dir = this.settings.direction === "rtl" ? -1 : 1;

	      if (this.settings.height) {
	        scrollTop = this.container.scrollTop;
	        scrollLeft = this.container.scrollLeft;
	      } else {
	        scrollTop = window.scrollY * dir;
	        scrollLeft = window.scrollX * dir;
	      }

	      this.scrollTop = scrollTop;
	      this.scrollLeft = scrollLeft;

	      if (!this.ignore) {

	        this._scrolled();
	      } else {
	        this.ignore = false;
	      }

	      this.scrollDeltaVert += Math.abs(scrollTop - this.prevScrollTop);
	      this.scrollDeltaHorz += Math.abs(scrollLeft - this.prevScrollLeft);

	      this.prevScrollTop = scrollTop;
	      this.prevScrollLeft = scrollLeft;

	      clearTimeout(this.scrollTimeout);
	      this.scrollTimeout = setTimeout(function () {
	        this.scrollDeltaVert = 0;
	        this.scrollDeltaHorz = 0;
	      }.bind(this), 150);

	      this.didScroll = false;
	    }
	  }, {
	    key: "scrolled",
	    value: function scrolled() {
	      this.q.enqueue(function () {
	        this.check();
	        this.recenter();
	        setTimeout(function () {
	          this.emit(EVENTS.MANAGERS.SCROLLED, {
	            top: this.scrollTop,
	            left: this.scrollLeft
	          });
	        }.bind(this), 500);
	      }.bind(this));

	      this.emit(EVENTS.MANAGERS.SCROLL, {
	        top: this.scrollTop,
	        left: this.scrollLeft
	      });

	      clearTimeout(this.afterScrolled);
	      this.afterScrolled = setTimeout(function () {
	        this.emit(EVENTS.MANAGERS.SCROLLED, {
	          top: this.scrollTop,
	          left: this.scrollLeft
	        });
	      }.bind(this));
	    }
	  }, {
	    key: "next",
	    value: function next() {

	      var dir = this.settings.direction;
	      var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

	      delta = this.container.offsetHeight / this.settings.scale;

	      if (!this.views.length) return;

	      if (this.isPaginated && this.settings.axis === "horizontal") {

	        this.scrollBy(delta, 0, true);
	      } else {

	        // this.scrollBy(0, this.layout.height, true);
	        this.scrollBy(0, delta, true);
	      }

	      this.q.enqueue(function () {
	        this.check();
	      }.bind(this));
	    }
	  }, {
	    key: "prev",
	    value: function prev() {

	      var dir = this.settings.direction;
	      var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

	      if (!this.views.length) return;

	      if (this.isPaginated && this.settings.axis === "horizontal") {

	        this.scrollBy(-delta, 0, true);
	      } else {

	        this.scrollBy(0, -this.layout.height, true);
	      }

	      this.q.enqueue(function () {
	        this.check();
	      }.bind(this));
	    }
	  }, {
	    key: "updateAxis",
	    value: function updateAxis(axis, forceUpdate) {

	      if (!this.isPaginated) {
	        axis = "vertical";
	      }

	      if (!forceUpdate && axis === this.settings.axis) {
	        return;
	      }

	      this.settings.axis = axis;

	      this.stage && this.stage.axis(axis);

	      this.viewSettings.axis = axis;

	      if (this.mapping) {
	        this.mapping.axis(axis);
	      }

	      if (this.layout) {
	        if (axis === "vertical") {
	          this.layout.spread("none");
	        } else {
	          this.layout.spread(this.layout.settings.spread);
	        }
	      }

	      if (axis === "vertical") {
	        this.settings.infinite = true;
	      } else {
	        this.settings.infinite = false;
	      }
	    }
	  }, {
	    key: "recenter",
	    value: function recenter() {
	      var wrapper = this.container.parentElement;
	      var w3 = wrapper.scrollWidth / 2 - wrapper.offsetWidth / 2;
	      wrapper.scrollLeft = w3;
	    }
	  }, {
	    key: "sizeToViewport",
	    value: function sizeToViewport(section) {
	      var h = this.layout.height;
	      // reduce to 80% to avoid hacking epubjs/layout.js
	      var w = this.layout.columnWidth * 0.8 * this.settings.scale;
	      if (section.viewport.height != 'auto') {
	        if (this.layout.columnWidth > section.viewport.width) {
	          w = section.viewport.width * this.settings.scale;
	        }
	        var r = w / section.viewport.width;
	        h = Math.floor(section.viewport.height * r);
	      }
	      return [w, h];
	    }
	  }, {
	    key: "sizeToViewport_X",
	    value: function sizeToViewport_X(section) {
	      var h = this.layout.height;
	      var w = this.layout.columnWidth * 0.80;

	      if (section.viewport.height != 'auto') {

	        var r = w / section.viewport.width;
	        h = section.viewport.height * r;
	        var f = 1 / 0.60;
	        var m = Math.min(f * this.layout.height / h, 1.0);
	        console.log("AHOY SHRINKING", "( " + f + " * " + this.layout.height + " ) / " + h + " = " + m + " :: " + h * m);
	        h *= m;

	        h *= this.settings.scale;
	        if (h > section.viewport.height) {
	          h = section.viewport.height;
	        }

	        r = h / section.viewport.height;
	        w = section.viewport.width * r;

	        h = Math.floor(h);
	        w = Math.floor(w);
	      }
	      return [w, h];
	    }
	  }, {
	    key: "scale",
	    value: function scale(_scale) {
	      var self = this;
	      this.settings.scale = _scale;
	      var current = this.currentLocation();
	      var index = -1;
	      if (current[0]) {
	        index = current[0].index;
	      }

	      this.views.hide();
	      this.views.clear();
	      this._redrawViews();
	      this.views.show();
	      setTimeout(function () {
	        console.log("AHOY JUMPING TO", index);
	        if (index > -1) {
	          var div = self.container.querySelector("div.epub-view[ref=\"" + index + "\"]");
	          div.scrollIntoView(true);
	        }
	        this.check().then(function () {
	          this.onScroll();
	        }.bind(this));
	      }.bind(this), 0);
	    }
	  }, {
	    key: "resetScale",
	    value: function resetScale() {
	      // NOOP
	    }
	  }]);

	  return PrePaginatedContinuousViewManager;
	}(ContinuousViewManager);

	PrePaginatedContinuousViewManager.toString = function () {
	  return 'prepaginated';
	};

	var _createClass$w = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$w(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn$3(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits$3(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var ReusableIframeView = function (_IframeView) {
	    _inherits$3(ReusableIframeView, _IframeView);

	    function ReusableIframeView(section, options) {
	        _classCallCheck$w(this, ReusableIframeView);

	        return _possibleConstructorReturn$3(this, (ReusableIframeView.__proto__ || Object.getPrototypeOf(ReusableIframeView)).call(this, section, options));
	        // this._layout.height = null;
	    }

	    _createClass$w(ReusableIframeView, [{
	        key: "container",
	        value: function container(axis) {
	            var check = document.querySelector("div[ref='" + this.index + "']");
	            if (check) {
	                check.dataset.reused = 'true';
	                return check;
	            }

	            var element = document.createElement("div");

	            element.classList.add("epub-view");

	            // this.element.style.minHeight = "100px";
	            element.style.height = "0px";
	            element.style.width = "0px";
	            element.style.overflow = "hidden";
	            element.style.position = "relative";
	            element.style.display = "block";

	            if (axis && axis == "horizontal") {
	                element.style.flex = "none";
	            } else {
	                element.style.flex = "initial";
	            }

	            return element;
	        }
	    }, {
	        key: "create",
	        value: function create() {

	            if (this.iframe) {
	                return this.iframe;
	            }

	            if (!this.element) {
	                this.element = this.createContainer();
	            }

	            if (this.element.hasAttribute('layout-height')) {
	                var height = parseInt(this.element.getAttribute('layout-height'), 10);
	                this._layout_height = height;
	            }

	            this.iframe = this.element.querySelector("iframe");
	            if (this.iframe) {
	                return this.iframe;
	            }

	            this.iframe = document.createElement("iframe");
	            this.iframe.id = this.id;
	            this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations
	            this.iframe.style.overflow = "hidden";
	            this.iframe.seamless = "seamless";
	            // Back up if seamless isn't supported
	            this.iframe.style.border = "none";

	            this.iframe.setAttribute("enable-annotation", "true");

	            this.resizing = true;

	            // this.iframe.style.display = "none";
	            this.element.style.visibility = "hidden";
	            this.iframe.style.visibility = "hidden";

	            this.iframe.style.width = "0";
	            this.iframe.style.height = "0";
	            this._width = 0;
	            this._height = 0;

	            this.element.setAttribute("ref", this.index);
	            this.element.setAttribute("data-href", this.section.href);

	            // this.element.appendChild(this.iframe);
	            this.added = true;

	            this.elementBounds = bounds$1(this.element);

	            // if(width || height){
	            //   this.resize(width, height);
	            // } else if(this.width && this.height){
	            //   this.resize(this.width, this.height);
	            // } else {
	            //   this.iframeBounds = bounds(this.iframe);
	            // }


	            if ("srcdoc" in this.iframe) {
	                this.supportsSrcdoc = true;
	            } else {
	                this.supportsSrcdoc = false;
	            }

	            if (!this.settings.method) {
	                this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
	            }

	            return this.iframe;
	        }
	    }]);

	    return ReusableIframeView;
	}(IframeView);

	var isImplemented$3 = function () {
		var assign = Object.assign, obj;
		if (typeof assign !== 'function') return false;
		obj = { foo: 'raz' };
		assign(obj, { bar: 'dwa' }, { trzy: 'trzy' });
		return (obj.foo + obj.bar + obj.trzy) === 'razdwatrzy';
	};

	var isImplemented$4 = function () {
		try {
			return true;
		} catch (e) { return false; }
	};

	var keys$3 = Object.keys;

	var shim$3 = function (object) {
		return keys$3(object == null ? object : Object(object));
	};

	var keys$4 = isImplemented$4()
		? Object.keys
		: shim$3;

	var validValue$1 = function (value) {
		if (value == null) throw new TypeError("Cannot use null or undefined");
		return value;
	};

	var max$1 = Math.max;

	var shim$4 = function (dest, src/*, …srcn*/) {
		var error, i, l = max$1(arguments.length, 2), assign;
		dest = Object(validValue$1(dest));
		assign = function (key) {
			try { dest[key] = src[key]; } catch (e) {
				if (!error) error = e;
			}
		};
		for (i = 1; i < l; ++i) {
			src = arguments[i];
			keys$4(src).forEach(assign);
		}
		if (error !== undefined) throw error;
		return dest;
	};

	var assign$2 = isImplemented$3()
		? Object.assign
		: shim$4;

	var forEach$1 = Array.prototype.forEach, create$3 = Object.create;

	var process$3 = function (src, obj) {
		var key;
		for (key in src) obj[key] = src[key];
	};

	var normalizeOptions$1 = function (options/*, …options*/) {
		var result = create$3(null);
		forEach$1.call(arguments, function (options) {
			if (options == null) return;
			process$3(Object(options), result);
		});
		return result;
	};

	// Deprecated

	var isCallable$1 = function (obj) { return typeof obj === 'function'; };

	var str$1 = 'razdwatrzy';

	var isImplemented$5 = function () {
		if (typeof str$1.contains !== 'function') return false;
		return ((str$1.contains('dwa') === true) && (str$1.contains('foo') === false));
	};

	var indexOf$2 = String.prototype.indexOf;

	var shim$5 = function (searchString/*, position*/) {
		return indexOf$2.call(this, searchString, arguments[1]) > -1;
	};

	var contains$3 = isImplemented$5()
		? String.prototype.contains
		: shim$5;

	var d_1$1 = createCommonjsModule(function (module) {

	var d;

	d = module.exports = function (dscr, value/*, options*/) {
		var c, e, w, options, desc;
		if ((arguments.length < 2) || (typeof dscr !== 'string')) {
			options = value;
			value = dscr;
			dscr = null;
		} else {
			options = arguments[2];
		}
		if (dscr == null) {
			c = w = true;
			e = false;
		} else {
			c = contains$3.call(dscr, 'c');
			e = contains$3.call(dscr, 'e');
			w = contains$3.call(dscr, 'w');
		}

		desc = { value: value, configurable: c, enumerable: e, writable: w };
		return !options ? desc : assign$2(normalizeOptions$1(options), desc);
	};

	d.gs = function (dscr, get, set/*, options*/) {
		var c, e, options, desc;
		if (typeof dscr !== 'string') {
			options = set;
			set = get;
			get = dscr;
			dscr = null;
		} else {
			options = arguments[3];
		}
		if (get == null) {
			get = undefined;
		} else if (!isCallable$1(get)) {
			options = get;
			get = set = undefined;
		} else if (set == null) {
			set = undefined;
		} else if (!isCallable$1(set)) {
			options = set;
			set = undefined;
		}
		if (dscr == null) {
			c = true;
			e = false;
		} else {
			c = contains$3.call(dscr, 'c');
			e = contains$3.call(dscr, 'e');
		}

		desc = { get: get, set: set, configurable: c, enumerable: e };
		return !options ? desc : assign$2(normalizeOptions$1(options), desc);
	};
	});

	var validCallable$1 = function (fn) {
		if (typeof fn !== 'function') throw new TypeError(fn + " is not a function");
		return fn;
	};

	var eventEmitter$1 = createCommonjsModule(function (module, exports) {

	var apply = Function.prototype.apply, call = Function.prototype.call
	  , create = Object.create, defineProperty = Object.defineProperty
	  , defineProperties = Object.defineProperties
	  , hasOwnProperty = Object.prototype.hasOwnProperty
	  , descriptor = { configurable: true, enumerable: false, writable: true }

	  , on, once, off, emit, methods, descriptors, base;

	on = function (type, listener) {
		var data;

		validCallable$1(listener);

		if (!hasOwnProperty.call(this, '__ee__')) {
			data = descriptor.value = create(null);
			defineProperty(this, '__ee__', descriptor);
			descriptor.value = null;
		} else {
			data = this.__ee__;
		}
		if (!data[type]) data[type] = listener;
		else if (typeof data[type] === 'object') data[type].push(listener);
		else data[type] = [data[type], listener];

		return this;
	};

	once = function (type, listener) {
		var once, self;

		validCallable$1(listener);
		self = this;
		on.call(this, type, once = function () {
			off.call(self, type, once);
			apply.call(listener, this, arguments);
		});

		once.__eeOnceListener__ = listener;
		return this;
	};

	off = function (type, listener) {
		var data, listeners, candidate, i;

		validCallable$1(listener);

		if (!hasOwnProperty.call(this, '__ee__')) return this;
		data = this.__ee__;
		if (!data[type]) return this;
		listeners = data[type];

		if (typeof listeners === 'object') {
			for (i = 0; (candidate = listeners[i]); ++i) {
				if ((candidate === listener) ||
						(candidate.__eeOnceListener__ === listener)) {
					if (listeners.length === 2) data[type] = listeners[i ? 0 : 1];
					else listeners.splice(i, 1);
				}
			}
		} else {
			if ((listeners === listener) ||
					(listeners.__eeOnceListener__ === listener)) {
				delete data[type];
			}
		}

		return this;
	};

	emit = function (type) {
		var i, l, listener, listeners, args;

		if (!hasOwnProperty.call(this, '__ee__')) return;
		listeners = this.__ee__[type];
		if (!listeners) return;

		if (typeof listeners === 'object') {
			l = arguments.length;
			args = new Array(l - 1);
			for (i = 1; i < l; ++i) args[i - 1] = arguments[i];

			listeners = listeners.slice();
			for (i = 0; (listener = listeners[i]); ++i) {
				apply.call(listener, this, args);
			}
		} else {
			switch (arguments.length) {
			case 1:
				call.call(listeners, this);
				break;
			case 2:
				call.call(listeners, this, arguments[1]);
				break;
			case 3:
				call.call(listeners, this, arguments[1], arguments[2]);
				break;
			default:
				l = arguments.length;
				args = new Array(l - 1);
				for (i = 1; i < l; ++i) {
					args[i - 1] = arguments[i];
				}
				apply.call(listeners, this, args);
			}
		}
	};

	methods = {
		on: on,
		once: once,
		off: off,
		emit: emit
	};

	descriptors = {
		on: d_1$1(on),
		once: d_1$1(once),
		off: d_1$1(off),
		emit: d_1$1(emit)
	};

	base = defineProperties({}, descriptors);

	module.exports = exports = function (o) {
		return (o == null) ? create(base) : defineProperties(Object(o), descriptors);
	};
	exports.methods = methods;
	});
	var eventEmitter_1$1 = eventEmitter$1.methods;

	var _createClass$x = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$x(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
	window.inVp = inVp;

	var Views$1 = function () {
	    function Views(container) {
	        var preloading = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

	        _classCallCheck$x(this, Views);

	        this.container = container;
	        this._views = [];
	        this.length = 0;
	        this.hidden = false;
	        this.preloading = preloading;
	        this.observer = new IntersectionObserver(this.handleObserver.bind(this), {
	            root: this.containr,
	            rootMargin: '0px',
	            threshold: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
	        });
	    }

	    _createClass$x(Views, [{
	        key: 'all',
	        value: function all() {
	            return this._views;
	        }
	    }, {
	        key: 'first',
	        value: function first() {
	            // return this._views[0];
	            return this.displayed()[0];
	        }
	    }, {
	        key: 'last',
	        value: function last() {
	            var d = this.displayed();
	            return d[d.length - 1];
	            // return this._views[this._views.length-1];
	        }
	    }, {
	        key: 'prev',
	        value: function prev(view) {
	            var index = this.indexOf(view);
	            return this.get(index - 1);
	        }
	    }, {
	        key: 'next',
	        value: function next(view) {
	            var index = this.indexOf(view);
	            return this.get(index + 1);
	        }
	    }, {
	        key: 'indexOf',
	        value: function indexOf$$1(view) {
	            return this._views.indexOf(view);
	        }
	    }, {
	        key: 'slice',
	        value: function slice() {
	            return this._views.slice.apply(this._views, arguments);
	        }
	    }, {
	        key: 'get',
	        value: function get(i) {
	            return i < 0 ? null : this._views[i];
	        }
	    }, {
	        key: 'append',
	        value: function append(view) {
	            this._views.push(view);
	            if (this.container) {
	                this.container.appendChild(view.element);
	                var h = this.container.offsetHeight;
	                // view.observer = ElementObserver(view.element, {
	                //     container: this.container,
	                //     onEnter: this.onEnter.bind(this, view), // callback when the element enters the viewport
	                //     onExit: this.onExit.bind(this, view), // callback when the element exits the viewport
	                //     offset: 0, // offset from the edges of the viewport in pixels
	                //     once: false, // if true, observer is detroyed after first callback is triggered
	                //     observerCollection: null // new ObserverCollection() // Advanced: Used for grouping custom viewport handling
	                // })
	                // const { fully, partially, edges } = inVp(view.element, threshold, this.container);
	                // if ( edges.percentage > 0 ) {
	                //     this.onEnter(view);
	                // }

	                this.observer.observe(view.element);
	            }
	            this.length++;
	            return view;
	        }
	    }, {
	        key: 'handleObserver',
	        value: function handleObserver(entries, observer) {
	            var _this = this;

	            entries.forEach(function (entry) {
	                var div = entry.target;
	                var index = div.getAttribute('ref');
	                var view = _this.get(index);
	                if (entry.isIntersecting && entry.intersectionRatio > 0.0) {
	                    if (!view.displayed) {
	                        console.log("AHOY OBSERVING", entries.length, index, 'onEnter');
	                        _this.onEnter(view);
	                    }
	                } else if (view && view.displayed) {
	                    console.log("AHOY OBSERVING", entries.length, index, 'onExit');
	                    _this.onExit(view);
	                }
	            });
	        }
	    }, {
	        key: 'prepend',
	        value: function prepend(view) {
	            this._views.unshift(view);
	            if (this.container) {
	                this.container.insertBefore(view.element, this.container.firstChild);
	            }
	            this.length++;
	            return view;
	        }

	        // insert(view, index) {
	        //     this._views.splice(index, 0, view);

	        //     if(this.container){
	        //         if(index < this.container.children.length){
	        //             this.container.insertBefore(view.element, this.container.children[index]);
	        //         } else {
	        //             this.container.appendChild(view.element);
	        //         }
	        //     }

	        //     this.length++;
	        //     return view;
	        // }

	        // remove(view) {
	        //     var index = this._views.indexOf(view);

	        //     if(index > -1) {
	        //         this._views.splice(index, 1);
	        //     }


	        //     this.destroy(view);

	        //     this.length--;
	        // }

	    }, {
	        key: 'destroy',
	        value: function destroy(view) {
	            // if(view.displayed){
	            //     view.destroy();
	            // }
	            this.observer.unobserve(view.element);
	            view.destroy();

	            if (this.container) {
	                this.container.removeChild(view.element);
	            }
	            view = null;
	        }

	        // Iterators

	    }, {
	        key: 'forEach',
	        value: function forEach() {
	            // return this._views.forEach.apply(this._views, arguments);
	            return this.displayed().forEach.apply(this._views, arguments);
	        }
	    }, {
	        key: 'clear',
	        value: function clear() {
	            // Remove all views
	            var view;
	            var len = this.length;

	            if (!this.length) return;

	            for (var i = 0; i < len; i++) {
	                view = this._views[i];
	                this.destroy(view);
	            }

	            this._views = [];
	            this.length = 0;
	            this.observer.disconnect();
	        }
	    }, {
	        key: 'updateLayout',
	        value: function updateLayout(options) {
	            var width = options.width;
	            var height = options.height;
	            this._views.forEach(function (view) {
	                view.size(width, height);
	                if (view.contents) {
	                    view.contents.size(width, height);
	                }
	            });
	        }
	    }, {
	        key: 'find',
	        value: function find(section) {

	            var view;
	            var len = this.length;

	            for (var i = 0; i < len; i++) {
	                view = this._views[i];
	                // view.displayed
	                if (view.section.index == section.index) {
	                    return view;
	                }
	            }
	        }
	    }, {
	        key: 'displayed',
	        value: function displayed() {
	            var displayed = [];
	            var view;
	            var len = this.length;

	            for (var i = 0; i < len; i++) {
	                view = this._views[i];

	                var _inVp = inVp(view.element, this.container),
	                    fully = _inVp.fully,
	                    partially = _inVp.partially,
	                    edges = _inVp.edges;

	                if ((fully || partially) && edges.percentage > 0 && view.displayed) {
	                    displayed.push(view);
	                }
	                // if(view.displayed){
	                //     displayed.push(view);
	                // }
	            }
	            return displayed;
	        }
	    }, {
	        key: 'show',
	        value: function show() {
	            var view;
	            var len = this.length;

	            for (var i = 0; i < len; i++) {
	                view = this._views[i];
	                if (view.displayed) {
	                    view.show();
	                }
	            }
	            this.hidden = false;
	        }
	    }, {
	        key: 'hide',
	        value: function hide() {
	            var view;
	            var len = this.length;

	            for (var i = 0; i < len; i++) {
	                view = this._views[i];
	                if (view.displayed) {
	                    // console.log("AHOY VIEWS hide", view.index);
	                    view.hide();
	                }
	            }
	            this.hidden = true;
	        }
	    }, {
	        key: 'onEnter',
	        value: function onEnter(view, el, viewportState) {
	            // console.log("AHOY VIEWS onEnter", view.index, view.preloaded, view.displayed);
	            var preload = !view.displayed || view.preloaded;
	            if (!view.displayed) {
	                // console.log("AHOY SHOULD BE SHOWING", view);
	                this.emit("view.display", { view: view, viewportState: viewportState });
	            }
	            if (this.preloading && preload) {
	                // can we grab the next one?
	                this.preload(this.next(view), view.index);
	                this.preload(this.prev(view), view.index);
	            }
	            if (!view.displayed && view.preloaded) {
	                // console.log("AHOY VIEWS onEnter TOGGLE", view.index, view.preloaded, view.displayed);
	                view.preloaded = false;
	            }
	        }
	    }, {
	        key: 'preload',
	        value: function preload(view, index) {
	            if (view) {
	                view.preloaded = true;
	                // console.log("AHOY VIEWS preload", index, ">", view.index);
	                this.emit("view.preload", { view: view });
	            }
	        }
	    }, {
	        key: 'onExit',
	        value: function onExit(view, el, viewportState) {
	            // console.log("AHOY VIEWS onExit", view.index, view.preloaded);
	            if (view.preloaded) {
	                return;
	            }
	            view.unload();
	        }
	    }]);

	    return Views;
	}();

	eventEmitter$1(Views$1.prototype);

	var _createClass$y = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck$y(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	// import inVp from "in-vp";

	var ScrollingContinuousViewManager = function () {
	  function ScrollingContinuousViewManager(options) {
	    _classCallCheck$y(this, ScrollingContinuousViewManager);

	    this.name = "scrolling";
	    this.optsSettings = options.settings;
	    this.View = options.view;
	    this.request = options.request;
	    this.renditionQueue = options.queue;
	    this.q = new Queue(this);

	    this.settings = extend$1(this.settings || {}, {
	      infinite: true,
	      hidden: false,
	      width: undefined,
	      height: undefined,
	      axis: undefined,
	      flow: "scrolled",
	      ignoreClass: "",
	      fullsize: undefined,
	      minHeight: 1024
	    });

	    extend$1(this.settings, options.settings || {});

	    this.viewSettings = {
	      ignoreClass: this.settings.ignoreClass,
	      axis: this.settings.axis,
	      flow: this.settings.flow,
	      layout: this.layout,
	      method: this.settings.method, // srcdoc, blobUrl, write
	      width: 0,
	      height: 0,
	      forceEvenPages: true
	    };

	    this.rendered = false;
	    this.settings.scale = this.settings.scale || 1.0;
	    this.settings.xscale = this.settings.scale;

	    this.fraction = 0.8;
	    // this.settings.maxWidth = 1024;
	  }

	  _createClass$y(ScrollingContinuousViewManager, [{
	    key: "render",
	    value: function render(element, size) {
	      var tag = element.tagName;

	      if (typeof this.settings.fullsize === "undefined" && tag && (tag.toLowerCase() == "body" || tag.toLowerCase() == "html")) {
	        this.settings.fullsize = true;
	      }

	      if (this.settings.fullsize) {
	        this.settings.overflow = "visible";
	        this.overflow = this.settings.overflow;
	      }

	      this.settings.size = size;

	      // Save the stage
	      this.stage = new Stage({
	        width: size.width,
	        height: size.height,
	        overflow: this.overflow,
	        hidden: this.settings.hidden,
	        axis: this.settings.axis,
	        fullsize: this.settings.fullsize,
	        direction: this.settings.direction,
	        scale: 1.0 // this.settings.scale --- scrolling scales different
	      });

	      this.stage.attachTo(element);

	      // Get this stage container div
	      this.container = this.stage.getContainer();

	      // Views array methods
	      this.views = new Views$1(this.container, this.layout.name == 'pre-paginated');

	      // Calculate Stage Size
	      this._bounds = this.bounds();
	      this._stageSize = this.stage.size();

	      var ar = this._stageSize.width / this._stageSize.height;
	      console.log("AHOY STAGE", this._stageSize.width, this._stageSize.height, ">", ar);

	      // Set the dimensions for views
	      this.viewSettings.width = this._stageSize.width;
	      this.viewSettings.height = this._stageSize.height;

	      // Function to handle a resize event.
	      // Will only attach if width and height are both fixed.
	      this.stage.onResize(this.onResized.bind(this));

	      this.stage.onOrientationChange(this.onOrientationChange.bind(this));

	      // Add Event Listeners
	      this.addEventListeners();

	      // Add Layout method
	      // this.applyLayoutMethod();
	      if (this.layout) {
	        this.updateLayout();
	      }

	      this.rendered = true;
	      this._spine = [];

	      this.views.on("view.preload", function (_ref) {
	        var view = _ref.view;

	        view.display(this.request).then(function () {
	          view.show();
	        });
	      }.bind(this));

	      this.views.on("view.display", function (_ref2) {
	        var view = _ref2.view,
	            viewportState = _ref2.viewportState;

	        // console.log("AHOY VIEWS scrolling.view.display", view.index);
	        view.display(this.request).then(function () {
	          view.show();
	          this.gotoTarget(view);
	          {
	            this.emit(EVENTS.MANAGERS.SCROLLED, {
	              top: this.scrollTop,
	              left: this.scrollLeft
	            });
	            this._forceLocationEvent = false;
	          }
	        }.bind(this));
	      }.bind(this));
	    }
	  }, {
	    key: "display",
	    value: function display(section, target) {
	      var displaying = new defer();
	      var displayed = displaying.promise;

	      if (!this.views.length) {
	        this.initializeViews(section);
	      }

	      // Check if moving to target is needed
	      if (target === section.href || isNumber(target)) {
	        target = undefined;
	      }

	      var current = this.current();

	      this.ignore = false;
	      var visible = this.views.find(section);

	      // console.log("AHOY scrolling display", section, visible, current, current == visible);

	      if (target) {
	        this._target = [visible, target];
	      }

	      visible.element.scrollIntoView();

	      if (visible == current) {
	        this.gotoTarget(visible);
	      }

	      displaying.resolve();
	      return displayed;
	    }
	  }, {
	    key: "gotoTarget",
	    value: function gotoTarget(view) {
	      if (this._target && this._target[0] == view) {
	        var offset = view.locationOf(this._target[1]);

	        // -- this does not work; top varies.
	        // offset.top += view.element.getBoundingClientRect().top;

	        setTimeout(function () {
	          offset.top += this.container.scrollTop;
	          this.moveTo(offset);
	          this._target = null;
	        }.bind(this), 10);

	        // var prev; var style;
	        // for(var i = 0; i < view.index; i++) {
	        //   prev = this.views.get(i);
	        //   style = window.getComputedStyle(prev.element);
	        //   offset.top += ( parseInt(style.height) / this.settings.scale ) + parseInt(style.marginBottom) + parseInt(style.marginTop);
	        //   // offset.top += prev.height() || prev.element.offsetHeight;
	        // }
	        // this.moveTo(offset);
	        // this._target = null;
	      }
	    }
	  }, {
	    key: "afterDisplayed",
	    value: function afterDisplayed(view) {
	      // if ( this._target && this._target[0] == view ) {
	      //   let offset = view.locationOf(this._target[1]);
	      //   this.moveTo(offset);
	      //   this._target = null;
	      // }
	      this.emit(EVENTS.MANAGERS.ADDED, view);
	    }
	  }, {
	    key: "afterResized",
	    value: function afterResized(view) {

	      var bounds = this.container.getBoundingClientRect();
	      var rect = view.element.getBoundingClientRect();

	      this.ignore = true;

	      // view.element.dataset.resizable = "true"
	      view.reframeElement();

	      var delta;
	      if (rect.bottom <= bounds.bottom && rect.top < 0) {
	        delta = view.element.getBoundingClientRect().height - rect.height;
	        // delta /= this.settings.scale;
	        // console.log("AHOY afterResized", view.index, this.container.scrollTop, view.element.getBoundingClientRect().height, rect.height, delta / this.settings.scale);
	        this.container.scrollTop += Math.ceil(delta);
	      }

	      // console.log("AHOY AFTER RESIZED", view, delta);
	      this.emit(EVENTS.MANAGERS.RESIZE, view.section);
	    }
	  }, {
	    key: "moveTo",
	    value: function moveTo(offset) {
	      var distX = 0,
	          distY = 0;
	      distY = offset.top;
	      // this.scrollTo(distX, this.container.scrollTop + distY, true);
	      this.scrollTo(distX, distY, false);
	    }
	  }, {
	    key: "initializeViews",
	    value: function initializeViews(section) {

	      this.ignore = true;

	      // if ( self._spine.length == 0 ) {
	      //   console.time("AHOY initializeViews CRAWL");
	      //   // can we build a manifest here?
	      //   var prev_ = section.prev();
	      //   while ( prev_ ) {
	      //     // self._spine.unshift(prev_.href);
	      //     self._spine.unshift(prev_);
	      //     prev_ = prev_.prev();
	      //   }

	      //   self._spine.push(section);

	      //   var next_ = section.next();
	      //   while ( next_ ) {
	      //     // self._spine.push(next_.href);
	      //     self._spine.push(next_);
	      //     next_ = next_.next();
	      //   }

	      //   console.timeEnd("AHOY initializeViews CRAWL");
	      // }

	      // this._spine.forEach(function (section) {

	      this.settings.spine.each(function (section) {
	        var _this = this;

	        // if ( this.layout.name == 'pre-paginated' ) {
	        //   // do something
	        //   // viewSettings.layout.height = h;
	        //   // viewSettings.layout.columnWidth = w;

	        //   var r = this.layout.height / this.layout.columnWidth;

	        //   viewSettings.layout.columnWidth = this.layout.columnWidth * 0.8;
	        //   viewSettings.layout.height = this.layout.height * ( this.layout.columnWidth)

	        // }
	        var viewSettings = Object.assign({}, this.viewSettings);
	        viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
	        if (this.layout.name == 'pre-paginated') {
	          viewSettings.layout.columnWidth = this.calcuateWidth(viewSettings.layout.columnWidth); // *= ( this.fraction * this.settings.xscale );
	          viewSettings.layout.width = this.calcuateWidth(viewSettings.layout.width); // *= ( this.fraction * this.settings.xscale );
	          viewSettings.minHeight *= this.settings.xscale;
	          viewSettings.maxHeight = viewSettings.height * this.settings.xscale;
	          viewSettings.height = viewSettings.height * this.settings.xscale;
	          viewSettings.layout.height = viewSettings.height;
	          // console.log("AHOY new view", section.index, viewSettings.height);
	        }

	        var view = new this.View(section, viewSettings);
	        view.onDisplayed = this.afterDisplayed.bind(this);
	        view.onResize = this.afterResized.bind(this);
	        view.on(EVENTS.VIEWS.AXIS, function (axis) {
	          _this.updateAxis(axis);
	        });
	        this.views.append(view);
	      }.bind(this));

	      this.ignore = false;
	    }
	  }, {
	    key: "direction",
	    value: function direction() {
	      var dir = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : "ltr";

	      this.settings.direction = dir;

	      this.stage && this.stage.direction(dir);

	      this.viewSettings.direction = dir;

	      this.updateLayout();
	    }
	  }, {
	    key: "onOrientationChange",
	    value: function onOrientationChange(e) {}
	  }, {
	    key: "onResized",
	    value: function onResized(e) {
	      // if ( this.resizeTimeout ) {
	      //   clearTimeout(this.resizeTimeout);
	      // } else {
	      //   // this._current = this.current() && this.current().section;
	      //   // this._current = { view: this.current(), location: this.currentLocation() };
	      // }
	      // this.resizeTimeout = setTimeout(this.resize.bind(this), 100);
	      this.resize();
	    }
	  }, {
	    key: "resize",
	    value: function resize(width, height) {
	      var stageSize = this.stage.size(width, height);
	      if (this.resizeTimeout) {
	        clearTimeout(this.resizeTimeout);
	        this.resizeTimeout = null;
	      }

	      this.ignore = true;

	      // For Safari, wait for orientation to catch up
	      // if the window is a square
	      this.winBounds = windowBounds();
	      if (this.orientationTimeout && this.winBounds.width === this.winBounds.height) {
	        // reset the stage size for next resize
	        this._stageSize = undefined;
	        return;
	      }

	      if (this._stageSize && this._stageSize.width === stageSize.width && this._stageSize.height === stageSize.height) {
	        // Size is the same, no need to resize
	        return;
	      }

	      this._stageSize = stageSize;

	      this._bounds = this.bounds();

	      // if ( ! this._resizeTarget ) {
	      //   var current = this.current();
	      //   if ( current ) {
	      //     this._resizeTarget = current.section;
	      //   }
	      // }

	      this.clear();

	      // Update for new views
	      this.viewSettings.width = this._stageSize.width;
	      this.viewSettings.height = this._stageSize.height;

	      this.updateLayout();

	      // var section; var target;
	      // if ( this._current ) {
	      //   section = this._current.view.section;
	      //   target = this._current.location[0].mapping.start;
	      //   this._current = null;
	      // } else {
	      //   section = this._spine[0];
	      // }
	      // this.initializeViews(section);
	      // this.display(section, target);

	      // this.views.updateLayout(this.viewSettings);

	      this.emit(EVENTS.MANAGERS.RESIZED, {
	        width: this._stageSize.width,
	        height: this._stageSize.height
	      });
	    }
	  }, {
	    key: "updateAxis",
	    value: function updateAxis(axis, forceUpdate) {
	      if (!this.isPaginated) {
	        axis = "vertical";
	      }

	      if (!forceUpdate && axis === this.settings.axis) {
	        return;
	      }

	      this.settings.axis = axis;

	      this.stage && this.stage.axis(axis);

	      this.viewSettings.axis = axis;

	      if (this.mapping) {
	        this.mapping = new Mapping(this.layout.props, this.settings.direction, this.settings.axis);
	      }

	      if (this.layout) {
	        this.layout.spread("none");
	      }
	    }
	  }, {
	    key: "updateFlow",
	    value: function updateFlow(flow) {
	      this.isPaginated = false;
	      this.updateAxis("vertical");

	      this.viewSettings.flow = flow;

	      if (!this.settings.overflow) {
	        this.overflow = this.isPaginated ? "hidden" : "auto";
	      } else {
	        this.overflow = this.settings.overflow;
	      }

	      this.stage && this.stage.overflow(this.overflow);

	      this.updateLayout();
	    }
	  }, {
	    key: "getContents",
	    value: function getContents() {
	      var contents = [];
	      if (!this.views) {
	        return contents;
	      }
	      this.views.forEach(function (view) {
	        var viewContents = view && view.contents;
	        if (viewContents) {
	          contents.push(viewContents);
	        }
	      });
	      return contents;
	    }
	  }, {
	    key: "current",
	    value: function current() {
	      var visible = this.visible();
	      var view;
	      if (visible.length) {
	        // Current is the last visible view
	        var current = null;
	        for (var i = 0; i < visible.length; i++) {
	          view = visible[i];

	          var _inVp = inVp(view.element, this.container),
	              edges = _inVp.edges;

	          if (!current) {
	            current = view;current.percentage = edges.percentage;
	          } else if (edges.percentage > current.percentage) {
	            current = view;
	            current.percentage = edges.percentage;
	          }
	        }
	        if (current) {
	          return current;
	        }
	        return visible[visible.length - 1];
	      }
	      return null;
	    }
	  }, {
	    key: "visible",
	    value: function visible() {
	      var visible = [];
	      var views = this.views.displayed();
	      var viewsLength = views.length;
	      var visible = [];
	      var view;

	      return this.views.displayed();

	      for (var i = 0; i < viewsLength; i++) {
	        view = views[i];
	        if (view.displayed) {
	          visible.push(view);
	        }
	      }

	      return visible;
	    }
	  }, {
	    key: "scrollBy",
	    value: function scrollBy(x, y, silent) {
	      var dir = this.settings.direction === "rtl" ? -1 : 1;

	      if (silent) {
	        this.ignore = true;
	      }

	      if (!this.settings.fullsize) {
	        if (x) this.container.scrollLeft += x * dir;
	        if (y) this.container.scrollTop += y;
	      } else {
	        window.scrollBy(x * dir, y * dir);
	      }
	      this.scrolled = true;
	    }
	  }, {
	    key: "scrollTo",
	    value: function scrollTo(x, y, silent) {
	      if (silent) {
	        this.ignore = true;
	      }

	      if (!this.settings.fullsize) {
	        this.container.scrollLeft = x;
	        this.container.scrollTop = y;
	      } else {
	        window.scrollTo(x, y);
	      }
	      this.scrolled = true;
	    }
	  }, {
	    key: "onScroll",
	    value: function onScroll() {
	      var scrollTop = void 0;
	      var scrollLeft = void 0;

	      if (!this.settings.fullsize) {
	        scrollTop = this.container.scrollTop;
	        scrollLeft = this.container.scrollLeft;
	      } else {
	        scrollTop = window.scrollY;
	        scrollLeft = window.scrollX;
	      }

	      this.scrollTop = scrollTop;
	      this.scrollLeft = scrollLeft;

	      if (!this.ignore) {
	        this.emit(EVENTS.MANAGERS.SCROLL, {
	          top: scrollTop,
	          left: scrollLeft
	        });

	        clearTimeout(this.afterScrolled);
	        this.afterScrolled = setTimeout(function () {
	          this.emit(EVENTS.MANAGERS.SCROLLED, {
	            top: this.scrollTop,
	            left: this.scrollLeft
	          });
	        }.bind(this), 20);
	      } else {
	        this.ignore = false;
	      }
	    }
	  }, {
	    key: "bounds",
	    value: function bounds() {
	      var bounds;

	      bounds = this.stage.bounds();

	      return bounds;
	    }
	  }, {
	    key: "applyLayout",
	    value: function applyLayout(layout) {
	      this.layout = layout;
	      this.updateLayout();
	    }
	  }, {
	    key: "updateLayout",
	    value: function updateLayout() {
	      if (!this.stage) {
	        return;
	      }

	      this._stageSize = this.stage.size();
	      this.layout.calculate(this._stageSize.width, this._stageSize.height);
	      // this.layout.width = this.container.offsetWidth * 0.80;

	      // Set the dimensions for views
	      this.viewSettings.width = this.layout.width; //  * this.settings.scale;
	      this.viewSettings.height = this.calculateHeight(this.layout.height);
	      this.viewSettings.minHeight = this.viewSettings.height; // * this.settings.scale;

	      this.setLayout(this.layout);
	    }
	  }, {
	    key: "setLayout",
	    value: function setLayout(layout) {

	      this.viewSettings.layout = layout;

	      this.mapping = new Mapping(layout.props, this.settings.direction, this.settings.axis);

	      if (this.views) {

	        this.views._views.forEach(function (view) {
	          var viewSettings = Object.assign({}, this.viewSettings);
	          viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
	          if (this.layout.name == 'pre-paginated') {
	            viewSettings.layout.columnWidth = this.calcuateWidth(viewSettings.layout.columnWidth); // *= ( this.fraction * this.settings.xscale );
	            viewSettings.layout.width = this.calcuateWidth(viewSettings.layout.width); // *= ( this.fraction * this.settings.xscale );
	            viewSettings.minHeight *= this.settings.xscale;
	            viewSettings.maxHeight = viewSettings.height * this.settings.xscale;
	            viewSettings.height = viewSettings.height * this.settings.xscale;
	            viewSettings.layout.height = viewSettings.height;
	          }

	          view.size(viewSettings.layout.width, viewSettings.layout.height);
	          view.reframe(viewSettings.layout.width, viewSettings.layout.height);
	          view.setLayout(viewSettings.layout);
	        });

	        // this.views.forEach(function(view){
	        //   if (view) {
	        //     view.reframe(layout.width, layout.height);
	        //     view.setLayout(layout);
	        //   }
	        // });
	      }
	    }
	  }, {
	    key: "addEventListeners",
	    value: function addEventListeners() {
	      var scroller;

	      window.addEventListener("unload", function (e) {
	        this.destroy();
	      }.bind(this));

	      if (!this.settings.fullsize) {
	        scroller = this.container;
	      } else {
	        scroller = window;
	      }

	      this._onScroll = this.onScroll.bind(this);
	      scroller.addEventListener("scroll", this._onScroll);
	    }
	  }, {
	    key: "removeEventListeners",
	    value: function removeEventListeners() {
	      var scroller;

	      if (!this.settings.fullsize) {
	        scroller = this.container;
	      } else {
	        scroller = window;
	      }

	      scroller.removeEventListener("scroll", this._onScroll);
	      this._onScroll = undefined;
	    }
	  }, {
	    key: "destroy",
	    value: function destroy() {
	      clearTimeout(this.orientationTimeout);
	      clearTimeout(this.resizeTimeout);
	      clearTimeout(this.afterScrolled);

	      this.clear();

	      this.removeEventListeners();

	      this.stage.destroy();

	      this.rendered = false;

	      /*
	         clearTimeout(this.trimTimeout);
	        if(this.settings.hidden) {
	          this.element.removeChild(this.wrapper);
	        } else {
	          this.element.removeChild(this.container);
	        }
	      */
	    }
	  }, {
	    key: "next",
	    value: function next() {

	      var displaying = new defer();
	      var displayed = displaying.promise;

	      var dir = this.settings.direction;

	      if (!this.views.length) return;

	      this.scrollTop = this.container.scrollTop;

	      var top = this.container.scrollTop + this.container.offsetHeight;

	      this.scrollBy(0, this.layout.height, false);

	      this.q.enqueue(function () {
	        displaying.resolve();
	        return displayed;
	      });
	    }
	  }, {
	    key: "prev",
	    value: function prev() {

	      var displaying = new defer();
	      var displayed = displaying.promise;

	      var dir = this.settings.direction;

	      if (!this.views.length) return;

	      this.scrollTop = this.container.scrollTop;

	      var top = this.container.scrollTop - this.container.offsetHeight;
	      this.scrollBy(0, -this.layout.height, false);

	      this.q.enqueue(function () {
	        displaying.resolve();
	        return displayed;
	      });
	    }
	  }, {
	    key: "clear",
	    value: function clear() {

	      // // this.q.clear();

	      if (this.views) {
	        this.views.hide();
	        this.scrollTo(0, 0, true);
	        this.views.clear();
	      }
	    }
	  }, {
	    key: "currentLocation",
	    value: function currentLocation() {
	      var _this2 = this;

	      var visible = this.visible();
	      var container = this.container.getBoundingClientRect();
	      var pageHeight = container.height < window.innerHeight ? container.height : window.innerHeight;

	      var offset = 0;
	      var used = 0;

	      if (this.settings.fullsize) {
	        offset = window.scrollY;
	      }

	      var sections = visible.map(function (view) {
	        var _view$section = view.section,
	            index = _view$section.index,
	            href = _view$section.href;

	        var position = view.position();
	        var height = view.height();

	        var startPos = offset + container.top - position.top + used;
	        var endPos = startPos + pageHeight - used;
	        if (endPos > height) {
	          endPos = height;
	          used = endPos - startPos;
	        }

	        var totalPages = _this2.layout.count(height, pageHeight).pages;

	        var currPage = Math.ceil(startPos / pageHeight);
	        var pages = [];
	        var endPage = Math.ceil(endPos / pageHeight);

	        pages = [];
	        for (var i = currPage; i <= endPage; i++) {
	          var pg = i + 1;
	          pages.push(pg);
	        }

	        totalPages = pages.length;

	        var mapping = _this2.mapping.page(view.contents, view.section.cfiBase, startPos, endPos);

	        return {
	          index: index,
	          href: href,
	          pages: pages,
	          totalPages: totalPages,
	          mapping: mapping
	        };
	      });

	      if (sections.length == 0) {
	        self._forceLocationEvent = true;
	      }

	      return sections;
	    }
	  }, {
	    key: "isRendered",
	    value: function isRendered() {
	      return this.rendered;
	    }
	  }, {
	    key: "scale",
	    value: function scale(s) {
	      if (s == null) {
	        s = 1.0;
	      }
	      this.settings.scale = this.settings.xscale = s;

	      // if (this.stage) {
	      //   this.stage.scale(s);
	      // }

	      this.clear();
	      this.updateLayout();
	      this.emit(EVENTS.MANAGERS.RESIZED, {
	        width: this._stageSize.width,
	        height: this._stageSize.height
	      });
	    }
	  }, {
	    key: "calcuateWidth",
	    value: function calcuateWidth(width) {
	      var retval = width * this.fraction * this.settings.xscale;
	      // if ( retval > this.settings.maxWidth * this.settings.xscale ) {
	      //   retval = this.settings.maxWidth * this.settings.xscale;
	      // }
	      return retval;
	    }
	  }, {
	    key: "calculateHeight",
	    value: function calculateHeight(height) {
	      var minHeight = this.layout.name == 'xxpre-paginated' ? 0 : this.settings.minHeight;
	      return height > minHeight ? this.layout.height : this.settings.minHeight;
	    }
	  }]);

	  return ScrollingContinuousViewManager;
	}();

	ScrollingContinuousViewManager.toString = function () {
	  return 'continuous';
	};

	//-- Enable binding events to Manager
	eventEmitter$1(ScrollingContinuousViewManager.prototype);

	function Viewport(t,e){var i=this;this.container=t,this.observers=[],this.lastX=0,this.lastY=0;var o=!1,n=function(){o||(o=!0,requestAnimationFrame(function(){for(var t=i.observers,e=i.getState(),n=t.length;n--;)t[n].check(e);i.lastX=e.positionX,i.lastY=e.positionY,o=!1;}));},r=e.handleScrollResize,s=this.handler=r?r(n):n;addEventListener("scroll",s,!0),addEventListener("resize",s,!0),addEventListener("DOMContentLoaded",function(){(i.mutationObserver=new MutationObserver(n)).observe(document,{attributes:!0,childList:!0,subtree:!0});});}function Observer(t){return this.offset=~~t.offset||0,this.container=t.container||document.body,this.once=Boolean(t.once),this.observerCollection=t.observerCollection||defaultObserverCollection,this.activate()}function ObserverCollection(t){for(var e=arguments.length,i=Array(e);e--;)i[e]=arguments[e];if(void 0===t&&(t={}),!(this instanceof ObserverCollection))return new(Function.prototype.bind.apply(ObserverCollection,[null].concat(i)));this.viewports=new Map,this.handleScrollResize=t.handleScrollResize;}Viewport.prototype={getState:function(){var t,e,i,o,n=this.container,r=this.lastX,s=this.lastY;return n===document.body?(t=window.innerWidth,e=window.innerHeight,i=window.pageXOffset,o=window.pageYOffset):(t=n.offsetWidth,e=n.offsetHeight,i=n.scrollLeft,o=n.scrollTop),{width:t,height:e,positionX:i,positionY:o,directionX:r<i?"right":r>i?"left":"none",directionY:s<o?"down":s>o?"up":"none"}},destroy:function(){var t=this.handler,e=this.mutationObserver;removeEventListener("scroll",t),removeEventListener("resize",t),e&&e.disconnect();}},Observer.prototype={activate:function(){var t=this.container,e=this.observerCollection,i=e.viewports,o=i.get(t);o||(o=new Viewport(t,e),i.set(t,o));var n=o.observers;return n.indexOf(this)<0&&n.push(this),o},destroy:function(){var t=this.container,e=this.observerCollection.viewports,i=e.get(t);if(i){var o=i.observers,n=o.indexOf(this);n>-1&&o.splice(n,1),o.length||(i.destroy(),e.delete(t));}}};var defaultObserverCollection=new ObserverCollection;function PositionObserver(t){for(var e=arguments.length,i=Array(e);e--;)i[e]=arguments[e];if(void 0===t&&(t={}),!(this instanceof PositionObserver))return new(Function.prototype.bind.apply(PositionObserver,[null].concat(i)));this.onTop=t.onTop,this.onBottom=t.onBottom,this.onLeft=t.onLeft,this.onRight=t.onRight,this.onMaximized=t.onMaximized,this._wasTop=!0,this._wasBottom=!1,this._wasLeft=!0,this._wasRight=!1;var o=Observer.call(this,t);this.check(o.getState());}function ElementObserver(t,e){for(var i=arguments.length,o=Array(i);i--;)o[i]=arguments[i];if(void 0===e&&(e={}),!(this instanceof ElementObserver))return new(Function.prototype.bind.apply(ElementObserver,[null].concat(o)));this.element=t,this.onEnter=e.onEnter,this.onExit=e.onExit,this._didEnter=!1;var n=Observer.call(this,e);isElementInDOM(t)&&this.check(n.getState());}function isElementInViewport(t,e,i,o){var n,r,s,h,l=t.getBoundingClientRect();if(!l.width||!l.height)return !1;var a=window.innerWidth,c=window.innerHeight,v=a;if(o===document.body)n=c,r=0,s=v,h=0;else{if(!(l.top<c&&l.bottom>0&&l.left<v&&l.right>0))return !1;var d=o.getBoundingClientRect();n=d.bottom,r=d.top,s=d.right,h=d.left;}return l.top<n+e&&l.bottom>r-e&&l.left<s+e&&l.right>h-e}function isElementInDOM(t){return t&&t.parentNode}PositionObserver.prototype=Object.create(Observer.prototype),PositionObserver.prototype.constructor=PositionObserver,PositionObserver.prototype.check=function(t){var e=this,i=e.onTop,o=e.onBottom,n=e.onLeft,r=e.onRight,s=e.onMaximized,h=e._wasTop,l=e._wasBottom,a=e._wasLeft,c=e._wasRight,v=e.container,d=e.offset,p=e.once,f=v.scrollHeight,b=v.scrollWidth,u=t.width,w=t.height,O=t.positionX,m=t.positionY,g=m-d<=0,y=f>w&&w+m+d>=f,E=O-d<=0,_=b>u&&u+O+d>=b,C=!1;o&&!l&&y?o.call(this,v,t):i&&!h&&g?i.call(this,v,t):r&&!c&&_?r.call(this,v,t):n&&!a&&E?n.call(this,v,t):s&&f===w?s.call(this,v,t):C=!0,p&&!C&&this.destroy(),this._wasTop=g,this._wasBottom=y,this._wasLeft=E,this._wasRight=_;},ElementObserver.prototype=Object.create(Observer.prototype),ElementObserver.prototype.constructor=ElementObserver,ElementObserver.prototype.check=function(t){var e=this.container,i=this.onEnter,o=this.onExit,n=this.element,r=this.offset,s=this.once,h=this._didEnter;if(!isElementInDOM(n))return this.destroy();var l=isElementInViewport(n,r,t,e);!h&&l?(this._didEnter=!0,i&&(i.call(this,n,t),s&&this.destroy())):h&&!l&&(this._didEnter=!1,o&&(o.call(this,n,t),s&&this.destroy()));};

	var _createClass$z = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	var _get$2 = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

	function _classCallCheck$z(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn$4(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits$4(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var StickyIframeView = function (_IframeView) {
	    _inherits$4(StickyIframeView, _IframeView);

	    function StickyIframeView(section, options) {
	        _classCallCheck$z(this, StickyIframeView);

	        var _this = _possibleConstructorReturn$4(this, (StickyIframeView.__proto__ || Object.getPrototypeOf(StickyIframeView)).call(this, section, options));

	        _this.element.style.height = _this.layout.height + "px";
	        _this.element.style.width = _this.layout.width + "px";
	        _this.element.style.visibility = "hidden";

	        // console.log("AHOY sticky NEW", this.layout.height);
	        return _this;
	    }

	    _createClass$z(StickyIframeView, [{
	        key: "container",
	        value: function container(axis) {
	            var check = document.querySelector("div[ref='" + this.index + "']");
	            if (check) {
	                check.dataset.reused = 'true';
	                return check;
	            }

	            var element = document.createElement("div");

	            element.classList.add("epub-view");

	            // this.element.style.minHeight = "100px";
	            element.style.height = "0px";
	            element.style.width = "0px";
	            element.style.overflow = "hidden";
	            element.style.position = "relative";
	            element.style.display = "block";

	            element.setAttribute('ref', this.index);

	            if (axis && axis == "horizontal") {
	                element.style.flex = "none";
	            } else {
	                element.style.flex = "initial";
	            }

	            return element;
	        }
	    }, {
	        key: "create",
	        value: function create() {

	            if (this.iframe) {
	                return this.iframe;
	            }

	            if (!this.element) {
	                this.element = this.createContainer();
	            }

	            if (this.element.hasAttribute('layout-height')) {
	                var height = parseInt(this.element.getAttribute('layout-height'), 10);
	                this._layout_height = height;
	            }

	            this.iframe = this.element.querySelector("iframe");
	            if (this.iframe) {
	                return this.iframe;
	            }

	            this.iframe = document.createElement("iframe");
	            this.iframe.id = this.id;
	            this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations
	            this.iframe.style.overflow = "hidden";
	            this.iframe.seamless = "seamless";
	            // Back up if seamless isn't supported
	            this.iframe.style.border = "none";

	            this.iframe.setAttribute("enable-annotation", "true");

	            this.resizing = true;

	            // this.iframe.style.display = "none";
	            this.element.style.visibility = "hidden";
	            this.iframe.style.visibility = "hidden";
	            this.element.classList.add('epub-view---loading');

	            this.iframe.style.width = "0";
	            this.iframe.style.height = "0";
	            this._width = 0;
	            this._height = 0;

	            this.element.setAttribute("ref", this.index);
	            this.element.setAttribute("data-href", this.section.href);

	            // this.element.appendChild(this.iframe);
	            this.added = true;

	            this.elementBounds = bounds$1(this.element);

	            // if(width || height){
	            //   this.resize(width, height);
	            // } else if(this.width && this.height){
	            //   this.resize(this.width, this.height);
	            // } else {
	            //   this.iframeBounds = bounds(this.iframe);
	            // }


	            if ("srcdoc" in this.iframe) {
	                this.supportsSrcdoc = true;
	            } else {
	                this.supportsSrcdoc = false;
	            }

	            if (!this.settings.method) {
	                this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
	            }

	            return this.iframe;
	        }
	    }, {
	        key: "reframe",
	        value: function reframe(width, height) {
	            var _this2 = this;

	            var size;

	            var minHeight = this.settings.minHeight || 0;
	            var maxHeight = this.settings.maxHeight || -1;

	            // console.log("AHOY AHOY reframe", this.index, width, height);

	            if (isNumber(width)) {
	                this.element.style.width = width + "px";
	                if (this.iframe) {
	                    this.iframe.style.width = width + "px";
	                }
	                this._width = width;
	            }

	            if (isNumber(height)) {
	                var checkMinHeight = false; // not doing this
	                if (isNumber(width) && width > height) {
	                    checkMinHeight = false;
	                }
	                height = checkMinHeight && height <= minHeight ? minHeight : height;

	                var styles = window.getComputedStyle(this.element);
	                // setting the element height is delayed
	                if (this.iframe) {
	                    this.iframe.style.height = height + "px";
	                }
	                // console.log("AHOY VIEW DISPLAY REFRAME", this.index, this.element.style.height, this.iframe && this.iframe.style.height);
	                this._height = height;
	            }

	            var widthDelta = this.prevBounds ? width - this.prevBounds.width : width;
	            var heightDelta = this.prevBounds ? height - this.prevBounds.height : height;

	            size = {
	                width: width,
	                height: height,
	                widthDelta: widthDelta,
	                heightDelta: heightDelta
	            };

	            this.pane && this.pane.render();

	            requestAnimationFrame(function () {
	                var mark = void 0;
	                for (var m in _this2.marks) {
	                    if (_this2.marks.hasOwnProperty(m)) {
	                        mark = _this2.marks[m];
	                        _this2.placeMark(mark.element, mark.range);
	                    }
	                }
	            });

	            this.onResize(this, size);

	            this.emit(EVENTS.VIEWS.RESIZED, size);

	            this.prevBounds = size;

	            this.elementBounds = bounds$1(this.element);
	        }
	    }, {
	        key: "reframeElement",
	        value: function reframeElement() {
	            if (!this.iframe) {
	                return;
	            }
	            // var height = this.iframe.contentDocument.body.offsetHeight;
	            var height = this.iframe.offsetHeight;
	            var styles = window.getComputedStyle(this.element);
	            var new_height = height + parseInt(styles.paddingTop) + parseInt(styles.paddingBottom);
	            this.element.style.height = new_height + "px";
	            // console.log("AHOY AFTER RESIZED ELEMENT", this.index, height, new_height, styles.paddingTop, styles.paddingBottom);
	        }
	    }, {
	        key: "display",
	        value: function display(request) {
	            var displayed = new defer();

	            if (!this.displayed) {

	                this.render(request).then(function () {

	                    this.emit(EVENTS.VIEWS.DISPLAYED, this);
	                    this.onDisplayed(this);

	                    this.displayed = true;
	                    displayed.resolve(this);
	                }.bind(this), function (err) {
	                    displayed.reject(err, this);
	                });
	            } else {
	                displayed.resolve(this);
	            }

	            return displayed.promise;
	        }
	    }, {
	        key: "show",
	        value: function show() {
	            _get$2(StickyIframeView.prototype.__proto__ || Object.getPrototypeOf(StickyIframeView.prototype), "show", this).call(this);
	            this.element.classList.remove('epub-view---loading');
	        }
	    }, {
	        key: "hide",
	        value: function hide() {
	            _get$2(StickyIframeView.prototype.__proto__ || Object.getPrototypeOf(StickyIframeView.prototype), "hide", this).call(this);
	        }
	    }, {
	        key: "onLoad",
	        value: function onLoad(event, promise) {
	            var _this3 = this;

	            this.window = this.iframe.contentWindow;
	            this.document = this.iframe.contentDocument;

	            this.contents = new Contents$1(this.document, this.document.body, this.section.cfiBase, this.section.index);
	            this.contents.axis = this.settings.axis;

	            this.rendering = false;

	            var link = this.document.querySelector("link[rel='canonical']");
	            if (link) {
	                link.setAttribute("href", this.section.canonical);
	            } else {
	                link = this.document.createElement("link");
	                link.setAttribute("rel", "canonical");
	                link.setAttribute("href", this.section.canonical);
	                this.document.querySelector("head").appendChild(link);
	            }

	            this.contents.on(EVENTS.CONTENTS.EXPAND, function () {
	                if (_this3.displayed && _this3.iframe) {
	                    _this3.expand();
	                    if (_this3.contents) {
	                        // console.log("AHOY EXPAND", this.index, this.layout.columnWidth, this.layout.height);
	                        _this3.layout.format(_this3.contents);
	                    }
	                }
	            });

	            this.contents.on(EVENTS.CONTENTS.RESIZE, function (e) {
	                if (_this3.displayed && _this3.iframe) {
	                    _this3.expand();
	                    if (_this3.contents) {
	                        // console.log("AHOY RESIZE", this.index, this.layout.columnWidth, this.layout.height);
	                        _this3.layout.format(_this3.contents);
	                    }
	                }
	            });

	            promise.resolve(this.contents);
	        }
	    }, {
	        key: "unload",
	        value: function unload() {

	            for (var cfiRange in this.highlights) {
	                this.unhighlight(cfiRange);
	            }

	            for (var _cfiRange in this.underlines) {
	                this.ununderline(_cfiRange);
	            }

	            for (var _cfiRange2 in this.marks) {
	                this.unmark(_cfiRange2);
	            }

	            if (this.pane) {
	                this.element.removeChild(this.pane.element);
	                this.pane = undefined;
	            }

	            if (this.blobUrl) {
	                revokeBlobUrl(this.blobUrl);
	            }

	            if (this.displayed) {
	                this.displayed = false;

	                this.removeListeners();

	                this.stopExpanding = true;
	                this.element.removeChild(this.iframe);
	                this.element.style.visibility = "hidden";

	                this.iframe = undefined;
	                this.contents = undefined;

	                // this._textWidth = null;
	                // this._textHeight = null;
	                // this._width = null;
	                // this._height = null;
	            }

	            // this.element.style.height = "0px";
	            // this.element.style.width = "0px";
	        }

	        // setLayout(layout) {

	        // }

	    }]);

	    return StickyIframeView;
	}(IframeView);

	function popupTables(reader, contents) {
	  var tables = contents.document.querySelectorAll('table');
	  var h = reader._rendition.manager.layout.height;
	  var clipped_tables = [];
	  for (var i = 0; i < tables.length; i++) {
	    var table = tables[i];
	    if (table.offsetHeight >= h * 0.75) {
	      clipped_tables.push(table);
	    }
	  }

	  if (!clipped_tables.length) {
	    return;
	  }

	  contents._originalHTML = contents.document.documentElement.outerHTML;

	  contents.addStylesheetRules({
	    'table.clipped': {
	      'break-inside': 'avoid',
	      'width': reader._rendition.manager.layout.columnWidth * 0.95 + 'px !important',
	      'table-layout': 'fixed'
	    },
	    'table.clipped tbody': {
	      'height': h * 0.25 + 'px !important',
	      overflow: 'scroll !important',
	      display: 'block !important',
	      position: 'relative !important',
	      width: '100%'
	    },
	    'table.clipped::after': {
	      content: "",
	      display: 'block',
	      break: 'all'
	    },
	    'div.clipped': {
	      position: 'absolute',
	      display: 'flex',
	      'align-items': 'center',
	      'justify-content': 'center',
	      top: '0px',
	      bottom: '0px',
	      right: '0px',
	      left: '0px',
	      'background-color': 'rgba(255, 255, 255, 0.75)'
	    },
	    'div.clipped button': {
	      cursor: 'pointer',
	      'background-color': '#000000',
	      color: '#ffffff',
	      margin: '2px 0',
	      border: '1px solid transparent',
	      'border-radius': '4px',
	      padding: '1rem 1rem',
	      'text-transform': 'uppercase'
	    },
	    'div.clipped button:active': {
	      transform: 'translateY(1px)',
	      filter: 'saturate(150%)'
	    },
	    'div.clipped button:hover, div.clipped button:focus': {
	      color: '#000000',
	      'border-color': 'currentColor',
	      'background-color': 'white'
	    }
	  });

	  reader._originalHTML = {};

	  clipped_tables.forEach(function (table) {
	    // find a dang background color
	    var element = table;
	    var styles;
	    var bgcolor;
	    while (bgcolor === undefined && element instanceof HTMLElement) {
	      styles = window.getComputedStyle(element);
	      if (styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent') {
	        bgcolor = styles.backgroundColor;
	        break;
	      }
	      element = element.parentNode;
	    }

	    if (!bgcolor) {
	      // no background color defined in the EPUB, so what is cozy-sun-bear using?
	      element = reader._panes['epub'];
	      while (bgcolor === undefined && element instanceof HTMLElement) {
	        styles = window.getComputedStyle(element);
	        if (styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent') {
	          bgcolor = styles.backgroundColor;
	          break;
	        }
	        element = element.parentNode;
	      }
	    }

	    if (!bgcolor) {
	      bgcolor = '#fff';
	    }

	    var tableHTML = table.outerHTML;

	    table.classList.add('clipped');

	    var div = document.createElement('div');
	    div.classList.add('clipped');
	    table.querySelector('tbody').appendChild(div);

	    var button = document.createElement('button');
	    button.innerText = 'Open table';

	    var tableId = table.getAttribute('data-id');
	    if (!tableId) {
	      var ts = new Date().getTime();
	      tableId = "table" + ts + Math.random(ts);
	      table.setAttribute('data-id', tableId);
	    }

	    reader._originalHTML[tableId] = tableHTML;
	    // button.dataset.tableHTML = tableHTML;
	    button.addEventListener('click', function (event) {
	      event.preventDefault();

	      var regex = /<body[^>]+>/;
	      var index0 = contents._originalHTML.search(regex);
	      var tableHTML = reader._originalHTML[tableId];
	      var newHTML = contents._originalHTML.substr(0, index0) + ('<body style="padding: 1.5rem; background: ' + bgcolor + '"><section>' + tableHTML + '</section></body></html>');

	      reader.popup({
	        title: 'View Table',
	        srcdoc: newHTML,
	        onLoad: function onLoad(contentDocument, modal) {
	          // adpated from epub.js#replaceLinks --- need to catch _any_ link
	          // to close the modal
	          var base = contentDocument.querySelector("base");
	          var location = base ? base.getAttribute("href") : undefined;

	          var links = contentDocument.querySelectorAll('a[href]');
	          for (var i = 0; i < links.length; i++) {
	            var link = links[i];
	            var href = link.getAttribute('href');
	            link.addEventListener('click', function (event) {
	              modal.closeModal();
	              var absolute = href.indexOf('://') > -1;
	              if (absolute) {
	                link.setAttribute('target', '_blank');
	              } else {
	                var linkUrl = new Url(href, location);
	                if (linkUrl) {
	                  event.preventDefault();
	                  reader.gotoPage(linkUrl.Path.path + (linkUrl.hash ? linkUrl.hash : ''));
	                }
	              }
	            });
	          }
	        }
	      });
	    });

	    div.appendChild(button);
	  });
	}

	Reader.EpubJS = Reader.extend({

	  initialize: function initialize(id, options) {
	    Reader.prototype.initialize.apply(this, arguments);
	    this._epubjs_ready = false;
	    window.xpath = path$1;
	  },

	  open: function open(target, callback) {
	    var self = this;
	    if (typeof target == 'function') {
	      callback = target;
	      target = undefined;
	    }
	    if (callback == null) {
	      callback = function callback() {};
	    }

	    self.rootfiles = [];

	    this.options.rootfilePath = this.options.rootfilePath || sessionStorage.getItem('rootfilePath');

	    var book_href = this.options.href;
	    var book_options = { packagePath: this.options.rootfilePath };
	    if (this.options.useArchive) {
	      book_href = book_href.replace(/\/(\w+)\/$/, '/$1/$1.sm.epub');
	      book_options.openAs = 'epub';
	    }
	    this._book = ePub(book_href, book_options);
	    sessionStorage.removeItem('rootfilePath');

	    this._book.loaded.navigation.then(function (toc) {
	      self._contents = toc;
	      self.metadata = self._book.packaging.metadata;

	      self.fire('updateContents', toc);
	      self.fire('updateTitle', self._book.packaging.metadata);
	    });
	    this._book.ready.then(function () {
	      self.parseRootfiles();

	      self.draw(target, callback);

	      if (self.metadata.layout == 'pre-paginated') {
	        // fake it with the spine
	        var locations = [];
	        self._book.spine.each(function (item) {
	          locations.push('epubcfi(' + item.cfiBase + '!/4/2)');
	          self.locations._locations.push('epubcfi(' + item.cfiBase + '!/4/2)');
	        });
	        self.locations.total = locations.length;
	        var t;
	        var f = function f() {
	          if (self._rendition && self._rendition.manager && self._rendition.manager.stage) {
	            var location = self._rendition.currentLocation();
	            if (location && location.start) {
	              self.fire('updateLocations', locations);
	              clearTimeout(t);
	              return;
	            }
	          }
	          t = setTimeout(f, 100);
	        };

	        t = setTimeout(f, 100);
	      } else {
	        self._book.locations.generate(1600).then(function (locations) {
	          // console.log("AHOY WUT", locations);
	          self.fire('updateLocations', locations);
	        });
	      }
	    });
	    // .then(callback);
	  },

	  parseRootfiles: function parseRootfiles() {
	    var self = this;
	    self._book.load(self._book.url.resolve("META-INF/container.xml")).then(function (containerDoc) {
	      var rootfiles = containerDoc.querySelectorAll("rootfile");
	      if (rootfiles.length > 1) {
	        for (var i = 0; i < rootfiles.length; i++) {
	          var rootfile = rootfiles[i];
	          var rootfilePath = rootfile.getAttribute('full-path');
	          var label = rootfile.getAttribute('rendition:label');
	          var layout = rootfile.getAttribute('rendition:layout');
	          self.rootfiles.push({
	            rootfilePath: rootfilePath,
	            label: label,
	            layout: layout
	          });
	        }
	      }
	    });
	  },

	  draw: function draw(target, callback) {
	    var self = this;

	    if (self._rendition && !self._rendition.draft) {
	      // self._unbindEvents();
	      var container = self._rendition.manager.container;
	      Object.keys(self._rendition.hooks).forEach(function (key) {
	        self._rendition.hooks[key].clear();
	      });
	      self._rendition.destroy();
	      self._rendition = null;
	    }

	    var key = self.metadata.layout;
	    var flow = this.options.flow;
	    if (self._cozyOptions[key] && self._cozyOptions[key].flow) {
	      flow = self._cozyOptions[key].flow;
	    }

	    if (flow == 'auto') {
	      if (this.metadata.layout == 'pre-paginated') {
	        if (this._container.offsetHeight <= this.options.forceScrolledDocHeight) {
	          flow = 'scrolled-doc';
	        }
	      } else {
	        flow = 'paginated';
	      }
	    }

	    // if ( flow == 'auto' && this.metadata.layout == 'pre-paginated' ) {
	    //   if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ){
	    //     flow = 'scrolled-doc';
	    //   }
	    // }

	    // var key = `${flow}/${self.metadata.layout}`;
	    if (self._cozyOptions[key]) {
	      if (self._cozyOptions[key].text_size) {
	        self.options.text_size = self._cozyOptions[key].text_size;
	      }
	      if (self._cozyOptions[key].scale) {
	        self.options.scale = self._cozyOptions[key].scale;
	      }
	    }

	    this.settings = { flow: flow, stylesheet: this.options.injectStylesheet };
	    this.settings.manager = this.options.manager || 'default';

	    // if ( this.settings.flow == 'auto' && this.metadata.layout == 'pre-paginated' ) {
	    //   // dumb check to see if the window is _tall_ enough to put
	    //   // two pages side by side
	    //   if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ) {
	    //     this.settings.flow = 'scrolled-doc';

	    //     // this.settings.manager = PrePaginatedContinuousViewManager;
	    //     // this.settings.view = ReusableIframeView;

	    //     this.settings.manager = ScrollingContinuousViewManager;
	    //     this.settings.view = StickyIframeView;
	    //     this.settings.width = '100%'; // 100%?
	    //     this.settings.spine = this._book.spine;
	    //   }
	    // }

	    if (this.settings.flow == 'auto' || this.settings.flow == 'paginated') {
	      this._panes['epub'].style.overflow = this.metadata.layout == 'pre-paginated' ? 'auto' : 'hidden';
	      this.settings.manager = 'default';
	    } else {
	      this._panes['epub'].style.overflow = 'auto';
	      if (this.settings.manager == 'default') {
	        // this.settings.manager = 'continuous';
	        this.settings.manager = ScrollingContinuousViewManager;
	        this.settings.view = StickyIframeView;
	        this.settings.width = '100%'; // 100%?
	        this.settings.spine = this._book.spine;
	      }
	    }

	    if (!callback) {
	      callback = function callback() {};
	    }

	    self.settings.height = '100%';
	    self.settings.width = '100%';
	    self.settings['ignoreClass'] = 'annotator-hl';

	    if (this.metadata.layout == 'pre-paginated' && this.settings.manager == 'continuous') {
	      // this.settings.manager = 'prepaginated';
	      // this.settings.manager = PrePaginatedContinuousViewManager;
	      // this.settings.view = ReusableIframeView;
	      this.settings.manager = ScrollingContinuousViewManager;
	      this.settings.view = StickyIframeView;
	      this.settings.spread = 'none';
	    }

	    if (this.metadata.layout == 'pre-paginated' && this.settings.manager == ScrollingContinuousViewManager) {
	      if (this.options.minHeight) {
	        this.settings.minHeight = this.options.minHeight;
	      }
	    }

	    if (self.options.scale != '100') {
	      self.settings.scale = parseInt(self.options.scale, 10) / 100;
	    }

	    self._panes['book'].dataset.manager = this.settings.manager + (this.settings.spread ? '-' + this.settings.spread : '');
	    self._panes['book'].dataset.layout = this.metadata.layout || 'reflowable';

	    self._drawRendition(target, callback);
	  },

	  _drawRendition: function _drawRendition(target, callback) {
	    var self = this;

	    // self._rendition = self._book.renderTo(self._panes['epub'], self.settings);
	    self.rendition = new ePub.Rendition(self._book, self.settings);
	    self._book.rendition = self._rendition;
	    self._updateFontSize();
	    self._rendition.attachTo(self._panes['epub']);

	    self._bindEvents();
	    self._drawn = true;

	    if (target && target.start) {
	      target = target.start;
	    }
	    if (!target && window.location.hash) {
	      if (window.location.hash.substr(1, 3) == '/6/') {
	        var original_target = window.location.hash.substr(1);
	        target = decodeURIComponent(window.location.hash.substr(1));
	        target = "epubcfi(" + target + ")";
	      } else {
	        target = window.location.hash.substr(2);
	        target = self._book.url.path().resolve(decodeURIComponent(target));
	      }
	    }

	    var status_index = 0;
	    self._rendition.on('started', function () {
	      self._manager = self._rendition.manager;

	      self._rendition.manager.on("building", function (status) {
	        if (status) {
	          status_index += 1;
	          self._panes['loader-status'].innerHTML = '<span>' + Math.round(status_index / status.total * 100.0) + '%</span>';
	        } else {
	          self._enableBookLoader(-1);
	        }
	      });
	      self._rendition.manager.on("built", function () {
	        self._disableBookLoader(true);
	      });
	    });

	    self._rendition.hooks.content.register(function (contents) {
	      self.fire('ready:contents', contents);
	      self.fire('readyContents', contents);

	      // check for tables + columns
	      if (self._rendition.manager.layout.name == 'reflowable' && !(ie || edge)) {
	        popupTables(self, contents);
	      }
	    });

	    self.gotoPage(target, function () {
	      window._loaded = true;
	      self._initializeReaderStyles();

	      if (callback) {
	        callback();
	      }

	      self._epubjs_ready = true;

	      self.gotoPage(target, function () {
	        setTimeout(function () {
	          self.fire('opened');
	          self.fire('ready');
	          self._disableBookLoader();
	          clearTimeout(self._queueTimeout);
	          self.tracking.event("openBook", {
	            rootFilePath: self.options.rootFilePath,
	            flow: self.settings.flow,
	            manager: self.settings.manager
	          });
	        }, 100);
	      });
	    });
	  },

	  _scroll: function _scroll(delta) {
	    var self = this;
	    if (self.options.flow == 'XXscrolled-doc') {
	      var container = self._rendition.manager.container;
	      var rect = container.getBoundingClientRect();
	      var scrollTop = container.scrollTop;
	      var newScrollTop = scrollTop;
	      var scrollBy = rect.height * 0.98;
	      switch (delta) {
	        case 'PREV':
	          newScrollTop = -(scrollTop + scrollBy);
	          break;
	        case 'NEXT':
	          newScrollTop = scrollTop + scrollBy;
	          break;
	        case 'HOME':
	          newScrollTop = 0;
	          break;
	        case 'END':
	          newScrollTop = container.scrollHeight - scrollBy;
	          break;
	      }
	      container.scrollTop = newScrollTop;
	      return Math.floor(container.scrollTop) != Math.floor(scrollTop);
	    }
	    return false;
	  },

	  _navigate: function _navigate(promise, callback) {
	    var self = this;
	    self._enableBookLoader(100);
	    promise.then(function () {
	      self._disableBookLoader();
	      if (callback) {
	        callback();
	      }
	    }).catch(function (e) {
	      self._disableBookLoader();
	      if (callback) {
	        callback();
	      }
	      console.log("AHOY NAVIGATE ERROR", e);
	      throw e;
	    });
	  },

	  next: function next() {
	    var self = this;
	    this.tracking.action('reader/go/next');
	    self._scroll('NEXT') || self._navigate(this._rendition.next());
	  },

	  prev: function prev() {
	    this.tracking.action('reader/go/previous');
	    this._scroll('PREV') || this._navigate(this._rendition.prev());
	  },

	  first: function first() {
	    this.tracking.action('reader/go/first');
	    this._navigate(this._rendition.display(0), undefined);
	  },

	  last: function last() {
	    this.tracking.action('reader/go/last');
	    var target = this._book.spine.length - 1;
	    this._navigate(this._rendition.display(target), undefined);
	  },

	  gotoPage: function gotoPage(target, callback) {
	    var self = this;

	    var hash;
	    if (target != null) {
	      var section = this._book.spine.get(target);
	      if (!section) {
	        // maybe it needs to be resolved
	        var guessed = target;
	        if (guessed.indexOf("://") < 0) {
	          var path1 = path$1.resolve(this._book.path.directory, this._book.packaging.navPath);
	          var path2 = path$1.resolve(path$1.dirname(path1), target);
	          guessed = this._book.canonical(path2);
	        }
	        if (guessed.indexOf("#") !== 0) {
	          hash = guessed.split('#')[1];
	          guessed = guessed.split('#')[0];
	        }

	        this._book.spine.each(function (item) {
	          if (item.canonical == guessed) {
	            section = item;
	            target = section.href;
	            return;
	          }
	        });

	        if (hash) {
	          target = target + '#' + hash;
	        }

	        // console.log("AHOY GUESSED", target);
	      } else if (target.toString().match(/^\d+$/)) {
	        // console.log("AHOY USING", section.href);
	        target = section.href;
	      }

	      if (!section) {
	        if (!this._epubjs_ready) {
	          target = 0;
	        } else {
	          return;
	        }
	      }
	    }

	    self.tracking.reset();
	    var navigating = this._rendition.display(target).then(function () {
	      this._rendition.display(target);
	    }.bind(this));
	    this._navigate(navigating, callback);
	  },

	  percentageFromCfi: function percentageFromCfi(cfi) {
	    return this._book.percentageFromCfi(cfi);
	  },

	  destroy: function destroy() {
	    if (this._rendition) {
	      try {
	        this._rendition.destroy();
	      } catch (e) {}
	    }
	    this._rendition = null;
	    this._drawn = false;
	  },

	  reopen: function reopen(options, target) {
	    // different per reader?
	    var target = target || this.currentLocation();
	    if (target.start) {
	      target = target.start;
	    }
	    if (target.cfi) {
	      target = target.cfi;
	    }

	    var doUpdate = false;
	    if (options === true) {
	      doUpdate = true;options = {};
	    }
	    var changed = {};
	    Object.keys(options).forEach(function (key) {
	      if (options[key] != this.options[key]) {
	        doUpdate = true;
	        changed[key] = true;
	      }
	      // doUpdate = doUpdate || ( options[key] != this.options[key] );
	    }.bind(this));

	    if (!doUpdate) {
	      return;
	    }

	    // performance hack
	    if (Object.keys(changed).length == 1 && changed.scale) {
	      reader.options.scale = options.scale;
	      this._updateScale();
	      return;
	    }

	    if (options.rootfilePath && options.rootfilePath != this.options.rootfilePath) {
	      // we need to REOPEN THE DANG BOOK
	      sessionStorage.setItem('rootfilePath', options.rootfilePath);
	      location.reload();
	      return;
	    }

	    extend(this.options, options);

	    this.draw(target, function () {
	      // this._updateFontSize();
	      this._updateScale();
	      this._updateTheme();
	      this._selectTheme(true);
	    }.bind(this));
	  },

	  currentLocation: function currentLocation() {
	    if (this._rendition && this._rendition.manager) {
	      this._cached_location = this._rendition.currentLocation();
	    }
	    return this._cached_location;
	  },

	  _bindEvents: function _bindEvents() {
	    var self = this;
	    if (this._book.packaging.metadata.layout == 'pre-paginated') ; else if (this.options.flow == 'auto' || this.options.flow == 'paginated') ;

	    var custom_stylesheet_rules = [];

	    // force 90% height instead of default 60%
	    if (this.metadata.layout != 'pre-paginated') {
	      this._rendition.hooks.content.register(function (contents) {
	        contents.addStylesheetRules({
	          "img": {
	            "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
	            "max-height": (this._layout.height ? this._layout.height * 0.9 + "px" : "90%") + "!important",
	            "object-fit": "contain",
	            "page-break-inside": "avoid"
	          },
	          "svg": {
	            "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
	            "max-height": (this._layout.height ? this._layout.height * 0.9 + "px" : "90%") + "!important",
	            "page-break-inside": "avoid"
	          },
	          "body": {
	            "overflow": "hidden",
	            "column-rule": "1px solid #ddd"
	          }
	        });
	      }.bind(this._rendition));
	    } else {
	      this._rendition.hooks.content.register(function (contents) {
	        contents.addStylesheetRules({
	          "img": {
	            // "border": "64px solid black !important",
	            "box-sizing": "border-box !important"
	          },
	          "figure": {
	            "box-sizing": "border-box !important",
	            "margin": "0 !important"
	          },
	          "body": {
	            "margin": "0",
	            "overflow": "hidden"
	          }
	        });
	      }.bind(this._rendition));
	    }

	    this._updateFontSize();

	    if (custom_stylesheet_rules.length) {
	      this._rendition.hooks.content.register(function (view) {
	        view.addStylesheetRules(custom_stylesheet_rules);
	      });
	    }

	    this._rendition.on('resized', function (box) {
	      self.fire('resized', box);
	    });

	    this._rendition.on('click', function (event, contents) {
	      if (event.isTrusted) {
	        this.tracking.action("inline/go/link");
	      }
	    }.bind(this));

	    this._rendition.on('keydown', function (event, contents) {
	      var target = event.target;
	      var IGNORE_TARGETS = ['input', 'textarea'];
	      if (IGNORE_TARGETS.indexOf(target.localName) >= 0) {
	        return;
	      }
	      this.fire('keyDown', { keyName: event.key, shiftKey: event.shiftKey, inner: true });
	    }.bind(this));

	    var relocated_handler = debounce_1(function (location) {
	      if (self._fired) {
	        self._fired = false;return;
	      }
	      self.fire('relocated', location);
	      if (safari && self._last_location_start && self._last_location_start != location.start.href) {
	        self._fired = true;
	        setTimeout(function () {
	          // self._rendition.display(location.start.cfi);
	        }, 0);
	      }
	      self._last_location_start = location.start.href;
	    }, 10);

	    this._rendition.on('relocated', relocated_handler);

	    this._rendition.on('displayerror', function (err) {
	      console.log("AHOY RENDITION DISPLAY ERROR", err);
	    });

	    var locationChanged_handler = debounce_1(function (location) {
	      var view = this.manager.current();
	      var section = view.section;
	      var current = this.book.navigation.get(section.href);

	      self.fire("updateSection", current);
	      self.fire("updateLocation", location);
	    }, 150);

	    this._rendition.on("locationChanged", locationChanged_handler);

	    this._rendition.on("rendered", function (section, view) {

	      self.on('keyDown', function (data) {
	        if (data.keyName == 'Tab' && data.inner) {
	          var container = self._rendition.manager.container;
	          var mod;
	          var delta;
	          var x;var xyz;
	          setTimeout(function () {
	            var scrollLeft = container.scrollLeft;
	            mod = scrollLeft % parseInt(self._rendition.manager.layout.delta, 10);
	            if (mod > 0 && mod / self._rendition.manager.layout.delta < 0.99) {
	              // var x = Math.floor(event.target.scrollLeft / parseInt(self._rendition.manager.layout.delta, 10)) + 1;
	              // var delta = ( x * self._rendition.manager.layout.delta) - event.target.scrollLeft;
	              x = Math.floor(container.scrollLeft / parseInt(self._rendition.manager.layout.delta, 10));
	              if (data.shiftKey) {
	                x -= 0;
	              } else {
	                x += 1;
	              }
	              var y = container.scrollLeft;
	              delta = x * self._rendition.manager.layout.delta - y;
	              xyz = x * self._rendition.manager.layout.delta;
	              // if ( data.shiftKey ) { delta *= -1 ; }
	              {
	                self._rendition.manager.scrollBy(delta);
	              }
	            }
	            // console.log("AHOY DOING THE SCROLLING", data.shiftKey, scrollLeft, mod, x, xyz, delta);
	          }, 0);
	        }
	      });
	    });
	  },

	  _initializeReaderStyles: function _initializeReaderStyles() {
	    var self = this;
	    var themes = this.options.themes;
	    if (themes) {
	      themes.forEach(function (theme) {
	        self._rendition.themes.register(theme['klass'], theme.href ? theme.href : theme.rules);
	      });
	    }

	    // base for highlights
	    // this._rendition.themes.override('.epubjs-hl', "fill: yellow; fill-opacity: 0.3; mix-blend-mode: multiply;");
	  },

	  _selectTheme: function _selectTheme(refresh) {
	    var theme = this.options.theme || 'default';
	    this._rendition.themes.select(theme);
	  },

	  _updateFontSize: function _updateFontSize() {

	    var text_size = this.options.text_size || 100; // this.options.modes[this.flow].text_size; // this.options.text_size == 'auto' ? 100 : this.options.text_size;
	    this._rendition.themes.fontSize(text_size + '%');
	  },

	  _updateScale: function _updateScale() {
	    if (this.metadata.layout != 'pre-paginated') {
	      // we're not scaling for reflowable
	      return;
	    }
	    // var scale = this.options.modes[this.flow].scale;
	    var scale = this.options.scale;
	    if (scale) {
	      this.settings.scale = parseInt(scale, 10) / 100.0;
	      this._queueScale();
	    }
	  },

	  _queueScale: function _queueScale(scale) {
	    this._queueTimeout = setTimeout(function () {
	      if (this._rendition.manager && this._rendition.manager.stage) {
	        this._rendition.scale(this.settings.scale);
	        var text_size = this.settings.scale == 1.0 ? 100 : this.settings.scale * 100.0;
	        this._rendition.themes.fontSize(text_size + '%');
	      } else {
	        this._queueScale();
	      }
	    }.bind(this), 100);
	  },

	  EOT: true

	});

	Object.defineProperty(Reader.EpubJS.prototype, 'metadata', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    return this._metadata;
	  },

	  set: function set(data) {
	    this._metadata = extend({}, data, this.options.metadata);
	  }
	});

	Object.defineProperty(Reader.EpubJS.prototype, 'annotations', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    if (ie) {
	      return {
	        reset: function reset() {/* NOOP */},
	        highlight: function highlight(cfiRange) {/* NOOP */}
	      };
	    }
	    if (!this._rendition.annotations.reset) {
	      this._rendition.annotations.reset = function () {
	        for (var hash in this._annotations) {
	          var cfiRange = decodeURI(hash);
	          this.remove(cfiRange);
	        }
	        this._annotationsBySectionIndex = {};
	      }.bind(this._rendition.annotations);
	    }
	    return this._rendition.annotations;
	  }
	});

	Object.defineProperty(Reader.EpubJS.prototype, 'locations', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    return this._book.locations;
	  }
	});

	Object.defineProperty(Reader.EpubJS.prototype, 'rendition', {
	  get: function get$$1() {
	    if (!this._rendition) {
	      this._rendition = { draft: true };
	      this._rendition.hooks = {};
	      this._rendition.hooks.content = new Hook(this);
	    }
	    return this._rendition;
	  },

	  set: function set(rendition) {
	    if (this._rendition && this._rendition.draft) {
	      var hook = this._rendition.hooks.content;
	      hook.hooks.forEach(function (fn) {
	        rendition.hooks.content.register(fn);
	      });
	    }
	    this._rendition = rendition;
	  }
	});

	Object.defineProperty(Reader.EpubJS.prototype, 'CFI', {
	  get: function get$$1() {
	    return ePub.CFI;
	  }
	});

	window.Reader = Reader;

	function createReader$1(id, options) {
	  return new Reader.EpubJS(id, options);
	}

	Reader.Mock = Reader.extend({

	  initialize: function initialize(id, options) {
	    Reader.prototype.initialize.apply(this, arguments);
	  },

	  open: function open(target, callback) {
	    this._book = {
	      metadata: {
	        title: 'The Mock Life',
	        creator: 'Alex Mock',
	        publisher: 'University Press',
	        location: 'Ann Arbor, MI',
	        pubdate: '2017-05-23'
	      },
	      contents: {
	        toc: [{ id: 1, href: "/epubs/mock/ops/xhtml/TitlePage.xhtml", label: "Title", parent: null }, { id: 2, href: "/epubs/mock/ops/xhtml/Chapter01.xhtml", label: "Chapter 1", parent: null }, { id: 3, href: "/epubs/mock/ops/xhtml/Chapter02.xhtml", label: "Chapter 2", parent: null }, { id: 4, href: "/epubs/mock/ops/xhtml/Chapter03.xhtml", label: "Chapter 3", parent: null }, { id: 5, href: "/epubs/mock/ops/xhtml/Chapter04.xhtml", label: "Chapter 4", parent: null }, { id: 6, href: "/epubs/mock/ops/xhtml/Chapter05.xhtml", label: "Chapter 5", parent: null }, { id: 7, href: "/epubs/mock/ops/xhtml/Chapter06.xhtml", label: "Chapter 6", parent: null }, { id: 8, href: "/epubs/mock/ops/xhtml/Chapter07.xhtml", label: "Chapter 7", parent: null }, { id: 9, href: "/epubs/mock/ops/xhtml/Index.xhtml", label: "Index", parent: null }]
	      }
	    };

	    this._locations = ['epubcfi(/6/4[TitlePage.xhtml])', 'epubcfi(/6/4[Chapter01.xhtml])', 'epubcfi(/6/4[Chapter02.xhtml])', 'epubcfi(/6/4[Chapter03.xhtml])', 'epubcfi(/6/4[Chapter04.xhtml])', 'epubcfi(/6/4[Chapter05.xhtml])', 'epubcfi(/6/4[Chapter06.xhtml])', 'epubcfi(/6/4[Chapter07.xhtml])', 'epubcfi(/6/4[Chapter08.xhtml])', 'epubcfi(/6/4[Index.xhtml])'];

	    this.__currentIndex = 0;

	    this.metadata = this._book.metadata;
	    this.fire('updateContents', this._book.contents);
	    this.fire('updateTitle', this._metadata);
	    this.fire('updateLocations', this._locations);
	    this.draw(target, callback);
	  },

	  draw: function draw(target, callback) {
	    var self = this;
	    this.settings = { flow: this.options.flow };
	    this.settings.height = '100%';
	    this.settings.width = '99%';
	    // this.settings.width = '100%';
	    if (this.options.flow == 'auto') {
	      this._panes['book'].style.overflow = 'hidden';
	    } else {
	      this._panes['book'].style.overflow = 'auto';
	    }
	    if (typeof target == 'function' && cb === undefined) {
	      callback = target;
	      target = undefined;
	    }
	    callback();
	    self.fire('ready');
	  },

	  next: function next() {
	    // this._rendition.next();
	  },

	  prev: function prev() {
	    // this._rendition.prev();
	  },

	  first: function first() {
	    // this._rendition.display(0);
	  },

	  last: function last() {},

	  gotoPage: function gotoPage(target) {
	    if (typeof target == "string") {
	      this.__currentIndex = this._locations.indexOf(target);
	    } else {
	      this.__currentIndex = target;
	    }
	    this.fire("relocated", this.currentLocation());
	  },

	  destroy: function destroy() {
	    // if ( this._rendition ) {
	    //   this._rendition.destroy();
	    // }
	    // this._rendition = null;
	  },

	  currentLocation: function currentLocation() {
	    var cfi = this._locations[this.__currentIndex];
	    return {
	      start: { cfi: cfi, href: cfi },
	      end: { cfi: cfi, href: cfi }
	    };
	  },

	  _bindEvents: function _bindEvents() {
	  },

	  _updateTheme: function _updateTheme() {},

	  EOT: true

	});

	Object.defineProperty(Reader.Mock.prototype, 'metadata', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    return this._metadata;
	  },

	  set: function set(data) {
	    this._metadata = extend({}, data, this.options.metadata);
	  }
	});

	Object.defineProperty(Reader.Mock.prototype, 'locations', {
	  get: function get$$1() {
	    // return the combined metadata of configured + book metadata
	    var self = this;
	    return {
	      total: self._locations.length,
	      locationFromCfi: function locationFromCfi(cfi) {
	        return self._locations.indexOf(cfi);
	      },
	      percentageFromCfi: function percentageFromCfi(cfi) {
	        var index = self.locations.locationFromCfi(cfi);
	        return index / self.locations.total;
	      },
	      cfiFromPercentage: function cfiFromPercentage(percentage) {
	        var index = Math.ceil(percentage * 10);
	        return self._locations[index];
	      }
	    };
	  }
	});

	Object.defineProperty(Reader.Mock.prototype, 'annotations', {
	  get: function get$$1() {
	    return {
	      reset: function reset() {},
	      highlight: function highlight() {}
	    };
	  }
	});

	function createReader$2(id, options) {
	  return new Reader.Mock(id, options);
	}

	var engines = {
	  epubjs: createReader$1,
	  mock: createReader$2
	};

	var reader$1 = function reader(id, options) {
	  options = options || {};
	  var engine = options.engine || window.COZY_EPUB_ENGINE || 'epubjs';
	  var engine_href = options.engine_href || window.COZY_EPUB_ENGINE_HREF;
	  var _this = this;

	  options.engine = engine;
	  options.engine_href = engine_href;

	  return engines[engine].apply(_this, [id, options]);
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
	exports.inVp = inVp;
	exports.bus = bus;
	exports.DomEvent = DomEvent;
	exports.DomUtil = DomUtil;
	exports.Reader = Reader;
	exports.reader = reader$1;

	Object.defineProperty(exports, '__esModule', { value: true });

})));
//# sourceMappingURL=cozy-sun-bear.js.map
