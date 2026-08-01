import * as Util from '../core/Util';
import {Reader} from './Reader';
import * as DomUtil from '../dom/DomUtil';

Reader.Mock = Reader.extend({

  initialize: function(id, options) {
    Reader.prototype.initialize.apply(this, arguments);
  },

  open: function(target, callback) {
    var self = this;
    this._book = {
      metadata: {
        title: 'The Mock Life',
        creator: 'Alex Mock',
        publisher: 'University Press',
        location: 'Ann Arbor, MI',
        pubdate: '2017-05-23'
      },
      contents: {
        toc: [
          {id: 1, href: "/epubs/mock/ops/xhtml/TitlePage.xhtml", label: "Title", parent: null},
          {id: 2, href: "/epubs/mock/ops/xhtml/Chapter01.xhtml", label: "Chapter 1", parent: null},
          {id: 3, href: "/epubs/mock/ops/xhtml/Chapter02.xhtml", label: "Chapter 2", parent: null},
          {id: 4, href: "/epubs/mock/ops/xhtml/Chapter03.xhtml", label: "Chapter 3", parent: null},
          {id: 5, href: "/epubs/mock/ops/xhtml/Chapter04.xhtml", label: "Chapter 4", parent: null},
          {id: 6, href: "/epubs/mock/ops/xhtml/Chapter05.xhtml", label: "Chapter 5", parent: null},
          {id: 7, href: "/epubs/mock/ops/xhtml/Chapter06.xhtml", label: "Chapter 6", parent: null},
          {id: 8, href: "/epubs/mock/ops/xhtml/Chapter07.xhtml", label: "Chapter 7", parent: null},
          {id: 9, href: "/epubs/mock/ops/xhtml/Index.xhtml", label: "Index", parent: null},
        ]
      }
    };

    this._locations = [
      'epubcfi(/6/4[TitlePage.xhtml])',
      'epubcfi(/6/4[Chapter01.xhtml])',
      'epubcfi(/6/4[Chapter02.xhtml])',
      'epubcfi(/6/4[Chapter03.xhtml])',
      'epubcfi(/6/4[Chapter04.xhtml])',
      'epubcfi(/6/4[Chapter05.xhtml])',
      'epubcfi(/6/4[Chapter06.xhtml])',
      'epubcfi(/6/4[Chapter07.xhtml])',
      'epubcfi(/6/4[Chapter08.xhtml])',
      'epubcfi(/6/4[Index.xhtml])',
    ];

    this.__currentIndex = 0;

    this.metadata = this._book.metadata;
    this.fire('updateContents', this._book.contents);
    this.fire('updateTitle', this._metadata);
    this.fire('updateLocations', this._locations);
    this.draw(target, callback);
  },

  draw: function(target, callback) {
    var self = this;
    this.settings = { flow: this.options.flow };
    this.settings.height = '100%';
    this.settings.width = '99%';
    // this.settings.width = '100%';
    if ( this.options.flow == 'auto' ) {
      this._panes['book'].style.overflow = 'hidden';
    } else {
      this._panes['book'].style.overflow = 'auto';
    }
    if ( typeof(target) == 'function' && cb === undefined ) {
      callback = target;
      target = undefined;
    }
    callback();
    self.fire('ready');
  },

  next: function() {
    // this._rendition.next();
  },

  prev: function() {
    // this._rendition.prev();
  },

  first: function() {
    // this._rendition.display(0);
  },

  last: function() {
  },

  gotoPage: function(target) {
    if ( typeof(target) == "string" ) {
      this.__currentIndex = this._locations.indexOf(target);
    } else {
      this.__currentIndex = target;
    }
    this.fire("relocated", this.currentLocation());
  },

  destroy: function() {
    // if ( this._rendition ) {
    //   this._rendition.destroy();
    // }
    // this._rendition = null;
  },

  currentLocation: function() {
    var cfi = this._locations[this.__currentIndex];
    return {
      start: { cfi: cfi, href: cfi },
      end: { cfi: cfi, href: cfi }
    }
  },

  _bindEvents: function() {
    var self = this;

  },

  _updateTheme: function() {

  },

  EOT: true

})

Object.defineProperty(Reader.Mock.prototype, 'metadata', {
  get: function() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },

  set: function(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});

Object.defineProperty(Reader.Mock.prototype, 'locations', {
  get: function() {
    // return the combined metadata of configured + book metadata
    var self = this;
    return {
      total: self._locations.length,
      locationFromCfi: function(cfi) {
        return self._locations.indexOf(cfi);
      },
      percentageFromCfi: function(cfi) {
        var index = self.locations.locationFromCfi(cfi);
        return ( index / self.locations.total );
      },
      cfiFromPercentage: function(percentage) {
        var index = Math.ceil(percentage * 10);
        return self._locations[index];
      }
    }
  }
});

Object.defineProperty(Reader.Mock.prototype, 'annotations', {
  get: function() {
    return {
      reset: function() {},
      highlight: function() {}
    }
  }
})

export function createReader(id, options) {
  return new Reader.Mock(id, options);
}
