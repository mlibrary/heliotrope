import * as Util from '../core/Util';
import {Reader} from './Reader';
import ePub from 'epubjs';
window.ePub = ePub;
import * as DomUtil from '../dom/DomUtil';
import * as Browser from '../core/Browser';

import path from "path-webpack";

import PrePaginatedContinuousViewManager from '../epubjs/managers/continuous/prepaginated';
import ReusableIframeView from '../epubjs/managers/views/iframe';

import ScrollingContinuousViewManager from '../epubjs/managers/continuous/scrolling';
import StickyIframeView from '../epubjs/managers/views/sticky';

import { handlePopups } from "../utils/manglers";
import * as focus from "../utils/focus";

import debounce from 'lodash/debounce';

import Hook from "epubjs/src/utils/hook";

Reader.EpubJS = Reader.extend({

  initialize: function(id, options) {
    Reader.prototype.initialize.apply(this, arguments);
    this._epubjs_ready = false;
    window.xpath = path;
  },

  open: function(target, callback) {
    var self = this;
    if ( typeof(target) == 'function' ) {
      callback = target;
      target = undefined;
    }
    if ( callback == null ) {
      callback = function() { };
    }

    self.rootfiles = [];

    this.options.rootfilePath = this.options.rootfilePath || sessionStorage.getItem('rootfilePath');

    var book_href = this.options.href;
    var book_options = { packagePath: this.options.rootfilePath };
    if ( this.options.useArchive ) {
      book_href = book_href.replace(/\/(\w+)\/$/, '/$1/$1.sm.epub');
      book_options.openAs = 'epub';
    }
    this._book = ePub(book_href, book_options);
    sessionStorage.removeItem('rootfilePath');

    this._book.loaded.navigation.then(function(toc) {
      self._contents = toc;
      self.metadata = self._book.packaging.metadata;

      self.fire('updateContents', toc);
      self.fire('updateTitle', self._book.packaging.metadata);
    })
    this._book.ready.then(function() {
      self.parseRootfiles();

      self.draw(target, callback);

      if ( self.metadata.layout == 'pre-paginated' ) {
        // fake it with the spine
        var locations = [];
        self._book.spine.each(function(item) {
          locations.push(`epubcfi(${item.cfiBase}!/4/2)`);
          self.locations._locations.push(`epubcfi(${item.cfiBase}!/4/2)`);
        });
        self.locations.total = locations.length;
        var t;
        var f = function() {
          if ( self._rendition && self._rendition.manager && self._rendition.manager.stage ) {
            var location = self._rendition.currentLocation();
            if ( location && location.start) {
              self.fire('updateLocations', locations);
              clearTimeout(t);
              return;
            }
          }
          t = setTimeout(f, 100);
        }

        t = setTimeout(f, 100);
      } else if ( self._book.pageList && self._book.pageList.pageList.length && ! self._book.pageList.locations.length ) {
        self._book.locations.generateFromPageList(self._book.pageList).then(function(locations) {
          self.fire('updateLocations', locations);
        })
      } else {
        self._book.locations.generate(1600).then(function(locations) {
          self.fire('updateLocations', locations);
        })
      }
    })
    // .then(callback);
  },

  parseRootfiles: function() {
    var self = this;
    self._book.load(self._book.url.resolve("META-INF/container.xml")).then(function(containerDoc) {
        var rootfiles = containerDoc.querySelectorAll("rootfile");
        if ( rootfiles.length > 1 ) {
          for(var i = 0; i < rootfiles.length; i++) {
            var rootfile = rootfiles[i];
            var rootfilePath = rootfile.getAttribute('full-path');
            var label = rootfile.getAttribute('rendition:label');
            var layout = rootfile.getAttribute('rendition:layout');
            self.rootfiles.push({
              rootfilePath: rootfilePath,
              label: label,
              layout: layout
            })
          }
        }
    })
  },

  draw: function(target, callback) {
    var self = this;

    if ( self._rendition && ! self._rendition.draft ) {
      // self._unbindEvents();
      var container = self._rendition.manager.container;
      Object.keys(self._rendition.hooks).forEach(function(key) {
        self._rendition.hooks[key].clear();
      })
      self._rendition.destroy();
      self._rendition = null;
    }


    var key = self.metadata.layout || 'reflowable';
    var flow = this.options.flow;
    if ( self._cozyOptions[key] && self._cozyOptions[key].flow ) {
      flow = self._cozyOptions[key].flow;
      this.options.flow = flow; // restore from stored preferences
    }

    if ( flow == 'auto' ) {
      if ( this.metadata.layout == 'pre-paginated' ) {
          if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ){
            flow = 'scrolled-doc';
          }
      } else {
        // flow = 'paginated';
        flow = this.metadata.flow || 'auto';
      }
    }

    // if ( flow == 'auto' && this.metadata.layout == 'pre-paginated' ) {
    //   if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ){
    //     flow = 'scrolled-doc';
    //   }
    // }

    // var key = `${flow}/${self.metadata.layout}`;
    if ( self._cozyOptions[key] ) {
      if ( self._cozyOptions[key].text_size ) {
        self.options.text_size = self._cozyOptions[key].text_size;
      }
      if ( self._cozyOptions[key].scale ) {
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

    if ( this.settings.flow == 'auto' || this.settings.flow == 'paginated' ) {
      this._panes['epub'].style.overflow = this.metadata.layout == 'pre-paginated' ? 'auto' : 'hidden';
      this.settings.manager = 'default';
    } else {
      this._panes['epub'].style.overflow = 'auto';
      if ( this.settings.manager == 'default' ) {
        // this.settings.manager = 'continuous';
        this.settings.manager = ScrollingContinuousViewManager;
        this.settings.view = StickyIframeView;
        this.settings.width = '100%'; // 100%?
        this.settings.spine = this._book.spine;
      }
    }

    if ( ! callback ) {
      callback = function() { };
    }

    self.settings.height = '100%';
    self.settings.width = '100%';
    self.settings['ignoreClass'] = 'annotator-hl';

    if ( this.metadata.layout == 'pre-paginated' && this.settings.manager == 'continuous' ) {
        // this.settings.manager = 'prepaginated';
        // this.settings.manager = PrePaginatedContinuousViewManager;
        // this.settings.view = ReusableIframeView;
        this.settings.manager = ScrollingContinuousViewManager;
        this.settings.view = StickyIframeView;
        this.settings.spread = 'none';
    }

    if ( this.settings.manager == ScrollingContinuousViewManager ) {
      if ( this.metadata.layout != 'pre-paginated' && ! this.options.minHeight ) {
        this.options.minHeight = this._panes['book'].offsetHeight * 0.75;
      }
      if ( this.options.minHeight ) {
        this.settings.minHeight = this.options.minHeight;
      }
    }

    if ( self.options.scale != '100' ) {
      self.settings.scale = parseInt(self.options.scale, 10) / 100;
    }

    self._panes['book'].dataset.manager = this.settings.manager + ( this.settings.spread ? `-${this.settings.spread}` : '');
    self._panes['book'].dataset.layout = this.metadata.layout || 'reflowable';

    self._drawRendition(target, callback);
  },

  _drawRendition: function(target, callback) {
    var self = this;

    // self._rendition = self._book.renderTo(self._panes['epub'], self.settings);
    self.rendition = new ePub.Rendition(self._book, self.settings);
    self._book.rendition = self._rendition;

    this._rendition.settings.prehooks = {};
    this._rendition.settings.prehooks.head = new Hook(this);

    self._updateFontSize();
    self._rendition.attachTo(self._panes['epub']);

    self._bindEvents();
    self._drawn = true;

    if ( target && target.start ) { target = target.start; }
    if ( ! target && window.location.hash ) {
      if ( window.location.hash.substr(1, 3) == '/6/' ) {
        var original_target = window.location.hash.substr(1);
        target = decodeURIComponent(window.location.hash.substr(1));
        target = "epubcfi(" + target + ")";
      } else {
        target = window.location.hash.substr(2);
        target = self._book.url.path().resolve(decodeURIComponent(target));
      }
    }

    var status_index = 0;
    self._rendition.on('started', function() {
      self._manager = self._rendition.manager;

      self._rendition.manager.on("building", function(status) {
        if ( status ) {
          status_index += 1;
          self._panes['loader-status'].innerHTML = `<span>${Math.round((status_index / status.total) * 100.0)}%</span>`;
        } else {
          self._enableBookLoader(-1);
        }
      })
      self._rendition.manager.on("built", function() {
        self._disableBookLoader(true);
      })

      self.fire('renditionStarted', self._rendition);
    })

    self._rendition.hooks.content.register(function(contents) {
      self.fire('ready:contents', contents);
      self.fire('readyContents', contents);

      // check for tables + columns + popups
      if ( self._rendition.manager.layout.name == 'reflowable' ) {
        handlePopups(self, contents);
      }

    })

    self.display(target, function() {
      window._loaded = true;
      self._initializeReaderStyles();

      if ( callback ) { callback(); }

      self._epubjs_ready = true;

      self.display(target, function() {
        setTimeout(function() {
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
      })

    })
  },

  _scroll: function(delta) {
    var self = this;
    if ( self.options.flow == 'XXscrolled-doc' ) {
      var container = self._rendition.manager.container;
      var rect = container.getBoundingClientRect();
      var scrollTop = container.scrollTop;
      var newScrollTop = scrollTop;
      var scrollBy = ( rect.height * 0.98 );
      switch(delta) {
        case 'PREV':
          newScrollTop = -( scrollTop + scrollBy );
          break;
        case 'NEXT':
          newScrollTop = ( scrollTop + scrollBy );
          break;
        case 'HOME':
          newScrollTop = 0;
          break;
        case 'END':
          newScrollTop = container.scrollHeight - scrollBy;
          break;
      }
      container.scrollTop = newScrollTop;
      return ( Math.floor(container.scrollTop) != Math.floor(scrollTop) );
    }
    return false;
  },

  _navigate: function(promise, callback) {
    var self = this;
    self._enableBookLoader(100);
    promise.then(function() {
      self._disableBookLoader();
      if ( callback ) { callback(); }
    }).catch(function(e) {
      self._disableBookLoader();
      if ( callback ) { callback(); }
      console.log("AHOY NAVIGATE ERROR", e);
      throw(e);
    })
  },

  next: function() {
    var self = this;
    this.tracking.action('reader/go/next');
    self._scroll('NEXT') || self._navigate(this._rendition.next());
  },

  prev: function() {
    this.tracking.action('reader/go/previous');
    this._scroll('PREV') || this._navigate(this._rendition.prev());
  },

  first: function() {
    this.tracking.action('reader/go/first');
    this._navigate(this._rendition.display(0), undefined);
  },

  last: function() {
    var self = this;
    this.tracking.action('reader/go/last');
    var target = this._book.spine.length - 1;
    this._navigate(this._rendition.display(target), undefined);
  },

  display: function(target, callback) {
    var self = this;

    var hash;
    if ( target != null ) {
      var section = this._book.spine.get(target);
      if ( ! section) {
        // maybe it needs to be resolved
        var guessed = target;
        if ( guessed.indexOf("://") < 0 ) {
          var path1 = path.resolve(this._book.path.directory, this._book.packaging.navPath);
          var path2 = path.resolve(path.dirname(path1), target);
          guessed = this._book.canonical(path2);
        }
        if ( guessed.indexOf("#") !== 0 ) {
          hash = guessed.split('#')[1];
          guessed = guessed.split('#')[0];
        }

        this._book.spine.each(function(item) {
          if ( item.canonical == guessed ) {
            section = item;
            target = section.href;
            return;
          }
        })

        if ( hash ) {
          target = target + '#' + hash;
        }

        // console.log("AHOY GUESSED", target);
      } else if ( target.toString().match(/^\d+$/) ) {
        // console.log("AHOY USING", section.href);
        target = section.href;
      }

      if ( ! section ) {
        if ( ! this._epubjs_ready ) {
          target = 0;
        } else {
          return;
        }
      }
    }

    self.tracking.reset();
    var navigating = this._rendition.display(target).then(function() {
      this._rendition.display(target);
    }.bind(this));
    this._navigate(navigating, callback);
  },

  gotoPage(target, callback) {
    return this.display(target, callback)
  },

  percentageFromCfi: function(cfi) {
    return this._book.percentageFromCfi(cfi);
  },

  destroy: function() {
    if ( this._rendition ) {
      try {
        this._rendition.destroy();
      } catch(e) {}
    }
    this._rendition = null;
    this._drawn = false;
  },

  reopen: function(options, target) {
    // different per reader?
    var target = target || this.currentLocation();
    if( target.start ) { target = target.start ; }
    if ( target.cfi ) { target = target.cfi ; }

    var doUpdate = false;
    if ( options === true ) { doUpdate = true; options = {}; }
    var changed = {};
    Object.keys(options).forEach(function(key) {
      if ( options[key] != this.options[key] ) {
        doUpdate = true;
        changed[key] = true;
      }
      // doUpdate = doUpdate || ( options[key] != this.options[key] );
    }.bind(this));

    if ( ! doUpdate ) {
      return;
    }

    // performance hack
    if ( Object.keys(changed).length == 1 && changed.scale ) {
      this.options.scale = options.scale;
      this._updateScale();
      return;
    }

    if ( options.rootfilePath && options.rootfilePath != this.options.rootfilePath ) {
      // we need to REOPEN THE DANG BOOK
      sessionStorage.setItem('rootfilePath', options.rootfilePath);
      location.reload();
      return;
    }

    Util.extend(this.options, options);

    this.draw(target, function() {
      // this._updateFontSize();
      this._updateScale();
      this._updateTheme();
      this._selectTheme(true);
    }.bind(this))
  },

  currentLocation: function() {
    if ( this._rendition && this._rendition.manager ) {
      this._cached_location = this._rendition.currentLocation();
    }
    return this._cached_location;
  },

  _bindEvents: function() {
    var self = this;

    // add a stylesheet to stop images from breaking their columns
    var add_max_img_styles = false;
    if ( this._book.packaging.metadata.layout == 'pre-paginated' ) {
      // NOOP
    } else if ( this.options.flow == 'auto' || this.options.flow == 'paginated' ) {
      add_max_img_styles = true;
    }

    var custom_stylesheet_rules = [];

    // force 90% height instead of default 60%
    if ( this.metadata.layout != 'pre-paginated' ) {
      if ( this.options.flow == 'scrolled-doc' ) {
        // these prehooks are a hack to avoid the contents hooks applying _after_
        // the view has been displayed
        this._rendition.settings.prehooks.head.register(function(buffer) {
          var layout = this.layout;
          var retval = `
<style>
img {
  max-width: ${layout.columnWidth ? layout.columnWidth + "px" : "100%"} !important;
  max-height: ${(layout.height ? (layout.height * 0.9) + "px" : "90%")} !important;
  object-fit: contain;
  page-break-inside: avoid;
}
svg {
  max-width: ${layout.columnWidth ? layout.columnWidth + "px" : "100%"} !important;
  max-height: ${(layout.height ? (layout.height * 0.9) + "px" : "90%")} !important;
  page-break-inside: avoid;
}
body {
  overflow: hidden;
  column-rule: 1px solid #ddd;
}
</style>
          ` 
          buffer.push(retval);
        }.bind(this._rendition));
      }
      // --- KEEP THIS IN CASE WE HAVE TO REVERT THE PREHOOKS
      // this._rendition.hooks.content.register(function(contents) {
      //   contents.addStylesheetRules({
      //     "img" : {
      //       "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
      //       "max-height": (this._layout.height ? (this._layout.height * 0.9) + "px" : "90%") + "!important",
      //       "object-fit": "contain",
      //       "page-break-inside": "avoid"
      //     },
      //     "svg" : {
      //       "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
      //       "max-height": (this._layout.height ? (this._layout.height * 0.9) + "px" : "90%") + "!important",
      //       "page-break-inside": "avoid"
      //     },
      //     "body": {
      //       "overflow": "hidden",
      //       "column-rule": "1px solid #ddd"
      //     }
      //   });
      // }.bind(this._rendition))
    } else {
      this._rendition.hooks.content.register(function(contents) {
        contents.addStylesheetRules({
          "img" : {
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

    if ( custom_stylesheet_rules.length ) {
      this._rendition.hooks.content.register(function(view) {
        view.addStylesheetRules(custom_stylesheet_rules);
      })
    }

    this._rendition.on('resized', function(box) {
      self.fire('resized', box);
    })

    this._rendition.on('click', function(event, contents) {
      if ( event.isTrusted ) {
        this.tracking.action("inline/go/link");
      }
    }.bind(this));

    this._rendition.on('keydown', function(event, contents) {
      var target = event.target;
      var IGNORE_TARGETS = [ 'input', 'textarea' ];
      if ( IGNORE_TARGETS.indexOf(target.localName) >= 0 ) {
        return;
      }
      this.fire('keyDown', { keyName: event.key, shiftKey: event.shiftKey, inner: true });
    }.bind(this));

    var relocated_handler = debounce(function(location) {
      if ( self._fired ) { self._fired = false; return ; }
      self.fire('relocated', location);

      // hideEverything/showEverything
      focus.updateFocus(self, location);

      if ( Browser.safari && self._last_location_start && self._last_location_start != location.start.href ) {
        self._fired = true;
        setTimeout(function() {
          // self._rendition.display(location.start.cfi);
        }, 0);
      }
    }, 10);

    this._rendition.on('relocated', relocated_handler);

    this._rendition.on('displayerror', function(err) {
      console.log("AHOY RENDITION DISPLAY ERROR", err);
      self.fire('displayerror', err);
    })

    var locationChanged_handler = debounce(function(location) {
      var view = this.manager.current();
      if ( ! view ) { return ; }
      var section = view.section;
      var current = this.book.navigation.get(section.href);

      self.fire("updateSection", current);
      self.fire("updateLocation", location);
    }, 150);

    this._rendition.on("locationChanged", locationChanged_handler);

    this.on('updateLocations', function() {
      // trigger this when all the locations have been loaded from the spine
      this._rendition.emit('relocated', this._rendition.currentLocation());
    })

    this._rendition.on("rendered", function(section, view) {
      self._updateFrameTitle(section, view);
    });

    this._rendition.on("rendered", function(section, view) {

      if ( self.settings.flow == 'scrolled-doc' ) { return ; }
      if ( Browser.ie ) { self.options.disableFocusHandling = true; return ; }

      // add focus rules
      focus.setupFocusRules(self);

    })
  },

  _initializeReaderStyles: function() {
    var self = this;
    var themes = this.options.themes;
    if ( themes ) {
      themes.forEach(function(theme) {
        self._rendition.themes.register(theme['klass'], theme.href ? theme.href : theme.rules);
      })
    }

    // base for highlights
    // this._rendition.themes.override('.epubjs-hl', "fill: yellow; fill-opacity: 0.3; mix-blend-mode: multiply;");
  },

  _selectTheme: function(refresh) {
    var theme = this.options.theme || 'default';
    this._rendition.themes.select(theme);
  },

  _updateFontSize: function() {
    if ( false && this.metadata.layout == 'pre-paginated') {
      // we're not doing font changes for pre-paginated
      return;
    }

    var text_size = this.options.text_size || 100; // this.options.modes[this.flow].text_size; // this.options.text_size == 'auto' ? 100 : this.options.text_size;
    if ( text_size == 100 ) { 
      // do not add an unncessary override
      if ( ! this._rendition.themes._overrides['font-size'] ) {
        return; 
      }
    }
    this._rendition.themes.fontSize(`${text_size}%`);

    // --- prehook avoids jitter but cannot be readily replaced
    // --- TODO: if this is the first font-size setting could use prehook
    // --- else: use `themes.fontSize`
    // this._rendition.settings.prehooks.head.register(function(buffer) {
    //   buffer.push(`<style>body { font-size: ${text_size}%; }</style>`);
    // })
  },

  _updateScale: function() {
    if ( this.metadata.layout != 'pre-paginated') {
      // we're not scaling for reflowable
      return;
    }
    // var scale = this.options.modes[this.flow].scale;
    var scale = this.options.scale;
    if ( scale ) {
      this.settings.scale = parseInt(scale, 10) / 100.0;
      this._queueScale();
    }
  },

  _queueScale: function(scale) {
    this._queueTimeout = setTimeout(function() {
      if ( this._rendition.manager && this._rendition.manager.stage ) {
        this._rendition.scale(this.settings.scale);
        var text_size = this.settings.scale == 1.0 ? 100 : this.settings.scale * 100.0;
        this._rendition.themes.fontSize(`${text_size}%`);
      } else {
        this._queueScale();
      }
    }.bind(this), 100);
  },

  _updateFrameTitle: function(section, view) {
    var self = this;

    var title = `Section ${section.index + 1}`;
    var current = self._book.navigation && self._book.navigation.get(section.href);
    if ( ! current ) {
      var subtitle;
      for(var tag of [ 'h1', 'h2' ]) {
        var tmp = view.document.querySelectorAll(tag);
        if ( tmp ) {
          var buffer = [];
          for(var i = 0; i < tmp.length; i++) {
            buffer.push(tmp[i].innerText);
            if ( tag == 'h2' ) { break; } // only one of these
          }
          subtitle = buffer.join(' - ');
          break;
        }
      }
      if ( ! subtitle ) {
        for(var i = section.index; i >= 0; i--) {
          var previousSection = self._book.spine.get(i);
          var previous = self._book.navigation.get(previousSection.href);
          if ( previous ) {
            subtitle = previous.label;
            break;
          }
        }
      }
      if ( subtitle ) {
        title += ': ' + subtitle;
      }
    } else {
      title += ': ' + current.label;
    }
    if ( title && view.iframe ) {
      view.iframe.title = `Contents: ${title}` ;
    }
  },

  EOT: true

})

Object.defineProperty(Reader.EpubJS.prototype, 'metadata', {
  get: function() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },

  set: function(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});

Object.defineProperty(Reader.EpubJS.prototype, 'annotations', {
  get: function() {
    // return the combined metadata of configured + book metadata
    if ( Browser.ie ) {
      return {
        reset: function() { /* NOOP */ },
        highlight: function(cfiRange) { /* NOOP */ }
      }
    }
    if ( ! this._rendition.annotations.reset ) {
      this._rendition.annotations.reset = function(){
        for(var hash in this._annotations) {
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
  get: function() {
    // return the combined metadata of configured + book metadata
    return this._book.locations;
  }
});

Object.defineProperty(Reader.EpubJS.prototype, 'pageList', {
  get: function() {
    // return the combined metadata of configured + book metadata
    return this._book.pageList.pageList.length > 0 ? this._book.pageList : undefined;
  }
});

Object.defineProperty(Reader.EpubJS.prototype, 'rendition', {
  get: function() {
    if ( ! this._rendition ) {
      this._rendition = { draft: true };
      this._rendition.hooks = {};
      this._rendition.hooks.content = new Hook(this);
    }
    return this._rendition;
  },

  set: function(rendition) {
    if ( this._rendition && this._rendition.draft ) {
      var hook = this._rendition.hooks.content;
      hook.hooks.forEach(function(fn) {
        rendition.hooks.content.register(fn)
      })
    }
    this._rendition = rendition;
  }
})


Object.defineProperty(Reader.EpubJS.prototype, 'CFI', {
  get: function() {
    return ePub.CFI;
  }
})

window.Reader = Reader;

export function createReader(id, options) {
  return new Reader.EpubJS(id, options);
}
