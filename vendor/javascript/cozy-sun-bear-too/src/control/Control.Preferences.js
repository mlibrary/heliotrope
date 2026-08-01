import {Class} from '../core/Class';
import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';
import * as Util from '../core/Util';

import assign from 'lodash/assign';
import keys from 'lodash/keys';

export var Preferences = Control.extend({
  options: {
    label: 'Preferences',
    hasThemes: false
  },

  defaultTemplate: `<button class="button--sm cozy-preferences" data-toggle="open" aria-label="Text display preferences and settings">Aa</button>`,

  onAdd: function(reader) {
    var self = this;
    var className = this._className();
    var container = DomUtil.create('div', className);
    var template = this.options.template || this.defaultTemplate;
    var body = new DOMParser().parseFromString(template, "text/html").body;
    while ( body.children.length ) {
      container.appendChild(body.children[0]);
    }

    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function(event) {
      event.preventDefault();
      self.activate();
    }, this);

    // self.initializeForm();
    this._modal = this._reader.modal({
      // template: '<form></form>',
      title: 'Preferences',
      className: 'cozy-modal-preferences',
      actions: [
        {
          label: 'Save Changes',
          callback: function(event) {
            self.updatePreferences(event);
          }
        }
      ],
      region: 'right'
    });

    return container;
  },

  activate: function() {
    var self = this;
    self.initializeForm();
    self._modal.activate();
  },

  _createPanel: function() {
    var self = this;
    if ( this._modal._container.querySelector('form') ) { return; }

    var template = '';

    var possible_fieldsets = [];
    if ( this._reader.metadata.layout == 'pre-paginated' ) {
      // different panel
      possible_fieldsets.push('Scale');
    } else {
      possible_fieldsets.push('TextSize');
    }
    possible_fieldsets.push('Display');

    if ( this._reader.rootfiles && this._reader.rootfiles.length > 1 ) {
      // this.options.hasPackagePaths = true;
      possible_fieldsets.push('Rendition');
    }

    if ( this._reader.options.themes && this._reader.options.themes.length > 0 ) {
      this.options.hasThemes = true;
      possible_fieldsets.push('Theme');
    }

    this._fieldsets = [];
    possible_fieldsets.forEach(function(cls) {
      var fieldset = new Preferences.fieldset[cls](this);
      template += fieldset.template();
      this._fieldsets.push(fieldset);
    }.bind(this))

    if ( this.options.fields ) {
      this.options.hasFields = true;
      for(var i in this.options.fields) {
        var field = this.options.fields[i];
        var id = "preferences-custom-" + i;
        template += `<fieldset class="custom-field">
          <legend>${field.label}</legend>
        `;
        for(var j in field.inputs) {
          var input = field.inputs[j];
          var checked = input.value == field.value ? ' checked="checked"' : '';
          template += `<label><input id="preferences-custom-${i}-${j}" type="radio" name="x${field.name}" value="${input.value}" ${checked}/>${input.label}</label>`;
        }
        if ( field.hint ) {
          template += `<p class="hint" style="font-size: 90%">${field.hint}</p>`;
        }
      }
    }

    template = '<form>' + template + '</form>';

    // this._modal = this._reader.modal({
    //   template: template,
    //   title: 'Preferences',
    //   className: 'cozy-modal-preferences',
    //   actions: [
    //     {
    //       label: 'Save Changes',
    //       callback: function(event) {
    //         self.updatePreferences(event);
    //       }
    //     }
    //   ],
    //   region: 'right'
    // });

    this._modal._container.querySelector('main').innerHTML = template;
    this._form = this._modal._container.querySelector('form');
  },

  initializeForm: function() {
    this._createPanel();
    this._fieldsets.forEach(function(fieldset) {
      fieldset.initializeForm(this._form);
    }.bind(this));
  },

  updatePreferences: function(event) {
    event.preventDefault();

    var doUpdate = false;
    var new_options = {};
    var saveable_options = {};
    this._fieldsets.forEach(function(fieldset) {
      // doUpdate = doUpdate || fieldset.updateForm(this._form, new_options);
      // assign(new_options, fieldset.updateForm(this._form));
      fieldset.updateForm(this._form, new_options, saveable_options);
    }.bind(this));

    if ( this.options.hasFields ) {
      for(var i in this.options.fields) {
        var field = this.options.fields[i];
        var id = "preferences-custom-" + i;
        var input = this._form.querySelector(`input[name="x${field.name}"]:checked`);
        if ( input.value != field.value ) {
          field.value = input.value;
          field.callback(field.value);
        }
      }
    }

    this._modal.deactivate();

    setTimeout(function() {
      this._reader.saveOptions(saveable_options);
      this._reader.reopen(new_options);
    }.bind(this), 100);
  },

  EOT: true
});

