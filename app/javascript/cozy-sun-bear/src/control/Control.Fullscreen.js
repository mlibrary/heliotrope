import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Fullscreen = Control.extend({
  options: {
    label: 'View Fullscreen',
    html: '<span>View Fullscreen</span>'
  },

  defaultTemplate: `<button class="button--sm cozy-fullscreen oi" data-toggle="open" data-glyph="fullscreen-enter" aria-label="Enter Fullscreen"></button>`,

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
    DomEvent.on(this._control, 'click', function(event) {
      event.preventDefault();
      self.activate();
    }, this)

    // // fullscreenchange is not standard across all browsers
    // document.addEventListener('fullscreenchange', (event) => {
    //   // document.fullscreenElement will point to the element that
    //   // is in fullscreen mode if there is one. If there isn't one,
    //   // the value of the property is null.    
    //   this._fullscreenchangeHandler();
    // });

    this._reader.on('fullscreenchange', (data) => {
      this._fullscreenchangeHandler(data.isFullscreen);
    })

    return container;
  },

  activate: function() {
    if ( ! document.fullscreenElement ) {
      this._reader.requestFullscreen();
    } else {
      if ( document.exitFullscreen ) {
        document.exitFullscreen();
      }
    }
  },

  _fullscreenchangeHandler: function(isFullscreen) {
    if (isFullscreen) {
      this._control.dataset.glyph = 'fullscreen-exit';
      this._control.setAttribute('aria-label', 'Exit Fullscreen');
    } else {
      this._control.dataset.glyph = 'fullscreen-enter';
      this._control.setAttribute('aria-label', 'Enter Fullscreen');
    }    
  },

  EOT: true
});

export var fullscreen = function(options) {
  return new Fullscreen(options);
}
