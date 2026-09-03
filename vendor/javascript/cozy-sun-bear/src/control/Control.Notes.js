import {Control} from './Control';
import {Reader} from '../reader/Reader';
import {Modal} from './Modal';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Notes = Control.extend({

  defaultTemplate: `<button class="button--sm" data-toggle="open" aria-label="Notes">Notes</button>`,

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

    this._control = container.querySelector("[data-toggle=open]");
    this._control.setAttribute('id', 'action-' + this._id);
    container.style.position = 'relative';

    this._bindEvents();

    return container;
  },

  _bindEvents() {
    var self = this;
    
    this._reader.on('updateContents', function(data) {

      DomEvent.on(this._control, 'click', function(event) {
        event.preventDefault();
        self._goto_interval = false;
        self._reader.tracking.action('contents/open');
        self._modal.activate();
      }, this);

      this._modal = this._reader.modal({
        template: `
<div class="cozy-contents-main">
  <div class="cozy-contents-contentlist">
    <ul></ul>
  </div>
</div>`.trim(),
        title: 'Notes',
        region: 'left',
        className: 'cozy-modal-contents',
        callbacks: {
          onShow: function() {},
          onClose: function (modal) {
          if (self._goto_interval) {
            self._reader.rendition.manager.container.setAttribute("tabindex", 0);
            self._reader.rendition.manager.container.focus();
          }
        }
      }});

      this._display = {};
      this._display.noteslist = this._modal._container.querySelector(section[role="doc-endnotes"]);
      
      this._modal.on('click', 'a[href]', function(modal, target) {
        target = target.getAttribute('data-href');
        this._goto_interval = true;
        this._reader.tracking.action('contents/go/link');
        this._reader.display(target);
        return true;
      }.bind(this));

      this._modal.on('closed', function() {
        self._reader.tracking.action('contents/close');
      });

      var parent = self._modal._container.querySelector('section[role=doc-endnotes] ol');
      var _process = function(items, tabindex, parent) {
        items.forEach(function(item) {
          var option = self._createOption(item, tabindex, parent);
          if ( item.subitems && item.subitems.length ) {
            _process(item.subitems, tabindex + 1, option);
          }
        })
      };
      _process(data.toc, 0, parent);

    }.bind(this))
  },

  _createOption(chapter, tabindex, parent) {

    function pad(value, length) {
        return (value.toString().length < length) ? pad("-"+value, length):value;
    }
    var option = DomUtil.create('li');
    if ( chapter.href ) {
      var anchor = DomUtil.create('a', null, option);
      if ( chapter.html ) {
        anchor.innerHTML = chapter.html;
      } else {
        anchor.textContent = chapter.label;
      }
      // var tab = pad('', tabindex); tab = tab.length ? tab + ' ' : '';
      // option.textContent = tab + chapter.label;
      anchor.setAttribute('href', chapter.href);
      anchor.setAttribute('data-href', chapter.href);
    } else {
      var span = DomUtil.create('span', null, option);
      span.textContent = chapter.label;
    }

    if ( parent.tagName === 'LI' ) {
      // need to nest
      var tmp = parent.querySelector('ol');
      if ( ! tmp ) {
        tmp = DomUtil.create('ol', null, parent);
      }
      parent = tmp;
    }

    parent.appendChild(option);
    return option;
  },

  EOT: true
});

export var notes = function(options) {
  return new Notes(options);
};