Preferences.fieldset = {};

var Fieldset = Class.extend({

  options: {},

  initialize: function (control, options) {
      Util.setOptions(this, options);
      this._control = control;
      this._current = {};
      this._id = (new Date()).getTime() + '-' + parseInt(Math.random((new Date()).getTime()) * 1000, 10);
  },

  template: function() {

  },

  EOT: true


});

Preferences.fieldset.TextSize = Fieldset.extend({

  initializeForm: function(form) {
    if ( ! this._input ) {
      this._input = form.querySelector(`#x${this._id}-input`);
      this._output = form.querySelector(`#x${this._id}-output`);
      this._preview = form.querySelector(`#x${this._id}-preview`);
      this._actionReset = form.querySelector(`#x${this._id}-reset`);

      this._input.addEventListener('input', this._updatePreview.bind(this));
      this._input.addEventListener('change', this._updatePreview.bind(this));

      this._actionReset.addEventListener('click', function(event) {
        event.preventDefault();
        this._input.value = 100;
        this._updatePreview();
      }.bind(this));
    }

    var text_size = this._control._reader.options.text_size || 100;
    if ( text_size == 'auto' ) { text_size = 100; }
    this._current.text_size = text_size;
    this._input.value = text_size;
    this._updatePreview();
  },

  updateForm: function(form, options, saveable) {
    // return { text_size: this._input.value };
    options.text_size = saveable.text_size = this._input.value;
    // options.text_size = this._input.value;
    // return ( this._input.value != this._current.text_size );
  },

  template: function() {
    return `<fieldset class="cozy-fieldset-text_size">
        <legend>Text Size</legend>
        <div class="preview--text_size" id="x${this._id}-preview">
          ‘Yes, that’s it,’ said the Hatter with a sigh: ‘it’s always tea-time, and we’ve no time to wash the things between whiles.’
        </div>
        <p style="white-space: no-wrap">
          <span>T-</span>
          <input name="text_size" type="range" id="x${this._id}-input" value="100" min="50" max="400" step="10" aria-valuemin="50" aria-valuemax="400" style="width: 75%; display: inline-block" />
          <span>T+</span>
        </p>
        <p>
          <span>Text Size: </span>
          <span id="x${this._id}-output">100</span>
          <button id="x${this._id}-reset" class="reset button--lg" style="margin-left: 8px">Reset to 100%</button> 
        </p>
      </fieldset>`;
  },

  _updatePreview: function() {
    this._preview.style.fontSize = `${( parseInt(this._input.value, 10) / 100 )}em`;
    this._output.innerHTML = `${this._input.value}%`;
    this._input.setAttribute('aria-valuenow',`${this._input.value}`);
    this._input.setAttribute('aria-valuetext',`${this._input.value} percent`);
  },

  EOT: true

});

Preferences.fieldset.Display = Fieldset.extend({

  initializeForm: function(form) {
    var flow = this._control._reader.options.flow || this._control._reader.metadata.flow || 'auto';
    // if ( flow == 'auto' ) { flow = 'paginated'; }

    var input = form.querySelector(`#x${this._id}-input-${flow}`);
    input.checked = true;
    this._current.flow = flow;

  },

  updateForm: function(form, options, saveable) {
    var input = form.querySelector(`input[name="x${this._id}-flow"]:checked`);
    options.flow = input.value;
    if ( options.flow != 'auto' ) {
      saveable.flow = options.flow;
    }
    // if ( input.value == 'auto' ) {
    //   // we do NOT want to save flow as a preference
    //   return {};
    // }
    // return { flow: input.value };
  },

  template: function() {
    var scrolled_help = '';
    if ( this._control._reader.metadata.layout != 'pre-paginated' ) {
      scrolled_help = "<br /><small>This is an experimental feature that may cause display and loading issues for the book when enabled.</small>";
    }
    return `<fieldset>
            <legend>Display</legend>
            <label><input name="x${this._id}-flow" type="radio" id="x${this._id}-input-auto" value="auto" /> Auto<br /><small>Let the reader determine display mode based on your browser dimensions and the type of content you're reading</small></label>
            <label><input name="x${this._id}-flow" type="radio" id="x${this._id}-input-paginated" value="paginated" /> Page-by-Page</label>
            <label><input name="x${this._id}-flow" type="radio" id="x${this._id}-input-scrolled-doc" value="scrolled-doc" /> Scroll${scrolled_help}</label>
          </fieldset>`;
  },

  EOT: true

});

