import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Citation = Control.extend({
  options: {
    label: 'Citation',
    html: '<span class="citation" aria-label="Get Citation"></span>'
  },

  defaultTemplate: '<button class="button--sm cozy-citation citation" data-toggle="open" aria-label="Get Citation"></button>',


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

  _action: function() {
    var self = this;
    self._modal.activate();
  },

  _createButton: function (html, title, className, container, fn) {
    var link = DomUtil.create('button', className, container);
    link.innerHTML = html;
    link.title = title;

    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    DomEvent.disableClickPropagation(link);
    DomEvent.on(link, 'click', DomEvent.stop);
    DomEvent.on(link, 'click', fn, this);

    return link;
  },

  _createPanel: function() {
    var self = this;

    var template = `<form>
      <fieldset>
        <legend>Select Citation Format</legend>
      </fieldset>
    </form>
    <blockquote id="formatted" style="padding: 8px; border-left: 4px solid black; background-color: #fff"></blockquote>
    <div class="alert alert-info" id="message" style="display: none"></div>`;

    this._modal = this._reader.modal({
      template: template,
      title: 'Copy Citation to Clipboard',
      className: 'cozy-modal-citation',
      actions: [
        {
          label: 'Copy Citation',
          close: true,
          callback: function(event) {
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
            } catch(err) {
              console.log("AHOY COPY FAILED", err);
            }

            self._message.innerHTML = 'Success! Citation copied to your clipboard.';
            self._message.style.display = 'block';
            sel.removeAllRanges();
            range.detach();
            document.designMode = "off";
          }
        }
      ],
      region: 'left',
      fraction: 1.0
    });

    this._form = this._modal._container.querySelector('form');
    var fieldset = this._form.querySelector('fieldset');

    var citations = this.options.citations || this._reader.metadata.citations;

    citations.forEach(function(citation, index) {
      var label = DomUtil.create('label', null, fieldset);
      var input = DomUtil.create('input', null, label);
      input.setAttribute('name', 'format');
      input.setAttribute('value', citation.format);
      input.setAttribute('type', 'radio');
      if ( index == 0 ) {
        input.setAttribute('checked', 'checked');
      }
      var text = document.createTextNode(" " + citation.format);
      label.appendChild(text);
      input.setAttribute('data-text', citation.text);
    });

    this._formatted = this._modal._container.querySelector("#formatted");
    this._message = this._modal._container.querySelector("#message");
    DomEvent.on(this._form, 'change', function(event) {
      var target = event.target;
      if ( target.tagName == 'INPUT' ) {
        this._initializeForm();
      }
    }, this);

    this._initializeForm();
  },

  _initializeForm: function() {
    var formatted = this._formatCitation();
    this._formatted.innerHTML = formatted;
    this._message.style.display = 'none';
    this._message.innerHTML = '';
  },

  _formatCitation: function(format) {
    if ( format == null ) {
      var selected = this._form.querySelector("input:checked");
      format = selected.value;
    }
    var selected = this._form.querySelector("input[value=" + format + "]");
    return selected.getAttribute('data-text');
    // return selected.dataset.text;
  },

  EOT: true
});

export var citation = function(options) {
  return new Citation(options);
}
