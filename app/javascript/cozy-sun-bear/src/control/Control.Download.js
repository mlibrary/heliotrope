import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Download = Control.extend({
  options: {
    label: 'Download Book',
    html: '<span>Download Book</span>'
  },

  defaultTemplate: `<button class="button--sm cozy-download oi" data-toggle="open" data-glyph="data-transfer-download"> Download Book</button>`,


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


    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function(event) {
      event.preventDefault();
      self._modal.activate();
    }, this)

    return container;
  },

  _createPanel: function() {
    var self = this;

    var template = `<form>
      <fieldset>
        <legend>Choose File Format</legend>
      </fieldset>
    </form>`;

    this._modal = this._reader.modal({
      template: template,
      title: 'Download Book',
      className: 'cozy-modal-download',
      actions: [
        {
          label: 'Download',
          callback: function(event) {
            var selected = self._form.querySelector("input:checked");
            var href = selected.getAttribute('data-href');
            self._configureDownloadForm(href);
            self._form.submit();
          }
        }
      ],
      region: 'left',
      fraction: 1.0
    });

    this._form = this._modal._container.querySelector('form');    
    var fieldset = this._form.querySelector('fieldset');
    this._reader.options.download_links.forEach(function(link, index) {
      var label = DomUtil.create('label', null, fieldset);
      var input = DomUtil.create('input', null, label);
      input.setAttribute('name', 'format');
      input.setAttribute('value', link.format);
      input.setAttribute('data-href', link.href);
      input.setAttribute('type', 'radio');
      if ( index == 0 ) {
        input.setAttribute('checked', 'checked');
      }
      var text = link.format;
      if ( link.size ) {
        text += " (" + link.size + ")";
      }
      var text = document.createTextNode(" " + text);
      label.appendChild(text);
    });

  },

  _configureDownloadForm: function(href) {
    var self = this;
    self._form.setAttribute('method', 'GET');
    self._form.setAttribute('action', href);
    self._form.setAttribute('target', '_blank');
  },


  EOT: true
});

export var download = function(options) {
  return new Download(options);
}