Preferences.fieldset.Theme = Fieldset.extend({

  initializeForm: function(form) {
    var theme = this._control._reader.options.theme || 'default';

    var input = form.querySelector(`#x${this._id}-input-theme-${theme}`);
    input.checked = true;
    this._current.theme = theme;
  },

  updateForm: function(form, options, saveable) {
    var input = form.querySelector(`input[name="x${this._id}-theme"]:checked`);
    options.theme = saveable.theme = input.value;
    // return { theme: input.value };
  },

  template: function() {
    var template = `<fieldset>
            <legend>Theme</legend>
            <label><input name="x${this._id}-theme" type="radio" id="x${this._id}-input-theme-default" value="default" />Default</label>`;

    this._control._reader.options.themes.forEach(function(theme) {
      template += `<label><input name="x${this._id}-theme" type="radio" id="x${this._id}-input-theme-${theme.klass}" value="${theme.klass}" />${theme.name}</label>`
    }.bind(this));

    template += '</fieldset>';

    return template;

  },

  EOT: true

});

Preferences.fieldset.Rendition = Fieldset.extend({

  initializeForm: function(form) {
    var rootfiles = this._control._reader.rootfiles;
    var rootfilePath = this._control._reader.options.rootfilePath;
    var expr = rootfilePath ? `[value="${rootfilePath}"]` : ":first-child";
    var input = form.querySelector(`input[name="x${this._id}-rootfilePath"]${expr}`);
    input.checked = true;
    this._current.rootfilePath = rootfilePath || rootfiles[0].rootfilePath;
  },

  updateForm: function(form, options, saveable) {
    var input = form.querySelector(`input[name="x${this._id}-rootfilePath"]:checked`);
    if ( input.value != this._current.rootfilePath ) {
      options.rootfilePath = input.value;
      this._current.rootfilePath = input.value;
    }
  },

  template: function() {
    var template = `<fieldset>
            <legend>Rendition</legend>
    `;

    this._control._reader.rootfiles.forEach(function(rootfile, i) {
      template += `<label><input name="x${this._id}-rootfilePath" type="radio" id="x${this._id}-input-rootfilePath-${i}" value="${rootfile.rootfilePath}" />${rootfile.label || rootfile.accessMode || rootfile.rootfilePath}</label>`;
    }.bind(this))

    template += '</fieldset>';

    return template;

  },

  EOT: true

});

Preferences.fieldset.Scale = Fieldset.extend({

  initializeForm: function(form) {
    if ( ! this._input ) {
      this._input = form.querySelector(`#x${this._id}-input`);
      this._output = form.querySelector(`#x${this._id}-output`);
      this._preview = form.querySelector(`#x${this._id}-preview > div`);
      this._actionReset = form.querySelector(`#x${this._id}-reset`);

      this._input.addEventListener('input', this._updatePreview.bind(this));
      this._input.addEventListener('change', this._updatePreview.bind(this));

      this._actionReset.addEventListener('click', function(event) {
        event.preventDefault();
        this._input.value = 100;
        this._updatePreview();
      }.bind(this));
    }

    var scale = this._control._reader.options.scale || 100;
    if ( ! scale ) { scale = 100; }
    this._current.scale = scale;
    this._input.value = scale;
    this._updatePreview();
  },

  updateForm: function(form, options, saveable) {
    // return { text_size: this._input.value };
    options.scale = saveable.scale = this._input.value;
    // options.text_size = this._input.value;
    // return ( this._input.value != this._current.text_size );
  },

  template: function() {
    return `<fieldset class="cozy-fieldset-text_size">
        <legend>Zoom In/Out</legend>
        <div class="preview--scale" id="x${this._id}-preview" style="overflow: hidden; height: 5rem">
          <div>
            ‘Yes, that’s it,’ said the Hatter with a sigh: ‘it’s always tea-time, and we’ve no time to wash the things between whiles.’
          </div>
        </div>
        <p style="white-space: no-wrap">
          <span style="font-size: 150%">⊖<span class="u-screenreader"> Zoom Out</span></span>
          <input name="scale" type="range" id="x${this._id}-input" value="100" min="50" max="400" step="10" style="width: 75%; display: inline-block" />
          <span style="font-size: 150%">⊕<span class="u-screenreader">Zoom In </span></span>
        </p>
        <p>
          <span>Scale: </span>
          <span id="x${this._id}-output">100</span>
          <button id="x${this._id}-reset" class="reset button--inline" style="margin-left: 8px">Reset</button> 
        </p>
      </fieldset>`;
  },

  _updatePreview: function() {
    this._preview.style.transform = `scale(${( parseInt(this._input.value, 10) / 100 )}) translate(0,0)`;
    this._output.innerHTML = `${this._input.value}%`;
  },

  EOT: true

});

export var preferences = function(options) {
  return new Preferences(options);
}
