import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Widget = Control.extend({


  options: {
      // @option region: String = 'topright'
      // The region of the control (one of the reader corners). Possible values are `'topleft'`,
      // `'topright'`, `'bottomleft'` or `'bottomright'`
  },

  onAdd: function(reader) {
    var container = this._container;
    if ( container ) {
      // NOOP
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

    this._onAddExtra(container);
    this._updateTemplate(container);
    this._updateClass(container);
    this._bindEvents(container);

    return container;
  },

  _updateTemplate: function(container) {
    var data = this.data();
    for(var slot in data) {
      if ( data.hasOwnProperty(slot) ) {
        var value = data[slot];
        if ( typeof(value) == "function" ) { value = value(); }
        var node = container.querySelector(`[data-slot=${slot}]`);
        if ( node ) {
          if ( node.hasAttribute('value') ) {
            node.setAttribute('value', value);
          } else {
            node.innerHTML = value;
          }
        }
      }
    }
  },

  _updateClass: function(container) {
    if ( this.options.className ) {
      DomUtil.addClass(container, this.options.className);
    }
  },

  _onAddExtra: function() { },

  _bindEvents: function(container) {
    var control = container.querySelector("[data-toggle=button]");
    if ( ! control ) { return ; }
    DomEvent.disableClickPropagation(control);
    DomEvent.on(control, 'click', DomEvent.stop);
    DomEvent.on(control, 'click', this._action, this);
  },

  _action: function() {
  },

  data: function() {
    return this.options.data || {};
  },

  EOT: true
});

Widget.Button = Widget.extend({
  defaultTemplate: `<button data-toggle="button" data-slot="label"></button>`,

  _action: function() {
    this.options.onClick(this, this._reader);
  },

  EOT: true
});

Widget.Panel = Widget.extend({
  defaultTemplate: `<div><span data-slot="text"></span></div>`,


  EOT: true
});

Widget.Toggle = Widget.extend({
  defaultTemplate: `<button data-toggle="button" data-slot="label"></button>`,

  _onAddExtra: function(container) {
    this.state(this.options.states[0].stateName, container);

    return container;
  },

  state: function(stateName, container) {
    container = container || this._container;
    this._resetState(container);
    this._state = this.options.states.filter(function(s) { return s.stateName == stateName })[0];
    this._updateClass(container);
    this._updateTemplate(container);
  },

  _resetState: function(container) {
    if ( ! this._state ) { return; }
    if ( this._state.className ) {
      DomUtil.removeClass(container, this._state.className);
    }
  },

  _updateClass: function(container) {
    if ( this._state.className ) {
      DomUtil.addClass(container, this._state.className);
    }
  },

  _action: function() {
    this._state.onClick(this, this._reader);
  },

  data: function() {
    return this._state.data || {};
  },

  EOT: true
});

// export var widget = function(options) {
//   return new Widget(options);
// }

export var widget = {
  button: function(options) { return new Widget.Button(options); },
  panel: function(options) { return new Widget.Panel(options); },
  toggle: function(options) { return new Widget.Toggle(options); }
}
