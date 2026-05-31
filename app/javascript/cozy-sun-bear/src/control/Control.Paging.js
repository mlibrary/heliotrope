import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

var PageControl = Control.extend({
  onAdd: function(reader) {
    var container = this._container;
    if ( container ) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {

      var className = this._className(),
          options = this.options;
      container = DomUtil.create('div', className),

      this._control  = this._createButton(this._fill(options.html || options.label), this._fill(options.label),
              className, container);
    }
    this._bindEvents();

    return container;
  },

  _createButton: function (html, title, className, container) {
    var link = DomUtil.create('a', className, container);
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
    var self = this;
    DomEvent.disableClickPropagation(this._control);
    DomEvent.on(this._control, 'click', DomEvent.stop);
    DomEvent.on(this._control, 'click', this._action, this);

    this._reader.on('reopen', function(data) {
      // update the button text / titles
      var html = self.options.html || self.options.label;
      self._control.innerHTML = self._fill(html);
      self._control.setAttribute('title', self._fill(self.options.label));
      self._control.setAttribute('aria-label', self._fill(self.options.label));
    });

  },

  _unit: function() {
    return ( this._reader.options.flow == 'scrolled-doc' ) ? 'Section' : 'Page';
  },

  _fill: function(s) {
    var unit = this._unit();
    return s.replace(/\$\{unit\}/g, unit);
  },

  _label: function() {
    return this.options.label + " " + ( this._reader.options.flow == 'scrolled-doc' ) ? 'Section' : 'Page';
  },

  EOT: true
});

export var PagePrevious = PageControl.extend({
  options: {
    region: 'edge.left',
    direction: 'previous',
    label: 'Previous ${unit}',
    html: '<i class="icon-chevron-left oi" data-glyph="chevron-left" title="Previous ${unit}" aria-hidden="true"></i>'
  },

  _action: function(e) {
    this._reader.prev();
  }
});

export var PageNext = PageControl.extend({
  options: {
    region: 'edge.right',
    direction: 'next',
    label: 'Next ${unit}',
    html: '<i class="icon-chevron-right oi" data-glyph="chevron-right" title="Next ${unit}" aria-hidden="true"></i>'
  },

  _action: function(e) {
    this._reader.next();
  }
});

export var PageFirst = PageControl.extend({
  options: {
    direction: 'first',
    label: 'First ${unit}'
  },
  _action: function(e) {
      this._reader.first();
  }
});

export var PageLast = PageControl.extend({
  options: {
    direction: 'last',
    label: 'Last ${unit}'
  },
  _action: function(e) {
      this._reader.last();
  }
});

export var pageNext = function(options) {
  return new PageNext(options);
}

export var pagePrevious = function(options) {
  return new PagePrevious(options);
}

export var pageFirst = function(options) {
  return new PageFirst(options);
}

export var pageLast = function(options) {
  return new PageLast(options);
}
