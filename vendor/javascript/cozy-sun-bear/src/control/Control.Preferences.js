import {Class} from '../core/Class';
import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';
import * as Util from '../core/Util';
import SliderControl from '../utils/slider-control';
import { PreferencesConfig } from '../config/PreferencesConfig';

import assign from 'lodash/assign';
import keys from 'lodash/keys';

export var Preferences = Control.extend({
  options: {
    label: 'Preferences',
    hasThemes: false
  },

  defaultTemplate: `<button class="button--sm cozy-preferences oi" data-toggle="open" data-glyph="cog" aria-label="Preferences and Settings"></button>`,

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

    // Build actions array (footer buttons) conditionally
    var actions = [
      {
        label: 'Save Changes',
        callback: function(event) {
          self.updatePreferences(event);
        }
      }
    ];

    // For now at least, we only want the overarching "Set Defaults" button for reflowable layouts
    if (this._reader.metadata.layout != 'pdf' && this._reader.metadata.layout != 'pre-paginated') {
      actions.push({
        label: 'Set Defaults',
        callback: function(event) {
          self.resetPreferencesToDefault(event);
        }
      });
    }

    this._modal = this._reader.modal({
      title: 'Preferences',
      className: this._reader.metadata.layout == 'reflowable' ? 'cozy-modal-preferences' : 'cozy-modal-preferences',
      actions: actions,
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
      possible_fieldsets.push('Font');
      possible_fieldsets.push('Spacing');
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
      // Dumb as it seems, we're closing <div id="text-preferences-scrolling-area"> here which, in theory, is...
      // dynamically/conditionally added. I'm OK with this. This file is very clunky in its attempt to support...
      // generalized use of cozy-sun-bear, which never happened. Might all be refactored "soon"?! :-D
      if( cls === 'Display') template += '</div>'
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

  // this method is run on click of the "Set Defaults" footer button, for both reflowable EPUB and pdf ebooks, so...
  // element existence checks are key!
  resetPreferencesToDefault: function() {
    // this is the only option that targets the PDF reader's Zoom In/Out option, resetting it to "Automatic Zoom"
    // see heliotrope's app/views/e_pubs/show_pdf.html.erb
    var pdf_scale_radio_buttons = document.querySelector('ul[id$="-list"]');
    if (pdf_scale_radio_buttons) pdf_scale_radio_buttons.querySelector('input[value="auto"]').checked = true;

    // the rest of these target the options available for reflowable EPUBs
    var fontDropdown = document.querySelector('[name="font"]');
    if (fontDropdown) fontDropdown.value = "default";

    // Reset text size to index for 100% (index 5 in the 50-400 range with 10% steps)
    var fontSizeSlider = document.querySelector('[name="text_size"]');
    if (fontSizeSlider) {
      // Values are 50, 60, 70, 80, 90, 100, ... so 100 is at index 5
      fontSizeSlider.value = 5;
      // Dispatch event to update display
      fontSizeSlider.dispatchEvent(new Event('input', { bubbles: true }));
    }

    // Reset the 5 new text options
    var wordSpacingInput = document.querySelector('input[id$="-word-spacing"]');
    if (wordSpacingInput) {
      wordSpacingInput.value = 0;
      wordSpacingInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    var letterSpacingInput = document.querySelector('input[id$="-letter-spacing"]');
    if (letterSpacingInput) {
      letterSpacingInput.value = 0;
      letterSpacingInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    var lineHeightInput = document.querySelector('input[id$="-line-height"]');
    if (lineHeightInput) {
      lineHeightInput.value = 0;
      lineHeightInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    var marginsInput = document.querySelector('input[id$="-margins"]');
    if (marginsInput) {
      marginsInput.value = 0;
      marginsInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    var paragraphSpacingInput = document.querySelector('input[id$="-paragraph-spacing"]');
    if (paragraphSpacingInput) {
      paragraphSpacingInput.value = 0;
      paragraphSpacingInput.dispatchEvent(new Event('input', { bubbles: true }));
    }

    // set Display mode radio buttons to "Auto"
    var textDisplayModePanel = document.querySelector('#text-display-mode');
    if (textDisplayModePanel) {
      var autoRadio = textDisplayModePanel.querySelector('input[type="radio"][value="auto"]');
      if (autoRadio) autoRadio.checked = true;
    }

    if (Array.isArray(this._fieldsets)) {
      this._fieldsets.forEach(function(fieldset) {
        if (typeof fieldset._updatePreview === "function") {
          fieldset._updatePreview();
        }
      });
    }
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
      // useful dev output if you're adding/changing saved preferences
      // console.log('savable_options: ' + JSON.stringify(saveable_options, null, 4));
      this._reader.saveOptions(saveable_options);
      console.log('new_options: ' + JSON.stringify(new_options, null, 4));
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

Preferences.fieldset.Font = Fieldset.extend({

  initializeForm: function(form) {
    if ( ! this._input ) {
      this._input = form.querySelector(`#x${this._id}-input`);
      this._output = form.querySelector(`#x${this._id}-output`);
      this._preview = form.querySelector(`#x${this._id}-preview`);
      this._font = form.querySelector(`#x${this._id}-font`);

      // Reset button reference
      this._actionResetTextSize = form.querySelector(`#x${this._id}-text-size-reset`);

      // Use shared config for text size values
      this._textSizeValues = PreferencesConfig.textSize.valid.map(String);

      // Initialize slider control with contextual aria-label
      this._textSizeSlider = new SliderControl(this._input, this._textSizeValues, 'font size');

      this._input.addEventListener('input', this._updatePreview.bind(this));
      this._input.addEventListener('change', this._updatePreview.bind(this));
      this._font.addEventListener('change', this._updatePreview.bind(this));

      // Reset button event listener
      this._actionResetTextSize.addEventListener('click', function(event) {
        event.preventDefault();
        // Find index of 100 in text size values (50, 60, 70, ... 100 is at index 5)
        var resetIndex = this._textSizeValues.indexOf('100');
        this._input.value = String(resetIndex);
        this._textSizeSlider.currentIndex = resetIndex;
        this._textSizeSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));
    }

    var font_input = this._control._reader.options.font || this._control._reader.metadata.font || 'default';
    this._current.font = font_input;
    this._font.value = font_input;

    var text_size = this._control._reader.options.text_size || 100;
    if ( text_size == 'auto' ) { text_size = 100; }
    this._current.text_size = text_size;
    // Find index for text size value
    var textSizeIndex = this._textSizeValues.indexOf(String(text_size));
    if (textSizeIndex === -1) textSizeIndex = this._textSizeValues.indexOf('100'); // Default to 100%
    this._input.value = String(textSizeIndex);
    this._textSizeSlider.currentIndex = textSizeIndex;

    this._updatePreview();
  },

  updateForm: function(form, options, saveable) {
    options.font = saveable.font = this._font.value;
    options.text_size = saveable.text_size = this._textSizeSlider.getValue();
  },

  template: function() {
    return `
<div id="text-preview" role="region" aria-labelledby="text-preview-heading">
  <h4 id="text-preview-heading" class="preview-heading">Preview</h4>
  <div class="preview--text_preferences" id="x${this._id}-preview" style="font-size: 1em;">
    <p>'Yes, that's it,' said the Hatter with a sigh: 'it's always tea-time, and we've no time to wash the things between whiles.'</p>
    <p>'Then you keep moving round, I suppose?' said Alice.</p>
    <p>'Exactly so,' said the Hatter: 'as the things get used up.'</p>
  </div>
</div>
<div id="text-preferences-scrolling-area">
<fieldset class="cozy-fieldset-font_options">
  <legend>Font</legend>
  <div>
    <span id="change-font">Change Font</span>
    <select aria-labelledby="change-font" name="font" id="x${this._id}-font">
      <option value="default">Default</option>
      <optgroup label="Serif Fonts">
        <option value="Palatino,Palatino Linotype,Palatino LT STD,Book Antiqua,Georgia,serif">Palatino</option>
        <option value="TimesNewRoman,Times New Roman,Times,Baskerville,Georgia,serif">Times New Roman</option>
      </optgroup>
      <optgroup label="Sans Serif Fonts">
        <option value="Arial,Helvetica Neue,Helvetica,sans-serif">Arial</option>
        <option value="Verdana,Geneva,sans-serif">Verdana</option>
      </optgroup>
      <optgroup label="Dyslexic Fonts">
        <option value="OpenDyslexic">Open Dyslexic</option>
      </optgroup>
      <optgroup label="Monospace Fonts">
        <option value="Consolas,monaco,monospace">Consolas</option>
      </optgroup>
    </select>
  </div>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-text-size-label" for="x${this._id}-input">Adjust Font Size</label>
      <span id="x${this._id}-output" class="slider-value">100%</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset text size to 100%" id="x${this._id}-text-size-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-text-size-label" name="text_size" type="range" id="x${this._id}-input" value="100">
    </div>
  </div>
</fieldset>`;
  },

  _updatePreview: function() {
    if (this._font.value != 'default') {
      this._preview.style.fontFamily = this._font.value;
    } else {
      this._preview.style.fontFamily = null;
    }

    // Get text size value from slider
    var textSizeValue = parseInt(this._textSizeSlider.getValue(), 10);
    this._preview.style.fontSize = `${( textSizeValue / 100 )}em`;

    // Update text size display
    this._output.textContent = `${textSizeValue}%`;
  },

  EOT: true

});

Preferences.fieldset.Spacing = Fieldset.extend({

  initializeForm: function(form) {
    if ( ! this._initialized ) {
      // Query by class since the preview is created by Font fieldset with a different ID
      this._preview = form.querySelector('.preview--text_preferences');

      // Reset button references
      this._actionResetWordSpacing = form.querySelector(`#x${this._id}-word-spacing-reset`);
      this._actionResetLetterSpacing = form.querySelector(`#x${this._id}-letter-spacing-reset`);
      this._actionResetLineHeight = form.querySelector(`#x${this._id}-line-height-reset`);
      this._actionResetMargins = form.querySelector(`#x${this._id}-margins-reset`);
      this._actionResetParagraphSpacing = form.querySelector(`#x${this._id}-paragraph-spacing-reset`);

      // New spacing inputs
      this._wordSpacing = form.querySelector(`#x${this._id}-word-spacing`);
      this._letterSpacing = form.querySelector(`#x${this._id}-letter-spacing`);
      this._lineHeight = form.querySelector(`#x${this._id}-line-height`);
      this._margins = form.querySelector(`#x${this._id}-margins`);
      this._paragraphSpacing = form.querySelector(`#x${this._id}-paragraph-spacing`);

      // Value display spans
      this._wordSpacingValue = form.querySelector(`#x${this._id}-word-spacing-value`);
      this._letterSpacingValue = form.querySelector(`#x${this._id}-letter-spacing-value`);
      this._lineHeightValue = form.querySelector(`#x${this._id}-line-height-value`);
      this._marginsValue = form.querySelector(`#x${this._id}-margins-value`);
      this._paragraphSpacingValue = form.querySelector(`#x${this._id}-paragraph-spacing-value`);

      // Use shared config for spacing values
      this._wordSpacingValues = PreferencesConfig.wordSpacing.valid;
      this._letterSpacingValues = PreferencesConfig.letterSpacing.valid;
      this._lineHeightValues = PreferencesConfig.lineHeight.valid;
      this._marginsValues = PreferencesConfig.margins.valid;
      this._paragraphSpacingValues = PreferencesConfig.paragraphSpacing.valid;

      // Initialize slider controls with contextual aria-labels
      this._wordSpacingSlider = new SliderControl(this._wordSpacing, this._wordSpacingValues, 'word spacing');
      this._letterSpacingSlider = new SliderControl(this._letterSpacing, this._letterSpacingValues, 'letter spacing');
      this._lineHeightSlider = new SliderControl(this._lineHeight, this._lineHeightValues, 'line height');
      this._marginsSlider = new SliderControl(this._margins, this._marginsValues, 'margins');
      this._paragraphSpacingSlider = new SliderControl(this._paragraphSpacing, this._paragraphSpacingValues, 'paragraph spacing');

      // Add listeners for spacing inputs
      [this._wordSpacing, this._letterSpacing, this._lineHeight, this._margins, this._paragraphSpacing].forEach(function(input) {
        input.addEventListener('input', this._updatePreview.bind(this));
        input.addEventListener('change', this._updatePreview.bind(this));
      }.bind(this));

      // Reset button event listeners
      this._actionResetWordSpacing.addEventListener('click', function(event) {
        event.preventDefault();
        this._wordSpacing.value = '0';
        this._wordSpacingSlider.currentIndex = 0;
        this._wordSpacingSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));

      this._actionResetLetterSpacing.addEventListener('click', function(event) {
        event.preventDefault();
        this._letterSpacing.value = '0';
        this._letterSpacingSlider.currentIndex = 0;
        this._letterSpacingSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));

      this._actionResetLineHeight.addEventListener('click', function(event) {
        event.preventDefault();
        this._lineHeight.value = '0';
        this._lineHeightSlider.currentIndex = 0;
        this._lineHeightSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));

      this._actionResetMargins.addEventListener('click', function(event) {
        event.preventDefault();
        this._margins.value = '0';
        this._marginsSlider.currentIndex = 0;
        this._marginsSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));

      this._actionResetParagraphSpacing.addEventListener('click', function(event) {
        event.preventDefault();
        this._paragraphSpacing.value = '0';
        this._paragraphSpacingSlider.currentIndex = 0;
        this._paragraphSpacingSlider.updateDisplay();
        this._updatePreview();
      }.bind(this));

      this._initialized = true;
    }

    // Ensure preview is available even if not in initialization block
    // Use a generic selector since the preview is created by the Font fieldset with its own ID
    if (!this._preview) {
      this._preview = form.querySelector('.preview--text_preferences');
    }

    // Initialize spacing options - find index or default to 0 (auto)
    this._current.word_spacing = this._control._reader.options.word_spacing || 'auto';
    var wordSpacingIndex = this._wordSpacingValues.indexOf(this._current.word_spacing);
    if (wordSpacingIndex === -1) wordSpacingIndex = 0;
    this._wordSpacing.value = String(wordSpacingIndex);
    this._wordSpacingSlider.currentIndex = wordSpacingIndex;

    this._current.letter_spacing = this._control._reader.options.letter_spacing || 'auto';
    var letterSpacingIndex = this._letterSpacingValues.indexOf(this._current.letter_spacing);
    if (letterSpacingIndex === -1) letterSpacingIndex = 0;
    this._letterSpacing.value = String(letterSpacingIndex);
    this._letterSpacingSlider.currentIndex = letterSpacingIndex;

    this._current.line_height = this._control._reader.options.line_height || 'auto';
    var lineHeightIndex = this._lineHeightValues.indexOf(this._current.line_height);
    if (lineHeightIndex === -1) lineHeightIndex = 0;
    this._lineHeight.value = String(lineHeightIndex);
    this._lineHeightSlider.currentIndex = lineHeightIndex;

    this._current.margins = this._control._reader.options.margins || 'auto';
    var marginsIndex = this._marginsValues.indexOf(this._current.margins);
    if (marginsIndex === -1) marginsIndex = 0;
    this._margins.value = String(marginsIndex);
    this._marginsSlider.currentIndex = marginsIndex;

    this._current.paragraph_spacing = this._control._reader.options.paragraph_spacing || 'auto';
    var paragraphSpacingIndex = this._paragraphSpacingValues.indexOf(this._current.paragraph_spacing);
    if (paragraphSpacingIndex === -1) paragraphSpacingIndex = 0;
    this._paragraphSpacing.value = String(paragraphSpacingIndex);
    this._paragraphSpacingSlider.currentIndex = paragraphSpacingIndex;

    this._updatePreview();
  },


  updateForm: function(form, options, saveable) {
    options.word_spacing = saveable.word_spacing = this._wordSpacingSlider.getValue();
    options.letter_spacing = saveable.letter_spacing = this._letterSpacingSlider.getValue();
    options.line_height = saveable.line_height = this._lineHeightSlider.getValue();
    options.margins = saveable.margins = this._marginsSlider.getValue();
    options.paragraph_spacing = saveable.paragraph_spacing = this._paragraphSpacingSlider.getValue();
  },

  template: function() {
    return `
<fieldset class="cozy-fieldset-spacing_options">
  <legend>Spacing</legend>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-word-spacing-label" for="x${this._id}-word-spacing">Word Spacing</label>
      <span id="x${this._id}-word-spacing-value" class="slider-value">auto</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset word spacing to auto" id="x${this._id}-word-spacing-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-word-spacing-label" type="range" id="x${this._id}-word-spacing" value="auto">
    </div>
  </div>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-letter-spacing-label" for="x${this._id}-letter-spacing">Letter Spacing</label>
      <span id="x${this._id}-letter-spacing-value" class="slider-value">auto</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset letter spacing to auto" id="x${this._id}-letter-spacing-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-letter-spacing-label" type="range" id="x${this._id}-letter-spacing" value="auto">
    </div>
  </div>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-line-height-label" for="x${this._id}-line-height">Line Height</label>
      <span id="x${this._id}-line-height-value" class="slider-value">auto</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset line height to auto" id="x${this._id}-line-height-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-line-height-label" type="range" id="x${this._id}-line-height" value="auto">
    </div>
  </div>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-margins-label" for="x${this._id}-margins">Margins</label>
      <span id="x${this._id}-margins-value" class="slider-value">auto</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset margins to auto" id="x${this._id}-margins-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-margins-label" type="range" id="x${this._id}-margins" value="auto">
    </div>
  </div>
  <div class="slider-option">
    <div class="slider-label-row">
      <label id="x${this._id}-paragraph-spacing-label" for="x${this._id}-paragraph-spacing">Paragraph Spacing</label>
      <span id="x${this._id}-paragraph-spacing-value" class="slider-value">auto</span>
    </div>
    <div class="slider-control-row">
      <button aria-label="Reset paragraph spacing to auto" id="x${this._id}-paragraph-spacing-reset" class="reset-text-options button--sm"><i class="icon-action-undo oi" data-glyph="action-undo" aria-hidden="true"></i></button>
      <input aria-labelledby="x${this._id}-paragraph-spacing-label" type="range" id="x${this._id}-paragraph-spacing" value="auto">
    </div>
  </div>
</fieldset>`;
  },

  _updatePreview: function() {

    // Get actual values from sliders
    var wordSpacingValue = this._wordSpacingSlider.getValue();
    var letterSpacingValue = this._letterSpacingSlider.getValue();
    var lineHeightValue = this._lineHeightSlider.getValue();
    var marginsValue = this._marginsSlider.getValue();
    var paragraphSpacingValue = this._paragraphSpacingSlider.getValue();

    // Update display spans
    this._wordSpacingValue.textContent = wordSpacingValue;
    this._letterSpacingValue.textContent = letterSpacingValue;
    this._lineHeightValue.textContent = lineHeightValue;
    this._marginsValue.textContent = marginsValue;
    this._paragraphSpacingValue.textContent = paragraphSpacingValue;

    // Apply styles to preview
    if (wordSpacingValue !== 'auto') {
      this._preview.style.wordSpacing = wordSpacingValue;
    } else {
      this._preview.style.wordSpacing = null;
    }

    if (letterSpacingValue !== 'auto') {
      this._preview.style.letterSpacing = letterSpacingValue;
    } else {
      this._preview.style.letterSpacing = null;
    }

    if (lineHeightValue !== 'auto') {
      this._preview.style.lineHeight = lineHeightValue;
    } else {
      this._preview.style.lineHeight = null;
    }

    if (marginsValue !== 'auto') {
      this._preview.style.margin = marginsValue;
    } else {
      this._preview.style.margin = null;
    }

    var paragraphs = this._preview.querySelectorAll('p');
    if (paragraphSpacingValue !== 'auto') {
      paragraphs.forEach(function(p) {
        p.style.marginBottom = paragraphSpacingValue;
      });
    } else {
      paragraphs.forEach(function(p) {
        p.style.marginBottom = null;
      });
    }
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
    return `<fieldset id="text-display-mode">
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
      this._actionResetTextSize = form.querySelector(`#x${this._id}-text-size-reset`);

      this._input.addEventListener('input', this._updatePreview.bind(this));
      this._input.addEventListener('change', this._updatePreview.bind(this));

      this._actionResetTextSize.addEventListener('click', function(event) {
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
    return `<fieldset class="cozy-fieldset-text_options">
        <legend>Zoom In/Out</legend>
        <p style="white-space: nowrap">
          <span style="font-size: 150%">⊖<span class="u-screenreader"> Zoom Out</span></span>
          <input name="scale" type="range" id="x${this._id}-input" value="100" min="50" max="400" step="10" style="width: 75%; display: inline-block" />
          <span style="font-size: 150%">⊕<span class="u-screenreader">Zoom In </span></span>
        </p>
        <p>
          <span>Scale: </span>
          <span id="x${this._id}-output">100</span>
          <button id="x${this._id}-text-size-reset" class="reset button--inline" style="margin-left: 8px">Reset</button> 
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
