import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

// Title + Chapter

export var Title = Control.extend({
  onAdd: function(reader) {
    var self = this;
    var className = this._className(),
        container = DomUtil.create('div', className),
        options = this.options;

    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

    var h1 = DomUtil.create('h1', 'cozy-h1', container);
    DomUtil.setOpacity(h1, 0);
    this._title = DomUtil.create('span', 'cozy-title', h1);
    this._divider = DomUtil.create('span', 'cozy-divider', h1);
    this._divider.textContent = " · ";
    this._section = DomUtil.create('span', 'cozy-section', h1);

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

    this._reader.on('updateTitle', function(data) {
      if ( data ) {
        self._title.textContent = data.title || data.bookTitle;
        DomUtil.setOpacity(self._section, 0);
        DomUtil.setOpacity(self._divider, 0);
        DomUtil.setOpacity(h1, 1);
      }
    })

    return container;
  },

  _createButton: function (html, title, className, container, fn) {
    var link = DomUtil.create('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;

    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    DomEvent.disableClickPropagation(link);
    DomEvent.on(link, 'click', DomEvent.stop);
    DomEvent.on(link, 'click', fn, this);
    // DomEvent.on(link, 'click', this._refocusOnMap, this);

    return link;
  },

  EOT: true
});

export var title = function(options) {
  return new Title(options);
}
