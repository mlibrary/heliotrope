import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

// Title + Chapter

export var PublicationMetadata = Control.extend({
  onAdd: function(reader) {
    var self = this;
    var className = this._className(),
        container = DomUtil.create('div', className),
        options = this.options;

    // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;

    this._publisher = DomUtil.create('div', 'cozy-publisher', container);
    this._rights = DomUtil.create('div', 'cozy-rights', container);

    this._reader.on('updateTitle', function(data) {
      if ( data ) {
        self._publisher.textContent = data.publisher;
        self._rights.textContent = data.rights;
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

export var publicationMetadata = function(options) {
  return new PublicationMetadata(options);
}
