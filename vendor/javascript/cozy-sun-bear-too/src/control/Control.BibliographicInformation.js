import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

// Title + Chapter

export var BibliographicInformation = Control.extend({
  options: {
    label: 'Info',
    direction: 'left',
    html: '<span class="oi" data-glyph="info">Info</span>'
  },

  defaultTemplate: `<button class="button--sm" data-toggle="open" aria-label="Bibliographic Information"><i class="icon-info oi" data-glyph="info" title="Book Information" aria-hidden="true"></i></button>`,

  onAdd: function(reader) {
    var self = this;
    var container = this._container;
    if ( container ) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {

      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);

      var template = this.options.template || this.defaultTemplate;

      var body = new DOMParser().parseFromString(template, "text/html").body;
      while ( body.children.length ) {
        container.appendChild(body.children[0]);
      }
    }

    this._reader.on('updateContents', function(data) {
      self._createPanel();
    });


    this._control = container.closest("[data-toggle=open]") || container.querySelector('[data-toggle="open"]');
    this._control.setAttribute('id', 'action-' + this._id);
    container.style.position = 'relative';
    DomEvent.on(this._control, 'click', function(event) {
      event.preventDefault();
      self._modal.activate();
    }, this)

    return container;
  },

  _createPanel: function() {
    var self = this;

    var template = `<dl>
    </dl>`;

    this._modal = this._reader.modal({
      template: template,
      title: 'Info',
      region: 'left',
      fraction: 1.0,
      className: 'cozy-modal-contents',
    });

    var dl = this._modal._container.querySelector('dl');

    var metadata_fields = [
      [ 'title', 'Title' ],
      [ 'creator', 'Author' ],
      [ 'pubdate', 'Publication Date' ],
      [ 'modified_date', 'Modified Date' ],
      [ 'publisher', 'Publisher' ],
      [ 'rights', 'Rights' ],
      [ 'doi', 'DOI' ],
      [ 'description', 'Description' ],
    ];

    var metadata_fields_seen = {};

    var metadata = this._reader.metadata;

    for(var idx in metadata_fields) {
      var key = metadata_fields[idx][0];
      var label = metadata_fields[idx][1];
      if ( metadata[key] ) {
        var value = metadata[key];
        if ( key == 'pubdate' || key == 'modified_date' ) {
          value = this._formatDate(value);
          if ( ! value ) { continue; }
          // value = d.toISOString().slice(0,10); // for YYYY-MM-DD
        }
        metadata_fields_seen[key] = true;
        var dt = DomUtil.create('dt', 'cozy-bib-info-label', dl);
        dt.innerHTML = label;
        var dd = DomUtil.create('dd', 'cozy-bib-info-value cozy-bib-info-value-' + key, dl);
        dd.innerHTML = value;
      }
    }

  },

  _formatDate: function(value) {
    var match = value.match(/\d{4}/);
    if ( match ) {
      return match[0];
    }
    return null;
  },

  EOT: true
});

export var bibliographicInformation = function(options) {
  return new BibliographicInformation(options);
}
