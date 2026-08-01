import * as Util from '../core/Util';
import {Evented} from '../core/Events';
// import {Class} from '../core/Class';
import * as Browser from '../core/Browser';
import * as DomEvent from '../dom/DomEvent';
import * as DomUtil from '../dom/DomUtil';

import debounce from 'lodash/debounce';
import assign from 'lodash/assign';

import {screenfull} from '../screenfull';

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
export var Reader = Evented.extend({
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

  initialize: function(id, options) {
    var self = this

    self._original_document_title = document.title;

    if ( false && localStorage.getItem('cozy.options') ) {
      options = assign(options, JSON.parse(localStorage.getItem('cozy.options')));
      if ( options[this.flow] && options[this.flow].text_size ) {
        options.text_size = options[this.flow].text_size;
      }
      if ( options[this.flow] && options[this.flow].scale ) {      
        options.scale = options[this.flow].scale;
      }
    }

    this._cozyOptions = {};
    if ( localStorage.getItem('cozy.options') ) {
      this._cozyOptions = JSON.parse(localStorage.getItem('cozy.options'));
      if ( this._cozyOptions.theme ) {
        this.options.theme = this._cozyOptions.theme;
      }
      // if ( this._cozyOptions.flow ) {
      //   this.options.flow = this._cozyOptions.flow;
      // }
    }

    options = Util.setOptions(this, options);

    this._checkFeatureCompatibility();

    this.metadata = this.options.metadata; // initial seed

    this._initContainer(id);
    this._initLayout();

    if ( this.options.themes && this.options.themes.length > 0 ) {
        this.options.themes.forEach(function(theme) {
            if ( theme.href ) { return; }
            var klass = theme.klass;
            var rules = {};
            for(var rule in theme.rules) {
                var new_rule = '.' + klass;
                if ( rule == 'body' ) { new_rule = 'body' + new_rule; }
                else { new_rule += ' ' + rule ; }
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

  start: function(target, cb) {
    var self = this;

    if ( typeof(target) == 'function' && cb === undefined ) {
      cb = target;
      target = undefined;
    }

    self._start(target, cb);

    // Util.loader.js(this.options.engine_href).then(function() {
    //   self._start(target, cb);
    //   self._loaded = true;
    // })
  },

  _start: function(target, cb) {
    var self = this;
    target = target || 0;

    // self.open(function() {
    //   self.draw(target, cb);
    // });

    self.open(target, cb);
  },

  reopen: function(options, target) {
    /* NOP */
  },

  saveOptions: function(options) {
    var saved_options = {};
    if ( localStorage.getItem('cozy.options') ) {
      saved_options = JSON.parse(localStorage.getItem('cozy.options'));
    }

    assign(saved_options, options);
    var key = this.metadata.layout || 'reflowable';
    var flow = saved_options.flow;
    if ( saved_options.flow == 'auto' ) {
      // do not save
      delete saved_options.flow;
      flow = this.metadata.flow || 'paginated';
    }
    // key += '/' + flow;

    // var key = `${this.flow}/${this.metadata.layout}`;
    // var key = this.metadata.layout;
    if ( saved_options.text_size || saved_options.scale ) {
      saved_options[key] = {};
      if ( saved_options.text_size ) {
        saved_options[key].text_size = saved_options.text_size;
        delete saved_options.text_size;
      }
      if ( saved_options.scale ) {
        saved_options[key].scale = saved_options.scale;
        delete saved_options.scale;
      }
      if ( saved_options.flow ) {
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

  _updateTheme: function() {
    DomUtil.removeClass(this._container, 'cozy-theme-' + ( this._container.dataset.theme || 'default' ));
    DomUtil.addClass(this._container, 'cozy-theme-' + this.options.theme);
    this._container.dataset.theme = this.options.theme;
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

  display: function(target) {
    // backwards compatibility
    // NOOP
    return this.gotoPage(target);
  },

  gotoPage: function(target) {
    // NOOP
  },

  goBack: function() {
    history.back();
  },

  goForward: function() {
    history.forward();
  },

  requestFullscreen: function() {
    if ( screenfull.enabled ) {
      // this._preResize();
      screenfull.toggle(this._container);
    }
  },

  _preResize: function() {

  },

  _initContainer: function (id) {
    var container = this._container = DomUtil.get(id);

    if (!container) {
      throw new Error('Reader container not found.');
    } else if (container._cozy_id) {
      throw new Error('Reader container is already initialized.');
    }

    DomEvent.on(container, 'scroll', this._onScroll, this);
    this._containerId = Util.stamp(container);
  },

  _initLayout: function () {
    var container = this._container;

    this._fadeAnimated = this.options.fadeAnimation && Browser.any3d;

    DomUtil.addClass(container, 'cozy-reader cozy-container' +
      (Browser.touch ? ' cozy-touch' : '') +
      (Browser.retina ? ' cozy-retina' : '') +
      (Browser.ielt9 ? ' cozy-oldie' : '') +
      (Browser.safari ? ' cozy-safari' : '') +
      (this._fadeAnimated ? ' cozy-fade-anim' : '') +
      ' cozy-engine-' + this.options.engine +
      ' cozy-theme-' + this.options.theme);

    var position = DomUtil.getStyle(container, 'position');

    this._initPanes();

    if ( ! Browser.columnCount ) {
      this.options.flow = 'scrolled-doc';
    }
  },

  _initPanes: function () {
    var self = this;

    var panes = this._panes = {};

    var l = 'cozy-';
    var container = this._container;

    var prefix = 'cozy-module-';

    DomUtil.addClass(container, 'cozy-container');
    panes['live-status'] = DomUtil.create('div', prefix + 'live-status u-screenreader', container);
    panes['live-status'].setAttribute('aria-live', 'polite');
    panes['top'] = DomUtil.create('div', prefix + 'top', container);
    panes['main'] = DomUtil.create('div', prefix + 'main', container);
    panes['bottom'] = DomUtil.create('div', prefix + 'bottom', container);
    panes['left'] = DomUtil.create('div', prefix + 'left', panes['main']);
    panes['right'] = DomUtil.create('div', prefix + 'right', panes['main']);
    panes['book-cover'] = DomUtil.create('div', prefix + 'book-cover', panes['main']);
    panes['book'] = DomUtil.create('div', prefix + 'book', panes['book-cover']);
    panes['loader'] = DomUtil.create('div', prefix + 'book-loading', panes['book']);
    panes['epub'] = DomUtil.create('div', prefix + 'book-epub', panes['book']);
    this._initBookLoader();
  },

  _checkIfLoaded: function () {
    if (!this._loaded) {
      throw new Error('Set map center and zoom first.');
    }
  },

  // DOM event handling

  // @section Interaction events
  _initEvents: function (remove) {
    this._targets = {};
    this._targets[Util.stamp(this._container)] = this;

    this.tracking = function(reader) {
      var _action = [];
      var _last_location_start;
      var _last_scrollTop;
      var _reader = reader;
      return {
        action: function(v) {
          if ( v ) {
            _action = [v];
            this.event(v);
            // _reader.fire('trackAction', { action: v })
          } else {
            return _action.pop();
          }
        },

        peek: function() {
          return _action[0];
        },

        event: function(action, data) {
          if ( data == null ) { data = {}; }
          data.action = action;
          _reader.fire("trackAction", data);
        },

        pageview: function(location) {
          var do_report = true;
          if ( _reader.settings.flow == 'scrolled-doc' ) {
            var scrollTop = 0;
            if ( _reader._rendition.manager && _reader._rendition.manager.container ) {
              scrollTop = _reader._rendition.manager.container.scrollTop;
              // console.log("AHOY CHECKING SCROLLTOP", _last_scrollTop, scrollTop, Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height);
            }
            if ( _last_scrollTop && Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height ) {
              do_report = false;
            } else {
              _last_scrollTop = scrollTop;
            }
          }
          if ( location.start != _last_location_start && do_report ) {
            _last_location_start = location.start;
            var tracking = { cfi: location.start, href: location.href, action: this.action()};
            _reader.fire('trackPageview', tracking)
            return tracking;
          }
          return false;
        },

        reset: function() {
          if ( _reader.settings.flow == 'scrolled-doc' ) {
            _last_scrollTop = null;
          }
        }
      }
    }(this);

    var onOff = remove ? DomEvent.off : DomEvent.on;

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

    if (Browser.any3d && this.options.transform3DLimit) {
      (remove ? this.off : this.on).call(this, 'moveend', this._onMoveEnd);
    }

    var self = this;
    if (screenfull.enabled) {
      screenfull.on('change', function() {
        // setTimeout(function() {
        //   self.invalidateSize({});
        // }, 100);
        self.fire('fullscreenchange', { isFullscreen: screenfull.isFullscreen });
        console.log('AHOY: Am I fullscreen?', screenfull.isFullscreen ? 'YES' : 'NO');
      });
    }

    self.on("updateLocation", function(location) {
      // possibly invoke a pageview event
      var tracking;
      if ( tracking = self.tracking.pageview(location) ) {
        if ( location.percentage ) {
          var p = Math.ceil(location.percentage * 100);
          document.title = `${p}% - ${self._original_document_title}`;
        }
        var tmp_href = window.location.href.split("#");
        tmp_href[1] = location.start.substr(8, location.start.length - 8 - 1);
        var context = [{ cfi: location.start }, '', tmp_href.join('#')];

        if ( tracking.action && tracking.action.match(/\/go\/link/) ) {
          // console.log("AHOY ACTION", tracking.action, context[0].cfi);
          history.pushState.apply(history, context);
        } else {
          history.replaceState.apply(history, context);
        }
      }
    })

    window.addEventListener('popstate', function(event) {
      console.log("AHOY POP STATE", event)
      if ( event.isTrusted && event.state != null ) {
        if ( event.state.cfi == self.__last_state_cfi ) {
          console.log("AHOY POP STATE IGNORE", self.__last_state_cfi);
          event.preventDefault();
          return;
        }
        self.__last_state_cfi = event.state.cfi;
        if ( event.state == null || event.state.cfi == null ) {
          event.preventDefault();
          return;
        }
        self.display(event.state.cfi);
      }
    })

    document.addEventListener('keydown', function(event) {
      var keyName = event.key;
      var target = event.target;

      // check if the activeElement is ".special-panel"
      var check = document.activeElement;
      while ( check.localName != 'body' ) {
        if ( check.classList.contains('special-panel') ) {
          return;
        }
        check = check.parentElement;
      }

      var IGNORE_TARGETS = [ 'input', 'textarea' ];
      if ( IGNORE_TARGETS.indexOf(target.localName) >= 0 ) {
        return;
      }

      self.fire('keyDown', { keyName: keyName, shiftKey: event.shiftKey });
    });

    self.on('keyDown', function(data) {
      switch(data.keyName) {
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
          self._scroll('END')
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

  _onScroll: function () {
    this._container.scrollTop  = 0;
    this._container.scrollLeft = 0;
  },

  _handleDOMEvent: function (e) {
    if (!this._loaded || DomEvent.skipped(e)) { return; }

    var type = e.type === 'keypress' && e.keyCode === 13 ? 'click' : e.type;

    if (type === 'mousedown') {
      // prevents outline when clicking on keyboard-focusable element
      DomUtil.preventOutline(e.target || e.srcElement);
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
      var synth = Util.extend({}, e);
      synth.type = 'preclick';
      this._fireDOMEvent(synth, synth.type, targets);
    }

    if (e._stopped) { return; }

    // Find the layer the event is propagating from and its parents.
    targets = (targets || []).concat(this._findEventTargets(e, type));

    if (!targets.length) { return; }

    var target = targets[0];
    if (type === 'contextmenu' && target.listens(type, true)) {
      DomEvent.preventDefault(e);
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
        (targets[i].options.nonBubblingEvents && Util.indexOf(targets[i].options.nonBubblingEvents, type) !== -1)) { return; }
    }
  },

  getFixedBookPanelSize: function() {
    // have to make the book
    var style = window.getComputedStyle(this._panes['book']);
    var h = this._panes['book'].clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
    var w = this._panes['book'].clientWidth - parseFloat(style.paddingRight) - parseFloat(style.paddingLeft);
    return { height: Math.floor(h * 1.00), width: Math.floor(w * 1.00) };
  },

  invalidateSize: function(options) {
    // TODO: IS THIS EVER USED?
    var self = this;

    if ( ! self._drawn ) { return; }

    Util.cancelAnimFrame(this._resizeRequest);

    if (! this._loaded) { return this; }

    this.fire('resized');
  },

  _resizeBookPane: function() {

  },

  _setupHooks: function() {

  },

  _checkFeatureCompatibility: function() {
    if ( ! DomUtil.isPropertySupported('columnCount') || this._checkMobileDevice() ) {
      // force
      this.options.flow = 'scrolled-doc';
    }
    if ( this._checkMobileDevice() ) {
      this.options.text_size = 120;
    }
  },

  _checkMobileDevice: function() {
    if ( this._isMobile === undefined ) {
      this._isMobile = false;
      if ( this.options.mobileMediaQuery ) {
        this._isMobile = window.matchMedia(this.options.mobileMediaQuery).matches;
      }
    }
    return this._isMobile;
  },

  _enableBookLoader: function(delay=0) {
    var self = this;
    self._clearBookLoaderTimeout();
    if ( delay < 0 ) {
      delay = 0;
      self._force_progress = true;
    }
    self._loader_timeout = setTimeout(function() {
      self._panes['loader'].style.display = 'block';
    }, delay);
  },

  _disableBookLoader: function(force=false) {
    var self = this;
    self._clearBookLoaderTimeout();
    if ( ! self._force_progress || force ) {
      self._panes['loader'].style.display = 'none';
      self._force_progress = false;
      self._panes['loader-status'].innerHTML = '';
    }
  },

  _clearBookLoaderTimeout: function() {
    var self = this;
    if ( self._loader_timeout ) {
      clearTimeout(self._loader_timeout);
      self._loader_timeout = null;
    }
  },

  _initBookLoader: function() {
    // is this not awesome?
    var template = this.options.loader_template || this.loaderTemplate();

    var body = new DOMParser().parseFromString(template, "text/html").body;
    while ( body.children.length ) {
      this._panes['loader'].appendChild(body.children[0]);
    }
    this._panes['loader-status'] = DomUtil.create('div', 'cozy-module-book-loading-status', this._panes['loader']);
  },

  loaderTemplate: function() {
    return `<div class="cozy-loader-spinner">
    <div class="spinner-backdrop spinner-backdrop--1"></div>
    <div class="spinner-backdrop spinner-backdrop--2"></div>
    <div class="spinner-backdrop spinner-backdrop--3"></div>
    <div class="spinner-backdrop spinner-backdrop--4"></div>
    <div class="spinner-quarter spinner-quarter--1"></div>
    <div class="spinner-quarter spinner-quarter--2"></div>
    <div class="spinner-quarter spinner-quarter--3"></div>
    <div class="spinner-quarter spinner-quarter--4"></div>
  </div>`;
  },

  updateLiveStatus: function(message) {
    if ( ! this._panes['live-status'] ) { return ; }
    if ( message != this._last_message ) {
      if ( this._last_timer ) { clearTimeout(this._last_timer); this._last_timer = null; }
      var clearDelay = 500;
      setTimeout(() => {
        this._panes['live-status'].innerText = message;
        this._last_message = message;
        console.log("-- status:", message);
      }, 50);
      this._last_timer = setTimeout(() => {
        this._panes['live-status'].innerText = '';
      }, clearDelay);
    }
  },

  EOT: true
});

Object.defineProperty(Reader.prototype, 'metadata', {
  get: function() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },

  set: function(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});

Object.defineProperty(Reader.prototype, 'flow', {
  get: function() {
    // return the combined metadata of configured + book metadata
    return ( this.options.flow == 'auto' ? 'paginated' : this.options.flow );
  }
});

Object.defineProperty(Reader.prototype, 'flowOptions', {
  get: function() {
    // return the combined metadata of configured + book metadata

    var flow = this.flow;
    if ( ! this.options.flowOptions[flow] ) {
      this.options.flowOptions[flow] = {};
    }
    if ( ! this.options.flowOptions[flow].text_size ) {
      this.options.flowOptions[flow].text_size = this.options.text_size;
    }
    if ( ! this.options.flowOptions[flow].scale ) {
      this.options.flowOptions[flow].scale = this.options.scale;
    }

    return this.options.flowOptions[flow]
  }
});

export function createReader(id, options) {
  return new Reader(id, options);
}
