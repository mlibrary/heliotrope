(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("xmldom"));
	else if(typeof define === 'function' && define.amd)
		define(["xmldom"], factory);
	else if(typeof exports === 'object')
		exports["cozy"] = factory(require("xmldom"));
	else
		root["cozy"] = factory(root["xmldom"]);
})(self, function(__WEBPACK_EXTERNAL_MODULE__5348__) {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 5782:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "Control": () => (/* reexport */ Control),
  "control": () => (/* reexport */ control)
});

// EXTERNAL MODULE: ./src/core/Class.js
var Class = __webpack_require__(7573);
// EXTERNAL MODULE: ./src/reader/Reader.js + 1 modules
var Reader = __webpack_require__(8399);
// EXTERNAL MODULE: ./src/core/Util.js
var Util = __webpack_require__(7518);
// EXTERNAL MODULE: ./src/dom/DomUtil.js
var DomUtil = __webpack_require__(9542);
;// CONCATENATED MODULE: ./src/control/Control.js




/*
 * @class Control
 * @aka L.Control
 * @inherits Class
 *
 * L.Control is a base class for implementing reader controls. Handles regioning.
 * All other controls extend from this class.
 */

var Control = Class/* Class.extend */.w.extend({
  // @section
  // @aka Control options
  options: {// @option region: String = 'topright'
    // The region of the control (one of the reader corners). Possible values are `'topleft'`,
    // `'topright'`, `'bottomleft'` or `'bottomright'`
  },
  initialize: function initialize(options) {
    Util.setOptions(this, options);

    if (options.container) {
      this._container = options.container;
      this._locked = true;
    }

    this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
  },

  /* @section
   * Classes extending L.Control will inherit the following methods:
   *
   * @method getRegion: string
   * Returns the region of the control.
   */
  getRegion: function getRegion() {
    return this.options.region;
  },
  // @method setRegion(region: string): this
  // Sets the region of the control.
  setRegion: function setRegion(region) {
    var reader = this._reader;

    if (reader) {
      reader.removeControl(this);
    }

    this.options.region = region;

    if (reader) {
      reader.addControl(this);
    }

    return this;
  },
  // @method getContainer: HTMLElement
  // Returns the HTMLElement that contains the control.
  getContainer: function getContainer() {
    return this._container;
  },
  // @method addTo(reader: Map): this
  // Adds the control to the given reader.
  addTo: function addTo(reader) {
    this.remove();
    this._reader = reader;
    var container = this._container = this.onAdd(reader);
    DomUtil.addClass(container, 'cozy-control');

    if (!this._locked) {
      var region = this.getRegion();
      var area = reader.getControlRegion(region);
      area.appendChild(container);
    }

    return this;
  },
  // @method remove: this
  // Removes the control from the reader it is currently active on.
  remove: function remove() {
    if (!this._reader) {
      return this;
    }

    if (!this._container) {
      return this;
    }

    if (!this._locked) {
      DomUtil.remove(this._container);
    }

    if (this.onRemove) {
      this.onRemove(this._reader);
    }

    this._reader = null;
    return this;
  },
  _refocusOnMap: function _refocusOnMap(e) {
    // if reader exists and event is not a keyboard event
    if (this._reader && e && e.screenX > 0 && e.screenY > 0) {
      this._reader.getContainer().focus();
    }
  },
  _className: function _className(widget) {
    var className = ['cozy-control'];

    if (this.options.direction) {
      className.push('cozy-control-' + this.options.direction);
    }

    if (widget) {
      className.push('cozy-control-' + widget);
    }

    return className.join(' ');
  }
});
var control = function control(options) {
  return new Control(options);
};
/* @section Extension methods
 * @uninheritable
 *
 * Every control should extend from `L.Control` and (re-)implement the following methods.
 *
 * @method onAdd(reader: Map): HTMLElement
 * Should return the container DOM element for the control and add listeners on relevant reader events. Called on [`control.addTo(reader)`](#control-addTo).
 *
 * @method onRemove(reader: Map)
 * Optional method. Should contain all clean up code that removes the listeners previously added in [`onAdd`](#control-onadd). Called on [`control.remove()`](#control-remove).
 */

/* @namespace Map
 * @section Methods for Layers and Controls
 */

Reader/* Reader.include */.E.include({
  // @method addControl(control: Control): this
  // Adds the given control to the reader
  addControl: function addControl(control) {
    control.addTo(this);
    return this;
  },
  // @method removeControl(control: Control): this
  // Removes the given control from the reader
  removeControl: function removeControl(control) {
    control.remove();
    return this;
  },
  getControlContainer: function getControlContainer() {
    var l = 'cozy-';

    if (!this._controlContainer) {
      this._controlContainer = DomUtil.create('div', l + 'control-container', this._container);
    }

    return this._controlContainer;
  },
  getControlRegion: function getControlRegion(target) {
    if (!this._panes[target]) {
      // target is dot-delimited string
      // first dot is the panel
      var parts = target.split('.');
      var tmp = [];
      var parent = this._container;
      var x = 0;

      while (parts.length) {
        var slug = parts.shift();
        tmp.push(slug);
        var panel = tmp.join(".");
        var className = 'cozy-panel-' + slug;

        if (!this._panes[panel]) {
          this._panes[panel] = DomUtil.create('div', className, parent);
        }

        parent = this._panes[panel];
        x += 1;

        if (x > 100) {
          break;
        }
      }
    }

    return this._panes[target];
  },
  getControlRegion_1: function getControlRegion_1(target) {
    var tmp = target.split('.');
    var region = tmp.shift();
    var slot = tmp.pop() || '-slot';
    var container = this._panes[region];

    if (!this._panes[target]) {
      var className = 'cozy-' + region + '--item cozy-slot-' + slot;

      if (!this._panes[region + '.' + slot]) {
        var div = DomUtil.create('div', className);

        if (slot == 'left' || slot == 'bottom') {
          var childElement = this._panes[region].firstChild;

          this._panes[region].insertBefore(div, childElement);
        } else {
          this._panes[region].appendChild(div);
        }

        this._panes[region + '.' + slot] = div;
      }

      className = this._classify(tmp);
      this._panes[target] = DomUtil.create('div', className, this._panes[region + '.' + slot]);
    }

    return this._panes[target];
  },
  _classify: function _classify(tmp) {
    var l = 'cozy-';
    var className = [];

    for (var i in tmp) {
      className.push(l + tmp[i]);
    }

    className = className.join(' ');
    return className;
  },
  _clearControlRegion: function _clearControlRegion() {
    for (var i in this._controlRegions) {
      DomUtil.remove(this._controlRegions[i]);
    }

    DomUtil.remove(this._controlContainer);
    delete this._controlRegions;
    delete this._controlContainer;
  }
});
// EXTERNAL MODULE: ./src/dom/DomEvent.js + 2 modules
var DomEvent = __webpack_require__(975);
;// CONCATENATED MODULE: ./src/control/Control.Paging.js




var PageControl = Control.extend({
  onAdd: function onAdd(reader) {
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className), this._control = this._createButton(this._fill(options.html || options.label), this._fill(options.label), className, container);
    }

    this._bindEvents();

    return container;
  },
  _createButton: function _createButton(html, title, className, container) {
    var link = DomUtil.create('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;
    /*
     * Will force screen readers like VoiceOver to read this as "Zoom in - button"
     */

    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);
    return link;
  },
  _bindEvents: function _bindEvents() {
    var self = this;
    DomEvent.disableClickPropagation(this._control);
    DomEvent.on(this._control, 'click', DomEvent.stop);
    DomEvent.on(this._control, 'click', this._action, this);

    this._reader.on('reopen', function (data) {
      // update the button text / titles
      var html = self.options.html || self.options.label;
      self._control.innerHTML = self._fill(html);

      self._control.setAttribute('title', self._fill(self.options.label));

      self._control.setAttribute('aria-label', self._fill(self.options.label));
    });
  },
  _unit: function _unit() {
    return this._reader.options.flow == 'scrolled-doc' ? 'Section' : 'Page';
  },
  _fill: function _fill(s) {
    var unit = this._unit();

    return s.replace(/\$\{unit\}/g, unit);
  },
  _label: function _label() {
    return this.options.label + " " + (this._reader.options.flow == 'scrolled-doc') ? 'Section' : 'Page';
  },
  EOT: true
});
var PagePrevious = PageControl.extend({
  options: {
    region: 'edge.left',
    direction: 'previous',
    label: 'Previous ${unit}',
    html: '<i class="icon-chevron-left oi" data-glyph="chevron-left" title="Previous ${unit}" aria-hidden="true"></i>'
  },
  _action: function _action(e) {
    this._reader.prev();
  }
});
var PageNext = PageControl.extend({
  options: {
    region: 'edge.right',
    direction: 'next',
    label: 'Next ${unit}',
    html: '<i class="icon-chevron-right oi" data-glyph="chevron-right" title="Next ${unit}" aria-hidden="true"></i>'
  },
  _action: function _action(e) {
    this._reader.next();
  }
});
var PageFirst = PageControl.extend({
  options: {
    direction: 'first',
    label: 'First ${unit}'
  },
  _action: function _action(e) {
    this._reader.first();
  }
});
var PageLast = PageControl.extend({
  options: {
    direction: 'last',
    label: 'Last ${unit}'
  },
  _action: function _action(e) {
    this._reader.last();
  }
});
var pageNext = function pageNext(options) {
  return new PageNext(options);
};
var pagePrevious = function pagePrevious(options) {
  return new PagePrevious(options);
};
var pageFirst = function pageFirst(options) {
  return new PageFirst(options);
};
var pageLast = function pageLast(options) {
  return new PageLast(options);
};
// EXTERNAL MODULE: ./node_modules/lodash/assign.js
var lodash_assign = __webpack_require__(8583);
var assign_default = /*#__PURE__*/__webpack_require__.n(lodash_assign);
;// CONCATENATED MODULE: ./src/control/Modal.js






var activeModal;
var dismissModalListener = false; // from https://github.com/ghosh/micromodal/blob/master/src/index.js

var FOCUSABLE_ELEMENTS = ['a[href]', 'area[href]', 'input:not([disabled]):not([type="hidden"])', 'select:not([disabled])', 'textarea:not([disabled])', 'button:not([disabled])', 'iframe', 'object', 'embed', '[contenteditable]', '[tabindex]:not([tabindex^="-"])'];
var ACTIONABLE_ELEMENTS = ['a[href]', 'area[href]', 'input[type="submit"]:not([disabled])', 'button:not([disabled])'];
var Modal = Class/* Class.extend */.w.extend({
  options: {
    // @option region: String = 'topright'
    // The region of the control (one of the reader edges). Possible values are `'left' ad 'right'`
    region: 'left',
    fraction: 0,
    width: null,
    className: {},
    actions: null,
    callbacks: {
      onShow: function onShow() {},
      onClose: function onClose() {}
    },
    handlers: {},
    modalContainer: null
  },
  initialize: function initialize(options) {
    options = Util.setOptions(this, options);
    this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
    this._initializedEvents = false;
    this.callbacks = assign_default()({}, this.options.callbacks);
    this.actions = this.options.actions ? assign_default()({}, this.options.actions) : null;
    this.handlers = assign_default()({}, this.options.handlers);

    if (typeof this.options.className == 'string') {
      this.options.className = {
        container: this.options.className
      };
    }

    console.log("-- modal: initialize", this.options);
  },
  addTo: function addTo(reader) {
    var self = this;
    this._reader = reader;
    var template = this.options.template;
    var panelHTML = "<div class=\"cozy-modal modal-slide ".concat(this.options.region || 'left', "\" id=\"modal-").concat(this._id, "\" aria-labelledby=\"modal-").concat(this._id, "-title\" role=\"dialog\" aria-describedby=\"modal-").concat(this._id, "-content\" aria-hidden=\"true\">\n      <div class=\"modal__overlay\" tabindex=\"-1\" data-modal-close>\n        <div class=\"modal__container ").concat(this.options.className.container ? this.options.className.container : '', "\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"modal-").concat(this._id, "-title\" aria-describedby=\"modal-").concat(this._id, "-content\" id=\"modal-").concat(this._id, "-container\">\n          <div role=\"document\">\n            <header class=\"modal__header\">\n              <h3 class=\"modal__title\" id=\"modal-").concat(this._id, "-title\">").concat(this.options.title, "</h3>\n              <button class=\"modal__close\" aria-label=\"Close modal\" aria-controls=\"modal-").concat(this._id, "-container\" data-modal-close></button>\n            </header>\n            <main class=\"modal__content ").concat(this.options.className.main ? this.options.className.main : '', "\" id=\"modal-").concat(this._id, "-content\">\n              ").concat(template, "\n            </main>");

    if (this.options.actions) {
      panelHTML += '<footer class="modal__footer">';

      for (var i in this.options.actions) {
        var action = this.options.actions[i];
        var button_cls = action.className || 'button--default';
        panelHTML += "<button id=\"action-".concat(this._id, "-").concat(i, "\" class=\"button button--inline ").concat(button_cls, "\">").concat(action.label, "</button>");
      }

      panelHTML += '</footer>';
    }

    panelHTML += '</div></div></div></div>';
    var body = new DOMParser().parseFromString(panelHTML, "text/html").body;
    var container = reader.options.modalContainer ? reader.options.modalContainer : self.options.modalContainer ? self.options.modalContainer : reader._container;
    this.modal = container.appendChild(body.children[0]);
    this._container = this.modal; // compatibility

    this.container = this.modal.querySelector('.modal__container');

    this._bindEvents();

    return this;
  },
  _bindEvents: function _bindEvents() {
    var _this = this;

    var self = this;
    this.onClick = this.onClick.bind(this);
    this.onKeydown = this.onKeydown.bind(this);
    this.onModalTransition = this.onModalTransition.bind(this);
    this.modal.addEventListener('transitionend', function () {}.bind(this)); // bind any actions

    if (this.actions) {
      var _loop = function _loop() {
        var action = _this.actions[i];
        var button_id = '#action-' + _this._id + '-' + i;

        var button = _this.modal.querySelector(button_id);

        if (button) {
          DomEvent.on(button, 'click', function (event) {
            event.preventDefault();
            action.callback(event);

            if (action.close) {
              self.closeModal();
            }
          });
        }
      };

      for (var i in this.actions) {
        _loop();
      }
    }
  },
  deactivate: function deactivate() {
    this.closeModal();
  },
  closeModal: function closeModal() {
    var self = this;
    this.modal.setAttribute('aria-hidden', 'true');
    this.removeEventListeners();

    if (this.activeElement) {
      this.activeElement.focus();
    }

    this.callbacks.onClose(this.modal);
    this._reader._container.dataset.modalActivated = false;

    if (this.options.modalContainer) {
      this.options.modalContainer.dataset.modalActived = false;
    }

    window.dispatchEvent(new Event('resize'));
  },
  showModal: function showModal() {
    this.activeElement = document.activeElement;

    this._resize();

    this._reader._container.dataset.modalActivated = true;

    if (this.options.modalContainer) {
      this.options.modalContainer.dataset.modalActived = true;
    }

    this.modal.setAttribute('aria-hidden', 'false');
    this.setFocusToFirstNode();
    this.addEventListeners();
    this.callbacks.onShow(this.modal);
    window.dispatchEvent(new Event('resize'));
  },
  activate: function activate() {
    return this.showModal();
    var self = this;
    activeModal = this;
    DomUtil.addClass(self._reader._container, 'st-modal-activating');

    this._resize();

    DomUtil.addClass(this._reader._container, 'st-modal-open');
    setTimeout(function () {
      DomUtil.addClass(self._container, 'active');
      DomUtil.removeClass(self._reader._container, 'st-modal-activating');

      self._container.setAttribute('aria-hidden', 'false');

      self.setFocusToFirstNode();
    }, 25);
  },
  addEventListeners: function addEventListeners() {
    // --- do we need touch listeners?
    // this.modal.addEventListener('touchstart', this.onClick)
    // this.modal.addEventListener('touchend', this.onClick)
    this.modal.addEventListener('click', this.onClick);
    document.addEventListener('keydown', this.onKeydown);
    'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend'.split(' ').forEach(function (event) {
      this.modal.addEventListener(event, this.onModalTransition);
    }.bind(this));
  },
  removeEventListeners: function removeEventListeners() {
    this.modal.removeEventListener('touchstart', this.onClick);
    this.modal.removeEventListener('click', this.onClick);
    'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend'.split(' ').forEach(function (event) {
      this.modal.removeEventListener(event, this.onModalTransition);
    }.bind(this));
    document.removeEventListener('keydown', this.onKeydown);
  },
  _resize: function _resize() {
    var container = this._reader._container;
    this.container.style.height = container.offsetHeight + 'px'; // console.log("AHOY MODAL", this.container.style.height);

    if (!this.options.className.container) {
      this.container.style.width = this.options.width || parseInt(container.offsetWidth * this.options.fraction) + 'px';
    }

    var header = this.container.querySelector('header');
    var footer = this.container.querySelector('footer');
    var main = this.container.querySelector('main');
    var height = this.container.clientHeight - header.clientHeight;

    if (footer) {
      height -= footer.clientHeight;
    }

    main.style.height = height + 'px';
  },
  getFocusableNodes: function getFocusableNodes() {
    var nodes = this.modal.querySelectorAll(FOCUSABLE_ELEMENTS);
    return Object.keys(nodes).map(function (key) {
      return nodes[key];
    });
  },
  setFocusToFirstNode: function setFocusToFirstNode() {
    var focusableNodes = this.getFocusableNodes();

    if (focusableNodes.length) {
      focusableNodes[0].focus();
    } else {
      activeModal._container.focus();
    }
  },
  getActionableNodes: function getActionableNodes() {
    var nodes = this.modal.querySelectorAll(ACTIONABLE_ELEMENTS);
    return Object.keys(nodes).map(function (key) {
      return nodes[key];
    });
  },
  onKeydown: function onKeydown(event) {
    if (event.keyCode == 27) {
      this.closeModal();
    }

    if (event.keyCode == 9) {
      this.maintainFocus(event);
    }
  },
  onClick: function onClick(event) {
    var closeAfterAction = false;
    var target = event.target; // As far as I can tell, the code below isn't catching direct clicks on
    // items with class='data-modal-close' as they're not ACTIONABLE_ELEMENTS.
    // Adding them to ACTIONABLE_ELEMENTS causes undesirable behavior where
    // their child items also close the modal thanks to the loop below.
    // Children of .modal__overlay include the modal header, border area and
    // padding. We don't want clicks on these closing the modal.
    // Just close the modal now for direct clicks on a '.data-modal-close'.

    if (target.hasAttribute('data-modal-close')) {
      this.fire('closed');
      this.closeModal();
      return;
    } // if the target isn't an actionable type, walk the DOM until
    // one is found


    var actionableNodes = this.getActionableNodes();

    while (actionableNodes.indexOf(target) < 0 && target != this.modal) {
      target = target.parentElement;
    } // no target found, punt


    if (actionableNodes.indexOf(target) < 0) {
      return;
    }

    if (this.handlers.click) {
      var did_match = false;

      for (var selector in this.handlers.click) {
        if (target.matches(selector)) {
          closeAfterAction = this.handlers.click[selector](this, target);
          break;
        }
      }
    }

    if (closeAfterAction || target.hasAttribute('data-modal-close')) this.closeModal(); //if (target.hasAttribute('data-modal-close')) this.closeModal();

    event.preventDefault();
  },
  onModalTransition: function onModalTransition(event) {
    if (this.modal.getAttribute('aria-hidden') == 'true') {
      this._reader.fire('modal-closed');
    } else {
      this._reader.fire('modal-opened');
    }
  },
  on: function on(event, selector, handler) {
    if (!this.handlers[event]) {
      this.handlers[event] = {};
    }

    if (typeof selector == 'function') {
      handler = selector;
      selector = '*';
    }

    this.handlers[event][selector] = handler;
  },
  fire: function fire(event) {
    if (this.handlers[event] && this.handlers[event]['*']) {
      this.handlers[event]['*'](this);
    }
  },
  maintainFocus: function maintainFocus(event) {
    var focusableNodes = this.getFocusableNodes();
    var focusedItemIndex = focusableNodes.indexOf(document.activeElement);

    if (event.shiftKey && focusedItemIndex === 0) {
      focusableNodes[focusableNodes.length - 1].focus();
      event.preventDefault();
    }

    if (!event.shiftKey && focusedItemIndex === focusableNodes.length - 1) {
      focusableNodes[0].focus();
      event.preventDefault();
    }
  },
  update: function update(options) {
    if (options.title) {
      this.options.title = options.title;
      var titleEl = this.container.querySelector('.modal__title');
      titleEl.innerText = options.title;
    }

    if (options.fraction) {
      this.options.fraction = options.fraction;
      this.container.style.width = parseInt(this.container.offsetWidth * this.options.fraction) + 'px';
    }
  },
  EOT: true
});
Reader/* Reader.include */.E.include({
  modal: function modal(options) {
    var modal = new Modal(options);
    return modal.addTo(this); // return this;
  },
  popup: function popup(options) {
    options = assign_default()({
      title: 'Info',
      fraction: 1.0
    }, options);

    if (!this._popupModal) {
      this._popupModal = this.modal({
        title: options.title,
        region: 'full',
        template: '<div style="height: 100%; width: 100%"></div>',
        fraction: options.fraction || 1.0,
        actions: [{
          label: 'Close',
          callback: function callback(event) {},
          close: true
        }]
      });
    } else {
      this._popupModal.update({
        title: options.title,
        fraction: options.fraction
      });
    }

    var iframe;

    var modalDiv = this._popupModal.container.querySelector('main > div');

    var iframe = modalDiv.querySelector('iframe');

    if (iframe) {
      modalDiv.removeChild(iframe);
    }

    iframe = document.createElement('iframe');
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.setAttribute('title', options.title);
    iframe = modalDiv.appendChild(iframe);

    if (options.onLoad) {
      iframe.addEventListener('load', function () {
        options.onLoad(iframe.contentDocument, this._popupModal);
      }.bind(this));
    }

    if (options.srcdoc) {
      if ("srcdoc" in iframe) {
        iframe.srcdoc = options.srcdoc;
      } else {
        iframe.contentDocument.open();
        iframe.contentDocument.write(options.srcdoc);
        iframe.contentDocument.close();
      }
    } else if (options.href) {
      iframe.setAttribute('src', options.href);
    }

    this._popupModal.activate();
  },
  EOT: true
});
;// CONCATENATED MODULE: ./src/control/Control.Contents.js





var Contents = Control.extend({
  defaultTemplate: "<button class=\"button--sm\" data-toggle=\"open\" aria-label=\"Table of Contents\"><i class=\"icon-align-left oi\" data-glyph=\"align-left\" title=\"Table of Contents\" aria-hidden=\"true\"></i></button>",
  onAdd: function onAdd(reader) {
    var self = this;
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._control = container.closest("[data-toggle=open]") || container.querySelector('[data-toggle="open"]');

    this._control.setAttribute('id', 'action-' + this._id);

    this._control.setAttribute("data-modal-open", "");

    container.style.position = 'relative';

    this._bindEvents();

    return container;
  },
  _bindEvents: function _bindEvents() {
    var _this2 = this;

    var self = this;

    this._reader.on('updateContents', function (data) {
      var _this = this;

      DomEvent.on(this._control, 'click', function (event) {
        event.preventDefault(); // HELIO-4287 "action" modal-opening buttons should both open *and* close their associated modal, and close others when opening.
        // use ariaHidden to check open/close status of this modal. Seems weird but I think it's used this way elsewhere also.

        if (self._modal.modal.ariaHidden == 'false') {
          // if it's visible, close it and return
          this._modal.deactivate();

          return;
        } else {
          // we're going to open this modal. Look for any currently-open modals to close first.
          var open_modals_close_buttons = self._modal.container.ownerDocument.querySelectorAll('.cozy-modal[aria-hidden="false"] button[data-modal-close]');

          console.log(open_modals_close_buttons);
          open_modals_close_buttons.forEach(function (button) {
            button.click();
          });
        }

        self._goto_interval = false;

        self._reader.tracking.action('contents/open');

        self._modal.activate();
      }, this);
      console.log("-- control.contents modal", self.options);
      this._modal = this._reader.modal({
        template: "\n<div class=\"cozy-contents-toolbar button-group\" aria-hidden=\"true\">\n  <button class=\"cozy-control button toggled\" data-toggle=\"contentlist\">Table of Contents</button>\n  <button class=\"cozy-control button\" data-toggle=\"pagelist\">Page List</button>\n</div>\n<div class=\"cozy-contents-main\">\n  <div class=\"cozy-contents-contentlist\">\n    <ul></ul>\n  </div>\n  <div class=\"cozy-contents-pagelist\" style=\"display: none\">\n    <form>\n      <label for=\"cozy-contents-pagelist-pagenum\">Page Number</label>\n      <input type=\"text\" size=\"5\" id=\"cozy-contents-pagelist-pagenum\" />\n      <button class=\"button--sm\">Go</button>\n      <p class=\"pagelist-error oi\" data-glyph=\"target\" role=\"alert\"></p>\n    </form>\n    <ul></ul>\n  </div>\n</div>".trim(),
        title: 'Contents',
        region: 'left',
        className: 'cozy-modal-contents',
        callbacks: {
          onShow: function onShow() {},
          onClose: function onClose(modal) {
            if (self._goto_interval) {
              self._reader.rendition.manager.container.setAttribute("tabindex", 0);

              self._reader.rendition.manager.container.focus();
            }
          }
        },
        modalContainer: self.options.modalContainer,
        seriously: 'wtf'
      });
      this._display = {};
      this._display.contentlist = this._modal._container.querySelector('.cozy-contents-contentlist');
      this._display.pagelist = this._modal._container.querySelector('.cozy-contents-pagelist');
      this._toolbar = this._modal._container.querySelector('.cozy-contents-toolbar');
      this._pageListError = this._modal.container.querySelector('.pagelist-error');

      this._toolbar.addEventListener('click', function (event) {
        if (event.target.dataset.toggle) {
          var target = event.target.dataset.toggle;

          var current = _this._toolbar.querySelector('[data-toggle].toggled');

          if (current) {
            current.classList.remove('toggled');
            _this._display[current.dataset.toggle].style.display = 'none';
          }

          event.target.classList.add('toggled');
          _this._display[event.target.dataset.toggle].style.display = 'block';

          _this._reader.updateLiveStatus("Displaying ".concat(event.target.innerText));
        }
      });

      this._modal.on('click', '.cozy-contents-pagelist form button', function (modal, target) {
        var form = target.parentNode;
        var input = form.querySelector('input[type="text"]');
        var value = input.value.trim();

        if (value) {
          var pageList = this._reader.pageList;
          var page = pageList.pageList.find(function (p) {
            return p.pageLabel == value;
          }) || false;

          if (page) {
            target = pageList.cfiFromPage(page.page);
            this._goto_interval = true;

            this._reader.tracking.action('contents/go/link');

            this._reader.display(target);

            return true;
          } else {
            var p = this._pageListError; // form.querySelector('.pagelist-error');

            var p1 = pageList.firstPageLabel;
            var p2 = pageList.lastPageLabel;
            p.innerHTML = "Please enter a page number between <strong>".concat(p1, "-").concat(p2, "</strong>.");
          }
        }
      }.bind(this));

      this._modal.on('click', 'a[href]', function (modal, target) {
        target = target.getAttribute('data-href');
        this._goto_interval = true; //this._reader.tracking.action('contents/go/link');

        this._reader.display(target);

        if (this.options.closePanel === false) {
          return false;
        }

        return true;
      }.bind(this));

      this._modal.on('closed', function () {
        self._pageListError.innerHTML = '';

        self._reader.tracking.action('contents/close');
      });

      this._setupSkipLink();

      var parent = self._modal._container.querySelector('.cozy-contents-contentlist ul');

      var _process = function _process(items, tabindex, parent) {
        items.forEach(function (item) {
          var option = self._createOption(item, tabindex, parent);

          if (item.subitems && item.subitems.length) {
            _process(item.subitems, tabindex + 1, option);
          }
        });
      };

      _process(data.toc, 0, parent);
    }.bind(this));

    this._reader.on('updateLocations', function (data) {
      if (_this2._reader.pageList) {
        // this._toolbar.style.display = 'flex';
        _this2._toolbar.setAttribute('aria-hidden', 'false');
      }

      if (self._reader.pageList) {
        var parent = self._modal._container.querySelector('.cozy-contents-pagelist ul');

        for (var i = 0; i < self._reader.pageList.pages.length; i++) {
          var pg = self._reader.pageList.pages[i];
          var info = self._reader.pageList.pageList[i];
          var cfi = self._reader.pageList.locations[i];
          var item = {
            label: info.pageLabel || info.page,
            href: cfi
          };

          var option = self._createOption(item, 0, parent);
        }
      }
    });
  },
  _createOption: function _createOption(chapter, tabindex, parent) {
    function pad(value, length) {
      return value.toString().length < length ? pad("-" + value, length) : value;
    }

    var option = DomUtil.create('li');

    if (chapter.href) {
      var anchor = DomUtil.create('a', null, option);

      if (chapter.html) {
        anchor.innerHTML = chapter.html;
      } else {
        anchor.textContent = chapter.label;
      } // var tab = pad('', tabindex); tab = tab.length ? tab + ' ' : '';
      // option.textContent = tab + chapter.label;


      anchor.setAttribute('href', chapter.href);
      anchor.setAttribute('data-href', chapter.href);
    } else {
      var span = DomUtil.create('span', null, option);
      span.textContent = chapter.label;
    }

    if (parent.tagName === 'LI') {
      // need to nest
      var tmp = parent.querySelector('ul');

      if (!tmp) {
        tmp = DomUtil.create('ul', null, parent);
      }

      parent = tmp;
    }

    parent.appendChild(option);
    return option;
  },
  _setupSkipLink: function _setupSkipLink() {
    if (!this.options.skipLink) {
      return;
    }

    var target = document.querySelector(this.options.skipLink);

    if (!target) {
      return;
    }

    var link = document.createElement('a');
    link.textContent = 'Skip to contents';
    link.setAttribute('href', '#action-' + this._id);
    var ul = target.querySelector('ul');

    if (ul) {
      // add to list
      target = document.createElement('li');
      ul.appendChild(target);
    }

    target.appendChild(link);
    link.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();

      this._control.click();
    }.bind(this));
  },
  EOT: true
});
var contents = function contents(options) {
  console.log("-- control.contents", options);
  return new Contents(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Title.js



 // Title + Chapter

var Title = Control.extend({
  onAdd: function onAdd(reader) {
    var self = this;

    var className = this._className(),
        container = DomUtil.create('div', className),
        options = this.options; // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;


    var h1 = DomUtil.create('h1', 'cozy-h1', container);
    DomUtil.setOpacity(h1, 0);
    this._title = DomUtil.create('span', 'cozy-title', h1);
    this._divider = DomUtil.create('span', 'cozy-divider', h1);
    this._divider.textContent = " · ";
    this._section = DomUtil.create('span', 'cozy-section', h1); // --- TODO: disable until we can work out how to 
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

    this._reader.on('updateTitle', function (data) {
      if (data) {
        self._title.textContent = data.title || data.bookTitle;
        DomUtil.setOpacity(self._section, 0);
        DomUtil.setOpacity(self._divider, 0);
        DomUtil.setOpacity(h1, 1);
      }
    });

    return container;
  },
  _createButton: function _createButton(html, title, className, container, fn) {
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
    DomEvent.on(link, 'click', fn, this); // DomEvent.on(link, 'click', this._refocusOnMap, this);

    return link;
  },
  EOT: true
});
var title = function title(options) {
  return new Title(options);
};
;// CONCATENATED MODULE: ./src/control/Control.PublicationMetadata.js



 // Title + Chapter

var PublicationMetadata = Control.extend({
  onAdd: function onAdd(reader) {
    var self = this;

    var className = this._className(),
        container = DomUtil.create('div', className),
        options = this.options; // var template = '<h1><span class="cozy-title">Contents: </span><select size="1" name="contents"></select></label>';
    // var control = new DOMParser().parseFromString(template, "text/html").body.firstChild;


    this._publisher = DomUtil.create('div', 'cozy-publisher', container);
    this._rights = DomUtil.create('div', 'cozy-rights', container);

    this._reader.on('updateTitle', function (data) {
      if (data) {
        self._publisher.textContent = data.publisher;
        self._rights.textContent = data.rights;
      }
    });

    return container;
  },
  _createButton: function _createButton(html, title, className, container, fn) {
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
    DomEvent.on(link, 'click', fn, this); // DomEvent.on(link, 'click', this._refocusOnMap, this);

    return link;
  },
  EOT: true
});
var publicationMetadata = function publicationMetadata(options) {
  return new PublicationMetadata(options);
};
// EXTERNAL MODULE: ./node_modules/lodash/keys.js
var keys = __webpack_require__(3674);
;// CONCATENATED MODULE: ./src/control/Control.Preferences.js








var Preferences = Control.extend({
  options: {
    label: 'Preferences',
    hasThemes: false
  },
  defaultTemplate: "<button class=\"button--sm cozy-preferences\" data-toggle=\"open\" aria-label=\"Text display preferences and settings\">Aa</button>",
  onAdd: function onAdd(reader) {
    var self = this;

    var className = this._className();

    var container = DomUtil.create('div', className);
    var template = this.options.template || this.defaultTemplate;
    var body = new DOMParser().parseFromString(template, "text/html").body;

    while (body.children.length) {
      container.appendChild(body.children[0]);
    }

    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault();
      self.activate();
    }, this); // self.initializeForm();

    this._modal = this._reader.modal({
      // template: '<form></form>',
      title: 'Preferences',
      className: 'cozy-modal-preferences',
      actions: [{
        label: 'Save Changes',
        callback: function callback(event) {
          self.updatePreferences(event);
        }
      }],
      region: 'right'
    });
    return container;
  },
  activate: function activate() {
    var self = this;
    self.initializeForm();

    self._modal.activate();
  },
  _createPanel: function _createPanel() {
    var self = this;

    if (this._modal._container.querySelector('form')) {
      return;
    }

    var template = '';
    var possible_fieldsets = [];

    if (this._reader.metadata.layout == 'pre-paginated') {
      // different panel
      possible_fieldsets.push('Scale');
    } else {
      possible_fieldsets.push('TextSize');
    }

    possible_fieldsets.push('Display');

    if (this._reader.rootfiles && this._reader.rootfiles.length > 1) {
      // this.options.hasPackagePaths = true;
      possible_fieldsets.push('Rendition');
    }

    if (this._reader.options.themes && this._reader.options.themes.length > 0) {
      this.options.hasThemes = true;
      possible_fieldsets.push('Theme');
    }

    this._fieldsets = [];
    possible_fieldsets.forEach(function (cls) {
      var fieldset = new Preferences.fieldset[cls](this);
      template += fieldset.template();

      this._fieldsets.push(fieldset);
    }.bind(this));

    if (this.options.fields) {
      this.options.hasFields = true;

      for (var i in this.options.fields) {
        var field = this.options.fields[i];
        var id = "preferences-custom-" + i;
        template += "<fieldset class=\"custom-field\">\n          <legend>".concat(field.label, "</legend>\n        ");

        for (var j in field.inputs) {
          var input = field.inputs[j];
          var checked = input.value == field.value ? ' checked="checked"' : '';
          template += "<label><input id=\"preferences-custom-".concat(i, "-").concat(j, "\" type=\"radio\" name=\"x").concat(field.name, "\" value=\"").concat(input.value, "\" ").concat(checked, "/>").concat(input.label, "</label>");
        }

        if (field.hint) {
          template += "<p class=\"hint\" style=\"font-size: 90%\">".concat(field.hint, "</p>");
        }
      }
    }

    template = '<form>' + template + '</form>'; // this._modal = this._reader.modal({
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
  initializeForm: function initializeForm() {
    this._createPanel();

    this._fieldsets.forEach(function (fieldset) {
      fieldset.initializeForm(this._form);
    }.bind(this));
  },
  updatePreferences: function updatePreferences(event) {
    event.preventDefault();
    var doUpdate = false;
    var new_options = {};
    var saveable_options = {};

    this._fieldsets.forEach(function (fieldset) {
      // doUpdate = doUpdate || fieldset.updateForm(this._form, new_options);
      // assign(new_options, fieldset.updateForm(this._form));
      fieldset.updateForm(this._form, new_options, saveable_options);
    }.bind(this));

    if (this.options.hasFields) {
      for (var i in this.options.fields) {
        var field = this.options.fields[i];
        var id = "preferences-custom-" + i;

        var input = this._form.querySelector("input[name=\"x".concat(field.name, "\"]:checked"));

        if (input.value != field.value) {
          field.value = input.value;
          field.callback(field.value);
        }
      }
    }

    this._modal.deactivate();

    setTimeout(function () {
      this._reader.saveOptions(saveable_options);

      this._reader.reopen(new_options);
    }.bind(this), 100);
  },
  EOT: true
});
Preferences.fieldset = {};
var Fieldset = Class/* Class.extend */.w.extend({
  options: {},
  initialize: function initialize(control, options) {
    Util.setOptions(this, options);
    this._control = control;
    this._current = {};
    this._id = new Date().getTime() + '-' + parseInt(Math.random(new Date().getTime()) * 1000, 10);
  },
  template: function template() {},
  EOT: true
});
Preferences.fieldset.TextSize = Fieldset.extend({
  initializeForm: function initializeForm(form) {
    if (!this._input) {
      this._input = form.querySelector("#x".concat(this._id, "-input"));
      this._output = form.querySelector("#x".concat(this._id, "-output"));
      this._preview = form.querySelector("#x".concat(this._id, "-preview"));
      this._actionReset = form.querySelector("#x".concat(this._id, "-reset"));

      this._input.addEventListener('input', this._updatePreview.bind(this));

      this._input.addEventListener('change', this._updatePreview.bind(this));

      this._actionReset.addEventListener('click', function (event) {
        event.preventDefault();
        this._input.value = 100;

        this._updatePreview();
      }.bind(this));
    }

    var text_size = this._control._reader.options.text_size || 100;

    if (text_size == 'auto') {
      text_size = 100;
    }

    this._current.text_size = text_size;
    this._input.value = text_size;

    this._updatePreview();
  },
  updateForm: function updateForm(form, options, saveable) {
    // return { text_size: this._input.value };
    options.text_size = saveable.text_size = this._input.value; // options.text_size = this._input.value;
    // return ( this._input.value != this._current.text_size );
  },
  template: function template() {
    return "<fieldset class=\"cozy-fieldset-text_size\">\n        <legend>Text Size</legend>\n        <div class=\"preview--text_size\" id=\"x".concat(this._id, "-preview\">\n          \u2018Yes, that\u2019s it,\u2019 said the Hatter with a sigh: \u2018it\u2019s always tea-time, and we\u2019ve no time to wash the things between whiles.\u2019\n        </div>\n        <p style=\"white-space: no-wrap\">\n          <span>T-</span>\n          <input name=\"text_size\" type=\"range\" id=\"x").concat(this._id, "-input\" value=\"100\" min=\"50\" max=\"400\" step=\"10\" aria-valuemin=\"50\" aria-valuemax=\"400\" style=\"width: 75%; display: inline-block\" />\n          <span>T+</span>\n        </p>\n        <p>\n          <span>Text Size: </span>\n          <span id=\"x").concat(this._id, "-output\">100</span>\n          <button id=\"x").concat(this._id, "-reset\" class=\"reset button--lg\" style=\"margin-left: 8px\">Reset to 100%</button> \n        </p>\n      </fieldset>");
  },
  _updatePreview: function _updatePreview() {
    this._preview.style.fontSize = "".concat(parseInt(this._input.value, 10) / 100, "em");
    this._output.innerHTML = "".concat(this._input.value, "%");

    this._input.setAttribute('aria-valuenow', "".concat(this._input.value));

    this._input.setAttribute('aria-valuetext', "".concat(this._input.value, " percent"));
  },
  EOT: true
});
Preferences.fieldset.Display = Fieldset.extend({
  initializeForm: function initializeForm(form) {
    var flow = this._control._reader.options.flow || this._control._reader.metadata.flow || 'auto'; // if ( flow == 'auto' ) { flow = 'paginated'; }

    var input = form.querySelector("#x".concat(this._id, "-input-").concat(flow));
    input.checked = true;
    this._current.flow = flow;
  },
  updateForm: function updateForm(form, options, saveable) {
    var input = form.querySelector("input[name=\"x".concat(this._id, "-flow\"]:checked"));
    options.flow = input.value;

    if (options.flow != 'auto') {
      saveable.flow = options.flow;
    } // if ( input.value == 'auto' ) {
    //   // we do NOT want to save flow as a preference
    //   return {};
    // }
    // return { flow: input.value };

  },
  template: function template() {
    var scrolled_help = '';

    if (this._control._reader.metadata.layout != 'pre-paginated') {
      scrolled_help = "<br /><small>This is an experimental feature that may cause display and loading issues for the book when enabled.</small>";
    }

    return "<fieldset>\n            <legend>Display</legend>\n            <label><input name=\"x".concat(this._id, "-flow\" type=\"radio\" id=\"x").concat(this._id, "-input-auto\" value=\"auto\" /> Auto<br /><small>Let the reader determine display mode based on your browser dimensions and the type of content you're reading</small></label>\n            <label><input name=\"x").concat(this._id, "-flow\" type=\"radio\" id=\"x").concat(this._id, "-input-paginated\" value=\"paginated\" /> Page-by-Page</label>\n            <label><input name=\"x").concat(this._id, "-flow\" type=\"radio\" id=\"x").concat(this._id, "-input-scrolled-doc\" value=\"scrolled-doc\" /> Scroll").concat(scrolled_help, "</label>\n          </fieldset>");
  },
  EOT: true
});
Preferences.fieldset.Theme = Fieldset.extend({
  initializeForm: function initializeForm(form) {
    var theme = this._control._reader.options.theme || 'default';
    var input = form.querySelector("#x".concat(this._id, "-input-theme-").concat(theme));
    input.checked = true;
    this._current.theme = theme;
  },
  updateForm: function updateForm(form, options, saveable) {
    var input = form.querySelector("input[name=\"x".concat(this._id, "-theme\"]:checked"));
    options.theme = saveable.theme = input.value; // return { theme: input.value };
  },
  template: function template() {
    var template = "<fieldset>\n            <legend>Theme</legend>\n            <label><input name=\"x".concat(this._id, "-theme\" type=\"radio\" id=\"x").concat(this._id, "-input-theme-default\" value=\"default\" />Default</label>");

    this._control._reader.options.themes.forEach(function (theme) {
      template += "<label><input name=\"x".concat(this._id, "-theme\" type=\"radio\" id=\"x").concat(this._id, "-input-theme-").concat(theme.klass, "\" value=\"").concat(theme.klass, "\" />").concat(theme.name, "</label>");
    }.bind(this));

    template += '</fieldset>';
    return template;
  },
  EOT: true
});
Preferences.fieldset.Rendition = Fieldset.extend({
  initializeForm: function initializeForm(form) {
    var rootfiles = this._control._reader.rootfiles;
    var rootfilePath = this._control._reader.options.rootfilePath;
    var expr = rootfilePath ? "[value=\"".concat(rootfilePath, "\"]") : ":first-child";
    var input = form.querySelector("input[name=\"x".concat(this._id, "-rootfilePath\"]").concat(expr));
    input.checked = true;
    this._current.rootfilePath = rootfilePath || rootfiles[0].rootfilePath;
  },
  updateForm: function updateForm(form, options, saveable) {
    var input = form.querySelector("input[name=\"x".concat(this._id, "-rootfilePath\"]:checked"));

    if (input.value != this._current.rootfilePath) {
      options.rootfilePath = input.value;
      this._current.rootfilePath = input.value;
    }
  },
  template: function template() {
    var template = "<fieldset>\n            <legend>Rendition</legend>\n    ";

    this._control._reader.rootfiles.forEach(function (rootfile, i) {
      template += "<label><input name=\"x".concat(this._id, "-rootfilePath\" type=\"radio\" id=\"x").concat(this._id, "-input-rootfilePath-").concat(i, "\" value=\"").concat(rootfile.rootfilePath, "\" />").concat(rootfile.label || rootfile.accessMode || rootfile.rootfilePath, "</label>");
    }.bind(this));

    template += '</fieldset>';
    return template;
  },
  EOT: true
});
Preferences.fieldset.Scale = Fieldset.extend({
  initializeForm: function initializeForm(form) {
    if (!this._input) {
      this._input = form.querySelector("#x".concat(this._id, "-input"));
      this._output = form.querySelector("#x".concat(this._id, "-output"));
      this._preview = form.querySelector("#x".concat(this._id, "-preview > div"));
      this._actionReset = form.querySelector("#x".concat(this._id, "-reset"));

      this._input.addEventListener('input', this._updatePreview.bind(this));

      this._input.addEventListener('change', this._updatePreview.bind(this));

      this._actionReset.addEventListener('click', function (event) {
        event.preventDefault();
        this._input.value = 100;

        this._updatePreview();
      }.bind(this));
    }

    var scale = this._control._reader.options.scale || 100;

    if (!scale) {
      scale = 100;
    }

    this._current.scale = scale;
    this._input.value = scale;

    this._updatePreview();
  },
  updateForm: function updateForm(form, options, saveable) {
    // return { text_size: this._input.value };
    options.scale = saveable.scale = this._input.value; // options.text_size = this._input.value;
    // return ( this._input.value != this._current.text_size );
  },
  template: function template() {
    return "<fieldset class=\"cozy-fieldset-text_size\">\n        <legend>Zoom In/Out</legend>\n        <div class=\"preview--scale\" id=\"x".concat(this._id, "-preview\" style=\"overflow: hidden; height: 5rem\">\n          <div>\n            \u2018Yes, that\u2019s it,\u2019 said the Hatter with a sigh: \u2018it\u2019s always tea-time, and we\u2019ve no time to wash the things between whiles.\u2019\n          </div>\n        </div>\n        <p style=\"white-space: no-wrap\">\n          <span style=\"font-size: 150%\">\u2296<span class=\"u-screenreader\"> Zoom Out</span></span>\n          <input name=\"scale\" type=\"range\" id=\"x").concat(this._id, "-input\" value=\"100\" min=\"50\" max=\"400\" step=\"10\" style=\"width: 75%; display: inline-block\" />\n          <span style=\"font-size: 150%\">\u2295<span class=\"u-screenreader\">Zoom In </span></span>\n        </p>\n        <p>\n          <span>Scale: </span>\n          <span id=\"x").concat(this._id, "-output\">100</span>\n          <button id=\"x").concat(this._id, "-reset\" class=\"reset button--inline\" style=\"margin-left: 8px\">Reset</button> \n        </p>\n      </fieldset>");
  },
  _updatePreview: function _updatePreview() {
    this._preview.style.transform = "scale(".concat(parseInt(this._input.value, 10) / 100, ") translate(0,0)");
    this._output.innerHTML = "".concat(this._input.value, "%");
  },
  EOT: true
});
var preferences = function preferences(options) {
  return new Preferences(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Widget.js




var Widget = Control.extend({
  options: {// @option region: String = 'topright'
    // The region of the control (one of the reader corners). Possible values are `'topleft'`,
    // `'topright'`, `'bottomleft'` or `'bottomright'`
  },
  onAdd: function onAdd(reader) {
    var container = this._container;

    if (container) {// NOOP
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._onAddExtra(container);

    this._updateTemplate(container);

    this._updateClass(container);

    this._bindEvents(container);

    return container;
  },
  _updateTemplate: function _updateTemplate(container) {
    var data = this.data();

    for (var slot in data) {
      if (data.hasOwnProperty(slot)) {
        var value = data[slot];

        if (typeof value == "function") {
          value = value();
        }

        var node = container.querySelector("[data-slot=".concat(slot, "]"));

        if (node) {
          if (node.hasAttribute('value')) {
            node.setAttribute('value', value);
          } else {
            node.innerHTML = value;
          }
        }
      }
    }
  },
  _updateClass: function _updateClass(container) {
    if (this.options.className) {
      DomUtil.addClass(container, this.options.className);
    }
  },
  _onAddExtra: function _onAddExtra() {},
  _bindEvents: function _bindEvents(container) {
    var control = container.querySelector("[data-toggle=button]");

    if (!control) {
      return;
    }

    DomEvent.disableClickPropagation(control);
    DomEvent.on(control, 'click', DomEvent.stop);
    DomEvent.on(control, 'click', this._action, this);
  },
  _action: function _action() {},
  data: function data() {
    return this.options.data || {};
  },
  EOT: true
});
Widget.Button = Widget.extend({
  defaultTemplate: "<button data-toggle=\"button\" data-slot=\"label\"></button>",
  _action: function _action() {
    this.options.onClick(this, this._reader);
  },
  EOT: true
});
Widget.Panel = Widget.extend({
  defaultTemplate: "<div><span data-slot=\"text\"></span></div>",
  EOT: true
});
Widget.Toggle = Widget.extend({
  defaultTemplate: "<button data-toggle=\"button\" data-slot=\"label\"></button>",
  _onAddExtra: function _onAddExtra(container) {
    this.state(this.options.states[0].stateName, container);
    return container;
  },
  state: function state(stateName, container) {
    container = container || this._container;

    this._resetState(container);

    this._state = this.options.states.filter(function (s) {
      return s.stateName == stateName;
    })[0];

    this._updateClass(container);

    this._updateTemplate(container);
  },
  _resetState: function _resetState(container) {
    if (!this._state) {
      return;
    }

    if (this._state.className) {
      DomUtil.removeClass(container, this._state.className);
    }
  },
  _updateClass: function _updateClass(container) {
    if (this._state.className) {
      DomUtil.addClass(container, this._state.className);
    }
  },
  _action: function _action() {
    this._state.onClick(this, this._reader);
  },
  data: function data() {
    return this._state.data || {};
  },
  EOT: true
}); // export var widget = function(options) {
//   return new Widget(options);
// }

var widget = {
  button: function button(options) {
    return new Widget.Button(options);
  },
  panel: function panel(options) {
    return new Widget.Panel(options);
  },
  toggle: function toggle(options) {
    return new Widget.Toggle(options);
  }
};
;// CONCATENATED MODULE: ./src/control/Control.Citation.js




var Citation = Control.extend({
  options: {
    label: 'Cite',
    html: '<span class="citation" aria-label="Get Citation"></span>'
  },
  defaultTemplate: '<button class="button--sm cozy-citation citation" data-toggle="open" aria-label="Get Citation"></button>',
  onAdd: function onAdd(reader) {
    var self = this;
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._reader.on('updateContents', function (data) {
      self._createPanel();
    });

    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault();

      self._modal.activate();
    }, this);
    return container;
  },
  _action: function _action() {
    var self = this;

    self._modal.activate();
  },
  _createButton: function _createButton(html, title, className, container, fn) {
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
  _createPanel: function _createPanel() {
    var self = this;
    var template = "<form>\n      <fieldset>\n        <legend>Select Citation Format</legend>\n      </fieldset>\n    </form>\n    <blockquote id=\"formatted\" style=\"padding: 8px; border-left: 4px solid black; background-color: #fff\"></blockquote>\n    <div class=\"alert alert-info\" id=\"message\" style=\"display: none\"></div>";
    this._modal = this._reader.modal({
      template: template,
      title: 'Copy Citation to Clipboard',
      className: 'cozy-modal-citation',
      actions: [{
        label: 'Copy Citation',
        close: true,
        callback: function callback(event) {
          document.designMode = "on";

          var formatted = self._modal._container.querySelector("#formatted");

          var range = document.createRange();
          range.selectNode(formatted);
          var sel = window.getSelection();
          sel.removeAllRanges();
          sel.addRange(range); // formatted.select();

          try {
            var flag = document.execCommand('copy');
          } catch (err) {
            console.log("AHOY COPY FAILED", err);
          }

          self._message.innerHTML = 'Success! Citation copied to your clipboard.';
          self._message.style.display = 'block';
          sel.removeAllRanges();
          range.detach();
          document.designMode = "off";
        }
      }],
      region: 'right',
      fraction: 1.0
    });
    this._form = this._modal._container.querySelector('form');

    var fieldset = this._form.querySelector('fieldset');

    var citations = this.options.citations || this._reader.metadata.citations;
    citations.forEach(function (citation, index) {
      var label = DomUtil.create('label', null, fieldset);
      var input = DomUtil.create('input', null, label);
      input.setAttribute('name', 'format');
      input.setAttribute('value', citation.format);
      input.setAttribute('type', 'radio');

      if (index == 0) {
        input.setAttribute('checked', 'checked');
      }

      var text = document.createTextNode(" " + citation.format);
      label.appendChild(text);
      input.setAttribute('data-text', citation.text);
    });
    this._formatted = this._modal._container.querySelector("#formatted");
    this._message = this._modal._container.querySelector("#message");
    DomEvent.on(this._form, 'change', function (event) {
      var target = event.target;

      if (target.tagName == 'INPUT') {
        this._initializeForm();
      }
    }, this);

    this._initializeForm();
  },
  _initializeForm: function _initializeForm() {
    var formatted = this._formatCitation();

    this._formatted.innerHTML = formatted;
    this._message.style.display = 'none';
    this._message.innerHTML = '';
  },
  _formatCitation: function _formatCitation(format) {
    if (format == null) {
      var selected = this._form.querySelector("input:checked");

      format = selected.value;
    }

    var selected = this._form.querySelector("input[value=" + format + "]");

    return selected.getAttribute('data-text'); // return selected.dataset.text;
  },
  EOT: true
});
var citation = function citation(options) {
  return new Citation(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Search.js




var Search = Control.extend({
  options: {
    label: 'Search',
    html: '<span>Search</span>'
  },
  defaultTemplate: "<button class=\"button--sm\" data-toggle=\"open\" aria-label=\"Search\"><i class=\"icon-magnifying-glass oi\" data-glyph=\"magnifying-glass\" title=\"Search\" aria-hidden=\"true\"></i></button>",
  onAdd: function onAdd(reader) {
    var self = this;
    var container = this._container;

    if (container) {//this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._reader.on('updateContents', function (data) {
      self._createPanel();
    });

    this._control = container.closest("[data-toggle=open]") || container.querySelector('[data-toggle="open"]');

    this._control.setAttribute('id', 'action-' + this._id);

    this._control.setAttribute("data-modal-open", "");

    container.style.position = 'relative';
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault(); // HELIO-4287 "action" modal-opening buttons should both open *and* close their associated modal, and close others when opening.
      // use ariaHidden to check open/close status of this modal. Seems weird but I think it's used this way elsewhere also.

      if (self._modal.modal.ariaHidden == 'false') {
        // if it's visible, close it and return
        this._modal.deactivate();

        return;
      } else {
        // we're going to open this modal. Look for any currently-open modals to close first.
        var open_modals_close_buttons = self._modal.container.ownerDocument.querySelectorAll('.cozy-modal[aria-hidden="false"] button[data-modal-close]');

        console.log(open_modals_close_buttons);
        open_modals_close_buttons.forEach(function (button) {
          button.click();
        });
      }

      self._modal.activate();
    }, this);
    return container;
  },
  _createPanel: function _createPanel() {
    var self = this;
    console.log("-- control.contents modal", self.options);
    this._modal = this._reader.modal({
      template: "\n  <div class=\"cozy-search\">\n    <form class=\"search\">\n      <label class=\"u-screenreader\" for=\"cozy-search-string\">Search in this text</label>\n      <input id=\"cozy-search-string\" name=\"search\" type=\"text\" placeholder=\"Search in this text...\" data-hj-allow=\"true\" />\n      <button class=\"button--sm\" data-toggle=\"open\" aria-label=\"Search\" type=\"submit\"><i class=\"icon-magnifying-glass oi\" data-glyph=\"magnifying-glass\" title=\"Search\" aria-hidden=\"true\"></i></button>\n    </form>\n  </div>\n<article></article>",
      title: 'Search',
      className: {
        container: 'cozy-modal-search'
      },
      region: 'left',
      modalContainer: self.options.modalContainer,
      seriously: 'wtf'
    });

    this._modal.callbacks.onClose = function () {
      if (self._processing) {
        self._canceled = true;
      }
    };

    this._article = this._modal._container.querySelector('article');

    this._modal.on('click', '.cozy-search form button', function (modal, target) {
      var form = target.parentNode;
      var searchString = form.querySelector('input[type="text"]').value;
      searchString = searchString.replace(/^\s*/, '').replace(/\s*$/, '');

      if (!searchString) {
        // just punt
        return;
      }

      if (searchString == this.searchString) {
        // cached results
        self.openModalResults();
      } else {
        this.searchString = searchString;
        self.openModalWaiting();
        self.submitQuery(searchString);
      }
    }.bind(this));

    this._modal.on('click', 'a[class="search-result"]', function (modal, target) {
      target = target.getAttribute('href');

      this._reader.tracking.action('search/go/link');

      this._reader.display(target, function () {
        // return focus to epub iframe, CSB-259
        document.getElementsByTagName("iframe")[0].focus();
      });

      if (this.options.closePanel === false) {
        return false;
      }

      return true;
    }.bind(this));

    this._modal.on('click', 'a[class="feedback-link"]', function (modal, target) {
      window.open(target.href, '_blank');
    }.bind(this));

    this._modal.on('closed', function () {
      this._reader.tracking.action('contents/close');
    }.bind(this)); // only add locations when they've been processed


    this._reader.on('updateLocations', function () {
      this._addLocation = true;
    }.bind(this));

    window.addEventListener('keydown', function (evt) {
      var cmd = (evt.ctrlKey ? 1 : 0) | (evt.altKey ? 2 : 0) | (evt.shiftKey ? 4 : 0) | (evt.metaKey ? 8 : 0);

      if (cmd === 1 || cmd === 8 || cmd === 5 || cmd === 12) {
        if (evt.keyCode == '70') {
          // command/control-F
          evt.preventDefault();

          this._container.querySelector("#cozy-search-string").focus();
        }
      }
    }.bind(this));
  },
  openModalWaiting: function openModalWaiting() {
    this._processing = true;

    this._emptyArticle();

    var value = this.searchString;
    this._article.innerHTML = '<p>Submitting query for <em>' + value + '</em>...</p>' + this._reader.loaderTemplate(); //this._modal.activate();
  },
  openModalResults: function openModalResults() {
    if (this._canceled) {
      this._canceled = false;
      return;
    }

    this._buildResults(); //this._modal.activate();


    this._reader.tracking.action("search/open");
  },
  submitQuery: function submitQuery() {
    var self = this;
    var url = this.options.searchUrl + encodeURIComponent(this.searchString);
    var request = new XMLHttpRequest();
    request.open('GET', url, true);

    request.onload = function () {
      if (this.status >= 200 && this.status < 400) {
        // Success!
        var data = JSON.parse(this.response);
        console.log("SEARCH DATA", data);
        self._data = data;
      } else {
        // We reached our target server, but it returned an error
        self._data = null;
        console.log(this.response);
      }

      self._reader.tracking.action("search/submitQuery");

      self.openModalResults();
    };

    request.onerror = function () {
      // There was a connection error of some sort
      self._data = null;
      self.openModalResults();
    };

    request.send();
  },
  _emptyArticle: function _emptyArticle() {
    while (this._article && this._article.hasChildNodes()) {
      this._article.removeChild(this._article.lastChild);
    }
  },
  _buildResults: function _buildResults() {
    var self = this;
    var content;
    var no_results;
    var feedback;
    var results_list;
    var feedback_link = document.createElement('a');
    feedback_link.target = '_blank';
    feedback_link.href = 'https://umich.qualtrics.com/jfe/form/SV_3KSLynPij0fqrD7?publisher=' + self._reader.metadata.press_subdomain + '&noid=' + self._reader.metadata.noid + '&title=' + self._reader.metadata.title + '&search_location=ereader&q=' + self.searchString + '&url=' + window.location.href;
    feedback_link.innerText = 'Share your feedback.';
    feedback_link.setAttribute("class", "feedback-link");
    var feedback_text = 'Not finding what you\'re looking for? ';
    feedback = DomUtil.create("p");
    feedback.textContent = feedback_text;
    feedback.appendChild(feedback_link);
    this._processing = false;

    self._emptyArticle();

    var reader = this._reader;
    reader.annotations.reset();

    if (this._data) {
      var highlight = true;

      if (this._data.highlight_off == "yes") {
        highlight = false;
      }

      content = DomUtil.create('div');

      if (this._data.search_results.length == 0) {
        no_results = DomUtil.create("p");
        no_results.textContent = 'No results found for "' + self.searchString + '"';
        content.appendChild(no_results);
        content.appendChild(feedback);
      } else {
        content.appendChild(feedback);
        results_list = DomUtil.create('ol');

        this._data.search_results.forEach(function (result) {
          var option = DomUtil.create('li');
          var anchor = DomUtil.create('a', null, option);
          var cfiRange = "epubcfi(" + result.cfi + ")";

          if (result.snippet) {
            // results for epubs
            if (self._addLocation) {
              var loc = reader.locations.locationFromCfi(cfiRange);
              var locText = "Location " + loc + " • ";

              if (cfiRange.match(/^epubcfi\(page/)) {
                // results for pdfs
                // see heliotrope: app/views/e_pubs/show_pdf.html.erb, _gatherResults()
                loc = cfiRange.split("=")[1];
                locText = "Page " + loc.slice(0, -1) + " • ";
              }

              var locElement = DomUtil.create('i');
              locElement.textContent = locText;
              anchor.appendChild(locElement);
            }

            anchor.appendChild(document.createTextNode(result.snippet));
            anchor.setAttribute("href", cfiRange);
            anchor.setAttribute("class", 'search-result');
            results_list.appendChild(option);
          }

          if (highlight) {
            reader.annotations.highlight(cfiRange, {}, null, 'epubjs-search-hl');
          }
        });

        content.appendChild(results_list);
      }
    } else {
      content = DomUtil.create("p");
      content.textContent = 'There was a problem processing this query.';
    }

    self._article.appendChild(content);
  },
  EOT: true
});
var search = function search(options) {
  console.log("-- control.contents", options);
  return new Search(options);
};
;// CONCATENATED MODULE: ./src/control/Control.BibliographicInformation.js



 // Title + Chapter

var BibliographicInformation = Control.extend({
  options: {
    label: 'Info',
    direction: 'left',
    html: '<span class="oi" data-glyph="info">Info</span>'
  },
  defaultTemplate: "<button class=\"button--sm\" data-toggle=\"open\" aria-label=\"Bibliographic Information\"><i class=\"icon-info oi\" data-glyph=\"info\" title=\"Book Information\" aria-hidden=\"true\"></i></button>",
  onAdd: function onAdd(reader) {
    var self = this;
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._reader.on('updateContents', function (data) {
      self._createPanel();
    });

    this._control = container.closest("[data-toggle=open]") || container.querySelector('[data-toggle="open"]');

    this._control.setAttribute('id', 'action-' + this._id);

    container.style.position = 'relative';
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault();

      self._modal.activate();
    }, this);
    return container;
  },
  _createPanel: function _createPanel() {
    var self = this;
    var template = "<dl>\n    </dl>";
    this._modal = this._reader.modal({
      template: template,
      title: 'Info',
      region: 'left',
      fraction: 1.0,
      className: 'cozy-modal-contents'
    });

    var dl = this._modal._container.querySelector('dl');

    var metadata_fields = [['title', 'Title'], ['creator', 'Author'], ['pubdate', 'Publication Date'], ['modified_date', 'Modified Date'], ['publisher', 'Publisher'], ['rights', 'Rights'], ['doi', 'DOI'], ['description', 'Description']];
    var metadata_fields_seen = {};
    var metadata = this._reader.metadata;

    for (var idx in metadata_fields) {
      var key = metadata_fields[idx][0];
      var label = metadata_fields[idx][1];

      if (metadata[key]) {
        var value = metadata[key];

        if (key == 'pubdate' || key == 'modified_date') {
          value = this._formatDate(value);

          if (!value) {
            continue;
          } // value = d.toISOString().slice(0,10); // for YYYY-MM-DD

        }

        metadata_fields_seen[key] = true;
        var dt = DomUtil.create('dt', 'cozy-bib-info-label', dl);
        dt.innerHTML = label;
        var dd = DomUtil.create('dd', 'cozy-bib-info-value cozy-bib-info-value-' + key, dl);
        dd.innerHTML = value;
      }
    }
  },
  _formatDate: function _formatDate(value) {
    var match = value.match(/\d{4}/);

    if (match) {
      return match[0];
    }

    return null;
  },
  EOT: true
});
var bibliographicInformation = function bibliographicInformation(options) {
  return new BibliographicInformation(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Download.js




var Download = Control.extend({
  options: {
    label: 'Download Book',
    html: '<span>Download Book</span>'
  },
  defaultTemplate: "<button class=\"button--sm cozy-download oi\" data-toggle=\"open\" data-glyph=\"data-transfer-download\"> Download Book</button>",
  onAdd: function onAdd(reader) {
    var self = this;
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._reader.on('updateContents', function (data) {
      self._createPanel();
    });

    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault();

      self._modal.activate();
    }, this);
    return container;
  },
  _createPanel: function _createPanel() {
    var self = this;
    var template = "<form>\n      <fieldset>\n        <legend>Choose File Format</legend>\n      </fieldset>\n    </form>";
    this._modal = this._reader.modal({
      template: template,
      title: 'Download Book',
      className: 'cozy-modal-download',
      actions: [{
        label: 'Download',
        callback: function callback(event) {
          var selected = self._form.querySelector("input:checked");

          var href = selected.getAttribute('data-href');

          self._configureDownloadForm(href);

          self._form.submit();
        }
      }],
      region: 'left',
      fraction: 1.0
    });
    this._form = this._modal._container.querySelector('form');

    var fieldset = this._form.querySelector('fieldset');

    this._reader.options.download_links.forEach(function (link, index) {
      var label = DomUtil.create('label', null, fieldset);
      var input = DomUtil.create('input', null, label);
      input.setAttribute('name', 'format');
      input.setAttribute('value', link.format);
      input.setAttribute('data-href', link.href);
      input.setAttribute('type', 'radio');

      if (index == 0) {
        input.setAttribute('checked', 'checked');
      }

      var text = link.format;

      if (link.size) {
        text += " (" + link.size + ")";
      }

      var text = document.createTextNode(" " + text);
      label.appendChild(text);
    });
  },
  _configureDownloadForm: function _configureDownloadForm(href) {
    var self = this;

    self._form.setAttribute('method', 'GET');

    self._form.setAttribute('action', href);

    self._form.setAttribute('target', '_blank');
  },
  EOT: true
});
var download = function download(options) {
  return new Download(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Navigator.js
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }





var Navigator = Control.extend({
  onAdd: function onAdd(reader) {
    var container = this._container;

    if (container) {} else {
      var className = this._className('navigator'),
          options = this.options;

      container = DomUtil.create('div', className);
    }

    this._setup(container);

    this._reader.on('updateLocations', function (locations) {
      this._initializeNavigator(locations);
    }.bind(this));

    return container;
  },
  _setup: function _setup(container) {
    this._control = container.querySelector("input[type=range]");

    if (!this._control) {
      this._createControl(container);
    }

    this._background = container.querySelector(".cozy-navigator-range__background");
    this._status = container.querySelector(".cozy-navigator-range__status");
    this._spanCurrentPercentage = container.querySelector(".currentPercentage");
    this._spanCurrentLocation = container.querySelector(".currentLocation");
    this._spanTotalLocations = container.querySelector(".totalLocations");
    this._spanCurrentPageLabel = container.querySelector('.currentPageLabel');

    this._bindEvents();
  },
  _createControl: function _createControl(container) {
    var template = "<div class=\"cozy-navigator-range\">\n        <label class=\"u-screenreader\" for=\"cozy-navigator-range-input\">Location: </label>\n        <input class=\"cozy-navigator-range__input\" id=\"cozy-navigator-range-input\" type=\"range\" name=\"locations-range-value\" min=\"0\" max=\"100\" step=\"1\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"0\" aria-valuetext=\"0% \u2022\xA0Location 0 of ?\" value=\"0\" data-background-position=\"0\" />\n        <div class=\"cozy-navigator-range__background\"></div>\n      </div>\n      <div class=\"cozy-navigator-range__status\"><span class=\"currentPercentage\">0%</span><span> \u2022 </span><span>Location <span class=\"currentLocation\">0</span> of <span class=\"totalLocations\">?</span><span class=\"currentPageLabel\"></span></span></div>\n    ";
    template = "<div class=\"cozy-navigator-range\">\n      <form>\n        <label class=\"u-screenreader\" for=\"cozy-navigator-range-input\">Location: </label>\n        <div class=\"cozy-navigator-range__background\">\n          <input class=\"cozy-navigator-range__input\" id=\"cozy-navigator-range-input\" type=\"range\" name=\"locations-range-value\" min=\"0\" max=\"100\" step=\"1\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"0\" aria-valuetext=\"0% \u2022\xA0Location 0 of ?\" value=\"0\" data-background-position=\"0\" />\n        </div>\n      </form>\n      </div>\n      <div class=\"cozy-navigator-range__status\"><span class=\"currentPercentage\">0%</span><span> \u2022 </span><span>Location <span class=\"currentLocation\">0</span> of <span class=\"totalLocations\">?</span><span class=\"currentPageLabel\"></span></span></div>";
    var body = new DOMParser().parseFromString(template, "text/html").body;

    while (body.children.length) {
      container.appendChild(body.children[0]);
    }

    this._control = container.querySelector("input[type=range]");
  },
  _bindEvents: function _bindEvents() {
    var self = this;
    var isIE = window.navigator.userAgent.indexOf("Trident/") > -1;

    this._control.addEventListener("input", function () {
      if (self._keyDown) {
        self._keyDown = false;
        return;
      }

      self._update(false);
    }, false);

    this._control.addEventListener("change", function (event) {
      if (self._mouseDown) {
        if (isIE) {
          self._update(false);
        }

        return;
      }

      self._action();
    }, false);

    this._control.addEventListener("mousedown", function (event) {
      self._mouseDown = true;

      self._container.classList.add('updating');
    }, false);

    this._control.addEventListener("mouseup", function () {
      self._mouseDown = false;

      self._container.classList.remove('updating');

      if (isIE) {
        self._action();

        return;
      }

      self._update();
    }, false);

    this._control.addEventListener("keydown", function (event) {
      if (event.key == 'ArrowLeft' || event.key == 'ArrowRight') {
        // do not fire input events if we're just keying around
        self._keyDown = true;
      }
    }, false);

    this._control.addEventListener("keyup", function () {// self._mouseDown = false;
    }, false);
  },
  _action: function _action() {
    var _this = this;

    var value = parseInt(this._control.value, 10);
    var cfi;
    var locations = this._reader.locations;

    if (locations.cfiFromLocation) {
      cfi = locations.cfiFromLocation(value);
    } else {
      // hopefully short-term compatibility
      var percent = value / this._total;
      cfi = locations.cfiFromPercentage(percent);
    }

    this._reader.tracking.action("navigator/go"); // this._ignore = true;


    if (this._watching == 'updateLocation') {
      setTimeout(function () {
        _this._update();
      }, 100);
    }

    this._reader.gotoPage(cfi);
  },
  _update: function _update(current) {
    var self = this;
    var value = parseFloat(this._control.value, 10);
    var current_location = value;
    var max = parseFloat(this._control.max, 10);
    var percentage = value / max * 100.0; // this._background.setAttribute('style', 'background-position: ' + (-percentage) + '% 0%, left top;');

    var fill = this._fill; // '#2497e3';

    var end = this._end; // '#ffffff';

    this._control.style.background = "linear-gradient(to right, ".concat(fill, " 0%, ").concat(fill, " ").concat(percentage, "%, ").concat(end, " ").concat(percentage, "%, ").concat(end, " 100%)");
    percentage = Math.ceil(percentage);
    this._spanCurrentPercentage.innerHTML = percentage + '%';

    this._control.setAttribute('data-background-position', percentage);

    this._spanCurrentLocation.innerHTML = current_location;
    var current_page = '';

    if (this._reader.pageList) {
      // && current !== false
      var pages;

      if (_typeof(current) != 'object') {
        var cfi = this._reader.locations.cfiFromLocation(current_location);

        pages = [this._reader.pageList.pageFromCfi(cfi)];
      } else {
        pages = this._reader.pageList.pagesFromLocation(current);
      }

      var pageLabels = [];
      var label = 'p.';

      if (pages.length) {
        var p1 = pages.shift();
        pageLabels.push(this._reader.pageList.pageLabel(p1));

        if (pages.length) {
          var p2 = pages.pop();
          pageLabels.push(this._reader.pageList.pageLabel(p2));
          label = 'pp.';
        }
      }

      if (pageLabels.length) {
        current_page = " (".concat(label, " ").concat(pageLabels.join('-'), ")");
      }

      this._spanCurrentPageLabel.innerHTML = current_page;
    }

    this._control.setAttribute('aria-valuenow', value);

    this._control.setAttribute('aria-valuetext', "".concat(percentage, "% \u2022\xA0Location ").concat(current_location, " of ").concat(this._total).concat(current_page)); // var message = `Location ${current_location}; ${percentage}%${current_page}`;
    // this._reader.updateLiveStatus(message);

  },
  _initializeNavigator: function _initializeNavigator(locations) {
    var self = this;
    this._initiated = true;
    this._fill = window.getComputedStyle(this._background, ':before').getPropertyValue('background-color');
    this._end = window.getComputedStyle(this._background, ':after').getPropertyValue('background-color');

    if (!this._reader.pageList) {
      this._spanCurrentPageLabel.style.display = 'none';
    }

    this._total = this._reader.locations.total;
    var max = this._total;
    var min = 1;

    if (this._reader.locations.spine) {
      max -= 1;
      min -= 1;
    }

    this._control.max = max;
    this._control.min = min;

    var current = this._reader.currentLocation();

    var value = this._parseLocation(current);

    this._control.value = value;
    this._last_value = this._control.value;

    this._update(current);

    this._spanTotalLocations.innerHTML = this._total;

    if (this._reader.locations.cfiFromLocation) {
      this._watching = 'relocated';

      this._reader.on('relocated', function (location) {
        self._handle_relocated(location);
      });
    } else {
      // BACK COMPATIBILITY
      this._watching = 'updateLocation';

      this._reader.on('updateLocation', function (location) {
        console.log("AHOY NAVIGATOR updateLocation", location);

        self._handle_relocated(location);
      });
    }

    setTimeout(function () {
      DomUtil.addClass(this._container, 'initialized');
    }.bind(this), 0);
  },
  _handle_relocated: function _handle_relocated(location) {
    var self = this;
    var value;
    var percentage;

    if (!self._initiated) {
      return;
    }

    if (!(location && location.start)) {
      return;
    }

    var value;

    if (location.start && location.end) {
      // EPUB
      value = parseInt(self._control.value, 10);
      var start = parseInt(location.start.location, 10);
      var end = parseInt(location.end.location, 10);

      if (start == this._last_location_start && end == this._last_location_end) {
        return;
      }

      this._last_location_start = start;
      this._last_location_end = end; // console.log("AHOY NAVIGATOR relocated", value, start, end, value < start, value > end);

      if (value < start || value > end) {
        self._last_value = value;
        self._control.value = value < start ? start : end;
      }
    } else {
      value = self._parseLocation(location);

      if (value == this._last_value) {
        return;
      }

      self._last_value = value;
      self._control.value = value;
    }

    self._update(location); // var message = `Location ${current_location}; ${percentage}%${current_page}`;


    var message = this._control.getAttribute('aria-valuetext');

    this._reader.updateLiveStatus(message);
  },
  _parseLocation: function _parseLocation(location) {
    var self = this;
    var value;

    function handle_possible_pdf_location(location) {
      var start = location.start.cfi ? location.start.cfi : location.start;

      if (typeof start == 'string' && start.indexOf('page=') > -1) {
        // dumb
        start = start.replace('epubcfi(page=', '').replace(')', '');
      }

      return start;
    }

    if (typeof location.start == 'undefined') {
      // If the window is being resized while the reader is still loading an EPUB chapter, then...
      // `location.start` will be undefined here. This causes the reader to appear to load forever.
      // I _think_ this is going to be a rarity in the wild, although clicking the full screen...
      // button too soon will also cause it. Also, it's actually very likely to happen when a ...
      // developer opens a "docked" dev tools dialog while CSB is loading a complex chapter.
      // In this event starting from scratch with a page reload seems like the best move.
      // Anything else causes a recursive, asynchronous mess.
      console.log("AHOY NAVIGATOR location lost. Window resized while loading? Reloading page.");
      window.location.reload(); // errors may still appear in the console before the reload occurs
    } else if (_typeof(location.start) == 'object') {
      if (location.start.location != null) {
        value = location.start.location;
      } else {
        var start_cfi = handle_possible_pdf_location(location);

        var percentage = self._reader.locations.percentageFromCfi(start_cfi);

        value = Math.ceil(self._total * percentage);
      }
    } else {
      // PDF bug
      var start = handle_possible_pdf_location(location);
      value = parseInt(start, 10);
    }

    return value;
  },
  EOT: true
});
var Control_Navigator_navigator = function navigator(options) {
  return new Navigator(options);
};
;// CONCATENATED MODULE: ./src/control/Control.Fullscreen.js




var Fullscreen = Control.extend({
  options: {
    label: 'View Fullscreen',
    html: '<span>View Fullscreen</span>'
  },
  defaultTemplate: "<button class=\"button--sm cozy-fullscreen oi\" data-toggle=\"open\" data-glyph=\"fullscreen-enter\" aria-label=\"Enter Fullscreen\"></button>",
  onAdd: function onAdd(reader) {
    var _this = this;

    var self = this;
    var container = this._container;

    if (container) {
      this._control = container.querySelector("[data-target=" + this.options.direction + "]");
    } else {
      var className = this._className(),
          options = this.options;

      container = DomUtil.create('div', className);
      var template = this.options.template || this.defaultTemplate;
      var body = new DOMParser().parseFromString(template, "text/html").body;

      while (body.children.length) {
        container.appendChild(body.children[0]);
      }
    }

    this._control = container.querySelector("[data-toggle=open]");
    DomEvent.on(this._control, 'click', function (event) {
      event.preventDefault();
      self.activate();
    }, this); // // fullscreenchange is not standard across all browsers
    // document.addEventListener('fullscreenchange', (event) => {
    //   // document.fullscreenElement will point to the element that
    //   // is in fullscreen mode if there is one. If there isn't one,
    //   // the value of the property is null.    
    //   this._fullscreenchangeHandler();
    // });

    this._reader.on('fullscreenchange', function (data) {
      _this._fullscreenchangeHandler(data.isFullscreen);
    });

    return container;
  },
  activate: function activate() {
    if (!document.fullscreenElement) {
      this._reader.requestFullscreen();
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      }
    }
  },
  _fullscreenchangeHandler: function _fullscreenchangeHandler(isFullscreen) {
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
var fullscreen = function fullscreen(options) {
  return new Fullscreen(options);
};
;// CONCATENATED MODULE: ./src/control/index.js












 // import {Zoom, zoom} from './Control.Zoom';
// import {Attribution, attribution} from './Control.Attribution';

Control.PageNext = PageNext;
Control.PagePrevious = PagePrevious;
Control.PageFirst = PageFirst;
Control.PageLast = PageLast;
control.pagePrevious = pagePrevious;
control.pageNext = pageNext;
control.pageFirst = pageFirst;
control.pageLast = pageLast;
Control.Contents = Contents;
control.contents = contents;
Control.Title = Title;
control.title = title;
Control.PublicationMetadata = PublicationMetadata;
control.publicationMetadata = publicationMetadata;
Control.Preferences = Preferences;
control.preferences = preferences;
Control.Widget = Widget;
control.widget = widget;
Control.Citation = Citation;
control.citation = citation;
Control.Search = Search;
control.search = search;
Control.BibliographicInformation = BibliographicInformation;
control.bibliographicInformation = bibliographicInformation;
Control.Download = Download;
control.download = download;
Control.Navigator = Navigator;
control.navigator = Control_Navigator_navigator;
Control.Fullscreen = Fullscreen;
control.fullscreen = fullscreen;


/***/ }),

/***/ 8643:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ie": () => (/* binding */ ie),
/* harmony export */   "ielt9": () => (/* binding */ ielt9),
/* harmony export */   "edge": () => (/* binding */ edge),
/* harmony export */   "webkit": () => (/* binding */ webkit),
/* harmony export */   "android": () => (/* binding */ android),
/* harmony export */   "android23": () => (/* binding */ android23),
/* harmony export */   "opera": () => (/* binding */ opera),
/* harmony export */   "chrome": () => (/* binding */ chrome),
/* harmony export */   "gecko": () => (/* binding */ gecko),
/* harmony export */   "safari": () => (/* binding */ safari),
/* harmony export */   "phantom": () => (/* binding */ phantom),
/* harmony export */   "opera12": () => (/* binding */ opera12),
/* harmony export */   "win": () => (/* binding */ win),
/* harmony export */   "ie3d": () => (/* binding */ ie3d),
/* harmony export */   "webkit3d": () => (/* binding */ webkit3d),
/* harmony export */   "gecko3d": () => (/* binding */ gecko3d),
/* harmony export */   "any3d": () => (/* binding */ any3d),
/* harmony export */   "mobile": () => (/* binding */ mobile),
/* harmony export */   "mobileWebkit": () => (/* binding */ mobileWebkit),
/* harmony export */   "mobileWebkit3d": () => (/* binding */ mobileWebkit3d),
/* harmony export */   "msPointer": () => (/* binding */ msPointer),
/* harmony export */   "pointer": () => (/* binding */ pointer),
/* harmony export */   "touch": () => (/* binding */ touch),
/* harmony export */   "mobileOpera": () => (/* binding */ mobileOpera),
/* harmony export */   "mobileGecko": () => (/* binding */ mobileGecko),
/* harmony export */   "retina": () => (/* binding */ retina),
/* harmony export */   "canvas": () => (/* binding */ canvas),
/* harmony export */   "svg": () => (/* binding */ svg),
/* harmony export */   "vml": () => (/* binding */ vml),
/* harmony export */   "columnCount": () => (/* binding */ columnCount),
/* harmony export */   "classList": () => (/* binding */ classList)
/* harmony export */ });
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

/*
 * @namespace Browser
 * @aka L.Browser
 *
 * A namespace with static properties for browser/feature detection used by Leaflet internally.
 *
 * @example
 *
 * ```js
 * if (L.Browser.ielt9) {
 *   alert('Upgrade your browser, dude!');
 * }
 * ```
 */
var style = document.documentElement.style; // @property ie: Boolean; `true` for all Internet Explorer versions (not Edge).

var ie = ('ActiveXObject' in window); // @property ielt9: Boolean; `true` for Internet Explorer versions less than 9.

var ielt9 = ie && !document.addEventListener; // @property edge: Boolean; `true` for the Edge web browser.

var edge = 'msLaunchUri' in navigator && !('documentMode' in document); // @property webkit: Boolean;
// `true` for webkit-based browsers like Chrome and Safari (including mobile versions).

var webkit = userAgentContains('webkit'); // @property android: Boolean
// `true` for any browser running on an Android platform.

var android = userAgentContains('android'); // @property android23: Boolean; `true` for browsers running on Android 2 or Android 3.

var android23 = userAgentContains('android 2') || userAgentContains('android 3'); // @property opera: Boolean; `true` for the Opera browser

var opera = !!window.opera; // @property chrome: Boolean; `true` for the Chrome browser.

var chrome = userAgentContains('chrome'); // @property gecko: Boolean; `true` for gecko-based browsers like Firefox.

var gecko = userAgentContains('gecko') && !webkit && !opera && !ie; // @property safari: Boolean; `true` for the Safari browser.

var safari = !chrome && userAgentContains('safari');
var phantom = userAgentContains('phantom'); // @property opera12: Boolean
// `true` for the Opera browser supporting CSS transforms (version 12 or later).

var opera12 = ('OTransition' in style); // @property win: Boolean; `true` when the browser is running in a Windows platform

var win = navigator.platform.indexOf('Win') === 0; // @property ie3d: Boolean; `true` for all Internet Explorer versions supporting CSS transforms.

var ie3d = ie && 'transition' in style; // @property webkit3d: Boolean; `true` for webkit-based browsers supporting CSS transforms.

var webkit3d = 'WebKitCSSMatrix' in window && 'm11' in new window.WebKitCSSMatrix() && !android23; // @property gecko3d: Boolean; `true` for gecko-based browsers supporting CSS transforms.

var gecko3d = ('MozPerspective' in style); // @property any3d: Boolean
// `true` for all browsers supporting CSS transforms.

var any3d = !window.L_DISABLE_3D && (ie3d || webkit3d || gecko3d) && !opera12 && !phantom; // @property mobile: Boolean; `true` for all browsers running in a mobile device.

var mobile = typeof orientation !== 'undefined' || userAgentContains('mobile'); // @property mobileWebkit: Boolean; `true` for all webkit-based browsers in a mobile device.

var mobileWebkit = mobile && webkit; // @property mobileWebkit3d: Boolean
// `true` for all webkit-based browsers in a mobile device supporting CSS transforms.

var mobileWebkit3d = mobile && webkit3d; // @property msPointer: Boolean
// `true` for browsers implementing the Microsoft touch events model (notably IE10).

var msPointer = !window.PointerEvent && window.MSPointerEvent; // @property pointer: Boolean
// `true` for all browsers supporting [pointer events](https://msdn.microsoft.com/en-us/library/dn433244%28v=vs.85%29.aspx).

var pointer = !!(window.PointerEvent || msPointer); // @property touch: Boolean
// `true` for all browsers supporting [touch events](https://developer.mozilla.org/docs/Web/API/Touch_events).
// This does not necessarily mean that the browser is running in a computer with
// a touchscreen, it only means that the browser is capable of understanding
// touch events.

var touch = !window.L_NO_TOUCH && (pointer || 'ontouchstart' in window || window.DocumentTouch && document instanceof window.DocumentTouch); // @property mobileOpera: Boolean; `true` for the Opera browser in a mobile device.

var mobileOpera = mobile && opera; // @property mobileGecko: Boolean
// `true` for gecko-based browsers running in a mobile device.

var mobileGecko = mobile && gecko; // @property retina: Boolean
// `true` for browsers on a high-resolution "retina" screen.

var retina = (window.devicePixelRatio || window.screen.deviceXDPI / window.screen.logicalXDPI) > 1; // @property canvas: Boolean
// `true` when the browser supports [`<canvas>`](https://developer.mozilla.org/docs/Web/API/Canvas_API).

var canvas = function () {
  return !!document.createElement('canvas').getContext;
}(); // @property svg: Boolean
// `true` when the browser supports [SVG](https://developer.mozilla.org/docs/Web/SVG).
// export var svg = !!(document.createElementNS && svgCreate('svg').createSVGRect);

var svg = true; // @property vml: Boolean
// `true` if the browser supports [VML](https://en.wikipedia.org/wiki/Vector_Markup_Language).

var vml = !svg && function () {
  try {
    var div = document.createElement('div');
    div.innerHTML = '<v:shape adj="1"/>';
    var shape = div.firstChild;
    shape.style.behavior = 'url(#default#VML)';
    return shape && _typeof(shape.adj) === 'object';
  } catch (e) {
    return false;
  }
}();
var columnCount = ('columnCount' in style);
var classList = document.documentElement.classList !== undefined;

function userAgentContains(str) {
  return navigator.userAgent.toLowerCase().indexOf(str) >= 0;
}

/***/ }),

/***/ 7573:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "w": () => (/* binding */ Class)
/* harmony export */ });
/* harmony import */ var _Util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(7518);
 // @class Class
// @aka L.Class
// @section
// @uninheritable
// Thanks to John Resig and Dean Edwards for inspiration!

function Class() {}

Class.extend = function (props) {
  // @function extend(props: Object): Function
  // [Extends the current class](#class-inheritance) given the properties to be included.
  // Returns a Javascript function that is a class constructor (to be called with `new`).
  var NewClass = function NewClass() {
    // call the constructor
    if (this.initialize) {
      this.initialize.apply(this, arguments);
    } // call all constructor hooks


    this.callInitHooks();
  };

  var parentProto = NewClass.__super__ = this.prototype;
  var proto = _Util__WEBPACK_IMPORTED_MODULE_0__.create(parentProto);
  proto.constructor = NewClass;
  NewClass.prototype = proto; // inherit parent's statics

  for (var i in this) {
    if (this.hasOwnProperty(i) && i !== 'prototype') {
      NewClass[i] = this[i];
    }
  } // mix static properties into the class


  if (props.statics) {
    _Util__WEBPACK_IMPORTED_MODULE_0__.extend(NewClass, props.statics);
    delete props.statics;
  } // mix includes into the prototype


  if (props.includes) {
    checkDeprecatedMixinEvents(props.includes);
    _Util__WEBPACK_IMPORTED_MODULE_0__.extend.apply(null, [proto].concat(props.includes));
    delete props.includes;
  } // merge options


  if (proto.options) {
    props.options = _Util__WEBPACK_IMPORTED_MODULE_0__.extend(_Util__WEBPACK_IMPORTED_MODULE_0__.create(proto.options), props.options);
  } // mix given properties into the prototype


  _Util__WEBPACK_IMPORTED_MODULE_0__.extend(proto, props);
  proto._initHooks = []; // add method for calling all hooks

  proto.callInitHooks = function () {
    if (this._initHooksCalled) {
      return;
    }

    if (parentProto.callInitHooks) {
      parentProto.callInitHooks.call(this);
    }

    this._initHooksCalled = true;

    for (var i = 0, len = proto._initHooks.length; i < len; i++) {
      proto._initHooks[i].call(this);
    }
  };

  return NewClass;
}; // @function include(properties: Object): this
// [Includes a mixin](#class-includes) into the current class.


Class.include = function (props) {
  _Util__WEBPACK_IMPORTED_MODULE_0__.extend(this.prototype, props);
  return this;
}; // @function mergeOptions(options: Object): this
// [Merges `options`](#class-options) into the defaults of the class.


Class.mergeOptions = function (options) {
  _Util__WEBPACK_IMPORTED_MODULE_0__.extend(this.prototype.options, options);
  return this;
}; // @function addInitHook(fn: Function): this
// Adds a [constructor hook](#class-constructor-hooks) to the class.


Class.addInitHook = function (fn) {
  // (Function) || (String, args...)
  var args = Array.prototype.slice.call(arguments, 1);
  var init = typeof fn === 'function' ? fn : function () {
    this[fn].apply(this, args);
  };
  this.prototype._initHooks = this.prototype._initHooks || [];

  this.prototype._initHooks.push(init);

  return this;
};

function checkDeprecatedMixinEvents(includes) {
  if (!cozy || !cozy.Mixin) {
    return;
  }

  includes = cozy.Util.isArray(includes) ? includes : [includes]; // for (var i = 0; i < includes.length; i++) {
  // 	if (includes[i] === cozy.Mixin.Events) {
  // 		console.warn('Deprecated include of cozy.Mixin.Events: ' +
  // 			'this property will be removed in future releases, ' +
  // 			'please inherit from cozy.Evented instead.', new Error().stack);
  // 	}
  // }
}

/***/ }),

/***/ 1146:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "c": () => (/* binding */ Evented)
/* harmony export */ });
/* harmony import */ var _Class__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(7573);
/* harmony import */ var _Util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(7518);
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }



/*
 * @class Evented
 * @aka L.Evented
 * @inherits Class
 *
 * A set of methods shared between event-powered classes (like `Map` and `Marker`). Generally, events allow you to execute some function when something happens with an object (e.g. the user clicks on the map, causing the map to fire `'click'` event).
 *
 * @example
 *
 * ```js
 * map.on('click', function(e) {
 * 	alert(e.latlng);
 * } );
 * ```
 *
 * Leaflet deals with event listeners by reference, so if you want to add a listener and then remove it, define it as a function:
 *
 * ```js
 * function onClick(e) { ... }
 *
 * map.on('click', onClick);
 * map.off('click', onClick);
 * ```
 */

var Evented = _Class__WEBPACK_IMPORTED_MODULE_0__/* .Class.extend */ .w.extend({
  /* @method on(type: String, fn: Function, context?: Object): this
   * Adds a listener function (`fn`) to a particular event type of the object. You can optionally specify the context of the listener (object the this keyword will point to). You can also pass several space-separated types (e.g. `'click dblclick'`).
   *
   * @alternative
   * @method on(eventMap: Object): this
   * Adds a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`
   */
  on: function on(types, fn, context) {
    // types can be a map of types/handlers
    if (_typeof(types) === 'object') {
      for (var type in types) {
        // we don't process space-separated events here for performance;
        // it's a hot path since Layer uses the on(obj) syntax
        this._on(type, types[type], fn);
      }
    } else {
      // types can be a string of space-separated words
      types = _Util__WEBPACK_IMPORTED_MODULE_1__.splitWords(types);

      for (var i = 0, len = types.length; i < len; i++) {
        this._on(types[i], fn, context);
      }
    }

    return this;
  },

  /* @method off(type: String, fn?: Function, context?: Object): this
   * Removes a previously added listener function. If no function is specified, it will remove all the listeners of that particular event from the object. Note that if you passed a custom context to `on`, you must pass the same context to `off` in order to remove the listener.
   *
   * @alternative
   * @method off(eventMap: Object): this
   * Removes a set of type/listener pairs.
   *
   * @alternative
   * @method off: this
   * Removes all listeners to all events on the object.
   */
  off: function off(types, fn, context) {
    if (!types) {
      // clear all listeners if called without arguments
      delete this._events;
    } else if (_typeof(types) === 'object') {
      for (var type in types) {
        this._off(type, types[type], fn);
      }
    } else {
      types = _Util__WEBPACK_IMPORTED_MODULE_1__.splitWords(types);

      for (var i = 0, len = types.length; i < len; i++) {
        this._off(types[i], fn, context);
      }
    }

    return this;
  },
  // attach listener (without syntactic sugar now)
  _on: function _on(type, fn, context) {
    this._events = this._events || {};
    /* get/init listeners for type */

    var typeListeners = this._events[type];

    if (!typeListeners) {
      typeListeners = [];
      this._events[type] = typeListeners;
    }

    if (context === this) {
      // Less memory footprint.
      context = undefined;
    }

    var newListener = {
      fn: fn,
      ctx: context
    },
        listeners = typeListeners; // check if fn already there

    for (var i = 0, len = listeners.length; i < len; i++) {
      if (listeners[i].fn === fn && listeners[i].ctx === context) {
        return;
      }
    }

    listeners.push(newListener);
  },
  _off: function _off(type, fn, context) {
    var listeners, i, len;

    if (!this._events) {
      return;
    }

    listeners = this._events[type];

    if (!listeners) {
      return;
    }

    if (!fn) {
      // Set all removed listeners to noop so they are not called if remove happens in fire
      for (i = 0, len = listeners.length; i < len; i++) {
        listeners[i].fn = _Util__WEBPACK_IMPORTED_MODULE_1__.falseFn;
      } // clear all listeners for a type if function isn't specified


      delete this._events[type];
      return;
    }

    if (context === this) {
      context = undefined;
    }

    if (listeners) {
      // find fn and remove it
      for (i = 0, len = listeners.length; i < len; i++) {
        var l = listeners[i];

        if (l.ctx !== context) {
          continue;
        }

        if (l.fn === fn) {
          // set the removed listener to noop so that's not called if remove happens in fire
          l.fn = _Util__WEBPACK_IMPORTED_MODULE_1__.falseFn;

          if (this._firingCount) {
            /* copy array in case events are being fired */
            this._events[type] = listeners = listeners.slice();
          }

          listeners.splice(i, 1);
          return;
        }
      }
    }
  },
  // @method fire(type: String, data?: Object, propagate?: Boolean): this
  // Fires an event of the specified type. You can optionally provide an data
  // object — the first argument of the listener function will contain its
  // properties. The event can optionally be propagated to event parents.
  fire: function fire(type, data, propagate) {
    if (!this.listens(type, propagate)) {
      return this;
    }

    var event = _Util__WEBPACK_IMPORTED_MODULE_1__.extend({}, data, {
      type: type,
      target: this
    });

    if (this._events) {
      var listeners = this._events[type];

      if (listeners) {
        this._firingCount = this._firingCount + 1 || 1;

        for (var i = 0, len = listeners.length; i < len; i++) {
          var l = listeners[i];
          l.fn.call(l.ctx || this, event);
        }

        this._firingCount--;
      }
    }

    if (propagate) {
      // propagate the event to parents (set with addEventParent)
      this._propagateEvent(event);
    }

    return this;
  },
  // @method listens(type: String): Boolean
  // Returns `true` if a particular event type has any listeners attached to it.
  listens: function listens(type, propagate) {
    var listeners = this._events && this._events[type];

    if (listeners && listeners.length) {
      return true;
    }

    if (propagate) {
      // also check parents for listeners if event propagates
      for (var id in this._eventParents) {
        if (this._eventParents[id].listens(type, propagate)) {
          return true;
        }
      }
    }

    return false;
  },
  // @method once(…): this
  // Behaves as [`on(…)`](#evented-on), except the listener will only get fired once and then removed.
  once: function once(types, fn, context) {
    if (_typeof(types) === 'object') {
      for (var type in types) {
        this.once(type, types[type], fn);
      }

      return this;
    }

    var handler = _Util__WEBPACK_IMPORTED_MODULE_1__.bind(function () {
      this.off(types, fn, context).off(types, handler, context);
    }, this); // add a listener that's executed once and removed after that

    return this.on(types, fn, context).on(types, handler, context);
  },
  // @method addEventParent(obj: Evented): this
  // Adds an event parent - an `Evented` that will receive propagated events
  addEventParent: function addEventParent(obj) {
    this._eventParents = this._eventParents || {};
    this._eventParents[_Util__WEBPACK_IMPORTED_MODULE_1__.stamp(obj)] = obj;
    return this;
  },
  // @method removeEventParent(obj: Evented): this
  // Removes an event parent, so it will stop receiving propagated events
  removeEventParent: function removeEventParent(obj) {
    if (this._eventParents) {
      delete this._eventParents[_Util__WEBPACK_IMPORTED_MODULE_1__.stamp(obj)];
    }

    return this;
  },
  _propagateEvent: function _propagateEvent(e) {
    for (var id in this._eventParents) {
      this._eventParents[id].fire(e.type, _Util__WEBPACK_IMPORTED_MODULE_1__.extend({
        layer: e.target
      }, e), true);
    }
  }
});
var proto = Evented.prototype; // aliases; we should ditch those eventually
// @method addEventListener(…): this
// Alias to [`on(…)`](#evented-on)

proto.addEventListener = proto.on; // @method removeEventListener(…): this
// Alias to [`off(…)`](#evented-off)
// @method clearAllEventListeners(…): this
// Alias to [`off()`](#evented-off)

proto.removeEventListener = proto.clearAllEventListeners = proto.off; // @method addOneTimeEventListener(…): this
// Alias to [`once(…)`](#evented-once)

proto.addOneTimeEventListener = proto.once; // @method fireEvent(…): this
// Alias to [`fire(…)`](#evented-fire)

proto.fireEvent = proto.fire; // @method hasEventListeners(…): Boolean
// Alias to [`listens(…)`](#evented-listens)

proto.hasEventListeners = proto.listens;

/***/ }),

/***/ 7518:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "extend": () => (/* binding */ extend),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "bind": () => (/* binding */ bind),
/* harmony export */   "lastId": () => (/* binding */ lastId),
/* harmony export */   "stamp": () => (/* binding */ stamp),
/* harmony export */   "throttle": () => (/* binding */ throttle),
/* harmony export */   "wrapNum": () => (/* binding */ wrapNum),
/* harmony export */   "falseFn": () => (/* binding */ falseFn),
/* harmony export */   "formatNum": () => (/* binding */ formatNum),
/* harmony export */   "isNumeric": () => (/* binding */ isNumeric),
/* harmony export */   "trim": () => (/* binding */ trim),
/* harmony export */   "splitWords": () => (/* binding */ splitWords),
/* harmony export */   "setOptions": () => (/* binding */ setOptions),
/* harmony export */   "getParamString": () => (/* binding */ getParamString),
/* harmony export */   "template": () => (/* binding */ template),
/* harmony export */   "isArray": () => (/* binding */ isArray),
/* harmony export */   "indexOf": () => (/* binding */ indexOf),
/* harmony export */   "emptyImageUrl": () => (/* binding */ emptyImageUrl),
/* harmony export */   "requestFn": () => (/* binding */ requestFn),
/* harmony export */   "cancelFn": () => (/* binding */ cancelFn),
/* harmony export */   "requestAnimFrame": () => (/* binding */ requestAnimFrame),
/* harmony export */   "cancelAnimFrame": () => (/* binding */ cancelAnimFrame),
/* harmony export */   "inVp": () => (/* binding */ inVp),
/* harmony export */   "loader": () => (/* binding */ loader)
/* harmony export */ });
/*
 * @namespace Util
 *
 * Various utility functions, used by Leaflet internally.
 */
// @function extend(dest: Object, src?: Object): Object
// Merges the properties of the `src` object (or multiple objects) into `dest` object and returns the latter. Has an `L.extend` shortcut.
function extend(dest) {
  var i, j, len, src;

  for (j = 1, len = arguments.length; j < len; j++) {
    src = arguments[j];

    for (i in src) {
      dest[i] = src[i];
    }
  }

  return dest;
} // @function create(proto: Object, properties?: Object): Object
// Compatibility polyfill for [Object.create](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Object/create)

var create = Object.create || function () {
  function F() {}

  return function (proto) {
    F.prototype = proto;
    return new F();
  };
}(); // @function bind(fn: Function, …): Function
// Returns a new function bound to the arguments passed, like [Function.prototype.bind](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Function/bind).
// Has a `L.bind()` shortcut.

function bind(fn, obj) {
  var slice = Array.prototype.slice;

  if (fn.bind) {
    return fn.bind.apply(fn, slice.call(arguments, 1));
  }

  var args = slice.call(arguments, 2);
  return function () {
    return fn.apply(obj, args.length ? args.concat(slice.call(arguments)) : arguments);
  };
} // @property lastId: Number
// Last unique ID used by [`stamp()`](#util-stamp)

var lastId = 0; // @function stamp(obj: Object): Number
// Returns the unique ID of an object, assiging it one if it doesn't have it.

function stamp(obj) {
  /*eslint-disable */
  obj._cozy_id = obj._cozy_id || ++lastId;
  return obj._cozy_id;
  /* not leaflet */

  /*eslint-enable */
} // @function throttle(fn: Function, time: Number, context: Object): Function
// Returns a function which executes function `fn` with the given scope `context`
// (so that the `this` keyword refers to `context` inside `fn`'s code). The function
// `fn` will be called no more than one time per given amount of `time`. The arguments
// received by the bound function will be any arguments passed when binding the
// function, followed by any arguments passed when invoking the bound function.
// Has an `L.throttle` shortcut.

function throttle(fn, time, context) {
  var lock, args, wrapperFn, later;

  later = function later() {
    // reset lock and call if queued
    lock = false;

    if (args) {
      wrapperFn.apply(context, args);
      args = false;
    }
  };

  wrapperFn = function wrapperFn() {
    if (lock) {
      // called too soon, queue to call later
      args = arguments;
    } else {
      // call and lock until later
      fn.apply(context, arguments);
      setTimeout(later, time);
      lock = true;
    }
  };

  return wrapperFn;
} // @function wrapNum(num: Number, range: Number[], includeMax?: Boolean): Number
// Returns the number `num` modulo `range` in such a way so it lies within
// `range[0]` and `range[1]`. The returned value will be always smaller than
// `range[1]` unless `includeMax` is set to `true`.

function wrapNum(x, range, includeMax) {
  var max = range[1],
      min = range[0],
      d = max - min;
  return x === max && includeMax ? x : ((x - min) % d + d) % d + min;
} // @function falseFn(): Function
// Returns a function which always returns `false`.

function falseFn() {
  return false;
} // @function formatNum(num: Number, digits?: Number): Number
// Returns the number `num` rounded to `digits` decimals, or to 5 decimals by default.

function formatNum(num, digits) {
  var pow = Math.pow(10, digits || 5);
  return Math.round(num * pow) / pow;
} // @function isNumeric(num: Number): Boolean
// Returns whether num is actually numeric

function isNumeric(num) {
  return !isNaN(parseFloat(num)) && isFinite(num);
} // @function trim(str: String): String
// Compatibility polyfill for [String.prototype.trim](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/String/Trim)

function trim(str) {
  return str.trim ? str.trim() : str.replace(/^\s+|\s+$/g, '');
} // @function splitWords(str: String): String[]
// Trims and splits the string on whitespace and returns the array of parts.

function splitWords(str) {
  return trim(str).split(/\s+/);
} // @function setOptions(obj: Object, options: Object): Object
// Merges the given properties to the `options` of the `obj` object, returning the resulting options. See `Class options`. Has an `L.setOptions` shortcut.

function setOptions(obj, options) {
  if (!obj.hasOwnProperty('options')) {
    obj.options = obj.options ? create(obj.options) : {};
  }

  for (var i in options) {
    obj.options[i] = options[i];
  }

  return obj.options;
} // @function getParamString(obj: Object, existingUrl?: String, uppercase?: Boolean): String
// Converts an object into a parameter URL string, e.g. `{a: "foo", b: "bar"}`
// translates to `'?a=foo&b=bar'`. If `existingUrl` is set, the parameters will
// be appended at the end. If `uppercase` is `true`, the parameter names will
// be uppercased (e.g. `'?A=foo&B=bar'`)

function getParamString(obj, existingUrl, uppercase) {
  var params = [];

  for (var i in obj) {
    params.push(encodeURIComponent(uppercase ? i.toUpperCase() : i) + '=' + encodeURIComponent(obj[i]));
  }

  return (!existingUrl || existingUrl.indexOf('?') === -1 ? '?' : '&') + params.join('&');
}
var templateRe = /\{ *([\w_\-]+) *\}/g; // @function template(str: String, data: Object): String
// Simple templating facility, accepts a template string of the form `'Hello {a}, {b}'`
// and a data object like `{a: 'foo', b: 'bar'}`, returns evaluated string
// `('Hello foo, bar')`. You can also specify functions instead of strings for
// data values — they will be evaluated passing `data` as an argument.

function template(str, data) {
  return str.replace(templateRe, function (str, key) {
    var value = data[key];

    if (value === undefined) {
      throw new Error('No value provided for variable ' + str);
    } else if (typeof value === 'function') {
      value = value(data);
    }

    return value;
  });
} // @function isArray(obj): Boolean
// Compatibility polyfill for [Array.isArray](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray)

var isArray = Array.isArray || function (obj) {
  return Object.prototype.toString.call(obj) === '[object Array]';
}; // @function indexOf(array: Array, el: Object): Number
// Compatibility polyfill for [Array.prototype.indexOf](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf)

function indexOf(array, el) {
  for (var i = 0; i < array.length; i++) {
    if (array[i] === el) {
      return i;
    }
  }

  return -1;
} // @property emptyImageUrl: String
// Data URI string containing a base64-encoded empty GIF image.
// Used as a hack to free memory from unused images on WebKit-powered
// mobile devices (by setting image `src` to this string).

var emptyImageUrl = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs='; // inspired by http://paulirish.com/2011/requestanimationframe-for-smart-animating/

function getPrefixed(name) {
  return window['webkit' + name] || window['moz' + name] || window['ms' + name];
}

var lastTime = 0; // fallback for IE 7-8

function timeoutDefer(fn) {
  var time = +new Date(),
      timeToCall = Math.max(0, 16 - (time - lastTime));
  lastTime = time + timeToCall;
  return window.setTimeout(fn, timeToCall);
}

var requestFn = window.requestAnimationFrame || getPrefixed('RequestAnimationFrame') || timeoutDefer;
var cancelFn = window.cancelAnimationFrame || getPrefixed('CancelAnimationFrame') || getPrefixed('CancelRequestAnimationFrame') || function (id) {
  window.clearTimeout(id);
}; // @function requestAnimFrame(fn: Function, context?: Object, immediate?: Boolean): Number
// Schedules `fn` to be executed when the browser repaints. `fn` is bound to
// `context` if given. When `immediate` is set, `fn` is called immediately if
// the browser doesn't have native support for
// [`window.requestAnimationFrame`](https://developer.mozilla.org/docs/Web/API/window/requestAnimationFrame),
// otherwise it's delayed. Returns a request ID that can be used to cancel the request.

function requestAnimFrame(fn, context, immediate) {
  if (immediate && requestFn === timeoutDefer) {
    fn.call(context);
  } else {
    return requestFn.call(window, bind(fn, context));
  }
} // @function cancelAnimFrame(id: Number): undefined
// Cancels a previous `requestAnimFrame`. See also [window.cancelAnimationFrame](https://developer.mozilla.org/docs/Web/API/window/cancelAnimationFrame).

function cancelAnimFrame(id) {
  if (id) {
    cancelFn.call(window, id);
  }
}
function inVp(elem) {
  var threshold = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var container = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;

  if (threshold instanceof HTMLElement) {
    container = threshold;
    threshold = {};
  }

  threshold = Object.assign({
    top: 0,
    right: 0,
    bottom: 0,
    left: 0
  }, threshold);
  container = container || document.documentElement; // Get the viewport dimensions

  var vp = {
    width: container.clientWidth,
    height: container.clientHeight
  }; // Get the viewport offset and size of the element.
  // Normailze right and bottom to show offset from their
  // respective edges istead of the top-left edges.

  var box = elem.getBoundingClientRect();
  var top = box.top,
      left = box.left,
      width = box.width,
      height = box.height;
  var right = vp.width - box.right;
  var bottom = vp.height - box.bottom; // Calculate which sides of the element are cut-off
  // by the viewport.

  var cutOff = {
    top: top < threshold.top,
    left: left < threshold.left,
    bottom: bottom < threshold.bottom,
    right: right < threshold.right
  }; // Calculate which sides of the element are partially shown

  var partial = {
    top: cutOff.top && top > -height + threshold.top,
    left: cutOff.left && left > -width + threshold.left,
    bottom: cutOff.bottom && bottom > -height + threshold.bottom,
    right: cutOff.right && right > -width + threshold.right
  };
  var isFullyVisible = top >= threshold.top && right >= threshold.right && bottom >= threshold.bottom && left >= threshold.left;
  var isPartiallyVisible = partial.top || partial.right || partial.bottom || partial.left;
  var elH = elem.offsetHeight;
  var H = container.offsetHeight;
  var percentage = Math.max(0, top > 0 ? Math.min(elH, H - top) : box.bottom < H ? box.bottom : H); // Calculate which edge of the element are visible.
  // Every edge can have three states:
  // - 'fully':     The edge is completely visible.
  // - 'partially': Some part of the edge can be seen.
  // - false:       The edge is not visible at all.

  var edges = {
    top: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.top && !cutOff.left && !cutOff.right && 'fully' || !cutOff.top && 'partially' || false,
    right: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.right && !cutOff.top && !cutOff.bottom && 'fully' || !cutOff.right && 'partially' || false,
    bottom: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.bottom && !cutOff.left && !cutOff.right && 'fully' || !cutOff.bottom && 'partially' || false,
    left: !isFullyVisible && !isPartiallyVisible ? false : !cutOff.left && !cutOff.top && !cutOff.bottom && 'fully' || !cutOff.left && 'partially' || false,
    percentage: percentage
  };
  return {
    fully: isFullyVisible,
    partially: isPartiallyVisible,
    edges: edges
  };
}
var loader = {
  js: function js(url) {
    var handler = {
      _resolved: false
    };
    handler.callbacks = [];
    handler.error = [];

    handler.then = function (cb) {
      handler.callbacks.push(cb);

      if (handler._resolved) {
        return handler.resolve();
      }

      return handler;
    };

    handler["catch"] = function (cb) {
      handler.error.push(cb);

      if (handler._resolved) {
        return handler.reject();
      }

      return handler;
    };

    handler.resolve = function (_argv) {
      // var _argv;
      handler._resolved = true;

      while (handler.callbacks.length) {
        var cb = handler.callbacks.shift();
        var retval;

        try {
          _argv = cb(_argv);
        } catch (e) {
          console.log(e);
          handler.reject(e);
          break;
        }
      }

      return handler;
    };

    handler.reject = function (e) {
      while (handler.error.length) {
        var cb = handler.error.shift();
        cb(e);
      }

      console.log(e);
      console.trace();
      return handler;
    };

    if (url == undefined) {
      handler._resolved = true;
      return handler;
    }

    var element = document.createElement('script');

    element.onload = function () {
      handler.resolve(url);
    };

    element.onerror = function () {
      handler["catch"].apply(arguments);
    };

    element.async = true;
    var parent = 'body';
    var attr = 'src';
    element[attr] = url;
    document[parent].appendChild(element);
    console.log("AHOY APPENDED", url);
    return handler;
  }
};

/***/ }),

/***/ 5123:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "Browser": () => (/* reexport */ Browser),
  "Class": () => (/* reexport */ Class/* Class */.w),
  "Evented": () => (/* reexport */ Events/* Evented */.c),
  "Mixin": () => (/* binding */ Mixin),
  "Util": () => (/* reexport */ Util),
  "bind": () => (/* reexport */ Util.bind),
  "bus": () => (/* reexport */ bus),
  "extend": () => (/* reexport */ Util.extend),
  "inVp": () => (/* reexport */ Util.inVp),
  "setOptions": () => (/* reexport */ Util.setOptions),
  "stamp": () => (/* reexport */ Util.stamp)
});

// EXTERNAL MODULE: ./src/core/Browser.js
var Browser = __webpack_require__(8643);
// EXTERNAL MODULE: ./src/core/Class.js
var Class = __webpack_require__(7573);
// EXTERNAL MODULE: ./src/core/Events.js
var Events = __webpack_require__(1146);
// EXTERNAL MODULE: ./src/core/Util.js
var Util = __webpack_require__(7518);
;// CONCATENATED MODULE: ./src/core/Bus.js

var Bus = Events/* Evented.extend */.c.extend({});
var instance;
var bus = function bus() {
  return instance || (instance = new Bus());
};
;// CONCATENATED MODULE: ./src/core/index.js





var Mixin = {
  Events: Events/* Evented.prototype */.c.prototype
};





/***/ }),

/***/ 5324:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "default": () => (/* binding */ src_cozy)
});

// UNUSED EXPORTS: noConflict

;// CONCATENATED MODULE: ./package.json
const package_namespaceObject = {};
;// CONCATENATED MODULE: ./src/cozy.js
// import {version} from '../package.json';
// export {version};
// // control
// export * from './control/index';
// // core
// export * from './core/index';
// // dom
// export * from './dom/index';
// // reader
// import {reader} from './reader/index';
// export * from './reader/index';
// misc
var oldCozy = window.cozy;
function noConflict() {
  window.cozy = oldCozy;
  return this;
}
var cozy = {}; // cozy.reader = reader;



var control = __webpack_require__(5782);

var core = __webpack_require__(5123);

var dom = __webpack_require__(9804);

var reader = __webpack_require__(4789);

[control, core, dom, reader].forEach(function (m) {
  Object.keys(m).forEach(function (key) {
    cozy[key] = m[key];
  });
});
/* harmony default export */ const src_cozy = (cozy);

/***/ }),

/***/ 975:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "addListener": () => (/* binding */ on),
  "disableClickPropagation": () => (/* binding */ disableClickPropagation),
  "disableScrollPropagation": () => (/* binding */ disableScrollPropagation),
  "fakeStop": () => (/* binding */ fakeStop),
  "getMousePosition": () => (/* binding */ getMousePosition),
  "getWheelDelta": () => (/* binding */ getWheelDelta),
  "isExternalTarget": () => (/* binding */ isExternalTarget),
  "off": () => (/* binding */ off),
  "on": () => (/* binding */ on),
  "preventDefault": () => (/* binding */ preventDefault),
  "removeListener": () => (/* binding */ off),
  "skipped": () => (/* binding */ skipped),
  "stop": () => (/* binding */ stop),
  "stopPropagation": () => (/* binding */ stopPropagation)
});

// EXTERNAL MODULE: ./src/geometry/Point.js
var Point = __webpack_require__(9583);
// EXTERNAL MODULE: ./src/core/Util.js
var Util = __webpack_require__(7518);
// EXTERNAL MODULE: ./src/core/Browser.js
var Browser = __webpack_require__(8643);
;// CONCATENATED MODULE: ./src/dom/DomEvent.Pointer.js



/*
 * Extends L.DomEvent to provide touch support for Internet Explorer and Windows-based devices.
 */

var POINTER_DOWN = Browser.msPointer ? 'MSPointerDown' : 'pointerdown',
    POINTER_MOVE = Browser.msPointer ? 'MSPointerMove' : 'pointermove',
    POINTER_UP = Browser.msPointer ? 'MSPointerUp' : 'pointerup',
    POINTER_CANCEL = Browser.msPointer ? 'MSPointerCancel' : 'pointercancel',
    TAG_WHITE_LIST = ['INPUT', 'SELECT', 'OPTION'],
    _pointers = {},
    _pointerDocListener = false; // DomEvent.DoubleTap needs to know about this

var _pointersCount = 0; // Provides a touch events wrapper for (ms)pointer events.
// ref http://www.w3.org/TR/pointerevents/ https://www.w3.org/Bugs/Public/show_bug.cgi?id=22890

function addPointerListener(obj, type, handler, id) {
  if (type === 'touchstart') {
    _addPointerStart(obj, handler, id);
  } else if (type === 'touchmove') {
    _addPointerMove(obj, handler, id);
  } else if (type === 'touchend') {
    _addPointerEnd(obj, handler, id);
  }

  return this;
}
function removePointerListener(obj, type, id) {
  var handler = obj['_leaflet_' + type + id];

  if (type === 'touchstart') {
    obj.removeEventListener(POINTER_DOWN, handler, false);
  } else if (type === 'touchmove') {
    obj.removeEventListener(POINTER_MOVE, handler, false);
  } else if (type === 'touchend') {
    obj.removeEventListener(POINTER_UP, handler, false);
    obj.removeEventListener(POINTER_CANCEL, handler, false);
  }

  return this;
}

function _addPointerStart(obj, handler, id) {
  var onDown = Util.bind(function (e) {
    if (e.pointerType !== 'mouse' && e.pointerType !== e.MSPOINTER_TYPE_MOUSE && e.pointerType !== e.MSPOINTER_TYPE_MOUSE) {
      // In IE11, some touch events needs to fire for form controls, or
      // the controls will stop working. We keep a whitelist of tag names that
      // need these events. For other target tags, we prevent default on the event.
      if (TAG_WHITE_LIST.indexOf(e.target.tagName) < 0) {
        preventDefault(e);
      } else {
        return;
      }
    }

    _handlePointer(e, handler);
  });
  obj['_leaflet_touchstart' + id] = onDown;
  obj.addEventListener(POINTER_DOWN, onDown, false); // need to keep track of what pointers and how many are active to provide e.touches emulation

  if (!_pointerDocListener) {
    // we listen documentElement as any drags that end by moving the touch off the screen get fired there
    document.documentElement.addEventListener(POINTER_DOWN, _globalPointerDown, true);
    document.documentElement.addEventListener(POINTER_MOVE, _globalPointerMove, true);
    document.documentElement.addEventListener(POINTER_UP, _globalPointerUp, true);
    document.documentElement.addEventListener(POINTER_CANCEL, _globalPointerUp, true);
    _pointerDocListener = true;
  }
}

function _globalPointerDown(e) {
  _pointers[e.pointerId] = e;
  _pointersCount++;
}

function _globalPointerMove(e) {
  if (_pointers[e.pointerId]) {
    _pointers[e.pointerId] = e;
  }
}

function _globalPointerUp(e) {
  delete _pointers[e.pointerId];
  _pointersCount--;
}

function _handlePointer(e, handler) {
  e.touches = [];

  for (var i in _pointers) {
    e.touches.push(_pointers[i]);
  }

  e.changedTouches = [e];
  handler(e);
}

function _addPointerMove(obj, handler, id) {
  var onMove = function onMove(e) {
    // don't fire touch moves when mouse isn't down
    if ((e.pointerType === e.MSPOINTER_TYPE_MOUSE || e.pointerType === 'mouse') && e.buttons === 0) {
      return;
    }

    _handlePointer(e, handler);
  };

  obj['_leaflet_touchmove' + id] = onMove;
  obj.addEventListener(POINTER_MOVE, onMove, false);
}

function _addPointerEnd(obj, handler, id) {
  var onUp = function onUp(e) {
    _handlePointer(e, handler);
  };

  obj['_leaflet_touchend' + id] = onUp;
  obj.addEventListener(POINTER_UP, onUp, false);
  obj.addEventListener(POINTER_CANCEL, onUp, false);
}
;// CONCATENATED MODULE: ./src/dom/DomEvent.DoubleTap.js


/*
 * Extends the event handling code with double tap support for mobile browsers.
 */

var _touchstart = Browser.msPointer ? 'MSPointerDown' : Browser.pointer ? 'pointerdown' : 'touchstart',
    _touchend = Browser.msPointer ? 'MSPointerUp' : Browser.pointer ? 'pointerup' : 'touchend',
    _pre = '_leaflet_'; // inspired by Zepto touch code by Thomas Fuchs


function addDoubleTapListener(obj, handler, id) {
  var last,
      touch,
      doubleTap = false,
      delay = 250;

  function onTouchStart(e) {
    var count;

    if (Browser.pointer) {
      if (!Browser.edge || e.pointerType === 'mouse') {
        return;
      }

      count = _pointersCount;
    } else {
      count = e.touches.length;
    }

    if (count > 1) {
      return;
    }

    var now = Date.now(),
        delta = now - (last || now);
    touch = e.touches ? e.touches[0] : e;
    doubleTap = delta > 0 && delta <= delay;
    last = now;
  }

  function onTouchEnd(e) {
    if (doubleTap && !touch.cancelBubble) {
      if (Browser.pointer) {
        if (!Browser.edge || e.pointerType === 'mouse') {
          return;
        } // work around .type being readonly with MSPointer* events


        var newTouch = {},
            prop,
            i;

        for (i in touch) {
          prop = touch[i];
          newTouch[i] = prop && prop.bind ? prop.bind(touch) : prop;
        }

        touch = newTouch;
      }

      touch.type = 'dblclick';
      handler(touch);
      last = null;
    }
  }

  obj[_pre + _touchstart + id] = onTouchStart;
  obj[_pre + _touchend + id] = onTouchEnd;
  obj[_pre + 'dblclick' + id] = handler;
  obj.addEventListener(_touchstart, onTouchStart, false);
  obj.addEventListener(_touchend, onTouchEnd, false); // On some platforms (notably, chrome<55 on win10 + touchscreen + mouse),
  // the browser doesn't fire touchend/pointerup events but does fire
  // native dblclicks. See #4127.
  // Edge 14 also fires native dblclicks, but only for pointerType mouse, see #5180.

  obj.addEventListener('dblclick', handler, false);
  return this;
}
function removeDoubleTapListener(obj, id) {
  var touchstart = obj[_pre + _touchstart + id],
      touchend = obj[_pre + _touchend + id],
      dblclick = obj[_pre + 'dblclick' + id];
  obj.removeEventListener(_touchstart, touchstart, false);
  obj.removeEventListener(_touchend, touchend, false);

  if (!Browser.edge) {
    obj.removeEventListener('dblclick', dblclick, false);
  }

  return this;
}
;// CONCATENATED MODULE: ./src/dom/DomEvent.js
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }






/*
 * @namespace DomEvent
 * Utility functions to work with the [DOM events](https://developer.mozilla.org/docs/Web/API/Event), used by Leaflet internally.
 */
// Inspired by John Resig, Dean Edwards and YUI addEvent implementations.
// @function on(el: HTMLElement, types: String, fn: Function, context?: Object): this
// Adds a listener function (`fn`) to a particular DOM event type of the
// element `el`. You can optionally specify the context of the listener
// (object the `this` keyword will point to). You can also pass several
// space-separated types (e.g. `'click dblclick'`).
// @alternative
// @function on(el: HTMLElement, eventMap: Object, context?: Object): this
// Adds a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`

function on(obj, types, fn, context) {
  if (_typeof(types) === 'object') {
    for (var type in types) {
      addOne(obj, type, types[type], fn);
    }
  } else {
    types = Util.splitWords(types);

    for (var i = 0, len = types.length; i < len; i++) {
      addOne(obj, types[i], fn, context);
    }
  }

  return this;
}
var eventsKey = '_leaflet_events'; // @function off(el: HTMLElement, types: String, fn: Function, context?: Object): this
// Removes a previously added listener function. If no function is specified,
// it will remove all the listeners of that particular DOM event from the element.
// Note that if you passed a custom context to on, you must pass the same
// context to `off` in order to remove the listener.
// @alternative
// @function off(el: HTMLElement, eventMap: Object, context?: Object): this
// Removes a set of type/listener pairs, e.g. `{click: onClick, mousemove: onMouseMove}`
// @alternative
// @function off(el: HTMLElement): this
// Removes all known event listeners

function off(obj, types, fn, context) {
  if (_typeof(types) === 'object') {
    for (var type in types) {
      removeOne(obj, type, types[type], fn);
    }
  } else if (types) {
    types = Util.splitWords(types);

    for (var i = 0, len = types.length; i < len; i++) {
      removeOne(obj, types[i], fn, context);
    }
  } else {
    for (var j in obj[eventsKey]) {
      removeOne(obj, j, obj[eventsKey][j]);
    }

    delete obj[eventsKey];
  }
}

function addOne(obj, type, fn, context) {
  var id = type + Util.stamp(fn) + (context ? '_' + Util.stamp(context) : '');

  if (obj[eventsKey] && obj[eventsKey][id]) {
    return this;
  }

  var handler = function handler(e) {
    return fn.call(context || obj, e || window.event);
  };

  var originalHandler = handler;

  if (Browser.pointer && type.indexOf('touch') === 0) {
    // Needs DomEvent.Pointer.js
    addPointerListener(obj, type, handler, id);
  } else if (Browser.touch && type === 'dblclick' && addDoubleTapListener && !(Browser.pointer && Browser.chrome)) {
    // Chrome >55 does not need the synthetic dblclicks from addDoubleTapListener
    // See #5180
    addDoubleTapListener(obj, handler, id);
  } else if ('addEventListener' in obj) {
    if (type === 'mousewheel') {
      obj.addEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);
    } else if (type === 'mouseenter' || type === 'mouseleave') {
      handler = function handler(e) {
        e = e || window.event;

        if (isExternalTarget(obj, e)) {
          originalHandler(e);
        }
      };

      obj.addEventListener(type === 'mouseenter' ? 'mouseover' : 'mouseout', handler, false);
    } else {
      if (type === 'click' && Browser.android) {
        handler = function handler(e) {
          filterClick(e, originalHandler);
        };
      }

      obj.addEventListener(type, handler, false);
    }
  } else if ('attachEvent' in obj) {
    obj.attachEvent('on' + type, handler);
  }

  obj[eventsKey] = obj[eventsKey] || {};
  obj[eventsKey][id] = handler;
}

function removeOne(obj, type, fn, context) {
  var id = type + Util.stamp(fn) + (context ? '_' + Util.stamp(context) : ''),
      handler = obj[eventsKey] && obj[eventsKey][id];

  if (!handler) {
    return this;
  }

  if (Browser.pointer && type.indexOf('touch') === 0) {
    removePointerListener(obj, type, id);
  } else if (Browser.touch && type === 'dblclick' && removeDoubleTapListener) {
    removeDoubleTapListener(obj, id);
  } else if ('removeEventListener' in obj) {
    if (type === 'mousewheel') {
      obj.removeEventListener('onwheel' in obj ? 'wheel' : 'mousewheel', handler, false);
    } else {
      obj.removeEventListener(type === 'mouseenter' ? 'mouseover' : type === 'mouseleave' ? 'mouseout' : type, handler, false);
    }
  } else if ('detachEvent' in obj) {
    obj.detachEvent('on' + type, handler);
  }

  obj[eventsKey][id] = null;
} // @function stopPropagation(ev: DOMEvent): this
// Stop the given event from propagation to parent elements. Used inside the listener functions:
// ```js
// L.DomEvent.on(div, 'click', function (ev) {
// 	L.DomEvent.stopPropagation(ev);
// });
// ```


function stopPropagation(e) {
  if (e.stopPropagation) {
    e.stopPropagation();
  } else if (e.originalEvent) {
    // In case of Leaflet event.
    e.originalEvent._stopped = true;
  } else {
    e.cancelBubble = true;
  }

  skipped(e);
  return this;
} // @function disableScrollPropagation(el: HTMLElement): this
// Adds `stopPropagation` to the element's `'mousewheel'` events (plus browser variants).

function disableScrollPropagation(el) {
  return addOne(el, 'mousewheel', stopPropagation);
} // @function disableClickPropagation(el: HTMLElement): this
// Adds `stopPropagation` to the element's `'click'`, `'doubleclick'`,
// `'mousedown'` and `'touchstart'` events (plus browser variants).

function disableClickPropagation(el) {
  on(el, 'mousedown touchstart dblclick', stopPropagation);
  addOne(el, 'click', fakeStop);
  return this;
} // @function preventDefault(ev: DOMEvent): this
// Prevents the default action of the DOM Event `ev` from happening (such as
// following a link in the href of the a element, or doing a POST request
// with page reload when a `<form>` is submitted).
// Use it inside listener functions.

function preventDefault(e) {
  if (e.preventDefault) {
    e.preventDefault();
  } else {
    e.returnValue = false;
  }

  return this;
} // @function stop(ev): this
// Does `stopPropagation` and `preventDefault` at the same time.

function stop(e) {
  preventDefault(e);
  stopPropagation(e);
  return this;
} // @function getMousePosition(ev: DOMEvent, container?: HTMLElement): Point
// Gets normalized mouse position from a DOM event relative to the
// `container` or to the whole page if not specified.

function getMousePosition(e, container) {
  if (!container) {
    return new Point/* Point */.E(e.clientX, e.clientY);
  }

  var rect = container.getBoundingClientRect();
  return new Point/* Point */.E(e.clientX - rect.left - container.clientLeft, e.clientY - rect.top - container.clientTop);
} // Chrome on Win scrolls double the pixels as in other platforms (see #4538),
// and Firefox scrolls device pixels, not CSS pixels

var wheelPxFactor = Browser.win && Browser.chrome ? 2 : Browser.gecko ? window.devicePixelRatio : 1; // @function getWheelDelta(ev: DOMEvent): Number
// Gets normalized wheel delta from a mousewheel DOM event, in vertical
// pixels scrolled (negative if scrolling down).
// Events from pointing devices without precise scrolling are mapped to
// a best guess of 60 pixels.

function getWheelDelta(e) {
  return Browser.edge ? e.wheelDeltaY / 2 : // Don't trust window-geometry-based delta
  e.deltaY && e.deltaMode === 0 ? -e.deltaY / wheelPxFactor : // Pixels
  e.deltaY && e.deltaMode === 1 ? -e.deltaY * 20 : // Lines
  e.deltaY && e.deltaMode === 2 ? -e.deltaY * 60 : // Pages
  e.deltaX || e.deltaZ ? 0 : // Skip horizontal/depth wheel events
  e.wheelDelta ? (e.wheelDeltaY || e.wheelDelta) / 2 : // Legacy IE pixels
  e.detail && Math.abs(e.detail) < 32765 ? -e.detail * 20 : // Legacy Moz lines
  e.detail ? e.detail / -32765 * 60 : // Legacy Moz pages
  0;
}
var skipEvents = {};
function fakeStop(e) {
  // fakes stopPropagation by setting a special event flag, checked/reset with skipped(e)
  skipEvents[e.type] = true;
}
function skipped(e) {
  var events = skipEvents[e.type]; // reset when checking, as it's only used in map container and propagates outside of the map

  skipEvents[e.type] = false;
  return events;
} // check if element really left/entered the event target (for mouseenter/mouseleave)

function isExternalTarget(el, e) {
  var related = e.relatedTarget;

  if (!related) {
    return true;
  }

  try {
    while (related && related !== el) {
      related = related.parentNode;
    }
  } catch (err) {
    return false;
  }

  return related !== el;
}
var lastClick; // this is a horrible workaround for a bug in Android where a single touch triggers two click events

function filterClick(e, handler) {
  var timeStamp = e.timeStamp || e.originalEvent && e.originalEvent.timeStamp,
      elapsed = lastClick && timeStamp - lastClick; // are they closer together than 500ms yet more than 100ms?
  // Android typically triggers them ~300ms apart while multiple listeners
  // on the same event should be triggered far faster;
  // or check if click is simulated on the element, and if it is, reject any non-simulated events

  if (elapsed && elapsed > 100 && elapsed < 500 || e.target._simulatedClick && !e._simulated) {
    stop(e);
    return;
  }

  lastClick = timeStamp;
  handler(e);
} // @function addListener(…): this
// Alias to [`L.DomEvent.on`](#domevent-on)


 // @function removeListener(…): this
// Alias to [`L.DomEvent.off`](#domevent-off)



/***/ }),

/***/ 9542:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "TRANSFORM": () => (/* binding */ TRANSFORM),
/* harmony export */   "TRANSITION": () => (/* binding */ TRANSITION),
/* harmony export */   "TRANSITION_END": () => (/* binding */ TRANSITION_END),
/* harmony export */   "get": () => (/* binding */ get),
/* harmony export */   "getStyle": () => (/* binding */ getStyle),
/* harmony export */   "create": () => (/* binding */ create),
/* harmony export */   "remove": () => (/* binding */ remove),
/* harmony export */   "empty": () => (/* binding */ empty),
/* harmony export */   "toFront": () => (/* binding */ toFront),
/* harmony export */   "toBack": () => (/* binding */ toBack),
/* harmony export */   "hasClass": () => (/* binding */ hasClass),
/* harmony export */   "addClass": () => (/* binding */ addClass),
/* harmony export */   "removeClass": () => (/* binding */ removeClass),
/* harmony export */   "setClass": () => (/* binding */ setClass),
/* harmony export */   "getClass": () => (/* binding */ getClass),
/* harmony export */   "setOpacity": () => (/* binding */ setOpacity),
/* harmony export */   "testProp": () => (/* binding */ testProp),
/* harmony export */   "isPropertySupported": () => (/* binding */ isPropertySupported),
/* harmony export */   "setTransform": () => (/* binding */ setTransform),
/* harmony export */   "setPosition": () => (/* binding */ setPosition),
/* harmony export */   "getPosition": () => (/* binding */ getPosition),
/* harmony export */   "disableTextSelection": () => (/* binding */ disableTextSelection),
/* harmony export */   "enableTextSelection": () => (/* binding */ enableTextSelection),
/* harmony export */   "disableImageDrag": () => (/* binding */ disableImageDrag),
/* harmony export */   "enableImageDrag": () => (/* binding */ enableImageDrag),
/* harmony export */   "preventOutline": () => (/* binding */ preventOutline),
/* harmony export */   "restoreOutline": () => (/* binding */ restoreOutline)
/* harmony export */ });
/* harmony import */ var _DomEvent__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(975);
/* harmony import */ var _core_Util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(7518);
/* harmony import */ var _geometry_Point__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(9583);
/* harmony import */ var _core_Browser__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(8643);




/*
 * @namespace DomUtil
 *
 * Utility functions to work with the [DOM](https://developer.mozilla.org/docs/Web/API/Document_Object_Model)
 * tree, used by Leaflet internally.
 *
 * Most functions expecting or returning a `HTMLElement` also work for
 * SVG elements. The only difference is that classes refer to CSS classes
 * in HTML and SVG classes in SVG.
 */

if (!Element.prototype.matches) {
  var ep = Element.prototype;
  if (ep.webkitMatchesSelector) // Chrome <34, SF<7.1, iOS<8
    ep.matches = ep.webkitMatchesSelector;
  if (ep.msMatchesSelector) // IE9/10/11 & Edge
    ep.matches = ep.msMatchesSelector;
  if (ep.mozMatchesSelector) // FF<34
    ep.matches = ep.mozMatchesSelector;
} // @property TRANSFORM: String
// Vendor-prefixed fransform style name (e.g. `'webkitTransform'` for WebKit).


var TRANSFORM = testProp(['transform', 'WebkitTransform', 'OTransform', 'MozTransform', 'msTransform']); // webkitTransition comes first because some browser versions that drop vendor prefix don't do
// the same for the transitionend event, in particular the Android 4.1 stock browser
// @property TRANSITION: String
// Vendor-prefixed transform style name.

var TRANSITION = testProp(['webkitTransition', 'transition', 'OTransition', 'MozTransition', 'msTransition']);
var TRANSITION_END = TRANSITION === 'webkitTransition' || TRANSITION === 'OTransition' ? TRANSITION + 'End' : 'transitionend'; // @function get(id: String|HTMLElement): HTMLElement
// Returns an element given its DOM id, or returns the element itself
// if it was passed directly.

function get(id) {
  return typeof id === 'string' ? document.getElementById(id) : id;
} // @function getStyle(el: HTMLElement, styleAttrib: String): String
// Returns the value for a certain style attribute on an element,
// including computed values or values set through CSS.

function getStyle(el, style) {
  var value = el.style[style] || el.currentStyle && el.currentStyle[style];

  if ((!value || value === 'auto') && document.defaultView) {
    var css = document.defaultView.getComputedStyle(el, null);
    value = css ? css[style] : null;
  }

  return value === 'auto' ? null : value;
} // @function create(tagName: String, className?: String, container?: HTMLElement): HTMLElement
// Creates an HTML element with `tagName`, sets its class to `className`, and optionally appends it to `container` element.

function create(tagName, className, container) {
  var el = document.createElement(tagName);
  el.className = className || '';

  if (container) {
    container.appendChild(el);
  }

  return el;
} // @function remove(el: HTMLElement)
// Removes `el` from its parent element

function remove(el) {
  var parent = el.parentNode;

  if (parent) {
    parent.removeChild(el);
  }
} // @function empty(el: HTMLElement)
// Removes all of `el`'s children elements from `el`

function empty(el) {
  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
} // @function toFront(el: HTMLElement)
// Makes `el` the last child of its parent, so it renders in front of the other children.

function toFront(el) {
  el.parentNode.appendChild(el);
} // @function toBack(el: HTMLElement)
// Makes `el` the first child of its parent, so it renders behind the other children.

function toBack(el) {
  var parent = el.parentNode;
  parent.insertBefore(el, parent.firstChild);
} // @function hasClass(el: HTMLElement, name: String): Boolean
// Returns `true` if the element's class attribute contains `name`.

function hasClass(el, name) {
  if (el.classList !== undefined) {
    return el.classList.contains(name);
  }

  var className = getClass(el);
  return className.length > 0 && new RegExp('(^|\\s)' + name + '(\\s|$)').test(className);
} // @function addClass(el: HTMLElement, name: String)
// Adds `name` to the element's class attribute.

function addClass(el, name) {
  if (el.classList !== undefined) {
    var classes = _core_Util__WEBPACK_IMPORTED_MODULE_1__.splitWords(name);

    for (var i = 0, len = classes.length; i < len; i++) {
      el.classList.add(classes[i]);
    }
  } else if (!hasClass(el, name)) {
    var className = getClass(el);
    setClass(el, (className ? className + ' ' : '') + name);
  }
} // @function removeClass(el: HTMLElement, name: String)
// Removes `name` from the element's class attribute.

function removeClass(el, name) {
  if (el.classList !== undefined) {
    el.classList.remove(name);
  } else {
    setClass(el, _core_Util__WEBPACK_IMPORTED_MODULE_1__.trim((' ' + getClass(el) + ' ').replace(' ' + name + ' ', ' ')));
  }
} // @function setClass(el: HTMLElement, name: String)
// Sets the element's class.

function setClass(el, name) {
  if (el.className.baseVal === undefined) {
    el.className = name;
  } else {
    // in case of SVG element
    el.className.baseVal = name;
  }
} // @function getClass(el: HTMLElement): String
// Returns the element's class.

function getClass(el) {
  return el.className.baseVal === undefined ? el.className : el.className.baseVal;
} // @function setOpacity(el: HTMLElement, opacity: Number)
// Set the opacity of an element (including old IE support).
// `opacity` must be a number from `0` to `1`.

function setOpacity(el, value) {
  if ('opacity' in el.style) {
    el.style.opacity = value;
  } else if ('filter' in el.style) {
    _setOpacityIE(el, value);
  }
}

function _setOpacityIE(el, value) {
  var filter = false,
      filterName = 'DXImageTransform.Microsoft.Alpha'; // filters collection throws an error if we try to retrieve a filter that doesn't exist

  try {
    filter = el.filters.item(filterName);
  } catch (e) {
    // don't set opacity to 1 if we haven't already set an opacity,
    // it isn't needed and breaks transparent pngs.
    if (value === 1) {
      return;
    }
  }

  value = Math.round(value * 100);

  if (filter) {
    filter.Enabled = value !== 100;
    filter.Opacity = value;
  } else {
    el.style.filter += ' progid:' + filterName + '(opacity=' + value + ')';
  }
} // @function testProp(props: String[]): String|false
// Goes through the array of style names and returns the first name
// that is a valid style name for an element. If no such name is found,
// it returns false. Useful for vendor-prefixed styles like `transform`.


function testProp(props) {
  var style = document.documentElement.style;

  for (var i = 0; i < props.length; i++) {
    if (props[i] in style) {
      return props[i];
    }
  }

  return false;
}
function isPropertySupported(prop) {
  var style = document.documentElement.style;
  return prop in style;
} // @function setTransform(el: HTMLElement, offset: Point, scale?: Number)
// Resets the 3D CSS transform of `el` so it is translated by `offset` pixels
// and optionally scaled by `scale`. Does not have an effect if the
// browser doesn't support 3D CSS transforms.

function setTransform(el, offset, scale) {
  var pos = offset || new _geometry_Point__WEBPACK_IMPORTED_MODULE_2__/* .Point */ .E(0, 0);
  el.style[TRANSFORM] = (_core_Browser__WEBPACK_IMPORTED_MODULE_3__.ie3d ? 'translate(' + pos.x + 'px,' + pos.y + 'px)' : 'translate3d(' + pos.x + 'px,' + pos.y + 'px,0)') + (scale ? ' scale(' + scale + ')' : '');
} // @function setPosition(el: HTMLElement, position: Point)
// Sets the position of `el` to coordinates specified by `position`,
// using CSS translate or top/left positioning depending on the browser
// (used by Leaflet internally to position its layers).

function setPosition(el, point) {
  /*eslint-disable */
  el._leaflet_pos = point;
  /*eslint-enable */

  if (_core_Browser__WEBPACK_IMPORTED_MODULE_3__.any3d) {
    setTransform(el, point);
  } else {
    el.style.left = point.x + 'px';
    el.style.top = point.y + 'px';
  }
} // @function getPosition(el: HTMLElement): Point
// Returns the coordinates of an element previously positioned with setPosition.

function getPosition(el) {
  // this method is only used for elements previously positioned using setPosition,
  // so it's safe to cache the position for performance
  return el._leaflet_pos || new _geometry_Point__WEBPACK_IMPORTED_MODULE_2__/* .Point */ .E(0, 0);
} // @function disableTextSelection()
// Prevents the user from generating `selectstart` DOM events, usually generated
// when the user drags the mouse through a page with text. Used internally
// by Leaflet to override the behaviour of any click-and-drag interaction on
// the map. Affects drag interactions on the whole document.
// @function enableTextSelection()
// Cancels the effects of a previous [`L.DomUtil.disableTextSelection`](#domutil-disabletextselection).

var disableTextSelection;
var enableTextSelection;

var _userSelect;

if ('onselectstart' in document) {
  disableTextSelection = function disableTextSelection() {
    _DomEvent__WEBPACK_IMPORTED_MODULE_0__.on(window, 'selectstart', _DomEvent__WEBPACK_IMPORTED_MODULE_0__.preventDefault);
  };

  enableTextSelection = function enableTextSelection() {
    _DomEvent__WEBPACK_IMPORTED_MODULE_0__.off(window, 'selectstart', _DomEvent__WEBPACK_IMPORTED_MODULE_0__.preventDefault);
  };
} else {
  var userSelectProperty = testProp(['userSelect', 'WebkitUserSelect', 'OUserSelect', 'MozUserSelect', 'msUserSelect']);

  disableTextSelection = function disableTextSelection() {
    if (userSelectProperty) {
      var style = document.documentElement.style;
      _userSelect = style[userSelectProperty];
      style[userSelectProperty] = 'none';
    }
  };

  enableTextSelection = function enableTextSelection() {
    if (userSelectProperty) {
      document.documentElement.style[userSelectProperty] = _userSelect;
      _userSelect = undefined;
    }
  };
} // @function disableImageDrag()
// As [`L.DomUtil.disableTextSelection`](#domutil-disabletextselection), but
// for `dragstart` DOM events, usually generated when the user drags an image.


function disableImageDrag() {
  _DomEvent__WEBPACK_IMPORTED_MODULE_0__.on(window, 'dragstart', _DomEvent__WEBPACK_IMPORTED_MODULE_0__.preventDefault);
} // @function enableImageDrag()
// Cancels the effects of a previous [`L.DomUtil.disableImageDrag`](#domutil-disabletextselection).

function enableImageDrag() {
  _DomEvent__WEBPACK_IMPORTED_MODULE_0__.off(window, 'dragstart', _DomEvent__WEBPACK_IMPORTED_MODULE_0__.preventDefault);
}

var _outlineElement, _outlineStyle; // @function preventOutline(el: HTMLElement)
// Makes the [outline](https://developer.mozilla.org/docs/Web/CSS/outline)
// of the element `el` invisible. Used internally by Leaflet to prevent
// focusable elements from displaying an outline when the user performs a
// drag interaction on them.


function preventOutline(element) {
  while (element.tabIndex === -1) {
    element = element.parentNode;
  }

  if (!element || !element.style) {
    return;
  }

  restoreOutline();
  _outlineElement = element;
  _outlineStyle = element.style.outline;
  element.style.outline = 'none';
  _DomEvent__WEBPACK_IMPORTED_MODULE_0__.on(window, 'keydown', restoreOutline);
} // @function restoreOutline()
// Cancels the effects of a previous [`L.DomUtil.preventOutline`]().

function restoreOutline() {
  if (!_outlineElement) {
    return;
  }

  _outlineElement.style.outline = _outlineStyle;
  _outlineElement = undefined;
  _outlineStyle = undefined;
  _DomEvent__WEBPACK_IMPORTED_MODULE_0__.off(window, 'keydown', restoreOutline);
}

/***/ }),

/***/ 9804:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "DomEvent": () => (/* reexport module object */ _DomEvent__WEBPACK_IMPORTED_MODULE_0__),
/* harmony export */   "DomUtil": () => (/* reexport module object */ _DomUtil__WEBPACK_IMPORTED_MODULE_1__)
/* harmony export */ });
/* harmony import */ var _DomEvent__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(975);
/* harmony import */ var _DomUtil__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(9542);





/***/ }),

/***/ 9583:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "E": () => (/* binding */ Point)
/* harmony export */ });
/* unused harmony export toPoint */
/* harmony import */ var _core_Util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(7518);
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }


/*
 * @class Point
 * @aka L.Point
 *
 * Represents a point with `x` and `y` coordinates in pixels.
 *
 * @example
 *
 * ```js
 * var point = L.point(200, 300);
 * ```
 *
 * All Leaflet methods and options that accept `Point` objects also accept them in a simple Array form (unless noted otherwise), so these lines are equivalent:
 *
 * ```js
 * map.panBy([200, 300]);
 * map.panBy(L.point(200, 300));
 * ```
 */

function Point(x, y, round) {
  // @property x: Number; The `x` coordinate of the point
  this.x = round ? Math.round(x) : x; // @property y: Number; The `y` coordinate of the point

  this.y = round ? Math.round(y) : y;
}
Point.prototype = {
  // @method clone(): Point
  // Returns a copy of the current point.
  clone: function clone() {
    return new Point(this.x, this.y);
  },
  // @method add(otherPoint: Point): Point
  // Returns the result of addition of the current and the given points.
  add: function add(point) {
    // non-destructive, returns a new point
    return this.clone()._add(toPoint(point));
  },
  _add: function _add(point) {
    // destructive, used directly for performance in situations where it's safe to modify existing point
    this.x += point.x;
    this.y += point.y;
    return this;
  },
  // @method subtract(otherPoint: Point): Point
  // Returns the result of subtraction of the given point from the current.
  subtract: function subtract(point) {
    return this.clone()._subtract(toPoint(point));
  },
  _subtract: function _subtract(point) {
    this.x -= point.x;
    this.y -= point.y;
    return this;
  },
  // @method divideBy(num: Number): Point
  // Returns the result of division of the current point by the given number.
  divideBy: function divideBy(num) {
    return this.clone()._divideBy(num);
  },
  _divideBy: function _divideBy(num) {
    this.x /= num;
    this.y /= num;
    return this;
  },
  // @method multiplyBy(num: Number): Point
  // Returns the result of multiplication of the current point by the given number.
  multiplyBy: function multiplyBy(num) {
    return this.clone()._multiplyBy(num);
  },
  _multiplyBy: function _multiplyBy(num) {
    this.x *= num;
    this.y *= num;
    return this;
  },
  // @method scaleBy(scale: Point): Point
  // Multiply each coordinate of the current point by each coordinate of
  // `scale`. In linear algebra terms, multiply the point by the
  // [scaling matrix](https://en.wikipedia.org/wiki/Scaling_%28geometry%29#Matrix_representation)
  // defined by `scale`.
  scaleBy: function scaleBy(point) {
    return new Point(this.x * point.x, this.y * point.y);
  },
  // @method unscaleBy(scale: Point): Point
  // Inverse of `scaleBy`. Divide each coordinate of the current point by
  // each coordinate of `scale`.
  unscaleBy: function unscaleBy(point) {
    return new Point(this.x / point.x, this.y / point.y);
  },
  // @method round(): Point
  // Returns a copy of the current point with rounded coordinates.
  round: function round() {
    return this.clone()._round();
  },
  _round: function _round() {
    this.x = Math.round(this.x);
    this.y = Math.round(this.y);
    return this;
  },
  // @method floor(): Point
  // Returns a copy of the current point with floored coordinates (rounded down).
  floor: function floor() {
    return this.clone()._floor();
  },
  _floor: function _floor() {
    this.x = Math.floor(this.x);
    this.y = Math.floor(this.y);
    return this;
  },
  // @method ceil(): Point
  // Returns a copy of the current point with ceiled coordinates (rounded up).
  ceil: function ceil() {
    return this.clone()._ceil();
  },
  _ceil: function _ceil() {
    this.x = Math.ceil(this.x);
    this.y = Math.ceil(this.y);
    return this;
  },
  // @method distanceTo(otherPoint: Point): Number
  // Returns the cartesian distance between the current and the given points.
  distanceTo: function distanceTo(point) {
    point = toPoint(point);
    var x = point.x - this.x,
        y = point.y - this.y;
    return Math.sqrt(x * x + y * y);
  },
  // @method equals(otherPoint: Point): Boolean
  // Returns `true` if the given point has the same coordinates.
  equals: function equals(point) {
    point = toPoint(point);
    return point.x === this.x && point.y === this.y;
  },
  // @method contains(otherPoint: Point): Boolean
  // Returns `true` if both coordinates of the given point are less than the corresponding current point coordinates (in absolute values).
  contains: function contains(point) {
    point = toPoint(point);
    return Math.abs(point.x) <= Math.abs(this.x) && Math.abs(point.y) <= Math.abs(this.y);
  },
  // @method toString(): String
  // Returns a string representation of the point for debugging purposes.
  toString: function toString() {
    return 'Point(' + (0,_core_Util__WEBPACK_IMPORTED_MODULE_0__.formatNum)(this.x) + ', ' + (0,_core_Util__WEBPACK_IMPORTED_MODULE_0__.formatNum)(this.y) + ')';
  }
}; // @factory L.point(x: Number, y: Number, round?: Boolean)
// Creates a Point object with the given `x` and `y` coordinates. If optional `round` is set to true, rounds the `x` and `y` values.
// @alternative
// @factory L.point(coords: Number[])
// Expects an array of the form `[x, y]` instead.
// @alternative
// @factory L.point(coords: Object)
// Expects a plain object of the form `{x: Number, y: Number}` instead.

function toPoint(x, y, round) {
  if (x instanceof Point) {
    return x;
  }

  if ((0,_core_Util__WEBPACK_IMPORTED_MODULE_0__.isArray)(x)) {
    return new Point(x[0], x[1]);
  }

  if (x === undefined || x === null) {
    return x;
  }

  if (_typeof(x) === 'object' && 'x' in x && 'y' in x) {
    return new Point(x.x, x.y);
  }

  return new Point(x, y, round);
}

/***/ }),

/***/ 8399:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "E": () => (/* binding */ Reader)
});

// UNUSED EXPORTS: createReader

// EXTERNAL MODULE: ./src/core/Util.js
var Util = __webpack_require__(7518);
// EXTERNAL MODULE: ./src/core/Events.js
var Events = __webpack_require__(1146);
// EXTERNAL MODULE: ./src/core/Browser.js
var Browser = __webpack_require__(8643);
// EXTERNAL MODULE: ./src/dom/DomEvent.js + 2 modules
var DomEvent = __webpack_require__(975);
// EXTERNAL MODULE: ./src/dom/DomUtil.js
var DomUtil = __webpack_require__(9542);
// EXTERNAL MODULE: ./node_modules/lodash/debounce.js
var debounce = __webpack_require__(3279);
// EXTERNAL MODULE: ./node_modules/lodash/assign.js
var lodash_assign = __webpack_require__(8583);
var assign_default = /*#__PURE__*/__webpack_require__.n(lodash_assign);
;// CONCATENATED MODULE: ./src/screenfull.js
var screenfull_document = typeof window !== 'undefined' && typeof window.document !== 'undefined' ? window.document : {};
var keyboardAllowed = typeof Element !== 'undefined' && 'ALLOW_KEYBOARD_INPUT' in Element;

var fn = function () {
  var val;
  var fnMap = [['requestFullscreen', 'exitFullscreen', 'fullscreenElement', 'fullscreenEnabled', 'fullscreenchange', 'fullscreenerror'], // New WebKit
  ['webkitRequestFullscreen', 'webkitExitFullscreen', 'webkitFullscreenElement', 'webkitFullscreenEnabled', 'webkitfullscreenchange', 'webkitfullscreenerror'], // Old WebKit (Safari 5.1)
  ['webkitRequestFullScreen', 'webkitCancelFullScreen', 'webkitCurrentFullScreenElement', 'webkitCancelFullScreen', 'webkitfullscreenchange', 'webkitfullscreenerror'], ['mozRequestFullScreen', 'mozCancelFullScreen', 'mozFullScreenElement', 'mozFullScreenEnabled', 'mozfullscreenchange', 'mozfullscreenerror'], ['msRequestFullscreen', 'msExitFullscreen', 'msFullscreenElement', 'msFullscreenEnabled', 'MSFullscreenChange', 'MSFullscreenError']];
  var i = 0;
  var l = fnMap.length;
  var ret = {};

  for (; i < l; i++) {
    val = fnMap[i];

    if (val && val[1] in screenfull_document) {
      for (i = 0; i < val.length; i++) {
        ret[fnMap[0][i]] = val[i];
      }

      return ret;
    }
  }

  return false;
}();

var eventNameMap = {
  change: fn.fullscreenchange,
  error: fn.fullscreenerror
};
var screenfull = {
  request: function request(elem) {
    var request = fn.requestFullscreen;
    elem = elem || screenfull_document.documentElement; // Work around Safari 5.1 bug: reports support for
    // keyboard in fullscreen even though it doesn't.
    // Browser sniffing, since the alternative with
    // setTimeout is even worse.

    if (/5\.1[.\d]* Safari/.test(navigator.userAgent)) {
      elem[request]();
    } else {
      elem[request](keyboardAllowed ? Element.ALLOW_KEYBOARD_INPUT : {});
    }
  },
  exit: function exit() {
    screenfull_document[fn.exitFullscreen]();
  },
  toggle: function toggle(elem) {
    if (this.isFullscreen) {
      this.exit();
    } else {
      this.request(elem);
    }
  },
  onchange: function onchange(callback) {
    this.on('change', callback);
  },
  onerror: function onerror(callback) {
    this.on('error', callback);
  },
  on: function on(event, callback) {
    var eventName = eventNameMap[event];

    if (eventName) {
      screenfull_document.addEventListener(eventName, callback, false);
    }
  },
  off: function off(event, callback) {
    var eventName = eventNameMap[event];

    if (eventName) {
      screenfull_document.removeEventListener(eventName, callback, false);
    }
  },
  raw: fn
};
Object.defineProperties(screenfull, {
  isFullscreen: {
    get: function get() {
      return Boolean(screenfull_document[fn.fullscreenElement]);
    }
  },
  element: {
    enumerable: true,
    get: function get() {
      return screenfull_document[fn.fullscreenElement];
    }
  },
  enabled: {
    enumerable: true,
    get: function get() {
      // Coerce to boolean in case of old WebKit
      return Boolean(screenfull_document[fn.fullscreenEnabled]);
    }
  }
});

;// CONCATENATED MODULE: ./src/reader/Reader.js

 // import {Class} from '../core/Class';







/*
 * @class Reader
 * @aka cozy.Map
 * @inherits Evented
 *
 * The central class of the API — it is used to create a book on a page and manipulate it.
 *
 * @example
 *
 * ```js
 * // initialize the map on the "map" div with a given center and zoom
 * var map = L.map('map', {
 *  center: [51.505, -0.09],
 *  zoom: 13
 * });
 * ```
 *
 */

var _padding = 1.0;
var Reader = Events/* Evented.extend */.c.extend({
  options: {
    regions: ['header', 'toolbar.top', 'toolbar.left', 'main', 'toolbar.right', 'toolbar.bottom', 'footer'],
    metadata: {},
    flow: 'auto',
    engine: 'epubjs',
    trackResize: true,
    mobileMediaQuery: '(min-device-width : 300px) and (max-device-width : 600px)',
    forceScrolledDocHeight: 1200,
    rootfilePath: '',
    text_size: 100,
    scale: 100.0,
    flowOptions: {},
    theme: 'default',
    themes: [],
    injectStylesheet: null
  },
  initialize: function initialize(id, options) {
    var self = this;
    self._original_document_title = document.title;

    if (false) {}

    this._cozyOptions = {};

    if (localStorage.getItem('cozy.options')) {
      this._cozyOptions = JSON.parse(localStorage.getItem('cozy.options'));

      if (this._cozyOptions.theme) {
        this.options.theme = this._cozyOptions.theme;
      } // if ( this._cozyOptions.flow ) {
      //   this.options.flow = this._cozyOptions.flow;
      // }

    }

    options = Util.setOptions(this, options);

    this._checkFeatureCompatibility();

    this.metadata = this.options.metadata; // initial seed

    this._initContainer(id);

    this._initLayout();

    if (this.options.themes && this.options.themes.length > 0) {
      this.options.themes.forEach(function (theme) {
        if (theme.href) {
          return;
        }

        var klass = theme.klass;
        var rules = {};

        for (var rule in theme.rules) {
          var new_rule = '.' + klass;

          if (rule == 'body') {
            new_rule = 'body' + new_rule;
          } else {
            new_rule += ' ' + rule;
          }

          rules[new_rule] = theme.rules[rule];
        }

        theme.rules = rules;
      });
    }

    this._updateTheme(); // hack for https://github.com/Leaflet/Leaflet/issues/1980
    // this._onResize = Util.bind(this._onResize, this);


    this._initEvents();

    this.callInitHooks();
    this._mode = this.options.mode;
  },
  start: function start(target, cb) {
    var self = this;

    if (typeof target == 'function' && cb === undefined) {
      cb = target;
      target = undefined;
    }

    self._start(target, cb); // Util.loader.js(this.options.engine_href).then(function() {
    //   self._start(target, cb);
    //   self._loaded = true;
    // })

  },
  _start: function _start(target, cb) {
    var self = this;
    target = target || 0; // self.open(function() {
    //   self.draw(target, cb);
    // });

    self.open(target, cb);
  },
  reopen: function reopen(options, target) {
    /* NOP */
  },
  saveOptions: function saveOptions(options) {
    var saved_options = {};

    if (localStorage.getItem('cozy.options')) {
      saved_options = JSON.parse(localStorage.getItem('cozy.options'));
    }

    assign_default()(saved_options, options);
    var key = this.metadata.layout || 'reflowable';
    var flow = saved_options.flow;

    if (saved_options.flow == 'auto') {
      // do not save
      delete saved_options.flow;
      flow = this.metadata.flow || 'paginated';
    } // key += '/' + flow;
    // var key = `${this.flow}/${this.metadata.layout}`;
    // var key = this.metadata.layout;


    if (saved_options.text_size || saved_options.scale) {
      saved_options[key] = {};

      if (saved_options.text_size) {
        saved_options[key].text_size = saved_options.text_size;
        delete saved_options.text_size;
      }

      if (saved_options.scale) {
        saved_options[key].scale = saved_options.scale;
        delete saved_options.scale;
      }

      if (saved_options.flow) {
        saved_options[key].flow = saved_options.flow;
        delete saved_options.flow;
      }
    } // saved_options[this.flow] = {}
    // if ( saved_options.text_size ) {
    // }


    localStorage.setItem('cozy.options', JSON.stringify(saved_options));
    this._cozyOptions = saved_options;
  },
  _updateTheme: function _updateTheme() {
    DomUtil.removeClass(this._container, 'cozy-theme-' + (this._container.dataset.theme || 'default'));
    DomUtil.addClass(this._container, 'cozy-theme-' + this.options.theme);
    this._container.dataset.theme = this.options.theme;
  },
  draw: function draw(target) {// NOOP
  },
  next: function next() {// NOOP
  },
  prev: function prev() {// NOOP
  },
  display: function display(target) {
    // backwards compatibility
    // NOOP
    return this.gotoPage(target);
  },
  gotoPage: function gotoPage(target) {// NOOP
  },
  goBack: function goBack() {
    history.back();
  },
  goForward: function goForward() {
    history.forward();
  },
  requestFullscreen: function requestFullscreen() {
    if (screenfull.enabled) {
      // this._preResize();
      screenfull.toggle(this._container);
    }
  },
  _preResize: function _preResize() {},
  _initContainer: function _initContainer(id) {
    var container = this._container = DomUtil.get(id);

    if (!container) {
      throw new Error('Reader container not found.');
    } else if (container._cozy_id) {
      throw new Error('Reader container is already initialized.');
    }

    DomEvent.on(container, 'scroll', this._onScroll, this);
    this._containerId = Util.stamp(container);
  },
  _initLayout: function _initLayout() {
    var container = this._container;
    this._fadeAnimated = this.options.fadeAnimation && Browser.any3d;
    DomUtil.addClass(container, 'cozy-reader cozy-container' + (Browser.touch ? ' cozy-touch' : '') + (Browser.retina ? ' cozy-retina' : '') + (Browser.ielt9 ? ' cozy-oldie' : '') + (Browser.safari ? ' cozy-safari' : '') + (this._fadeAnimated ? ' cozy-fade-anim' : '') + ' cozy-engine-' + this.options.engine + ' cozy-theme-' + this.options.theme);
    var position = DomUtil.getStyle(container, 'position');

    this._initPanes();

    if (!Browser.columnCount) {
      this.options.flow = 'scrolled-doc';
    }
  },
  _initPanes: function _initPanes() {
    var self = this;
    var panes = this._panes = {};
    var l = 'cozy-';
    var container = this._container;
    var prefix = 'cozy-module-';
    DomUtil.addClass(container, 'cozy-container');
    panes['live-status'] = DomUtil.create('div', prefix + 'live-status u-screenreader', container);
    panes['live-status'].setAttribute('aria-live', 'polite');
    panes['top'] = DomUtil.create('div', prefix + 'top', container);
    panes['main'] = DomUtil.create('div', prefix + 'main', container);
    panes['bottom'] = DomUtil.create('div', prefix + 'bottom', container);
    panes['left'] = DomUtil.create('div', prefix + 'left', panes['main']);
    panes['right'] = DomUtil.create('div', prefix + 'right', panes['main']);
    panes['book-cover'] = DomUtil.create('div', prefix + 'book-cover', panes['main']);
    panes['book'] = DomUtil.create('div', prefix + 'book', panes['book-cover']);
    panes['loader'] = DomUtil.create('div', prefix + 'book-loading', panes['book']);
    panes['epub'] = DomUtil.create('div', prefix + 'book-epub', panes['book']);

    this._initBookLoader();
  },
  _checkIfLoaded: function _checkIfLoaded() {
    if (!this._loaded) {
      throw new Error('Set map center and zoom first.');
    }
  },
  // DOM event handling
  // @section Interaction events
  _initEvents: function _initEvents(remove) {
    this._targets = {};
    this._targets[Util.stamp(this._container)] = this;

    this.tracking = function (reader) {
      var _action = [];

      var _last_location_start;

      var _last_scrollTop;

      var _reader = reader;
      return {
        action: function action(v) {
          if (v) {
            _action = [v];
            this.event(v); // _reader.fire('trackAction', { action: v })
          } else {
            return _action.pop();
          }
        },
        peek: function peek() {
          return _action[0];
        },
        event: function event(action, data) {
          if (data == null) {
            data = {};
          }

          data.action = action;

          _reader.fire("trackAction", data);
        },
        pageview: function pageview(location) {
          var do_report = true;

          if (_reader.settings.flow == 'scrolled-doc') {
            var scrollTop = 0;

            if (_reader._rendition.manager && _reader._rendition.manager.container) {
              scrollTop = _reader._rendition.manager.container.scrollTop; // console.log("AHOY CHECKING SCROLLTOP", _last_scrollTop, scrollTop, Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height);
            }

            if (_last_scrollTop && Math.abs(_last_scrollTop - scrollTop) < _reader._rendition.manager.layout.height) {
              do_report = false;
            } else {
              _last_scrollTop = scrollTop;
            }
          }

          if (location.start != _last_location_start && do_report) {
            _last_location_start = location.start;
            var tracking = {
              cfi: location.start,
              href: location.href,
              action: this.action()
            };

            _reader.fire('trackPageview', tracking);

            return tracking;
          }

          return false;
        },
        reset: function reset() {
          if (_reader.settings.flow == 'scrolled-doc') {
            _last_scrollTop = null;
          }
        }
      };
    }(this);

    var onOff = remove ? DomEvent.off : DomEvent.on; // @event click: MouseEvent
    // Fired when the user clicks (or taps) the map.
    // @event dblclick: MouseEvent
    // Fired when the user double-clicks (or double-taps) the map.
    // @event mousedown: MouseEvent
    // Fired when the user pushes the mouse button on the map.
    // @event mouseup: MouseEvent
    // Fired when the user releases the mouse button on the map.
    // @event mouseover: MouseEvent
    // Fired when the mouse enters the map.
    // @event mouseout: MouseEvent
    // Fired when the mouse leaves the map.
    // @event mousemove: MouseEvent
    // Fired while the mouse moves over the map.
    // @event contextmenu: MouseEvent
    // Fired when the user pushes the right mouse button on the map, prevents
    // default browser context menu from showing if there are listeners on
    // this event. Also fired on mobile when the user holds a single touch
    // for a second (also called long press).
    // @event keypress: KeyboardEvent
    // Fired when the user presses a key from the keyboard while the map is focused.
    // onOff(this._container, 'click dblclick mousedown mouseup ' +
    //   'mouseover mouseout mousemove contextmenu keypress', this._handleDOMEvent, this);
    // if (this.options.trackResize) {
    //   var self = this;
    //   var fn = debounce(function(){ self.invalidateSize({}); }, 150);
    //   onOff(window, 'resize', fn, this);
    // }

    if (Browser.any3d && this.options.transform3DLimit) {
      (remove ? this.off : this.on).call(this, 'moveend', this._onMoveEnd);
    }

    var self = this;

    if (screenfull.enabled) {
      screenfull.on('change', function () {
        // setTimeout(function() {
        //   self.invalidateSize({});
        // }, 100);
        self.fire('fullscreenchange', {
          isFullscreen: screenfull.isFullscreen
        });
        console.log('AHOY: Am I fullscreen?', screenfull.isFullscreen ? 'YES' : 'NO');
      });
    }

    self.on("updateLocation", function (location) {
      // possibly invoke a pageview event
      var tracking;

      if (tracking = self.tracking.pageview(location)) {
        if (location.percentage) {
          var p = Math.ceil(location.percentage * 100);
          document.title = "".concat(p, "% - ").concat(self._original_document_title);
        }

        var tmp_href = window.location.href.split("#");
        tmp_href[1] = location.start.substr(8, location.start.length - 8 - 1);
        var context = [{
          cfi: location.start
        }, '', tmp_href.join('#')];

        if (tracking.action && tracking.action.match(/\/go\/link/)) {
          // console.log("AHOY ACTION", tracking.action, context[0].cfi);
          history.pushState.apply(history, context);
        } else {
          history.replaceState.apply(history, context);
        }
      }
    });
    window.addEventListener('popstate', function (event) {
      console.log("AHOY POP STATE", event);

      if (event.isTrusted && event.state != null) {
        if (event.state.cfi == self.__last_state_cfi) {
          console.log("AHOY POP STATE IGNORE", self.__last_state_cfi);
          event.preventDefault();
          return;
        }

        self.__last_state_cfi = event.state.cfi;

        if (event.state == null || event.state.cfi == null) {
          event.preventDefault();
          return;
        }

        self.display(event.state.cfi);
      }
    });
    document.addEventListener('keydown', function (event) {
      var keyName = event.key;
      var target = event.target; // check if the activeElement is ".special-panel"

      var check = document.activeElement;

      while (check.localName != 'body') {
        if (check.classList.contains('special-panel')) {
          return;
        }

        check = check.parentElement;
      }

      var IGNORE_TARGETS = ['input', 'textarea'];

      if (IGNORE_TARGETS.indexOf(target.localName) >= 0) {
        return;
      }

      self.fire('keyDown', {
        keyName: keyName,
        shiftKey: event.shiftKey
      });
    });
    self.on('keyDown', function (data) {
      switch (data.keyName) {
        case 'ArrowRight':
        case 'PageDown':
          self.next();
          break;

        case 'ArrowLeft':
        case 'PageUp':
          self.prev();
          break;

        case 'Home':
          self._scroll('HOME');

          break;

        case 'End':
          self._scroll('END');

          break;
      }
    });
  },
  // _onResize: function() {
  //   if ( ! this._resizeRequest ) {
  //     this._resizeRequest = Util.requestAnimFrame(function() {
  //       this.invalidateSize({})
  //     }, this);
  //   }
  // },
  _onScroll: function _onScroll() {
    this._container.scrollTop = 0;
    this._container.scrollLeft = 0;
  },
  _handleDOMEvent: function _handleDOMEvent(e) {
    if (!this._loaded || DomEvent.skipped(e)) {
      return;
    }

    var type = e.type === 'keypress' && e.keyCode === 13 ? 'click' : e.type;

    if (type === 'mousedown') {
      // prevents outline when clicking on keyboard-focusable element
      DomUtil.preventOutline(e.target || e.srcElement);
    }

    this._fireDOMEvent(e, type);
  },
  _fireDOMEvent: function _fireDOMEvent(e, type, targets) {
    if (e.type === 'click') {
      // Fire a synthetic 'preclick' event which propagates up (mainly for closing popups).
      // @event preclick: MouseEvent
      // Fired before mouse click on the map (sometimes useful when you
      // want something to happen on click before any existing click
      // handlers start running).
      var synth = Util.extend({}, e);
      synth.type = 'preclick';

      this._fireDOMEvent(synth, synth.type, targets);
    }

    if (e._stopped) {
      return;
    } // Find the layer the event is propagating from and its parents.


    targets = (targets || []).concat(this._findEventTargets(e, type));

    if (!targets.length) {
      return;
    }

    var target = targets[0];

    if (type === 'contextmenu' && target.listens(type, true)) {
      DomEvent.preventDefault(e);
    }

    var data = {
      originalEvent: e
    };

    if (e.type !== 'keypress') {
      var isMarker = target.options && 'icon' in target.options;
      data.containerPoint = isMarker ? this.latLngToContainerPoint(target.getLatLng()) : this.mouseEventToContainerPoint(e);
      data.layerPoint = this.containerPointToLayerPoint(data.containerPoint);
      data.latlng = isMarker ? target.getLatLng() : this.layerPointToLatLng(data.layerPoint);
    }

    for (var i = 0; i < targets.length; i++) {
      targets[i].fire(type, data, true);

      if (data.originalEvent._stopped || targets[i].options.nonBubblingEvents && Util.indexOf(targets[i].options.nonBubblingEvents, type) !== -1) {
        return;
      }
    }
  },
  getFixedBookPanelSize: function getFixedBookPanelSize() {
    // have to make the book
    var style = window.getComputedStyle(this._panes['book']);
    var h = this._panes['book'].clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
    var w = this._panes['book'].clientWidth - parseFloat(style.paddingRight) - parseFloat(style.paddingLeft);
    return {
      height: Math.floor(h * 1.00),
      width: Math.floor(w * 1.00)
    };
  },
  invalidateSize: function invalidateSize(options) {
    // TODO: IS THIS EVER USED?
    var self = this;

    if (!self._drawn) {
      return;
    }

    Util.cancelAnimFrame(this._resizeRequest);

    if (!this._loaded) {
      return this;
    }

    this.fire('resized');
  },
  _resizeBookPane: function _resizeBookPane() {},
  _setupHooks: function _setupHooks() {},
  _checkFeatureCompatibility: function _checkFeatureCompatibility() {
    if (!DomUtil.isPropertySupported('columnCount') || this._checkMobileDevice()) {
      // force
      this.options.flow = 'scrolled-doc';
    }

    if (this._checkMobileDevice()) {
      this.options.text_size = 120;
    }
  },
  _checkMobileDevice: function _checkMobileDevice() {
    if (this._isMobile === undefined) {
      this._isMobile = false;

      if (this.options.mobileMediaQuery) {
        this._isMobile = window.matchMedia(this.options.mobileMediaQuery).matches;
      }
    }

    return this._isMobile;
  },
  _enableBookLoader: function _enableBookLoader() {
    var delay = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
    var self = this;

    self._clearBookLoaderTimeout();

    if (delay < 0) {
      delay = 0;
      self._force_progress = true;
    }

    self._loader_timeout = setTimeout(function () {
      self._panes['loader'].style.display = 'block';
    }, delay);
  },
  _disableBookLoader: function _disableBookLoader() {
    var force = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;
    var self = this;

    self._clearBookLoaderTimeout();

    if (!self._force_progress || force) {
      self._panes['loader'].style.display = 'none';
      self._force_progress = false;
      self._panes['loader-status'].innerHTML = '';
    }
  },
  _clearBookLoaderTimeout: function _clearBookLoaderTimeout() {
    var self = this;

    if (self._loader_timeout) {
      clearTimeout(self._loader_timeout);
      self._loader_timeout = null;
    }
  },
  _initBookLoader: function _initBookLoader() {
    // is this not awesome?
    var template = this.options.loader_template || this.loaderTemplate();
    var body = new DOMParser().parseFromString(template, "text/html").body;

    while (body.children.length) {
      this._panes['loader'].appendChild(body.children[0]);
    }

    this._panes['loader-status'] = DomUtil.create('div', 'cozy-module-book-loading-status', this._panes['loader']);
  },
  loaderTemplate: function loaderTemplate() {
    return "<div class=\"cozy-loader-spinner\">\n    <div class=\"spinner-backdrop spinner-backdrop--1\"></div>\n    <div class=\"spinner-backdrop spinner-backdrop--2\"></div>\n    <div class=\"spinner-backdrop spinner-backdrop--3\"></div>\n    <div class=\"spinner-backdrop spinner-backdrop--4\"></div>\n    <div class=\"spinner-quarter spinner-quarter--1\"></div>\n    <div class=\"spinner-quarter spinner-quarter--2\"></div>\n    <div class=\"spinner-quarter spinner-quarter--3\"></div>\n    <div class=\"spinner-quarter spinner-quarter--4\"></div>\n  </div>";
  },
  updateLiveStatus: function updateLiveStatus(message) {
    var _this = this;

    if (!this._panes['live-status']) {
      return;
    }

    if (message != this._last_message) {
      if (this._last_timer) {
        clearTimeout(this._last_timer);
        this._last_timer = null;
      }

      var clearDelay = 500;
      setTimeout(function () {
        _this._panes['live-status'].innerText = message;
        _this._last_message = message;
        console.log("-- status:", message);
      }, 50);
      this._last_timer = setTimeout(function () {
        _this._panes['live-status'].innerText = '';
      }, clearDelay);
    }
  },
  EOT: true
});
Object.defineProperty(Reader.prototype, 'metadata', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },
  set: function set(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});
Object.defineProperty(Reader.prototype, 'flow', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this.options.flow == 'auto' ? 'paginated' : this.options.flow;
  }
});
Object.defineProperty(Reader.prototype, 'flowOptions', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    var flow = this.flow;

    if (!this.options.flowOptions[flow]) {
      this.options.flowOptions[flow] = {};
    }

    if (!this.options.flowOptions[flow].text_size) {
      this.options.flowOptions[flow].text_size = this.options.text_size;
    }

    if (!this.options.flowOptions[flow].scale) {
      this.options.flowOptions[flow].scale = this.options.scale;
    }

    return this.options.flowOptions[flow];
  }
});
function createReader(id, options) {
  return new Reader(id, options);
}

/***/ }),

/***/ 4789:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "Reader": () => (/* reexport */ Reader/* Reader */.E),
  "reader": () => (/* binding */ reader_reader)
});

// EXTERNAL MODULE: ./src/reader/Reader.js + 1 modules
var Reader = __webpack_require__(8399);
// EXTERNAL MODULE: ./src/core/Util.js
var Util = __webpack_require__(7518);
// EXTERNAL MODULE: ./node_modules/event-emitter/index.js
var event_emitter = __webpack_require__(8370);
var event_emitter_default = /*#__PURE__*/__webpack_require__.n(event_emitter);
// EXTERNAL MODULE: ./node_modules/epubjs/src/utils/core.js
var core = __webpack_require__(6458);
// EXTERNAL MODULE: ./node_modules/epubjs/src/utils/path.js
var utils_path = __webpack_require__(5233);
// EXTERNAL MODULE: ./node_modules/path-webpack/path.js
var path = __webpack_require__(9294);
var path_default = /*#__PURE__*/__webpack_require__.n(path);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/utils/url.js



/**
 * creates a Url object for parsing and manipulation of a url string
 * @param	{string} urlString	a url string (relative or absolute)
 * @param	{string} [baseString] optional base for the url,
 * default to window.location.href
 */
class Url {
	constructor(urlString, baseString) {
		var absolute = (urlString.indexOf("://") > -1);
		var pathname = urlString;
		var basePath;

		this.Url = undefined;
		this.href = urlString;
		this.protocol = "";
		this.origin = "";
		this.hash = "";
		this.hash = "";
		this.search = "";
		this.base = baseString;

		if (!absolute &&
				baseString !== false &&
				typeof(baseString) !== "string" &&
				window && window.location) {
			this.base = window.location.href;
		}

		// URL Polyfill doesn't throw an error if base is empty
		if (absolute || this.base) {
			try {
				if (this.base) { // Safari doesn't like an undefined base
					this.Url = new URL(urlString, this.base);
				} else {
					this.Url = new URL(urlString);
				}
				this.href = this.Url.href;

				this.protocol = this.Url.protocol;
				this.origin = this.Url.origin;
				this.hash = this.Url.hash;
				this.search = this.Url.search;

				pathname = this.Url.pathname;
			} catch (e) {
				// Skip URL parsing
				this.Url = undefined;
				// resolve the pathname from the base
				if (this.base) {
					basePath = new utils_path/* default */.Z(this.base);
					pathname = basePath.resolve(pathname);
				}
			}
		}

		this.Path = new utils_path/* default */.Z(pathname);

		this.directory = this.Path.directory;
		this.filename = this.Path.filename;
		this.extension = this.Path.extension;

	}

	/**
	 * @returns {Path}
	 */
	path () {
		return this.Path;
	}

	/**
	 * Resolves a relative path to a absolute url
	 * @param {string} what
	 * @returns {string} url
	 */
	resolve (what) {
		var isAbsolute = (what.indexOf("://") > -1);
		var fullpath;

		if (isAbsolute) {
			return what;
		}

		fullpath = path_default().resolve(this.directory, what);
		return this.origin + fullpath;
	}

	/**
	 * Resolve a path relative to the url
	 * @param {string} what
	 * @returns {string} path
	 */
	relative (what) {
		return path_default().relative(what, this.directory);
	}

	/**
	 * @returns {string}
	 */
	toString () {
		return this.href;
	}
}

/* harmony default export */ const utils_url = (Url);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/epubcfi.js


const ELEMENT_NODE = 1;
const TEXT_NODE = 3;
const COMMENT_NODE = 8;
const DOCUMENT_NODE = 9;

/**
	* Parsing and creation of EpubCFIs: http://www.idpf.org/epub/linking/cfi/epub-cfi.html

	* Implements:
	* - Character Offset: epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/2/1:3)
	* - Simple Ranges : epubcfi(/6/4[chap01ref]!/4[body01]/10[para05],/2/1:1,/3:4)

	* Does Not Implement:
	* - Temporal Offset (~)
	* - Spatial Offset (@)
	* - Temporal-Spatial Offset (~ + @)
	* - Text Location Assertion ([)
	* @class
	@param {string | Range | Node } [cfiFrom]
	@param {string | object} [base]
	@param {string} [ignoreClass] class to ignore when parsing DOM
*/
class EpubCFI {
	constructor(cfiFrom, base, ignoreClass){
		var type;

		this.str = "";

		this.base = {};
		this.spinePos = 0; // For compatibility

		this.range = false; // true || false;

		this.path = {};
		this.start = null;
		this.end = null;

		// Allow instantiation without the "new" keyword
		if (!(this instanceof EpubCFI)) {
			return new EpubCFI(cfiFrom, base, ignoreClass);
		}

		if(typeof base === "string") {
			this.base = this.parseComponent(base);
		} else if(typeof base === "object" && base.steps) {
			this.base = base;
		}

		type = this.checkType(cfiFrom);


		if(type === "string") {
			this.str = cfiFrom;
			return (0,core.extend)(this, this.parse(cfiFrom));
		} else if (type === "range") {
			return (0,core.extend)(this, this.fromRange(cfiFrom, this.base, ignoreClass));
		} else if (type === "node") {
			return (0,core.extend)(this, this.fromNode(cfiFrom, this.base, ignoreClass));
		} else if (type === "EpubCFI" && cfiFrom.path) {
			return cfiFrom;
		} else if (!cfiFrom) {
			return this;
		} else {
			throw new TypeError("not a valid argument for EpubCFI");
		}

	}

	/**
	 * Check the type of constructor input
	 * @private
	 */
	checkType(cfi) {

		if (this.isCfiString(cfi)) {
			return "string";
		// Is a range object
		} else if (cfi && typeof cfi === "object" && ((0,core.type)(cfi) === "Range" || typeof(cfi.startContainer) != "undefined")){
			return "range";
		} else if (cfi && typeof cfi === "object" && typeof(cfi.nodeType) != "undefined" ){ // || typeof cfi === "function"
			return "node";
		} else if (cfi && typeof cfi === "object" && cfi instanceof EpubCFI){
			return "EpubCFI";
		} else {
			return false;
		}
	}

	/**
	 * Parse a cfi string to a CFI object representation
	 * @param {string} cfiStr
	 * @returns {object} cfi
	 */
	parse(cfiStr) {
		var cfi = {
			spinePos: -1,
			range: false,
			base: {},
			path: {},
			start: null,
			end: null
		};
		var baseComponent, pathComponent, range;

		if(typeof cfiStr !== "string") {
			return {spinePos: -1};
		}

		if(cfiStr.indexOf("epubcfi(") === 0 && cfiStr[cfiStr.length-1] === ")") {
			// Remove intial epubcfi( and ending )
			cfiStr = cfiStr.slice(8, cfiStr.length-1);
		}

		baseComponent = this.getChapterComponent(cfiStr);

		// Make sure this is a valid cfi or return
		if(!baseComponent) {
			return {spinePos: -1};
		}

		cfi.base = this.parseComponent(baseComponent);

		pathComponent = this.getPathComponent(cfiStr);
		cfi.path = this.parseComponent(pathComponent);

		range = this.getRange(cfiStr);

		if(range) {
			cfi.range = true;
			cfi.start = this.parseComponent(range[0]);
			cfi.end = this.parseComponent(range[1]);
		}

		// Get spine node position
		// cfi.spineSegment = cfi.base.steps[1];

		// Chapter segment is always the second step
		cfi.spinePos = cfi.base.steps[1].index;

		return cfi;
	}

	parseComponent(componentStr){
		var component = {
			steps: [],
			terminal: {
				offset: null,
				assertion: null
			}
		};
		var parts = componentStr.split(":");
		var steps = parts[0].split("/");
		var terminal;

		if(parts.length > 1) {
			terminal = parts[1];
			component.terminal = this.parseTerminal(terminal);
		}

		if (steps[0] === "") {
			steps.shift(); // Ignore the first slash
		}

		component.steps = steps.map(function(step){
			return this.parseStep(step);
		}.bind(this));

		return component;
	}

	parseStep(stepStr){
		var type, num, index, has_brackets, id;

		has_brackets = stepStr.match(/\[(.*)\]/);
		if(has_brackets && has_brackets[1]){
			id = has_brackets[1];
		}

		//-- Check if step is a text node or element
		num = parseInt(stepStr);

		if(isNaN(num)) {
			return;
		}

		if(num % 2 === 0) { // Even = is an element
			type = "element";
			index = num / 2 - 1;
		} else {
			type = "text";
			index = (num - 1 ) / 2;
		}

		return {
			"type" : type,
			"index" : index,
			"id" : id || null
		};
	}

	parseTerminal(termialStr){
		var characterOffset, textLocationAssertion;
		var assertion = termialStr.match(/\[(.*)\]/);

		if(assertion && assertion[1]){
			characterOffset = parseInt(termialStr.split("[")[0]);
			textLocationAssertion = assertion[1];
		} else {
			characterOffset = parseInt(termialStr);
		}

		if (!(0,core.isNumber)(characterOffset)) {
			characterOffset = null;
		}

		return {
			"offset": characterOffset,
			"assertion": textLocationAssertion
		};

	}

	getChapterComponent(cfiStr) {

		var indirection = cfiStr.split("!");

		return indirection[0];
	}

	getPathComponent(cfiStr) {

		var indirection = cfiStr.split("!");

		if(indirection[1]) {
			let ranges = indirection[1].split(",");
			return ranges[0];
		}

	}

	getRange(cfiStr) {

		var ranges = cfiStr.split(",");

		if(ranges.length === 3){
			return [
				ranges[1],
				ranges[2]
			];
		}

		return false;
	}

	getCharecterOffsetComponent(cfiStr) {
		var splitStr = cfiStr.split(":");
		return splitStr[1] || "";
	}

	joinSteps(steps) {
		if(!steps) {
			return "";
		}

		return steps.map(function(part){
			var segment = "";

			if(part.type === "element") {
				segment += (part.index + 1) * 2;
			}

			if(part.type === "text") {
				segment += 1 + (2 * part.index); // TODO: double check that this is odd
			}

			if(part.id) {
				segment += "[" + part.id + "]";
			}

			return segment;

		}).join("/");

	}

	segmentString(segment) {
		var segmentString = "/";

		segmentString += this.joinSteps(segment.steps);

		if(segment.terminal && segment.terminal.offset != null){
			segmentString += ":" + segment.terminal.offset;
		}

		if(segment.terminal && segment.terminal.assertion != null){
			segmentString += "[" + segment.terminal.assertion + "]";
		}

		return segmentString;
	}

	/**
	 * Convert CFI to a epubcfi(...) string
	 * @returns {string} epubcfi
	 */
	toString(cfi) {
		if ( ! cfi ) { cfi = this; }
		var cfiString = "epubcfi(";

		cfiString += this.segmentString(cfi.base);

		cfiString += "!";
		cfiString += this.segmentString(cfi.path);

		// Add Range, if present
		if(cfi.range && cfi.start) {
			cfiString += ",";
			cfiString += this.segmentString(cfi.start);
		}

		if(cfi.range && cfi.end) {
			cfiString += ",";
			cfiString += this.segmentString(cfi.end);
		}

		cfiString += ")";

		return cfiString;
	}


	/**
	 * Compare which of two CFIs is earlier in the text
	 * @returns {number} First is earlier = -1, Second is earlier = 1, They are equal = 0
	 */
	compare(cfiOne, cfiTwo) {
		var stepsA, stepsB;
		var terminalA, terminalB;

		var rangeAStartSteps, rangeAEndSteps;
		var rangeBEndSteps, rangeBEndSteps;
		var rangeAStartTerminal, rangeAEndTerminal;
		var rangeBStartTerminal, rangeBEndTerminal;

		if(typeof cfiOne === "string") {
			cfiOne = new EpubCFI(cfiOne);
		}
		if(typeof cfiTwo === "string") {
			cfiTwo = new EpubCFI(cfiTwo);
		}
		// Compare Spine Positions
		if(cfiOne.spinePos > cfiTwo.spinePos) {
			return 1;
		}
		if(cfiOne.spinePos < cfiTwo.spinePos) {
			return -1;
		}

		if (cfiOne.range) {
			stepsA = cfiOne.path.steps.concat(cfiOne.start.steps);
			terminalA = cfiOne.start.terminal;
		} else {
			stepsA = cfiOne.path.steps;
			terminalA = cfiOne.path.terminal;
		}

		if (cfiTwo.range) {
			stepsB = cfiTwo.path.steps.concat(cfiTwo.start.steps);
			terminalB = cfiTwo.start.terminal;
		} else {
			stepsB = cfiTwo.path.steps;
			terminalB = cfiTwo.path.terminal;
		}

		// Compare Each Step in the First item
		for (var i = 0; i < stepsA.length; i++) {
			if(!stepsA[i]) {
				return -1;
			}
			if(!stepsB[i]) {
				return 1;
			}
			if(stepsA[i].index > stepsB[i].index) {
				return 1;
			}
			if(stepsA[i].index < stepsB[i].index) {
				return -1;
			}
			// Otherwise continue checking
		}

		// All steps in First equal to Second and First is Less Specific
		if(stepsA.length < stepsB.length) {
			return 1;
		}

		// Compare the charecter offset of the text node
		if(terminalA.offset > terminalB.offset) {
			return 1;
		}
		if(terminalA.offset < terminalB.offset) {
			return -1;
		}

		// CFI's are equal
		return 0;
	}

	step(node) {
		var nodeType = (node.nodeType === TEXT_NODE) ? "text" : "element";

		return {
			"id" : node.id,
			"tagName" : node.tagName,
			"type" : nodeType,
			"index" : this.position(node)
		};
	}

	filteredStep(node, ignoreClass) {
		var filteredNode = this.filter(node, ignoreClass);
		var nodeType;

		// Node filtered, so ignore
		if (!filteredNode) {
			return;
		}

		// Otherwise add the filter node in
		nodeType = (filteredNode.nodeType === TEXT_NODE) ? "text" : "element";

		return {
			"id" : filteredNode.id,
			"tagName" : filteredNode.tagName,
			"type" : nodeType,
			"index" : this.filteredPosition(filteredNode, ignoreClass)
		};
	}

	pathTo(node, offset, ignoreClass) {
		var segment = {
			steps: [],
			terminal: {
				offset: null,
				assertion: null
			}
		};
		var currentNode = node;
		var step;

		while(currentNode && currentNode.parentNode &&
					currentNode.parentNode.nodeType != DOCUMENT_NODE) {

			if (ignoreClass) {
				step = this.filteredStep(currentNode, ignoreClass);
			} else {
				step = this.step(currentNode);
			}

			if (step) {
				segment.steps.unshift(step);
			}

			currentNode = currentNode.parentNode;

		}

		if (offset != null && offset >= 0) {

			segment.terminal.offset = offset;

			// Make sure we are getting to a textNode if there is an offset
			if(segment.steps[segment.steps.length-1].type != "text") {
				segment.steps.push({
					"type" : "text",
					"index" : 0
				});
			}

		}


		return segment;
	}

	equalStep(stepA, stepB) {
		if (!stepA || !stepB) {
			return false;
		}

		if(stepA.index === stepB.index &&
			 stepA.id === stepB.id &&
			 stepA.type === stepB.type) {
			return true;
		}

		return false;
	}

	/**
	 * Create a CFI object from a Range
	 * @param {Range} range
	 * @param {string | object} base
	 * @param {string} [ignoreClass]
	 * @returns {object} cfi
	 */
	fromRange(range, base, ignoreClass) {
		var cfi = {
			range: false,
			base: {},
			path: {},
			start: null,
			end: null
		};

		var start = range.startContainer;
		var end = range.endContainer;

		var startOffset = range.startOffset;
		var endOffset = range.endOffset;

		var needsIgnoring = false;

		if (ignoreClass) {
			// Tell pathTo if / what to ignore
			needsIgnoring = (start.ownerDocument.querySelector("." + ignoreClass) != null);
		}


		if (typeof base === "string") {
			cfi.base = this.parseComponent(base);
			cfi.spinePos = cfi.base.steps[1].index;
		} else if (typeof base === "object") {
			cfi.base = base;
		}

		if (range.collapsed) {
			if (needsIgnoring) {
				startOffset = this.patchOffset(start, startOffset, ignoreClass);
			}
			cfi.path = this.pathTo(start, startOffset, ignoreClass);
		} else {
			cfi.range = true;

			if (needsIgnoring) {
				startOffset = this.patchOffset(start, startOffset, ignoreClass);
			}

			cfi.start = this.pathTo(start, startOffset, ignoreClass);
			if (needsIgnoring) {
				endOffset = this.patchOffset(end, endOffset, ignoreClass);
			}

			cfi.end = this.pathTo(end, endOffset, ignoreClass);

			// Create a new empty path
			cfi.path = {
				steps: [],
				terminal: null
			};

			// Push steps that are shared between start and end to the common path
			var len = cfi.start.steps.length;
			var i;

			for (i = 0; i < len; i++) {
				if (this.equalStep(cfi.start.steps[i], cfi.end.steps[i])) {
					if(i === len-1) {
						// Last step is equal, check terminals
						if(cfi.start.terminal === cfi.end.terminal) {
							// CFI's are equal
							cfi.path.steps.push(cfi.start.steps[i]);
							// Not a range
							cfi.range = false;
						}
					} else {
						cfi.path.steps.push(cfi.start.steps[i]);
					}

				} else {
					break;
				}
			}

			cfi.start.steps = cfi.start.steps.slice(cfi.path.steps.length);
			cfi.end.steps = cfi.end.steps.slice(cfi.path.steps.length);

			// TODO: Add Sanity check to make sure that the end if greater than the start
		}

		return cfi;
	}

	/**
	 * Create a CFI object from a Node
	 * @param {Node} anchor
	 * @param {string | object} base
	 * @param {string} [ignoreClass]
	 * @returns {object} cfi
	 */
	fromNode(anchor, base, ignoreClass) {
		var cfi = {
			range: false,
			base: {},
			path: {},
			start: null,
			end: null
		};

		if (typeof base === "string") {
			cfi.base = this.parseComponent(base);
			cfi.spinePos = cfi.base.steps[1].index;
		} else if (typeof base === "object") {
			cfi.base = base;
		}

		cfi.path = this.pathTo(anchor, null, ignoreClass);

		return cfi;
	}

	filter(anchor, ignoreClass) {
		var needsIgnoring;
		var sibling; // to join with
		var parent, previousSibling, nextSibling;
		var isText = false;

		if (anchor.nodeType === TEXT_NODE) {
			isText = true;
			parent = anchor.parentNode;
			needsIgnoring = anchor.parentNode.classList.contains(ignoreClass);
		} else {
			isText = false;
			needsIgnoring = anchor.classList.contains(ignoreClass);
		}

		if (needsIgnoring && isText) {
			previousSibling = parent.previousSibling;
			nextSibling = parent.nextSibling;

			// If the sibling is a text node, join the nodes
			if (previousSibling && previousSibling.nodeType === TEXT_NODE) {
				sibling = previousSibling;
			} else if (nextSibling && nextSibling.nodeType === TEXT_NODE) {
				sibling = nextSibling;
			}

			if (sibling) {
				return sibling;
			} else {
				// Parent will be ignored on next step
				return anchor;
			}

		} else if (needsIgnoring && !isText) {
			// Otherwise just skip the element node
			return false;
		} else {
			// No need to filter
			return anchor;
		}

	}

	patchOffset(anchor, offset, ignoreClass) {
		if (anchor.nodeType != TEXT_NODE) {
			throw new Error("Anchor must be a text node");
		}

		var curr = anchor;
		var totalOffset = offset;

		// If the parent is a ignored node, get offset from it's start
		if (anchor.parentNode.classList.contains(ignoreClass)) {
			curr = anchor.parentNode;
		}

		while (curr.previousSibling) {
			if(curr.previousSibling.nodeType === ELEMENT_NODE) {
				// Originally a text node, so join
				if(curr.previousSibling.classList.contains(ignoreClass)){
					totalOffset += curr.previousSibling.textContent.length;
				} else {
					break; // Normal node, dont join
				}
			} else {
				// If the previous sibling is a text node, join the nodes
				totalOffset += curr.previousSibling.textContent.length;
			}

			curr = curr.previousSibling;
		}

		return totalOffset;

	}

	normalizedMap(children, nodeType, ignoreClass) {
		var output = {};
		var prevIndex = -1;
		var i, len = children.length;
		var currNodeType;
		var prevNodeType;

		for (i = 0; i < len; i++) {

			currNodeType = children[i].nodeType;

			// Check if needs ignoring
			if (currNodeType === ELEMENT_NODE &&
					children[i].classList.contains(ignoreClass)) {
				currNodeType = TEXT_NODE;
			}

			if (i > 0 &&
					currNodeType === TEXT_NODE &&
					prevNodeType === TEXT_NODE) {
				// join text nodes
				output[i] = prevIndex;
			} else if (nodeType === currNodeType){
				prevIndex = prevIndex + 1;
				output[i] = prevIndex;
			}

			prevNodeType = currNodeType;

		}

		return output;
	}

	position(anchor) {
		var children, index;
		if (anchor.nodeType === ELEMENT_NODE) {
			children = anchor.parentNode.children;
			if (!children) {
				children = (0,core.findChildren)(anchor.parentNode);
			}
			index = Array.prototype.indexOf.call(children, anchor);
		} else {
			children = this.textNodes(anchor.parentNode);
			index = children.indexOf(anchor);
		}

		return index;
	}

	filteredPosition(anchor, ignoreClass) {
		var children, index, map;

		if (anchor.nodeType === ELEMENT_NODE) {
			children = anchor.parentNode.children;
			map = this.normalizedMap(children, ELEMENT_NODE, ignoreClass);
		} else {
			children = anchor.parentNode.childNodes;
			// Inside an ignored node
			if(anchor.parentNode.classList.contains(ignoreClass)) {
				anchor = anchor.parentNode;
				children = anchor.parentNode.childNodes;
			}
			map = this.normalizedMap(children, TEXT_NODE, ignoreClass);
		}


		index = Array.prototype.indexOf.call(children, anchor);

		return map[index];
	}

	stepsToXpath(steps) {
		var xpath = [".", "*"];

		steps.forEach(function(step){
			var position = step.index + 1;

			if(step.id){
				xpath.push("*[position()=" + position + " and @id='" + step.id + "']");
			} else if(step.type === "text") {
				xpath.push("text()[" + position + "]");
			} else {
				xpath.push("*[" + position + "]");
			}
		});

		return xpath.join("/");
	}


	/*

	To get the last step if needed:

	// Get the terminal step
	lastStep = steps[steps.length-1];
	// Get the query string
	query = this.stepsToQuery(steps);
	// Find the containing element
	startContainerParent = doc.querySelector(query);
	// Find the text node within that element
	if(startContainerParent && lastStep.type == "text") {
		container = startContainerParent.childNodes[lastStep.index];
	}
	*/
	stepsToQuerySelector(steps) {
		var query = ["html"];

		steps.forEach(function(step){
			var position = step.index + 1;

			if(step.id){
				query.push("#" + step.id);
			} else if(step.type === "text") {
				// unsupported in querySelector
				// query.push("text()[" + position + "]");
			} else {
				query.push("*:nth-child(" + position + ")");
			}
		});

		return query.join(">");

	}

	textNodes(container, ignoreClass) {
		return Array.prototype.slice.call(container.childNodes).
			filter(function (node) {
				if (node.nodeType === TEXT_NODE) {
					return true;
				} else if (ignoreClass && node.classList.contains(ignoreClass)) {
					return true;
				}
				return false;
			});
	}

	walkToNode(steps, _doc, ignoreClass) {
		var doc = _doc || document;
		var container = doc.documentElement;
		var children;
		var step;
		var len = steps.length;
		var i;

		for (i = 0; i < len; i++) {
			step = steps[i];

			if(step.type === "element") {
				//better to get a container using id as some times step.index may not be correct
				//For ex.https://github.com/futurepress/epub.js/issues/561
				if(step.id) {
					container = doc.getElementById(step.id);
				}
				else {
					children = container.children || (0,core.findChildren)(container);
					container = children[step.index];
				}
			} else if(step.type === "text") {
				container = this.textNodes(container, ignoreClass)[step.index];
			}
			if(!container) {
				//Break the for loop as due to incorrect index we can get error if
				//container is undefined so that other functionailties works fine
				//like navigation
				break;
			}

		}

		return container;
	}

	findNode(steps, _doc, ignoreClass) {
		var doc = _doc || document;
		var container;
		var xpath;

		if(!ignoreClass && typeof doc.evaluate != "undefined") {
			xpath = this.stepsToXpath(steps);
			container = doc.evaluate(xpath, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
		} else if(ignoreClass) {
			container = this.walkToNode(steps, doc, ignoreClass);
		} else {
			container = this.walkToNode(steps, doc);
		}

		return container;
	}

	fixMiss(steps, offset, _doc, ignoreClass) {
		var container = this.findNode(steps.slice(0,-1), _doc, ignoreClass);
		var children = container.childNodes;
		var map = this.normalizedMap(children, TEXT_NODE, ignoreClass);
		var child;
		var len;
		var lastStepIndex = steps[steps.length-1].index;

		for (let childIndex in map) {
			if (!map.hasOwnProperty(childIndex)) return;

			if(map[childIndex] === lastStepIndex) {
				child = children[childIndex];
				len = child.textContent.length;
				if(offset > len) {
					offset = offset - len;
				} else {
					if (child.nodeType === ELEMENT_NODE) {
						container = child.childNodes[0];
					} else {
						container = child;
					}
					break;
				}
			}
		}

		return {
			container: container,
			offset: offset
		};

	}

	/**
	 * Creates a DOM range representing a CFI
	 * @param {document} _doc document referenced in the base
	 * @param {string} [ignoreClass]
	 * @return {Range}
	 */
	toRange(_doc, ignoreClass) {
		var doc = _doc || document;
		var range;
		var start, end, startContainer, endContainer;
		var cfi = this;
		var startSteps, endSteps;
		var needsIgnoring = ignoreClass ? (doc.querySelector("." + ignoreClass) != null) : false;
		var missed;

		if (typeof(doc.createRange) !== "undefined") {
			range = doc.createRange();
		} else {
			range = new core.RangeObject();
		}

		if (cfi.range) {
			start = cfi.start;
			startSteps = cfi.path.steps.concat(start.steps);
			startContainer = this.findNode(startSteps, doc, needsIgnoring ? ignoreClass : null);
			end = cfi.end;
			endSteps = cfi.path.steps.concat(end.steps);
			endContainer = this.findNode(endSteps, doc, needsIgnoring ? ignoreClass : null);
		} else {
			start = cfi.path;
			startSteps = cfi.path.steps;
			startContainer = this.findNode(cfi.path.steps, doc, needsIgnoring ? ignoreClass : null);
		}

		if(startContainer) {
			try {

				if(start.terminal.offset != null) {
					range.setStart(startContainer, start.terminal.offset);
				} else {
					range.setStart(startContainer, 0);
				}

			} catch (e) {
				missed = this.fixMiss(startSteps, start.terminal.offset, doc, needsIgnoring ? ignoreClass : null);
				range.setStart(missed.container, missed.offset);
			}
		} else {
			console.log("No startContainer found for", this.toString());
			// No start found
			return null;
		}

		if (endContainer) {
			try {

				if(end.terminal.offset != null) {
					range.setEnd(endContainer, end.terminal.offset);
				} else {
					range.setEnd(endContainer, 0);
				}

			} catch (e) {
				missed = this.fixMiss(endSteps, cfi.end.terminal.offset, doc, needsIgnoring ? ignoreClass : null);
				range.setEnd(missed.container, missed.offset);
			}
		}


		// doc.defaultView.getSelection().addRange(range);
		return range;
	}

	/**
	 * Check if a string is wrapped with "epubcfi()"
	 * @param {string} str
	 * @returns {boolean}
	 */
	isCfiString(str) {
		if(typeof str === "string" &&
			str.indexOf("epubcfi(") === 0 &&
			str[str.length-1] === ")") {
			return true;
		}

		return false;
	}

	generateChapterComponent(_spineNodeIndex, _pos, id) {
		var pos = parseInt(_pos),
				spineNodeIndex = (_spineNodeIndex + 1) * 2,
				cfi = "/"+spineNodeIndex+"/";

		cfi += (pos + 1) * 2;

		if(id) {
			cfi += "[" + id + "]";
		}

		return cfi;
	}

	/**
	 * Collapse a CFI Range to a single CFI Position
	 * @param {boolean} [toStart=false]
	 */
	collapse(toStart) {
		if (!this.range) {
			return;
		}

		this.range = false;

		if (toStart) {
			this.path.steps = this.path.steps.concat(this.start.steps);
			this.path.terminal = this.start.terminal;
		} else {
			this.path.steps = this.path.steps.concat(this.end.steps);
			this.path.terminal = this.end.terminal;
		}

	}
}

/* harmony default export */ const epubcfi = (EpubCFI);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/utils/hook.js
/**
 * Hooks allow for injecting functions that must all complete in order before finishing
 * They will execute in parallel but all must finish before continuing
 * Functions may return a promise if they are asycn.
 * @param {any} context scope of this
 * @example this.content = new EPUBJS.Hook(this);
 */
class Hook {
	constructor(context){
		this.context = context || this;
		this.hooks = [];
	}

	/**
	 * Adds a function to be run before a hook completes
	 * @example this.content.register(function(){...});
	 */
	register(){
		for(var i = 0; i < arguments.length; ++i) {
			if (typeof arguments[i]  === "function") {
				this.hooks.push(arguments[i]);
			} else {
				// unpack array
				for(var j = 0; j < arguments[i].length; ++j) {
					this.hooks.push(arguments[i][j]);
				}
			}
		}
	}

	/**
	 * Removes a function
	 * @example this.content.deregister(function(){...});
	 */
	deregister(func){
		let hook;
		for (let i = 0; i < this.hooks.length; i++) {
			hook = this.hooks[i];
			if (hook === func) {
				this.hooks.splice(i, 1);
				break;
			}
		}
	}

	/**
	 * Triggers a hook to run all functions
	 * @example this.content.trigger(args).then(function(){...});
	 */
	trigger(){
		var args = arguments;
		var context = this.context;
		var promises = [];

		this.hooks.forEach(function(task) {
			var executing = task.apply(context, args);

			if(executing && typeof executing["then"] === "function") {
				// Task is a function that returns a promise
				promises.push(executing);
			}
			// Otherwise Task resolves immediately, continue
		});


		return Promise.all(promises);
	}

	// Adds a function to be run before a hook completes
	list(){
		return this.hooks;
	}

	clear(){
		return this.hooks = [];
	}
}
/* harmony default export */ const hook = (Hook);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/utils/replacements.js




function replaceBase(doc, section){
	var base;
	var head;
	var url = section.url;
	var absolute = (url.indexOf("://") > -1);

	if(!doc){
		return;
	}

	head = (0,core.qs)(doc, "head");
	base = (0,core.qs)(head, "base");

	if(!base) {
		base = doc.createElement("base");
		head.insertBefore(base, head.firstChild);
	}

	// Fix for Safari crashing if the url doesn't have an origin
	if (!absolute && window && window.location) {
		url = window.location.origin + url;
	}

	base.setAttribute("href", url);
}

function replaceCanonical(doc, section){
	var head;
	var link;
	var url = section.canonical;

	if(!doc){
		return;
	}

	head = (0,core.qs)(doc, "head");
	link = (0,core.qs)(head, "link[rel='canonical']");

	if (link) {
		link.setAttribute("href", url);
	} else {
		link = doc.createElement("link");
		link.setAttribute("rel", "canonical");
		link.setAttribute("href", url);
		head.appendChild(link);
	}
}

function replaceMeta(doc, section){
	var head;
	var meta;
	var id = section.idref;
	if(!doc){
		return;
	}

	head = (0,core.qs)(doc, "head");
	meta = (0,core.qs)(head, "link[property='dc.identifier']");

	if (meta) {
		meta.setAttribute("content", id);
	} else {
		meta = doc.createElement("meta");
		meta.setAttribute("name", "dc.identifier");
		meta.setAttribute("content", id);
		head.appendChild(meta);
	}
}

// TODO: move me to Contents
function replaceLinks(contents, fn) {

	var links = contents.querySelectorAll("a[href]");

	if (!links.length) {
		return;
	}

	var base = (0,core.qs)(contents.ownerDocument, "base");
	var location = base ? base.getAttribute("href") : undefined;
	var replaceLink = function(link){
		var href = link.getAttribute("href");

		if(href.indexOf("mailto:") === 0){
			return;
		}

		var absolute = (href.indexOf("://") > -1);

		if(absolute){

			link.setAttribute("target", "_blank");

		}else{
			var linkUrl;
			try {
				linkUrl = new utils_url(href, location);	
			} catch(error) {
				// NOOP
			}

			link.onclick = function(){

				if(linkUrl && linkUrl.hash) {
					fn(linkUrl.Path.path + linkUrl.hash);
				} else if(linkUrl){
					fn(linkUrl.Path.path);
				} else {
					fn(href);
				}

				return false;
			};
		}
	}.bind(this);

	for (var i = 0; i < links.length; i++) {
		replaceLink(links[i]);
	}


}

function substitute(content, urls, replacements) {
	urls.forEach(function(url, i){
		if (url && replacements[i]) {
			content = content.replace(new RegExp(url, "g"), replacements[i]);
		}
	});
	return content;
}

;// CONCATENATED MODULE: ./node_modules/epubjs/src/section.js






/**
 * Represents a Section of the Book
 *
 * In most books this is equivelent to a Chapter
 * @param {object} item  The spine item representing the section
 * @param {object} hooks hooks for serialize and content
 */
class Section {
	constructor(item, hooks){
		this.idref = item.idref;
		this.linear = item.linear === "yes";
		this.properties = item.properties;
		this.index = item.index;
		this.href = item.href;
		this.url = item.url;
		this.canonical = item.canonical;
		this.next = item.next;
		this.prev = item.prev;

		this.cfiBase = item.cfiBase;

		if (hooks) {
			this.hooks = hooks;
		} else {
			this.hooks = {};
			this.hooks.serialize = new hook(this);
			this.hooks.content = new hook(this);
		}

		this.document = undefined;
		this.contents = undefined;
		this.output = undefined;
	}

	/**
	 * Load the section from its url
	 * @param  {method} [_request] a request method to use for loading
	 * @return {document} a promise with the xml document
	 */
	load(_request){
		var request = _request || this.request || __webpack_require__(5817);
		var loading = new core.defer();
		var loaded = loading.promise;

		if(this.contents) {
			loading.resolve(this.contents);
		} else {
			request(this.url)
				.then(function(xml){
					// var directory = new Url(this.url).directory;

					this.document = xml;
					this.contents = xml.documentElement;

					return this.hooks.content.trigger(this.document, this);
				}.bind(this))
				.then(function(){
					loading.resolve(this.contents);
				}.bind(this))
				.catch(function(error){
					loading.reject(error);
				});
		}

		return loaded;
	}

	/**
	 * Adds a base tag for resolving urls in the section
	 * @private
	 */
	base(){
		return replaceBase(this.document, this);
	}

	/**
	 * Render the contents of a section
	 * @param  {method} [_request] a request method to use for loading
	 * @return {string} output a serialized XML Document
	 */
	render(_request){
		var rendering = new core.defer();
		var rendered = rendering.promise;
		this.output; // TODO: better way to return this from hooks?

		this.load(_request).
			then(function(contents){
				var userAgent = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
				var isIE = userAgent.indexOf('Trident') >= 0;
				var Serializer;
				if (false) {} else {
					Serializer = XMLSerializer;
				}
				var serializer = new Serializer();
				this.output = serializer.serializeToString(contents);
				return this.output;
			}.bind(this)).
			then(function(){
				return this.hooks.serialize.trigger(this.output, this);
			}.bind(this)).
			then(function(){
				rendering.resolve(this.output);
			}.bind(this))
			.catch(function(error){
				rendering.reject(error);
			});

		return rendered;
	}

	/**
	 * Find a string in a section
	 * @param  {string} _query The query string to find
	 * @return {object[]} A list of matches, with form {cfi, excerpt}
	 */
	find(_query){
		var section = this;
		var matches = [];
		var query = _query.toLowerCase();
		var find = function(node){
			var text = node.textContent.toLowerCase();
			var range = section.document.createRange();
			var cfi;
			var pos;
			var last = -1;
			var excerpt;
			var limit = 150;

			while (pos != -1) {
				// Search for the query
				pos = text.indexOf(query, last + 1);

				if (pos != -1) {
					// We found it! Generate a CFI
					range = section.document.createRange();
					range.setStart(node, pos);
					range.setEnd(node, pos + query.length);

					cfi = section.cfiFromRange(range);

					// Generate the excerpt
					if (node.textContent.length < limit) {
						excerpt = node.textContent;
					}
					else {
						excerpt = node.textContent.substring(pos - limit/2, pos + limit/2);
						excerpt = "..." + excerpt + "...";
					}

					// Add the CFI to the matches list
					matches.push({
						cfi: cfi,
						excerpt: excerpt
					});
				}

				last = pos;
			}
		};

		(0,core.sprint)(section.document, function(node) {
			find(node);
		});

		return matches;
	};

	/**
	* Reconciles the current chapters layout properies with
	* the global layout properities.
	* @param {object} globalLayout  The global layout settings object, chapter properties string
	* @return {object} layoutProperties Object with layout properties
	*/
	reconcileLayoutSettings(globalLayout){
		//-- Get the global defaults
		var settings = {
			layout : globalLayout.layout,
			spread : globalLayout.spread,
			orientation : globalLayout.orientation
		};

		//-- Get the chapter's display type
		this.properties.forEach(function(prop){
			var rendition = prop.replace("rendition:", "");
			var split = rendition.indexOf("-");
			var property, value;

			if(split != -1){
				property = rendition.slice(0, split);
				value = rendition.slice(split+1);

				settings[property] = value;
			}
		});
		return settings;
	}

	/**
	 * Get a CFI from a Range in the Section
	 * @param  {range} _range
	 * @return {string} cfi an EpubCFI string
	 */
	cfiFromRange(_range) {
		return new epubcfi(_range, this.cfiBase).toString();
	}

	/**
	 * Get a CFI from an Element in the Section
	 * @param  {element} el
	 * @return {string} cfi an EpubCFI string
	 */
	cfiFromElement(el) {
		return new epubcfi(el, this.cfiBase).toString();
	}

	/**
	 * Unload the section document
	 */
	unload() {
		this.document = undefined;
		this.contents = undefined;
		this.output = undefined;
	}

	destroy() {
		this.unload();
		this.hooks.serialize.clear();
		this.hooks.content.clear();

		this.hooks = undefined;
		this.idref = undefined;
		this.linear = undefined;
		this.properties = undefined;
		this.index = undefined;
		this.href = undefined;
		this.url = undefined;
		this.next = undefined;
		this.prev = undefined;

		this.cfiBase = undefined;
	}
}

/* harmony default export */ const section = (Section);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/spine.js





/**
 * A collection of Spine Items
 */
class Spine {
	constructor() {
		this.spineItems = [];
		this.spineByHref = {};
		this.spineByAbsoluteHref = {};
		this.spineById = {};

		this.hooks = {};
		this.hooks.serialize = new hook();
		this.hooks.content = new hook();

		// Register replacements
		this.hooks.content.register(replaceBase);
		this.hooks.content.register(replaceCanonical);
		this.hooks.content.register(replaceMeta);

		this.epubcfi = new epubcfi();

		this.loaded = false;

		this.items = undefined;
		this.manifest = undefined;
		this.spineNodeIndex = undefined;
		this.baseUrl = undefined;
		this.length = undefined;
	}

	/**
	 * Unpack items from a opf into spine items
	 * @param  {Packaging} _package
	 * @param  {method} resolver URL resolver
	 * @param  {method} canonical Resolve canonical url
	 */
	unpack(_package, resolver, canonical) {

		this.items = _package.spine;
		this.manifest = _package.manifest;
		this.spineNodeIndex = _package.spineNodeIndex;
		this.baseUrl = _package.baseUrl || _package.basePath || "";
		this.length = this.items.length;

		this.items.forEach( (item, index) => {
			var manifestItem = this.manifest[item.idref];
			var spineItem;

			item.index = index;
			item.cfiBase = this.epubcfi.generateChapterComponent(this.spineNodeIndex, item.index, item.idref);

			if (item.href) {
				item.url = resolver(item.href, true);
				item.canonical = canonical(item.href);
			}

			if(manifestItem) {
				item.href = manifestItem.href;
				item.url = resolver(item.href, true);
				item.canonical = canonical(item.href);

				if(manifestItem.properties.length){
					item.properties.push.apply(item.properties, manifestItem.properties);
				}
			}

			if (item.linear === "yes") {
				item.prev = function() {
					let prevIndex = item.index;
					while (prevIndex > 0) {
						let prev = this.get(prevIndex-1);
						if (prev && prev.linear) {
							return prev;
						}
						prevIndex -= 1;
					}
					return;
				}.bind(this);
				item.next = function() {
					let nextIndex = item.index;
					while (nextIndex < this.spineItems.length-1) {
						let next = this.get(nextIndex+1);
						if (next && next.linear) {
							return next;
						}
						nextIndex += 1;
					}
					return;
				}.bind(this);
			} else {
				item.prev = function() {
					return;
				}
				item.next = function() {
					return;
				}
			}


			spineItem = new section(item, this.hooks);

			this.append(spineItem);


		});

		this.loaded = true;
	}

	/**
	 * Get an item from the spine
	 * @param  {string|number} [target]
	 * @return {Section} section
	 * @example spine.get();
	 * @example spine.get(1);
	 * @example spine.get("chap1.html");
	 * @example spine.get("#id1234");
	 */
	get(target) {
		var index = 0;

		if (typeof target === "undefined") {
			while (index < this.spineItems.length) {
				let next = this.spineItems[index];
				if (next && next.linear) {
					break;
				}
				index += 1;
			}
		} else if(this.epubcfi.isCfiString(target)) {
			let cfi = new epubcfi(target);
			index = cfi.spinePos;
		} else if(typeof target === "number" || isNaN(target) === false){
			index = target;
		} else if(typeof target === "string" && target.indexOf("#") === 0) {
			index = this.spineById[target.substring(1)];
		} else if(typeof target === "string") {
			// Remove fragments
			target = target.split("#")[0];
			index = this.spineByAbsoluteHref[target] || this.spineByAbsoluteHref[encodeURI(target)] || this.spineByHref[target] || this.spineByHref[encodeURI(target)];
			if ( ! index ) {
				// check for relative paths
				for(var i = 0; i < this.spineItems.length; i++)	{
					if ( this.spineItems[i].href.indexOf('/' + target) > -1 ) {
						index = i;
						break;
					}
				}
			}
		}

		return this.spineItems[index] || null;
	}

	/**
	 * Append a Section to the Spine
	 * @private
	 * @param  {Section} section
	 */
	append(section) {
		var index = this.spineItems.length;
		section.index = index;

		this.spineItems.push(section);

		// Encode and Decode href lookups
		// see pr for details: https://github.com/futurepress/epub.js/pull/358
		this.spineByHref[decodeURI(section.href)] = index;
		this.spineByHref[encodeURI(section.href)] = index;
		this.spineByHref[section.href.substring(section.href.lastIndexOf('/')+1)] = index;
		this.spineByHref[section.href] = index;

		this.spineById[section.idref] = index;

		this.spineByAbsoluteHref[section.url] = index;

		return index;
	}

	/**
	 * Prepend a Section to the Spine
	 * @private
	 * @param  {Section} section
	 */
	prepend(section) {
		// var index = this.spineItems.unshift(section);
		this.spineByHref[section.href] = 0;
		this.spineById[section.idref] = 0;

		// Re-index
		this.spineItems.forEach(function(item, index){
			item.index = index;
		});

		return 0;
	}

	// insert(section, index) {
	//
	// };

	/**
	 * Remove a Section from the Spine
	 * @private
	 * @param  {Section} section
	 */
	remove(section) {
		var index = this.spineItems.indexOf(section);

		if(index > -1) {
			delete this.spineByHref[section.href];
			delete this.spineById[section.idref];

			return this.spineItems.splice(index, 1);
		}
	}

	/**
	 * Loop over the Sections in the Spine
	 * @return {method} forEach
	 */
	each() {
		return this.spineItems.forEach.apply(this.spineItems, arguments);
	}

	/**
	 * Find the first Section in the Spine
	 * @return {Section} first section
	 */
	first() {
		let index = 0;

		do {
			let next = this.get(index);

			if (next && next.linear) {
				return next;
			}
			index += 1;
		} while (index < this.spineItems.length) ;
	}

	/**
	 * Find the last Section in the Spine
	 * @return {Section} last section
	 */
	last() {
		let index = this.spineItems.length-1;

		do {
			let prev = this.get(index);
			if (prev && prev.linear) {
				return prev;
			}
			index -= 1;
		} while (index >= 0);
	}

	destroy() {
		this.each((section) => section.destroy());

		this.spineItems = undefined
		this.spineByHref = undefined
		this.spineById = undefined

		this.hooks.serialize.clear();
		this.hooks.content.clear();
		this.hooks = undefined;

		this.epubcfi = undefined;

		this.loaded = false;

		this.items = undefined;
		this.manifest = undefined;
		this.spineNodeIndex = undefined;
		this.baseUrl = undefined;
		this.length = undefined;
	}
}

/* harmony default export */ const spine = (Spine);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/utils/queue.js


/**
 * Queue for handling tasks one at a time
 * @class
 * @param {scope} context what this will resolve to in the tasks
 */
class Queue {
	constructor(context){
		this._q = [];
		this.context = context;
		this.tick = core.requestAnimationFrame;
		this.running = false;
		this.paused = false;
	}

	/**
	 * Add an item to the queue
	 * @return {Promise}
	 */
	enqueue() {
		var deferred, promise;
		var queued;
		var task = [].shift.call(arguments);
		var args = arguments;

		// Handle single args without context
		// if(args && !Array.isArray(args)) {
		//   args = [args];
		// }
		if(!task) {
			throw new Error("No Task Provided");
		}

		if(typeof task === "function"){

			deferred = new core.defer();
			promise = deferred.promise;

			queued = {
				"task" : task,
				"args"     : args,
				//"context"  : context,
				"deferred" : deferred,
				"promise" : promise
			};

		} else {
			// Task is a promise
			queued = {
				"promise" : task
			};

		}

		this._q.push(queued);

		// Wait to start queue flush
		if (this.paused == false && !this.running) {
			// setTimeout(this.flush.bind(this), 0);
			// this.tick.call(window, this.run.bind(this));
			this.run();
		}

		return queued.promise;
	}

	/**
	 * Run one item
	 * @return {Promise}
	 */
	dequeue(){
		var inwait, task, result;

		if(this._q.length && !this.paused) {
			inwait = this._q.shift();
			task = inwait.task;
			if(task){
				// console.log(task)

				result = task.apply(this.context, inwait.args);

				if(result && typeof result["then"] === "function") {
					// Task is a function that returns a promise
					return result.then(function(){
						inwait.deferred.resolve.apply(this.context, arguments);
					}.bind(this), function() {
						inwait.deferred.reject.apply(this.context, arguments);
					}.bind(this));
				} else {
					// Task resolves immediately
					inwait.deferred.resolve.apply(this.context, result);
					return inwait.promise;
				}



			} else if(inwait.promise) {
				// Task is a promise
				return inwait.promise;
			}

		} else {
			inwait = new core.defer();
			inwait.deferred.resolve();
			return inwait.promise;
		}

	}

	// Run All Immediately
	dump(){
		while(this._q.length) {
			this.dequeue();
		}
	}

	/**
	 * Run all tasks sequentially, at convince
	 * @return {Promise}
	 */
	run(){

		if(!this.running){
			this.running = true;
			this.defered = new core.defer();
		}

		this.tick.call(window, () => {

			if(this._q.length) {

				this.dequeue()
					.then(function(){
						this.run();
					}.bind(this));

			} else {
				this.defered.resolve();
				this.running = undefined;
			}

		});

		// Unpause
		if(this.paused == true) {
			this.paused = false;
		}

		return this.defered.promise;
	}

	/**
	 * Flush all, as quickly as possible
	 * @return {Promise}
	 */
	flush(){

		if(this.running){
			return this.running;
		}

		if(this._q.length) {
			this.running = this.dequeue()
				.then(function(){
					this.running = undefined;
					return this.flush();
				}.bind(this));

			return this.running;
		}

	}

	/**
	 * Clear all items in wait
	 */
	clear(){
		this._q = [];
	}

	/**
	 * Get the number of tasks in the queue
	 * @return {number} tasks
	 */
	length(){
		return this._q.length;
	}

	/**
	 * Pause a running queue
	 */
	pause(){
		this.paused = true;
	}

	/**
	 * End the queue
	 */
	stop(){
		this._q = [];
		this.running = false;
		this.paused = true;
	}
}


/**
 * Create a new task from a callback
 * @class
 * @private
 * @param {function} task
 * @param {array} args
 * @param {scope} context
 * @return {function} task
 */
class Task {
	constructor(task, args, context){

		return function(){
			var toApply = arguments || [];

			return new Promise( (resolve, reject) => {
				var callback = function(value, err){
					if (!value && err) {
						reject(err);
					} else {
						resolve(value);
					}
				};
				// Add the callback to the arguments list
				toApply.push(callback);

				// Apply all arguments to the functions
				task.apply(context || this, toApply);

			});

		};

	}
}


/* harmony default export */ const queue = (Queue);


;// CONCATENATED MODULE: ./node_modules/epubjs/src/utils/constants.js
const EPUBJS_VERSION = "0.3";

// Dom events to listen for
const DOM_EVENTS = ["keydown", "keyup", "keypressed", "mouseup", "mousedown", "click", "touchend", "touchstart", "touchmove"];

const EVENTS = {
  BOOK : {
    OPEN_FAILED : "openFailed"
  },
  CONTENTS : {
    EXPAND : "expand",
    RESIZE : "resize",
    SELECTED : "selected",
    SELECTED_RANGE : "selectedRange",
    LINK_CLICKED : "linkClicked"
  },
  LOCATIONS : {
    CHANGED : "changed"
  },
  MANAGERS : {
    RESIZE : "resize",
    RESIZED : "resized",
    ORIENTATION_CHANGE : "orientationchange",
    ADDED : "added",
    SCROLL : "scroll",
    SCROLLED : "scrolled",
    REMOVED : "removed",
  },
  VIEWS : {
    AXIS : "axis",
    LOAD_ERROR : "loaderror",
    RENDERED : "rendered",
    RESIZED : "resized",
    DISPLAYED : "displayed",
    SHOWN : "shown",
    HIDDEN : "hidden",
    MARK_CLICKED : "markClicked"
  },
  RENDITION : {
    STARTED : "started",
    ATTACHED : "attached",
    DISPLAYED : "displayed",
    DISPLAY_ERROR : "displayerror",
    RENDERED : "rendered",
    REMOVED : "removed",
    RESIZED : "resized",
    ORIENTATION_CHANGE : "orientationchange",
    LOCATION_CHANGED : "locationChanged",
    RELOCATED : "relocated",
    MARK_CLICKED : "markClicked",
    SELECTED : "selected",
    LAYOUT: "layout"
  },
  LAYOUT : {
    UPDATED : "updated"
  }
}

;// CONCATENATED MODULE: ./node_modules/epubjs/src/locations.js






/**
 * Find Locations for a Book
 * @param {Spine} spine
 * @param {request} request
 * @param {number} [pause=100]
 */
class Locations {
	constructor(spine, request, pause) {
		this.spine = spine;
		this.request = request;
		this.pause = pause || 100;

		this.q = new queue(this);
		this.epubcfi = new epubcfi();

		this._locations = [];
		this.total = 0;

		this.break = 150;

		this._current = 0;

		this.currentLocation = '';
		this._currentCfi ='';
		this.processingTimeout = undefined;
	}

	generateFromPageList(pageList) {

		this.break = 1600;
		this.q.pause();

		var i = 0;

		this._pageList = pageList;

		this.spine.each(function(section) {
			if (section.linear) {
				this.q.enqueue(this.process.bind(this), section);
			}
		}.bind(this));

		return this.q.run().then(function() {
			this.total = this._locations.length - 1;

			if (this._currentCfi) {
				this.currentLocation = this._currentCfi;
			}

			return this._locations;
		}.bind(this));
	}

	/**
	 * Load all of sections in the book to generate locations
	 * @param  {int} chars how many chars to split on
	 * @return {object} locations
	 */
	generate(chars) {

		if (chars) {
			this.break = chars;
		}

		this.q.pause();

		this.spine.each(function(section) {
			if (section.linear) {
				this.q.enqueue(this.process.bind(this), section);
			}
		}.bind(this));

		return this.q.run().then(function() {
			this.total = this._locations.length - 1;

			if (this._currentCfi) {
				this.currentLocation = this._currentCfi;
			}

			return this._locations;
			// console.log(this.percentage(this.book.rendition.location.start), this.percentage(this.book.rendition.location.end));
		}.bind(this));

	}

	createRange () {
		return {
			startContainer: undefined,
			startOffset: undefined,
			endContainer: undefined,
			endOffset: undefined
		};
	}

	process(section) {

		return section.load(this.request)
			.then(function(contents) {
				var completed = new core.defer();
				var locations = this.parse(contents, section.cfiBase);
				this._locations = this._locations.concat(locations);

				if ( this._pageList ) {

					var pages = this._pageList.pagesByAbsolutePath[section.canonical] || []; // || 

					pages.forEach((page) => {
						var item = this._pageList.pageList[page - 1];

						var parts = item.href.split('#');
						var target = parts[1] ? '#' + parts[1] : 'body';
						var node = contents.ownerDocument.querySelector(target);
						var cfi = section.cfiFromElement(node);
						this._pageList.locations[page - 1] = cfi;
					})
				}

				section.unload();

				this.processingTimeout = setTimeout(() => completed.resolve(locations), this.pause);
				return completed.promise;
			}.bind(this));

	}

	parse(contents, cfiBase, chars) {
		var locations = [];
		var range;
		var doc = contents.ownerDocument;
		var body = (0,core.qs)(doc, "body");
		var counter = 0;
		var prev;
		var _break = chars || this.break;
		var parser = function(node) {
			var len = node.length;
			var dist;
			var pos = 0;

			if (node.textContent.trim().length === 0) {
				return false; // continue
			}

			// Start range
			if (counter == 0) {
				range = this.createRange();
				range.startContainer = node;
				range.startOffset = 0;
			}

			dist = _break - counter;

			// Node is smaller than a break,
			// skip over it
			if(dist > len){
				counter += len;
				pos = len;
			}


			while (pos < len) {
				dist = _break - counter;

				if (counter === 0) {
					// Start new range
					pos += 1;
					range = this.createRange();
					range.startContainer = node;
					range.startOffset = pos;
				}

				// pos += dist;

				// Gone over
				if(pos + dist >= len){
					// Continue counter for next node
					counter += len - pos;
					// break
					pos = len;
				// At End
				} else {
					// Advance pos
					pos += dist;

					// End the previous range
					range.endContainer = node;
					range.endOffset = pos;
					// cfi = section.cfiFromRange(range);
					let cfi = new epubcfi(range, cfiBase).toString();
					locations.push(cfi);
					counter = 0;
				}
			}
			prev = node;
		};

		(0,core.sprint)(body, parser.bind(this));

		// Close remaining
		if (range && range.startContainer && prev) {
			range.endContainer = prev;
			range.endOffset = prev.length;
			let cfi = new epubcfi(range, cfiBase).toString();
			locations.push(cfi);
			counter = 0;
		}

		return locations;
	}

	/**
	 * Get a location from an EpubCFI
	 * @param {EpubCFI} cfi
	 * @return {number}
	 */
	locationFromCfi(cfi){
		let loc;
		if (epubcfi.prototype.isCfiString(cfi)) {
			cfi = new epubcfi(cfi);
		}
		// Check if the location has not been set yet
		if(this._locations.length === 0) {
			return -1;
		}

		loc = (0,core.locationOf)(cfi, this._locations, this.epubcfi.compare);

		if (loc > this.total) {
			return this.total;
		}

		return loc;
	}

	/**
	 * Get a percentage position in locations from an EpubCFI
	 * @param {EpubCFI} cfi
	 * @return {number}
	 */
	percentageFromCfi(cfi) {
		if(this._locations.length === 0) {
			return null;
		}
		// Find closest cfi
		var loc = this.locationFromCfi(cfi);
		// Get percentage in total
		return this.percentageFromLocation(loc);
	}

	/**
	 * Get a percentage position from a location index
	 * @param {number} location
	 * @return {number}
	 */
	percentageFromLocation(loc) {
		if (!loc || !this.total) {
			return 0;
		}

		return (loc / this.total);
	}

	/**
	 * Get an EpubCFI from location index
	 * @param {number} loc
	 * @return {EpubCFI} cfi
	 */
	cfiFromLocation(loc){
		var cfi = -1;
		// check that pg is an int
		if(typeof loc != "number"){
			loc = parseInt(loc);
		}

		if(loc >= 0 && loc < this._locations.length) {
			cfi = this._locations[loc];
		}

		return cfi;
	}

	/**
	 * Get an EpubCFI from location percentage
	 * @param {number} percentage
	 * @return {EpubCFI} cfi
	 */
	cfiFromPercentage(percentage){
		let loc;
		if (percentage > 1) {
			console.warn("Normalize cfiFromPercentage value to between 0 - 1");
		}

		// Make sure 1 goes to very end
		if (percentage >= 1) {
			let cfi = new epubcfi(this._locations[this.total]);
			cfi.collapse();
			return cfi.toString();
		}

		loc = Math.ceil(this.total * percentage);
		return this.cfiFromLocation(loc);
	}

	/**
	 * Load locations from JSON
	 * @param {json} locations
	 */
	load(locations){
		if (typeof locations === "string") {
			this._locations = JSON.parse(locations);
		} else {
			this._locations = locations;
		}
		this.total = this._locations.length - 1;
		return this._locations;
	}

	/**
	 * Save locations to JSON
	 * @return {json}
	 */
	save(){
		return JSON.stringify(this._locations);
	}

	getCurrent(){
		return this._current;
	}

	setCurrent(curr){
		var loc;

		if(typeof curr == "string"){
			this._currentCfi = curr;
		} else if (typeof curr == "number") {
			this._current = curr;
		} else {
			return;
		}

		if(this._locations.length === 0) {
			return;
		}

		if(typeof curr == "string"){
			loc = this.locationFromCfi(curr);
			this._current = loc;
		} else {
			loc = curr;
		}

		this.emit(EVENTS.LOCATIONS.CHANGED, {
			percentage: this.percentageFromLocation(loc)
		});
	}

	/**
	 * Get the current location
	 */
	get currentLocation() {
		return this._current;
	}

	/**
	 * Set the current location
	 */
	set currentLocation(curr) {
		this.setCurrent(curr);
	}

	/**
	 * Locations length
	 */
	length () {
		return this._locations.length;
	}

	destroy () {
		this.spine = undefined;
		this.request = undefined;
		this.pause = undefined;

		this.q.stop();
		this.q = undefined;
		this.epubcfi = undefined;

		this._locations = undefined
		this.total = undefined;

		this.break = undefined;
		this._current = undefined;

		this.currentLocation = undefined;
		this._currentCfi = undefined;
		clearTimeout(this.processingTimeout);
	}
}

event_emitter_default()(Locations.prototype);

/* harmony default export */ const locations = (Locations);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/container.js



/**
 * Handles Parsing and Accessing an Epub Container
 * @class
 * @param {document} [containerDocument] xml document
 */
class Container {
	constructor(containerDocument) {
		this.packagePath = '';
		this.directory = '';
		this.encoding = '';

		if (containerDocument) {
			this.parse(containerDocument);
		}
	}

	/**
	 * Parse the Container XML
	 * @param  {document} containerDocument
	 */
	parse(containerDocument){
		//-- <rootfile full-path="OPS/package.opf" media-type="application/oebps-package+xml"/>
		var rootfile;

		if(!containerDocument) {
			throw new Error("Container File Not Found");
		}

		rootfile = (0,core.qs)(containerDocument, "rootfile");

		if(!rootfile) {
			throw new Error("No RootFile Found");
		}

		this.packagePath = rootfile.getAttribute("full-path");
		this.directory = path_default().dirname(this.packagePath);
		this.encoding = containerDocument.xmlEncoding;
	}

	destroy() {
		this.packagePath = undefined;
		this.directory = undefined;
		this.encoding = undefined;
	}
}

/* harmony default export */ const container = (Container);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/packaging.js


/**
 * Open Packaging Format Parser
 * @class
 * @param {document} packageDocument OPF XML
 */
class Packaging {
	constructor(packageDocument) {
		this.manifest = {};
		this.navPath = '';
		this.ncxPath = '';
		this.coverPath = '';
		this.spineNodeIndex = 0;
		this.spine = [];
		this.metadata = {};

		if (packageDocument) {
			this.parse(packageDocument);
		}
	}

	/**
	 * Parse OPF XML
	 * @param  {document} packageDocument OPF XML
	 * @return {object} parsed package parts
	 */
	parse(packageDocument){
		var metadataNode, manifestNode, spineNode;

		if(!packageDocument) {
			throw new Error("Package File Not Found");
		}

		metadataNode = (0,core.qs)(packageDocument, "metadata");
		if(!metadataNode) {
			throw new Error("No Metadata Found");
		}

		manifestNode = (0,core.qs)(packageDocument, "manifest");
		if(!manifestNode) {
			throw new Error("No Manifest Found");
		}

		spineNode = (0,core.qs)(packageDocument, "spine");
		if(!spineNode) {
			throw new Error("No Spine Found");
		}

		this.manifest = this.parseManifest(manifestNode);
		this.navPath = this.findNavPath(manifestNode);
		this.ncxPath = this.findNcxPath(manifestNode, spineNode);
		this.coverPath = this.findCoverPath(packageDocument);

		this.spineNodeIndex = (0,core.indexOfElementNode)(spineNode);

		this.spine = this.parseSpine(spineNode, this.manifest);

		this.uniqueIdentifier = this.findUniqueIdentifier(packageDocument);
		this.metadata = this.parseMetadata(metadataNode);

		this.metadata.direction = spineNode.getAttribute("page-progression-direction");


		return {
			"metadata" : this.metadata,
			"spine"    : this.spine,
			"manifest" : this.manifest,
			"navPath"  : this.navPath,
			"ncxPath"  : this.ncxPath,
			"coverPath": this.coverPath,
			"spineNodeIndex" : this.spineNodeIndex
		};
	}

	/**
	 * Parse Metadata
	 * @private
	 * @param  {node} xml
	 * @return {object} metadata
	 */
	parseMetadata(xml){
		var metadata = {};

		metadata.title = this.getElementText(xml, "title");
		metadata.creator = this.getElementText(xml, "creator");
		metadata.description = this.getElementText(xml, "description");

		metadata.pubdate = this.getElementText(xml, "date");

		metadata.publisher = this.getElementText(xml, "publisher");

		metadata.identifier = this.getElementText(xml, "identifier");
		metadata.language = this.getElementText(xml, "language");
		metadata.rights = this.getElementText(xml, "rights");

		metadata.modified_date = this.getPropertyText(xml, "dcterms:modified");

		metadata.layout = this.getPropertyText(xml, "rendition:layout");
		metadata.orientation = this.getPropertyText(xml, "rendition:orientation");
		metadata.flow = this.getPropertyText(xml, "rendition:flow");
		metadata.viewport = this.getPropertyText(xml, "rendition:viewport");
		metadata.media_active_class = this.getPropertyText(xml, "media:active-class");
		// metadata.page_prog_dir = packageXml.querySelector("spine").getAttribute("page-progression-direction");

		return metadata;
	}

	/**
	 * Parse Manifest
	 * @private
	 * @param  {node} manifestXml
	 * @return {object} manifest
	 */
	parseManifest(manifestXml){
		var manifest = {};

		//-- Turn items into an array
		// var selected = manifestXml.querySelectorAll("item");
		var selected = (0,core.qsa)(manifestXml, "item");
		var items = Array.prototype.slice.call(selected);

		//-- Create an object with the id as key
		items.forEach(function(item){
			var id = item.getAttribute("id"),
					href = item.getAttribute("href") || "",
					type = item.getAttribute("media-type") || "",
					overlay = item.getAttribute("media-overlay") || "",
					properties = item.getAttribute("properties") || "";

			manifest[id] = {
				"href" : href,
				// "url" : href,
				"type" : type,
				"overlay" : overlay,
				"properties" : properties.length ? properties.split(" ") : []
			};

		});

		return manifest;

	}

	/**
	 * Parse Spine
	 * @private
	 * @param  {node} spineXml
	 * @param  {Packaging.manifest} manifest
	 * @return {object} spine
	 */
	parseSpine(spineXml, manifest){
		var spine = [];

		var selected = (0,core.qsa)(spineXml, "itemref");
		var items = Array.prototype.slice.call(selected);

		// var epubcfi = new EpubCFI();

		//-- Add to array to mantain ordering and cross reference with manifest
		items.forEach(function(item, index){
			var idref = item.getAttribute("idref");
			// var cfiBase = epubcfi.generateChapterComponent(spineNodeIndex, index, Id);
			var props = item.getAttribute("properties") || "";
			var propArray = props.length ? props.split(" ") : [];
			// var manifestProps = manifest[Id].properties;
			// var manifestPropArray = manifestProps.length ? manifestProps.split(" ") : [];

			var itemref = {
				"idref" : idref,
				"linear" : item.getAttribute("linear") || "yes",
				"properties" : propArray,
				// "href" : manifest[Id].href,
				// "url" :  manifest[Id].url,
				"index" : index
				// "cfiBase" : cfiBase
			};
			spine.push(itemref);
		});

		return spine;
	}

	/**
	 * Find Unique Identifier
	 * @private
	 * @param  {node} packageXml
	 * @return {string} Unique Identifier text
	 */
	findUniqueIdentifier(packageXml){
		var uniqueIdentifierId = packageXml.documentElement.getAttribute("unique-identifier");
		if (! uniqueIdentifierId) {
			return "";
		}
		var identifier = packageXml.getElementById(uniqueIdentifierId);
		if (! identifier) {
			return "";
		}

		if (identifier.localName === "identifier" && identifier.namespaceURI === "http://purl.org/dc/elements/1.1/") {
			return identifier.childNodes[0].nodeValue.trim();
		}

		return "";
	}

	/**
	 * Find TOC NAV
	 * @private
	 * @param {element} manifestNode
	 * @return {string}
	 */
	findNavPath(manifestNode){
		// Find item with property "nav"
		// Should catch nav irregardless of order
		// var node = manifestNode.querySelector("item[properties$='nav'], item[properties^='nav '], item[properties*=' nav ']");
		var node = (0,core.qsp)(manifestNode, "item", {"properties":"nav"});
		return node ? node.getAttribute("href") : false;
	}

	/**
	 * Find TOC NCX
	 * media-type="application/x-dtbncx+xml" href="toc.ncx"
	 * @private
	 * @param {element} manifestNode
	 * @param {element} spineNode
	 * @return {string}
	 */
	findNcxPath(manifestNode, spineNode){
		// var node = manifestNode.querySelector("item[media-type='application/x-dtbncx+xml']");
		var node = (0,core.qsp)(manifestNode, "item", {"media-type":"application/x-dtbncx+xml"});
		var tocId;

		// If we can't find the toc by media-type then try to look for id of the item in the spine attributes as
		// according to http://www.idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#Section2.4.1.2,
		// "The item that describes the NCX must be referenced by the spine toc attribute."
		if (!node) {
			tocId = spineNode.getAttribute("toc");
			if(tocId) {
				// node = manifestNode.querySelector("item[id='" + tocId + "']");
				node = manifestNode.querySelector(`#${tocId}`);
			}
		}

		return node ? node.getAttribute("href") : false;
	}

	/**
	 * Find the Cover Path
	 * <item properties="cover-image" id="ci" href="cover.svg" media-type="image/svg+xml" />
	 * Fallback for Epub 2.0
	 * @private
	 * @param  {node} packageXml
	 * @return {string} href
	 */
	findCoverPath(packageXml){
		var pkg = (0,core.qs)(packageXml, "package");
		var epubVersion = pkg.getAttribute("version");

		if (epubVersion === "2.0") {
			var metaCover = (0,core.qsp)(packageXml, "meta", {"name":"cover"});
			if (metaCover) {
				var coverId = metaCover.getAttribute("content");
				// var cover = packageXml.querySelector("item[id='" + coverId + "']");
				var cover = packageXml.getElementById(coverId);
				return cover ? cover.getAttribute("href") : "";
			}
			else {
				return false;
			}
		}
		else {
			// var node = packageXml.querySelector("item[properties='cover-image']");
			var node = (0,core.qsp)(packageXml, "item", {"properties":"cover-image"});
			return node ? node.getAttribute("href") : "";
		}
	}

	/**
	 * Get text of a namespaced element
	 * @private
	 * @param  {node} xml
	 * @param  {string} tag
	 * @return {string} text
	 */
	getElementText(xml, tag){
		var found = xml.getElementsByTagNameNS("http://purl.org/dc/elements/1.1/", tag);
		var el;

		if(!found || found.length === 0) return "";

		el = found[0];

		if(el.childNodes.length){
			return el.childNodes[0].nodeValue;
		}

		return "";

	}

	/**
	 * Get text by property
	 * @private
	 * @param  {node} xml
	 * @param  {string} property
	 * @return {string} text
	 */
	getPropertyText(xml, property){
		var el = (0,core.qsp)(xml, "meta", {"property":property});

		if(el && el.childNodes.length){
			return el.childNodes[0].nodeValue;
		}

		return "";
	}

	/**
	 * Load JSON Manifest
	 * @param  {document} packageDocument OPF XML
	 * @return {object} parsed package parts
	 */
	load(json) {
		this.metadata = json.metadata;

		let spine = json.readingOrder || json.spine;
		this.spine = spine.map((item, index) =>{
			item.index = index;
			return item;
		});

		json.resources.forEach((item, index) => {
			this.manifest[index] = item;

			if (item.rel && item.rel[0] === "cover") {
				this.coverPath = item.href;
			}
		});

		this.spineNodeIndex = 0;

		this.toc = json.toc.map((item, index) =>{
			item.label = item.title;
			return item;
		});

		return {
			"metadata" : this.metadata,
			"spine"    : this.spine,
			"manifest" : this.manifest,
			"navPath"  : this.navPath,
			"ncxPath"  : this.ncxPath,
			"coverPath": this.coverPath,
			"spineNodeIndex" : this.spineNodeIndex,
			"toc" : this.toc
		};
	}

	destroy() {
		this.manifest = undefined;
		this.navPath = undefined;
		this.ncxPath = undefined;
		this.coverPath = undefined;
		this.spineNodeIndex = undefined;
		this.spine = undefined;
		this.metadata = undefined;
	}
}

/* harmony default export */ const packaging = (Packaging);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/navigation.js


/**
 * Navigation Parser
 * @param {document} xml navigation html / xhtml / ncx
 */
class Navigation {
	constructor(xml, path, canonical) {
		this.toc = [];
		this.tocByHref = {};
		this.tocById = {};

		this.landmarks = [];
		this.landmarksByType = {};

		this.canonical = canonical;

		this.path = path;

		this.length = 0;
		if (xml) {
			this.parse(xml);
		}
	}

	/**
	 * Parse out the navigation items
	 * @param {document} xml navigation html / xhtml / ncx
	 */
	parse(xml) {
		let isXml = xml.nodeType;
		let html;
		let ncx;

		if (isXml) {
			html = (0,core.qs)(xml, "html");
			ncx = (0,core.qs)(xml, "ncx");
		}

		if (!isXml) {
			this.toc = this.load(xml);
		} else if(html) {
			this.toc = this.parseNav(xml);
			this.landmarks = this.parseLandmarks(xml);
		} else if(ncx){
			this.toc = this.parseNcx(xml);
		}

		this.length = 0;

		this.unpack(this.toc);
	}

	/**
	 * Unpack navigation items
	 * @private
	 * @param  {array} toc
	 */
	unpack(toc) {
		var item;

		for (var i = 0; i < toc.length; i++) {
			item = toc[i];

			if (item.href) {
				this.tocByHref[item.href] = i;
			}

			if (item.id) {
				this.tocById[item.id] = i;
			}

			this.length++;

			if (item.subitems.length) {
				this.unpack(item.subitems);
			}
		}

	}

	/**
	 * Get an item from the navigation
	 * @param  {string} target
	 * @return {object} navItem
	 */
	get(target) {
		var index;

		if(!target) {
			return this.toc;
		}

		if(target.indexOf("#") === 0) {
			index = this.tocById[target.substring(1)];
		} else if(target in this.tocByHref){
			index = this.tocByHref[target];
		}

		return this.toc[index];
	}

	/**
	 * Get a landmark by type
	 * List of types: https://idpf.github.io/epub-vocabs/structure/
	 * @param  {string} type
	 * @return {object} landmarkItem
	 */
	landmark(type) {
		var index;

		if(!type) {
			return this.landmarks;
		}

		index = this.landmarksByType[type];

		return this.landmarks[index];
	}

	/**
	 * Parse toc from a Epub > 3.0 Nav
	 * @private
	 * @param  {document} navHtml
	 * @return {array} navigation list
	 */
	parseNav(navHtml){
		var navElement = (0,core.querySelectorByType)(navHtml, "nav", "toc");
		var navItems = navElement ? (0,core.qsa)(navElement, "li") : [];
		var length = navItems.length;
		var i;
		var toc = {};
		var list = [];
		var item, parent;

		if(!navItems || length === 0) return list;

		for (i = 0; i < length; ++i) {
			item = this.navItem(navItems[i]);
			if (item) {
				toc[item.id] = item;
				if(!item.parent) {
					list.push(item);
				} else {
					parent = toc[item.parent];
					parent.subitems.push(item);
				}
			}
		}

		return list;
	}

	/**
	 * Create a navItem
	 * @private
	 * @param  {element} item
	 * @return {object} navItem
	 */
	navItem(item){
		let id = item.getAttribute("id") || undefined;
		let content = (0,core.filterChildren)(item, "a", true);

		if (!content) {
			return;
		}

		let src = content.getAttribute("href") || "";
		
		if (!id) {
			id = src;
		}
		let text = content.textContent || "";
		let html = content.innerHTML;
		let subitems = [];
		let parentItem = (0,core.getParentByTagName)(item, "li");
		let parent;

		if (parentItem) {
			parent = parentItem.getAttribute("id");
			if (!parent) {
				const parentContent = (0,core.filterChildren)(parentItem, "a", true);
				parent = parentContent && parentContent.getAttribute("href");
      			}
		}

		while (!parent && parentItem) {
			parentItem = (0,core.getParentByTagName)(parentItem, "li");
			if (parentItem) {
				parent = parentItem.getAttribute("id");
				if (!parent) {
					const parentContent = (0,core.filterChildren)(parentItem, "a", true);
          				parent = parentContent && parentContent.getAttribute("href");
        			}
			}
		}

		var path = this.path.resolve(src);

		return {
			"id": id,
			"href": src,
			"canonical": this.canonical(path),
			"label": text,
			"html": html,
			"subitems" : subitems,
			"parent" : parent
		};
	}

	/**
	 * Parse landmarks from a Epub > 3.0 Nav
	 * @private
	 * @param  {document} navHtml
	 * @return {array} landmarks list
	 */
	parseLandmarks(navHtml){
		var navElement = (0,core.querySelectorByType)(navHtml, "nav", "landmarks");
		var navItems = navElement ? (0,core.qsa)(navElement, "li") : [];
		var length = navItems.length;
		var i;
		var list = [];
		var item;

		if(!navItems || length === 0) return list;

		for (i = 0; i < length; ++i) {
			item = this.landmarkItem(navItems[i]);
			if (item) {
				list.push(item);
				this.landmarksByType[item.type] = i;
			}
		}

		return list;
	}

	/**
	 * Create a landmarkItem
	 * @private
	 * @param  {element} item
	 * @return {object} landmarkItem
	 */
	landmarkItem(item){
		let content = (0,core.filterChildren)(item, "a", true);

		if (!content) {
			return;
		}

		let type = content.getAttributeNS("http://www.idpf.org/2007/ops", "type") || undefined;
		let href = content.getAttribute("href") || "";
		let text = content.textContent || "";

		return {
			"href": href,
			"label": text,
			"type" : type
		};
	}

	/**
	 * Parse from a Epub > 3.0 NC
	 * @private
	 * @param  {document} navHtml
	 * @return {array} navigation list
	 */
	parseNcx(tocXml){
		var navPoints = (0,core.qsa)(tocXml, "navPoint");
		var length = navPoints.length;
		var i;
		var toc = {};
		var list = [];
		var item, parent;

		if(!navPoints || length === 0) return list;

		for (i = 0; i < length; ++i) {
			item = this.ncxItem(navPoints[i]);
			toc[item.id] = item;
			if(!item.parent) {
				list.push(item);
			} else {
				parent = toc[item.parent];
				parent.subitems.push(item);
			}
		}

		return list;
	}

	/**
	 * Create a ncxItem
	 * @private
	 * @param  {element} item
	 * @return {object} ncxItem
	 */
	ncxItem(item){
		var id = item.getAttribute("id") || false,
				content = (0,core.qs)(item, "content"),
				src = content.getAttribute("src"),
				navLabel = (0,core.qs)(item, "navLabel"),
				text = navLabel.textContent ? navLabel.textContent : "",
				subitems = [],
				parentNode = item.parentNode,
				parent;

		if(parentNode && (parentNode.nodeName === "navPoint" || parentNode.nodeName.split(':').slice(-1)[0] === "navPoint")) {
			parent = parentNode.getAttribute("id");
		}


		return {
			"id": id,
			"href": src,
			"label": text,
			"subitems" : subitems,
			"parent" : parent
		};
	}

	/**
	 * Load Spine Items
	 * @param  {object} json the items to be loaded
	 * @return {Array} navItems
	 */
	load(json) {
		return json.map(item => {
			item.label = item.title;
			item.subitems = item.children ? this.load(item.children) : [];
			return item;
		});
	}

	/**
	 * forEach pass through
	 * @param  {Function} fn function to run on each item
	 * @return {method} forEach loop
	 */
	forEach(fn) {
		return this.toc.forEach(fn);
	}
}

/* harmony default export */ const navigation = (Navigation);

// EXTERNAL MODULE: ./node_modules/epubjs/libs/mime/mime.js
var mime = __webpack_require__(1597);
var mime_default = /*#__PURE__*/__webpack_require__.n(mime);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/resources.js







/**
 * Handle Package Resources
 * @class
 * @param {Manifest} manifest
 * @param {object} [options]
 * @param {string} [options.replacements="base64"]
 * @param {Archive} [options.archive]
 * @param {method} [options.resolver]
 */
class Resources {
	constructor(manifest, options) {
		this.settings = {
			replacements: (options && options.replacements) || "base64",
			archive: (options && options.archive),
			resolver: (options && options.resolver),
			request: (options && options.request)
		};

		this.process(manifest);
	}

	/**
	 * Process resources
	 * @param {Manifest} manifest
	 */
	process(manifest){
		this.manifest = manifest;
		this.resources = Object.keys(manifest).
			map(function (key){
				return manifest[key];
			});

		this.replacementUrls = [];

		this.html = [];
		this.assets = [];
		this.css = [];

		this.urls = [];
		this.cssUrls = [];

		this.split();
		this.splitUrls();
	}

	/**
	 * Split resources by type
	 * @private
	 */
	split(){

		// HTML
		this.html = this.resources.
			filter(function (item){
				if (item.type === "application/xhtml+xml" ||
						item.type === "text/html") {
					return true;
				}
			});

		// Exclude HTML
		this.assets = this.resources.
			filter(function (item){
				if (item.type !== "application/xhtml+xml" &&
						item.type !== "text/html") {
					return true;
				}
			});

		// Only CSS
		this.css = this.resources.
			filter(function (item){
				if (item.type === "text/css") {
					return true;
				}
			});
	}

	/**
	 * Convert split resources into Urls
	 * @private
	 */
	splitUrls(){

		// All Assets Urls
		this.urls = this.assets.
			map(function(item) {
				return item.href;
			}.bind(this));

		// Css Urls
		this.cssUrls = this.css.map(function(item) {
			return item.href;
		});

	}

	/**
	 * Create a url to a resource
	 * @param {string} url
	 * @return {Promise<string>} Promise resolves with url string
	 */
	createUrl (url) {
		var parsedUrl = new utils_url(url);
		var mimeType = mime_default().lookup(parsedUrl.filename);

		if (this.settings.archive) {
			return this.settings.archive.createUrl(url, {"base64": (this.settings.replacements === "base64")});
		} else {
			if (this.settings.replacements === "base64") {
				return this.settings.request(url, 'blob')
					.then((blob) => {
						return (0,core.blob2base64)(blob);
					})
					.then((blob) => {
						return (0,core.createBase64Url)(blob, mimeType);
					});
			} else {
				return this.settings.request(url, 'blob').then((blob) => {
					return (0,core.createBlobUrl)(blob, mimeType);
				})
			}
		}
	}

	/**
	 * Create blob urls for all the assets
	 * @return {Promise}         returns replacement urls
	 */
	replacements(){
		if (this.settings.replacements === "none") {
			return new Promise(function(resolve) {
				resolve(this.urls);
			}.bind(this));
		}

		var replacements = this.urls.
			map( (url) => {
				var absolute = this.settings.resolver(url);

				return this.createUrl(absolute).
					catch((err) => {
						console.error(err);
						return null;
					});
			});

		return Promise.all(replacements)
			.then( (replacementUrls) => {
				this.replacementUrls = replacementUrls.filter((url) => {
					return (typeof(url) === "string");
				});
				return replacementUrls;
			});
	}

	/**
	 * Replace URLs in CSS resources
	 * @private
	 * @param  {Archive} [archive]
	 * @param  {method} [resolver]
	 * @return {Promise}
	 */
	replaceCss(archive, resolver){
		var replaced = [];
		archive = archive || this.settings.archive;
		resolver = resolver || this.settings.resolver;
		this.cssUrls.forEach(function(href) {
			var replacement = this.createCssFile(href, archive, resolver)
				.then(function (replacementUrl) {
					// switch the url in the replacementUrls
					var indexInUrls = this.urls.indexOf(href);
					if (indexInUrls > -1) {
						this.replacementUrls[indexInUrls] = replacementUrl;
					}
				}.bind(this))


			replaced.push(replacement);
		}.bind(this));
		return Promise.all(replaced);
	}

	/**
	 * Create a new CSS file with the replaced URLs
	 * @private
	 * @param  {string} href the original css file
	 * @return {Promise}  returns a BlobUrl to the new CSS file or a data url
	 */
	createCssFile(href){
		var newUrl;

		if (path_default().isAbsolute(href)) {
			return new Promise(function(resolve){
				resolve();
			});
		}

		var absolute = this.settings.resolver(href);

		// Get the text of the css file from the archive
		var textResponse;

		if (this.settings.archive) {
			textResponse = this.settings.archive.getText(absolute);
		} else {
			textResponse = this.settings.request(absolute, "text");
		}

		// Get asset links relative to css file
		var relUrls = this.urls.map( (assetHref) => {
			var resolved = this.settings.resolver(assetHref);
			var relative = new utils_path/* default */.Z(absolute).relative(resolved);

			return relative;
		});

		if (!textResponse) {
			// file not found, don't replace
			return new Promise(function(resolve){
				resolve();
			});
		}

		return textResponse.then( (text) => {
			// Replacements in the css text
			text = substitute(text, relUrls, this.replacementUrls);

			// Get the new url
			if (this.settings.replacements === "base64") {
				newUrl = (0,core.createBase64Url)(text, "text/css");
			} else {
				newUrl = (0,core.createBlobUrl)(text, "text/css");
			}

			return newUrl;
		}, (err) => {
			// handle response errors
			return new Promise(function(resolve){
				resolve();
			});
		});

	}

	/**
	 * Resolve all resources URLs relative to an absolute URL
	 * @param  {string} absolute to be resolved to
	 * @param  {resolver} [resolver]
	 * @return {string[]} array with relative Urls
	 */
	relativeTo(absolute, resolver){
		resolver = resolver || this.settings.resolver;

		// Get Urls relative to current sections
		return this.urls.
			map(function(href) {
				var resolved = resolver(href);
				var relative = new utils_path/* default */.Z(absolute).relative(resolved);
				return relative;
			}.bind(this));
	}

	/**
	 * Get a URL for a resource
	 * @param  {string} path
	 * @return {string} url
	 */
	get(path) {
		var indexInUrls = this.urls.indexOf(path);
		if (indexInUrls === -1) {
			return;
		}
		if (this.replacementUrls.length) {
			return new Promise(function(resolve, reject) {
				resolve(this.replacementUrls[indexInUrls]);
			}.bind(this));
		} else {
			return this.createUrl(path);
		}
	}

	/**
	 * Substitute urls in content, with replacements,
	 * relative to a url if provided
	 * @param  {string} content
	 * @param  {string} [url]   url to resolve to
	 * @return {string}         content with urls substituted
	 */
	substitute(content, url) {
		var relUrls;
		if (url) {
			relUrls = this.relativeTo(url);
		} else {
			relUrls = this.urls;
		}
		return substitute(content, relUrls, this.replacementUrls);
	}

	destroy() {
		this.settings = undefined;
		this.manifest = undefined;
		this.resources = undefined;
		this.replacementUrls = undefined;
		this.html = undefined;
		this.assets = undefined;
		this.css = undefined;

		this.urls = undefined;
		this.cssUrls = undefined;
	}
}

/* harmony default export */ const resources = (Resources);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/pagelist.js



/**
 * Page List Parser
 * @param {document} [xml]
 */
class PageList {
	constructor(xml, path, canonical) {
		this.pages = [];
		this.locations = [];
		this.epubcfi = new epubcfi();

		this.firstPage = 0;
		this.lastPage = 0;
		this.totalPages = 0;

		this.pagesByAbsolutePath = {};

		this.toc = undefined;
		this.ncx = undefined;

		this.path = path;
		this.canonical = canonical;

		if (xml) {
			this.pageList = this.parse(xml);
		}

		if(this.pageList && this.pageList.length) {
			this.process(this.pageList);
		}
	}

	/**
	 * Parse PageList Xml
	 * @param  {document} xml
	 */
	parse(xml) {
		var html = (0,core.qs)(xml, "html");
		var ncx = (0,core.qs)(xml, "ncx");

		if(html) {
			return this.parseNav(xml);
		} else if(ncx){ // Not supported
			// return this.parseNcx(xml);
			return;
		}

	}

	/**
	 * Parse a Nav PageList
	 * @private
	 * @param  {node} navHtml
	 * @return {PageList.item[]} list
	 */
	parseNav(navHtml){
		var navElement = (0,core.querySelectorByType)(navHtml, "nav", "page-list");
		var navItems = navElement ? (0,core.qsa)(navElement, "li") : [];
		var length = navItems.length;
		var i;
		var list = [];
		var item;

		if(!navItems || length === 0) return list;

		for (i = 0; i < length; ++i) {
			item = this.item(navItems[i], i);
			list.push(item);
		}

		return list;
	}

	/**
	 * Page List Item
	 * @private
	 * @param  {node} item
	 * @return {object} pageListItem
	 */
	item(item, i){
		var content = (0,core.qs)(item, "a"),
				href = content.getAttribute("href") || "",
				text = content.textContent || "",
				pageLabel = text,
				page = i + 1, 
				isCfi = href.indexOf("epubcfi"),
				split,
				packageUrl,
				cfi;

		if(isCfi != -1) {
			split = href.split("#");
			packageUrl = split[0];
			cfi = split.length > 1 ? split[1] : false;
			return {
				"cfi" : cfi,
				"href" : href,
				"packageUrl" : packageUrl,
				"page" : page,
				"pageLabel": pageLabel
			};
		} else {
			return {
				"href" : href,
				"page" : page,
				"pageLabel": pageLabel
			};
		}
	}

	/**
	 * Process pageList items
	 * @private
	 * @param  {array} pageList
	 */
	process(pageList){
		pageList.forEach(function(item){
			this.pages.push(item.page);
			if (item.cfi) {
				this.locations.push(item.cfi);
			}
			if ( item.href ) {
				var href = (item.href.split('#'))[0];
				var path = this.path.resolve(href);
				var absolute = this.canonical(path);
				if ( this.pagesByAbsolutePath[absolute] == null ) {
					this.pagesByAbsolutePath[absolute] = [];
				}
				this.pagesByAbsolutePath[absolute].push(item.page);
			}
		}, this);
		this.firstPage = parseInt(this.pages[0]);
		this.lastPage = parseInt(this.pages[this.pages.length-1]);
		this.totalPages = this.lastPage - this.firstPage;
		this.firstPageLabel = this.pageList[0].pageLabel;
		this.lastPageLabel = this.pageList[this.pageList.length - 1].pageLabel;
	}

	/**
	 * Get a PageList result from a EpubCFI
	 * @param  {string} cfi EpubCFI String
	 * @return {number} page
	 */
	pageFromCfi(cfi){
		var pg = -1;

		// Check if the pageList has not been set yet
		if(this.locations.length === 0) {
			return -1;
		}

		// TODO: check if CFI is valid?

		// check if the cfi is in the location list
		// var index = this.locations.indexOf(cfi);
		var index = (0,core.indexOfSorted)(cfi, this.locations, this.epubcfi.compare);
		if(index != -1) {
			pg = this.pages[index];
		} else {
			// Otherwise add it to the list of locations
			// Insert it in the correct position in the locations page
			//index = EPUBJS.core.insert(cfi, this.locations, this.epubcfi.compare);
			index = (0,core.locationOf)(cfi, this.locations, this.epubcfi.compare);
			// Get the page at the location just before the new one, or return the first
			pg = index-1 >= 0 ? this.pages[index-1] : this.pages[0];
			if(pg !== undefined) {
				// Add the new page in so that the locations and page array match up
				//this.pages.splice(index, 0, pg);
			} else {
				pg = -1;
			}

		}
		return pg;
	}

	pagesFromLocation(location) {
		var pgs = [];

		// Check if the pageList has not been set yet
		if(this.locations.length === 0) {
			return [];
		}

		var pg = this.pageFromCfi(location.start.cfi);
		if ( pg == -1 || pg >= this.locations.length ) {
			return [];
		}

		pgs.push(pg);
		pg = this.pageFromCfi(location.end.cfi);
		if ( pg != pgs[0] ) {
			pgs.push(pg);
		}

		return pgs;
	}

	pageLabel(page) {
		var item = this.pageList[page];
		if ( item ) {
			return item.pageLabel || `#${page}`;
		}
		return -1;
	}

	/**
	 * Get an EpubCFI from a Page List Item
	 * @param  {string | number} pg
	 * @return {string} cfi
	 */
	cfiFromPage(pg){
		var cfi = -1;
		// check that pg is an int
		if(typeof pg != "number"){
			pg = parseInt(pg);
		}

		// check if the cfi is in the page list
		// Pages could be unsorted.
		var index = this.pages.indexOf(pg);
		if(index != -1) {
			cfi = this.locations[index];
		}
		// TODO: handle pages not in the list
		return cfi;
	}

	cfiFromPageLabel(pageLabel) {
		var item = this.pageList.find(item => item.pageLabel == pageLabel);
		if ( item ) {
			return this.cfiFromPage(item.page);
		}
		return -1;
	}

	/**
	 * Get a Page from Book percentage
	 * @param  {number} percent
	 * @return {number} page
	 */
	pageFromPercentage(percent){
		var pg = Math.round(this.totalPages * percent);
		return pg;
	}

	itemFromPercentage(percent) {
		var pg = this.pageFromPercentage(percent);
		return this.pageList[pg - 1];
	}

	itemFromCfi(cfi) {
		var pg = this.pageFromCfi(cfi);
		return this.pageList[pg - 1];
	}

	/**
	 * Returns a value between 0 - 1 corresponding to the location of a page
	 * @param  {number} pg the page
	 * @return {number} percentage
	 */
	percentageFromPage(pg){
		var percentage = (pg - this.firstPage) / this.totalPages;
		return Math.round(percentage * 1000) / 1000;
	}

	/**
	 * Returns a value between 0 - 1 corresponding to the location of a cfi
	 * @param  {string} cfi EpubCFI String
	 * @return {number} percentage
	 */
	percentageFromCfi(cfi){
		var pg = this.pageFromCfi(cfi);
		var percentage = this.percentageFromPage(pg);
		return percentage;
	}

	/**
	 * Destroy
	 */
	destroy() {
		this.pages = undefined;
		this.locations = undefined;
		this.epubcfi = undefined;

		this.pageList = undefined;

		this.toc = undefined;
		this.ncx = undefined;
	}
}

/* harmony default export */ const pagelist = (PageList);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/layout.js




/**
 * Figures out the CSS values to apply for a layout
 * @class
 * @param {object} settings
 * @param {string} [settings.layout='reflowable']
 * @param {string} [settings.spread]
 * @param {number} [settings.minSpreadWidth=800]
 * @param {boolean} [settings.evenSpreads=false]
 */
class Layout {
	constructor(settings) {
		this.settings = settings;
		this.name = settings.layout || "reflowable";
		this._spread = (settings.spread === "none") ? false : true;
		this._minSpreadWidth = settings.minSpreadWidth || 800;
		this._evenSpreads = settings.evenSpreads || false;

		if (settings.flow === "scrolled" ||
				settings.flow === "scrolled-continuous" ||
				settings.flow === "scrolled-doc") {
			this._flow = "scrolled";
		} else {
			this._flow = "paginated";
		}


		this.width = 0;
		this.height = 0;
		this.spreadWidth = 0;
		this.delta = 0;

		this.columnWidth = 0;
		this.gap = 0;
		this.divisor = 1;

		this.props = {
			name: this.name,
			spread: this._spread,
			flow: this._flow,
			width: 0,
			height: 0,
			spreadWidth: 0,
			delta: 0,
			columnWidth: 0,
			gap: 0,
			divisor: 1
		};

	}

	/**
	 * Switch the flow between paginated and scrolled
	 * @param  {string} flow paginated | scrolled
	 * @return {string} simplified flow
	 */
	flow(flow) {
		if (typeof(flow) != "undefined") {
			if (flow === "scrolled" ||
					flow === "scrolled-continuous" ||
					flow === "scrolled-doc") {
				this._flow = "scrolled";
			} else {
				this._flow = "paginated";
			}
			// this.props.flow = this._flow;
			this.update({flow: this._flow});
		}
		return this._flow;
	}

	/**
	 * Switch between using spreads or not, and set the
	 * width at which they switch to single.
	 * @param  {string} spread "none" | "always" | "auto"
	 * @param  {number} min integer in pixels
	 * @return {boolean} spread true | false
	 */
	spread(spread, min) {

		if (spread) {
			this._spread = (spread === "none") ? false : true;
			// this.props.spread = this._spread;
			this.update({spread: this._spread});
		}

		if (min >= 0) {
			this._minSpreadWidth = min;
		}

		return this._spread;
	}

	/**
	 * Calculate the dimensions of the pagination
	 * @param  {number} _width  width of the rendering
	 * @param  {number} _height height of the rendering
	 * @param  {number} _gap    width of the gap between columns
	 */
	calculate(_width, _height, _gap){

		var divisor = 1;
		var gap = _gap || 0;

		//-- Check the width and create even width columns
		// var fullWidth = Math.floor(_width);
		var width = _width;
		var height = _height;

		var section = Math.floor(width / 12);

		var columnWidth;
		var spreadWidth;
		var pageWidth;
		var delta;

		if (this._spread && width >= this._minSpreadWidth) {
			divisor = 2;
		} else {
			divisor = 1;
		}

		if (this.name === "reflowable" && this._flow === "paginated" && !(_gap >= 0)) {
			gap = ((section % 2 === 0) ? section : section - 1);
		}

		if (this.name === "pre-paginated" ) {
			gap = 0;
		}

		//-- Double Page
		if(divisor > 1) {
			// width = width - gap;
			// columnWidth = (width - gap) / divisor;
			// gap = gap / divisor;
			columnWidth = (width / divisor) - gap;
			pageWidth = columnWidth + gap;
		} else {
			columnWidth = width;
			pageWidth = width;
		}

		if (this.name === "pre-paginated" && divisor > 1) {
			width = columnWidth;
		}

		spreadWidth = (columnWidth * divisor) + gap;

		delta = Math.ceil(width);

		this.width = width;
		this.height = height;
		this.spreadWidth = spreadWidth;
		this.pageWidth = pageWidth;
		this.delta = delta;

		this.columnWidth = columnWidth;
		this.gap = gap;
		this.divisor = divisor;

		// this.props.width = width;
		// this.props.height = _height;
		// this.props.spreadWidth = spreadWidth;
		// this.props.pageWidth = pageWidth;
		// this.props.delta = delta;
		//
		// this.props.columnWidth = colWidth;
		// this.props.gap = gap;
		// this.props.divisor = divisor;

		this.update({
			width,
			height,
			spreadWidth,
			pageWidth,
			delta,
			columnWidth,
			gap,
			divisor
		});

	}

	/**
	 * Apply Css to a Document
	 * @param  {Contents} contents
	 * @return {Promise}
	 */
	format(contents){
		var formating;

		var viewport = contents.viewport();
		// console.log("AHOY contents.format VIEWPORT", this.name, viewport.height);
		if (this.name === "pre-paginated" && viewport.height != 'auto' && viewport.height != undefined ) {
			// console.log("AHOY CONTENTS format", this.columnWidth, this.height);
			formating = contents.fit(this.columnWidth, this.height);
		} else if (this._flow === "paginated") {
			formating = contents.columns(this.width, this.height, this.columnWidth, this.gap);
		} else { // scrolled
			formating = contents.size(this.width, null);
			if ( this.name === 'pre-paginated' ) {
				contents.content.style.overflow = 'auto';
				contents.addStylesheetRules({
					"body": {
						"margin": 0,
						"padding": "1em !important",
						"box-sizing": "border-box"
					}
				})
			}
		}

		return formating; // might be a promise in some View Managers
	}

	/**
	 * Count number of pages
	 * @param  {number} totalLength
	 * @param  {number} pageLength
	 * @return {{spreads: Number, pages: Number}}
	 */
	count(totalLength, pageLength) {

		let spreads, pages;

		if (this.name === "pre-paginated") {
			spreads = 1;
			pages = 1;
		} else if (this._flow === "paginated") {
			pageLength = pageLength || this.delta;
			spreads = Math.ceil( totalLength / pageLength);
			pages = spreads * this.divisor;
		} else { // scrolled
			pageLength = pageLength || this.height;
			spreads = Math.ceil( totalLength / pageLength);
			pages = spreads;
		}

		return {
			spreads,
			pages
		};

	}

	/**
	 * Update props that have changed
	 * @private
	 * @param  {object} props
	 */
	update(props) {
		// Remove props that haven't changed
		Object.keys(props).forEach((propName) => {
			if (this.props[propName] === props[propName]) {
				delete props[propName];
			}
		});

		if(Object.keys(props).length > 0) {
			let newProps = (0,core.extend)(this.props, props);
			this.emit(EVENTS.LAYOUT.UPDATED, newProps, props);
		}
	}
}

event_emitter_default()(Layout.prototype);

/* harmony default export */ const layout = (Layout);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/themes.js


/**
 * Themes to apply to displayed content
 * @class
 * @param {Rendition} rendition
 */
class Themes {
	constructor(rendition) {
		this.rendition = rendition;
		this._themes = {
			"default" : {
				"rules" : {},
				"url" : "",
				"serialized" : ""
			}
		};
		this._overrides = {};
		this._current = "default";
		this._injected = [];
		this.rendition.hooks.content.register(this.inject.bind(this));
		this.rendition.hooks.content.register(this.overrides.bind(this));

	}

	/**
	 * Add themes to be used by a rendition
	 * @param {object | Array<object> | string}
	 * @example themes.register("light", "http://example.com/light.css")
	 * @example themes.register("light", { "body": { "color": "purple"}})
	 * @example themes.register({ "light" : {...}, "dark" : {...}})
	 */
	register () {
		if (arguments.length === 0) {
			return;
		}
		if (arguments.length === 1 && typeof(arguments[0]) === "object") {
			return this.registerThemes(arguments[0]);
		}
		if (arguments.length === 1 && typeof(arguments[0]) === "string") {
			return this.default(arguments[0]);
		}
		if (arguments.length === 2 && typeof(arguments[1]) === "string") {
			return this.registerUrl(arguments[0], arguments[1]);
		}
		if (arguments.length === 2 && typeof(arguments[1]) === "object") {
			return this.registerRules(arguments[0], arguments[1]);
		}
	}

	/**
	 * Add a default theme to be used by a rendition
	 * @param {object | string} theme
	 * @example themes.register("http://example.com/default.css")
	 * @example themes.register({ "body": { "color": "purple"}})
	 */
	default (theme) {
		if (!theme) {
			return;
		}
		if (typeof(theme) === "string") {
			return this.registerUrl("default", theme);
		}
		if (typeof(theme) === "object") {
			return this.registerRules("default", theme);
		}
	}

	/**
	 * Register themes object
	 * @param {object} themes
	 */
	registerThemes (themes) {
		for (var theme in themes) {
			if (themes.hasOwnProperty(theme)) {
				if (typeof(themes[theme]) === "string") {
					this.registerUrl(theme, themes[theme]);
				} else {
					this.registerRules(theme, themes[theme]);
				}
			}
		}
	}

	/**
	 * Register a url
	 * @param {string} name
	 * @param {string} input
	 */
	registerUrl (name, input) {
		var url = new utils_url(input);
		this._themes[name] = { "url": url.toString() };
		if (this._injected[name]) {
			this.update(name);
		}
	}

	/**
	 * Register rule
	 * @param {string} name
	 * @param {object} rules
	 */
	registerRules (name, rules) {
		this._themes[name] = { "rules": rules };
		// TODO: serialize css rules
		if (this._injected[name]) {
			this.update(name);
		}
	}

	/**
	 * Select a theme
	 * @param {string} name
	 */
	select (name) {
		var prev = this._current;
		var contents;

		this._current = name;
		this.update(name);

		contents = this.rendition.getContents();
		contents.forEach( (content) => {
			content.removeClass(prev);
			content.addClass(name);
		});
	}

	/**
	 * Update a theme
	 * @param {string} name
	 */
	update (name) {
		var contents = this.rendition.getContents();
		contents.forEach( (content) => {
			this.add(name, content);
		});
	}

	/**
	 * Inject all themes into contents
	 * @param {Contents} contents
	 */
	inject (contents) {
		var links = [];
		var themes = this._themes;
		var theme;

		for (var name in themes) {
			if (themes.hasOwnProperty(name) && (name === this._current || name === "default")) {
				theme = themes[name];
				if((theme.rules && Object.keys(theme.rules).length > 0) || (theme.url && links.indexOf(theme.url) === -1)) {
					this.add(name, contents);
				}
				this._injected.push(name);
			}
		}

		if(this._current != "default") {
			contents.addClass(this._current);
		}
	}

	/**
	 * Add Theme to contents
	 * @param {string} name
	 * @param {Contents} contents
	 */
	add (name, contents) {
		var theme = this._themes[name];

		if (!theme || !contents) {
			return;
		}

		if (theme.url) {
			contents.addStylesheet(theme.url);
		} else if (theme.serialized) {
			// TODO: handle serialized
		} else if (theme.rules) {
			contents.addStylesheetRules(theme.rules);
			theme.injected = true;
		}
	}

	/**
	 * Add override
	 * @param {string} name
	 * @param {string} value
	 * @param {boolean} priority
	 */
	override (name, value, priority) {
		var contents = this.rendition.getContents();

		this._overrides[name] = {
			value: value,
			priority: priority === true
		};

		contents.forEach( (content) => {
			content.css(name, this._overrides[name].value, this._overrides[name].priority);
		});
	}

	/**
	 * Add all overrides
	 * @param {Content} content
	 */
	overrides (contents) {
		var overrides = this._overrides;

		for (var rule in overrides) {
			if (overrides.hasOwnProperty(rule)) {
				contents.css(rule, overrides[rule].value, overrides[rule].priority);
			}
		}
	}

	/**
	 * Adjust the font size of a rendition
	 * @param {number} size
	 */
	fontSize (size) {
		this.override("font-size", size);
	}

	/**
	 * Adjust the font-family of a rendition
	 * @param {string} f
	 */
	font (f) {
		this.override("font-family", f, true);
	}

	destroy() {
		this.rendition = undefined;
		this._themes = undefined;
		this._overrides = undefined;
		this._current = undefined;
		this._injected = undefined;
	}

}

/* harmony default export */ const themes = (Themes);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/mapping.js



/**
 * Map text locations to CFI ranges
 * @class
 * @param {Layout} layout Layout to apply
 * @param {string} [direction="ltr"] Text direction
 * @param {string} [axis="horizontal"] vertical or horizontal axis
 * @param {boolean} [dev] toggle developer highlighting
 */
class Mapping {
	constructor(layout, direction, axis, dev) {
		this.layout = layout;
		this.horizontal = (axis === "horizontal") ? true : false;
		this.direction = direction || "ltr";
		this._dev = dev;
	}

	/**
	 * Find CFI pairs for entire section at once
	 */
	section(view) {
		var ranges = this.findRanges(view);
		var map = this.rangeListToCfiList(view.section.cfiBase, ranges);

		return map;
	}

	/**
	 * Find CFI pairs for a page
	 * @param {Contents} contents Contents from view
	 * @param {string} cfiBase string of the base for a cfi
	 * @param {number} start position to start at
	 * @param {number} end position to end at
	 */
	page(contents, cfiBase, start, end) {
		var root = contents && contents.document ? contents.document.body : false;
		var result;

		if (!root) {
			return;
		}

		result = this.rangePairToCfiPair(cfiBase, {
			start: this.findStart(root, start, end),
			end: this.findEnd(root, start, end)
		});

		if (this._dev === true) {
			let doc = contents.document;
			let startRange = new epubcfi(result.start).toRange(doc);
			let endRange = new epubcfi(result.end).toRange(doc);

			let selection = doc.defaultView.getSelection();
			let r = doc.createRange();
			selection.removeAllRanges();
			r.setStart(startRange.startContainer, startRange.startOffset);
			r.setEnd(endRange.endContainer, endRange.endOffset);
			selection.addRange(r);
		}

		return result;
	}

	/**
	 * Walk a node, preforming a function on each node it finds
	 * @private
	 * @param {Node} root Node to walkToNode
	 * @param {function} func walk function
	 * @return {*} returns the result of the walk function
	 */
	walk(root, func) {
		// IE11 has strange issue, if root is text node IE throws exception on
		// calling treeWalker.nextNode(), saying
		// Unexpected call to method or property access instead of returing null value
		if(root && root.nodeType === Node.TEXT_NODE) {
			return;
		}
		// safeFilter is required so that it can work in IE as filter is a function for IE
		// and for other browser filter is an object.
		var filter = {
			acceptNode: function(node) {
				if (node.data.trim().length > 0) {
					return NodeFilter.FILTER_ACCEPT;
				} else {
					return NodeFilter.FILTER_REJECT;
				}
			}
		};
		var safeFilter = filter.acceptNode;
		safeFilter.acceptNode = filter.acceptNode;

		var treeWalker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, safeFilter, false);
		var node;
		var result;
		while ((node = treeWalker.nextNode())) {
			result = func(node);
			if(result) break;
		}

		return result;
	}

	findRanges(view){
		var columns = [];
		var scrollWidth = view.contents.scrollWidth();
		var spreads = Math.ceil( scrollWidth / this.layout.spreadWidth);
		var count = spreads * this.layout.divisor;
		var columnWidth = this.layout.columnWidth;
		var gap = this.layout.gap;
		var start, end;

		for (var i = 0; i < count.pages; i++) {
			start = (columnWidth + gap) * i;
			end = (columnWidth * (i+1)) + (gap * i);
			columns.push({
				start: this.findStart(view.document.body, start, end),
				end: this.findEnd(view.document.body, start, end)
			});
		}

		return columns;
	}

	/**
	 * Find Start Range
	 * @private
	 * @param {Node} root root node
	 * @param {number} start position to start at
	 * @param {number} end position to end at
	 * @return {Range}
	 */
	findStart(root, start, end){
		var stack = [root];
		var $el;
		var found;
		var $prev = root;

		while (stack.length) {

			$el = stack.shift();

			found = this.walk($el, (node) => {
				var left, right, top, bottom;
				var elPos;
				var elRange;


				elPos = (0,core.nodeBounds)(node);

				if (this.horizontal && this.direction === "ltr") {

					left = this.horizontal ? elPos.left : elPos.top;
					right = this.horizontal ? elPos.right : elPos.bottom;

					if( left >= start && left <= end ) {
						return node;
					} else if (right > start) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				} else if (this.horizontal && this.direction === "rtl") {

					left = elPos.left;
					right = elPos.right;

					if( right <= end && right >= start ) {
						return node;
					} else if (left < end) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				} else {

					top = elPos.top;
					bottom = elPos.bottom;

					if( top >= start && top <= end ) {
						return node;
					} else if (bottom > start) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				}


			});

			if(found) {
				return this.findTextStartRange(found, start, end);
			}

		}

		// Return last element
		return this.findTextStartRange($prev, start, end);
	}

	/**
	 * Find End Range
	 * @private
	 * @param {Node} root root node
	 * @param {number} start position to start at
	 * @param {number} end position to end at
	 * @return {Range}
	 */
	findEnd(root, start, end){
		var stack = [root];
		var $el;
		var $prev = root;
		var found;

		while (stack.length) {

			$el = stack.shift();

			found = this.walk($el, (node) => {

				var left, right, top, bottom;
				var elPos;
				var elRange;

				elPos = (0,core.nodeBounds)(node);

				if (this.horizontal && this.direction === "ltr") {

					left = Math.round(elPos.left);
					right = Math.round(elPos.right);

					if(left > end && $prev) {
						return $prev;
					} else if(right > end) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				} else if (this.horizontal && this.direction === "rtl") {

					left = Math.round(this.horizontal ? elPos.left : elPos.top);
					right = Math.round(this.horizontal ? elPos.right : elPos.bottom);

					if(right < start && $prev) {
						return $prev;
					} else if(left < start) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				} else {

					top = Math.round(elPos.top);
					bottom = Math.round(elPos.bottom);

					if(top > end && $prev) {
						return $prev;
					} else if(bottom > end) {
						return node;
					} else {
						$prev = node;
						stack.push(node);
					}

				}

			});


			if(found){
				return this.findTextEndRange(found, start, end);
			}

		}

		// end of chapter
		return this.findTextEndRange($prev, start, end);
	}

	/**
	 * Find Text Start Range
	 * @private
	 * @param {Node} root root node
	 * @param {number} start position to start at
	 * @param {number} end position to end at
	 * @return {Range}
	 */
	findTextStartRange(node, start, end){
		var ranges = this.splitTextNodeIntoRanges(node);
		var range;
		var pos;
		var left, top, right;

		for (var i = 0; i < ranges.length; i++) {
			range = ranges[i];

			pos = range.getBoundingClientRect();

			if (this.horizontal && this.direction === "ltr") {

				left = pos.left;
				if( left >= start ) {
					return range;
				}

			} else if (this.horizontal && this.direction === "rtl") {

				right = pos.right;
				if( right <= end ) {
					return range;
				}

			} else {

				top = pos.top;
				if( top >= start ) {
					return range;
				}

			}

			// prev = range;

		}

		return ranges[0];
	}

	/**
	 * Find Text End Range
	 * @private
	 * @param {Node} root root node
	 * @param {number} start position to start at
	 * @param {number} end position to end at
	 * @return {Range}
	 */
	findTextEndRange(node, start, end){
		var ranges = this.splitTextNodeIntoRanges(node);
		var prev;
		var range;
		var pos;
		var left, right, top, bottom;

		for (var i = 0; i < ranges.length; i++) {
			range = ranges[i];

			pos = range.getBoundingClientRect();

			if (this.horizontal && this.direction === "ltr") {

				left = pos.left;
				right = pos.right;

				if(left > end && prev) {
					return prev;
				} else if(right > end) {
					return range;
				}

			} else if (this.horizontal && this.direction === "rtl") {

				left = pos.left
				right = pos.right;

				if(right < start && prev) {
					return prev;
				} else if(left < start) {
					return range;
				}

			} else {

				top = pos.top;
				bottom = pos.bottom;

				if(top > end && prev) {
					return prev;
				} else if(bottom > end) {
					return range;
				}

			}


			prev = range;

		}

		// Ends before limit
		return ranges[ranges.length-1];

	}

	/**
	 * Split up a text node into ranges for each word
	 * @private
	 * @param {Node} root root node
	 * @param {string} [_splitter] what to split on
	 * @return {Range[]}
	 */
	splitTextNodeIntoRanges(node, _splitter){
		var ranges = [];
		var textContent = node.textContent || "";
		var text = textContent.trim();
		var range;
		var doc = node.ownerDocument;
		var splitter = _splitter || " ";

		var pos = text.indexOf(splitter);

		if(pos === -1 || node.nodeType != Node.TEXT_NODE) {
			range = doc.createRange();
			range.selectNodeContents(node);
			return [range];
		}

		range = doc.createRange();
		range.setStart(node, 0);
		range.setEnd(node, pos);
		ranges.push(range);
		range = false;

		while ( pos != -1 ) {

			pos = text.indexOf(splitter, pos + 1);
			if(pos > 0) {

				if(range) {
					range.setEnd(node, pos);
					ranges.push(range);
				}

				range = doc.createRange();
				range.setStart(node, pos+1);
			}
		}

		if(range) {
			range.setEnd(node, text.length);
			ranges.push(range);
		}

		return ranges;
	}


	/**
	 * Turn a pair of ranges into a pair of CFIs
	 * @private
	 * @param {string} cfiBase base string for an EpubCFI
	 * @param {object} rangePair { start: Range, end: Range }
	 * @return {object} { start: "epubcfi(...)", end: "epubcfi(...)" }
	 */
	rangePairToCfiPair(cfiBase, rangePair){

		var startRange = rangePair.start;
		var endRange = rangePair.end;

		startRange.collapse(true);
		endRange.collapse(false);

		let startCfi = new epubcfi(startRange, cfiBase).toString();
		let endCfi = new epubcfi(endRange, cfiBase).toString();

		return {
			start: startCfi,
			end: endCfi
		};

	}

	rangeListToCfiList(cfiBase, columns){
		var map = [];
		var cifPair;

		for (var i = 0; i < columns.length; i++) {
			cifPair = this.rangePairToCfiPair(cfiBase, columns[i]);

			map.push(cifPair);

		}

		return map;
	}

	/**
	 * Set the axis for mapping
	 * @param {string} axis horizontal | vertical
	 * @return {boolean} is it horizontal?
	 */
	axis(axis) {
		if (axis) {
			this.horizontal = (axis === "horizontal") ? true : false;
		}
		return this.horizontal;
	}
}

/* harmony default export */ const src_mapping = (Mapping);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/contents.js







const hasNavigator = typeof (navigator) !== "undefined";

const isChrome = hasNavigator && /Chrome/.test(navigator.userAgent);
const isWebkit = hasNavigator && !isChrome && /AppleWebKit/.test(navigator.userAgent);

const contents_ELEMENT_NODE = 1;
const contents_TEXT_NODE = 3;

/**
	* Handles DOM manipulation, queries and events for View contents
	* @class
	* @param {document} doc Document
	* @param {element} content Parent Element (typically Body)
	* @param {string} cfiBase Section component of CFIs
	* @param {number} sectionIndex Index in Spine of Conntent's Section
	*/
class Contents {
	constructor(doc, content, cfiBase, sectionIndex) {
		// Blank Cfi for Parsing
		this.epubcfi = new epubcfi();

		this.document = doc;
		this.documentElement =  this.document.documentElement;
		this.content = content || this.document.body;
		this.window = this.document.defaultView;

		this._size = {
			width: 0,
			height: 0
		};

		this.sectionIndex = sectionIndex || 0;
		this.cfiBase = cfiBase || "";

		this.epubReadingSystem("epub.js", EPUBJS_VERSION);

		this.setViewport();
		this.listeners();
	}

	/**
		* Get DOM events that are listened for and passed along
		*/
	static get listenedEvents() {
		return DOM_EVENTS;
	}

	/**
		* Get or Set width
		* @param {number} [w]
		* @returns {number} width
		*/
	width(w) {
		// var frame = this.documentElement;
		var frame = this.content;

		if (w && (0,core.isNumber)(w)) {
			w = w + "px";
		}

		if (w) {
			frame.style.width = w;
			// this.content.style.width = w;
		}

		return this.window.getComputedStyle(frame)["width"];


	}

	/**
		* Get or Set height
		* @param {number} [h]
		* @returns {number} height
		*/
	height(h) {
		// var frame = this.documentElement;
		var frame = this.content;

		if (h && (0,core.isNumber)(h)) {
			h = h + "px";
		}

		if (h) {
			frame.style.height = h;
			// this.content.style.height = h;
		}

		return this.window.getComputedStyle(frame)["height"];

	}

	/**
		* Get or Set width of the contents
		* @param {number} [w]
		* @returns {number} width
		*/
	contentWidth(w) {

		var content = this.content || this.document.body;

		if (w && (0,core.isNumber)(w)) {
			w = w + "px";
		}

		if (w) {
			content.style.width = w;
		}

		return this.window.getComputedStyle(content)["width"];


	}

	/**
		* Get or Set height of the contents
		* @param {number} [h]
		* @returns {number} height
		*/
	contentHeight(h) {

		var content = this.content || this.document.body;

		if (h && (0,core.isNumber)(h)) {
			h = h + "px";
		}

		if (h) {
			content.style.height = h;
		}

		return this.window.getComputedStyle(content)["height"];

	}

	/**
		* Get the width of the text using Range
		* @returns {number} width
		*/
	textWidth() {
		var viewport = this.$viewport;
		if ( false ) {}

		let rect;
		let width;
		let range = this.document.createRange();
		let content = this.content || this.document.body;
		let border = (0,core.borders)(content);

		// Select the contents of frame
		range.selectNodeContents(content);

		// get the width of the text content
		rect = range.getBoundingClientRect();
		width = rect.width;

		if (border && border.width) {
			width += border.width;
		}

		return Math.round(width);
	}

	/**
		* Get the height of the text using Range
		* @returns {number} height
		*/
	textHeight() {
		var viewport = this.$viewport;
		if ( false ) {}

		let rect;
		let height;
		let range = this.document.createRange();
		let content = this.content || this.document.body;
		let border = (0,core.borders)(content);

		range.selectNodeContents(content);

		rect = range.getBoundingClientRect();
		height = rect.height;

		if (height && border.height) {
			height += border.height;
		}

		if (height && rect.top) {
			height += rect.top;
		}

		return Math.round(height);
	}

	/**
		* Get documentElement scrollWidth
		* @returns {number} width
		*/
	scrollWidth() {
		var width = this.documentElement.scrollWidth;

		return width;
	}

	/**
		* Get documentElement scrollHeight
		* @returns {number} height
		*/
	scrollHeight() {
		var height = this.documentElement.scrollHeight;

		return height;
	}

	/**
		* Set overflow css style of the contents
		* @param {string} [overflow]
		*/
	overflow(overflow) {

		if (overflow) {
			this.documentElement.style.overflow = overflow;
		}

		return this.window.getComputedStyle(this.documentElement)["overflow"];
	}

	/**
		* Set overflowX css style of the documentElement
		* @param {string} [overflow]
		*/
	overflowX(overflow) {

		if (overflow) {
			this.documentElement.style.overflowX = overflow;
		}

		return this.window.getComputedStyle(this.documentElement)["overflowX"];
	}

	/**
		* Set overflowY css style of the documentElement
		* @param {string} [overflow]
		*/
	overflowY(overflow) {

		if (overflow) {
			this.documentElement.style.overflowY = overflow;
		}

		return this.window.getComputedStyle(this.documentElement)["overflowY"];
	}

	/**
		* Set Css styles on the contents element (typically Body)
		* @param {string} property
		* @param {string} value
		* @param {boolean} [priority] set as "important"
		*/
	css(property, value, priority) {
		var content = this.content || this.document.body;

		if (value) {
			content.style.setProperty(property, value, priority ? "important" : "");
		}

		return this.window.getComputedStyle(content)[property];
	}

	/**
		* Get or Set the viewport element
		* @param {object} [options]
		* @param {string} [options.width]
		* @param {string} [options.height]
		* @param {string} [options.scale]
		* @param {string} [options.minimum]
		* @param {string} [options.maximum]
		* @param {string} [options.scalable]
		*/
	viewport(options) {
		var _width, _height, _scale, _minimum, _maximum, _scalable;
		// var width, height, scale, minimum, maximum, scalable;
		var $viewport = this.document.querySelector("meta[name='viewport']");
		var parsed = {
			"width": undefined,
			"height": undefined,
			"scale": undefined,
			"minimum": undefined,
			"maximum": undefined,
			"scalable": undefined
		};
		var newContent = [];
		var settings = {};

		/*
		* check for the viewport size
		* <meta name="viewport" content="width=1024,height=697" />
		*/
		if($viewport && $viewport.hasAttribute("content")) {
			let content = $viewport.getAttribute("content");
			let _width = content.match(/width\s*=\s*([^,]*)/);
			let _height = content.match(/height\s*=\s*([^,]*)/);
			let _scale = content.match(/initial-scale\s*=\s*([^,]*)/);
			let _minimum = content.match(/minimum-scale\s*=\s*([^,]*)/);
			let _maximum = content.match(/maximum-scale\s*=\s*([^,]*)/);
			let _scalable = content.match(/user-scalable\s*=\s*([^,]*)/);

			if(_width && _width.length && typeof _width[1] !== "undefined"){
				parsed.width = _width[1];
			}
			if(_height && _height.length && typeof _height[1] !== "undefined"){
				parsed.height = _height[1];
			}
			if(_scale && _scale.length && typeof _scale[1] !== "undefined"){
				parsed.scale = _scale[1];
			}
			if(_minimum && _minimum.length && typeof _minimum[1] !== "undefined"){
				parsed.minimum = _minimum[1];
			}
			if(_maximum && _maximum.length && typeof _maximum[1] !== "undefined"){
				parsed.maximum = _maximum[1];
			}
			if(_scalable && _scalable.length && typeof _scalable[1] !== "undefined"){
				parsed.scalable = _scalable[1];
			}
		}

		settings = (0,core.defaults)(options || {}, parsed);

		if (options) {
			if (settings.width) {
				newContent.push("width=" + settings.width);
			}

			if (settings.height) {
				newContent.push("height=" + settings.height);
			}

			if (settings.scale) {
				newContent.push("initial-scale=" + settings.scale);
			}

			if (settings.scalable === "no") {
				newContent.push("minimum-scale=" + settings.scale);
				newContent.push("maximum-scale=" + settings.scale);
				newContent.push("user-scalable=" + settings.scalable);
			} else {

				if (settings.scalable) {
					newContent.push("user-scalable=" + settings.scalable);
				}

				if (settings.minimum) {
					newContent.push("minimum-scale=" + settings.minimum);
				}

				if (settings.maximum) {
					newContent.push("minimum-scale=" + settings.maximum);
				}
			}

			if (!$viewport) {
				$viewport = this.document.createElement("meta");
				$viewport.setAttribute("name", "viewport");
				this.document.querySelector("head").appendChild($viewport);
			}

			$viewport.setAttribute("content", newContent.join(", "));

			this.window.scrollTo(0, 0);
		}


		return settings;
	}

	setViewport() {
		this.$viewport = { height: 'auto', width: 'auto' };
		var $viewport = this.document.querySelector("meta[name='viewport']");
		var parsed = {
			"width": undefined,
			"height": undefined,
			"scale": undefined,
			"minimum": undefined,
			"maximum": undefined,
			"scalable": undefined
		};
		var newContent = [];
		var settings = {};

		/*
		* check for the viewport size
		* <meta name="viewport" content="width=1024,height=697" />
		*/
		if($viewport && $viewport.hasAttribute("content")) {
			let content = $viewport.getAttribute("content");
			let _width = content.match(/width\s*=\s*([^,]*)/);
			let _height = content.match(/height\s*=\s*([^,]*)/);
			let _scale = content.match(/initial-scale\s*=\s*([^,]*)/);
			let _minimum = content.match(/minimum-scale\s*=\s*([^,]*)/);
			let _maximum = content.match(/maximum-scale\s*=\s*([^,]*)/);
			let _scalable = content.match(/user-scalable\s*=\s*([^,]*)/);

			if(_width && _width.length && typeof _width[1] !== "undefined"){
				parsed.width = _width[1];
			}
			if(_height && _height.length && typeof _height[1] !== "undefined"){
				parsed.height = _height[1];
			}
			if(_scale && _scale.length && typeof _scale[1] !== "undefined"){
				parsed.scale = _scale[1];
			}
			if(_minimum && _minimum.length && typeof _minimum[1] !== "undefined"){
				parsed.minimum = _minimum[1];
			}
			if(_maximum && _maximum.length && typeof _maximum[1] !== "undefined"){
				parsed.maximum = _maximum[1];
			}
			if(_scalable && _scalable.length && typeof _scalable[1] !== "undefined"){
				parsed.scalable = _scalable[1];
			}
		}
		this.$viewport.height = parseFloat(parsed.height) || 'auto';
		this.$viewport.width = parseFloat(parsed.width) || 'auto';
	}

	/**
	 * Event emitter for when the contents has expanded
	 * @private
	 */
	expand() {
		this.emit(EVENTS.CONTENTS.EXPAND);
	}

	/**
	 * Add DOM listeners
	 * @private
	 */
	listeners() {

		this.imageLoadListeners();

		this.mediaQueryListeners();

		// this.fontLoadListeners();

		this.addEventListeners();

		this.addSelectionListeners();

		// this.transitionListeners();

		this.resizeListeners();

		// this.resizeObservers();

		this.linksHandler();
	}

	/**
	 * Remove DOM listeners
	 * @private
	 */
	removeListeners() {

		this.removeEventListeners();

		this.removeSelectionListeners();

		clearTimeout(this.expanding);
	}

	/**
	 * Check if size of contents has changed and
	 * emit 'resize' event if it has.
	 * @private
	 */
	resizeCheck() {
		let width = this.textWidth();
		let height = this.textHeight();

		if (width != this._size.width || height != this._size.height) {

			this._size = {
				width: width,
				height: height
			};

			this.onResize && this.onResize(this._size);
			this.emit(EVENTS.CONTENTS.RESIZE, this._size);
		}
	}

	/**
	 * Poll for resize detection
	 * @private
	 */
	resizeListeners() {
		var width, height;
		// Test size again
		clearTimeout(this.expanding);

		requestAnimationFrame(this.resizeCheck.bind(this));

		this.expanding = setTimeout(this.resizeListeners.bind(this), 350);
	}

	/**
	 * Use css transitions to detect resize
	 * @private
	 */
	transitionListeners() {
		let body = this.content;

		body.style['transitionProperty'] = "font, font-size, font-size-adjust, font-stretch, font-variation-settings, font-weight, width, height";
		body.style['transitionDuration'] = "0.001ms";
		body.style['transitionTimingFunction'] = "linear";
		body.style['transitionDelay'] = "0";

		this._resizeCheck = this.resizeCheck.bind(this);
		this.document.addEventListener('transitionend', this._resizeCheck);
	}

	/**
	 * Listen for media query changes and emit 'expand' event
	 * Adapted from: https://github.com/tylergaw/media-query-events/blob/master/js/mq-events.js
	 * @private
	 */
	mediaQueryListeners() {
		var sheets = this.document.styleSheets;
		var mediaChangeHandler = function(m){
			if(m.matches && !this._expanding) {
				setTimeout(this.expand.bind(this), 1);
			}
		}.bind(this);

		for (var i = 0; i < sheets.length; i += 1) {
			var rules;
			// Firefox errors if we access cssRules cross-domain
			try {
				rules = sheets[i].cssRules;
			} catch (e) {
				return;
			}
			if(!rules) return; // Stylesheets changed
			for (var j = 0; j < rules.length; j += 1) {
				//if (rules[j].constructor === CSSMediaRule) {
				if(rules[j].media){
					var mql = this.window.matchMedia(rules[j].media.mediaText);
					mql.addListener(mediaChangeHandler);
					//mql.onchange = mediaChangeHandler;
				}
			}
		}
	}

	/**
	 * Use MutationObserver to listen for changes in the DOM and check for resize
	 * @private
	 */
	resizeObservers() {
		// create an observer instance
		this.observer = new MutationObserver((mutations) => {
			this.resizeCheck();
		});

		// configuration of the observer:
		let config = { attributes: true, childList: true, characterData: true, subtree: true };

		// pass in the target node, as well as the observer options
		this.observer.observe(this.document, config);
	}

	/**
	 * Test if images are loaded or add listener for when they load
	 * @private
	 */
	imageLoadListeners() {
		var images = this.document.querySelectorAll("img");
		var img;
		for (var i = 0; i < images.length; i++) {
			img = images[i];

			if (typeof img.naturalWidth !== "undefined" &&
					img.naturalWidth === 0) {
				img.onload = this.expand.bind(this);
			}
		}
	}

	/**
	 * Listen for font load and check for resize when loaded
	 * @private
	 */
	fontLoadListeners() {
		if (!this.document || !this.document.fonts) {
			return;
		}

		this.document.fonts.ready.then(function () {
			this.resizeCheck();
		}.bind(this));

	}

	/**
	 * Get the documentElement
	 * @returns {element} documentElement
	 */
	root() {
		if(!this.document) return null;
		return this.document.documentElement;
	}

	/**
	 * Get the location offset of a EpubCFI or an #id
	 * @param {string | EpubCFI} target
	 * @param {string} [ignoreClass] for the cfi
	 * @returns { {left: Number, top: Number }
	 */
	locationOf(target, ignoreClass) {
		var position;
		var targetPos = {"left": 0, "top": 0};

		if(!this.document) return targetPos;

		if(this.epubcfi.isCfiString(target)) {
			let range = new epubcfi(target).toRange(this.document, ignoreClass);

			if(range) {
				if (range.startContainer.nodeType === Node.ELEMENT_NODE) {
					position = range.startContainer.getBoundingClientRect();
					targetPos.left = position.left;
					targetPos.top = position.top;
				} else {
					// Webkit does not handle collapsed range bounds correctly
					// https://bugs.webkit.org/show_bug.cgi?id=138949

					// Construct a new non-collapsed range
					if (isWebkit) {
						let container = range.startContainer;
						let newRange = new Range();
						try {
							if (container.nodeType === contents_ELEMENT_NODE) {
								position = container.getBoundingClientRect();
							} else if (range.startOffset + 2 < container.length) {
								newRange.setStart(container, range.startOffset);
								newRange.setEnd(container, range.startOffset + 2);
								position = newRange.getBoundingClientRect();
							} else if (range.startOffset - 2 > 0) {
								newRange.setStart(container, range.startOffset - 2);
								newRange.setEnd(container, range.startOffset);
								position = newRange.getBoundingClientRect();
							} else { // empty, return the parent element
								position = container.parentNode.getBoundingClientRect();
							}
						} catch (e) {
							console.error(e, e.stack);
						}
					} else {
						position = range.getBoundingClientRect();
					}
				}
			}

		} else if(typeof target === "string" &&
			target.indexOf("#") > -1) {

			let id = target.substring(target.indexOf("#")+1);
			let el = this.document.getElementById(id);

			if(el) {
				position = el.getBoundingClientRect();
				if ( position.top < 0 ) {
					var offsetEl = el.offsetTop ? el : el.offsetParent;
					position = { top: offsetEl.offsetTop, left: offsetEl.offsetLeft };
				}
			}
		}

		if (position) {
			targetPos.left = position.left;
			targetPos.top = position.top;
		}

		return targetPos;
	}

	/**
	 * Append a stylesheet link to the document head
	 * @param {string} src url
	 */
	addStylesheet(src) {
		return new Promise(function(resolve, reject){
			var $stylesheet;
			var ready = false;

			if(!this.document) {
				resolve(false);
				return;
			}

			// Check if link already exists
			$stylesheet = this.document.querySelector("link[href='"+src+"']");
			if ($stylesheet) {
				resolve(true);
				return; // already present
			}

			$stylesheet = this.document.createElement("link");
			$stylesheet.type = "text/css";
			$stylesheet.rel = "stylesheet";
			$stylesheet.href = src;
			$stylesheet.onload = $stylesheet.onreadystatechange = function() {
				if ( !ready && (!this.readyState || this.readyState == "complete") ) {
					ready = true;
					// Let apply
					setTimeout(() => {
						resolve(true);
					}, 1);
				}
			};

			this.document.head.appendChild($stylesheet);

		}.bind(this));
	}

	/**
	 * Append stylesheet rules to a generate stylesheet
	 * Array: https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet/insertRule
	 * Object: https://github.com/desirable-objects/json-to-css
	 * @param {array | object} rules
	 */
	addStylesheetRules(rules) {
		var styleEl;
		var styleSheet;
		var key = "epubjs-inserted-css";

		if(!this.document || !rules || rules.length === 0) return;

		// Check if link already exists
		styleEl = this.document.getElementById(key);
		if (!styleEl) {
			styleEl = this.document.createElement("style");
			styleEl.id = key;
			// Append style element to head
			this.document.head.appendChild(styleEl);
		}


		// Grab style sheet
		styleSheet = styleEl.sheet;

		if (Object.prototype.toString.call(rules) === "[object Array]") {
			for (var i = 0, rl = rules.length; i < rl; i++) {
				var j = 1, rule = rules[i], selector = rules[i][0], propStr = "";
				// If the second argument of a rule is an array of arrays, correct our variables.
				if (Object.prototype.toString.call(rule[1][0]) === "[object Array]") {
					rule = rule[1];
					j = 0;
				}

				for (var pl = rule.length; j < pl; j++) {
					var prop = rule[j];
					propStr += prop[0] + ":" + prop[1] + (prop[2] ? " !important" : "") + ";\n";
				}

				// Insert CSS Rule
				styleSheet.insertRule(selector + "{" + propStr + "}", styleSheet.cssRules.length);
			}
		} else {
			const selectors = Object.keys(rules);
			selectors.forEach((selector) => {
				const definition = rules[selector];
				if (Array.isArray(definition)) {
					definition.forEach((item) => {
						const _rules = Object.keys(item);
						const result = _rules.map((rule) => {
							return `${rule}:${item[rule]}`;
						}).join(';');
						styleSheet.insertRule(`${selector}{${result}}`, styleSheet.cssRules.length);
					});
				} else {
					const _rules = Object.keys(definition);
					const result = _rules.map((rule) => {
						return `${rule}:${definition[rule]}`;
					}).join(';');
					styleSheet.insertRule(`${selector}{${result}}`, styleSheet.cssRules.length);
				}
			});
		}
	}

	/**
	 * Append a script tag to the document head
	 * @param {string} src url
	 * @returns {Promise} loaded
	 */
	addScript(src) {

		return new Promise(function(resolve, reject){
			var $script;
			var ready = false;

			if(!this.document) {
				resolve(false);
				return;
			}

			$script = this.document.createElement("script");
			$script.type = "text/javascript";
			$script.async = true;
			$script.src = src;
			$script.onload = $script.onreadystatechange = function() {
				if ( !ready && (!this.readyState || this.readyState == "complete") ) {
					ready = true;
					setTimeout(function(){
						resolve(true);
					}, 1);
				}
			};

			this.document.head.appendChild($script);

		}.bind(this));
	}

	/**
	 * Add a class to the contents container
	 * @param {string} className
	 */
	addClass(className) {
		var content;

		if(!this.document) return;

		content = this.content || this.document.body;

		if (content) {
			content.classList.add(className);
		}

	}

	/**
	 * Remove a class from the contents container
	 * @param {string} removeClass
	 */
	removeClass(className) {
		var content;

		if(!this.document) return;

		content = this.content || this.document.body;

		if (content) {
			content.classList.remove(className);
		}

	}

	/**
	 * Add DOM event listeners
	 * @private
	 */
	addEventListeners(){
		if(!this.document) {
			return;
		}

		this._triggerEvent = this.triggerEvent.bind(this);

		DOM_EVENTS.forEach(function(eventName){
			this.document.addEventListener(eventName, this._triggerEvent, { passive: true });
		}, this);

	}

	/**
	 * Remove DOM event listeners
	 * @private
	 */
	removeEventListeners(){
		if(!this.document) {
			return;
		}
		DOM_EVENTS.forEach(function(eventName){
			this.document.removeEventListener(eventName, this._triggerEvent, { passive: true });
		}, this);
		this._triggerEvent = undefined;
	}

	/**
	 * Emit passed browser events
	 * @private
	 */
	triggerEvent(e){
		this.emit(e.type, e);
	}

	/**
	 * Add listener for text selection
	 * @private
	 */
	addSelectionListeners(){
		if(!this.document) {
			return;
		}
		this._onSelectionChange = this.onSelectionChange.bind(this);
		this.document.addEventListener("selectionchange", this._onSelectionChange, { passive: true });
	}

	/**
	 * Remove listener for text selection
	 * @private
	 */
	removeSelectionListeners(){
		if(!this.document) {
			return;
		}
		this.document.removeEventListener("selectionchange", this._onSelectionChange, { passive: true });
		this._onSelectionChange = undefined;
	}

	/**
	 * Handle getting text on selection
	 * @private
	 */
	onSelectionChange(e){
		if (this.selectionEndTimeout) {
			clearTimeout(this.selectionEndTimeout);
		}
		this.selectionEndTimeout = setTimeout(function() {
			var selection = this.window.getSelection();
			this.triggerSelectedEvent(selection);
		}.bind(this), 250);
	}

	/**
	 * Emit event on text selection
	 * @private
	 */
	triggerSelectedEvent(selection){
		var range, cfirange;

		if (selection && selection.rangeCount > 0) {
			range = selection.getRangeAt(0);
			if(!range.collapsed) {
				// cfirange = this.section.cfiFromRange(range);
				cfirange = new epubcfi(range, this.cfiBase).toString();
				this.emit(EVENTS.CONTENTS.SELECTED, cfirange);
				this.emit(EVENTS.CONTENTS.SELECTED_RANGE, range);
			}
		}
	}

	/**
	 * Get a Dom Range from EpubCFI
	 * @param {EpubCFI} _cfi
	 * @param {string} [ignoreClass]
	 * @returns {Range} range
	 */
	range(_cfi, ignoreClass){
		var cfi = new epubcfi(_cfi);
		return cfi.toRange(this.document, ignoreClass);
	}

	/**
	 * Get an EpubCFI from a Dom Range
	 * @param {Range} range
	 * @param {string} [ignoreClass]
	 * @returns {EpubCFI} cfi
	 */
	cfiFromRange(range, ignoreClass){
		return new epubcfi(range, this.cfiBase, ignoreClass).toString();
	}

	/**
	 * Get an EpubCFI from a Dom node
	 * @param {node} node
	 * @param {string} [ignoreClass]
	 * @returns {EpubCFI} cfi
	 */
	cfiFromNode(node, ignoreClass){
		return new epubcfi(node, this.cfiBase, ignoreClass).toString();
	}

	// TODO: find where this is used - remove?
	map(layout){
		var map = new src_mapping(layout);
		return map.section();
	}

	/**
	 * Size the contents to a given width and height
	 * @param {number} [width]
	 * @param {number} [height]
	 */
	size(width, height){
		var viewport = { scale: 1.0, scalable: "no" };

		this.layoutStyle("scrolling");

		if (width >= 0) {
			this.width(width);
			viewport.width = width;
			this.css("padding", "0 "+(width/12)+"px");
		}

		if (height >= 0) {
			this.height(height);
			viewport.height = height;
		}

		this.css("margin", "0");
		this.css("box-sizing", "border-box");


		this.viewport(viewport);
	}

	/**
	 * Apply columns to the contents for pagination
	 * @param {number} width
	 * @param {number} height
	 * @param {number} columnWidth
	 * @param {number} gap
	 */
	columns(width, height, columnWidth, gap){
		let COLUMN_AXIS = (0,core.prefixed)("column-axis");
		let COLUMN_GAP = (0,core.prefixed)("column-gap");
		let COLUMN_WIDTH = (0,core.prefixed)("column-width");
		let COLUMN_FILL = (0,core.prefixed)("column-fill");

		let writingMode = this.writingMode();
		let axis = (writingMode.indexOf("vertical") === 0) ? "vertical" : "horizontal";

		this.layoutStyle("paginated");

		// Fix body width issues if rtl is only set on body element
		if (this.content.dir === "rtl") {
			this.direction("rtl");
		}

		this.width(width);
		this.height(height);

		// Deal with Mobile trying to scale to viewport
		this.viewport({ width: width, height: height, scale: 1.0, scalable: "no" });

		// TODO: inline-block needs more testing
		// Fixes Safari column cut offs, but causes RTL issues
		// this.css("display", "inline-block");

		this.css("overflow-y", "hidden");
		this.css("margin", "0", true);

		if (axis === "vertical") {
			this.css("padding-top", (gap / 2) + "px", true);
			this.css("padding-bottom", (gap / 2) + "px", true);
			this.css("padding-left", "20px");
			this.css("padding-right", "20px");
		} else {
			this.css("padding-top", "20px");
			this.css("padding-bottom", "20px");
			this.css("padding-left", (gap / 2) + "px", true);
			this.css("padding-right", (gap / 2) + "px", true);
		}

		this.css("box-sizing", "border-box");
		this.css("max-width", "inherit");

		this.css(COLUMN_AXIS, "horizontal");
		this.css(COLUMN_FILL, "auto");

		this.css(COLUMN_GAP, gap+"px");
		this.css(COLUMN_WIDTH, columnWidth+"px");
	}

	/**
	 * Scale contents from center
	 * @param {number} scale
	 * @param {number} offsetX
	 * @param {number} offsetY
	 */
	scaler(scale, offsetX, offsetY){
		var scaleStr = "scale(" + scale + ")";
		var translateStr = "";
		// this.css("position", "absolute"));
		this.css("transform-origin", "top left");

		if (offsetX >= 0 || offsetY >= 0) {
			translateStr = " translate(" + (offsetX || 0 )+ "px, " + (offsetY || 0 )+ "px)";
		// } else if ( offsetX || offsetY ) {
		// 	translateStr = " translate(" + offsetX + "," + offsetY + ")";
		}

		this.css("transform", scaleStr + translateStr);
	}

	/**
	 * Fit contents into a fixed width and height
	 * @param {number} width
	 * @param {number} height
	 */
	fit(width, height){
		var viewport = this.viewport();
		var viewportWidth;
		var viewportHeight;

		// var viewportWidth = parseInt(viewport.width);
		// var viewportHeight = parseInt(viewport.height);

		if ( viewport.width == 'auto' && viewport.height == 'auto' ) {
			viewportWidth = width;
			viewportHeight = height; // this.textHeight(); // height;
			console.log("AHOY contents.fit", height, this.textHeight());
		} else {
			viewportWidth = parseInt(viewport.width);
			viewportHeight = parseInt(viewport.height);
		}

		var widthScale = width / viewportWidth;
		var heightScale = height / viewportHeight;
		var scale;
		if ( this.axis == 'xxxvertical' ) {
			scale = widthScale > heightScale ? widthScale : heightScale;
		} else {
			scale = widthScale < heightScale ? widthScale : heightScale;
		}
		// console.log("AHOY contents.fit", width, height, ":", viewportWidth, viewportHeight, ":", scale);

		// the translate does not work as intended, elements can end up unaligned
		// var offsetY = (height - (viewportHeight * scale)) / 2;
		// var offsetX = 0;
		// if (this.sectionIndex % 2 === 1) {
		// 	offsetX = width - (viewportWidth * scale);
		// }

		this.layoutStyle("paginated");

		// scale needs width and height to be set
		this.width(viewportWidth);
		this.height(viewportHeight);
		this.overflow("hidden");

		if ( viewport.width == 'auto' || viewport.height == 'auto' ) {
			this.content.style.overflow = 'auto';
			this.addStylesheetRules({
				"body": {
					"margin": 0,
					"padding": "1em",
					"box-sizing": "border-box"
				}
			})
		}

		// Scale to the correct size
		this.scaler(scale, 0, 0);
		// this.scaler(scale, offsetX > 0 ? offsetX : 0, offsetY);

		// background images are not scaled by transform
		this.css("background-size", viewportWidth * scale + "px " + viewportHeight * scale + "px");

		this.css("background-color", "transparent");
	}

	/**
	 * Set the direction of the text
	 * @param {string} [dir="ltr"] "rtl" | "ltr"
	 */
	direction(dir) {
		if (this.documentElement) {
			this.documentElement.style["direction"] = dir;
		}
	}

	mapPage(cfiBase, layout, start, end, dev) {
		var mapping = new src_mapping(layout, dev);

		return mapping.page(this, cfiBase, start, end);
	}

	/**
	 * Emit event when link in content is clicked
	 * @private
	 */
	linksHandler() {
		replaceLinks(this.content, (href) => {
			this.emit(EVENTS.CONTENTS.LINK_CLICKED, href);
		});
	}

	/**
	 * Set the writingMode of the text
	 * @param {string} [mode="horizontal-tb"] "horizontal-tb" | "vertical-rl" | "vertical-lr"
	 */
	writingMode(mode) {
		let WRITING_MODE = (0,core.prefixed)("writing-mode");

		if (mode && this.documentElement) {
			this.documentElement.style[WRITING_MODE] = mode;
		}

		return this.window.getComputedStyle(this.documentElement)[WRITING_MODE] || '';
	}

	/**
	 * Set the layoutStyle of the content
	 * @param {string} [style="paginated"] "scrolling" | "paginated"
	 * @private
	 */
	layoutStyle(style) {

		if (style) {
			this._layoutStyle = style;
			navigator.epubReadingSystem.layoutStyle = this._layoutStyle;
		}

		return this._layoutStyle || "paginated";
	}

	/**
	 * Add the epubReadingSystem object to the navigator
	 * @param {string} name
	 * @param {string} version
	 * @private
	 */
	epubReadingSystem(name, version) {
		navigator.epubReadingSystem = {
			name: name,
			version: version,
			layoutStyle: this.layoutStyle(),
			hasFeature: function (feature) {
				switch (feature) {
					case "dom-manipulation":
						return true;
					case "layout-changes":
						return true;
					case "touch-events":
						return true;
					case "mouse-events":
						return true;
					case "keyboard-events":
						return true;
					case "spine-scripting":
						return false;
					default:
						return false;
				}
			}
		};
		return navigator.epubReadingSystem;
	}

	destroy() {
		// Stop observing
		if(this.observer) {
			this.observer.disconnect();
		}

		this.document.removeEventListener('transitionend', this._resizeCheck);

		this.removeListeners();

	}
}

event_emitter_default()(Contents.prototype);

/* harmony default export */ const contents = (Contents);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/annotations.js



/**
	* Handles managing adding & removing Annotations
	* @param {Rendition} rendition
	* @class
	*/
class Annotations {

	constructor (rendition) {
		this.rendition = rendition;
		this.highlights = [];
		this.underlines = [];
		this.marks = [];
		this._annotations = {};
		this._annotationsBySectionIndex = {};

		this.rendition.hooks.render.register(this.inject.bind(this));
		this.rendition.hooks.unloaded.register(this.clear.bind(this));
	}

	/**
	 * Add an annotation to store
	 * @param {string} type Type of annotation to add: "highlight", "underline", "mark"
	 * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	 * @param {object} data Data to assign to annotation
	 * @param {function} [cb] Callback after annotation is added
	 * @param {string} className CSS class to assign to annotation
	 * @param {object} styles CSS styles to assign to annotation
	 * @returns {Annotation} annotation
	 */
	add (type, cfiRange, data, cb, className, styles) {
		let hash = encodeURI(cfiRange);
		let cfi = new epubcfi(cfiRange);
		let sectionIndex = cfi.spinePos;
		let annotation = new Annotation({
			type,
			cfiRange,
			data,
			sectionIndex,
			cb,
			className,
			styles
		});

		this._annotations[hash] = annotation;

		if (sectionIndex in this._annotationsBySectionIndex) {
			this._annotationsBySectionIndex[sectionIndex].push(hash);
		} else {
			this._annotationsBySectionIndex[sectionIndex] = [hash];
		}

		let views = this.rendition.views();

		views.forEach( (view) => {
			if (annotation.sectionIndex === view.index) {
				annotation.attach(view);
			}
		});

		return annotation;
	}

	/**
	 * Remove an annotation from store
	 * @param {EpubCFI} cfiRange EpubCFI range the annotation is attached to
	 * @param {string} type Type of annotation to add: "highlight", "underline", "mark"
	 */
	remove (cfiRange, type) {
		let hash = encodeURI(cfiRange);

		if (hash in this._annotations) {
			let annotation = this._annotations[hash];

			if (type && annotation.type !== type) {
				return;
			}

			let views = this.rendition.views();
			views.forEach( (view) => {
				this._removeFromAnnotationBySectionIndex(annotation.sectionIndex, hash);
				if (annotation.sectionIndex === view.index) {
					annotation.detach(view);
				}
			});

			delete this._annotations[hash];
		}
	}

	/**
	 * Remove an annotations by Section Index
	 * @private
	 */
	_removeFromAnnotationBySectionIndex (sectionIndex, hash) {
		this._annotationsBySectionIndex[sectionIndex] = this._annotationsAt(sectionIndex).filter(h => h !== hash);
	}

	/**
	 * Get annotations by Section Index
	 * @private
	 */
	_annotationsAt (index) {
		return this._annotationsBySectionIndex[index];
	}


	/**
	 * Add a highlight to the store
	 * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	 * @param {object} data Data to assign to annotation
	 * @param {function} cb Callback after annotation is added
	 * @param {string} className CSS class to assign to annotation
	 * @param {object} styles CSS styles to assign to annotation
	 */
	highlight (cfiRange, data, cb, className, styles) {
		this.add("highlight", cfiRange, data, cb, className, styles);
	}

	/**
	 * Add a underline to the store
	 * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	 * @param {object} data Data to assign to annotation
	 * @param {function} cb Callback after annotation is added
	 * @param {string} className CSS class to assign to annotation
	 * @param {object} styles CSS styles to assign to annotation
	 */
	underline (cfiRange, data, cb, className, styles) {
		this.add("underline", cfiRange, data, cb, className, styles);
	}

	/**
	 * Add a mark to the store
	 * @param {EpubCFI} cfiRange EpubCFI range to attach annotation to
	 * @param {object} data Data to assign to annotation
	 * @param {function} cb Callback after annotation is added
	 */
	mark (cfiRange, data, cb) {
		this.add("mark", cfiRange, data, cb);
	}

	/**
	 * iterate over annotations in the store
	 */
	each () {
		return this._annotations.forEach.apply(this._annotations, arguments);
	}

	/**
	 * Hook for injecting annotation into a view
	 * @param {View} view
	 * @private
	 */
	inject (view) {
		let sectionIndex = view.index;
		if (sectionIndex in this._annotationsBySectionIndex) {
			let annotations = this._annotationsBySectionIndex[sectionIndex];
			annotations.forEach((hash) => {
				let annotation = this._annotations[hash];
				annotation.attach(view);
			});
		}
	}

	/**
	 * Hook for removing annotation from a view
	 * @param {View} view
	 * @private
	 */
	clear (view) {
		let sectionIndex = view.index;
		if (sectionIndex in this._annotationsBySectionIndex) {
			let annotations = this._annotationsBySectionIndex[sectionIndex];
			annotations.forEach((hash) => {
				let annotation = this._annotations[hash];
				annotation.detach(view);
			});
		}
	}

	/**
	 * [Not Implemented] Show annotations
	 * @TODO: needs implementation in View
	 */
	show () {

	}

	/**
	 * [Not Implemented] Hide annotations
	 * @TODO: needs implementation in View
	 */
	hide () {

	}

}

/**
 * Annotation object
 * @class
 * @param {object} options
 * @param {string} options.type Type of annotation to add: "highlight", "underline", "mark"
 * @param {EpubCFI} options.cfiRange EpubCFI range to attach annotation to
 * @param {object} options.data Data to assign to annotation
 * @param {int} options.sectionIndex Index in the Spine of the Section annotation belongs to
 * @param {function} [options.cb] Callback after annotation is added
 * @param {string} className CSS class to assign to annotation
 * @param {object} styles CSS styles to assign to annotation
 * @returns {Annotation} annotation
 */
class Annotation {

	constructor ({
		type,
		cfiRange,
		data,
		sectionIndex,
		cb,
		className,
		styles
	}) {
		this.type = type;
		this.cfiRange = cfiRange;
		this.data = data;
		this.sectionIndex = sectionIndex;
		this.mark = undefined;
		this.cb = cb;
		this.className = className;
		this.styles = styles;
	}

	/**
	 * Update stored data
	 * @param {object} data
	 */
	update (data) {
		this.data = data;
	}

	/**
	 * Add to a view
	 * @param {View} view
	 */
	attach (view) {
		let {cfiRange, data, type, mark, cb, className, styles} = this;
		let result;

		if (type === "highlight") {
			result = view.highlight(cfiRange, data, cb, className, styles);
		} else if (type === "underline") {
			result = view.underline(cfiRange, data, cb, className, styles);
		} else if (type === "mark") {
			result = view.mark(cfiRange, data, cb);
		}

		this.mark = result;

		return result;
	}

	/**
	 * Remove from a view
	 * @param {View} view
	 */
	detach (view) {
		let {cfiRange, type} = this;
		let result;

		if (view) {
			if (type === "highlight") {
				result = view.unhighlight(cfiRange);
			} else if (type === "underline") {
				result = view.ununderline(cfiRange);
			} else if (type === "mark") {
				result = view.unmark(cfiRange);
			}
		}

		this.mark = undefined;

		return result;
	}

	/**
	 * [Not Implemented] Get text of an annotation
	 * @TODO: needs implementation in contents
	 */
	text () {

	}

}

event_emitter_default()(Annotation.prototype);


/* harmony default export */ const annotations = (Annotations);

;// CONCATENATED MODULE: ./node_modules/marks-pane/src/svg.js
function createElement(name) {
    return document.createElementNS('http://www.w3.org/2000/svg', name);
}

/* harmony default export */ const svg = ({
    createElement: createElement
});

;// CONCATENATED MODULE: ./node_modules/marks-pane/src/events.js
// import 'babelify/polyfill'; // needed for Object.assign

/* harmony default export */ const events = ({
    proxyMouse: proxyMouse
});


/**
 * Start proxying all mouse events that occur on the target node to each node in
 * a set of tracked nodes.
 *
 * The items in tracked do not strictly have to be DOM Nodes, but they do have
 * to have dispatchEvent, getBoundingClientRect, and getClientRects methods.
 *
 * @param target {Node} The node on which to listen for mouse events.
 * @param tracked {Node[]} A (possibly mutable) array of nodes to which to proxy
 *                         events.
 */
function proxyMouse(target, tracked) {
    function dispatch(e) {
        // We walk through the set of tracked elements in reverse order so that
        // events are sent to those most recently added first.
        //
        // This is the least surprising behaviour as it simulates the way the
        // browser would work if items added later were drawn "on top of"
        // earlier ones.
        for (var i = tracked.length - 1; i >= 0; i--) {
            var t = tracked[i];
            var x = e.clientX
            var y = e.clientY;

            if (e.touches && e.touches.length) {
              x = e.touches[0].clientX;
              y = e.touches[0].clientY;
            }

            if (!contains(t, target, x, y)) {
                continue;
            }

            // The event targets this mark, so dispatch a cloned event:
            t.dispatchEvent(clone(e));
            // We only dispatch the cloned event to the first matching mark.
            break;
        }
    }

    if (target.nodeName === "iframe" || target.nodeName === "IFRAME") {

      try {
        // Try to get the contents if same domain
        this.target = target.contentDocument;
      } catch(err){
        this.target = target;
      }

    } else {
      this.target = target;
    }

    for (var ev of ['mouseup', 'mousedown', 'click', 'touchstart']) {
        this.target.addEventListener(ev, (e) => dispatch(e), false);
    }

}


/**
 * Clone a mouse event object.
 *
 * @param e {MouseEvent} A mouse event object to clone.
 * @returns {MouseEvent}
 */
function clone(e) {
    var opts = Object.assign({}, e, {bubbles: false});
    try {
        return new MouseEvent(e.type, opts);
    } catch(err) { // compat: webkit
        var copy = document.createEvent('MouseEvents');
        copy.initMouseEvent(e.type, false, opts.cancelable, opts.view,
                            opts.detail, opts.screenX, opts.screenY,
                            opts.clientX, opts.clientY, opts.ctrlKey,
                            opts.altKey, opts.shiftKey, opts.metaKey,
                            opts.button, opts.relatedTarget);
        return copy;
    }
}


/**
 * Check if the item contains the point denoted by the passed coordinates
 * @param item {Object} An object with getBoundingClientRect and getClientRects
 *                      methods.
 * @param x {Number}
 * @param y {Number}
 * @returns {Boolean}
 */
function contains(item, target, x, y) {
    // offset
    var offset = target.getBoundingClientRect();

    function rectContains(r, x, y) {
        var top = r.top - offset.top;
        var left = r.left - offset.left;
        var bottom = top + r.height;
        var right = left + r.width;
        return (top <= y && left <= x && bottom > y && right > x);
    }

    // Check overall bounding box first
    var rect = item.getBoundingClientRect();
    if (!rectContains(rect, x, y)) {
        return false;
    }

    // Then continue to check each child rect
    var rects = item.getClientRects();
    for (var i = 0, len = rects.length; i < len; i++) {
        if (rectContains(rects[i], x, y)) {
            return true;
        }
    }
    return false;
}

;// CONCATENATED MODULE: ./node_modules/marks-pane/src/marks.js



class Pane {
    constructor(target, container = document.body) {
        this.target = target;
        this.element = svg.createElement('svg');
        this.marks = [];

        // Match the coordinates of the target element
        this.element.style.position = 'absolute';
        // Disable pointer events
        this.element.setAttribute('pointer-events', 'none');

        // Set up mouse event proxying between the target element and the marks
        events.proxyMouse(this.target, this.marks);

        this.container = container;
        this.container.appendChild(this.element);

        this.render();
    }

    addMark(mark) {
        var g = svg.createElement('g');
        this.element.appendChild(g);
        mark.bind(g, this.container);

        this.marks.push(mark);

        mark.render();
        return mark;
    }

    removeMark(mark) {
        var idx = this.marks.indexOf(mark);
        if (idx === -1) {
            return;
        }
        var el = mark.unbind();
        this.element.removeChild(el);
        this.marks.splice(idx, 1);
    }

    render() {
        setCoords(this.element, coords(this.target, this.container));
        for (var m of this.marks) {
            m.render();
        }
    }
}


class Mark {
    constructor() {
        this.element = null;
    }

    bind(element, container) {
        this.element = element;
        this.container = container;
    }

    unbind() {
        var el = this.element;
        this.element = null;
        return el;
    }

    render() {}

    dispatchEvent(e) {
        if (!this.element) return;
        this.element.dispatchEvent(e);
    }

    getBoundingClientRect() {
        return this.element.getBoundingClientRect();
    }

    getClientRects() {
        var rects = [];
        var el = this.element.firstChild;
        while (el) {
            rects.push(el.getBoundingClientRect());
            el = el.nextSibling;
        }
        return rects;
    }

    filteredRanges() {
      var rects = Array.from(this.range.getClientRects());

      // De-duplicate the boxes
      return rects.filter((box) => {
        for (var i = 0; i < rects.length; i++) {
          if (rects[i] === box) {
            return true;
          }
          let contained = marks_contains(rects[i], box);
          if (contained) {
            return false;
          }
        }
        return true;
      })
    }

}

class Highlight extends Mark {
    constructor(range, className, data, attributes) {
        super();
        this.range = range;
        this.className = className;
        this.data = data || {};
        this.attributes = attributes || {};
    }

    bind(element, container) {
        super.bind(element, container);

        for (var attr in this.data) {
          if (this.data.hasOwnProperty(attr)) {
            this.element.dataset[attr] = this.data[attr];
          }
        }

        for (var attr in this.attributes) {
          if (this.attributes.hasOwnProperty(attr)) {
            this.element.setAttribute(attr, this.attributes[attr]);
          }
        }

        if (this.className) {
          this.element.classList.add(this.className);
        }
    }

    render() {
        // Empty element
        while (this.element.firstChild) {
            this.element.removeChild(this.element.firstChild);
        }

        var docFrag = this.element.ownerDocument.createDocumentFragment();
        var filtered = this.filteredRanges();
        var offset = this.element.getBoundingClientRect();
        var container = this.container.getBoundingClientRect();
        container = { top: container.top, left: container.left };
        // take into account padding
        var styles = window.getComputedStyle(this.container);
        container.left += parseInt(styles.paddingLeft);
        container.top += parseInt(styles.paddingTop);

        for (var i = 0, len = filtered.length; i < len; i++) {
            var r = filtered[i];
            var el = svg.createElement('rect');
            el.setAttribute('x', r.left - offset.left + container.left);
            el.setAttribute('y', r.top - offset.top + container.top);
            el.setAttribute('height', r.height);
            el.setAttribute('width', r.width);
            docFrag.appendChild(el);
        }

        this.element.appendChild(docFrag);

    }
}

class Underline extends Highlight {
    constructor(range, className, data, attributes) {
        super(range, className, data,  attributes);
    }

    render() {
        // Empty element
        while (this.element.firstChild) {
            this.element.removeChild(this.element.firstChild);
        }

        var docFrag = this.element.ownerDocument.createDocumentFragment();
        var filtered = this.filteredRanges();
        var offset = this.element.getBoundingClientRect();
        var container = this.container.getBoundingClientRect();

        for (var i = 0, len = filtered.length; i < len; i++) {
            var r = filtered[i];

            var rect = svg.createElement('rect');
            rect.setAttribute('x', r.left - offset.left + container.left);
            rect.setAttribute('y', r.top - offset.top + container.top);
            rect.setAttribute('height', r.height);
            rect.setAttribute('width', r.width);
            rect.setAttribute('fill', 'none');


            var line = svg.createElement('line');
            line.setAttribute('x1', r.left - offset.left + container.left);
            line.setAttribute('x2', r.left - offset.left + container.left + r.width);
            line.setAttribute('y1', r.top - offset.top + container.top + r.height - 1);
            line.setAttribute('y2', r.top - offset.top + container.top + r.height - 1);

            line.setAttribute('stroke-width', 1);
            line.setAttribute('stroke', 'black'); //TODO: match text color?
            line.setAttribute('stroke-linecap', 'square');

            docFrag.appendChild(rect);

            docFrag.appendChild(line);
        }

        this.element.appendChild(docFrag);

    }
}


function coords(el, container) {
    var offset = container.getBoundingClientRect();
    var rect = el.getBoundingClientRect();

    return {
        top: rect.top - offset.top,
        left: rect.left - offset.left,
        height: el.scrollHeight,
        width: el.scrollWidth
    };
}


function setCoords(el, coords) {
    el.style.setProperty('top', `${coords.top}px`, 'important');
    el.style.setProperty('left', `${coords.left}px`, 'important');
    el.style.setProperty('height', `${coords.height}px`, 'important');
    el.style.setProperty('width', `${coords.width}px`, 'important');
}

function marks_contains(rect1, rect2) {
  return (
    (rect2.right <= rect1.right) &&
    (rect2.left >= rect1.left) &&
    (rect2.top >= rect1.top) &&
    (rect2.bottom <= rect1.bottom)
  );
}

;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/views/iframe.js







class IframeView {
	constructor(section, options) {
		this.settings = (0,core.extend)({
			ignoreClass : "",
			axis: options.layout && options.layout.props.flow === "scrolled" ? "vertical" : "horizontal",
			direction: undefined,
			width: 0,
			height: 0,
			layout: undefined,
			globalLayoutProperties: {},
			method: undefined
		}, options || {});

		this.id = "epubjs-view-" + (0,core.uuid)();
		this.section = section;
		this.index = section.index;

		this.element = this.container(this.settings.axis);

		this.added = false;
		this.displayed = false;
		this.rendered = false;

		// this.width  = this.settings.width;
		// this.height = this.settings.height;

		this.fixedWidth  = 0;
		this.fixedHeight = 0;

		// Blank Cfi for Parsing
		this.epubcfi = new epubcfi();

		this.layout = this.settings.layout;
		// console.log("AHOY iframe NEW", this.layout.height);
		// Dom events to listen for
		// this.listenedEvents = ["keydown", "keyup", "keypressed", "mouseup", "mousedown", "click", "touchend", "touchstart"];

		this.pane = undefined;
		this.highlights = {};
		this.underlines = {};
		this.marks = {};

	}

	container(axis) {
		var element = document.createElement("div");

		element.classList.add("epub-view");

		// this.element.style.minHeight = "100px";
		element.style.height = "0px";
		element.style.width = "0px";
		element.style.overflow = "hidden";
		element.style.position = "relative";
		element.style.display = "block";

		if(axis && axis == "horizontal"){
			element.style.flex = "none";
		} else {
			element.style.flex = "initial";
		}

		return element;
	}

	create() {

		if(this.iframe) {
			return this.iframe;
		}

		if(!this.element) {
			this.element = this.createContainer();
		}

		this.iframe = document.createElement("iframe");
		this.iframe.id = this.id;
		this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations
		this.iframe.style.overflow = "hidden";
		this.iframe.seamless = "seamless";
		// Back up if seamless isn't supported
		this.iframe.style.border = "none";

		this.iframe.setAttribute("enable-annotation", "true");

		this.resizing = true;

		// this.iframe.style.display = "none";
		this.element.style.visibility = "hidden";
		this.iframe.style.visibility = "hidden";

		this.iframe.style.width = "0";
		this.iframe.style.height = "0";
		this._width = 0;
		this._height = 0;

		this.element.setAttribute("ref", this.index);

		this.added = true;

		this.elementBounds = (0,core.bounds)(this.element);

		// if(width || height){
		//   this.resize(width, height);
		// } else if(this.width && this.height){
		//   this.resize(this.width, this.height);
		// } else {
		//   this.iframeBounds = bounds(this.iframe);
		// }


		if(("srcdoc" in this.iframe)) {
			this.supportsSrcdoc = true;
		} else {
			this.supportsSrcdoc = false;
		}

		if (!this.settings.method) {
			this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
		}

		return this.iframe;
	}

	render(request, show) {

		// view.onLayout = this.layout.format.bind(this.layout);
		this.create();

		// Fit to size of the container, apply padding
		this.size();

		if(!this.sectionRender) {
			this.sectionRender = this.section.render(request);
		}

		// Render Chain
		return this.sectionRender
			.then(function(contents){
				return this.load(contents);
			}.bind(this))
			.then(function(){

				// apply the layout function to the contents
				// console.log("AHOY IFRAME render", this.layout.height);
				this.layout.format(this.contents);

				// find and report the writingMode axis
				let writingMode = this.contents.writingMode();
				let axis = (writingMode.indexOf("vertical") === 0) ? "vertical" : "horizontal";

				this.setAxis(axis);
				this.emit(EVENTS.VIEWS.AXIS, axis);


				// Listen for events that require an expansion of the iframe
				this.addListeners();

				return new Promise((resolve, reject) => {
					// Expand the iframe to the full size of the content
					this.expand();
					resolve();
				});

			}.bind(this), function(e){
				this.emit(EVENTS.VIEWS.LOAD_ERROR, e);
				return new Promise((resolve, reject) => {
					reject(e);
				});
			}.bind(this))
			.then(function() {
				this.emit(EVENTS.VIEWS.RENDERED, this.section);
			}.bind(this));

	}

	reset () {
		if (this.iframe) {
			this.iframe.style.width = "0";
			this.iframe.style.height = "0";
			this._width = 0;
			this._height = 0;
			this._textWidth = undefined;
			this._contentWidth = undefined;
			this._textHeight = undefined;
			this._contentHeight = undefined;
		}
		this._needsReframe = true;
	}

	// Determine locks base on settings
	size(_width, _height) {
		var width = _width || this.settings.width;
		var height = _height || this.settings.height;

		if(this.layout.name === "pre-paginated") {
			this.lock("both", width, height);
			// console.log("AHOY IRAME size lock", width, height);
		} else if(this.settings.axis === "horizontal") {
			this.lock("height", width, height);
		} else {
			this.lock("width", width, height);
		}

		this.settings.width = width;
		this.settings.height = height;
	}

	// Lock an axis to element dimensions, taking borders into account
	lock(what, width, height) {
		var elBorders = (0,core.borders)(this.element);
		var iframeBorders;

		if(this.iframe) {
			iframeBorders = (0,core.borders)(this.iframe);
		} else {
			iframeBorders = {width: 0, height: 0};
		}

		if(what == "width" && (0,core.isNumber)(width)){
			this.lockedWidth = width - elBorders.width - iframeBorders.width;
			// this.resize(this.lockedWidth, width); //  width keeps ratio correct
		}

		if(what == "height" && (0,core.isNumber)(height)){
			this.lockedHeight = height - elBorders.height - iframeBorders.height;
			// this.resize(width, this.lockedHeight);
		}

		if(what === "both" &&
			 (0,core.isNumber)(width) &&
			 (0,core.isNumber)(height)){

			this.lockedWidth = width - elBorders.width - iframeBorders.width;
			this.lockedHeight = height - elBorders.height - iframeBorders.height;
			// this.resize(this.lockedWidth, this.lockedHeight);
		}

		if(this.displayed && this.iframe) {

			// this.contents.layout();
			this.expand();
		}



	}

	// Resize a single axis based on content dimensions
	expand(force) {
		var width = this.lockedWidth;
		var height = this.lockedHeight;
		var columns;

		var textWidth, textHeight;

		if(!this.iframe || this._expanding) return;

		this._expanding = true;

		if(this.layout.name === 'pre-paginated' && this.settings.axis === 'vertical') {
			height = this.contents.textHeight();
			width = this.contents.textWidth();
            // width = this.layout.columnWidth;

		} else if(this.layout.name === "pre-paginated") {
			width = this.layout.columnWidth;
			height = this.layout.height;
		}
		// Expand Horizontally
		else if(this.settings.axis === "horizontal") {
			// Get the width of the text
			width = this.contents.textWidth();

			if (width % this.layout.pageWidth > 0) {
				width = Math.ceil(width / this.layout.pageWidth) * this.layout.pageWidth;
			}

			if (this.settings.forceEvenPages) {
				columns = (width / this.layout.pageWidth);
				if ( this.layout.divisor > 1 &&
						 this.layout.name === "reflowable" &&
						(columns % 2 > 0)) {
					// add a blank page
					width += this.layout.pageWidth;
				}
			}

		} // Expand Vertically
		else if(this.settings.axis === "vertical") {
			height = this.contents.textHeight();
			// width = this.contents.textWidth();
			// console.log("AHOY AHOY expand", this.index, width, height, "/", this._width, this._height);
		}

		// Only Resize if dimensions have changed or
		// if Frame is still hidden, so needs reframing
		if(this._needsReframe || width != this._width || height != this._height){
			this.reframe(width, height);
		}

		this._expanding = false;
	}

	reframe(width, height) {
		var size;

		if((0,core.isNumber)(width)){
			this.element.style.width = width + "px";
			this.iframe.style.width = width + "px";
			this._width = width;
		}

		if((0,core.isNumber)(height)){
			this.element.style.height = height + "px";
			this.iframe.style.height = height + "px";
			this._height = height;
		}

		let widthDelta = this.prevBounds ? width - this.prevBounds.width : width;
		let heightDelta = this.prevBounds ? height - this.prevBounds.height : height;

		size = {
			width: width,
			height: height,
			widthDelta: widthDelta,
			heightDelta: heightDelta,
		};

		this.pane && this.pane.render();

		requestAnimationFrame(() => {
			let mark;
			for (let m in this.marks) {
				if (this.marks.hasOwnProperty(m)) {
					mark = this.marks[m];
					this.placeMark(mark.element, mark.range);
				}
			}
		});

		this.onResize(this, size);

		this.emit(EVENTS.VIEWS.RESIZED, size);

		this.prevBounds = size;

		this.elementBounds = (0,core.bounds)(this.element);

	}


	load(contents) {
		var loading = new core.defer();
		var loaded = loading.promise;

		if(!this.iframe) {
			loading.reject(new Error("No Iframe Available"));
			return loaded;
		}

		this.iframe.onload = function(event) {

			this.onLoad(event, loading);

		}.bind(this);

		if (this.settings.method === "blobUrl") {
			this.blobUrl = (0,core.createBlobUrl)(contents, "application/xhtml+xml");
			this.iframe.src = this.blobUrl;
			this.element.appendChild(this.iframe);
		} else if(this.settings.method === "srcdoc"){
			contents = contents.replace('</body>', '<script>window.addEventListener("load", (e) => { });</script></body>');
			if ( this.settings.prehooks && this.settings.prehooks.head ) {
				var buffer = [];
				this.settings.prehooks.head.trigger(buffer);
				buffer.forEach((b) => {
					contents = contents.replace('</head>', b + '</head>');
				})
				// contents = contents.replace('</head>', this.settings.prehooks.head(this.settings.layout) + '</head>');
			}
			this.iframe.srcdoc = contents;
			this.element.appendChild(this.iframe);
		} else {

			this.element.appendChild(this.iframe);

			this.document = this.iframe.contentDocument;

			if(!this.document) {
				loading.reject(new Error("No Document Available"));
				return loaded;
			}

			this.iframe.contentDocument.open();
			this.iframe.contentDocument.write(contents);
			this.iframe.contentDocument.close();

		}

		return loaded;
	}

	onLoad(event, promise) {

		this.window = this.iframe.contentWindow;
		this.document = this.iframe.contentDocument;

		this.contents = new contents(this.document, this.document.body, this.section.cfiBase, this.section.index);

		this.rendering = false;

		var link = this.document.querySelector("link[rel='canonical']");
		if (link) {
			link.setAttribute("href", this.section.canonical);
		} else {
			link = this.document.createElement("link");
			link.setAttribute("rel", "canonical");
			link.setAttribute("href", this.section.canonical);
			this.document.querySelector("head").appendChild(link);
		}

		this.contents.on(EVENTS.CONTENTS.EXPAND, () => {
			if(this.displayed && this.iframe) {
				this.expand();
				if (this.contents) {
					this.layout.format(this.contents);
				}
			}
		});

		this.contents.on(EVENTS.CONTENTS.RESIZE, (e) => {
			if(this.displayed && this.iframe) {
				this.expand();
				if (this.contents) {
					this.layout.format(this.contents);
				}
			}
		});

		promise.resolve(this.contents);
	}

	setLayout(layout) {
		this.layout = layout;

		if (this.contents) {
			this.layout.format(this.contents);
			this.expand();
		}
	}

	setAxis(axis) {

		// Force vertical for scrolled
		if (this.layout.props.flow === "scrolled") {
			axis = "vertical";
		}

		this.settings.axis = axis;

		if(axis == "horizontal"){
			this.element.style.flex = "none";
		} else {
			this.element.style.flex = "initial";
		}

		this.size();

	}

	addListeners() {
		//TODO: Add content listeners for expanding
	}

	removeListeners(layoutFunc) {
		//TODO: remove content listeners for expanding
	}

	display(request) {
		var displayed = new core.defer();

		if (!this.displayed) {

			this.render(request)
				.then(function () {

					this.emit(EVENTS.VIEWS.DISPLAYED, this);
					this.onDisplayed(this);

					this.displayed = true;
					displayed.resolve(this);

				}.bind(this), function (err) {
					displayed.reject(err, this);
				});

		} else {
			displayed.resolve(this);
		}


		return displayed.promise;
	}

	show() {

		this.element.style.visibility = "visible";

		if(this.iframe){
			this.iframe.style.visibility = "visible";

			// Remind Safari to redraw the iframe
			this.iframe.style.transform = "translateZ(0)";
			this.iframe.offsetWidth;
			this.iframe.style.transform = null;
		}

		// console.log("AHOY VIEWS iframe show", this.index);
		this.emit(EVENTS.VIEWS.SHOWN, this);
	}

	hide() {
		// this.iframe.style.display = "none";
		this.element.style.visibility = "hidden";
		this.iframe.style.visibility = "hidden";

		this.stopExpanding = true;
		// console.log("AHOY VIEWS iframe hide", this.index);
		this.emit(EVENTS.VIEWS.HIDDEN, this);
	}

	offset() {
		return {
			top: this.element.offsetTop,
			left: this.element.offsetLeft
		}
	}

	width() {
		return this._width;
	}

	height() {
		return this._height;
	}

	position() {
		return this.element.getBoundingClientRect();
	}

	locationOf(target) {
		var parentPos = this.iframe.getBoundingClientRect();
		var targetPos = this.contents.locationOf(target, this.settings.ignoreClass);

		return {
			"left": targetPos.left,
			"top": targetPos.top
		};
	}

	onDisplayed(view) {
		// Stub, override with a custom functions
	}

	onResize(view, e) {
		// Stub, override with a custom functions
	}

	bounds(force) {
		if(force || !this.elementBounds) {
			this.elementBounds = (0,core.bounds)(this.element);
		}

		return this.elementBounds;
	}

	highlight(cfiRange, data={}, cb, className = "epubjs-hl", styles = {}) {
		if (!this.contents) {
			return;
		}
		const attributes = Object.assign({"fill": "yellow", "fill-opacity": "0.3", "mix-blend-mode": "multiply"}, styles);
		let range = this.contents.range(cfiRange);

		let emitter = () => {
			this.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
		};

		data["epubcfi"] = cfiRange;

		if (!this.pane) {
			this.pane = new Pane(this.iframe, this.element);
		}

		let m = new Highlight(range, className, data, attributes);
		let h = this.pane.addMark(m);

		this.highlights[cfiRange] = { "mark": h, "element": h.element, "listeners": [emitter, cb] };

		h.element.setAttribute("ref", className);
		h.element.addEventListener("click", emitter);
		h.element.addEventListener("touchstart", emitter);

		if (cb) {
			h.element.addEventListener("click", cb);
			h.element.addEventListener("touchstart", cb);
		}
		return h;
	}

	underline(cfiRange, data={}, cb, className = "epubjs-ul", styles = {}) {
		if (!this.contents) {
			return;
		}
		const attributes = Object.assign({"stroke": "black", "stroke-opacity": "0.3", "mix-blend-mode": "multiply"}, styles);
		let range = this.contents.range(cfiRange);
		let emitter = () => {
			this.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
		};

		data["epubcfi"] = cfiRange;

		if (!this.pane) {
			this.pane = new Pane(this.iframe, this.element);
		}

		let m = new Underline(range, className, data, attributes);
		let h = this.pane.addMark(m);

		this.underlines[cfiRange] = { "mark": h, "element": h.element, "listeners": [emitter, cb] };

		h.element.setAttribute("ref", className);
		h.element.addEventListener("click", emitter);
		h.element.addEventListener("touchstart", emitter);

		if (cb) {
			h.element.addEventListener("click", cb);
			h.element.addEventListener("touchstart", cb);
		}
		return h;
	}

	mark(cfiRange, data={}, cb) {
		if (!this.contents) {
			return;
		}

		if (cfiRange in this.marks) {
			let item = this.marks[cfiRange];
			return item;
		}

		let range = this.contents.range(cfiRange);
		if (!range) {
			return;
		}
		let container = range.commonAncestorContainer;
		let parent = (container.nodeType === 1) ? container : container.parentNode;

		let emitter = (e) => {
			this.emit(EVENTS.VIEWS.MARK_CLICKED, cfiRange, data);
		};

		if (range.collapsed && container.nodeType === 1) {
			range = new Range();
			range.selectNodeContents(container);
		} else if (range.collapsed) { // Webkit doesn't like collapsed ranges
			range = new Range();
			range.selectNodeContents(parent);
		}

		let mark = this.document.createElement("a");
		mark.setAttribute("ref", "epubjs-mk");
		mark.style.position = "absolute";

		mark.dataset["epubcfi"] = cfiRange;

		if (data) {
			Object.keys(data).forEach((key) => {
				mark.dataset[key] = data[key];
			});
		}

		if (cb) {
			mark.addEventListener("click", cb);
			mark.addEventListener("touchstart", cb);
		}

		mark.addEventListener("click", emitter);
		mark.addEventListener("touchstart", emitter);

		this.placeMark(mark, range);

		this.element.appendChild(mark);

		this.marks[cfiRange] = { "element": mark, "range": range, "listeners": [emitter, cb] };

		return parent;
	}

	placeMark(element, range) {
		let top, right, left;

		if(this.layout.name === "pre-paginated" ||
			this.settings.axis !== "horizontal") {
			let pos = range.getBoundingClientRect();
			top = pos.top;
			right = pos.right;
		} else {
			// Element might break columns, so find the left most element
			let rects = range.getClientRects();

			let rect;
			for (var i = 0; i != rects.length; i++) {
				rect = rects[i];
				if (!left || rect.left < left) {
					left = rect.left;
					// right = rect.right;
					right = Math.ceil(left / this.layout.props.pageWidth) * this.layout.props.pageWidth - (this.layout.gap / 2);
					top = rect.top;
				}
			}
		}

		element.style.top = `${top}px`;
		element.style.left = `${right}px`;
	}

	unhighlight(cfiRange) {
		let item;
		if (cfiRange in this.highlights) {
			item = this.highlights[cfiRange];

			this.pane.removeMark(item.mark);
			item.listeners.forEach((l) => {
				if (l) {
					item.element.removeEventListener("click", l);
					item.element.removeEventListener("touchstart", l);
				};
			});
			delete this.highlights[cfiRange];
		}
	}

	ununderline(cfiRange) {
		let item;
		if (cfiRange in this.underlines) {
			item = this.underlines[cfiRange];
			this.pane.removeMark(item.mark);
			item.listeners.forEach((l) => {
				if (l) {
					item.element.removeEventListener("click", l);
					item.element.removeEventListener("touchstart", l);
				};
			});
			delete this.underlines[cfiRange];
		}
	}

	unmark(cfiRange) {
		let item;
		if (cfiRange in this.marks) {
			item = this.marks[cfiRange];
			this.element.removeChild(item.element);
			item.listeners.forEach((l) => {
				if (l) {
					item.element.removeEventListener("click", l);
					item.element.removeEventListener("touchstart", l);
				};
			});
			delete this.marks[cfiRange];
		}
	}

	destroy() {

		for (let cfiRange in this.highlights) {
			this.unhighlight(cfiRange);
		}

		for (let cfiRange in this.underlines) {
			this.ununderline(cfiRange);
		}

		for (let cfiRange in this.marks) {
			this.unmark(cfiRange);
		}

		if (this.blobUrl) {
			(0,core.revokeBlobUrl)(this.blobUrl);
		}

		if(this.displayed){
			this.displayed = false;

			this.removeListeners();

			this.stopExpanding = true;
			this.element.removeChild(this.iframe);

			this.iframe = undefined;
			this.contents = undefined;

			this._textWidth = null;
			this._textHeight = null;
			this._width = null;
			this._height = null;
		}

		// this.element.style.height = "0px";
		// this.element.style.width = "0px";
	}
}

event_emitter_default()(IframeView.prototype);

/* harmony default export */ const iframe = (IframeView);

// EXTERNAL MODULE: ./node_modules/lodash/throttle.js
var throttle = __webpack_require__(3493);
var throttle_default = /*#__PURE__*/__webpack_require__.n(throttle);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/helpers/stage.js



class Stage {
	constructor(_options) {
		this.settings = _options || {};
		this.id = "epubjs-container-" + (0,core.uuid)();

		this.container = this.create(this.settings);

		if(this.settings.hidden) {
			this.wrapper = this.wrap(this.container);
		}

	}

	/*
	* Creates an element to render to.
	* Resizes to passed width and height or to the elements size
	*/
	create(options){
		let height  = options.height;// !== false ? options.height : "100%";
		let width   = options.width;// !== false ? options.width : "100%";
		let overflow  = options.overflow || false;
		let axis = options.axis || "vertical";
		let direction = options.direction;
		let scale = options.scale || 1.0;

		if(options.height && (0,core.isNumber)(options.height)) {
			height = options.height + "px";
		}

		if(options.width && (0,core.isNumber)(options.width)) {
			width = options.width + "px";
		}

		// Create new container element
		let container = document.createElement("div");

		container.id = this.id;
		container.classList.add("epub-container");

		// Style Element
		// container.style.fontSize = "0";
		container.style.wordSpacing = "0";
		container.style.lineHeight = "0";
		container.style.verticalAlign = "top";
		container.style.position = "relative";

		if(axis === "horizontal") {
			// container.style.whiteSpace = "nowrap";
			container.style.display = "flex";
			container.style.flexDirection = "row";
			container.style.flexWrap = "nowrap";
		}

		if(width){
			container.style.width = width;
		}

		if(height){
			container.style.height = height;
		}

		if (overflow) {
			container.style.overflow = overflow;
		}

		if (direction) {
			container.dir = direction;
			container.style["direction"] = direction;
		}

		if (direction && this.settings.fullsize) {
			document.body.style["direction"] = direction;
		}

		if (scale && scale != 1.0) {
			container.style["transform-origin"] = "top left";
			container.style["transform"] = "scale(" + scale + ")";
			container.style.overflow = "auto"; // "visible" breaks something?
		} else {
			container.style["transform-origin"] = null;
			container.style["transform"] = null;
		}

		return container;
	}

	wrap(container) {
		var wrapper = document.createElement("div");

		wrapper.style.visibility = "hidden";
		wrapper.style.overflow = "hidden";
		wrapper.style.width = "0";
		wrapper.style.height = "0";

		wrapper.appendChild(container);
		return wrapper;
	}


	getElement(_element){
		var element;

		if((0,core.isElement)(_element)) {
			element = _element;
		} else if (typeof _element === "string") {
			element = document.getElementById(_element);
		}

		if(!element){
			throw new Error("Not an Element");
		}

		return element;
	}

	attachTo(what){

		var element = this.getElement(what);
		var base;

		if(!element){
			return;
		}

		if(this.settings.hidden) {
			base = this.wrapper;
		} else {
			base = this.container;
		}

		element.appendChild(base);

		this.element = element;

		return element;

	}

	getContainer() {
		return this.container;
	}

	onResize(func){
		// Only listen to window for resize event if width and height are not fixed.
		// This applies if it is set to a percent or auto.
		if(!(0,core.isNumber)(this.settings.width) ||
			 !(0,core.isNumber)(this.settings.height) ) {
			this.resizeFunc = throttle_default()(func, 50);
			window.addEventListener("resize", this.resizeFunc, false);
		}

	}

	onOrientationChange(func){
		this.orientationChangeFunc = func;
		window.addEventListener("orientationchange", this.orientationChangeFunc, false);
	}

	size(width, height){
		var bounds;
		let _width = width || this.settings.width;
		let _height = height || this.settings.height;

		// If width or height are set to false, inherit them from containing element
		if(width === null) {
			bounds = this.element.getBoundingClientRect();

			if(bounds.width) {
				width = Math.floor(bounds.width);
				this.container.style.width = width + "px";
			}
		} else {
			if ((0,core.isNumber)(width)) {
				this.container.style.width = width + "px";
			} else {
				this.container.style.width = width;
			}
		}

		if(height === null) {
			bounds = bounds || this.element.getBoundingClientRect();

			if(bounds.height) {
				height = bounds.height;
				this.container.style.height = height + "px";
			}

		} else {
			if ((0,core.isNumber)(height)) {
				this.container.style.height = height + "px";
			} else {
				this.container.style.height = height;
			}
		}

		var _round = function(value) {
			return Math.round(value);

			// -- this calculates the closest even number to value
			var retval = 2 * Math.round(value / 2);
			if ( retval > value ) {
				retval -= 2;
			}
			return retval;
		}

		if(!(0,core.isNumber)(width)) {
			bounds = this.container.getBoundingClientRect();
			width = _round(bounds.width); // Math.floor(bounds.width);
			//height = bounds.height;
		}

		if(!(0,core.isNumber)(height)) {
			bounds = bounds || this.container.getBoundingClientRect();
			//width = bounds.width;
			height = _round(bounds.height); // bounds.height;
		}


		this.containerStyles = window.getComputedStyle(this.container);

		this.containerPadding = {
			left: parseFloat(this.containerStyles["padding-left"]) || 0,
			right: parseFloat(this.containerStyles["padding-right"]) || 0,
			top: parseFloat(this.containerStyles["padding-top"]) || 0,
			bottom: parseFloat(this.containerStyles["padding-bottom"]) || 0
		};

		// Bounds not set, get them from window
		let _windowBounds = (0,core.windowBounds)();
		let bodyStyles = window.getComputedStyle(document.body);
		let bodyPadding = {
			left: parseFloat(bodyStyles["padding-left"]) || 0,
			right: parseFloat(bodyStyles["padding-right"]) || 0,
			top: parseFloat(bodyStyles["padding-top"]) || 0,
			bottom: parseFloat(bodyStyles["padding-bottom"]) || 0
		};

		if (!_width) {
			width = _windowBounds.width -
								bodyPadding.left -
								bodyPadding.right;
		}

		if ((this.settings.fullsize && !_height) || !_height) {
			height = _windowBounds.height -
								bodyPadding.top -
								bodyPadding.bottom;
		}

		if ( this.settings.scale ) {
			width /= this.settings.scale;
			height /= this.settings.scale;
		}

		return {
			width: width -
							this.containerPadding.left -
							this.containerPadding.right,
			height: height -
							this.containerPadding.top -
							this.containerPadding.bottom
		};

	}

	bounds(){
		let box;
		if (this.container.style.overflow !== "visible") {
			box = this.container && this.container.getBoundingClientRect();
		}

		if(!box || !box.width || !box.height) {
			return (0,core.windowBounds)();
		} else {
			return box;
		}

	}

	getSheet(){
		var style = document.createElement("style");

		// WebKit hack --> https://davidwalsh.name/add-rules-stylesheets
		style.appendChild(document.createTextNode(""));

		document.head.appendChild(style);

		return style.sheet;
	}

	addStyleRules(selector, rulesArray){
		var scope = "#" + this.id + " ";
		var rules = "";

		if(!this.sheet){
			this.sheet = this.getSheet();
		}

		rulesArray.forEach(function(set) {
			for (var prop in set) {
				if(set.hasOwnProperty(prop)) {
					rules += prop + ":" + set[prop] + ";";
				}
			}
		});

		this.sheet.insertRule(scope + selector + " {" + rules + "}", 0);
	}

	axis(axis) {
		if(axis === "horizontal") {
			this.container.style.display = "flex";
			this.container.style.flexDirection = "row";
			this.container.style.flexWrap = "nowrap";
		} else {
			this.container.style.display = "block";
		}
	}

	// orientation(orientation) {
	// 	if (orientation === "landscape") {
	//
	// 	} else {
	//
	// 	}
	//
	// 	this.orientation = orientation;
	// }

	direction(dir) {
		if (this.container) {
			this.container.dir = dir;
			this.container.style["direction"] = dir;
		}

		if (this.settings.fullsize) {
			document.body.style["direction"] = dir;
		}
	}

	overflow(overflow) {
		if (this.container) {
			this.container.style["overflow"] = overflow;
		}
	}

	scale(s) {
		if (this.container) {
			if ( s != 1.0 ) {
				this._originalOverflow = this.container.style.overflow;
				this.container.style["transform-origin"] = "top left";
				this.container.style["transform"] = "scale(" + s + ")";
				this.container.style.overflow = "auto"; // "visible"
			} else {
				this.container.style.overflow = this._originalOverflow;
				this.container.style["transform-origin"] = null;
				this.container.style["transform"] = null;
			}
			this.settings.scale = s;
		}
	}

	destroy() {
		var base;

		if (this.element) {

			if(this.settings.hidden) {
				base = this.wrapper;
			} else {
				base = this.container;
			}

			if(this.element.contains(this.container)) {
				this.element.removeChild(this.container);
			}

			window.removeEventListener("resize", this.resizeFunc);
			window.removeEventListener("orientationChange", this.orientationChangeFunc);

		}
	}
}

/* harmony default export */ const stage = (Stage);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/helpers/views.js
class Views {
	constructor(container) {
		this.container = container;
		this._views = [];
		this.length = 0;
		this.hidden = false;
	}

	all() {
		return this._views;
	}

	first() {
		return this._views[0];
	}

	last() {
		return this._views[this._views.length-1];
	}

	indexOf(view) {
		return this._views.indexOf(view);
	}

	slice() {
		return this._views.slice.apply(this._views, arguments);
	}

	get(i) {
		return this._views[i];
	}

	append(view){
		this._views.push(view);
		if(this.container){
			this.container.appendChild(view.element);
		}
		this.length++;
		return view;
	}

	prepend(view){
		this._views.unshift(view);
		if(this.container){
			this.container.insertBefore(view.element, this.container.firstChild);
		}
		this.length++;
		return view;
	}

	insert(view, index) {
		this._views.splice(index, 0, view);

		if(this.container){
			if(index < this.container.children.length){
				this.container.insertBefore(view.element, this.container.children[index]);
			} else {
				this.container.appendChild(view.element);
			}
		}

		this.length++;
		return view;
	}

	remove(view) {
		var index = this._views.indexOf(view);

		if(index > -1) {
			this._views.splice(index, 1);
		}


		this.destroy(view);

		this.length--;
	}

	destroy(view) {
		if(view.displayed){
			view.destroy();
		}

		if(this.container){
			 this.container.removeChild(view.element);
		}
		view = null;
	}

	// Iterators

	forEach() {
		return this._views.forEach.apply(this._views, arguments);
	}

	clear(){
		// Remove all views
		var view;
		var len = this.length;

		if(!this.length) return;

		for (var i = 0; i < len; i++) {
			view = this._views[i];
			this.destroy(view);
		}

		this._views = [];
		this.length = 0;
	}

	find(section){

		var view;
		var len = this.length;

		for (var i = 0; i < len; i++) {
			view = this._views[i];
			if(view.displayed && view.section.index == section.index) {
				return view;
			}
		}

	}

	displayed(){
		var displayed = [];
		var view;
		var len = this.length;

		for (var i = 0; i < len; i++) {
			view = this._views[i];
			if(view.displayed){
				displayed.push(view);
			}
		}
		return displayed;
	}

	show(){
		var view;
		var len = this.length;

		for (var i = 0; i < len; i++) {
			view = this._views[i];
			if(view.displayed){
				view.show();
			}
		}
		this.hidden = false;
	}

	hide(){
		var view;
		var len = this.length;

		for (var i = 0; i < len; i++) {
			view = this._views[i];
			if(view.displayed){
				view.hide();
			}
		}
		this.hidden = true;
	}
}

/* harmony default export */ const views = (Views);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/default/index.js








class DefaultViewManager {
	constructor(options) {

		this.name = "default";
		this.optsSettings = options.settings;
		this.View = options.view;
		this.request = options.request;
		this.renditionQueue = options.queue;
		this.q = new queue(this);

		this.settings = (0,core.extend)(this.settings || {}, {
			infinite: true,
			hidden: false,
			width: undefined,
			height: undefined,
			axis: undefined,
			flow: "scrolled",
			ignoreClass: "",
			fullsize: undefined
		});

		(0,core.extend)(this.settings, options.settings || {});

		this.viewSettings = {
			prehooks: this.settings.prehooks,
			ignoreClass: this.settings.ignoreClass,
			axis: this.settings.axis,
			flow: this.settings.flow,
			layout: this.layout,
			method: this.settings.method, // srcdoc, blobUrl, write
			width: 0,
			height: 0,
			forceEvenPages: true
		};

		this.rendered = false;

	}

	render(element, size){
		let tag = element.tagName;

		if (typeof this.settings.fullsize === "undefined" &&
				tag && (tag.toLowerCase() == "body" ||
				tag.toLowerCase() == "html")) {
				this.settings.fullsize = true;
		}

		if (this.settings.fullsize) {
			this.settings.overflow = "visible";
			this.overflow = this.settings.overflow;
		}

		this.settings.size = size;

		// Save the stage
		this.stage = new stage({
			width: size.width,
			height: size.height,
			overflow: this.overflow,
			hidden: this.settings.hidden,
			axis: this.settings.axis,
			fullsize: this.settings.fullsize,
			direction: this.settings.direction,
			scale: this.settings.scale
		});

		this.stage.attachTo(element);

		// Get this stage container div
		this.container = this.stage.getContainer();

		// Views array methods
		this.views = new views(this.container);

		// Calculate Stage Size
		this._bounds = this.bounds();
		this._stageSize = this.stage.size();

		// Set the dimensions for views
		this.viewSettings.width = this._stageSize.width;
		this.viewSettings.height = this._stageSize.height;

		// Function to handle a resize event.
		// Will only attach if width and height are both fixed.
		this.stage.onResize(this.onResized.bind(this));

		this.stage.onOrientationChange(this.onOrientationChange.bind(this));

		// Add Event Listeners
		this.addEventListeners();

		// Add Layout method
		// this.applyLayoutMethod();
		if (this.layout) {
			this.updateLayout();
		}

		this.rendered = true;

	}

	addEventListeners(){
		var scroller;

		window.addEventListener("unload", function(e){
			this.destroy();
		}.bind(this));

		if(!this.settings.fullsize) {
			scroller = this.container;
		} else {
			scroller = window;
		}

		this._onScroll = this.onScroll.bind(this);
		scroller.addEventListener("scroll", this._onScroll);
	}

	removeEventListeners(){
		var scroller;

		if(!this.settings.fullsize) {
			scroller = this.container;
		} else {
			scroller = window;
		}

		scroller.removeEventListener("scroll", this._onScroll);
		this._onScroll = undefined;
	}

	destroy(){
		clearTimeout(this.orientationTimeout);
		clearTimeout(this.resizeTimeout);
		clearTimeout(this.afterScrolled);

		this.clear();

		this.removeEventListeners();

		this.stage.destroy();

		this.rendered = false;

		/*

			clearTimeout(this.trimTimeout);
			if(this.settings.hidden) {
				this.element.removeChild(this.wrapper);
			} else {
				this.element.removeChild(this.container);
			}
		*/
	}

	onOrientationChange(e) {
		let {orientation} = window;

		if(this.optsSettings.resizeOnOrientationChange) {
			this.resize();
		}

		// Per ampproject:
		// In IOS 10.3, the measured size of an element is incorrect if the
		// element size depends on window size directly and the measurement
		// happens in window.resize event. Adding a timeout for correct
		// measurement. See https://github.com/ampproject/amphtml/issues/8479
		clearTimeout(this.orientationTimeout);
		this.orientationTimeout = setTimeout(function(){
			this.orientationTimeout = undefined;

			if(this.optsSettings.resizeOnOrientationChange) {
				this.resize();
			}

			this.emit(EVENTS.MANAGERS.ORIENTATION_CHANGE, orientation);
		}.bind(this), 500);

	}

	onResized(e) {
		this.resize();
	}

	resize(width, height){
		let stageSize = this.stage.size(width, height);

		// For Safari, wait for orientation to catch up
		// if the window is a square
		this.winBounds = (0,core.windowBounds)();
		if (this.orientationTimeout &&
				this.winBounds.width === this.winBounds.height) {
			// reset the stage size for next resize
			this._stageSize = undefined;
			return;
		}

		if (this._stageSize &&
				this._stageSize.width === stageSize.width &&
				this._stageSize.height === stageSize.height ) {
			// Size is the same, no need to resize
			return;
		}

		this._stageSize = stageSize;

		this._bounds = this.bounds();

		// Clear current views
		this.clear();

		// Update for new views
		this.viewSettings.width = this._stageSize.width;
		this.viewSettings.height = this._stageSize.height;

		this.updateLayout();

		this.emit(EVENTS.MANAGERS.RESIZED, {
			width: this._stageSize.width,
			height: this._stageSize.height
		});
	}

	createView(section) {
		return new this.View(section, this.viewSettings);
	}

	display(section, target){

		var displaying = new core.defer();
		var displayed = displaying.promise;

		// Check if moving to target is needed
		if (target === section.href || (0,core.isNumber)(target)) {
			target = undefined;
		}

		// Check to make sure the section we want isn't already shown
		var visible = this.views.find(section);

		// View is already shown, just move to correct location in view
		if(visible && section) {
			let offset = visible.offset();

			if (this.settings.direction === "ltr") {
				this.scrollTo(offset.left, offset.top, true);
			} else {
				let width = visible.width();
				this.scrollTo(offset.left + width, offset.top, true);
			}

			if(target) {
				let offset = visible.locationOf(target);
				this.moveTo(offset);
			}

			displaying.resolve();
			return displayed;
		}

		// Hide all current views
		this.clear();

		this.add(section)
			.then(function(view){

				// Move to correct place within the section, if needed
				if(target) {
					let offset = view.locationOf(target);
					this.moveTo(offset);
					view.__target = { target: target, offset: offset };
				}

			}.bind(this), (err) => {
				displaying.reject(err);
			})
			.then(function(){
				var next;
				if (this.layout.name === "pre-paginated" &&
						this.layout.divisor > 1 && section.index > 0) {
					// First page (cover) should stand alone for pre-paginated books
					next = section.next();
					if (next) {
						return this.add(next);
					}
				}
			}.bind(this))
			.then(function(){

				this.views.show();
				displaying.resolve();

			}.bind(this));
		// .then(function(){
		// 	return this.hooks.display.trigger(view);
		// }.bind(this))
		// .then(function(){
		// 	this.views.show();
		// }.bind(this));
		return displayed;
	}

	afterDisplayed(view){
		this.emit(EVENTS.MANAGERS.ADDED, view);
	}

	afterResized(view){
		if ( view.__target ) {
			let offset = view.locationOf(view.__target.target);
			if ( offset.left != view.__target.offset.left && offset.top != view.__target.offset.top ) {
				this.moveTo(offset, false);
			}
			view.__target = undefined;
		}
		this.emit(EVENTS.MANAGERS.RESIZE, view.section);
	}

	moveTo(offset, silent=true){
		var distX = 0,
			  distY = 0;

		if(!this.isPaginated) {
			distY = offset.top;
		} else {
			distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;

			if (distX + this.layout.delta > this.container.scrollWidth) {
				distX = this.container.scrollWidth - this.layout.delta;
			}
		}
		this.scrollTo(distX, distY, silent);
	}

	add(section){
		var view = this.createView(section);

		this.views.append(view);

		// view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));
		view.onDisplayed = this.afterDisplayed.bind(this);
		view.onResize = this.afterResized.bind(this);

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		return view.display(this.request);

	}

	append(section){
		var view = this.createView(section);
		this.views.append(view);

		view.onDisplayed = this.afterDisplayed.bind(this);
		view.onResize = this.afterResized.bind(this);

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		return view.display(this.request);
	}

	prepend(section){
		var view = this.createView(section);

		view.on(EVENTS.VIEWS.RESIZED, (bounds) => {
			this.counter(bounds);
		});

		this.views.prepend(view);

		view.onDisplayed = this.afterDisplayed.bind(this);
		view.onResize = this.afterResized.bind(this);

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		return view.display(this.request);
	}

	counter(bounds){
		if(this.settings.axis === "vertical") {
			this.scrollBy(0, bounds.heightDelta, true);
		} else {
			this.scrollBy(bounds.widthDelta, 0, true);
		}

	}

	// resizeView(view) {
	//
	// 	if(this.settings.globalLayoutProperties.layout === "pre-paginated") {
	// 		view.lock("both", this.bounds.width, this.bounds.height);
	// 	} else {
	// 		view.lock("width", this.bounds.width, this.bounds.height);
	// 	}
	//
	// };

	next(){
		var next;
		var left;

		let dir = this.settings.direction;

		if(!this.views.length) return;

		if(this.isPaginated && this.settings.axis === "horizontal" && (!dir || dir === "ltr")) {

			this.scrollLeft = this.container.scrollLeft;

			left = this.container.scrollLeft + this.container.offsetWidth + this.layout.delta;

			if(left <= this.container.scrollWidth) {
				this.scrollBy(this.layout.delta, 0, true);
			} else {
				next = this.views.last().section.next();
			}
		} else if (this.isPaginated && this.settings.axis === "horizontal" && dir === "rtl") {

			this.scrollLeft = this.container.scrollLeft;

			left = this.container.scrollLeft;

			if(left > 0) {
				this.scrollBy(this.layout.delta, 0, true);
			} else {
				next = this.views.last().section.next();
			}

		} else if (this.isPaginated && this.settings.axis === "vertical") {

			this.scrollTop = this.container.scrollTop;

			let top  = this.container.scrollTop + this.container.offsetHeight;

			if(top < this.container.scrollHeight) {
				this.scrollBy(0, this.layout.height, true);
			} else {
				next = this.views.last().section.next();
			}

		} else {
			next = this.views.last().section.next();
		}

		if(next) {
			this.clear();

			return this.append(next)
				.then(function(){
					var right;
					if (this.layout.name === "pre-paginated" && this.layout.divisor > 1) {
						right = next.next();
						if (right) {
							return this.append(right);
						}
					}
				}.bind(this), (err) => {
					return err;
				})
				.then(function(){
					this.views.show();
				}.bind(this));
		}


	}

	prev(){
		var prev;
		var left;
		let dir = this.settings.direction;

		if(!this.views.length) return;

		if(this.isPaginated && this.settings.axis === "horizontal" && (!dir || dir === "ltr")) {

			this.scrollLeft = this.container.scrollLeft;

			left = this.container.scrollLeft;

			if(left > 0) {
				this.scrollBy(-this.layout.delta, 0, true);
			} else {
				prev = this.views.first().section.prev();
			}

		} else if (this.isPaginated && this.settings.axis === "horizontal" && dir === "rtl") {

			this.scrollLeft = this.container.scrollLeft;

			left = this.container.scrollLeft + this.container.offsetWidth + this.layout.delta;

			if(left <= this.container.scrollWidth) {
				this.scrollBy(-this.layout.delta, 0, true);
			} else {
				prev = this.views.first().section.prev();
			}

		} else if (this.isPaginated && this.settings.axis === "vertical") {

			this.scrollTop = this.container.scrollTop;

			let top = this.container.scrollTop;

			if(top > 0) {
				this.scrollBy(0, -(this.layout.height), true);
			} else {
				prev = this.views.first().section.prev();
			}

		} else {

			prev = this.views.first().section.prev();

		}

		if(prev) {
			this.clear();

			return this.prepend(prev)
				.then(function(){
					var left;
					if (this.layout.name === "pre-paginated" && this.layout.divisor > 1) {
						left = prev.prev();
						if (left) {
							return this.prepend(left);
						}
					}
				}.bind(this), (err) => {
					return err;
				})
				.then(function(){
					if(this.isPaginated && this.settings.axis === "horizontal") {
						if (this.settings.direction === "rtl") {
							this.scrollTo(0, 0, true);
						} else {
							this.scrollTo(this.container.scrollWidth - this.layout.delta, 0, true);
						}
					}
					this.views.show();
				}.bind(this));
		}
	}

	current(){
		var visible = this.visible();
		if(visible.length){
			// Current is the last visible view
			return visible[visible.length-1];
		}
		return null;
	}

	clear () {

		// this.q.clear();

		if (this.views) {
			this.views.hide();
			this.scrollTo(0,0, true);
			this.views.clear();
		}
	}

	currentLocation(){

		if (this.settings.axis === "vertical") {
			this.location = this.scrolledLocation();
		} else {
			this.location = this.paginatedLocation();
		}
		return this.location;
	}

	scrolledLocation() {
		let visible = this.visible();
		let container = this.container.getBoundingClientRect();
		let pageHeight = (container.height < window.innerHeight) ? container.height : window.innerHeight;

		let offset = 0;
		let used = 0;

		if(this.settings.fullsize) {
			offset = window.scrollY;
		}

		let sections = visible.map((view) => {
			let {index, href} = view.section;
			let position = view.position();
			let height = view.height();

			let startPos = offset + container.top - position.top + used;
			let endPos = startPos + pageHeight - used;
			if (endPos > height) {
				endPos = height;
				used = (endPos - startPos);
			}

			let totalPages = this.layout.count(height, pageHeight).pages;

			let currPage = Math.ceil(startPos / pageHeight);
			let pages = [];
			let endPage = Math.ceil(endPos / pageHeight);

			pages = [];
			for (var i = currPage; i <= endPage; i++) {
				let pg = i + 1;
				pages.push(pg);
			}

			let mapping = this.mapping.page(view.contents, view.section.cfiBase, startPos, endPos);

			return {
				index,
				href,
				pages,
				totalPages,
				mapping
			};
		});

		return sections;
	}

	paginatedLocation(){
		let visible = this.visible();
		let container = this.container.getBoundingClientRect();

		let left = 0;
		let used = 0;

		if(this.settings.fullsize) {
			left = window.scrollX;
		}

		let sections = visible.map((view) => {
			let {index, href} = view.section;
			let offset = view.offset().left;
			let position = view.position().left;
			let width = view.width();

			// Find mapping
			let start = left + container.left - position + used;
			let end = start + this.layout.width - used;

			let mapping = this.mapping.page(view.contents, view.section.cfiBase, start, end);

			// Find displayed pages
			//console.log("pre", end, offset + width);
			// if (end > offset + width) {
			// 	end = offset + width;
			// 	used = this.layout.pageWidth;
			// }
			// console.log("post", end);

			let totalPages = this.layout.count(width).pages;
			let startPage = Math.floor(start / this.layout.pageWidth);
			let pages = [];
			let endPage = Math.floor(end / this.layout.pageWidth);

			// start page should not be negative
			if (startPage < 0) {
				startPage = 0;
				endPage = endPage + 1;
			}

			// Reverse page counts for rtl
			if (this.settings.direction === "rtl") {
				let tempStartPage = startPage;
				startPage = totalPages - endPage;
				endPage = totalPages - tempStartPage;
			}


			for (var i = startPage + 1; i <= endPage; i++) {
				let pg = i;
				pages.push(pg);
			}

			return {
				index,
				href,
				pages,
				totalPages,
				mapping
			};
		});

		return sections;
	}

	isVisible(view, offsetPrev, offsetNext, _container){
		var position = view.position();
		var container = _container || this.bounds();

		if(this.settings.axis === "horizontal" &&
			position.right > container.left - offsetPrev &&
			position.left < container.right + offsetNext) {

			return true;

		} else if(this.settings.axis === "vertical" &&
			position.bottom > container.top - offsetPrev &&
			position.top < container.bottom + offsetNext) {

			return true;
		}

		return false;

	}

	visible(){
		var container = this.bounds();
		var views = this.views.displayed();
		var viewsLength = views.length;
		var visible = [];
		var isVisible;
		var view;

		for (var i = 0; i < viewsLength; i++) {
			view = views[i];
			isVisible = this.isVisible(view, 0, 0, container);

			if(isVisible === true) {
				visible.push(view);
			}

		}
		return visible;
	}

	scrollBy(x, y, silent){
		let dir = this.settings.direction === "rtl" ? -1 : 1;

		if(silent) {
			this.ignore = true;
		}

		if(!this.settings.fullsize) {
			if(x) this.container.scrollLeft += x * dir;
			if(y) this.container.scrollTop += y;
		} else {
			window.scrollBy(x * dir, y * dir);
		}
		this.scrolled = true;
	}

	scrollTo(x, y, silent){
		if(silent) {
			this.ignore = true;
		}

		if(!this.settings.fullsize) {
			this.container.scrollLeft = x;
			this.container.scrollTop = y;
		} else {
			window.scrollTo(x,y);
		}
		this.scrolled = true;
	}

	onScroll(){
		let scrollTop;
		let scrollLeft;

		if(!this.settings.fullsize) {
			scrollTop = this.container.scrollTop;
			scrollLeft = this.container.scrollLeft;
		} else {
			scrollTop = window.scrollY;
			scrollLeft = window.scrollX;
		}

		this.scrollTop = scrollTop;
		this.scrollLeft = scrollLeft;

		if(!this.ignore) {
			this.emit(EVENTS.MANAGERS.SCROLL, {
				top: scrollTop,
				left: scrollLeft
			});

			clearTimeout(this.afterScrolled);
			this.afterScrolled = setTimeout(function () {
				this.emit(EVENTS.MANAGERS.SCROLLED, {
					top: this.scrollTop,
					left: this.scrollLeft
				});
			}.bind(this), 20);



		} else {
			this.ignore = false;
		}

	}

	bounds() {
		var bounds;

		bounds = this.stage.bounds();

		return bounds;
	}

	applyLayout(layout) {

		this.layout = layout;
		this.updateLayout();
		 // this.manager.layout(this.layout.format);
	}

	updateLayout() {

		if (!this.stage) {
			return;
		}

		this._stageSize = this.stage.size();

		if(!this.isPaginated) {
			this.layout.calculate(this._stageSize.width, this._stageSize.height);
		} else {
			this.layout.calculate(
				this._stageSize.width,
				this._stageSize.height,
				this.settings.gap
			);

			// Set the look ahead offset for what is visible
			this.settings.offset = this.layout.delta;

			// this.stage.addStyleRules("iframe", [{"margin-right" : this.layout.gap + "px"}]);

		}

		// Set the dimensions for views
		this.viewSettings.width = this.layout.width;
		this.viewSettings.height = this.layout.height;

		this.setLayout(this.layout);
	}

	setLayout(layout){

		this.viewSettings.layout = layout;

		this.mapping = new src_mapping(layout.props, this.settings.direction, this.settings.axis);

		if(this.views) {

			this.views.forEach(function(view){
				if (view) {
					view.setLayout(layout);
				}
			});

		}

	}

	updateAxis(axis, forceUpdate){

		if (!this.isPaginated) {
			axis = "vertical";
		}

		if (!forceUpdate && axis === this.settings.axis) {
			return;
		}

		this.settings.axis = axis;

		this.stage && this.stage.axis(axis);

		this.viewSettings.axis = axis;

		if (this.mapping) {
			this.mapping = new src_mapping(this.layout.props, this.settings.direction, this.settings.axis);
		}

		if (this.layout) {
			if (axis === "vertical") {
				this.layout.spread("none");
			} else {
				this.layout.spread(this.layout.settings.spread);
			}
		}
	}

	updateFlow(flow){
		let isPaginated = (flow === "paginated" || flow === "auto");

		this.isPaginated = isPaginated;

		if (flow === "scrolled-doc" ||
				flow === "scrolled-continuous" ||
				flow === "scrolled") {
			this.updateAxis("vertical");
		} else {
			this.updateAxis("horizontal");
		}

		this.viewSettings.flow = flow;

		if (!this.settings.overflow) {
			this.overflow = isPaginated ? "hidden" : "auto";
		} else {
			this.overflow = this.settings.overflow;
		}

		this.stage && this.stage.overflow(this.overflow);

		this.updateLayout();

	}

	getContents(){
		var contents = [];
		if (!this.views) {
			return contents;
		}
		this.views.forEach(function(view){
			const viewContents = view && view.contents;
			if (viewContents) {
				contents.push(viewContents);
			}
		});
		return contents;
	}

	direction(dir="ltr") {
		this.settings.direction = dir;

		this.stage && this.stage.direction(dir);

		this.viewSettings.direction = dir;

		this.updateLayout();
	}

	isRendered() {
		return this.rendered;
	}

	scale(s) {
		if ( s == null ) { s = 1.0; }
		this.settings.scale = s;

		if (this.stage) {
			this.stage.scale(s);
		}
	}
}

//-- Enable binding events to Manager
event_emitter_default()(DefaultViewManager.prototype);

/* harmony default export */ const managers_default = (DefaultViewManager);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/helpers/snap.js




// easing equations from https://github.com/danro/easing-js/blob/master/easing.js
const PI_D2 = (Math.PI / 2);
const EASING_EQUATIONS = {
		easeOutSine: function (pos) {
				return Math.sin(pos * PI_D2);
		},
		easeInOutSine: function (pos) {
				return (-0.5 * (Math.cos(Math.PI * pos) - 1));
		},
		easeInOutQuint: function (pos) {
				if ((pos /= 0.5) < 1) {
						return 0.5 * Math.pow(pos, 5);
				}
				return 0.5 * (Math.pow((pos - 2), 5) + 2);
		},
		easeInCubic: function(pos) {
			return Math.pow(pos, 3);
  	}
};

class Snap {
	constructor(manager, options) {

		this.settings = (0,core.extend)({
			duration: 80,
			minVelocity: 0.2,
			minDistance: 10,
			easing: EASING_EQUATIONS['easeInCubic']
		}, options || {});

		this.supportsTouch = this.supportsTouch();

		if (this.supportsTouch) {
			this.setup(manager);
		}
	}

	setup(manager) {
		this.manager = manager;

		this.layout = this.manager.layout;

		this.fullsize = this.manager.settings.fullsize;
		if (this.fullsize) {
			this.element = this.manager.stage.element;
			this.scroller = window;
			this.disableScroll();
		} else {
			this.element = this.manager.stage.container;
			this.scroller = this.element;
			this.element.style["WebkitOverflowScrolling"] = "touch";
		}

		// this.overflow = this.manager.overflow;

		// set lookahead offset to page width
		this.manager.settings.offset = this.layout.width;
		this.manager.settings.afterScrolledTimeout = this.settings.duration * 2;

		this.isVertical = this.manager.settings.axis === "vertical";

		// disable snapping if not paginated or axis in not horizontal
		if (!this.manager.isPaginated || this.isVertical) {
			return;
		}

		this.touchCanceler = false;
		this.resizeCanceler = false;
		this.snapping = false;


		this.scrollLeft;
		this.scrollTop;

		this.startTouchX = undefined;
		this.startTouchY = undefined;
		this.startTime = undefined;
		this.endTouchX = undefined;
		this.endTouchY = undefined;
		this.endTime = undefined;

		this.addListeners();
	}

	supportsTouch() {
		if (('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch) {
			return true;
		}

		return false;
	}

	disableScroll() {
		this.element.style.overflow = "hidden";
	}

	enableScroll() {
		this.element.style.overflow = "";
	}

	addListeners() {
		this._onResize = this.onResize.bind(this);
		window.addEventListener('resize', this._onResize);

		this._onScroll = this.onScroll.bind(this);
		this.scroller.addEventListener('scroll', this._onScroll);

		this._onTouchStart = this.onTouchStart.bind(this);
		this.scroller.addEventListener('touchstart', this._onTouchStart, { passive: true });
		this.on('touchstart', this._onTouchStart);

		this._onTouchMove = this.onTouchMove.bind(this);
		this.scroller.addEventListener('touchmove', this._onTouchMove, { passive: true });
		this.on('touchmove', this._onTouchMove);

		this._onTouchEnd = this.onTouchEnd.bind(this);
		this.scroller.addEventListener('touchend', this._onTouchEnd, { passive: true });
		this.on('touchend', this._onTouchEnd);

		this._afterDisplayed = this.afterDisplayed.bind(this);
		this.manager.on(EVENTS.MANAGERS.ADDED, this._afterDisplayed);
	}

	removeListeners() {
		window.removeEventListener('resize', this._onResize);
		this._onResize = undefined;

		this.scroller.removeEventListener('scroll', this._onScroll);
		this._onScroll = undefined;

		this.scroller.removeEventListener('touchstart', this._onTouchStart, { passive: true });
		this.off('touchstart', this._onTouchStart);
		this._onTouchStart = undefined;

		this.scroller.removeEventListener('touchmove', this._onTouchMove, { passive: true });
		this.off('touchmove', this._onTouchMove);
		this._onTouchMove = undefined;

		this.scroller.removeEventListener('touchend', this._onTouchEnd, { passive: true });
		this.off('touchend', this._onTouchEnd);
		this._onTouchEnd = undefined;

		this.manager.off(EVENTS.MANAGERS.ADDED, this._afterDisplayed);
		this._afterDisplayed = undefined;
	}

	afterDisplayed(view) {
		let contents = view.contents;
		["touchstart", "touchmove", "touchend"].forEach((e) => {
			contents.on(e, (ev) => this.triggerViewEvent(ev, contents));
		});
	}

	triggerViewEvent(e, contents){
		this.emit(e.type, e, contents);
	}

	onScroll(e) {
		this.scrollLeft = this.fullsize ? window.scrollX : this.scroller.scrollLeft;
		this.scrollTop = this.fullsize ? window.scrollY : this.scroller.scrollTop;
	}

	onResize(e) {
		this.resizeCanceler = true;
	}

	onTouchStart(e) {
		let { screenX, screenY } = e.touches[0];

		if (this.fullsize) {
			this.enableScroll();
		}

		this.touchCanceler = true;

		if (!this.startTouchX) {
			this.startTouchX = screenX;
			this.startTouchY = screenY;
			this.startTime = this.now();
		}

		this.endTouchX = screenX;
		this.endTouchY = screenY;
		this.endTime = this.now();
	}

	onTouchMove(e) {
		let { screenX, screenY } = e.touches[0];
		let deltaY = Math.abs(screenY - this.endTouchY);

		this.touchCanceler = true;


		if (!this.fullsize && deltaY < 10) {
			this.element.scrollLeft -= screenX - this.endTouchX;
		}

		this.endTouchX = screenX;
		this.endTouchY = screenY;
		this.endTime = this.now();
	}

	onTouchEnd(e) {
		if (this.fullsize) {
			this.disableScroll();
		}

		this.touchCanceler = false;

		let swipped = this.wasSwiped();

		if (swipped !== 0) {
			this.snap(swipped);
		} else {
			this.snap();
		}

		this.startTouchX = undefined;
		this.startTouchY = undefined;
		this.startTime = undefined;
		this.endTouchX = undefined;
		this.endTouchY = undefined;
		this.endTime = undefined;
	}

	wasSwiped() {
		let snapWidth = this.layout.pageWidth * this.layout.divisor;
		let distance = (this.endTouchX - this.startTouchX);
		let absolute = Math.abs(distance);
		let time = this.endTime - this.startTime;
		let velocity = (distance / time);
		let minVelocity = this.settings.minVelocity;

		if (absolute <= this.settings.minDistance || absolute >= snapWidth) {
			return 0;
		}

		if (velocity > minVelocity) {
			// previous
			return -1;
		} else if (velocity < -minVelocity) {
			// next
			return 1;
		}
	}

	needsSnap() {
		let left = this.scrollLeft;
		let snapWidth = this.layout.pageWidth * this.layout.divisor;
		return (left % snapWidth) !== 0;
	}

	snap(howMany=0) {
		let left = this.scrollLeft;
		let snapWidth = this.layout.pageWidth * this.layout.divisor;
		let snapTo = Math.round(left / snapWidth) * snapWidth;

		if (howMany) {
			snapTo += (howMany * snapWidth);
		}

		return this.smoothScrollTo(snapTo);
	}

	smoothScrollTo(destination) {
		const deferred = new core.defer();
		const start = this.scrollLeft;
		const startTime = this.now();

		const duration = this.settings.duration;
		const easing = this.settings.easing;

		this.snapping = true;

		// add animation loop
		function tick() {
			const now = this.now();
			const time = Math.min(1, ((now - startTime) / duration));
			const timeFunction = easing(time);


			if (this.touchCanceler || this.resizeCanceler) {
				this.resizeCanceler = false;
				this.snapping = false;
				deferred.resolve();
				return;
			}

			if (time < 1) {
					window.requestAnimationFrame(tick.bind(this));
					this.scrollTo(start + ((destination - start) * time), 0);
			} else {
					this.scrollTo(destination, 0);
					this.snapping = false;
					deferred.resolve();
			}
		}

		tick.call(this);

		return deferred.promise;
	}

	scrollTo(left=0, top=0) {
		if (this.fullsize) {
			window.scroll(left, top);
		} else {
			this.scroller.scrollLeft = left;
			this.scroller.scrollTop = top;
		}
	}

	now() {
		return ('now' in window.performance) ? performance.now() : new Date().getTime();
	}

	destroy() {
		if (!this.scroller) {
			return;
		}

		if (this.fullsize) {
			this.enableScroll();
		}

		this.removeListeners();

		this.scroller = undefined;
	}
}

event_emitter_default()(Snap.prototype);

/* harmony default export */ const snap = (Snap);

// EXTERNAL MODULE: ./node_modules/lodash/debounce.js
var debounce = __webpack_require__(3279);
var debounce_default = /*#__PURE__*/__webpack_require__.n(debounce);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/managers/continuous/index.js






class ContinuousViewManager extends managers_default {
	constructor(options) {
		super(options);

		this.name = "continuous";

		this.settings = (0,core.extend)(this.settings || {}, {
			infinite: true,
			overflow: undefined,
			axis: undefined,
			flow: "scrolled",
			offset: 500,
			offsetDelta: 250,
			width: undefined,
			height: undefined,
			snap: false,
			afterScrolledTimeout: 10
		});

		(0,core.extend)(this.settings, options.settings || {});

		// Gap can be 0, but defaults doesn't handle that
		if (options.settings.gap != "undefined" && options.settings.gap === 0) {
			this.settings.gap = options.settings.gap;
		}

		this.viewSettings = {
			ignoreClass: this.settings.ignoreClass,
			axis: this.settings.axis,
			flow: this.settings.flow,
			layout: this.layout,
			width: 0,
			height: 0,
			forceEvenPages: false
		};

		this.scrollTop = 0;
		this.scrollLeft = 0;
	}

	display(section, target){
		return managers_default.prototype.display.call(this, section, target)
			.then(function () {
				return this.fill();
			}.bind(this));
	}

	fill(_full){
		var full = _full || new core.defer();

		this.q.enqueue(() => {
			return this.check();
		}).then((result) => {
			if (result) {
				this.fill(full);
			} else {
				full.resolve();
			}
		});

		return full.promise;
	}

	moveTo(offset){
		// var bounds = this.stage.bounds();
		// var dist = Math.floor(offset.top / bounds.height) * bounds.height;
		var distX = 0,
				distY = 0;

		var offsetX = 0,
				offsetY = 0;

		if(!this.isPaginated) {
			distY = offset.top;
			offsetY = offset.top+this.settings.offsetDelta;
		} else {
			distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;
			offsetX = distX+this.settings.offsetDelta;
		}

		if (distX > 0 || distY > 0) {
			this.scrollBy(distX, distY, true);
		}
	}

	afterResized(view){
		this.emit(EVENTS.MANAGERS.RESIZE, view.section);
	}

	// Remove Previous Listeners if present
	removeShownListeners(view){

		// view.off("shown", this.afterDisplayed);
		// view.off("shown", this.afterDisplayedAbove);
		view.onDisplayed = function(){};

	}

	add(section){
		var view = this.createView(section);

		this.views.append(view);

		view.on(EVENTS.VIEWS.RESIZED, (bounds) => {
			view.expanded = true;
		});

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		// view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));
		view.onDisplayed = this.afterDisplayed.bind(this);
		view.onResize = this.afterResized.bind(this);

		return view.display(this.request);
	}

	append(section){
		var view = this.createView(section);

		view.on(EVENTS.VIEWS.RESIZED, (bounds) => {
			view.expanded = true;
		});

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		this.views.append(view);

		view.onDisplayed = this.afterDisplayed.bind(this);

		return view;
	}

	prepend(section){
		var view = this.createView(section);

		view.on(EVENTS.VIEWS.RESIZED, (bounds) => {
			this.counter(bounds);
			view.expanded = true;
		});

		view.on(EVENTS.VIEWS.AXIS, (axis) => {
			this.updateAxis(axis);
		});

		this.views.prepend(view);

		view.onDisplayed = this.afterDisplayed.bind(this);

		return view;
	}

	counter(bounds){
		if(this.settings.axis === "vertical") {
			this.scrollBy(0, bounds.heightDelta, true);
		} else {
			this.scrollBy(bounds.widthDelta, 0, true);
		}

	}

	update(_offset){
		var container = this.bounds();
		var views = this.views.all();
		var viewsLength = views.length;
		var visible = [];
		var offset = typeof _offset != "undefined" ? _offset : (this.settings.offset || 0);
		var isVisible;
		var view;

		var updating = new core.defer();
		var promises = [];
		for (var i = 0; i < viewsLength; i++) {
			view = views[i];

			isVisible = this.isVisible(view, offset, offset, container);

			if(isVisible === true) {
				// console.log("visible " + view.index);

				if (!view.displayed) {
					let displayed = view.display(this.request)
						.then(function (view) {
							view.show();
						}, (err) => {
							view.hide();
						});
					promises.push(displayed);
				} else {
					view.show();
				}
				visible.push(view);
			} else {
				this.q.enqueue(view.destroy.bind(view));
				// console.log("hidden " + view.index);

				clearTimeout(this.trimTimeout);
				this.trimTimeout = setTimeout(function(){
					this.q.enqueue(this.trim.bind(this));
				}.bind(this), 250);
			}

		}

		if(promises.length){
			return Promise.all(promises)
				.catch((err) => {
					updating.reject(err);
				});
		} else {
			updating.resolve();
			return updating.promise;
		}

	}

	check(_offsetLeft, _offsetTop){
		var checking = new core.defer();
		var newViews = [];

		var horizontal = (this.settings.axis === "horizontal");
		var delta = this.settings.offset || 0;

		if (_offsetLeft && horizontal) {
			delta = _offsetLeft;
		}

		if (_offsetTop && !horizontal) {
			delta = _offsetTop;
		}

		var bounds = this._bounds; // bounds saved this until resize

		let rtl = this.settings.direction === "rtl";
		let dir = horizontal && rtl ? -1 : 1; //RTL reverses scrollTop

		var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
		var visibleLength = horizontal ? Math.floor(bounds.width) : bounds.height;
		var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

		let prepend = () => {
			let first = this.views.first();
			let prev = first && first.section.prev();

			if(prev) {
				newViews.push(this.prepend(prev));
			}
		};

		let append = () => {
			let last = this.views.last();
			let next = last && last.section.next();

			if(next) {
				newViews.push(this.append(next));
			}

		};

		if (offset + visibleLength + delta >= contentLength) {
			if (horizontal && rtl) {
				prepend();
			} else {
				append();
			}
		}

		if (offset - delta < 0 ) {
			if (horizontal && rtl) {
				append();
			} else {
				prepend();
			}
		}

		let promises = newViews.map((view) => {
			return view.displayed;
		});

		if(newViews.length){
			return Promise.all(promises)
				.then(() => {
					if (this.layout.name === "pre-paginated" && this.layout.props.spread) {
						return this.check();
					}
				})
				.then(() => {
					// Check to see if anything new is on screen after rendering
					return this.update(delta);
				}, (err) => {
					return err;
				});
		} else {
			this.q.enqueue(function(){
				this.update();
			}.bind(this));
			checking.resolve(false);
			return checking.promise;
		}


	}

	trim(){
		var task = new core.defer();
		var displayed = this.views.displayed();
		var first = displayed[0];
		var last = displayed[displayed.length-1];
		var firstIndex = this.views.indexOf(first);
		var lastIndex = this.views.indexOf(last);
		var above = this.views.slice(0, firstIndex);
		var below = this.views.slice(lastIndex+1);

		// Erase all but last above
		for (var i = 0; i < above.length-1; i++) {
			this.erase(above[i], above);
		}

		// Erase all except first below
		for (var j = 1; j < below.length; j++) {
			this.erase(below[j]);
		}

		task.resolve();
		return task.promise;
	}

	erase(view, above){ //Trim

		var prevTop;
		var prevLeft;

		if(!this.settings.fullsize) {
			prevTop = this.container.scrollTop;
			prevLeft = this.container.scrollLeft;
		} else {
			prevTop = window.scrollY;
			prevLeft = window.scrollX;
		}

		var bounds = view.bounds();

		this.views.remove(view);

		if(above) {
			if(this.settings.axis === "vertical") {
				this.scrollTo(0, prevTop - bounds.height, true);
			} else {
				this.scrollTo(prevLeft - Math.floor(bounds.width), 0, true);
			}
		}

	}

	addEventListeners(stage){

		window.addEventListener("unload", function(e){
			this.ignore = true;
			// this.scrollTo(0,0);
			this.destroy();
		}.bind(this));

		this.addScrollListeners();

		if (this.isPaginated && this.settings.snap) {
			this.snapper = new snap(this, this.settings.snap && (typeof this.settings.snap === "object") && this.settings.snap);
		}
	}

	addScrollListeners() {
		var scroller;

		this.tick = core.requestAnimationFrame;

		if(!this.settings.fullsize) {
			this.prevScrollTop = this.container.scrollTop;
			this.prevScrollLeft = this.container.scrollLeft;
		} else {
			this.prevScrollTop = window.scrollY;
			this.prevScrollLeft = window.scrollX;
		}

		this.scrollDeltaVert = 0;
		this.scrollDeltaHorz = 0;

		if(!this.settings.fullsize) {
			scroller = this.container;
			this.scrollTop = this.container.scrollTop;
			this.scrollLeft = this.container.scrollLeft;
		} else {
			scroller = window;
			this.scrollTop = window.scrollY;
			this.scrollLeft = window.scrollX;
		}

		this._onScroll = this.onScroll.bind(this);
		scroller.addEventListener("scroll", this._onScroll);
		this._scrolled = debounce_default()(this.scrolled.bind(this), 30);
		// this.tick.call(window, this.onScroll.bind(this));

		this.didScroll = false;

	}

	removeEventListeners(){
		var scroller;

		if(!this.settings.fullsize) {
			scroller = this.container;
		} else {
			scroller = window;
		}

		scroller.removeEventListener("scroll", this._onScroll);
		this._onScroll = undefined;
	}

	onScroll(){
		let scrollTop;
		let scrollLeft;
		let dir = this.settings.direction === "rtl" ? -1 : 1;

		if(!this.settings.fullsize) {
			scrollTop = this.container.scrollTop;
			scrollLeft = this.container.scrollLeft;
		} else {
			scrollTop = window.scrollY * dir;
			scrollLeft = window.scrollX * dir;
		}

		this.scrollTop = scrollTop;
		this.scrollLeft = scrollLeft;

		if(!this.ignore) {

			this._scrolled();

		} else {
			this.ignore = false;
		}

		this.scrollDeltaVert += Math.abs(scrollTop-this.prevScrollTop);
		this.scrollDeltaHorz += Math.abs(scrollLeft-this.prevScrollLeft);

		this.prevScrollTop = scrollTop;
		this.prevScrollLeft = scrollLeft;

		clearTimeout(this.scrollTimeout);
		this.scrollTimeout = setTimeout(function(){
			this.scrollDeltaVert = 0;
			this.scrollDeltaHorz = 0;
		}.bind(this), 150);

		clearTimeout(this.afterScrolled);

		this.didScroll = false;

	}

	scrolled() {

		this.q.enqueue(function() {
			this.check();
		}.bind(this));

		this.emit(EVENTS.MANAGERS.SCROLL, {
			top: this.scrollTop,
			left: this.scrollLeft
		});

		clearTimeout(this.afterScrolled);
		this.afterScrolled = setTimeout(function () {

			// Don't report scroll if we are about the snap
			if (this.snapper && this.snapper.supportsTouch && this.snapper.needsSnap()) {
				return;
			}

			this.emit(EVENTS.MANAGERS.SCROLLED, {
				top: this.scrollTop,
				left: this.scrollLeft
			});

		}.bind(this), this.settings.afterScrolledTimeout);
	}

	next(){

		let dir = this.settings.direction;
		let delta = this.layout.props.name === "pre-paginated" &&
								this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

		if(!this.views.length) return;

		if(this.isPaginated && this.settings.axis === "horizontal") {

			this.scrollBy(delta, 0, true);

		} else {

			this.scrollBy(0, this.layout.height, true);

		}

		this.q.enqueue(function() {
			this.check();
		}.bind(this));
	}

	prev(){

		let dir = this.settings.direction;
		let delta = this.layout.props.name === "pre-paginated" &&
								this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

		if(!this.views.length) return;

		if(this.isPaginated && this.settings.axis === "horizontal") {

			this.scrollBy(-delta, 0, true);

		} else {

			this.scrollBy(0, -this.layout.height, true);

		}

		this.q.enqueue(function() {
			this.check();
		}.bind(this));
	}

	// updateAxis(axis, forceUpdate){
	//
	// 	super.updateAxis(axis, forceUpdate);
	//
	// 	if (axis === "vertical") {
	// 		this.settings.infinite = true;
	// 	} else {
	// 		this.settings.infinite = false;
	// 	}
	// }

	updateFlow(flow){
		if (this.rendered && this.snapper) {
			this.snapper.destroy();
			this.snapper = undefined;
		}

		super.updateFlow(flow);

		if (this.rendered && this.isPaginated && this.settings.snap) {
			this.snapper = new snap(this, this.settings.snap && (typeof this.settings.snap === "object") && this.settings.snap);
		}
	}

	destroy(){
		super.destroy();

		if (this.snapper) {
			this.snapper.destroy();
		}
	}

}

/* harmony default export */ const continuous = (ContinuousViewManager);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/rendition.js






// import Mapping from "./mapping";





// Default Views


// Default View Managers



/**
 * Displays an Epub as a series of Views for each Section.
 * Requires Manager and View class to handle specifics of rendering
 * the section content.
 * @class
 * @param {Book} book
 * @param {object} [options]
 * @param {number} [options.width]
 * @param {number} [options.height]
 * @param {string} [options.ignoreClass] class for the cfi parser to ignore
 * @param {string | function | object} [options.manager='default']
 * @param {string | function} [options.view='iframe']
 * @param {string} [options.layout] layout to force
 * @param {string} [options.spread] force spread value
 * @param {number} [options.minSpreadWidth] overridden by spread: none (never) / both (always)
 * @param {string} [options.stylesheet] url of stylesheet to be injected
 * @param {boolean} [options.resizeOnOrientationChange] false to disable orientation events
 * @param {string} [options.script] url of script to be injected
 * @param {boolean | object} [options.snap=false] use snap scrolling
 */
class Rendition {
	constructor(book, options) {

		this.settings = (0,core.extend)(this.settings || {}, {
			width: null,
			height: null,
			ignoreClass: "",
			manager: "default",
			view: "iframe",
			flow: null,
			layout: null,
			spread: null,
			minSpreadWidth: 800,
			stylesheet: null,
			resizeOnOrientationChange: true,
			script: null,
			snap: false
		});

		(0,core.extend)(this.settings, options);

		if (typeof(this.settings.manager) === "object") {
			this.manager = this.settings.manager;
		}

		this.book = book;

		/**
		 * Adds Hook methods to the Rendition prototype
		 * @member {object} hooks
		 * @property {Hook} hooks.content
		 * @memberof Rendition
		 */
		this.hooks = {};
		this.hooks.display = new hook(this);
		this.hooks.serialize = new hook(this);
		this.hooks.content = new hook(this);
		this.hooks.unloaded = new hook(this);
		this.hooks.layout = new hook(this);
		this.hooks.render = new hook(this);
		this.hooks.show = new hook(this);

		this.hooks.content.register(this.handleLinks.bind(this));
		this.hooks.content.register(this.passEvents.bind(this));
		this.hooks.content.register(this.adjustImages.bind(this));

		this.injected = {};
		this.injected['identifier'] = this.injectIdentifier.bind(this);
		this.book.spine.hooks.content.register(this.injected['identifier']);

		if (this.settings.stylesheet) {
			this.injected['stylesheet'] = this.injectStylesheet.bind(this);
			this.book.spine.hooks.content.register(this.injected['stylesheet']);
		}

		if (this.settings.script) {
			this.injected['script'] = this.injectScript.bind(this);
			this.book.spine.hooks.content.register(this.injected['script']);
		}

		/**
		 * @member {Themes} themes
		 * @memberof Rendition
		 */
		this.themes = new themes(this);

		/**
		 * @member {Annotations} annotations
		 * @memberof Rendition
		 */
		this.annotations = new annotations(this);

		this.epubcfi = new epubcfi();

		this.q = new queue(this);

		/**
		 * A Rendered Location Range
		 * @typedef location
		 * @type {Object}
		 * @property {object} start
		 * @property {string} start.index
		 * @property {string} start.href
		 * @property {object} start.displayed
		 * @property {EpubCFI} start.cfi
		 * @property {number} start.location
		 * @property {number} start.percentage
		 * @property {number} start.displayed.page
		 * @property {number} start.displayed.total
		 * @property {object} end
		 * @property {string} end.index
		 * @property {string} end.href
		 * @property {object} end.displayed
		 * @property {EpubCFI} end.cfi
		 * @property {number} end.location
		 * @property {number} end.percentage
		 * @property {number} end.displayed.page
		 * @property {number} end.displayed.total
		 * @property {boolean} atStart
		 * @property {boolean} atEnd
		 * @memberof Rendition
		 */
		this.location = undefined;

		// Hold queue until book is opened
		this.q.enqueue(this.book.opened);

		this.starting = new core.defer();
		/**
		 * @member {promise} started returns after the rendition has started
		 * @memberof Rendition
		 */
		this.started = this.starting.promise;
		// Block the queue until rendering is started
		this.q.enqueue(this.start);
	}

	/**
	 * Set the manager function
	 * @param {function} manager
	 */
	setManager(manager) {
		this.manager = manager;
	}

	/**
	 * Require the manager from passed string, or as a class function
	 * @param  {string|object} manager [description]
	 * @return {method}
	 */
	requireManager(manager) {
		var viewManager;

		// If manager is a string, try to load from imported managers
		if (typeof manager === "string" && manager === "default") {
			viewManager = managers_default;
		} else if (typeof manager === "string" && manager === "continuous") {
			viewManager = continuous;
		} else {
			// otherwise, assume we were passed a class function
			viewManager = manager;
		}

		return viewManager;
	}

	/**
	 * Require the view from passed string, or as a class function
	 * @param  {string|object} view
	 * @return {view}
	 */
	requireView(view) {
		var View;

		// If view is a string, try to load from imported views,
		if (typeof view == "string" && view === "iframe") {
			View = iframe;
		} else {
			// otherwise, assume we were passed a class function
			View = view;
		}

		return View;
	}

	/**
	 * Start the rendering
	 * @return {Promise} rendering has started
	 */
	start(){

		if(!this.manager) {
			this.ViewManager = this.requireManager(this.settings.manager);
			this.View = this.requireView(this.settings.view);

			this.manager = new this.ViewManager({
				view: this.View,
				queue: this.q,
				request: this.book.load.bind(this.book),
				settings: this.settings
			});
		}

		this.direction(this.book.package.metadata.direction);

		// Parse metadata to get layout props
		this.settings.globalLayoutProperties = this.determineLayoutProperties(this.book.package.metadata);

		this.flow(this.settings.globalLayoutProperties.flow);

		this.layout(this.settings.globalLayoutProperties);

		// Listen for displayed views
		this.manager.on(EVENTS.MANAGERS.ADDED, this.afterDisplayed.bind(this));
		this.manager.on(EVENTS.MANAGERS.REMOVED, this.afterRemoved.bind(this));

		// Listen for resizing
		this.manager.on(EVENTS.MANAGERS.RESIZED, this.onResized.bind(this));

		// Listen for rotation
		this.manager.on(EVENTS.MANAGERS.ORIENTATION_CHANGE, this.onOrientationChange.bind(this));

		// Listen for scroll changes
		this.manager.on(EVENTS.MANAGERS.SCROLLED, this.reportLocation.bind(this));

		/**
		 * Emit that rendering has started
		 * @event started
		 * @memberof Rendition
		 */
		this.emit(EVENTS.RENDITION.STARTED);

		// Start processing queue
		this.starting.resolve();
	}

	/**
	 * Call to attach the container to an element in the dom
	 * Container must be attached before rendering can begin
	 * @param  {element} element to attach to
	 * @return {Promise}
	 */
	attachTo(element){

		return this.q.enqueue(function () {

			// Start rendering
			this.manager.render(element, {
				"width"  : this.settings.width,
				"height" : this.settings.height
			});

			/**
			 * Emit that rendering has attached to an element
			 * @event attached
			 * @memberof Rendition
			 */
			this.emit(EVENTS.RENDITION.ATTACHED);

		}.bind(this));

	}

	/**
	 * Display a point in the book
	 * The request will be added to the rendering Queue,
	 * so it will wait until book is opened, rendering started
	 * and all other rendering tasks have finished to be called.
	 * @param  {string} target Url or EpubCFI
	 * @return {Promise}
	 */
	display(target){
		if (this.displaying) {
			this.displaying.resolve();
		}
		return this.q.enqueue(this._display, target);
	}

	/**
	 * Tells the manager what to display immediately
	 * @private
	 * @param  {string} target Url or EpubCFI
	 * @return {Promise}
	 */
	_display(target){
		if (!this.book) {
			return;
		}
		var isCfiString = this.epubcfi.isCfiString(target);
		var displaying = new core.defer();
		var displayed = displaying.promise;
		var section;
		var moveTo;

		this.displaying = displaying;

		// Check if this is a book percentage
		if (this.book.locations.length() && (0,core.isFloat)(target)) {
			target = this.book.locations.cfiFromPercentage(parseFloat(target));
		}

		section = this.book.spine.get(target);

		if(!section){
			displaying.reject(new Error("No Section Found"));
			return displayed;
		}

		this.manager.display(section, target)
			.then(() => {
				displaying.resolve(section);
				this.displaying = undefined;

				/**
				 * Emit that a section has been displayed
				 * @event displayed
				 * @param {Section} section
				 * @memberof Rendition
				 */
				this.emit(EVENTS.RENDITION.DISPLAYED, section);
				this.reportLocation();
			}, (err) => {
				/**
				 * Emit that has been an error displaying
				 * @event displayError
				 * @param {Section} section
				 * @memberof Rendition
				 */
				this.emit(EVENTS.RENDITION.DISPLAY_ERROR, err);
			});

		return displayed;
	}

	/*
	render(view, show) {

		// view.onLayout = this.layout.format.bind(this.layout);
		view.create();

		// Fit to size of the container, apply padding
		this.manager.resizeView(view);

		// Render Chain
		return view.section.render(this.book.request)
			.then(function(contents){
				return view.load(contents);
			}.bind(this))
			.then(function(doc){
				return this.hooks.content.trigger(view, this);
			}.bind(this))
			.then(function(){
				this.layout.format(view.contents);
				return this.hooks.layout.trigger(view, this);
			}.bind(this))
			.then(function(){
				return view.display();
			}.bind(this))
			.then(function(){
				return this.hooks.render.trigger(view, this);
			}.bind(this))
			.then(function(){
				if(show !== false) {
					this.q.enqueue(function(view){
						view.show();
					}, view);
				}
				// this.map = new Map(view, this.layout);
				this.hooks.show.trigger(view, this);
				this.trigger("rendered", view.section);

			}.bind(this))
			.catch(function(e){
				this.trigger("loaderror", e);
			}.bind(this));

	}
	*/

	/**
	 * Report what section has been displayed
	 * @private
	 * @param  {*} view
	 */
	afterDisplayed(view){

		view.on(EVENTS.VIEWS.MARK_CLICKED, (cfiRange, data) => this.triggerMarkEvent(cfiRange, data, view));

		this.hooks.render.trigger(view, this)
			.then(() => {
				if (view.contents) {
					this.hooks.content.trigger(view.contents, this).then(() => {
						/**
						 * Emit that a section has been rendered
						 * @event rendered
						 * @param {Section} section
						 * @param {View} view
						 * @memberof Rendition
						 */
						this.emit(EVENTS.RENDITION.RENDERED, view.section, view);
					});
				} else {
					this.emit(EVENTS.RENDITION.RENDERED, view.section, view);
				}
			});

	}

	/**
	 * Report what has been removed
	 * @private
	 * @param  {*} view
	 */
	afterRemoved(view){
		this.hooks.unloaded.trigger(view, this).then(() => {
			/**
			 * Emit that a section has been removed
			 * @event removed
			 * @param {Section} section
			 * @param {View} view
			 * @memberof Rendition
			 */
			this.emit(EVENTS.RENDITION.REMOVED, view.section, view);
		});
	}

	/**
	 * Report resize events and display the last seen location
	 * @private
	 */
	onResized(size){

		/**
		 * Emit that the rendition has been resized
		 * @event resized
		 * @param {number} width
		 * @param {height} height
		 * @memberof Rendition
		 */
		this.emit(EVENTS.RENDITION.RESIZED, {
			width: size.width,
			height: size.height
		});

		if (this.location && this.location.start) {
			this.display(this.location.start.cfi);
		}

	}

	/**
	 * Report orientation events and display the last seen location
	 * @private
	 */
	onOrientationChange(orientation){
		/**
		 * Emit that the rendition has been rotated
		 * @event orientationchange
		 * @param {string} orientation
		 * @memberof Rendition
		 */
		this.emit(EVENTS.RENDITION.ORIENTATION_CHANGE, orientation);
	}

	/**
	 * Move the Rendition to a specific offset
	 * Usually you would be better off calling display()
	 * @param {object} offset
	 */
	moveTo(offset){
		this.manager.moveTo(offset);
	}

	/**
	 * Trigger a resize of the views
	 * @param {number} [width]
	 * @param {number} [height]
	 */
	resize(width, height){
		if (width) {
			this.settings.width = width;
		}
		if (height) {
			this.settings.height = height;
		}
		this.manager.resize(width, height);
	}

	/**
	 * Clear all rendered views
	 */
	clear(){
		this.manager.clear();
	}

	/**
	 * Go to the next "page" in the rendition
	 * @return {Promise}
	 */
	next(){
		return this.q.enqueue(this.manager.next.bind(this.manager))
			.then(this.reportLocation.bind(this));
	}

	/**
	 * Go to the previous "page" in the rendition
	 * @return {Promise}
	 */
	prev(){
		return this.q.enqueue(this.manager.prev.bind(this.manager))
			.then(this.reportLocation.bind(this));
	}

	//-- http://www.idpf.org/epub/301/spec/epub-publications.html#meta-properties-rendering
	/**
	 * Determine the Layout properties from metadata and settings
	 * @private
	 * @param  {object} metadata
	 * @return {object} properties
	 */
	determineLayoutProperties(metadata){
		var properties;
		var layout = this.settings.layout || metadata.layout || "reflowable";
		var spread = this.settings.spread || metadata.spread || "auto";
		var orientation = this.settings.orientation || metadata.orientation || "auto";
		var flow = this.settings.flow || metadata.flow || "auto";
		var viewport = metadata.viewport || "";
		var minSpreadWidth = this.settings.minSpreadWidth || metadata.minSpreadWidth || 800;
		var direction = this.settings.direction || metadata.direction || "ltr";

		if ((this.settings.width === 0 || this.settings.width > 0) &&
				(this.settings.height === 0 || this.settings.height > 0)) {
			// viewport = "width="+this.settings.width+", height="+this.settings.height+"";
		}

		properties = {
			layout : layout,
			spread : spread,
			orientation : orientation,
			flow : flow,
			viewport : viewport,
			minSpreadWidth : minSpreadWidth,
			direction: direction
		};

		return properties;
	}

	/**
	 * Adjust the flow of the rendition to paginated or scrolled
	 * (scrolled-continuous vs scrolled-doc are handled by different view managers)
	 * @param  {string} flow
	 */
	flow(flow){
		var _flow = flow;
		if (flow === "scrolled" ||
				flow === "scrolled-doc" ||
				flow === "scrolled-continuous") {
			_flow = "scrolled";
		}

		if (flow === "auto" || flow === "paginated") {
			_flow = "paginated";
		}

		this.settings.flow = flow;

		if (this._layout) {
			this._layout.flow(_flow);
		}

		if (this.manager && this._layout) {
			this.manager.applyLayout(this._layout);
		}

		if (this.manager) {
			this.manager.updateFlow(_flow);
		}

		if (this.manager && this.manager.isRendered() && this.location) {
			this.manager.clear();
			this.display(this.location.start.cfi);
		}
	}

	/**
	 * Adjust the layout of the rendition to reflowable or pre-paginated
	 * @param  {object} settings
	 */
	layout(settings){
		if (settings) {
			this._layout = new layout(settings);
			this._layout.spread(settings.spread, this.settings.minSpreadWidth);

			// this.mapping = new Mapping(this._layout.props);

			this._layout.on(EVENTS.LAYOUT.UPDATED, (props, changed) => {
				this.emit(EVENTS.RENDITION.LAYOUT, props, changed);
			})
		}

		if (this.manager && this._layout) {
			this.manager.applyLayout(this._layout);
		}

		return this._layout;
	}

	/**
	 * Adjust if the rendition uses spreads
	 * @param  {string} spread none | auto (TODO: implement landscape, portrait, both)
	 * @param  {int} [min] min width to use spreads at
	 */
	spread(spread, min){

		this.settings.spread = spread;

		if (min) {
			this.settings.minSpreadWidth = min;
		}

		if (this._layout) {
			this._layout.spread(spread, min);
		}

		if (this.manager && this.manager.isRendered()) {
			this.manager.updateLayout();
		}
	}

	/**
	 * Adjust the direction of the rendition
	 * @param  {string} dir
	 */
	direction(dir){

		this.settings.direction = dir || "ltr";

		if (this.manager) {
			this.manager.direction(this.settings.direction);
		}

		if (this.manager && this.manager.isRendered() && this.location) {
			this.manager.clear();
			this.display(this.location.start.cfi);
		}
	}

	/**
	 * Report the current location
	 * @fires relocated
	 * @fires locationChanged
	 */
	reportLocation(){
		return this.q.enqueue(function reportedLocation(){
			requestAnimationFrame(function reportedLocationAfterRAF() {
				var location = this.manager.currentLocation();
				if (location && location.then && typeof location.then === "function") {
					location.then(function(result) {
						let located = this.located(result);

						if (!located || !located.start || !located.end) {
							return;
						}

						this.location = located;

						this.emit(EVENTS.RENDITION.LOCATION_CHANGED, {
							index: this.location.start.index,
							href: this.location.start.href,
							start: this.location.start.cfi,
							end: this.location.end.cfi,
							percentage: this.location.start.percentage
						});

						this.emit(EVENTS.RENDITION.RELOCATED, this.location);
					}.bind(this));
				} else if (location) {
					let located = this.located(location);

					if (!located || !located.start || !located.end) {
						return;
					}

					this.location = located;

					/**
					 * @event locationChanged
					 * @deprecated
					 * @type {object}
					 * @property {number} index
					 * @property {string} href
					 * @property {EpubCFI} start
					 * @property {EpubCFI} end
					 * @property {number} percentage
					 * @memberof Rendition
					 */
					this.emit(EVENTS.RENDITION.LOCATION_CHANGED, {
						index: this.location.start.index,
						href: this.location.start.href,
						start: this.location.start.cfi,
						end: this.location.end.cfi,
						percentage: this.location.start.percentage
					});

					/**
					 * @event relocated
					 * @type {displayedLocation}
					 * @memberof Rendition
					 */
					this.emit(EVENTS.RENDITION.RELOCATED, this.location);
				}
			}.bind(this));
		}.bind(this));
	}

	/**
	 * Get the Current Location object
	 * @return {displayedLocation | promise} location (may be a promise)
	 */
	currentLocation(){
		var location = this.manager.currentLocation();
		if (location && location.then && typeof location.then === "function") {
			location.then(function(result) {
				let located = this.located(result);
				return located;
			}.bind(this));
		} else if (location) {
			let located = this.located(location);
			return located;
		}
	}

	/**
	 * Creates a Rendition#locationRange from location
	 * passed by the Manager
	 * @returns {displayedLocation}
	 * @private
	 */
	located(location){
		if (!location.length) {
			return {};
		}
		let start = location[0];
		let end = location[location.length-1];

		let located = {
			start: {
				index: start.index,
				href: start.href,
				cfi: start.mapping.start,
				displayed: {
					page: start.pages[0] || 1,
					total: start.totalPages
				}
			},
			end: {
				index: end.index,
				href: end.href,
				cfi: end.mapping.end,
				displayed: {
					page: end.pages[end.pages.length-1] || 1,
					total: end.totalPages
				}
			}
		};

		let locationStart = this.book.locations.locationFromCfi(start.mapping.start);
		let locationEnd = this.book.locations.locationFromCfi(end.mapping.end);

		if (locationStart != null) {
			located.start.location = locationStart;
			located.start.percentage = this.book.locations.percentageFromLocation(locationStart);
		}
		if (locationEnd != null) {
			located.end.location = locationEnd;
			located.end.percentage = this.book.locations.percentageFromLocation(locationEnd);
		}

		let pageStart = this.book.pageList.pageFromCfi(start.mapping.start);
		let pageEnd = this.book.pageList.pageFromCfi(end.mapping.end);

		if (pageStart != -1) {
			located.start.page = pageStart;
		}
		if (pageEnd != -1) {
			located.end.page = pageEnd;
		}

		if (end.index === this.book.spine.last().index &&
				located.end.displayed.page >= located.end.displayed.total) {
			located.atEnd = true;
		}

		if (start.index === this.book.spine.first().index &&
				located.start.displayed.page === 1) {
			located.atStart = true;
		}

		return located;
	}

	/**
	 * Remove and Clean Up the Rendition
	 */
	destroy(){
		// Clear the queue
		// this.q.clear();
		// this.q = undefined;

		this.manager && this.manager.destroy();
		this.book.spine.hooks.content.deregister(this.injected['identifier']);
		this.book.spine.hooks.content.deregister(this.injected['script']);
		this.book.spine.hooks.content.deregister(this.injected['stylesheet']);

		this.book = undefined;

		// this.views = null;

		// this.hooks.display.clear();
		// this.hooks.serialize.clear();
		// this.hooks.content.clear();
		// this.hooks.layout.clear();
		// this.hooks.render.clear();
		// this.hooks.show.clear();
		// this.hooks = {};

		// this.themes.destroy();
		// this.themes = undefined;

		// this.epubcfi = undefined;

		// this.starting = undefined;
		// this.started = undefined;


	}

	/**
	 * Pass the events from a view's Contents
	 * @private
	 * @param  {Contents} view contents
	 */
	passEvents(contents){
		DOM_EVENTS.forEach((e) => {
			contents.on(e, (ev) => this.triggerViewEvent(ev, contents));
		});

		contents.on(EVENTS.CONTENTS.SELECTED, (e) => this.triggerSelectedEvent(e, contents));
	}

	/**
	 * Emit events passed by a view
	 * @private
	 * @param  {event} e
	 */
	triggerViewEvent(e, contents){
		this.emit(e.type, e, contents);
	}

	/**
	 * Emit a selection event's CFI Range passed from a a view
	 * @private
	 * @param  {EpubCFI} cfirange
	 */
	triggerSelectedEvent(cfirange, contents){
		/**
		 * Emit that a text selection has occured
		 * @event selected
		 * @param {EpubCFI} cfirange
		 * @param {Contents} contents
		 * @memberof Rendition
		 */
		this.emit(EVENTS.RENDITION.SELECTED, cfirange, contents);
	}

	/**
	 * Emit a markClicked event with the cfiRange and data from a mark
	 * @private
	 * @param  {EpubCFI} cfirange
	 */
	triggerMarkEvent(cfiRange, data, contents){
		/**
		 * Emit that a mark was clicked
		 * @event markClicked
		 * @param {EpubCFI} cfirange
		 * @param {object} data
		 * @param {Contents} contents
		 * @memberof Rendition
		 */
		this.emit(EVENTS.RENDITION.MARK_CLICKED, cfiRange, data, contents);
	}

	/**
	 * Get a Range from a Visible CFI
	 * @param  {string} cfi EpubCfi String
	 * @param  {string} ignoreClass
	 * @return {range}
	 */
	getRange(cfi, ignoreClass){
		var _cfi = new epubcfi(cfi);
		var found = this.manager.visible().filter(function (view) {
			if(_cfi.spinePos === view.index) return true;
		});

		// Should only every return 1 item
		if (found.length) {
			return found[0].contents.range(_cfi, ignoreClass);
		}
	}

	/**
	 * Hook to adjust images to fit in columns
	 * @param  {Contents} contents
	 * @private
	 */
	adjustImages(contents) {

		if (this._layout.name === "pre-paginated") {
			return new Promise(function(resolve){
				resolve();
			});
		}

		let computed = contents.window.getComputedStyle(contents.content, null);
		let height = (contents.content.offsetHeight - (parseFloat(computed.paddingTop) + parseFloat(computed.paddingBottom))) * .95;
		let verticalPadding = parseFloat(computed.verticalPadding);

		contents.addStylesheetRules({
			"img" : {
				"max-width": (this._layout.columnWidth ? (this._layout.columnWidth - verticalPadding) + "px" : "100%") + "!important",
				"max-height": height + "px" + "!important",
				"object-fit": "contain",
				"page-break-inside": "avoid",
				"break-inside": "avoid",
				"box-sizing": "border-box"
			},
			"svg" : {
				"max-width": (this._layout.columnWidth ? (this._layout.columnWidth - verticalPadding) + "px" : "100%") + "!important",
				"max-height": height + "px" + "!important",
				"page-break-inside": "avoid",
				"break-inside": "avoid"
			}
		});

		return new Promise(function(resolve, reject){
			// Wait to apply
			setTimeout(function() {
				resolve();
			}, 1);
		});
	}

	/**
	 * Get the Contents object of each rendered view
	 * @returns {Contents[]}
	 */
	getContents () {
		return this.manager ? this.manager.getContents() : [];
	}

	/**
	 * Get the views member from the manager
	 * @returns {Views}
	 */
	views () {
		let views = this.manager ? this.manager.views : undefined;
		return views || [];
	}

	/**
	 * Hook to handle link clicks in rendered content
	 * @param  {Contents} contents
	 * @private
	 */
	handleLinks(contents) {
		if (contents) {
			contents.on(EVENTS.CONTENTS.LINK_CLICKED, (href) => {
				let relative = this.book.path.relative(href);
				this.display(relative);
			});
		}
	}

	/**
	 * Hook to handle injecting stylesheet before
	 * a Section is serialized
	 * @param  {document} doc
	 * @param  {Section} section
	 * @private
	 */
	injectStylesheet(doc, section) {
		let style = doc.createElement("link");
		style.setAttribute("type", "text/css");
		style.setAttribute("rel", "stylesheet");
		style.setAttribute("href", this.settings.stylesheet);
		doc.getElementsByTagName("head")[0].appendChild(style);
	}

	/**
	 * Hook to handle injecting scripts before
	 * a Section is serialized
	 * @param  {document} doc
	 * @param  {Section} section
	 * @private
	 */
	injectScript(doc, section) {
		let script = doc.createElement("script");
		script.setAttribute("type", "text/javascript");
		script.setAttribute("src", this.settings.script);
		script.textContent = " "; // Needed to prevent self closing tag
		doc.getElementsByTagName("head")[0].appendChild(script);
	}

	/**
	 * Hook to handle the document identifier before
	 * a Section is serialized
	 * @param  {document} doc
	 * @param  {Section} section
	 * @private
	 */
	injectIdentifier(doc, section) {
		let ident = this.book.packaging.metadata.identifier;
		let meta = doc.createElement("meta");
		meta.setAttribute("name", "dc.relation.ispartof");
		if (ident) {
			meta.setAttribute("content", ident);
		}
		doc.getElementsByTagName("head")[0].appendChild(meta);
	}

	scale(s) {
		return this.manager && this.manager.scale(s);
	}
}

//-- Enable binding events to Renderer
event_emitter_default()(Rendition.prototype);

/* harmony default export */ const rendition = (Rendition);

// EXTERNAL MODULE: ./node_modules/epubjs/src/utils/request.js
var request = __webpack_require__(5817);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/archive.js





/**
 * Handles Unzipping a requesting files from an Epub Archive
 * @class
 */
class Archive {

	constructor() {
		this.zip = undefined;
		this.urlCache = {};

		this.checkRequirements();

	}

	/**
	 * Checks to see if JSZip exists in global namspace,
	 * Requires JSZip if it isn't there
	 * @private
	 */
	checkRequirements(){
		try {
			if (typeof JSZip === "undefined") {
				let JSZip = __webpack_require__(5733);
				this.zip = new JSZip();
			} else {
				this.zip = new JSZip();
			}
		} catch (e) {
			throw new Error("JSZip lib not loaded");
		}
	}

	/**
	 * Open an archive
	 * @param  {binary} input
	 * @param  {boolean} [isBase64] tells JSZip if the input data is base64 encoded
	 * @return {Promise} zipfile
	 */
	open(input, isBase64){
		return this.zip.loadAsync(input, {"base64": isBase64});
	}

	/**
	 * Load and Open an archive
	 * @param  {string} zipUrl
	 * @param  {boolean} [isBase64] tells JSZip if the input data is base64 encoded
	 * @return {Promise} zipfile
	 */
	openUrl(zipUrl, isBase64){
		return (0,request.default)(zipUrl, "binary")
			.then(function(data){
				return this.zip.loadAsync(data, {"base64": isBase64});
			}.bind(this));
	}

	/**
	 * Request a url from the archive
	 * @param  {string} url  a url to request from the archive
	 * @param  {string} [type] specify the type of the returned result
	 * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	 */
	request(url, type){
		var deferred = new core.defer();
		var response;
		var path = new utils_path/* default */.Z(url);

		// If type isn't set, determine it from the file extension
		if(!type) {
			type = path.extension;
		}

		if(type == "blob"){
			response = this.getBlob(url);
		} else {
			response = this.getText(url);
		}

		if (response) {
			response.then(function (r) {
				let result = this.handleResponse(r, type);
				deferred.resolve(result);
			}.bind(this));
		} else {
			deferred.reject({
				message : "File not found in the epub: " + url,
				stack : new Error().stack
			});
		}
		return deferred.promise;
	}

	/**
	 * Handle the response from request
	 * @private
	 * @param  {any} response
	 * @param  {string} [type]
	 * @return {any} the parsed result
	 */
	handleResponse(response, type){
		var r;

		if(type == "json") {
			r = JSON.parse(response);
		}
		else
		if((0,core.isXml)(type)) {
			r = (0,core.parse)(response, "text/xml");
		}
		else
		if(type == "xhtml") {
			r = (0,core.parse)(response, "application/xhtml+xml");
		}
		else
		if(type == "html" || type == "htm") {
			r = (0,core.parse)(response, "text/html");
		 } else {
			 r = response;
		 }

		return r;
	}

	/**
	 * Get a Blob from Archive by Url
	 * @param  {string} url
	 * @param  {string} [mimeType]
	 * @return {Blob}
	 */
	getBlob(url, mimeType){
		var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
		var entry = this.zip.file(decodededUrl);

		if(entry) {
			mimeType = mimeType || mime_default().lookup(entry.name);
			return entry.async("uint8array").then(function(uint8array) {
				return new Blob([uint8array], {type : mimeType});
			});
		}
	}

	/**
	 * Get Text from Archive by Url
	 * @param  {string} url
	 * @param  {string} [encoding]
	 * @return {string}
	 */
	getText(url, encoding){
		var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
		var entry = this.zip.file(decodededUrl);

		if(entry) {
			return entry.async("string").then(function(text) {
				return text;
			});
		}
	}

	/**
	 * Get a base64 encoded result from Archive by Url
	 * @param  {string} url
	 * @param  {string} [mimeType]
	 * @return {string} base64 encoded
	 */
	getBase64(url, mimeType){
		var decodededUrl = window.decodeURIComponent(url.substr(1)); // Remove first slash
		var entry = this.zip.file(decodededUrl);

		if(entry) {
			mimeType = mimeType || mime_default().lookup(entry.name);
			return entry.async("base64").then(function(data) {
				return "data:" + mimeType + ";base64," + data;
			});
		}
	}

	/**
	 * Create a Url from an unarchived item
	 * @param  {string} url
	 * @param  {object} [options.base64] use base64 encoding or blob url
	 * @return {Promise} url promise with Url string
	 */
	createUrl(url, options){
		var deferred = new core.defer();
		var _URL = window.URL || window.webkitURL || window.mozURL;
		var tempUrl;
		var response;
		var useBase64 = options && options.base64;

		if(url in this.urlCache) {
			deferred.resolve(this.urlCache[url]);
			return deferred.promise;
		}

		if (useBase64) {
			response = this.getBase64(url);

			if (response) {
				response.then(function(tempUrl) {

					this.urlCache[url] = tempUrl;
					deferred.resolve(tempUrl);

				}.bind(this));

			}

		} else {

			response = this.getBlob(url);

			if (response) {
				response.then(function(blob) {

					tempUrl = _URL.createObjectURL(blob);
					this.urlCache[url] = tempUrl;
					deferred.resolve(tempUrl);

				}.bind(this));

			}
		}


		if (!response) {
			deferred.reject({
				message : "File not found in the epub: " + url,
				stack : new Error().stack
			});
		}

		return deferred.promise;
	}

	/**
	 * Revoke Temp Url for a achive item
	 * @param  {string} url url of the item in the archive
	 */
	revokeUrl(url){
		var _URL = window.URL || window.webkitURL || window.mozURL;
		var fromCache = this.urlCache[url];
		if(fromCache) _URL.revokeObjectURL(fromCache);
	}

	destroy() {
		var _URL = window.URL || window.webkitURL || window.mozURL;
		for (let fromCache in this.urlCache) {
			_URL.revokeObjectURL(fromCache);
		}
		this.zip = undefined;
		this.urlCache = {};
	}
}

/* harmony default export */ const archive = (Archive);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/store.js






/**
 * Handles saving and requesting files from local storage
 * @class
 * @param {string} name This should be the name of the application for modals
 * @param {function} [requester]
 * @param {function} [resolver]
 */
class Store {

	constructor(name, requester, resolver) {
		this.urlCache = {};

		this.storage = undefined;

		this.name = name;
		this.requester = requester || request.default;
		this.resolver = resolver;

		this.online = true;

		this.checkRequirements();

		this.addListeners();
	}

	/**
	 * Checks to see if localForage exists in global namspace,
	 * Requires localForage if it isn't there
	 * @private
	 */
	checkRequirements(){
		try {
			let store;
			if (typeof localforage === "undefined") {
				store = __webpack_require__(9483);
			} else {
				store = localforage;
			}
			this.storage = store.createInstance({
					name: this.name
			});
		} catch (e) {
			throw new Error("localForage lib not loaded");
		}
	}

	/**
	 * Add online and offline event listeners
	 * @private
	 */
	addListeners() {
		this._status = this.status.bind(this);
		window.addEventListener('online',  this._status);
	  window.addEventListener('offline', this._status);
	}

	/**
	 * Remove online and offline event listeners
	 * @private
	 */
	removeListeners() {
		window.removeEventListener('online',  this._status);
	  window.removeEventListener('offline', this._status);
		this._status = undefined;
	}

	/**
	 * Update the online / offline status
	 * @private
	 */
	status(event) {
		let online = navigator.onLine;
		this.online = online;
		if (online) {
			this.emit("online", this);
		} else {
			this.emit("offline", this);
		}
	}

	/**
	 * Add all of a book resources to the store
	 * @param  {Resources} resources  book resources
	 * @param  {boolean} [force] force resaving resources
	 * @return {Promise<object>} store objects
	 */
	add(resources, force) {
		let mapped = resources.resources.map((item) => {
			let { href } = item;
			let url = this.resolver(href);
			let encodedUrl = window.encodeURIComponent(url);

			return this.storage.getItem(encodedUrl).then((item) => {
				if (!item || force) {
					return this.requester(url, "binary")
						.then((data) => {
							return this.storage.setItem(encodedUrl, data);
						});
				} else {
					return item;
				}
			});

		});
		return Promise.all(mapped);
	}

	/**
	 * Put binary data from a url to storage
	 * @param  {string} url  a url to request from storage
	 * @param  {boolean} [withCredentials]
	 * @param  {object} [headers]
	 * @return {Promise<Blob>}
	 */
	put(url, withCredentials, headers) {
		let encodedUrl = window.encodeURIComponent(url);

		return this.storage.getItem(encodedUrl).then((result) => {
			if (!result) {
				return this.requester(url, "binary", withCredentials, headers).then((data) => {
					return this.storage.setItem(encodedUrl, data);
				});
			}
			return result;
		});
	}

	/**
	 * Request a url
	 * @param  {string} url  a url to request from storage
	 * @param  {string} [type] specify the type of the returned result
	 * @param  {boolean} [withCredentials]
	 * @param  {object} [headers]
	 * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	 */
	request(url, type, withCredentials, headers){
		if (this.online) {
			// From network
			return this.requester(url, type, withCredentials, headers).then((data) => {
				// save to store if not present
				this.put(url);
				return data;
			})
		} else {
			// From store
			return this.retrieve(url, type);
		}

	}

	/**
	 * Request a url from storage
	 * @param  {string} url  a url to request from storage
	 * @param  {string} [type] specify the type of the returned result
	 * @return {Promise<Blob | string | JSON | Document | XMLDocument>}
	 */
	retrieve(url, type) {
		var deferred = new core.defer();
		var response;
		var path = new utils_path/* default */.Z(url);

		// If type isn't set, determine it from the file extension
		if(!type) {
			type = path.extension;
		}

		if(type == "blob"){
			response = this.getBlob(url);
		} else {
			response = this.getText(url);
		}


		return response.then((r) => {
			var deferred = new core.defer();
			var result;
			if (r) {
				result = this.handleResponse(r, type);
				deferred.resolve(result);
			} else {
				deferred.reject({
					message : "File not found in storage: " + url,
					stack : new Error().stack
				});
			}
			return deferred.promise;
		});
	}

	/**
	 * Handle the response from request
	 * @private
	 * @param  {any} response
	 * @param  {string} [type]
	 * @return {any} the parsed result
	 */
	handleResponse(response, type){
		var r;

		if(type == "json") {
			r = JSON.parse(response);
		}
		else
		if((0,core.isXml)(type)) {
			r = (0,core.parse)(response, "text/xml");
		}
		else
		if(type == "xhtml") {
			r = (0,core.parse)(response, "application/xhtml+xml");
		}
		else
		if(type == "html" || type == "htm") {
			r = (0,core.parse)(response, "text/html");
		 } else {
			 r = response;
		 }

		return r;
	}

	/**
	 * Get a Blob from Storage by Url
	 * @param  {string} url
	 * @param  {string} [mimeType]
	 * @return {Blob}
	 */
	getBlob(url, mimeType){
		let encodedUrl = window.encodeURIComponent(url);

		return this.storage.getItem(encodedUrl).then(function(uint8array) {
			if(!uint8array) return;

			mimeType = mimeType || mime_default().lookup(url);

			return new Blob([uint8array], {type : mimeType});
		});

	}

	/**
	 * Get Text from Storage by Url
	 * @param  {string} url
	 * @param  {string} [mimeType]
	 * @return {string}
	 */
	getText(url, mimeType){
		let encodedUrl = window.encodeURIComponent(url);

		mimeType = mimeType || mime_default().lookup(url);

		return this.storage.getItem(encodedUrl).then(function(uint8array) {
			var deferred = new core.defer();
			var reader = new FileReader();
			var blob;

			if(!uint8array) return;

			blob = new Blob([uint8array], {type : mimeType});

			reader.addEventListener("loadend", () => {
				deferred.resolve(reader.result);
			});

			reader.readAsText(blob, mimeType);

			return deferred.promise;
		});
	}

	/**
	 * Get a base64 encoded result from Storage by Url
	 * @param  {string} url
	 * @param  {string} [mimeType]
	 * @return {string} base64 encoded
	 */
	getBase64(url, mimeType){
		let encodedUrl = window.encodeURIComponent(url);

		mimeType = mimeType || mime_default().lookup(url);

		return this.storage.getItem(encodedUrl).then((uint8array) => {
			var deferred = new core.defer();
			var reader = new FileReader();
			var blob;

			if(!uint8array) return;

			blob = new Blob([uint8array], {type : mimeType});

			reader.addEventListener("loadend", () => {
				deferred.resolve(reader.result);
			});
			reader.readAsDataURL(blob, mimeType);

			return deferred.promise;
		});
	}

	/**
	 * Create a Url from a stored item
	 * @param  {string} url
	 * @param  {object} [options.base64] use base64 encoding or blob url
	 * @return {Promise} url promise with Url string
	 */
	createUrl(url, options){
		var deferred = new core.defer();
		var _URL = window.URL || window.webkitURL || window.mozURL;
		var tempUrl;
		var response;
		var useBase64 = options && options.base64;

		if(url in this.urlCache) {
			deferred.resolve(this.urlCache[url]);
			return deferred.promise;
		}

		if (useBase64) {
			response = this.getBase64(url);

			if (response) {
				response.then(function(tempUrl) {

					this.urlCache[url] = tempUrl;
					deferred.resolve(tempUrl);

				}.bind(this));

			}

		} else {

			response = this.getBlob(url);

			if (response) {
				response.then(function(blob) {

					tempUrl = _URL.createObjectURL(blob);
					this.urlCache[url] = tempUrl;
					deferred.resolve(tempUrl);

				}.bind(this));

			}
		}


		if (!response) {
			deferred.reject({
				message : "File not found in storage: " + url,
				stack : new Error().stack
			});
		}

		return deferred.promise;
	}

	/**
	 * Revoke Temp Url for a achive item
	 * @param  {string} url url of the item in the store
	 */
	revokeUrl(url){
		var _URL = window.URL || window.webkitURL || window.mozURL;
		var fromCache = this.urlCache[url];
		if(fromCache) _URL.revokeObjectURL(fromCache);
	}

	destroy() {
		var _URL = window.URL || window.webkitURL || window.mozURL;
		for (let fromCache in this.urlCache) {
			_URL.revokeObjectURL(fromCache);
		}
		this.urlCache = {};
		this.removeListeners();
	}
}

event_emitter_default()(Store.prototype);

/* harmony default export */ const store = (Store);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/book.js


















const CONTAINER_PATH = "META-INF/container.xml";

const INPUT_TYPE = {
	BINARY: "binary",
	BASE64: "base64",
	EPUB: "epub",
	OPF: "opf",
	MANIFEST: "json",
	DIRECTORY: "directory"
};

/**
 * An Epub representation with methods for the loading, parsing and manipulation
 * of its contents.
 * @class
 * @param {string} [url]
 * @param {object} [options]
 * @param {method} [options.requestMethod] a request function to use instead of the default
 * @param {boolean} [options.requestCredentials=undefined] send the xhr request withCredentials
 * @param {object} [options.requestHeaders=undefined] send the xhr request headers
 * @param {string} [options.encoding=binary] optional to pass 'binary' or base64' for archived Epubs
 * @param {string} [options.replacements=none] use base64, blobUrl, or none for replacing assets in archived Epubs
 * @param {method} [options.canonical] optional function to determine canonical urls for a path
 * @param {string} [options.openAs] optional string to determine the input type
 * @param {string} [options.store=false] cache the contents in local storage, value should be the name of the reader
 * @returns {Book}
 * @example new Book("/path/to/book.epub", {})
 * @example new Book({ replacements: "blobUrl" })
 */
class Book {
	constructor(url, options) {
		// Allow passing just options to the Book
		if (typeof(options) === "undefined" &&
			  typeof(url) !== "string" &&
		    url instanceof Blob === false) {
			options = url;
			url = undefined;
		}

		this.settings = (0,core.extend)(this.settings || {}, {
			requestMethod: undefined,
			requestCredentials: undefined,
			requestHeaders: undefined,
			encoding: undefined,
			replacements: undefined,
			canonical: undefined,
			openAs: undefined,
			store: undefined
		});

		(0,core.extend)(this.settings, options);


		// Promises
		this.opening = new core.defer();
		/**
		 * @member {promise} opened returns after the book is loaded
		 * @memberof Book
		 */
		this.opened = this.opening.promise;
		this.isOpen = false;

		this.loading = {
			manifest: new core.defer(),
			spine: new core.defer(),
			metadata: new core.defer(),
			cover: new core.defer(),
			navigation: new core.defer(),
			pageList: new core.defer(),
			resources: new core.defer()
		};

		this.loaded = {
			manifest: this.loading.manifest.promise,
			spine: this.loading.spine.promise,
			metadata: this.loading.metadata.promise,
			cover: this.loading.cover.promise,
			navigation: this.loading.navigation.promise,
			pageList: this.loading.pageList.promise,
			resources: this.loading.resources.promise
		};

		/**
		 * @member {promise} ready returns after the book is loaded and parsed
		 * @memberof Book
		 * @private
		 */
		this.ready = Promise.all([
			this.loaded.manifest,
			this.loaded.spine,
			this.loaded.metadata,
			this.loaded.cover,
			this.loaded.navigation,
			this.loaded.resources
		]);


		// Queue for methods used before opening
		this.isRendered = false;
		// this._q = queue(this);

		/**
		 * @member {method} request
		 * @memberof Book
		 * @private
		 */
		this.request = this.settings.requestMethod || request.default;

		/**
		 * @member {Spine} spine
		 * @memberof Book
		 */
		this.spine = new spine();

		/**
		 * @member {Locations} locations
		 * @memberof Book
		 */
		this.locations = new locations(this.spine, this.load.bind(this));

		/**
		 * @member {Navigation} navigation
		 * @memberof Book
		 */
		this.navigation = undefined;

		/**
		 * @member {PageList} pagelist
		 * @memberof Book
		 */
		this.pageList = undefined;

		/**
		 * @member {Url} url
		 * @memberof Book
		 * @private
		 */
		this.url = undefined;

		/**
		 * @member {Path} path
		 * @memberof Book
		 * @private
		 */
		this.path = undefined;

		/**
		 * @member {boolean} archived
		 * @memberof Book
		 * @private
		 */
		this.archived = false;

		/**
		 * @member {Archive} archive
		 * @memberof Book
		 * @private
		 */
		this.archive = undefined;

		/**
		 * @member {Store} storage
		 * @memberof Book
		 * @private
		 */
		this.storage = undefined;

		/**
		 * @member {Resources} resources
		 * @memberof Book
		 * @private
		 */
		this.resources = undefined;

		/**
		 * @member {Rendition} rendition
		 * @memberof Book
		 * @private
		 */
		this.rendition = undefined;

		/**
		 * @member {Container} container
		 * @memberof Book
		 * @private
		 */
		this.container = undefined;

		/**
		 * @member {Packaging} packaging
		 * @memberof Book
		 * @private
		 */
		this.packaging = undefined;

		// this.toc = undefined;
		if (this.settings.store) {
			this.store(this.settings.store);
		}

		if(url) {
			this.open(url, this.settings.openAs).catch((error) => {
				var err = new Error("Cannot load book at "+ url );
				this.emit(EVENTS.BOOK.OPEN_FAILED, err);
			});
		}
	}

	/**
	 * Open a epub or url
	 * @param {string | ArrayBuffer} input Url, Path or ArrayBuffer
	 * @param {string} [what="binary", "base64", "epub", "opf", "json", "directory"] force opening as a certain type
	 * @returns {Promise} of when the book has been loaded
	 * @example book.open("/path/to/book.epub")
	 */
	open(input, what) {
		var opening;
		var type = what || this.determineType(input);

		if (type === INPUT_TYPE.BINARY) {
			this.archived = true;
			this.url = new utils_url("/", "");
			opening = this.openEpub(input);
		} else if (type === INPUT_TYPE.BASE64) {
			this.archived = true;
			this.url = new utils_url("/", "");
			opening = this.openEpub(input, type);
		} else if (type === INPUT_TYPE.EPUB) {
			this.archived = true;
			this.url = new utils_url("/", "");
			opening = this.request(input, "binary", this.settings.requestCredentials)
				.then(this.openEpub.bind(this));
		} else if(type == INPUT_TYPE.OPF) {
			this.url = new utils_url(input);
			opening = this.openPackaging(this.url.Path.toString());
		} else if(type == INPUT_TYPE.MANIFEST) {
			this.url = new utils_url(input);
			opening = this.openManifest(this.url.Path.toString());
		} else {
			this.url = new utils_url(input);
			opening = this.openContainer(CONTAINER_PATH)
				.then(this.openPackaging.bind(this));
		}

		return opening;
	}

	/**
	 * Open an archived epub
	 * @private
	 * @param  {binary} data
	 * @param  {string} [encoding]
	 * @return {Promise}
	 */
	openEpub(data, encoding) {
		return this.unarchive(data, encoding || this.settings.encoding)
			.then(() => {
				return this.openContainer(CONTAINER_PATH);
			})
			.then((packagePath) => {
				return this.openPackaging(packagePath);
			});
	}

	/**
	 * Open the epub container
	 * @private
	 * @param  {string} url
	 * @return {string} packagePath
	 */
	openContainer(url) {
		return this.load(url)
			.then((xml) => {
				this.container = new container(xml);
				return this.resolve(this.settings.packagePath || this.container.packagePath);
				// return this.resolve(this.container.packagePath);
			});
	}

	/**
	 * Open the Open Packaging Format Xml
	 * @private
	 * @param  {string} url
	 * @return {Promise}
	 */
	openPackaging(url) {
		this.path = new utils_path/* default */.Z(url);
		return this.load(url)
			.then((xml) => {
				this.packaging = new packaging(xml);
				return this.unpack(this.packaging);
			});
	}

	/**
	 * Open the manifest JSON
	 * @private
	 * @param  {string} url
	 * @return {Promise}
	 */
	openManifest(url) {
		this.path = new utils_path/* default */.Z(url);
		return this.load(url)
			.then((json) => {
				this.packaging = new packaging();
				this.packaging.load(json);
				return this.unpack(this.packaging);
			});
	}

	/**
	 * Load a resource from the Book
	 * @param  {string} path path to the resource to load
	 * @return {Promise}     returns a promise with the requested resource
	 */
	load(path) {
		var resolved = this.resolve(path);
		if(this.archived) {
			return this.archive.request(resolved);
		} else {
			return this.request(resolved, null, this.settings.requestCredentials, this.settings.requestHeaders);
		}
	}

	/**
	 * Resolve a path to it's absolute position in the Book
	 * @param  {string} path
	 * @param  {boolean} [absolute] force resolving the full URL
	 * @return {string}          the resolved path string
	 */
	resolve(path, absolute) {
		if (!path) {
			return;
		}
		var resolved = path;
		var isAbsolute = (path.indexOf("://") > -1);

		if (isAbsolute) {
			return path;
		}

		if (this.path) {
			resolved = this.path.resolve(path);
		}

		if(absolute != false && this.url) {
			resolved = this.url.resolve(resolved);
		}

		return resolved;
	}

	/**
	 * Get a canonical link to a path
	 * @param  {string} path
	 * @return {string} the canonical path string
	 */
	canonical(path) {
		var url = path;

		if (!path) {
			return "";
		}

		if (this.settings.canonical) {
			url = this.settings.canonical(path);
		} else {
			url = this.resolve(path, true);
		}

		return url;
	}

	/**
	 * Determine the type of they input passed to open
	 * @private
	 * @param  {string} input
	 * @return {string}  binary | directory | epub | opf
	 */
	determineType(input) {
		var url;
		var path;
		var extension;

		if (this.settings.encoding === "base64") {
			return INPUT_TYPE.BASE64;
		}

		if(typeof(input) != "string") {
			return INPUT_TYPE.BINARY;
		}

		url = new utils_url(input);
		path = url.path();
		extension = path.extension;

		if (!extension) {
			return INPUT_TYPE.DIRECTORY;
		}

		if(extension === "epub"){
			return INPUT_TYPE.EPUB;
		}

		if(extension === "opf"){
			return INPUT_TYPE.OPF;
		}

		if(extension === "json"){
			return INPUT_TYPE.MANIFEST;
		}
	}


	/**
	 * unpack the contents of the Books packaging
	 * @private
	 * @param {Packaging} packaging object
	 */
	unpack(packaging) {
		this.package = packaging; //TODO: deprecated this

		this.spine.unpack(this.packaging, this.resolve.bind(this), this.canonical.bind(this));

		this.resources = new resources(this.packaging.manifest, {
			archive: this.archive,
			resolver: this.resolve.bind(this),
			request: this.request.bind(this),
			replacements: this.settings.replacements || (this.archived ? "blobUrl" : "base64")
		});

		this.loadNavigation(this.packaging).then(() => {
			// this.toc = this.navigation.toc;
			this.loading.navigation.resolve(this.navigation);
		});

		if (this.packaging.coverPath) {
			this.cover = this.resolve(this.packaging.coverPath);
		}
		// Resolve promises
		this.loading.manifest.resolve(this.packaging.manifest);
		this.loading.metadata.resolve(this.packaging.metadata);
		this.loading.spine.resolve(this.spine);
		this.loading.cover.resolve(this.cover);
		this.loading.resources.resolve(this.resources);
		this.loading.pageList.resolve(this.pageList);

		this.isOpen = true;

		if(this.archived || this.settings.replacements && this.settings.replacements != "none") {
			this.replacements().then(() => {
				this.opening.resolve(this);
			})
			.catch((err) => {
				console.error(err);
			});
		} else {
			// Resolve book opened promise
			this.opening.resolve(this);
		}

	}

	/**
	 * Load Navigation and PageList from package
	 * @private
	 * @param {Packaging} packaging
	 */
	loadNavigation(packaging) {
		let navPath = packaging.navPath || packaging.ncxPath;
		let toc = packaging.toc;

		// From json manifest
		if (toc) {
			return new Promise((resolve, reject) => {
				this.navigation = new navigation(toc);

				if (packaging.pageList) {
					this.pageList = new pagelist(packaging.pageList); // TODO: handle page lists from Manifest
				}

				resolve(this.navigation);
			});
		}

		if (!navPath) {
			return new Promise((resolve, reject) => {
				this.navigation = new navigation();
				this.pageList = new pagelist();

				resolve(this.navigation);
			});
		}

		navPath = new utils_path/* default */.Z(this.resolve(navPath));
		return this.load(navPath.path, "xml")
			.then((xml) => {
				this.navigation = new navigation(xml, navPath, this.canonical.bind(this));
				this.pageList = new pagelist(xml, navPath, this.canonical.bind(this));
				return this.navigation;
			});
	}

	/**
	 * Gets a Section of the Book from the Spine
	 * Alias for `book.spine.get`
	 * @param {string} target
	 * @return {Section}
	 */
	section(target) {
		return this.spine.get(target);
	}

	/**
	 * Sugar to render a book to an element
	 * @param  {element | string} element element or string to add a rendition to
	 * @param  {object} [options]
	 * @return {Rendition}
	 */
	renderTo(element, options) {
		this.rendition = new rendition(this, options);
		this.rendition.attachTo(element);

		return this.rendition;
	}

	/**
	 * Set if request should use withCredentials
	 * @param {boolean} credentials
	 */
	setRequestCredentials(credentials) {
		this.settings.requestCredentials = credentials;
	}

	/**
	 * Set headers request should use
	 * @param {object} headers
	 */
	setRequestHeaders(headers) {
		this.settings.requestHeaders = headers;
	}

	/**
	 * Unarchive a zipped epub
	 * @private
	 * @param  {binary} input epub data
	 * @param  {string} [encoding]
	 * @return {Archive}
	 */
	unarchive(input, encoding) {
		this.archive = new archive();
		return this.archive.open(input, encoding);
	}

	/**
	 * Store the epubs contents
	 * @private
	 * @param  {binary} input epub data
	 * @param  {string} [encoding]
	 * @return {Store}
	 */
	store(name) {
		// Use "blobUrl" or "base64" for replacements
		let replacementsSetting = this.settings.replacements && this.settings.replacements !== "none";
		// Save original url
		let originalUrl = this.url;
		// Save original request method
		let requester = this.settings.requestMethod || request.default.bind(this);
		// Create new Store
		this.storage = new store(name, requester, this.resolve.bind(this));
		// Replace request method to go through store
		this.request = this.storage.request.bind(this.storage);

		this.opened.then(() => {
			if (this.archived) {
				this.storage.requester = this.archive.request.bind(this.archive);
			}
			// Substitute hook
			let substituteResources = (output, section) => {
				section.output = this.resources.substitute(output, section.url);
			};

			// Set to use replacements
			this.resources.settings.replacements = replacementsSetting || "blobUrl";
			// Create replacement urls
			this.resources.replacements().
				then(() => {
					return this.resources.replaceCss();
				});

			this.storage.on("offline", () => {
				// Remove url to use relative resolving for hrefs
				this.url = new utils_url("/", "");
				// Add hook to replace resources in contents
				this.spine.hooks.serialize.register(substituteResources);
			});

			this.storage.on("online", () => {
				// Restore original url
				this.url = originalUrl;
				// Remove hook
				this.spine.hooks.serialize.deregister(substituteResources);
			});

		});

		return this.storage;
	}

	/**
	 * Get the cover url
	 * @return {string} coverUrl
	 */
	coverUrl() {
		var retrieved = this.loaded.cover.
			then((url) => {
				if(this.archived) {
					// return this.archive.createUrl(this.cover);
					return this.resources.get(this.cover);
				}else{
					return this.cover;
				}
			});

		return retrieved;
	}

	/**
	 * Load replacement urls
	 * @private
	 * @return {Promise} completed loading urls
	 */
	replacements() {
		this.spine.hooks.serialize.register((output, section) => {
			section.output = this.resources.substitute(output, section.url);
		});

		return this.resources.replacements().
			then(() => {
				return this.resources.replaceCss();
			});
	}

	/**
	 * Find a DOM Range for a given CFI Range
	 * @param  {EpubCFI} cfiRange a epub cfi range
	 * @return {Range}
	 */
	getRange(cfiRange) {
		var cfi = new epubcfi(cfiRange);
		var item = this.spine.get(cfi.spinePos);
		var _request = this.load.bind(this);
		if (!item) {
			return new Promise((resolve, reject) => {
				reject("CFI could not be found");
			});
		}
		return item.load(_request).then(function (contents) {
			var range = cfi.toRange(item.document);
			return range;
		});
	}

	/**
	 * Generates the Book Key using the identifer in the manifest or other string provided
	 * @param  {string} [identifier] to use instead of metadata identifier
	 * @return {string} key
	 */
	key(identifier) {
		var ident = identifier || this.packaging.metadata.identifier || this.url.filename;
		return `epubjs:${EPUBJS_VERSION}:${ident}`;
	}

	/**
	 * Destroy the Book and all associated objects
	 */
	destroy() {
		this.opened = undefined;
		this.loading = undefined;
		this.loaded = undefined;
		this.ready = undefined;

		this.isOpen = false;
		this.isRendered = false;

		this.spine && this.spine.destroy();
		this.locations && this.locations.destroy();
		this.pageList && this.pageList.destroy();
		this.archive && this.archive.destroy();
		this.resources && this.resources.destroy();
		this.container && this.container.destroy();
		this.packaging && this.packaging.destroy();
		this.rendition && this.rendition.destroy();

		this.spine = undefined;
		this.locations = undefined;
		this.pageList = undefined;
		this.archive = undefined;
		this.resources = undefined;
		this.container = undefined;
		this.packaging = undefined;
		this.rendition = undefined;

		this.navigation = undefined;
		this.url = undefined;
		this.path = undefined;
		this.archived = false;
	}

}

//-- Enable binding events to book
event_emitter_default()(Book.prototype);

/* harmony default export */ const book = (Book);

// EXTERNAL MODULE: ./node_modules/epubjs/libs/url/url-polyfill.js
var url_polyfill = __webpack_require__(5749);
;// CONCATENATED MODULE: ./node_modules/epubjs/src/epub.js












/**
 * Creates a new Book
 * @param {string|ArrayBuffer} url URL, Path or ArrayBuffer
 * @param {object} options to pass to the book
 * @returns {Book} a new Book object
 * @example ePub("/path/to/book.epub", {})
 */
function epub_ePub(url, options) {
	return new book(url, options);
}

epub_ePub.VERSION = EPUBJS_VERSION;

if (typeof(__webpack_require__.g) !== "undefined") {
	__webpack_require__.g.EPUBJS_VERSION = EPUBJS_VERSION;
}

epub_ePub.Book = book;
epub_ePub.Rendition = rendition;
epub_ePub.Contents = contents;
epub_ePub.CFI = epubcfi;
epub_ePub.utils = core;

/* harmony default export */ const epub = (epub_ePub);

;// CONCATENATED MODULE: ./node_modules/epubjs/src/index.js







/* harmony default export */ const src = (epub);


// EXTERNAL MODULE: ./src/dom/DomUtil.js
var DomUtil = __webpack_require__(9542);
// EXTERNAL MODULE: ./src/core/Browser.js
var Browser = __webpack_require__(8643);
;// CONCATENATED MODULE: ./src/epubjs/managers/helpers/prefab.js
function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

var PrefabViews = /*#__PURE__*/function () {
  function PrefabViews(container) {
    _classCallCheck(this, PrefabViews);

    this.container = container;
    this._views = [];
    this.length = 0;
    this.hidden = false;
  }

  _createClass(PrefabViews, [{
    key: "all",
    value: function all() {
      return this._views;
    }
  }, {
    key: "first",
    value: function first() {
      return this._views[0];
    }
  }, {
    key: "last",
    value: function last() {
      return this._views[this._views.length - 1];
    }
  }, {
    key: "indexOf",
    value: function indexOf(view) {
      return this._views.indexOf(view);
    }
  }, {
    key: "slice",
    value: function slice() {
      return this._views.slice.apply(this._views, arguments);
    }
  }, {
    key: "get",
    value: function get(i) {
      return this._views[i];
    }
  }, {
    key: "append",
    value: function append(view) {
      var check = false;
      this.forEach(function (v) {
        if (v.section.href == view.section.href) {
          check = true;
        }
      });

      if (check) {
        return view;
      } // if ( check ) { console.log("AHOY views.append WUT", view.section.href)}


      this._views.push(view);

      this._views.sort(function (a, b) {
        return a.section.href > b.section.href ? 1 : b.section.href > a.section.href ? -1 : 0;
      });

      if (this.container && view.element.dataset.reused != 'true') {
        this.container.appendChild(view.element);
      }

      this.length++;
      return view;
    }
  }, {
    key: "dump",
    value: function dump() {
      return this._views.map(function (v) {
        return v.section.href;
      });
    }
  }, {
    key: "prepend",
    value: function prepend(view) {
      this._views.unshift(view);

      if (this.container && view.element.dataset.reused != 'true') {
        this.container.insertBefore(view.element, this.container.firstChild);
      }

      this.length++;
      return view;
    }
  }, {
    key: "insert",
    value: function insert(view, index) {
      this._views.splice(index, 0, view);

      if (this.container && view.element.dataset.reused != 'true') {
        if (index < this.container.children.length) {
          this.container.insertBefore(view.element, this.container.children[index]);
        } else {
          this.container.appendChild(view.element);
        }
      }

      this.length++;
      return view;
    }
  }, {
    key: "remove",
    value: function remove(view) {
      var index = this._views.indexOf(view);

      if (index > -1) {
        this._views.splice(index, 1);
      }

      this.destroy(view);
      this.length--;
    }
  }, {
    key: "destroy",
    value: function destroy(view) {
      if (view.displayed) {
        view.destroy();
      } // if(this.container && view.element.dataset.reused != 'true'){
      // 	 this.container.removeChild(view.element);
      // }


      view = null;
    } // Iterators

  }, {
    key: "forEach",
    value: function forEach() {
      return this._views.forEach.apply(this._views, arguments);
    }
  }, {
    key: "clear",
    value: function clear() {
      // Remove all views
      var view;
      var len = this.length;
      if (!this.length) return;

      for (var i = 0; i < len; i++) {
        view = this._views[i];
        this.destroy(view);
      }

      this._views = [];
      this.length = 0;
    }
  }, {
    key: "find",
    value: function find(section) {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed && view.section.index == section.index) {
          return view;
        }
      }
    }
  }, {
    key: "displayed",
    value: function displayed() {
      var displayed = [];
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed) {
          displayed.push(view);
        }
      }

      return displayed;
    }
  }, {
    key: "show",
    value: function show() {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed) {
          view.show();
        }
      }

      this.hidden = false;
    }
  }, {
    key: "hide",
    value: function hide() {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed) {
          view.hide();
        }
      }

      this.hidden = true;
    }
  }]);

  return PrefabViews;
}();

/* harmony default export */ const prefab = (PrefabViews);
;// CONCATENATED MODULE: ./src/epubjs/managers/continuous/prepaginated.js
function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function prepaginated_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function prepaginated_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function prepaginated_createClass(Constructor, protoProps, staticProps) { if (protoProps) prepaginated_defineProperties(Constructor.prototype, protoProps); if (staticProps) prepaginated_defineProperties(Constructor, staticProps); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }








var PrePaginatedContinuousViewManager = /*#__PURE__*/function (_ContinuousViewManage) {
  _inherits(PrePaginatedContinuousViewManager, _ContinuousViewManage);

  var _super = _createSuper(PrePaginatedContinuousViewManager);

  function PrePaginatedContinuousViewManager(options) {
    var _this;

    prepaginated_classCallCheck(this, PrePaginatedContinuousViewManager);

    _this = _super.call(this, options);
    _this.name = "prepaginated";
    _this._manifest = null;
    _this._spine = [];
    _this.settings.scale = _this.settings.scale || 1.0;
    return _this;
  }

  prepaginated_createClass(PrePaginatedContinuousViewManager, [{
    key: "render",
    value: function render(element, size) {
      var scale = this.settings.scale;
      this.settings.scale = null; // we don't want the stage to scale

      continuous.prototype.render.call(this, element, size); // Views array methods
      // use prefab views

      this.settings.scale = scale;
      this.views = new prefab(this.container);
    }
  }, {
    key: "onResized",
    value: function onResized(e) {
      if (this.resizeTimeout) {
        clearTimeout(this.resizeTimeout);
      }

      console.log("AHOY PREPAGINATED onResized queued");
      this.resizeTimeout = setTimeout(function () {
        this.resize();
        console.log("AHOY PREPAGINATED onResized actual");
        this.resizeTimeout = null;
      }.bind(this), 500); // this.resize();
    }
  }, {
    key: "resize",
    value: function resize(width, height) {
      var self = this;
      continuous.prototype.resize.call(this, width, height);

      this._redrawViews();
    }
  }, {
    key: "_redrawViews",
    value: function _redrawViews() {
      var self = this;

      for (var i = 0; i < self._spine.length; i++) {
        var href = self._spine[i]; // // console.log("AHOY DRAWING", href);

        var section_ = self._manifest[href]; // // var r = self.container.offsetWidth / section_.viewport.width;
        // // var h = Math.floor(dim.height * r);
        // var w = self.layout.columnWidth + ( self.layout.columnWidth * 0.10 );
        // var r = w / section_.viewport.width;
        // var h = Math.floor(section_.viewport.height * r);

        var h, w;

        var _self$sizeToViewport = self.sizeToViewport(section_);

        var _self$sizeToViewport2 = _slicedToArray(_self$sizeToViewport, 2);

        w = _self$sizeToViewport2[0];
        h = _self$sizeToViewport2[1];
        var div = self.container.querySelector("div.epub-view[ref=\"".concat(section_.index, "\"]"));
        div.style.width = "".concat(w, "px");
        div.style.height = "".concat(h, "px");
        div.setAttribute('original-height', h);
        div.setAttribute('layout-height', h);
        var view = this.views.find(section_);

        if (view) {
          view.size(w, h);
        }
      }
    } // RRE - debugging

  }, {
    key: "createView",
    value: function createView(section) {
      var view = this.views.find(section);

      if (view) {
        return view;
      }

      var w, h;

      var _this$sizeToViewport = this.sizeToViewport(section);

      var _this$sizeToViewport2 = _slicedToArray(_this$sizeToViewport, 2);

      w = _this$sizeToViewport2[0];
      h = _this$sizeToViewport2[1];
      var viewSettings = Object.assign({}, this.viewSettings);
      viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
      viewSettings.layout.height = h;
      viewSettings.layout.columnWidth = w;
      var view = new this.View(section, viewSettings);
      return view;
    }
  }, {
    key: "display",
    value: function display(section, target) {
      var self = this;
      var promises = [];
      this.q.clear();
      var display = new core.defer();
      var promises = [];
      this.faking = {};

      if (!this._manifest) {
        this.emit("building");
        self._manifest = {};

        var _buildManifest = function _buildManifest(section_) {
          self._manifest[section_.href] = false;

          if (self.settings.viewports && self.settings.viewports[section_.href]) {
            section_.viewport = self.settings.viewports[section_.href];
            self._manifest[section_.href] = section_;
          } else {
            self.q.enqueue(function () {
              section_.load(self.request).then(function (contents) {
                var meta = contents.querySelector('meta[name="viewport"]');
                var value = meta.getAttribute('content');
                var tmp = value.split(",");
                var key = section_.href;

                var idx = self._spine.indexOf(key);

                self.emit("building", {
                  index: idx + 1,
                  total: self._spine.length
                });
                section_.viewport = {};
                self._manifest[key] = section_; // self._manifest[key] = { viewport : {} };
                // self._manifest[key].index = section_.index;
                // self._manifest[key].href = section_.href;

                var viewport_width = tmp[0].replace('width=', '');
                var viewport_height = tmp[1].replace('height=', '');

                if (!viewport_height.match(/^\d+$/)) {
                  viewport_width = viewport_height = 'auto';
                } else {
                  viewport_width = parseInt(viewport_width, 10);
                  viewport_height = parseInt(viewport_height, 10);
                }

                self._manifest[key].viewport.width = viewport_width;
                self._manifest[key].viewport.height = viewport_height;
                self.faking[key] = self._manifest[key].viewport;
              });
            });
          }
        }; // can we build a manifest here?


        var prev_ = section.prev();

        while (prev_) {
          self._spine.unshift(prev_.href);

          _buildManifest(prev_);

          prev_ = prev_.prev();
        }

        self._spine.push(section.href);

        _buildManifest(section);

        var next_ = section.next();

        while (next_) {
          self._spine.push(next_.href);

          _buildManifest(next_);

          next_ = next_.next();
        }

        console.log("AHOY PRE-PAGINATED", promises.length);
      }

      var _display = function () {
        var check = document.querySelector('.epub-view');

        if (!check) {
          self._max_height = self._max_viewport_height = 0;
          self._max_width = self._max_viewport_width = 0;
          console.log("AHOY DRAWING", self._spine.length);

          for (var i = 0; i < self._spine.length; i++) {
            var href = self._spine[i];
            var section_ = self._manifest[href];
            var w, h;

            var _self$sizeToViewport3 = self.sizeToViewport(section_);

            var _self$sizeToViewport4 = _slicedToArray(_self$sizeToViewport3, 2);

            w = _self$sizeToViewport4[0];
            h = _self$sizeToViewport4[1];
            self.container.innerHTML += "<div class=\"epub-view\" ref=\"".concat(section_.index, "\" data-href=\"").concat(section_.href, "\" style=\"width: ").concat(w, "px; height: ").concat(h, "px; text-align: center; margin-left: auto; margin-right: auto\"></div>");
            var div = self.container.querySelector("div.epub-view[ref=\"".concat(section_.index, "\"]")); // div.setAttribute('use-')

            div.setAttribute('original-height', h);
            div.setAttribute('layout-height', h);

            if (window.debugManager) {
              div.style.backgroundImage = "url(\"data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 32' width='300' height='32'%3e%3cstyle%3e.small %7b fill: rgba(0,0,0,0.3);%7d%3c/style%3e%3ctext x='0' y='25' class='small'%3e".concat(section_.href, "%3c/text%3e%3c/svg%3e\")");
              var colorR = Math.floor(Math.random() * 100).toString();
              var colorG = Math.floor(Math.random() * 100).toString();
              var colorB = Math.floor(Math.random() * 100).toString();
              div.style.backgroundColor = "#".concat(colorR).concat(colorG).concat(colorB);
            }
          }
        } // find the <div> with this section
        // console.log("AHOY continuous.display START", section.href);


        var div = self.container.querySelector("div.epub-view[ref=\"".concat(section.index, "\"]"));
        div.scrollIntoView(); // this.q.clear();
        // return check ? this.update() : this.check();
        // var retval = check ? this.update() : this.check();

        var retval = this.check();
        console.log("AHOY DISPLAY", check ? "UPDATE" : "CHECK", retval);
        retval.then(function () {
          this.q.clear();
          console.log("AHOY MANAGER BUILT");
          this.emit("built");
          return display.resolve();
        }.bind(this)); // return DefaultViewManager.prototype.display.call(this, section, target)
        //  .then(function () {
        //    return this.fill();
        //  }.bind(this));

        return retval;
      }.bind(this); // // promises.push(_display);
      // while(promises.length) {
      //  this.q.enqueue(promises.shift);
      // }
      // console.log("AHOY PREPAGINATED", this.q._q.length);
      // this.q.enqueue().then((result) => {
      //  display.resolve();
      // })


      var q = function () {
        return this.q.enqueue(function (result) {
          var waiting = 0;

          for (var i = 0; i < self._spine.length; i++) {
            var href = self._spine[i];
            var has_section = self._manifest[href];

            if (has_section == false) {
              waiting += 1;
            }
          } // console.log("AHOY PRE-PAGINATED WAITING", waiting);


          if (waiting == 0) {
            return _display();
          } else {
            q();
          }
        });
      }.bind(this);

      return q();
      return display.promise;
    }
  }, {
    key: "_checkStillLoading",
    value: function _checkStillLoading() {
      this.q.enqueue(function (result) {
        var waiting = 0;

        for (var i = 0; i < self._spine.length; i++) {
          var href = self._spine[i];
          var has_section = self._manifest[href];

          if (has_section == false) {
            waiting += 1;
          }
        }

        console.log("AHOY PRE-PAGINATED WAITING", waiting);

        if (waiting == 0) {
          return _display();
        } else {
          q();
        }
      });
    }
  }, {
    key: "fill",
    value: function fill(_full) {
      var _this2 = this;

      var full = _full || new core.defer();
      this.q.enqueue(function () {
        return _this2._checkStillLoading();
      }).then(function (result) {
        if (result) {
          _this2.fill(full);
        } else {
          full.resolve();
        }
      });
      return full.promise;
    }
  }, {
    key: "fillXX",
    value: function fillXX(_full) {
      var _this3 = this;

      var full = _full || new core.defer();
      this.q.enqueue(function () {
        return _this3.check();
      }).then(function (result) {
        if (result) {
          _this3.fill(full);
        } else {
          full.resolve();
        }
      });
      return full.promise;
    }
  }, {
    key: "moveTo",
    value: function moveTo(offset) {
      // var bounds = this.stage.bounds();
      // var dist = Math.floor(offset.top / bounds.height) * bounds.height;
      var distX = 0,
          distY = 0;
      var offsetX = 0,
          offsetY = 0;

      if (!this.isPaginated) {
        distY = offset.top;
        offsetY = offset.top + this.settings.offset;
      } else {
        distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;
        offsetX = distX + this.settings.offset;
      }

      if (distX > 0 || distY > 0) {
        this.scrollBy(distX, distY, true);
      }
    }
  }, {
    key: "afterResized",
    value: function afterResized(view) {
      this.emit(EVENTS.MANAGERS.RESIZE, view.section);
    } // Remove Previous Listeners if present

  }, {
    key: "removeShownListeners",
    value: function removeShownListeners(view) {
      // view.off("shown", this.afterDisplayed);
      // view.off("shown", this.afterDisplayedAbove);
      view.onDisplayed = function () {};
    }
  }, {
    key: "add",
    value: function add(section) {
      var _this4 = this;

      var view = this.createView(section);
      this.views.append(view);
      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
        view.expanded = true;
      });
      view.on(EVENTS.VIEWS.AXIS, function (axis) {
        _this4.updateAxis(axis);
      }); // view.on(EVENTS.VIEWS.SHOWN, this.afterDisplayed.bind(this));

      view.onDisplayed = this.afterDisplayed.bind(this);
      view.onResize = this.afterResized.bind(this);
      return view.display(this.request);
    }
  }, {
    key: "append",
    value: function append(section) {
      var view = this.createView(section);
      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
        view.expanded = true; // do not do this
        // this.counter(bounds); // RRE
      });
      /*
      view.on(EVENTS.VIEWS.AXIS, (axis) => {
        this.updateAxis(axis);
      });
      */

      this.views.append(view);
      view.onDisplayed = this.afterDisplayed.bind(this);
      return view;
    }
  }, {
    key: "prepend",
    value: function prepend(section) {
      var _this5 = this;

      var view = this.createView(section);
      view.on(EVENTS.VIEWS.RESIZED, function (bounds) {
        _this5.counter(bounds);

        view.expanded = true;
      });
      /*
      view.on(EVENTS.VIEWS.AXIS, (axis) => {
        this.updateAxis(axis);
      });
      */

      this.views.prepend(view);
      view.onDisplayed = this.afterDisplayed.bind(this);
      return view;
    }
  }, {
    key: "counter",
    value: function counter(bounds) {
      // return;
      if (this.settings.axis === "vertical") {
        // if ( ! this._timer ) {
        //  this._timer = setTimeout(function() {
        //    this._timer = null;
        //    console.log("AHOY USING counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
        //    this.scrollBy(0, bounds.heightDelta, true);
        //    this.x1(`COUNTER ${bounds.heightDelta}`);
        //  }.bind(this), 500);
        // } else {
        //  console.log("AHOY SKIPPING counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
        // }
        // console.log("AHOY counter.scrollBy : top was =", this.__top, "/ top is =", this.container.scrollTop, "/ delta =", bounds.heightDelta);
        this.scrollBy(0, bounds.heightDelta, true);
      } else {
        this.scrollBy(bounds.widthDelta, 0, true);
      }
    }
  }, {
    key: "updateXXX",
    value: function updateXXX(_offset) {
      var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
      var visibleLength = horizontal ? bounds.width : bounds.height;
      var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;
      var divs = document.querySelectorAll('.epub-view');
      var visible = [];

      for (var i = 0; i < divs.length; i++) {
        var div = divs[i];
        var rect = div.getBoundingClientRect();
        var marker = ''; // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
        // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {

        if (offset < div.offsetTop + rect.height && offset + bounds.height > div.offsetTop) {
          marker = '**';
          var section = this._manifest[div.dataset.href];
          visible.push(section); // if ( ! div.querySelector('iframe') ) {
          //  newViews.push(this.append(section))
          // }
          // var idx = this._spine.indexOf(section.href);
          // if ( idx > 0 ) {
          //  visible.push(this._manifest[this._spine[idx - 1]]);
          // }
          // if ( idx < this._spine.length - 1 ) {
          //  visible.push(this._manifest[this._spine[idx + 1]]);
          // }
        } // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);

      }
    }
  }, {
    key: "update",
    value: function update(_offset) {
      var container = this.bounds();
      var views = this.views.all();
      var viewsLength = views.length;
      var visible = [];
      var offset = typeof _offset != "undefined" ? _offset : this.settings.offset || 0;
      var isVisible;
      var view;
      var updating = new core.defer();
      var promises = [];
      var queued = {};

      for (var i = 0; i < viewsLength; i++) {
        view = views[i];
        isVisible = this.isVisible(view, offset, offset, container);

        if (isVisible === true) {
          queued[i] = true;
        }
      }

      for (var i = 0; i < viewsLength; i++) {
        view = views[i];
        var isVisible = queued[i];

        if (isVisible === true) {
          // console.log("visible " + view.index);
          if (!view.displayed) {
            // console.log("AHOY continuous.update !displayed", view.section.href);
            var displayed = view.display(this.request).then(function (view) {
              view.show();
            }, function (err) {
              // console.log("AHOY continuous.update ERROR", err);
              view.hide();
            });
            promises.push(displayed);
          } else {
            // console.log("AHOY continuous.update show", view.section.href);
            view.show();
          }

          visible.push(view);
        } else {
          this.q.enqueue(view.destroy.bind(view)); // console.log("hidden " + view.index);

          clearTimeout(this.trimTimeout);
          this.trimTimeout = setTimeout(function () {
            this.q.enqueue(this.trim.bind(this));
          }.bind(this), 250);
        }
      }

      if (promises.length) {
        return Promise.all(promises)["catch"](function (err) {
          updating.reject(err);
        });
      } else {
        updating.resolve();
        return updating.promise;
      }
    }
  }, {
    key: "check",
    value: function check(_offsetLeft, _offsetTop) {
      var _this6 = this;

      var checking = new core.defer();
      var newViews = [];
      var horizontal = this.settings.axis === "horizontal";
      var delta = this.settings.offset || 0;

      if (_offsetLeft && horizontal) {
        delta = _offsetLeft;
      }

      if (_offsetTop && !horizontal) {
        delta = _offsetTop;
      }

      var bounds = this._bounds; // bounds saved this until resize

      var rtl = this.settings.direction === "rtl";
      var dir = horizontal && rtl ? -1 : 1; //RTL reverses scrollTop

      var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
      var visibleLength = horizontal ? bounds.width : bounds.height;
      var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;
      var prePaginated = this.layout.props.name == 'pre-paginated'; // console.log("continuous.check prePaginated =", prePaginated, "offset=",
      //  offset, "visibleLength =", visibleLength, "delta=", delta, ` (${offset + visibleLength + delta})`, " >= contentLength =", contentLength,
      //  " == ", offset + visibleLength + delta >= contentLength,
      //  " || ", offset - delta, "<", 0, " == ", offset - delta < 0 );

      var prepend = function prepend() {
        var first = _this6.views.first();

        var prev = first && first.section.prev();

        if (prev) {
          newViews.push(_this6.prepend(prev));
        }
      };

      var append = function append() {
        var last = _this6.views.last();

        var next = last && last.section.next();

        if (next) {
          newViews.push(_this6.append(next));
        }
      };

      var adjusted_top = offset - bounds.height * 8;
      var adjusted_end = offset + bounds.height * 8; // console.log("AHOY check", offset, "-", offset + bounds.height, "/", adjusted_top, "-", adjusted_end);
      // need to figure out which divs are viewable

      var divs = document.querySelectorAll('.epub-view');
      var visible = [];

      for (var i = 0; i < divs.length; i++) {
        var div = divs[i];
        var rect = div.getBoundingClientRect();
        var marker = ''; // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
        // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {

        if (offset < div.offsetTop + rect.height && offset + bounds.height > div.offsetTop) {
          marker = '**';
          var section = this._manifest[div.dataset.href];
          visible.push(section); // if ( ! div.querySelector('iframe') ) {
          //  newViews.push(this.append(section))
          // }
          // var idx = this._spine.indexOf(section.href);
          // if ( idx > 0 ) {
          //  visible.push(this._manifest[this._spine[idx - 1]]);
          // }
          // if ( idx < this._spine.length - 1 ) {
          //  visible.push(this._manifest[this._spine[idx + 1]]);
          // }
        } // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);

      }

      this.__check_visible = visible;
      var section = visible[0];

      if (section && section.index > 0) {
        visible.unshift(this._manifest[this._spine[section.index - 1]]);
      }

      if (section) {
        var tmp = this._spine[section.index + 1];

        if (tmp) {
          visible.push(this._manifest[tmp]);
        }
      } // if ( section && section.prev() ) {
      //  visible.unshift(section.prev());
      // }
      // section = visible[visible.length - 1];
      // if (section && section.next() ) {
      //  visible.push(section.next());
      // }


      for (var i = 0; i < visible.length; i++) {
        var section = visible[i]; // var div = document.querySelector(`.epub-view[ref="${section.index}"]`);
        // if ( div.querySelector('iframe') ) {
        //  continue;
        // }

        newViews.push(this.append(section));
      } // let promises = newViews.map((view) => {
      //  return view.displayed;
      // });


      var promises = [];

      for (var i = 0; i < newViews.length; i++) {
        if (newViews[i]) {
          promises.push(newViews[i]);
        }
      }

      if (newViews.length) {
        return Promise.all(promises).then(function () {// return this.check();
          // if (this.layout.name === "pre-paginated" && this.layout.props.spread && this.layout.flow() != 'scrolled') {
          //   // console.log("AHOY check again");
          //   return this.check();
          // }
        }).then(function () {
          // Check to see if anything new is on screen after rendering
          // console.log("AHOY update again");
          return _this6.update(delta);
        }, function (err) {
          return err;
        });
      } else {
        this.q.enqueue(function () {
          this.update();
        }.bind(this));
        checking.resolve(false);
        return checking.promise;
      }
    }
  }, {
    key: "trim",
    value: function trim() {
      var task = new core.defer();
      var displayed = this.views.displayed();
      var first = displayed[0];
      var last = displayed[displayed.length - 1];
      var firstIndex = this.views.indexOf(first);
      var lastIndex = this.views.indexOf(last);
      var above = this.views.slice(0, firstIndex);
      var below = this.views.slice(lastIndex + 1); // Erase all but last above

      for (var i = 0; i < above.length - 3; i++) {
        if (above[i]) {
          // console.log("AHOY trim > above", first.section.href, ":", above[i].section.href);
          this.erase(above[i], above);
        }
      } // Erase all except first below


      for (var j = 3; j < below.length; j++) {
        if (below[j]) {
          // console.log("AHOY trim > below", last.section.href, ":", below[j].section.href);
          this.erase(below[j]);
        }
      }

      task.resolve();
      return task.promise;
    }
  }, {
    key: "erase",
    value: function erase(view, above) {
      //Trim
      var prevTop;
      var prevLeft;

      if (this.settings.height) {
        prevTop = this.container.scrollTop;
        prevLeft = this.container.scrollLeft;
      } else {
        prevTop = window.scrollY;
        prevLeft = window.scrollX;
      }

      var bounds = view.bounds(); // console.log("AHOY erase", view.section.href, above);

      this.views.remove(view);

      if (above) {
        if (this.settings.axis === "vertical") {// this.scrollTo(0, prevTop - bounds.height, true);
        } else {
          this.scrollTo(prevLeft - bounds.width, 0, true);
        }
      }
    }
  }, {
    key: "addEventListeners",
    value: function addEventListeners(stage) {
      window.addEventListener("unload", function (e) {
        this.ignore = true; // this.scrollTo(0,0);

        this.destroy();
      }.bind(this));
      this.addScrollListeners();
    }
  }, {
    key: "addScrollListeners",
    value: function addScrollListeners() {
      var scroller;
      this.tick = core.requestAnimationFrame;

      if (this.settings.height) {
        this.prevScrollTop = this.container.scrollTop;
        this.prevScrollLeft = this.container.scrollLeft;
      } else {
        this.prevScrollTop = window.scrollY;
        this.prevScrollLeft = window.scrollX;
      }

      this.scrollDeltaVert = 0;
      this.scrollDeltaHorz = 0;

      if (this.settings.height) {
        scroller = this.container;
        this.scrollTop = this.container.scrollTop;
        this.scrollLeft = this.container.scrollLeft;
      } else {
        scroller = window;
        this.scrollTop = window.scrollY;
        this.scrollLeft = window.scrollX;
      }

      scroller.addEventListener("scroll", this.onScroll.bind(this));
      this._scrolled = debounce_default()(this.scrolled.bind(this), 30); // this.tick.call(window, this.onScroll.bind(this));

      this.didScroll = false;
    }
  }, {
    key: "removeEventListeners",
    value: function removeEventListeners() {
      var scroller;

      if (this.settings.height) {
        scroller = this.container;
      } else {
        scroller = window;
      }

      scroller.removeEventListener("scroll", this.onScroll.bind(this));
    }
  }, {
    key: "onScroll",
    value: function onScroll() {
      var scrollTop;
      var scrollLeft;
      var dir = this.settings.direction === "rtl" ? -1 : 1;

      if (this.settings.height) {
        scrollTop = this.container.scrollTop;
        scrollLeft = this.container.scrollLeft;
      } else {
        scrollTop = window.scrollY * dir;
        scrollLeft = window.scrollX * dir;
      }

      this.scrollTop = scrollTop;
      this.scrollLeft = scrollLeft;

      if (!this.ignore) {
        this._scrolled();
      } else {
        this.ignore = false;
      }

      this.scrollDeltaVert += Math.abs(scrollTop - this.prevScrollTop);
      this.scrollDeltaHorz += Math.abs(scrollLeft - this.prevScrollLeft);
      this.prevScrollTop = scrollTop;
      this.prevScrollLeft = scrollLeft;
      clearTimeout(this.scrollTimeout);
      this.scrollTimeout = setTimeout(function () {
        this.scrollDeltaVert = 0;
        this.scrollDeltaHorz = 0;
      }.bind(this), 150);
      this.didScroll = false;
    }
  }, {
    key: "scrolled",
    value: function scrolled() {
      this.q.enqueue(function () {
        this.check();
        this.recenter();
        setTimeout(function () {
          this.emit(EVENTS.MANAGERS.SCROLLED, {
            top: this.scrollTop,
            left: this.scrollLeft
          });
        }.bind(this), 500);
      }.bind(this));
      this.emit(EVENTS.MANAGERS.SCROLL, {
        top: this.scrollTop,
        left: this.scrollLeft
      });
      clearTimeout(this.afterScrolled);
      this.afterScrolled = setTimeout(function () {
        this.emit(EVENTS.MANAGERS.SCROLLED, {
          top: this.scrollTop,
          left: this.scrollLeft
        });
      }.bind(this));
    }
  }, {
    key: "next",
    value: function next() {
      var dir = this.settings.direction;
      var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;
      delta = this.container.offsetHeight / this.settings.scale;
      if (!this.views.length) return;

      if (this.isPaginated && this.settings.axis === "horizontal") {
        this.scrollBy(delta, 0, true);
      } else {
        // this.scrollBy(0, this.layout.height, true);
        this.scrollBy(0, delta, true);
      }

      this.q.enqueue(function () {
        this.check();
      }.bind(this));
    }
  }, {
    key: "prev",
    value: function prev() {
      var dir = this.settings.direction;
      var delta = this.layout.props.name === "pre-paginated" && this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;
      if (!this.views.length) return;

      if (this.isPaginated && this.settings.axis === "horizontal") {
        this.scrollBy(-delta, 0, true);
      } else {
        this.scrollBy(0, -this.layout.height, true);
      }

      this.q.enqueue(function () {
        this.check();
      }.bind(this));
    }
  }, {
    key: "updateAxis",
    value: function updateAxis(axis, forceUpdate) {
      if (!this.isPaginated) {
        axis = "vertical";
      }

      if (!forceUpdate && axis === this.settings.axis) {
        return;
      }

      this.settings.axis = axis;
      this.stage && this.stage.axis(axis);
      this.viewSettings.axis = axis;

      if (this.mapping) {
        this.mapping.axis(axis);
      }

      if (this.layout) {
        if (axis === "vertical") {
          this.layout.spread("none");
        } else {
          this.layout.spread(this.layout.settings.spread);
        }
      }

      if (axis === "vertical") {
        this.settings.infinite = true;
      } else {
        this.settings.infinite = false;
      }
    }
  }, {
    key: "recenter",
    value: function recenter() {
      var wrapper = this.container.parentElement;
      var w3 = wrapper.scrollWidth / 2 - wrapper.offsetWidth / 2;
      wrapper.scrollLeft = w3;
    }
  }, {
    key: "sizeToViewport",
    value: function sizeToViewport(section) {
      var h = this.layout.height; // reduce to 80% to avoid hacking epubjs/layout.js

      var w = this.layout.columnWidth * 0.8 * this.settings.scale;

      if (section.viewport.height != 'auto') {
        if (this.layout.columnWidth > section.viewport.width) {
          w = section.viewport.width * this.settings.scale;
        }

        var r = w / section.viewport.width;
        h = Math.floor(section.viewport.height * r);
      }

      return [w, h];
    }
  }, {
    key: "sizeToViewport_X",
    value: function sizeToViewport_X(section) {
      var h = this.layout.height;
      var w = this.layout.columnWidth * 0.80;

      if (section.viewport.height != 'auto') {
        var r = w / section.viewport.width;
        h = section.viewport.height * r;
        var f = 1 / 0.60;
        var m = Math.min(f * this.layout.height / h, 1.0);
        console.log("AHOY SHRINKING", "( ".concat(f, " * ").concat(this.layout.height, " ) / ").concat(h, " = ").concat(m, " :: ").concat(h * m));
        h *= m;
        h *= this.settings.scale;

        if (h > section.viewport.height) {
          h = section.viewport.height;
        }

        r = h / section.viewport.height;
        w = section.viewport.width * r;
        h = Math.floor(h);
        w = Math.floor(w);
      }

      return [w, h];
    }
  }, {
    key: "scale",
    value: function scale(_scale) {
      var self = this;
      this.settings.scale = _scale;
      var current = this.currentLocation();
      var index = -1;

      if (current[0]) {
        index = current[0].index;
      }

      this.views.hide();
      this.views.clear();

      this._redrawViews();

      this.views.show();
      setTimeout(function () {
        console.log("AHOY JUMPING TO", index);

        if (index > -1) {
          var div = self.container.querySelector("div.epub-view[ref=\"".concat(index, "\"]"));
          div.scrollIntoView(true);
        }

        this.check().then(function () {
          this.onScroll();
        }.bind(this));
      }.bind(this), 0);
    }
  }, {
    key: "resetScale",
    value: function resetScale() {// NOOP
    }
  }]);

  return PrePaginatedContinuousViewManager;
}(continuous);

PrePaginatedContinuousViewManager.toString = function () {
  return 'prepaginated';
};

/* harmony default export */ const prepaginated = ((/* unused pure expression or super */ null && (PrePaginatedContinuousViewManager)));
;// CONCATENATED MODULE: ./src/epubjs/managers/views/iframe.js
function iframe_typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { iframe_typeof = function _typeof(obj) { return typeof obj; }; } else { iframe_typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return iframe_typeof(obj); }

function iframe_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function iframe_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function iframe_createClass(Constructor, protoProps, staticProps) { if (protoProps) iframe_defineProperties(Constructor.prototype, protoProps); if (staticProps) iframe_defineProperties(Constructor, staticProps); return Constructor; }

function iframe_inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) iframe_setPrototypeOf(subClass, superClass); }

function iframe_setPrototypeOf(o, p) { iframe_setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return iframe_setPrototypeOf(o, p); }

function iframe_createSuper(Derived) { var hasNativeReflectConstruct = iframe_isNativeReflectConstruct(); return function _createSuperInternal() { var Super = iframe_getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = iframe_getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return iframe_possibleConstructorReturn(this, result); }; }

function iframe_possibleConstructorReturn(self, call) { if (call && (iframe_typeof(call) === "object" || typeof call === "function")) { return call; } return iframe_assertThisInitialized(self); }

function iframe_assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function iframe_isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function iframe_getPrototypeOf(o) { iframe_getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return iframe_getPrototypeOf(o); }




var ReusableIframeView = /*#__PURE__*/function (_IframeView) {
  iframe_inherits(ReusableIframeView, _IframeView);

  var _super = iframe_createSuper(ReusableIframeView);

  function ReusableIframeView(section, options) {
    iframe_classCallCheck(this, ReusableIframeView);

    return _super.call(this, section, options); // this._layout.height = null;
  }

  iframe_createClass(ReusableIframeView, [{
    key: "container",
    value: function container(axis) {
      var check = document.querySelector("div[ref='".concat(this.index, "']"));

      if (check) {
        check.dataset.reused = 'true';
        return check;
      }

      var element = document.createElement("div");
      element.classList.add("epub-view"); // this.element.style.minHeight = "100px";

      element.style.height = "0px";
      element.style.width = "0px";
      element.style.overflow = "hidden";
      element.style.position = "relative";
      element.style.display = "block";

      if (axis && axis == "horizontal") {
        element.style.flex = "none";
      } else {
        element.style.flex = "initial";
      }

      return element;
    }
  }, {
    key: "create",
    value: function create() {
      if (this.iframe) {
        return this.iframe;
      }

      if (!this.element) {
        this.element = this.createContainer();
      }

      if (this.element.hasAttribute('layout-height')) {
        var height = parseInt(this.element.getAttribute('layout-height'), 10);
        this._layout_height = height;
      }

      this.iframe = this.element.querySelector("iframe");

      if (this.iframe) {
        return this.iframe;
      }

      this.iframe = document.createElement("iframe");
      this.iframe.id = this.id;
      this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations

      this.iframe.style.overflow = "hidden";
      this.iframe.seamless = "seamless"; // Back up if seamless isn't supported

      this.iframe.style.border = "none";
      this.iframe.setAttribute("enable-annotation", "true");
      this.resizing = true; // this.iframe.style.display = "none";

      this.element.style.visibility = "hidden";
      this.iframe.style.visibility = "hidden";
      this.iframe.style.width = "0";
      this.iframe.style.height = "0";
      this._width = 0;
      this._height = 0;
      this.element.setAttribute("ref", this.index);
      this.element.setAttribute("data-href", this.section.href); // this.element.appendChild(this.iframe);

      this.added = true;
      this.elementBounds = (0,core.bounds)(this.element); // if(width || height){
      //   this.resize(width, height);
      // } else if(this.width && this.height){
      //   this.resize(this.width, this.height);
      // } else {
      //   this.iframeBounds = bounds(this.iframe);
      // }

      if ("srcdoc" in this.iframe) {
        this.supportsSrcdoc = true;
      } else {
        this.supportsSrcdoc = false;
      }

      if (!this.settings.method) {
        this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
      }

      return this.iframe;
    }
  }]);

  return ReusableIframeView;
}(iframe);

/* harmony default export */ const views_iframe = ((/* unused pure expression or super */ null && (ReusableIframeView)));
;// CONCATENATED MODULE: ./src/epubjs/managers/helpers/scrolling_views.js
function scrolling_views_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function scrolling_views_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function scrolling_views_createClass(Constructor, protoProps, staticProps) { if (protoProps) scrolling_views_defineProperties(Constructor.prototype, protoProps); if (staticProps) scrolling_views_defineProperties(Constructor, staticProps); return Constructor; }



window.inVp = Util.inVp;

var scrolling_views_Views = /*#__PURE__*/function () {
  function Views(container) {
    var preloading = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    scrolling_views_classCallCheck(this, Views);

    this.container = container;
    this._views = [];
    this.length = 0;
    this.hidden = false;
    this.preloading = preloading;
    this.observer = new IntersectionObserver(this.handleObserver.bind(this), {
      root: this.containr,
      rootMargin: '0px',
      threshold: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    });
  }

  scrolling_views_createClass(Views, [{
    key: "all",
    value: function all() {
      return this._views;
    }
  }, {
    key: "first",
    value: function first() {
      // return this._views[0];
      return this.displayed()[0];
    }
  }, {
    key: "last",
    value: function last() {
      var d = this.displayed();
      return d[d.length - 1]; // return this._views[this._views.length-1];
    }
  }, {
    key: "prev",
    value: function prev(view) {
      var index = this.indexOf(view);
      return this.get(index - 1);
    }
  }, {
    key: "next",
    value: function next(view) {
      var index = this.indexOf(view);
      return this.get(index + 1);
    }
  }, {
    key: "indexOf",
    value: function indexOf(view) {
      return this._views.indexOf(view);
    }
  }, {
    key: "slice",
    value: function slice() {
      return this._views.slice.apply(this._views, arguments);
    }
  }, {
    key: "get",
    value: function get(i) {
      return i < 0 ? null : this._views[i];
    }
  }, {
    key: "append",
    value: function append(view) {
      this._views.push(view);

      if (this.container) {
        this.container.appendChild(view.element);
        var threshold = {};
        var h = this.container.offsetHeight;
        threshold.top = -(h * 0.25);
        threshold.bottom = -(h * 0.25); // view.observer = ElementObserver(view.element, {
        //     container: this.container,
        //     onEnter: this.onEnter.bind(this, view), // callback when the element enters the viewport
        //     onExit: this.onExit.bind(this, view), // callback when the element exits the viewport
        //     offset: 0, // offset from the edges of the viewport in pixels
        //     once: false, // if true, observer is detroyed after first callback is triggered
        //     observerCollection: null // new ObserverCollection() // Advanced: Used for grouping custom viewport handling
        // })
        // const { fully, partially, edges } = inVp(view.element, threshold, this.container);
        // if ( edges.percentage > 0 ) {
        //     this.onEnter(view);
        // }

        this.observer.observe(view.element);
      }

      this.length++;
      return view;
    }
  }, {
    key: "handleObserver",
    value: function handleObserver(entries, observer) {
      var _this = this;

      entries.forEach(function (entry) {
        var div = entry.target;
        var index = div.getAttribute('ref');

        var view = _this.get(index);

        if (entry.isIntersecting && entry.intersectionRatio > 0.0) {
          if (!view.displayed) {
            console.log("AHOY OBSERVING", entries.length, index, 'onEnter');

            _this.onEnter(view);
          }
        } else if (view && view.displayed) {
          console.log("AHOY OBSERVING", entries.length, index, 'onExit');

          _this.onExit(view);
        }
      });
    }
  }, {
    key: "prepend",
    value: function prepend(view) {
      this._views.unshift(view);

      if (this.container) {
        this.container.insertBefore(view.element, this.container.firstChild);
      }

      this.length++;
      return view;
    } // insert(view, index) {
    //     this._views.splice(index, 0, view);
    //     if(this.container){
    //         if(index < this.container.children.length){
    //             this.container.insertBefore(view.element, this.container.children[index]);
    //         } else {
    //             this.container.appendChild(view.element);
    //         }
    //     }
    //     this.length++;
    //     return view;
    // }
    // remove(view) {
    //     var index = this._views.indexOf(view);
    //     if(index > -1) {
    //         this._views.splice(index, 1);
    //     }
    //     this.destroy(view);
    //     this.length--;
    // }

  }, {
    key: "destroy",
    value: function destroy(view) {
      // if(view.displayed){
      //     view.destroy();
      // }
      this.observer.unobserve(view.element);
      view.destroy();

      if (this.container) {
        this.container.removeChild(view.element);
      }

      view = null;
    } // Iterators

  }, {
    key: "forEach",
    value: function forEach() {
      // return this._views.forEach.apply(this._views, arguments);
      return this.displayed().forEach.apply(this._views, arguments);
    }
  }, {
    key: "clear",
    value: function clear() {
      // Remove all views
      var view;
      var len = this.length;
      if (!this.length) return;

      for (var i = 0; i < len; i++) {
        view = this._views[i];
        this.destroy(view);
      }

      this._views = [];
      this.length = 0;
      this.observer.disconnect();
    }
  }, {
    key: "updateLayout",
    value: function updateLayout(options) {
      var width = options.width;
      var height = options.height;

      this._views.forEach(function (view) {
        view.size(width, height);

        if (view.contents) {
          view.contents.size(width, height);
        }
      });
    }
  }, {
    key: "find",
    value: function find(section) {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i]; // view.displayed

        if (view.section.index == section.index) {
          return view;
        }
      }
    }
  }, {
    key: "displayed",
    value: function displayed() {
      var displayed = [];
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        var _inVp = (0,Util.inVp)(view.element, this.container),
            fully = _inVp.fully,
            partially = _inVp.partially,
            edges = _inVp.edges;

        if ((fully || partially) && edges.percentage > 0 && view.displayed) {
          displayed.push(view);
        } // if(view.displayed){
        //     displayed.push(view);
        // }

      }

      return displayed;
    }
  }, {
    key: "show",
    value: function show() {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed) {
          view.show();
        }
      }

      this.hidden = false;
    }
  }, {
    key: "hide",
    value: function hide() {
      var view;
      var len = this.length;

      for (var i = 0; i < len; i++) {
        view = this._views[i];

        if (view.displayed) {
          // console.log("AHOY VIEWS hide", view.index);
          view.hide();
        }
      }

      this.hidden = true;
    }
  }, {
    key: "onEnter",
    value: function onEnter(view, el, viewportState) {
      // console.log("AHOY VIEWS onEnter", view.index, view.preloaded, view.displayed);
      var preload = !view.displayed || view.preloaded;

      if (!view.displayed) {
        // console.log("AHOY SHOULD BE SHOWING", view);
        this.emit("view.display", {
          view: view,
          viewportState: viewportState
        });
      }

      if (this.preloading && preload) {
        // can we grab the next one?
        this.preload(this.next(view), view.index);
        this.preload(this.prev(view), view.index);
      }

      if (!view.displayed && view.preloaded) {
        // console.log("AHOY VIEWS onEnter TOGGLE", view.index, view.preloaded, view.displayed);
        view.preloaded = false;
      }
    }
  }, {
    key: "preload",
    value: function preload(view, index) {
      if (view && !view.preloaded) {
        view.preloaded = true; // console.log("AHOY VIEWS preload", index, ">", view.index);

        this.emit("view.preload", {
          view: view
        });
      }
    }
  }, {
    key: "onExit",
    value: function onExit(view, el, viewportState) {
      // console.log("AHOY VIEWS onExit", view.index, view.preloaded);
      if (view.preloaded) {
        return;
      }

      view.unload();
    }
  }]);

  return Views;
}();

event_emitter_default()(scrolling_views_Views.prototype);
/* harmony default export */ const scrolling_views = (scrolling_views_Views);
;// CONCATENATED MODULE: ./src/epubjs/managers/continuous/scrolling.js
function scrolling_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function scrolling_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function scrolling_createClass(Constructor, protoProps, staticProps) { if (protoProps) scrolling_defineProperties(Constructor.prototype, protoProps); if (staticProps) scrolling_defineProperties(Constructor, staticProps); return Constructor; }








 // import inVp from "in-vp";

var ScrollingContinuousViewManager = /*#__PURE__*/function () {
  function ScrollingContinuousViewManager(options) {
    scrolling_classCallCheck(this, ScrollingContinuousViewManager);

    this.name = "scrolling";
    this.optsSettings = options.settings;
    this.View = options.view;
    this.request = options.request;
    this.renditionQueue = options.queue;
    this.q = new queue(this);
    this.settings = (0,core.extend)(this.settings || {}, {
      infinite: true,
      hidden: false,
      width: undefined,
      height: undefined,
      axis: undefined,
      flow: "scrolled",
      ignoreClass: "",
      fullsize: undefined,
      minHeight: 1024
    });
    (0,core.extend)(this.settings, options.settings || {});
    this.viewSettings = {
      prehooks: this.settings.prehooks,
      ignoreClass: this.settings.ignoreClass,
      axis: this.settings.axis,
      flow: this.settings.flow,
      layout: this.layout,
      method: this.settings.method,
      // srcdoc, blobUrl, write
      width: 0,
      height: 0,
      forceEvenPages: true
    };
    this.rendered = false;
    this.settings.scale = this.settings.scale || 1.0;
    this.settings.xscale = this.settings.scale;
    this.fraction = 0.8; // this.settings.maxWidth = 1024;
  }

  scrolling_createClass(ScrollingContinuousViewManager, [{
    key: "render",
    value: function render(element, size) {
      var tag = element.tagName;

      if (typeof this.settings.fullsize === "undefined" && tag && (tag.toLowerCase() == "body" || tag.toLowerCase() == "html")) {
        this.settings.fullsize = true;
      }

      if (this.settings.fullsize) {
        this.settings.overflow = "visible";
        this.overflow = this.settings.overflow;
      }

      this.settings.size = size; // Save the stage

      this.stage = new stage({
        width: size.width,
        height: size.height,
        overflow: this.overflow,
        hidden: this.settings.hidden,
        axis: this.settings.axis,
        fullsize: this.settings.fullsize,
        direction: this.settings.direction,
        scale: 1.0 // this.settings.scale --- scrolling scales different

      });
      this.stage.attachTo(element); // Get this stage container div

      this.container = this.stage.getContainer(); // Views array methods

      this.views = new scrolling_views(this.container, this.layout.name == 'pre-paginated'); // Calculate Stage Size

      this._bounds = this.bounds();
      this._stageSize = this.stage.size();
      var ar = this._stageSize.width / this._stageSize.height; // console.log("AHOY STAGE", this._stageSize.width, this._stageSize.height, ">", ar);
      // Set the dimensions for views

      this.viewSettings.width = this._stageSize.width;
      this.viewSettings.height = this._stageSize.height; // Function to handle a resize event.
      // Will only attach if width and height are both fixed.

      this.stage.onResize(this.onResized.bind(this));
      this.stage.onOrientationChange(this.onOrientationChange.bind(this)); // Add Event Listeners

      this.addEventListeners(); // Add Layout method
      // this.applyLayoutMethod();

      if (this.layout) {
        this.updateLayout();
      }

      this.rendered = true;
      this._spine = [];
      this.views.on("view.preload", function (_ref) {
        var view = _ref.view;
        view.display(this.request).then(function () {
          view.show();
        });
      }.bind(this));
      this.views.on("view.display", function (_ref2) {
        var view = _ref2.view,
            viewportState = _ref2.viewportState;
        // console.log("AHOY VIEWS scrolling.view.display", view.index);
        view.display(this.request).then(function () {
          view.show();
          this.gotoTarget(view);

          if (true) {
            this.emit(EVENTS.MANAGERS.SCROLLED, {
              top: this.scrollTop,
              left: this.scrollLeft
            });
            this._forceLocationEvent = false;
          }
        }.bind(this));
      }.bind(this));
    }
  }, {
    key: "display",
    value: function display(section, target) {
      var displaying = new core.defer();
      var displayed = displaying.promise;

      if (!this.views.length) {
        this.initializeViews(section);
      } // Check if moving to target is needed


      if (target === section.href || (0,core.isNumber)(target)) {
        target = undefined;
      }

      var current = this.current();
      this.ignore = false;
      var visible = this.views.find(section); // console.log("AHOY scrolling display", section, visible, current, current == visible);

      if (target) {
        this._target = [visible, target];
      } // --- scrollIntoView is quirkily aggressive on mobile devices
      // visible.element.scrollIntoView();


      if (visible.element.parentNode) {
        visible.element.parentNode.scrollTop = visible.element.offsetTop;
      }

      if (visible == current) {
        this.gotoTarget(visible);
      }

      displaying.resolve();
      return displayed;
    }
  }, {
    key: "gotoTarget",
    value: function gotoTarget(view) {
      if (this._target && this._target[0] == view) {
        var offset = view.locationOf(this._target[1]); // -- this does not work; top varies.
        // offset.top += view.element.getBoundingClientRect().top;

        setTimeout(function () {
          offset.top += this.container.scrollTop;
          this.moveTo(offset);
          this._target = null;
        }.bind(this), 10); // var prev; var style;
        // for(var i = 0; i < view.index; i++) {
        //   prev = this.views.get(i);
        //   style = window.getComputedStyle(prev.element);
        //   offset.top += ( parseInt(style.height) / this.settings.scale ) + parseInt(style.marginBottom) + parseInt(style.marginTop);
        //   // offset.top += prev.height() || prev.element.offsetHeight;
        // }
        // this.moveTo(offset);
        // this._target = null;
      }
    }
  }, {
    key: "afterDisplayed",
    value: function afterDisplayed(view) {
      // if ( this._target && this._target[0] == view ) {
      //   let offset = view.locationOf(this._target[1]);
      //   this.moveTo(offset);
      //   this._target = null;
      // }
      this.emit(EVENTS.MANAGERS.ADDED, view);
    }
  }, {
    key: "afterResized",
    value: function afterResized(view) {
      var bounds = this.container.getBoundingClientRect();
      var rect = view.element.getBoundingClientRect();
      this.ignore = true; // view.element.dataset.resizable = "true"

      view.reframeElement();
      var delta;

      if (rect.bottom <= bounds.bottom && rect.top < 0) {
        (0,core.requestAnimationFrame)(function afterDisplayedAfterRAF() {
          delta = view.element.getBoundingClientRect().height - rect.height; // console.log("AHOY afterResized", view.index, view.element.getBoundingClientRect().height, rect.height, delta);

          this.container.scrollTop += Math.ceil(delta);
        }.bind(this));
      } // the default manager emits EVENTS.MANAGERS.RESIZE when the view is resized
      // which causes the rendition to scroll to display the current location
      // since we've (in theory) adjusted that during the paint frame
      // don't emit
      // -- this.emit(EVENTS.MANAGERS.RESIZE, view.section);

    }
  }, {
    key: "moveTo",
    value: function moveTo(offset) {
      var distX = 0,
          distY = 0;
      distY = offset.top; // this.scrollTo(distX, this.container.scrollTop + distY, true);

      this.scrollTo(distX, distY, false);
    }
  }, {
    key: "initializeViews",
    value: function initializeViews(section) {
      var self = this;
      this.ignore = true; // if ( self._spine.length == 0 ) {
      //   console.time("AHOY initializeViews CRAWL");
      //   // can we build a manifest here?
      //   var prev_ = section.prev();
      //   while ( prev_ ) {
      //     // self._spine.unshift(prev_.href);
      //     self._spine.unshift(prev_);
      //     prev_ = prev_.prev();
      //   }
      //   self._spine.push(section);
      //   var next_ = section.next();
      //   while ( next_ ) {
      //     // self._spine.push(next_.href);
      //     self._spine.push(next_);
      //     next_ = next_.next();
      //   }
      //   console.timeEnd("AHOY initializeViews CRAWL");
      // }
      // this._spine.forEach(function (section) {

      this.settings.spine.each(function (section) {
        var _this = this;

        // if ( this.layout.name == 'pre-paginated' ) {
        //   // do something
        //   // viewSettings.layout.height = h;
        //   // viewSettings.layout.columnWidth = w;
        //   var r = this.layout.height / this.layout.columnWidth;
        //   viewSettings.layout.columnWidth = this.layout.columnWidth * 0.8;
        //   viewSettings.layout.height = this.layout.height * ( this.layout.columnWidth)
        // }
        var viewSettings = Object.assign({}, this.viewSettings);
        viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);

        if (this.layout.name == 'pre-paginated') {
          viewSettings.layout.columnWidth = this.calcuateWidth(viewSettings.layout.columnWidth); // *= ( this.fraction * this.settings.xscale );

          viewSettings.layout.width = this.calcuateWidth(viewSettings.layout.width); // *= ( this.fraction * this.settings.xscale );

          viewSettings.minHeight *= this.settings.xscale;
          viewSettings.maxHeight = viewSettings.height * this.settings.xscale;
          viewSettings.height = viewSettings.height * this.settings.xscale;
          viewSettings.layout.height = viewSettings.height; // console.log("AHOY new view", section.index, viewSettings.height);
        }

        var view = new this.View(section, viewSettings);
        view.onDisplayed = this.afterDisplayed.bind(this);
        view.onResize = this.afterResized.bind(this);
        view.on(EVENTS.VIEWS.AXIS, function (axis) {
          _this.updateAxis(axis);
        }); // view.on('BAMBOOZLE', (e) => {
        //   this.afterResizedBamboozled(view);
        // })

        this.views.append(view);
      }.bind(this));
      this.ignore = false;
    }
  }, {
    key: "direction",
    value: function direction() {
      var dir = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : "ltr";
      this.settings.direction = dir;
      this.stage && this.stage.direction(dir);
      this.viewSettings.direction = dir;
      this.updateLayout();
    }
  }, {
    key: "onOrientationChange",
    value: function onOrientationChange(e) {}
  }, {
    key: "onResized",
    value: function onResized(e) {
      // if ( this.resizeTimeout ) {
      //   clearTimeout(this.resizeTimeout);
      // } else {
      //   // this._current = this.current() && this.current().section;
      //   // this._current = { view: this.current(), location: this.currentLocation() };
      // }
      // this.resizeTimeout = setTimeout(this.resize.bind(this), 100);
      this.resize();
    }
  }, {
    key: "resize",
    value: function resize(width, height) {
      var stageSize = this.stage.size(width, height);

      if (this.resizeTimeout) {
        clearTimeout(this.resizeTimeout);
        this.resizeTimeout = null;
      }

      this.ignore = true; // For Safari, wait for orientation to catch up
      // if the window is a square

      this.winBounds = (0,core.windowBounds)();

      if (this.orientationTimeout && this.winBounds.width === this.winBounds.height) {
        // reset the stage size for next resize
        this._stageSize = undefined;
        return;
      }

      if (this._stageSize && this._stageSize.width === stageSize.width && this._stageSize.height === stageSize.height) {
        // Size is the same, no need to resize
        return;
      }

      this._stageSize = stageSize;
      this._bounds = this.bounds(); // if ( ! this._resizeTarget ) {
      //   var current = this.current();
      //   if ( current ) {
      //     this._resizeTarget = current.section;
      //   }
      // }

      this.clear(); // Update for new views

      this.viewSettings.width = this._stageSize.width;
      this.viewSettings.height = this._stageSize.height;
      this.updateLayout(); // var section; var target;
      // if ( this._current ) {
      //   section = this._current.view.section;
      //   target = this._current.location[0].mapping.start;
      //   this._current = null;
      // } else {
      //   section = this._spine[0];
      // }
      // this.initializeViews(section);
      // this.display(section, target);
      // this.views.updateLayout(this.viewSettings);

      this.emit(EVENTS.MANAGERS.RESIZED, {
        width: this._stageSize.width,
        height: this._stageSize.height
      });
    }
  }, {
    key: "updateAxis",
    value: function updateAxis(axis, forceUpdate) {
      if (!this.isPaginated) {
        axis = "vertical";
      }

      if (!forceUpdate && axis === this.settings.axis) {
        return;
      }

      this.settings.axis = axis;
      this.stage && this.stage.axis(axis);
      this.viewSettings.axis = axis;

      if (this.mapping) {
        this.mapping = new src_mapping(this.layout.props, this.settings.direction, this.settings.axis);
      }

      if (this.layout) {
        this.layout.spread("none");
      }
    }
  }, {
    key: "updateFlow",
    value: function updateFlow(flow) {
      this.isPaginated = false;
      this.updateAxis("vertical");
      this.viewSettings.flow = flow;

      if (!this.settings.overflow) {
        this.overflow = this.isPaginated ? "hidden" : "auto";
      } else {
        this.overflow = this.settings.overflow;
      }

      this.stage && this.stage.overflow(this.overflow);
      this.updateLayout();
    }
  }, {
    key: "getContents",
    value: function getContents() {
      var contents = [];

      if (!this.views) {
        return contents;
      }

      this.views.forEach(function (view) {
        var viewContents = view && view.contents;

        if (viewContents) {
          contents.push(viewContents);
        }
      });
      return contents;
    }
  }, {
    key: "current",
    value: function current() {
      var visible = this.visible();
      var view;

      if (visible.length) {
        // Current is the last visible view
        var current = null;

        for (var i = 0; i < visible.length; i++) {
          view = visible[i];

          var _inVp = (0,Util.inVp)(view.element, this.container),
              fully = _inVp.fully,
              partially = _inVp.partially,
              edges = _inVp.edges;

          if (!current) {
            current = view;
            current.percentage = edges.percentage;
          } else if (edges.percentage > current.percentage) {
            current = view;
            current.percentage = edges.percentage;
          }
        }

        if (current) {
          return current;
        }

        return visible[visible.length - 1];
      }

      return null;
    }
  }, {
    key: "visible",
    value: function visible() {
      var visible = [];
      var views = this.views.displayed();
      var viewsLength = views.length;
      var visible = [];
      var isVisible;
      var view;
      return this.views.displayed();

      for (var i = 0; i < viewsLength; i++) {
        view = views[i];

        if (view.displayed) {
          visible.push(view);
        }
      }

      return visible;
    }
  }, {
    key: "scrollBy",
    value: function scrollBy(x, y, silent) {
      var dir = this.settings.direction === "rtl" ? -1 : 1;

      if (silent) {
        this.ignore = true;
      }

      if (!this.settings.fullsize) {
        if (x) this.container.scrollLeft += x * dir;
        if (y) this.container.scrollTop += y;
      } else {
        window.scrollBy(x * dir, y * dir);
      }

      this.scrolled = true;
    }
  }, {
    key: "scrollTo",
    value: function scrollTo(x, y, silent) {
      if (silent) {
        this.ignore = true;
      }

      if (!this.settings.fullsize) {
        this.container.scrollLeft = x;
        this.container.scrollTop = y;
      } else {
        window.scrollTo(x, y);
      }

      this.scrolled = true;
    }
  }, {
    key: "onScroll",
    value: function onScroll() {
      var scrollTop;
      var scrollLeft;

      if (!this.settings.fullsize) {
        scrollTop = this.container.scrollTop;
        scrollLeft = this.container.scrollLeft;
      } else {
        scrollTop = window.scrollY;
        scrollLeft = window.scrollX;
      }

      this.scrollTop = scrollTop;
      this.scrollLeft = scrollLeft;

      if (!this.ignore) {
        this.emit(EVENTS.MANAGERS.SCROLL, {
          top: scrollTop,
          left: scrollLeft
        });
        clearTimeout(this.afterScrolled);
        this.afterScrolled = setTimeout(function () {
          this.emit(EVENTS.MANAGERS.SCROLLED, {
            top: this.scrollTop,
            left: this.scrollLeft
          });
        }.bind(this), 20);
      } else {
        this.ignore = false;
      }
    }
  }, {
    key: "bounds",
    value: function bounds() {
      var bounds;
      bounds = this.stage.bounds();
      return bounds;
    }
  }, {
    key: "applyLayout",
    value: function applyLayout(layout) {
      this.layout = layout;
      this.updateLayout();
    }
  }, {
    key: "updateLayout",
    value: function updateLayout() {
      if (!this.stage) {
        return;
      }

      this._stageSize = this.stage.size();
      this.layout.calculate(this._stageSize.width, this._stageSize.height); // this.layout.width = this.container.offsetWidth * 0.80;
      // Set the dimensions for views

      this.viewSettings.width = this.layout.width; //  * this.settings.scale;

      this.viewSettings.height = this.calculateHeight(this.layout.height);
      this.viewSettings.minHeight = this.viewSettings.height; // * this.settings.scale;

      this.setLayout(this.layout);
    }
  }, {
    key: "setLayout",
    value: function setLayout(layout) {
      this.viewSettings.layout = layout;
      this.mapping = new src_mapping(layout.props, this.settings.direction, this.settings.axis);

      if (this.views) {
        this.views._views.forEach(function (view) {
          var viewSettings = Object.assign({}, this.viewSettings);
          viewSettings.layout = Object.assign(Object.create(Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);

          if (this.layout.name == 'pre-paginated') {
            viewSettings.layout.columnWidth = this.calcuateWidth(viewSettings.layout.columnWidth); // *= ( this.fraction * this.settings.xscale );

            viewSettings.layout.width = this.calcuateWidth(viewSettings.layout.width); // *= ( this.fraction * this.settings.xscale );

            viewSettings.minHeight *= this.settings.xscale;
            viewSettings.maxHeight = viewSettings.height * this.settings.xscale;
            viewSettings.height = viewSettings.height * this.settings.xscale;
            viewSettings.layout.height = viewSettings.height;
          }

          view.size(viewSettings.layout.width, viewSettings.layout.height);
          view.reframe(viewSettings.layout.width, viewSettings.layout.height);
          view.setLayout(viewSettings.layout);
        }); // this.views.forEach(function(view){
        //   if (view) {
        //     view.reframe(layout.width, layout.height);
        //     view.setLayout(layout);
        //   }
        // });

      }
    }
  }, {
    key: "addEventListeners",
    value: function addEventListeners() {
      var scroller;
      window.addEventListener("unload", function (e) {
        this.destroy();
      }.bind(this));

      if (!this.settings.fullsize) {
        scroller = this.container;
      } else {
        scroller = window;
      }

      this._onScroll = this.onScroll.bind(this);
      scroller.addEventListener("scroll", this._onScroll);
    }
  }, {
    key: "removeEventListeners",
    value: function removeEventListeners() {
      var scroller;

      if (!this.settings.fullsize) {
        scroller = this.container;
      } else {
        scroller = window;
      }

      scroller.removeEventListener("scroll", this._onScroll);
      this._onScroll = undefined;
    }
  }, {
    key: "destroy",
    value: function destroy() {
      clearTimeout(this.orientationTimeout);
      clearTimeout(this.resizeTimeout);
      clearTimeout(this.afterScrolled);
      this.clear();
      this.removeEventListeners();
      this.stage.destroy();
      this.rendered = false;
      /*
         clearTimeout(this.trimTimeout);
        if(this.settings.hidden) {
          this.element.removeChild(this.wrapper);
        } else {
          this.element.removeChild(this.container);
        }
      */
    }
  }, {
    key: "next",
    value: function next() {
      var next;
      var left;
      var displaying = new core.defer();
      var displayed = displaying.promise;
      var dir = this.settings.direction;
      if (!this.views.length) return;
      this.scrollTop = this.container.scrollTop;
      var top = this.container.scrollTop + this.container.offsetHeight;
      this.scrollBy(0, this.layout.height, false);
      this.q.enqueue(function () {
        displaying.resolve();
        return displayed;
      });
    }
  }, {
    key: "prev",
    value: function prev() {
      var next;
      var left;
      var displaying = new core.defer();
      var displayed = displaying.promise;
      var dir = this.settings.direction;
      if (!this.views.length) return;
      this.scrollTop = this.container.scrollTop;
      var top = this.container.scrollTop - this.container.offsetHeight;
      this.scrollBy(0, -this.layout.height, false);
      this.q.enqueue(function () {
        displaying.resolve();
        return displayed;
      });
    }
  }, {
    key: "clear",
    value: function clear() {
      // // this.q.clear();
      if (this.views) {
        this.views.hide();
        this.scrollTo(0, 0, true);
        this.views.clear();
      }
    }
  }, {
    key: "currentLocation",
    value: function currentLocation() {
      var _this2 = this;

      var visible = this.visible();
      var container = this.container.getBoundingClientRect();
      var pageHeight = container.height < window.innerHeight ? container.height : window.innerHeight;
      var offset = 0;
      var used = 0;

      if (this.settings.fullsize) {
        offset = window.scrollY;
      }

      var sections = visible.map(function (view) {
        var _view$section = view.section,
            index = _view$section.index,
            href = _view$section.href;
        var position = view.position();
        var height = view.height();
        var startPos = offset + container.top - position.top + used;
        var endPos = startPos + pageHeight - used;

        if (endPos > height) {
          endPos = height;
          used = endPos - startPos;
        }

        var totalPages = _this2.layout.count(height, pageHeight).pages;

        var currPage = Math.ceil(startPos / pageHeight);
        var pages = [];
        var endPage = Math.ceil(endPos / pageHeight);
        pages = [];

        for (var i = currPage; i <= endPage; i++) {
          var pg = i + 1;
          pages.push(pg);
        }

        totalPages = pages.length;

        var mapping = _this2.mapping.page(view.contents, view.section.cfiBase, startPos, endPos);

        return {
          index: index,
          href: href,
          pages: pages,
          totalPages: totalPages,
          mapping: mapping
        };
      });

      if (sections.length == 0) {
        self._forceLocationEvent = true;
      }

      return sections;
    }
  }, {
    key: "isRendered",
    value: function isRendered() {
      return this.rendered;
    }
  }, {
    key: "scale",
    value: function scale(s) {
      if (s == null) {
        s = 1.0;
      }

      this.settings.scale = this.settings.xscale = s; // if (this.stage) {
      //   this.stage.scale(s);
      // }

      this.clear();
      this.updateLayout();
      this.emit(EVENTS.MANAGERS.RESIZED, {
        width: this._stageSize.width,
        height: this._stageSize.height
      });
    }
  }, {
    key: "calcuateWidth",
    value: function calcuateWidth(width) {
      var retval = width * this.fraction * this.settings.xscale; // if ( retval > this.settings.maxWidth * this.settings.xscale ) {
      //   retval = this.settings.maxWidth * this.settings.xscale;
      // }

      return retval;
    }
  }, {
    key: "calculateHeight",
    value: function calculateHeight(height) {
      var minHeight = this.layout.name == 'xxpre-paginated' ? 0 : this.settings.minHeight;
      return height > minHeight ? this.layout.height : this.settings.minHeight;
    }
  }]);

  return ScrollingContinuousViewManager;
}();

ScrollingContinuousViewManager.toString = function () {
  return 'continuous';
}; //-- Enable binding events to Manager


event_emitter_default()(ScrollingContinuousViewManager.prototype);
/* harmony default export */ const scrolling = (ScrollingContinuousViewManager);
;// CONCATENATED MODULE: ./src/epubjs/managers/views/sticky.js
function sticky_typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { sticky_typeof = function _typeof(obj) { return typeof obj; }; } else { sticky_typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return sticky_typeof(obj); }

function sticky_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function sticky_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function sticky_createClass(Constructor, protoProps, staticProps) { if (protoProps) sticky_defineProperties(Constructor.prototype, protoProps); if (staticProps) sticky_defineProperties(Constructor, staticProps); return Constructor; }

function _get(target, property, receiver) { if (typeof Reflect !== "undefined" && Reflect.get) { _get = Reflect.get; } else { _get = function _get(target, property, receiver) { var base = _superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(receiver); } return desc.value; }; } return _get(target, property, receiver || target); }

function _superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = sticky_getPrototypeOf(object); if (object === null) break; } return object; }

function sticky_inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) sticky_setPrototypeOf(subClass, superClass); }

function sticky_setPrototypeOf(o, p) { sticky_setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return sticky_setPrototypeOf(o, p); }

function sticky_createSuper(Derived) { var hasNativeReflectConstruct = sticky_isNativeReflectConstruct(); return function _createSuperInternal() { var Super = sticky_getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = sticky_getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return sticky_possibleConstructorReturn(this, result); }; }

function sticky_possibleConstructorReturn(self, call) { if (call && (sticky_typeof(call) === "object" || typeof call === "function")) { return call; } return sticky_assertThisInitialized(self); }

function sticky_assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function sticky_isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function sticky_getPrototypeOf(o) { sticky_getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return sticky_getPrototypeOf(o); }






var StickyIframeView = /*#__PURE__*/function (_IframeView) {
  sticky_inherits(StickyIframeView, _IframeView);

  var _super = sticky_createSuper(StickyIframeView);

  function StickyIframeView(section, options) {
    var _this;

    sticky_classCallCheck(this, StickyIframeView);

    _this = _super.call(this, section, options);
    _this.element.style.height = "".concat(_this.layout.height, "px");
    _this.element.style.width = "".concat(_this.layout.width, "px");
    _this.element.style.visibility = "hidden"; // console.log("AHOY sticky NEW", this.layout.height);

    return _this;
  }

  sticky_createClass(StickyIframeView, [{
    key: "container",
    value: function container(axis) {
      var check = document.querySelector("div[ref='".concat(this.index, "']"));

      if (check) {
        check.dataset.reused = 'true';
        return check;
      }

      var element = document.createElement("div");
      element.classList.add("epub-view"); // this.element.style.minHeight = "100px";

      element.style.height = "0px";
      element.style.width = "0px";
      element.style.overflow = "hidden";
      element.style.position = "relative";
      element.style.display = "block";
      element.setAttribute('ref', this.index);

      if (axis && axis == "horizontal") {
        element.style.flex = "none";
      } else {
        element.style.flex = "initial";
      }

      return element;
    }
  }, {
    key: "create",
    value: function create() {
      if (this.iframe) {
        return this.iframe;
      }

      if (!this.element) {
        this.element = this.createContainer();
      }

      if (this.element.hasAttribute('layout-height')) {
        var height = parseInt(this.element.getAttribute('layout-height'), 10);
        this._layout_height = height;
      }

      this.iframe = this.element.querySelector("iframe");

      if (this.iframe) {
        return this.iframe;
      }

      this.iframe = document.createElement("iframe");
      this.iframe.id = this.id;
      this.iframe.scrolling = "no"; // Might need to be removed: breaks ios width calculations

      this.iframe.style.overflow = "hidden";
      this.iframe.seamless = "seamless"; // Back up if seamless isn't supported

      this.iframe.style.border = "none";
      this.iframe.setAttribute("enable-annotation", "true");
      this.resizing = true; // this.iframe.style.display = "none";

      this.element.style.visibility = "hidden";
      this.iframe.style.visibility = "hidden";
      this.element.classList.add('epub-view---loading');
      this.iframe.style.width = "0";
      this.iframe.style.height = "0";
      this._width = 0;
      this._height = 0;
      this.element.setAttribute("ref", this.index);
      this.element.setAttribute("data-href", this.section.href); // this.element.appendChild(this.iframe);

      this.added = true;
      this.elementBounds = (0,core.bounds)(this.element); // if(width || height){
      //   this.resize(width, height);
      // } else if(this.width && this.height){
      //   this.resize(this.width, this.height);
      // } else {
      //   this.iframeBounds = bounds(this.iframe);
      // }

      if ("srcdoc" in this.iframe) {
        this.supportsSrcdoc = true;
      } else {
        this.supportsSrcdoc = false;
      }

      if (!this.settings.method) {
        this.settings.method = this.supportsSrcdoc ? "srcdoc" : "write";
      }

      return this.iframe;
    }
  }, {
    key: "reframe",
    value: function reframe(width, height) {
      var _this2 = this;

      var size;
      var minHeight = this.settings.minHeight || 0;
      var maxHeight = this.settings.maxHeight || -1; // try to add some padding in the shortest pages

      minHeight *= 0.90; // console.log("AHOY AHOY reframe", this.index, width, height);

      if ((0,core.isNumber)(width)) {
        this.element.style.width = width + "px";

        if (this.iframe) {
          this.iframe.style.width = width + "px";
        }

        this._width = width;
      }

      if ((0,core.isNumber)(height)) {
        var checkMinHeight = this.settings.layout.name == 'reflowable';
        height = checkMinHeight && height <= minHeight ? minHeight : height;
        var styles = window.getComputedStyle(this.element); // setting the element height is delayed

        if (this.iframe) {
          this.iframe.style.height = height + "px";
        }

        this._height = height;
      }

      var widthDelta = this.prevBounds ? width - this.prevBounds.width : width;
      var heightDelta = this.prevBounds ? height - this.prevBounds.height : height;
      size = {
        width: width,
        height: height,
        widthDelta: widthDelta,
        heightDelta: heightDelta
      };
      this.pane && this.pane.render();
      requestAnimationFrame(function () {
        var mark;

        for (var m in _this2.marks) {
          if (_this2.marks.hasOwnProperty(m)) {
            mark = _this2.marks[m];

            _this2.placeMark(mark.element, mark.range);
          }
        }
      });
      this.onResize(this, size);
      this.emit(EVENTS.VIEWS.RESIZED, size);
      this.prevBounds = size;
      this.elementBounds = (0,core.bounds)(this.element);
    }
  }, {
    key: "queryReframeElement",
    value: function queryReframeElement() {
      if (!this.iframe) {
        return -1;
      }

      var height = this.iframe.offsetHeight;
      var styles = window.getComputedStyle(this.element);
      var new_height = height + parseInt(styles.paddingTop) + parseInt(styles.paddingBottom);
      return new_height;
    }
  }, {
    key: "reframeElement",
    value: function reframeElement() {
      if (!this.iframe) {
        return;
      }

      var height = this.iframe.offsetHeight;
      var styles = window.getComputedStyle(this.element);
      var new_height = height + parseInt(styles.paddingTop, 10) + parseInt(styles.paddingBottom, 10) + parseInt(styles.borderTopWidth, 10) + parseInt(styles.borderBottomWidth, 10);
      var current_height = this.element.offsetHeight; // if this is the first re-load and the height doesn't match the current height
      // DO NOT alter the height because some override is going to be applied
      // which will alter the height.

      this.afterResizeCounter += 1;

      if (this.unloaded && height != current_height && this.afterResizeCounter == 1) {
        return;
      }

      this.element.style.height = "".concat(new_height, "px");
    }
  }, {
    key: "display",
    value: function display(request) {
      var displayed = new core.defer();

      if (!this.displayed) {
        this.render(request).then(function () {
          this.emit(EVENTS.VIEWS.DISPLAYED, this);
          this.onDisplayed(this);
          this.displayed = true;
          displayed.resolve(this);
        }.bind(this), function (err) {
          displayed.reject(err, this);
        });
      } else {
        displayed.resolve(this);
      }

      return displayed.promise;
    }
  }, {
    key: "show",
    value: function show() {
      _get(sticky_getPrototypeOf(StickyIframeView.prototype), "show", this).call(this);

      this.element.classList.remove('epub-view---loading');
    }
  }, {
    key: "hide",
    value: function hide() {
      _get(sticky_getPrototypeOf(StickyIframeView.prototype), "hide", this).call(this);
    }
  }, {
    key: "onLoad",
    value: function onLoad(event, promise) {
      var _this3 = this;

      this.window = this.iframe.contentWindow;
      this.document = this.iframe.contentDocument;
      this.contents = new contents(this.document, this.document.body, this.section.cfiBase, this.section.index);
      this.contents.axis = this.settings.axis;
      this.rendering = false;
      this.afterResizeCounter = 0;
      var link = this.document.querySelector("link[rel='canonical']");

      if (link) {
        link.setAttribute("href", this.section.canonical);
      } else {
        link = this.document.createElement("link");
        link.setAttribute("rel", "canonical");
        link.setAttribute("href", this.section.canonical);
        this.document.querySelector("head").appendChild(link);
      }

      this.contents.on(EVENTS.CONTENTS.EXPAND, function () {
        if (_this3.displayed && _this3.iframe) {
          _this3.expand();

          if (_this3.contents) {
            // console.log("AHOY EXPAND", this.index, this.layout.columnWidth, this.layout.height);
            _this3.layout.format(_this3.contents);
          }
        }
      });
      this.contents.on(EVENTS.CONTENTS.RESIZE, function (e) {
        if (_this3.displayed && _this3.iframe) {
          _this3.expand();

          if (_this3.contents) {
            // console.log("AHOY RESIZE", this.index, this.layout.columnWidth, this.layout.height);
            _this3.layout.format(_this3.contents);
          }
        }
      });
      promise.resolve(this.contents);
    }
  }, {
    key: "unload",
    value: function unload() {
      for (var cfiRange in this.highlights) {
        this.unhighlight(cfiRange);
      }

      for (var _cfiRange in this.underlines) {
        this.ununderline(_cfiRange);
      }

      for (var _cfiRange2 in this.marks) {
        this.unmark(_cfiRange2);
      }

      if (this.pane) {
        this.element.removeChild(this.pane.element);
        this.pane = undefined;
      }

      if (this.blobUrl) {
        (0,core.revokeBlobUrl)(this.blobUrl);
      }

      if (this.displayed) {
        this.displayed = false;
        this.removeListeners();
        this.stopExpanding = true;
        this.element.removeChild(this.iframe);
        this.element.style.visibility = "hidden";
        this.unloaded = true;
        this.iframe = undefined;
        this.contents = undefined; // this._textWidth = null;
        // this._textHeight = null;
        // this._width = null;
        // this._height = null;
      } // this.element.style.height = "0px";
      // this.element.style.width = "0px";

    } // setLayout(layout) {
    // }

  }]);

  return StickyIframeView;
}(iframe);

/* harmony default export */ const sticky = (StickyIframeView);
;// CONCATENATED MODULE: ./src/utils/manglers.js
function manglers_typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { manglers_typeof = function _typeof(obj) { return typeof obj; }; } else { manglers_typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return manglers_typeof(obj); }

function manglers_slicedToArray(arr, i) { return manglers_arrayWithHoles(arr) || manglers_iterableToArrayLimit(arr, i) || manglers_unsupportedIterableToArray(arr, i) || manglers_nonIterableRest(); }

function manglers_nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function manglers_unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return manglers_arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return manglers_arrayLikeToArray(o, minLen); }

function manglers_arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function manglers_iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function manglers_arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function manglers_get(target, property, receiver) { if (typeof Reflect !== "undefined" && Reflect.get) { manglers_get = Reflect.get; } else { manglers_get = function _get(target, property, receiver) { var base = manglers_superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(receiver); } return desc.value; }; } return manglers_get(target, property, receiver || target); }

function manglers_superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = manglers_getPrototypeOf(object); if (object === null) break; } return object; }

function manglers_inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) manglers_setPrototypeOf(subClass, superClass); }

function manglers_setPrototypeOf(o, p) { manglers_setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return manglers_setPrototypeOf(o, p); }

function manglers_createSuper(Derived) { var hasNativeReflectConstruct = manglers_isNativeReflectConstruct(); return function _createSuperInternal() { var Super = manglers_getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = manglers_getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return manglers_possibleConstructorReturn(this, result); }; }

function manglers_possibleConstructorReturn(self, call) { if (call && (manglers_typeof(call) === "object" || typeof call === "function")) { return call; } return manglers_assertThisInitialized(self); }

function manglers_assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function manglers_isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Date.prototype.toString.call(Reflect.construct(Date, [], function () {})); return true; } catch (e) { return false; } }

function manglers_getPrototypeOf(o) { manglers_getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return manglers_getPrototypeOf(o); }

function manglers_classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function manglers_defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function manglers_createClass(Constructor, protoProps, staticProps) { if (protoProps) manglers_defineProperties(Constructor.prototype, protoProps); if (staticProps) manglers_defineProperties(Constructor, staticProps); return Constructor; }




var BaseUpdater = /*#__PURE__*/function () {
  function BaseUpdater() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    manglers_classCallCheck(this, BaseUpdater);

    this.reader = options.reader;
    this.contents = options.contents;
    this.layout = this.reader._rendition.manager.layout;
  }

  manglers_createClass(BaseUpdater, [{
    key: "test",
    value: function test(element) {
      return element.matches(this.selector);
    }
  }, {
    key: "stylesheet",
    value: function stylesheet() {
      return {};
    }
  }, {
    key: "update",
    value: function update(element) {}
  }]);

  return BaseUpdater;
}();

var TableUpdater = /*#__PURE__*/function (_BaseUpdater) {
  manglers_inherits(TableUpdater, _BaseUpdater);

  var _super = manglers_createSuper(TableUpdater);

  function TableUpdater() {
    var _this;

    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    manglers_classCallCheck(this, TableUpdater);

    _this = _super.call(this, options);
    _this.selector = 'table:not([data-fulcrum-table="false"])';
    return _this;
  }

  manglers_createClass(TableUpdater, [{
    key: "test",
    value: function test(element) {
      // clipping is buggy in IE
      return manglers_get(manglers_getPrototypeOf(TableUpdater.prototype), "test", this).call(this, element) && !(Browser.ie || Browser.edge) && element.offsetHeight >= this.layout.height * 0.75;
    }
  }, {
    key: "stylesheet",
    value: function stylesheet() {
      return {
        'table.cozy-mangled-clipped': {
          'break-inside': 'avoid',
          'width': "".concat(this.layout.columnWidth * 0.95, "px !important"),
          'table-layout': 'fixed'
        },
        'table.cozy-mangled-clipped tbody': {
          'height': "".concat(this.layout.height * 0.25, "px !important"),
          overflow: 'scroll !important',
          display: 'block !important',
          position: 'relative !important',
          width: '100%'
        },
        'table.cozy-mangled-clipped thead': {
          overflow: 'scroll !important',
          display: 'block !important'
        },
        'table.cozy-mangled-clipped tr': {
          display: 'block !important'
        },
        'table.cozy-mangled-clipped::after': {
          content: "",
          display: 'block',
          "break": 'all'
        },
        '.cozy-mangled-popup-table--container': {
          position: 'absolute',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          top: '0px',
          bottom: '0px',
          right: '0px',
          left: '0px',
          'background-color': 'rgba(255, 255, 255, 0.75)'
        }
      };
    }
  }, {
    key: "update",
    value: function update(table) {
      var reader = this.reader;
      var contents = this.contents; // find a dang background color

      var element = table;
      var styles;
      var bgcolor;

      while (bgcolor === undefined && element instanceof HTMLElement) {
        styles = window.getComputedStyle(element);

        if (styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent') {
          bgcolor = styles.backgroundColor;
          break;
        }

        element = element.parentNode;
      }

      if (!bgcolor) {
        // no background color defined in the EPUB, so what is cozy-sun-bear using?
        element = reader._panes['epub'];

        while (bgcolor === undefined && element instanceof HTMLElement) {
          styles = window.getComputedStyle(element);

          if (styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent') {
            bgcolor = styles.backgroundColor;
            break;
          }

          element = element.parentNode;
        }
      }

      if (!bgcolor) {
        bgcolor = '#fff';
      }

      var tableHTML = table.outerHTML;
      table.classList.add('cozy-mangled-clipped');
      var div = document.createElement('div');
      div.classList.add('cozy-mangled-popup-table--container');
      table.querySelector('tbody').appendChild(div);
      var button = document.createElement('button');
      button.classList.add('cozy-mangled-popup--action');
      button.innerText = 'Open table';
      var tableId = table.getAttribute('data-id');

      if (!tableId) {
        var ts = new Date().getTime();
        tableId = "table" + ts + Math.random(ts);
        table.setAttribute('data-id', tableId);
      }

      reader._originalHTML[tableId] = tableHTML; // button.dataset.tableHTML = tableHTML;

      button.addEventListener('click', function (event) {
        event.preventDefault();
        var regex = /<body[^>]+>/;

        var index0 = contents._originalHTML.search(regex);

        var tableHTML = reader._originalHTML[tableId];
        var newHTML = contents._originalHTML.substr(0, index0) + "<body style=\"padding: 1.5rem; background: ".concat(bgcolor, "\"><section>").concat(tableHTML, "</section></body></html>");
        reader.popup({
          title: 'View Table',
          srcdoc: newHTML,
          onLoad: function onLoad(contentDocument, modal) {
            // adpated from epub.js#replaceLinks --- need to catch _any_ link
            // to close the modal
            var base = contentDocument.querySelector("base");
            var location = base ? base.getAttribute("href") : undefined;
            var links = contentDocument.querySelectorAll('a[href]');

            for (var i = 0; i < links.length; i++) {
              var link = links[i];
              var href = link.getAttribute('href');
              link.addEventListener('click', function (event) {
                modal.closeModal();
                var absolute = href.indexOf('://') > -1;

                if (absolute) {
                  link.setAttribute('target', '_blank');
                } else {
                  var linkUrl = new utils_url(href, location);

                  if (linkUrl) {
                    event.preventDefault();
                    reader.display(linkUrl.Path.path + (linkUrl.hash ? linkUrl.hash : ''));
                  }
                }
              });
            }
          }
        });
      });
      div.appendChild(button);
    }
  }]);

  return TableUpdater;
}(BaseUpdater);

var EnhancedFigureUpdater = /*#__PURE__*/function (_BaseUpdater2) {
  manglers_inherits(EnhancedFigureUpdater, _BaseUpdater2);

  var _super2 = manglers_createSuper(EnhancedFigureUpdater);

  function EnhancedFigureUpdater() {
    var _this2;

    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    manglers_classCallCheck(this, EnhancedFigureUpdater);

    _this2 = _super2.call(this, options);
    _this2.selector = '[data-resource-type]';
    return _this2;
  }

  manglers_createClass(EnhancedFigureUpdater, [{
    key: "stylesheet",
    value: function stylesheet() {
      return {
        '.cozy-mangled-popup-figure--container': {
          'text-align': 'center !important',
          'padding': '16px !important'
        }
      };
    }
  }, {
    key: "update",
    value: function update(element) {
      var button = document.createElement('button');
      button.classList.add('cozy-mangled-popup--action');
      button.innerText = "Open ".concat(element.dataset.resourceType.replace(/-/g, ' '));
      var div = document.createElement('div');
      div.classList.add('cozy-mangled-popup-figure--container');
      var target = element.querySelector('[data-resource-trigger]');

      if (target) {
        // parent.innerHTML = '';
        target.replaceWith(div);
      } else {
        element.appendChild(div);
      }

      var iframe_href = element.dataset.href;
      var iframe_title = element.dataset.title;
      div.appendChild(button);
      button.addEventListener('click', function (event) {
        event.preventDefault();
        reader.popup({
          title: 'View ' + iframe_title,
          href: iframe_href,
          onLoad: function onLoad(contentDocument, modal) {}
        });
      });
    }
  }]);

  return EnhancedFigureUpdater;
}(BaseUpdater);

function handlePopups(reader, contents) {
  // var selectors = [ table_config.selector ];
  var updaters = []; // if ( _rendition.manager.layout.name == 'reflowable' && ! ( Browser.ie || Browser.edge ) ) {
  // }

  updaters.push(new TableUpdater({
    reader: reader,
    contents: contents
  }));
  updaters.push(new EnhancedFigureUpdater({
    reader: reader,
    contents: contents
  }));
  var selectors = [];
  updaters.forEach(function (updater) {
    selectors.push(updater.selector);
  });
  var elements = contents.document.querySelectorAll(selectors.join(','));
  var queue = [];

  for (var i = 0; i < elements.length; i++) {
    var element = elements[i];
    updaters.forEach(function (updater) {
      var check = true;

      if (!updater.test(element)) {
        return;
      }

      queue.push([element, updater]);
    });
  }

  if (!queue.length) {
    return;
  }

  contents.document.body.classList.add('cozy-mangled--enhanced');
  contents._originalHTML = contents.document.documentElement.outerHTML;
  contents._initialized = {};
  reader._originalHTML = reader._originalHTML || {};
  contents.addStylesheetRules({
    '.cozy-mangled-popup--action': {
      cursor: 'pointer',
      'background-color': '#000000',
      color: '#ffffff',
      margin: '2px 0',
      border: '1px solid transparent',
      'border-radius': '4px',
      'box-shadow': '0 0 0 2px #ddd, 0px 0px 0px 4px #666',
      padding: '1rem 1rem',
      'text-transform': 'uppercase'
    },
    '.cozy-mangled-popup--action:active': {
      transform: 'translateY(1px)',
      filter: 'saturate(150%)'
    },
    '.cozy-mangled-popup--action:hover, .cozy-mangled-popup--action:focus': {
      color: '#000000',
      'border-color': 'currentColor',
      'background-color': 'white'
    }
  });
  var initialized = {};
  queue.forEach(function (_ref) {
    var _ref2 = manglers_slicedToArray(_ref, 2),
        element = _ref2[0],
        updater = _ref2[1];

    if (!initialized[updater.selector]) {
      contents.addStylesheetRules(updater.stylesheet());
    }

    updater.update(element);
  });
}
;// CONCATENATED MODULE: ./src/utils/focus.js
function _createForOfIteratorHelper(o, allowArrayLike) { var it; if (typeof Symbol === "undefined" || o[Symbol.iterator] == null) { if (Array.isArray(o) || (it = focus_unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = o[Symbol.iterator](); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }

function focus_unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return focus_arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return focus_arrayLikeToArray(o, minLen); }

function focus_arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var INTERACTIVE = {};
INTERACTIVE['A'] = true;
INTERACTIVE['SELECT'] = true;
INTERACTIVE['BUTTON'] = true;
INTERACTIVE['INPUT'] = true;
var installedResizeHandler = false;

function isInteractive(node) {
  if (INTERACTIVE[node.nodeName]) {
    // possibly...
    if (node.nodeName == 'A') {
      return node.hasAttribute('href');
    }

    return true;
  }

  return false;
}

function hideEverythingInContents(contents) {
  var elements = contents.document.querySelectorAll('body *');

  for (var i = 0; i < elements.length; i++) {
    if (elements[i].nodeType == Node.ELEMENT_NODE) {
      var element = elements[i];
      element.setAttribute('aria-hidden', true);
      element.setAttribute('tabindex', '-1');
    }
  }
}

function hideEverythingVisible(contents) {
  var elements = contents.document.querySelectorAll('[aria-hidden="false"]');

  for (var i = 0; i < elements.length; i++) {
    if (elements[i].nodeType == Node.ELEMENT_NODE) {
      elements[i].setAttribute('aria-hidden', true);

      if (INTERACTIVE[elements[i].nodeName]) {
        elements[i].setAttribute('tabindex', '-1');
      }
    }
  }
}

function findMatchingContents(contents, cfi) {
  var _iterator2 = _createForOfIteratorHelper(contents),
      _step;

  try {
    for (_iterator2.s(); !(_step = _iterator2.n()).done;) {
      var content = _step.value;

      if (cfi.indexOf(content.cfiBase) > -1) {
        return content;
      }
    }
  } catch (err) {
    _iterator2.e(err);
  } finally {
    _iterator2.f();
  }

  return null; // ???
}

function showEverythingVisible(container, range) {
  var selfOrElement = function selfOrElement(node) {
    return node.nodeType == Node.TEXT_NODE ? node.parentNode : node;
  };

  var showNode = function showNode(node) {
    node.setAttribute('aria-hidden', false);

    if (INTERACTIVE[node.nodeName]) {
      var bounds = node.getBoundingClientRect();
      var x = bounds.x;
      var x2 = x + container.scrollLeft; // console.log("AHOY NODE BOUNDS", node, x, x2,
      //   "A",
      //   x > container.scrollLeft + container.offsetWidth,
      //   x < container.scrollLeft,
      //   "B",
      //   x2 > container.scrollLeft + container.offsetWidth,
      //   x2 < container.scrollLeft
      //   )

      if (x > container.scrollLeft + container.offsetWidth || x < container.scrollLeft) {} else {
        node.setAttribute('tabindex', 0);
        node.addEventListener('focus', function (event) {
          // console.log("AHOY FOCUS", node, container.scrollLeft, container.dataset.scrollLeft);
          var scrollLeft = parseInt(container.dataset.scrollLeft, 10);
          setTimeout(function () {
            container.scrollLeft = scrollLeft;
          }, 0);
        });
      }
    } // node.setAttribute('tabindex', 0);


    var _iterator3 = _createForOfIteratorHelper(node.children),
        _step2;

    try {
      for (_iterator3.s(); !(_step2 = _iterator3.n()).done;) {
        var child = _step2.value;
        showNode(child);
      }
    } catch (err) {
      _iterator3.e(err);
    } finally {
      _iterator3.f();
    }
  };

  var showNodeAndSelf = function showNodeAndSelf(node) {
    if (node.getAttribute('aria-hidden') == 'true') {
      showNode(node);
      var parent = node.parentNode;

      while (parent != node.ownerDocument.body) {
        // console.log("AHOY ACTIVATING UP", parent);
        parent.setAttribute('aria-hidden', false); //node.setAttribute('tabindex', 0);

        parent = parent.parentNode;
      }
    }
  };

  var ancestor = selfOrElement(range.commonAncestorContainer);
  var startContainer = selfOrElement(range.startContainer);
  var endContainer = selfOrElement(range.endContainer);

  var _iterator = document.createNodeIterator(ancestor, NodeFilter.SHOW_ALL, {
    acceptNode: function acceptNode(node) {
      return NodeFilter.FILTER_ACCEPT;
    }
  });

  var _nodes = [];

  while (_iterator.nextNode()) {
    // console.log("AHOY ITERATOR", _nodes.length, _iterator.referenceNode, startContainer, _iterator.referenceNode !== startContainer);
    if (_nodes.length === 0 && _iterator.referenceNode !== startContainer) continue;

    _nodes.push(_iterator.referenceNode);

    if (_iterator.referenceNode === endContainer) break;
  } // console.log("AHOY NODES", _nodes, _nodes[0] == startContainer);


  if (_nodes.length == 1 && _nodes[0] == startContainer) {
    _nodes.pop();

    var _iterator4 = _createForOfIteratorHelper(startContainer.children),
        _step3;

    try {
      for (_iterator4.s(); !(_step3 = _iterator4.n()).done;) {
        var child = _step3.value;

        _nodes.push(child);
      }
    } catch (err) {
      _iterator4.e(err);
    } finally {
      _iterator4.f();
    }
  }

  _nodes.forEach(function (node) {
    if (node.nodeType == Node.ELEMENT_NODE) {
      showNodeAndSelf(node);
    } else {
      showNodeAndSelf(node.parentNode);
    }
  });
}

function updateFocus(reader, location) {
  if (reader.settings.flow == 'scrolled-doc') {
    return;
  }

  if (reader.options.disableFocusHandling) {
    return;
  }

  setTimeout(function () {
    if (location.start.cfi == reader._last_location_start_cfi && location.end.cfi == reader._last_location_end_cfi) {
      return;
    }

    reader._last_location_start_cfi = location.start.cfi;
    reader._last_location_end_cfi = location.end.cfi;

    __updateFocus(reader, location);
  }, 0);
  reader._last_location_start = location.start.href;
}
var elemsWithBoundingRects = [];

var getBoundingClientRect = function getBoundingClientRect(element) {
  if (!element._boundingClientRect) {
    // If not, get it then store it for future use.
    element._boundingClientRect = element.getBoundingClientRect();
    elemsWithBoundingRects.push(element);
  }

  return element._boundingClientRect;
};

var clearClientRects = function clearClientRects() {
  var i;

  for (i = 0; i < elemsWithBoundingRects.length; i++) {
    if (elemsWithBoundingRects[i]) {
      elemsWithBoundingRects[i]._boundingClientRect = null;
    }
  }

  elemsWithBoundingRects = [];
};

function __updateFocus(reader, location) {
  // don't use location
  var selfOrElement = function selfOrElement(node) {
    return node.nodeType == Node.TEXT_NODE ? node.parentNode : node;
  };

  var container = reader._rendition.manager.container;
  var contents = findMatchingContents(reader._rendition.manager.getContents(), location.start.cfi);
  hideEverythingVisible(contents);
  var containerX = container.scrollLeft;
  var containerX2 = container.scrollLeft + container.offsetWidth;

  var _showThisNode = function _showThisNode(node) {
    var bounds = getBoundingClientRect(node); // node.getBoundingClientRect();

    var x = bounds.left;
    var x2 = bounds.left + bounds.width;
    var isVisible = false;

    if (x <= containerX && x2 >= containerX2) {
      isVisible = true;
    } else if (x >= containerX && x < containerX2) {
      isVisible = true;
    } else if (x2 > containerX && x2 <= containerX2) {
      isVisible = true;
    } // else if ( x <= containerX && x2 <= containerX2 ) { isVisible = true; }
    // else if ( x >= containerX && x2 <= containerX2 ) { isVisible = true; }
    // else if ( x >= containerX && x2 > containerX2 ) { isVisible = true; }


    if (isVisible) {
      // console.log("AHOY", isVisible, node, bounds, containerX, containerX2);
      node.setAttribute('aria-hidden', 'false');

      if (isInteractive(node)) {
        node.setAttribute('tabindex', '0');
      }

      var hasSeenVisibleChild = false;

      var _iterator5 = _createForOfIteratorHelper(node.children),
          _step4;

      try {
        for (_iterator5.s(); !(_step4 = _iterator5.n()).done;) {
          var child = _step4.value;

          var retval = _showThisNode(child);

          if (retval) {
            hasSeenVisibleChild = true;
          }

          if (!retval && hasSeenVisibleChild) {
            break;
          }
        }
      } catch (err) {
        _iterator5.e(err);
      } finally {
        _iterator5.f();
      }
    }

    return isVisible;
  };

  var startRange = new ePub.CFI(location.start.cfi).toRange(contents.document);
  var startNode = selfOrElement(startRange.startContainer);
  var _nodes = [];
  var checkNode = startNode;

  while (checkNode != contents.document.body) {
    var bounds = getBoundingClientRect(checkNode); // checkNode.getBoundingClientRect();

    var x = bounds.left;
    var x2 = bounds.left + bounds.width;
    var isVisible = false; // if ( x <= containerX && x2 >= containerX2 ) { isVisible = true; }

    if (x >= containerX && x < containerX2) {
      isVisible = true;
    } else if (x2 > containerX && x2 <= containerX2) {
      isVisible = true;
    }

    if (isVisible) {
      startNode = checkNode;
      checkNode = checkNode.parentNode;
    } else {
      break;
    }
  }

  var parentNode = startNode; // .parentNode;

  while (parentNode != contents.document.body) {
    parentNode.setAttribute('aria-hidden', false);
    parentNode = parentNode.parentNode;
  }

  _showThisNode(startNode);

  var children = startNode.parentNode.children;
  var doProcess = false;

  var _iterator6 = _createForOfIteratorHelper(children),
      _step5;

  try {
    for (_iterator6.s(); !(_step5 = _iterator6.n()).done;) {
      var nextNode = _step5.value;

      if (nextNode == startNode) {
        doProcess = true;
      } else if (doProcess) {
        var isVisible = _showThisNode(nextNode);

        if (!isVisible) {
          break;
        }
      }
    }
  } catch (err) {
    _iterator6.e(err);
  } finally {
    _iterator6.f();
  }

  if (reader.__target) {
    var possible = contents.document.querySelector("#".concat(reader.__target));

    if (possible && !reader.options.disableFocusTarget) {
      possible.focus();
      correct_drift(reader); // console.log("AHOY FOCUSING", reader.__target, possible);
    }

    reader.__target = null;
  }
}

var _checkLayout = function _checkLayout(reader) {
  var scrollLeft = reader._manager.container.scrollLeft;
  var mod = scrollLeft % parseInt(reader._manager.layout.delta, 10); // console.log("AHOY checkLayout", scrollLeft, reader._manager.layout.delta, mod);

  return mod;
};

var correct_drift = function correct_drift(reader) {
  var data = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var container = reader._rendition.manager.container;
  var mod;
  var delta;
  var x;
  var xyz;
  setTimeout(function () {
    var scrollLeft = container.scrollLeft; // mod = scrollLeft % parseInt(reader._rendition.manager.layout.delta, 10);

    mod = _checkLayout(reader); // console.log("AHOY AHOY keyDown TRAP", mod, mod / reader._rendition.manager.layout.delta,( mod / reader._rendition.manager.layout.delta ) < 0.99 );

    if (mod > 0 && mod / reader._rendition.manager.layout.delta < 0.99) {
      x = Math.floor(container.scrollLeft / parseInt(reader._rendition.manager.layout.delta, 10));

      if (data.shiftKey) {
        x -= 0;
      } else {
        x += 1;
      }

      var y = container.scrollLeft;
      delta = x * reader._rendition.manager.layout.delta - y;
      xyz = x * reader._rendition.manager.layout.delta; // console.log("AHOY AHOY keyDown SHIFT", mod, reader._rendition.manager.layout.delta, x, delta);

      reader._rendition.manager.scrollBy(delta);
    }
  }, 0);
};

function setupFocusRules(reader) {
  if (!installedResizeHandler) {
    installedResizeHandler = true;
    reader.on('resize', function () {
      clearClientRects();
    });
  }

  var contents = reader._rendition.getContents();

  contents.forEach(function (content) {
    if (reader.options.debugFocusHandling) {
      content.addStylesheetRules({
        '[aria-hidden="true"]': {
          'opacity': '0.25 !important'
        },
        ':focus': {
          'outline': '2px solid goldenrod',
          'padding': '4px',
          'background': 'lightgoldenrodyellow'
        }
      });
    }

    hideEverythingInContents(content); // --- attempts to heal safari/edge

    content.document.addEventListener('keydown', function (event) {
      if (event.keyCode == 9) {
        var activeElement = content.document.activeElement;

        if (activeElement) {
          reader._manager.container.dataset.scrollLeft = reader._manager.container.scrollLeft;
        } else {
          reader._manager.container.dataset.scrollLeft = 0;
        }
      }
    }); // --- capture internal link clicks?

    content.on('linkClicked', function (href) {
      if (href.indexOf('#') > -1) {
        reader.__target = href.split('#')[1];
      }
    });
  });

  var __watchInterval;

  reader._watchLayout = function () {
    var delta = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 1000;

    if (__watchInterval) {
      clearInterval(__watchInterval);
      return;
    }

    __watchInterval = setInterval(function () {
      return reader._checkLayout(reader);
    }, delta);
  };

  reader.on('keyDown', function (data) {
    reader._manager.container.dataset.scrollLeft = reader._manager.container.scrollLeft;
    correct_drift(reader, data);
  });
}
;// CONCATENATED MODULE: ./src/reader/Reader.EpubJS.js



window.ePub = src;











Reader/* Reader.EpubJS */.E.EpubJS = Reader/* Reader.extend */.E.extend({
  initialize: function initialize(id, options) {
    Reader/* Reader.prototype.initialize.apply */.E.prototype.initialize.apply(this, arguments);
    this._epubjs_ready = false;
    window.xpath = (path_default());
  },
  open: function open(target, callback) {
    var self = this;

    if (typeof target == 'function') {
      callback = target;
      target = undefined;
    }

    if (callback == null) {
      callback = function callback() {};
    }

    self.rootfiles = [];
    this.options.rootfilePath = this.options.rootfilePath || sessionStorage.getItem('rootfilePath');
    var book_href = this.options.href;
    var book_options = {
      packagePath: this.options.rootfilePath
    };

    if (this.options.useArchive) {
      book_href = book_href.replace(/\/(\w+)\/$/, '/$1/$1.sm.epub');
      book_options.openAs = 'epub';
    }

    this._book = src(book_href, book_options);
    sessionStorage.removeItem('rootfilePath');

    this._book.loaded.navigation.then(function (toc) {
      self._contents = toc;
      self.metadata = self._book.packaging.metadata;
      self.fire('updateContents', toc);
      self.fire('updateTitle', self._book.packaging.metadata);
    });

    this._book.ready.then(function () {
      self.parseRootfiles();
      self.draw(target, callback);

      if (self.metadata.layout == 'pre-paginated') {
        // fake it with the spine
        var locations = [];

        self._book.spine.each(function (item) {
          locations.push("epubcfi(".concat(item.cfiBase, "!/4/2)"));

          self.locations._locations.push("epubcfi(".concat(item.cfiBase, "!/4/2)"));
        });

        self.locations.total = locations.length;
        var t;

        var f = function f() {
          if (self._rendition && self._rendition.manager && self._rendition.manager.stage) {
            var location = self._rendition.currentLocation();

            if (location && location.start) {
              self.fire('updateLocations', locations);
              clearTimeout(t);
              return;
            }
          }

          t = setTimeout(f, 100);
        };

        t = setTimeout(f, 100);
      } else if (self._book.pageList && self._book.pageList.pageList.length && !self._book.pageList.locations.length) {
        self._book.locations.generateFromPageList(self._book.pageList).then(function (locations) {
          self.fire('updateLocations', locations);
        });
      } else {
        self._book.locations.generate(1600).then(function (locations) {
          self.fire('updateLocations', locations);
        });
      }
    }); // .then(callback);

  },
  parseRootfiles: function parseRootfiles() {
    var self = this;

    self._book.load(self._book.url.resolve("META-INF/container.xml")).then(function (containerDoc) {
      var rootfiles = containerDoc.querySelectorAll("rootfile");

      if (rootfiles.length > 1) {
        for (var i = 0; i < rootfiles.length; i++) {
          var rootfile = rootfiles[i];
          var rootfilePath = rootfile.getAttribute('full-path');
          var label = rootfile.getAttribute('rendition:label');
          var layout = rootfile.getAttribute('rendition:layout');
          self.rootfiles.push({
            rootfilePath: rootfilePath,
            label: label,
            layout: layout
          });
        }
      }
    });
  },
  draw: function draw(target, callback) {
    var self = this;

    if (self._rendition && !self._rendition.draft) {
      // self._unbindEvents();
      var container = self._rendition.manager.container;
      Object.keys(self._rendition.hooks).forEach(function (key) {
        self._rendition.hooks[key].clear();
      });

      self._rendition.destroy();

      self._rendition = null;
    }

    var key = self.metadata.layout || 'reflowable';
    var flow = this.options.flow;

    if (self._cozyOptions[key] && self._cozyOptions[key].flow) {
      flow = self._cozyOptions[key].flow;
      this.options.flow = flow; // restore from stored preferences
    }

    if (flow == 'auto') {
      if (this.metadata.layout == 'pre-paginated') {
        if (this._container.offsetHeight <= this.options.forceScrolledDocHeight) {
          flow = 'scrolled-doc';
        }
      } else {
        // flow = 'paginated';
        flow = this.metadata.flow || 'auto';
      }
    } // if ( flow == 'auto' && this.metadata.layout == 'pre-paginated' ) {
    //   if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ){
    //     flow = 'scrolled-doc';
    //   }
    // }
    // var key = `${flow}/${self.metadata.layout}`;


    if (self._cozyOptions[key]) {
      if (self._cozyOptions[key].text_size) {
        self.options.text_size = self._cozyOptions[key].text_size;
      }

      if (self._cozyOptions[key].scale) {
        self.options.scale = self._cozyOptions[key].scale;
      }
    }

    this.settings = {
      flow: flow,
      stylesheet: this.options.injectStylesheet
    };
    this.settings.manager = this.options.manager || 'default'; // if ( this.settings.flow == 'auto' && this.metadata.layout == 'pre-paginated' ) {
    //   // dumb check to see if the window is _tall_ enough to put
    //   // two pages side by side
    //   if ( this._container.offsetHeight <= this.options.forceScrolledDocHeight ) {
    //     this.settings.flow = 'scrolled-doc';
    //     // this.settings.manager = PrePaginatedContinuousViewManager;
    //     // this.settings.view = ReusableIframeView;
    //     this.settings.manager = ScrollingContinuousViewManager;
    //     this.settings.view = StickyIframeView;
    //     this.settings.width = '100%'; // 100%?
    //     this.settings.spine = this._book.spine;
    //   }
    // }

    if (this.settings.flow == 'auto' || this.settings.flow == 'paginated') {
      this._panes['epub'].style.overflow = this.metadata.layout == 'pre-paginated' ? 'auto' : 'hidden';
      this.settings.manager = 'default';
    } else {
      this._panes['epub'].style.overflow = 'auto';

      if (this.settings.manager == 'default') {
        // this.settings.manager = 'continuous';
        this.settings.manager = scrolling;
        this.settings.view = sticky;
        this.settings.width = '100%'; // 100%?

        this.settings.spine = this._book.spine;
      }
    }

    if (!callback) {
      callback = function callback() {};
    }

    self.settings.height = '100%';
    self.settings.width = '100%';
    self.settings['ignoreClass'] = 'annotator-hl';

    if (this.metadata.layout == 'pre-paginated' && this.settings.manager == 'continuous') {
      // this.settings.manager = 'prepaginated';
      // this.settings.manager = PrePaginatedContinuousViewManager;
      // this.settings.view = ReusableIframeView;
      this.settings.manager = scrolling;
      this.settings.view = sticky;
      this.settings.spread = 'none';
    }

    if (this.settings.manager == scrolling) {
      if (this.metadata.layout != 'pre-paginated' && !this.options.minHeight) {
        this.options.minHeight = this._panes['book'].offsetHeight * 0.75;
      }

      if (this.options.minHeight) {
        this.settings.minHeight = this.options.minHeight;
      }
    }

    if (self.options.scale != '100') {
      self.settings.scale = parseInt(self.options.scale, 10) / 100;
    }

    self._panes['book'].dataset.manager = this.settings.manager + (this.settings.spread ? "-".concat(this.settings.spread) : '');
    self._panes['book'].dataset.layout = this.metadata.layout || 'reflowable';

    self._drawRendition(target, callback);
  },
  _drawRendition: function _drawRendition(target, callback) {
    var self = this; // self._rendition = self._book.renderTo(self._panes['epub'], self.settings);

    self.rendition = new src.Rendition(self._book, self.settings);
    self._book.rendition = self._rendition;
    this._rendition.settings.prehooks = {};
    this._rendition.settings.prehooks.head = new hook(this);

    self._updateFontSize();

    self._rendition.attachTo(self._panes['epub']);

    self._bindEvents();

    self._drawn = true;

    if (target && target.start) {
      target = target.start;
    }

    if (!target && window.location.hash) {
      if (window.location.hash.substr(1, 3) == '/6/') {
        var original_target = window.location.hash.substr(1);
        target = decodeURIComponent(window.location.hash.substr(1));
        target = "epubcfi(" + target + ")";
      } else {
        target = window.location.hash.substr(2);
        target = self._book.url.path().resolve(decodeURIComponent(target));
      }
    }

    var status_index = 0;

    self._rendition.on('started', function () {
      self._manager = self._rendition.manager;

      self._rendition.manager.on("building", function (status) {
        if (status) {
          status_index += 1;
          self._panes['loader-status'].innerHTML = "<span>".concat(Math.round(status_index / status.total * 100.0), "%</span>");
        } else {
          self._enableBookLoader(-1);
        }
      });

      self._rendition.manager.on("built", function () {
        self._disableBookLoader(true);
      });

      self.fire('renditionStarted', self._rendition);
    });

    self._rendition.hooks.content.register(function (contents) {
      self.fire('ready:contents', contents);
      self.fire('readyContents', contents); // check for tables + columns + popups

      if (self._rendition.manager.layout.name == 'reflowable') {
        handlePopups(self, contents);
      }
    });

    self.display(target, function () {
      window._loaded = true;

      self._initializeReaderStyles();

      if (callback) {
        callback();
      }

      self._epubjs_ready = true;
      self.display(target, function () {
        setTimeout(function () {
          self.fire('opened');
          self.fire('ready');

          self._disableBookLoader();

          clearTimeout(self._queueTimeout);
          self.tracking.event("openBook", {
            rootFilePath: self.options.rootFilePath,
            flow: self.settings.flow,
            manager: self.settings.manager
          });
        }, 100);
      });
    });
  },
  _scroll: function _scroll(delta) {
    var self = this;

    if (self.options.flow == 'XXscrolled-doc') {
      var container = self._rendition.manager.container;
      var rect = container.getBoundingClientRect();
      var scrollTop = container.scrollTop;
      var newScrollTop = scrollTop;
      var scrollBy = rect.height * 0.98;

      switch (delta) {
        case 'PREV':
          newScrollTop = -(scrollTop + scrollBy);
          break;

        case 'NEXT':
          newScrollTop = scrollTop + scrollBy;
          break;

        case 'HOME':
          newScrollTop = 0;
          break;

        case 'END':
          newScrollTop = container.scrollHeight - scrollBy;
          break;
      }

      container.scrollTop = newScrollTop;
      return Math.floor(container.scrollTop) != Math.floor(scrollTop);
    }

    return false;
  },
  _navigate: function _navigate(promise, callback) {
    var self = this;

    self._enableBookLoader(100);

    promise.then(function () {
      self._disableBookLoader();

      if (callback) {
        callback();
      }
    })["catch"](function (e) {
      self._disableBookLoader();

      if (callback) {
        callback();
      }

      console.log("AHOY NAVIGATE ERROR", e);
      throw e;
    });
  },
  next: function next() {
    var self = this;
    this.tracking.action('reader/go/next');
    self._scroll('NEXT') || self._navigate(this._rendition.next());
  },
  prev: function prev() {
    this.tracking.action('reader/go/previous');
    this._scroll('PREV') || this._navigate(this._rendition.prev());
  },
  first: function first() {
    this.tracking.action('reader/go/first');

    this._navigate(this._rendition.display(0), undefined);
  },
  last: function last() {
    var self = this;
    this.tracking.action('reader/go/last');
    var target = this._book.spine.length - 1;

    this._navigate(this._rendition.display(target), undefined);
  },
  display: function display(target, callback) {
    var self = this;
    var hash;

    if (target != null) {
      var section = this._book.spine.get(target);

      if (!section) {
        // maybe it needs to be resolved
        var guessed = target;

        if (guessed.indexOf("://") < 0) {
          var path1 = path_default().resolve(this._book.path.directory, this._book.packaging.navPath);
          var path2 = path_default().resolve(path_default().dirname(path1), target);
          guessed = this._book.canonical(path2);
        }

        if (guessed.indexOf("#") !== 0) {
          hash = guessed.split('#')[1];
          guessed = guessed.split('#')[0];
        }

        this._book.spine.each(function (item) {
          if (item.canonical == guessed) {
            section = item;
            target = section.href;
            return;
          }
        });

        if (hash) {
          target = target + '#' + hash;
        } // console.log("AHOY GUESSED", target);

      } else if (target.toString().match(/^\d+$/)) {
        // console.log("AHOY USING", section.href);
        target = section.href;
      }

      if (!section) {
        if (!this._epubjs_ready) {
          target = 0;
        } else {
          return;
        }
      }
    }

    self.tracking.reset();

    var navigating = this._rendition.display(target).then(function () {
      this._rendition.display(target);
    }.bind(this));

    this._navigate(navigating, callback);
  },
  gotoPage: function gotoPage(target, callback) {
    return this.display(target, callback);
  },
  percentageFromCfi: function percentageFromCfi(cfi) {
    return this._book.percentageFromCfi(cfi);
  },
  destroy: function destroy() {
    if (this._rendition) {
      try {
        this._rendition.destroy();
      } catch (e) {}
    }

    this._rendition = null;
    this._drawn = false;
  },
  reopen: function reopen(options, target) {
    // different per reader?
    var target = target || this.currentLocation();

    if (target.start) {
      target = target.start;
    }

    if (target.cfi) {
      target = target.cfi;
    }

    var doUpdate = false;

    if (options === true) {
      doUpdate = true;
      options = {};
    }

    var changed = {};
    Object.keys(options).forEach(function (key) {
      if (options[key] != this.options[key]) {
        doUpdate = true;
        changed[key] = true;
      } // doUpdate = doUpdate || ( options[key] != this.options[key] );

    }.bind(this));

    if (!doUpdate) {
      return;
    } // performance hack


    if (Object.keys(changed).length == 1 && changed.scale) {
      this.options.scale = options.scale;

      this._updateScale();

      return;
    }

    if (options.rootfilePath && options.rootfilePath != this.options.rootfilePath) {
      // we need to REOPEN THE DANG BOOK
      sessionStorage.setItem('rootfilePath', options.rootfilePath);
      location.reload();
      return;
    }

    Util.extend(this.options, options);
    this.draw(target, function () {
      // this._updateFontSize();
      this._updateScale();

      this._updateTheme();

      this._selectTheme(true);
    }.bind(this));
  },
  currentLocation: function currentLocation() {
    if (this._rendition && this._rendition.manager) {
      this._cached_location = this._rendition.currentLocation();
    }

    return this._cached_location;
  },
  _bindEvents: function _bindEvents() {
    var self = this; // add a stylesheet to stop images from breaking their columns

    var add_max_img_styles = false;

    if (this._book.packaging.metadata.layout == 'pre-paginated') {// NOOP
    } else if (this.options.flow == 'auto' || this.options.flow == 'paginated') {
      add_max_img_styles = true;
    }

    var custom_stylesheet_rules = []; // force 90% height instead of default 60%

    if (this.metadata.layout != 'pre-paginated') {
      if (this.options.flow == 'scrolled-doc') {
        // these prehooks are a hack to avoid the contents hooks applying _after_
        // the view has been displayed
        this._rendition.settings.prehooks.head.register(function (buffer) {
          var layout = this.layout;
          var retval = "\n<style>\nimg {\n  max-width: ".concat(layout.columnWidth ? layout.columnWidth + "px" : "100%", " !important;\n  max-height: ").concat(layout.height ? layout.height * 0.9 + "px" : "90%", " !important;\n  object-fit: contain;\n  page-break-inside: avoid;\n}\nsvg {\n  max-width: ").concat(layout.columnWidth ? layout.columnWidth + "px" : "100%", " !important;\n  max-height: ").concat(layout.height ? layout.height * 0.9 + "px" : "90%", " !important;\n  page-break-inside: avoid;\n}\nbody {\n  overflow: hidden;\n  column-rule: 1px solid #ddd;\n}\n</style>\n          ");
          buffer.push(retval);
        }.bind(this._rendition));
      } // --- KEEP THIS IN CASE WE HAVE TO REVERT THE PREHOOKS
      // this._rendition.hooks.content.register(function(contents) {
      //   contents.addStylesheetRules({
      //     "img" : {
      //       "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
      //       "max-height": (this._layout.height ? (this._layout.height * 0.9) + "px" : "90%") + "!important",
      //       "object-fit": "contain",
      //       "page-break-inside": "avoid"
      //     },
      //     "svg" : {
      //       "max-width": (this._layout.columnWidth ? this._layout.columnWidth + "px" : "100%") + "!important",
      //       "max-height": (this._layout.height ? (this._layout.height * 0.9) + "px" : "90%") + "!important",
      //       "page-break-inside": "avoid"
      //     },
      //     "body": {
      //       "overflow": "hidden",
      //       "column-rule": "1px solid #ddd"
      //     }
      //   });
      // }.bind(this._rendition))

    } else {
      this._rendition.hooks.content.register(function (contents) {
        contents.addStylesheetRules({
          "img": {
            // "border": "64px solid black !important",
            "box-sizing": "border-box !important"
          },
          "figure": {
            "box-sizing": "border-box !important",
            "margin": "0 !important"
          },
          "body": {
            "margin": "0",
            "overflow": "hidden"
          }
        });
      }.bind(this._rendition));
    }

    this._updateFontSize();

    if (custom_stylesheet_rules.length) {
      this._rendition.hooks.content.register(function (view) {
        view.addStylesheetRules(custom_stylesheet_rules);
      });
    }

    this._rendition.on('resized', function (box) {
      self.fire('resized', box);
    });

    this._rendition.on('click', function (event, contents) {
      if (event.isTrusted) {
        this.tracking.action("inline/go/link");
      }
    }.bind(this));

    this._rendition.on('keydown', function (event, contents) {
      var target = event.target;
      var IGNORE_TARGETS = ['input', 'textarea'];

      if (IGNORE_TARGETS.indexOf(target.localName) >= 0) {
        return;
      }

      this.fire('keyDown', {
        keyName: event.key,
        shiftKey: event.shiftKey,
        inner: true
      });
    }.bind(this));

    var relocated_handler = debounce_default()(function (location) {
      if (self._fired) {
        self._fired = false;
        return;
      }

      self.fire('relocated', location); // hideEverything/showEverything

      updateFocus(self, location);

      if (Browser.safari && self._last_location_start && self._last_location_start != location.start.href) {
        self._fired = true;
        setTimeout(function () {// self._rendition.display(location.start.cfi);
        }, 0);
      }
    }, 10);

    this._rendition.on('relocated', relocated_handler);

    this._rendition.on('displayerror', function (err) {
      console.log("AHOY RENDITION DISPLAY ERROR", err);
      self.fire('displayerror', err);
    });

    var locationChanged_handler = debounce_default()(function (location) {
      var view = this.manager.current();

      if (!view) {
        return;
      }

      var section = view.section;
      var current = this.book.navigation.get(section.href);
      self.fire("updateSection", current);
      self.fire("updateLocation", location);
    }, 150);

    this._rendition.on("locationChanged", locationChanged_handler);

    this.on('updateLocations', function () {
      // trigger this when all the locations have been loaded from the spine
      this._rendition.emit('relocated', this._rendition.currentLocation());
    });

    this._rendition.on("rendered", function (section, view) {
      self._updateFrameTitle(section, view);
    });

    this._rendition.on("rendered", function (section, view) {
      if (self.settings.flow == 'scrolled-doc') {
        return;
      }

      if (Browser.ie) {
        self.options.disableFocusHandling = true;
        return;
      } // add focus rules


      setupFocusRules(self);
    });
  },
  _initializeReaderStyles: function _initializeReaderStyles() {
    var self = this;
    var themes = this.options.themes;

    if (themes) {
      themes.forEach(function (theme) {
        self._rendition.themes.register(theme['klass'], theme.href ? theme.href : theme.rules);
      });
    } // base for highlights
    // this._rendition.themes.override('.epubjs-hl', "fill: yellow; fill-opacity: 0.3; mix-blend-mode: multiply;");

  },
  _selectTheme: function _selectTheme(refresh) {
    var theme = this.options.theme || 'default';

    this._rendition.themes.select(theme);
  },
  _updateFontSize: function _updateFontSize() {
    if (false) {}

    var text_size = this.options.text_size || 100; // this.options.modes[this.flow].text_size; // this.options.text_size == 'auto' ? 100 : this.options.text_size;

    if (text_size == 100) {
      // do not add an unncessary override
      if (!this._rendition.themes._overrides['font-size']) {
        return;
      }
    }

    this._rendition.themes.fontSize("".concat(text_size, "%")); // --- prehook avoids jitter but cannot be readily replaced
    // --- TODO: if this is the first font-size setting could use prehook
    // --- else: use `themes.fontSize`
    // this._rendition.settings.prehooks.head.register(function(buffer) {
    //   buffer.push(`<style>body { font-size: ${text_size}%; }</style>`);
    // })

  },
  _updateScale: function _updateScale() {
    if (this.metadata.layout != 'pre-paginated') {
      // we're not scaling for reflowable
      return;
    } // var scale = this.options.modes[this.flow].scale;


    var scale = this.options.scale;

    if (scale) {
      this.settings.scale = parseInt(scale, 10) / 100.0;

      this._queueScale();
    }
  },
  _queueScale: function _queueScale(scale) {
    this._queueTimeout = setTimeout(function () {
      if (this._rendition.manager && this._rendition.manager.stage) {
        this._rendition.scale(this.settings.scale);

        var text_size = this.settings.scale == 1.0 ? 100 : this.settings.scale * 100.0;

        this._rendition.themes.fontSize("".concat(text_size, "%"));
      } else {
        this._queueScale();
      }
    }.bind(this), 100);
  },
  _updateFrameTitle: function _updateFrameTitle(section, view) {
    var self = this;
    var title = "Section ".concat(section.index + 1);

    var current = self._book.navigation && self._book.navigation.get(section.href);

    if (!current) {
      var subtitle;

      for (var _i = 0, _arr = ['h1', 'h2']; _i < _arr.length; _i++) {
        var tag = _arr[_i];
        var tmp = view.document.querySelectorAll(tag);

        if (tmp) {
          var buffer = [];

          for (var i = 0; i < tmp.length; i++) {
            buffer.push(tmp[i].innerText);

            if (tag == 'h2') {
              break;
            } // only one of these

          }

          subtitle = buffer.join(' - ');
          break;
        }
      }

      if (!subtitle) {
        for (var i = section.index; i >= 0; i--) {
          var previousSection = self._book.spine.get(i);

          var previous = self._book.navigation.get(previousSection.href);

          if (previous) {
            subtitle = previous.label;
            break;
          }
        }
      }

      if (subtitle) {
        title += ': ' + subtitle;
      }
    } else {
      title += ': ' + current.label;
    }

    if (title && view.iframe) {
      view.iframe.title = "Contents: ".concat(title);
    } // Ugly hijack to enable hotjar HELIO-4198
    // turning off hotjar in this experimental version of csb
    // view.iframe.setAttribute("data-hj-allow-iframe", "true");

  },
  EOT: true
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'metadata', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },
  set: function set(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'annotations', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    if (Browser.ie) {
      return {
        reset: function reset() {
          /* NOOP */
        },
        highlight: function highlight(cfiRange) {
          /* NOOP */
        }
      };
    }

    if (!this._rendition.annotations.reset) {
      this._rendition.annotations.reset = function () {
        for (var hash in this._annotations) {
          var cfiRange = decodeURI(hash);
          this.remove(cfiRange);
        }

        this._annotationsBySectionIndex = {};
      }.bind(this._rendition.annotations);
    }

    return this._rendition.annotations;
  }
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'locations', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this._book.locations;
  }
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'pageList', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this._book.pageList.pageList.length > 0 ? this._book.pageList : undefined;
  }
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'rendition', {
  get: function get() {
    if (!this._rendition) {
      this._rendition = {
        draft: true
      };
      this._rendition.hooks = {};
      this._rendition.hooks.content = new hook(this);
    }

    return this._rendition;
  },
  set: function set(rendition) {
    if (this._rendition && this._rendition.draft) {
      var hook = this._rendition.hooks.content;
      hook.hooks.forEach(function (fn) {
        rendition.hooks.content.register(fn);
      });
    }

    this._rendition = rendition;
  }
});
Object.defineProperty(Reader/* Reader.EpubJS.prototype */.E.EpubJS.prototype, 'CFI', {
  get: function get() {
    return src.CFI;
  }
});
window.Reader = Reader/* Reader */.E;
function createReader(id, options) {
  return new Reader/* Reader.EpubJS */.E.EpubJS(id, options);
}
;// CONCATENATED MODULE: ./src/reader/Reader.Mock.js



Reader/* Reader.Mock */.E.Mock = Reader/* Reader.extend */.E.extend({
  initialize: function initialize(id, options) {
    Reader/* Reader.prototype.initialize.apply */.E.prototype.initialize.apply(this, arguments);
  },
  open: function open(target, callback) {
    var self = this;
    this._book = {
      metadata: {
        title: 'The Mock Life',
        creator: 'Alex Mock',
        publisher: 'University Press',
        location: 'Ann Arbor, MI',
        pubdate: '2017-05-23'
      },
      contents: {
        toc: [{
          id: 1,
          href: "/epubs/mock/ops/xhtml/TitlePage.xhtml",
          label: "Title",
          parent: null
        }, {
          id: 2,
          href: "/epubs/mock/ops/xhtml/Chapter01.xhtml",
          label: "Chapter 1",
          parent: null
        }, {
          id: 3,
          href: "/epubs/mock/ops/xhtml/Chapter02.xhtml",
          label: "Chapter 2",
          parent: null
        }, {
          id: 4,
          href: "/epubs/mock/ops/xhtml/Chapter03.xhtml",
          label: "Chapter 3",
          parent: null
        }, {
          id: 5,
          href: "/epubs/mock/ops/xhtml/Chapter04.xhtml",
          label: "Chapter 4",
          parent: null
        }, {
          id: 6,
          href: "/epubs/mock/ops/xhtml/Chapter05.xhtml",
          label: "Chapter 5",
          parent: null
        }, {
          id: 7,
          href: "/epubs/mock/ops/xhtml/Chapter06.xhtml",
          label: "Chapter 6",
          parent: null
        }, {
          id: 8,
          href: "/epubs/mock/ops/xhtml/Chapter07.xhtml",
          label: "Chapter 7",
          parent: null
        }, {
          id: 9,
          href: "/epubs/mock/ops/xhtml/Index.xhtml",
          label: "Index",
          parent: null
        }]
      }
    };
    this._locations = ['epubcfi(/6/4[TitlePage.xhtml])', 'epubcfi(/6/4[Chapter01.xhtml])', 'epubcfi(/6/4[Chapter02.xhtml])', 'epubcfi(/6/4[Chapter03.xhtml])', 'epubcfi(/6/4[Chapter04.xhtml])', 'epubcfi(/6/4[Chapter05.xhtml])', 'epubcfi(/6/4[Chapter06.xhtml])', 'epubcfi(/6/4[Chapter07.xhtml])', 'epubcfi(/6/4[Chapter08.xhtml])', 'epubcfi(/6/4[Index.xhtml])'];
    this.__currentIndex = 0;
    this.metadata = this._book.metadata;
    this.fire('updateContents', this._book.contents);
    this.fire('updateTitle', this._metadata);
    this.fire('updateLocations', this._locations);
    this.draw(target, callback);
  },
  draw: function draw(target, callback) {
    var self = this;
    this.settings = {
      flow: this.options.flow
    };
    this.settings.height = '100%';
    this.settings.width = '99%'; // this.settings.width = '100%';

    if (this.options.flow == 'auto') {
      this._panes['book'].style.overflow = 'hidden';
    } else {
      this._panes['book'].style.overflow = 'auto';
    }

    if (typeof target == 'function' && cb === undefined) {
      callback = target;
      target = undefined;
    }

    callback();
    self.fire('ready');
  },
  next: function next() {// this._rendition.next();
  },
  prev: function prev() {// this._rendition.prev();
  },
  first: function first() {// this._rendition.display(0);
  },
  last: function last() {},
  gotoPage: function gotoPage(target) {
    if (typeof target == "string") {
      this.__currentIndex = this._locations.indexOf(target);
    } else {
      this.__currentIndex = target;
    }

    this.fire("relocated", this.currentLocation());
  },
  destroy: function destroy() {// if ( this._rendition ) {
    //   this._rendition.destroy();
    // }
    // this._rendition = null;
  },
  currentLocation: function currentLocation() {
    var cfi = this._locations[this.__currentIndex];
    return {
      start: {
        cfi: cfi,
        href: cfi
      },
      end: {
        cfi: cfi,
        href: cfi
      }
    };
  },
  _bindEvents: function _bindEvents() {
    var self = this;
  },
  _updateTheme: function _updateTheme() {},
  EOT: true
});
Object.defineProperty(Reader/* Reader.Mock.prototype */.E.Mock.prototype, 'metadata', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    return this._metadata;
  },
  set: function set(data) {
    this._metadata = Util.extend({}, data, this.options.metadata);
  }
});
Object.defineProperty(Reader/* Reader.Mock.prototype */.E.Mock.prototype, 'locations', {
  get: function get() {
    // return the combined metadata of configured + book metadata
    var self = this;
    return {
      total: self._locations.length,
      locationFromCfi: function locationFromCfi(cfi) {
        return self._locations.indexOf(cfi);
      },
      percentageFromCfi: function percentageFromCfi(cfi) {
        var index = self.locations.locationFromCfi(cfi);
        return index / self.locations.total;
      },
      cfiFromPercentage: function cfiFromPercentage(percentage) {
        var index = Math.ceil(percentage * 10);
        return self._locations[index];
      }
    };
  }
});
Object.defineProperty(Reader/* Reader.Mock.prototype */.E.Mock.prototype, 'annotations', {
  get: function get() {
    return {
      reset: function reset() {},
      highlight: function highlight() {}
    };
  }
});
function Reader_Mock_createReader(id, options) {
  return new Reader/* Reader.Mock */.E.Mock(id, options);
}
;// CONCATENATED MODULE: ./src/reader/index.js



var engines = {
  epubjs: createReader,
  mock: Reader_Mock_createReader
};

var reader_reader = function reader(id, options) {
  options = options || {};
  var engine = options.engine || window.COZY_EPUB_ENGINE || 'epubjs';
  var engine_href = options.engine_href || window.COZY_EPUB_ENGINE_HREF;

  var _this = this;

  var _arguments = arguments;
  options.engine = engine;
  options.engine_href = engine_href;
  return engines[engine].apply(_this, [id, options]);
};

/***/ }),

/***/ 1804:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isValue         = __webpack_require__(5618)
  , isPlainFunction = __webpack_require__(7205)
  , assign          = __webpack_require__(7191)
  , normalizeOpts   = __webpack_require__(5516)
  , contains        = __webpack_require__(9981);

var d = (module.exports = function (dscr, value/*, options*/) {
	var c, e, w, options, desc;
	if (arguments.length < 2 || typeof dscr !== "string") {
		options = value;
		value = dscr;
		dscr = null;
	} else {
		options = arguments[2];
	}
	if (isValue(dscr)) {
		c = contains.call(dscr, "c");
		e = contains.call(dscr, "e");
		w = contains.call(dscr, "w");
	} else {
		c = w = true;
		e = false;
	}

	desc = { value: value, configurable: c, enumerable: e, writable: w };
	return !options ? desc : assign(normalizeOpts(options), desc);
});

d.gs = function (dscr, get, set/*, options*/) {
	var c, e, options, desc;
	if (typeof dscr !== "string") {
		options = set;
		set = get;
		get = dscr;
		dscr = null;
	} else {
		options = arguments[3];
	}
	if (!isValue(get)) {
		get = undefined;
	} else if (!isPlainFunction(get)) {
		options = get;
		get = set = undefined;
	} else if (!isValue(set)) {
		set = undefined;
	} else if (!isPlainFunction(set)) {
		options = set;
		set = undefined;
	}
	if (isValue(dscr)) {
		c = contains.call(dscr, "c");
		e = contains.call(dscr, "e");
	} else {
		c = true;
		e = false;
	}

	desc = { get: get, set: set, configurable: c, enumerable: e };
	return !options ? desc : assign(normalizeOpts(options), desc);
};


/***/ }),

/***/ 1597:
/***/ ((module) => {

/*
 From Zip.js, by Gildas Lormeau
edited down
 */

var table = {
	"application" : {
		"ecmascript" : [ "es", "ecma" ],
		"javascript" : "js",
		"ogg" : "ogx",
		"pdf" : "pdf",
		"postscript" : [ "ps", "ai", "eps", "epsi", "epsf", "eps2", "eps3" ],
		"rdf+xml" : "rdf",
		"smil" : [ "smi", "smil" ],
		"xhtml+xml" : [ "xhtml", "xht" ],
		"xml" : [ "xml", "xsl", "xsd", "opf", "ncx" ],
		"zip" : "zip",
		"x-httpd-eruby" : "rhtml",
		"x-latex" : "latex",
		"x-maker" : [ "frm", "maker", "frame", "fm", "fb", "book", "fbdoc" ],
		"x-object" : "o",
		"x-shockwave-flash" : [ "swf", "swfl" ],
		"x-silverlight" : "scr",
		"epub+zip" : "epub",
		"font-tdpfr" : "pfr",
		"inkml+xml" : [ "ink", "inkml" ],
		"json" : "json",
		"jsonml+json" : "jsonml",
		"mathml+xml" : "mathml",
		"metalink+xml" : "metalink",
		"mp4" : "mp4s",
		// "oebps-package+xml" : "opf",
		"omdoc+xml" : "omdoc",
		"oxps" : "oxps",
		"vnd.amazon.ebook" : "azw",
		"widget" : "wgt",
		// "x-dtbncx+xml" : "ncx",
		"x-dtbook+xml" : "dtb",
		"x-dtbresource+xml" : "res",
		"x-font-bdf" : "bdf",
		"x-font-ghostscript" : "gsf",
		"x-font-linux-psf" : "psf",
		"x-font-otf" : "otf",
		"x-font-pcf" : "pcf",
		"x-font-snf" : "snf",
		"x-font-ttf" : [ "ttf", "ttc" ],
		"x-font-type1" : [ "pfa", "pfb", "pfm", "afm" ],
		"x-font-woff" : "woff",
		"x-mobipocket-ebook" : [ "prc", "mobi" ],
		"x-mspublisher" : "pub",
		"x-nzb" : "nzb",
		"x-tgif" : "obj",
		"xaml+xml" : "xaml",
		"xml-dtd" : "dtd",
		"xproc+xml" : "xpl",
		"xslt+xml" : "xslt",
		"internet-property-stream" : "acx",
		"x-compress" : "z",
		"x-compressed" : "tgz",
		"x-gzip" : "gz",
	},
	"audio" : {
		"flac" : "flac",
		"midi" : [ "mid", "midi", "kar", "rmi" ],
		"mpeg" : [ "mpga", "mpega", "mp2", "mp3", "m4a", "mp2a", "m2a", "m3a" ],
		"mpegurl" : "m3u",
		"ogg" : [ "oga", "ogg", "spx" ],
		"x-aiff" : [ "aif", "aiff", "aifc" ],
		"x-ms-wma" : "wma",
		"x-wav" : "wav",
		"adpcm" : "adp",
		"mp4" : "mp4a",
		"webm" : "weba",
		"x-aac" : "aac",
		"x-caf" : "caf",
		"x-matroska" : "mka",
		"x-pn-realaudio-plugin" : "rmp",
		"xm" : "xm",
		"mid" : [ "mid", "rmi" ]
	},
	"image" : {
		"gif" : "gif",
		"ief" : "ief",
		"jpeg" : [ "jpeg", "jpg", "jpe" ],
		"pcx" : "pcx",
		"png" : "png",
		"svg+xml" : [ "svg", "svgz" ],
		"tiff" : [ "tiff", "tif" ],
		"x-icon" : "ico",
		"bmp" : "bmp",
		"webp" : "webp",
		"x-pict" : [ "pic", "pct" ],
		"x-tga" : "tga",
		"cis-cod" : "cod"
	},
	"text" : {
		"cache-manifest" : [ "manifest", "appcache" ],
		"css" : "css",
		"csv" : "csv",
		"html" : [ "html", "htm", "shtml", "stm" ],
		"mathml" : "mml",
		"plain" : [ "txt", "text", "brf", "conf", "def", "list", "log", "in", "bas" ],
		"richtext" : "rtx",
		"tab-separated-values" : "tsv",
		"x-bibtex" : "bib"
	},
	"video" : {
		"mpeg" : [ "mpeg", "mpg", "mpe", "m1v", "m2v", "mp2", "mpa", "mpv2" ],
		"mp4" : [ "mp4", "mp4v", "mpg4" ],
		"quicktime" : [ "qt", "mov" ],
		"ogg" : "ogv",
		"vnd.mpegurl" : [ "mxu", "m4u" ],
		"x-flv" : "flv",
		"x-la-asf" : [ "lsf", "lsx" ],
		"x-mng" : "mng",
		"x-ms-asf" : [ "asf", "asx", "asr" ],
		"x-ms-wm" : "wm",
		"x-ms-wmv" : "wmv",
		"x-ms-wmx" : "wmx",
		"x-ms-wvx" : "wvx",
		"x-msvideo" : "avi",
		"x-sgi-movie" : "movie",
		"x-matroska" : [ "mpv", "mkv", "mk3d", "mks" ],
		"3gpp2" : "3g2",
		"h261" : "h261",
		"h263" : "h263",
		"h264" : "h264",
		"jpeg" : "jpgv",
		"jpm" : [ "jpm", "jpgm" ],
		"mj2" : [ "mj2", "mjp2" ],
		"vnd.ms-playready.media.pyv" : "pyv",
		"vnd.uvvu.mp4" : [ "uvu", "uvvu" ],
		"vnd.vivo" : "viv",
		"webm" : "webm",
		"x-f4v" : "f4v",
		"x-m4v" : "m4v",
		"x-ms-vob" : "vob",
		"x-smv" : "smv"
	}
};

var mimeTypes = (function() {
	var type, subtype, val, index, mimeTypes = {};
	for (type in table) {
		if (table.hasOwnProperty(type)) {
			for (subtype in table[type]) {
				if (table[type].hasOwnProperty(subtype)) {
					val = table[type][subtype];
					if (typeof val == "string") {
						mimeTypes[val] = type + "/" + subtype;
					} else {
						for (index = 0; index < val.length; index++) {
							mimeTypes[val[index]] = type + "/" + subtype;
						}
					}
				}
			}
		}
	}
	return mimeTypes;
})();

var defaultValue = "text/plain";//"application/octet-stream";

function lookup(filename) {
	return filename && mimeTypes[filename.split(".").pop().toLowerCase()] || defaultValue;
};

module.exports = {
	'lookup': lookup
}


/***/ }),

/***/ 5749:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
var __WEBPACK_AMD_DEFINE_FACTORY__, __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/* From https://github.com/webcomponents/URL/blob/master/url.js
 * Added UMD, file link handling */

/* Any copyright is dedicated to the Public Domain.
 * http://creativecommons.org/publicdomain/zero/1.0/ */

(function (root, factory) {
    // Fix for this being undefined in modules
    if (!root) {
      root = window || __webpack_require__.g;
    }
    if ( true && module.exports) {
        // Node
        module.exports = factory(root);
    } else if (true) {
        // AMD. Register as an anonymous module.
        !(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_FACTORY__ = (factory),
		__WEBPACK_AMD_DEFINE_RESULT__ = (typeof __WEBPACK_AMD_DEFINE_FACTORY__ === 'function' ?
		(__WEBPACK_AMD_DEFINE_FACTORY__.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__)) : __WEBPACK_AMD_DEFINE_FACTORY__),
		__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
    } else {}
}(this, function (scope) {
  // feature detect for URL constructor
  var hasWorkingUrl = false;
  if (!scope.forceJURL) {
    try {
      var u = new URL('b', 'http://a');
      u.pathname = 'c%20d';
      hasWorkingUrl = u.href === 'http://a/c%20d';
    } catch(e) {}
  }

  if (hasWorkingUrl)
    return scope.URL;

  var relative = Object.create(null);
  relative['ftp'] = 21;
  relative['file'] = 0;
  relative['gopher'] = 70;
  relative['http'] = 80;
  relative['https'] = 443;
  relative['ws'] = 80;
  relative['wss'] = 443;

  var relativePathDotMapping = Object.create(null);
  relativePathDotMapping['%2e'] = '.';
  relativePathDotMapping['.%2e'] = '..';
  relativePathDotMapping['%2e.'] = '..';
  relativePathDotMapping['%2e%2e'] = '..';

  function isRelativeScheme(scheme) {
    return relative[scheme] !== undefined;
  }

  function invalid() {
    clear.call(this);
    this._isInvalid = true;
  }

  function IDNAToASCII(h) {
    if ('' == h) {
      invalid.call(this)
    }
    // XXX
    return h.toLowerCase()
  }

  function percentEscape(c) {
    var unicode = c.charCodeAt(0);
    if (unicode > 0x20 &&
       unicode < 0x7F &&
       // " # < > ? `
       [0x22, 0x23, 0x3C, 0x3E, 0x3F, 0x60].indexOf(unicode) == -1
      ) {
      return c;
    }
    return encodeURIComponent(c);
  }

  function percentEscapeQuery(c) {
    // XXX This actually needs to encode c using encoding and then
    // convert the bytes one-by-one.

    var unicode = c.charCodeAt(0);
    if (unicode > 0x20 &&
       unicode < 0x7F &&
       // " # < > ` (do not escape '?')
       [0x22, 0x23, 0x3C, 0x3E, 0x60].indexOf(unicode) == -1
      ) {
      return c;
    }
    return encodeURIComponent(c);
  }

  var EOF = undefined,
      ALPHA = /[a-zA-Z]/,
      ALPHANUMERIC = /[a-zA-Z0-9\+\-\.]/;

  function parse(input, stateOverride, base) {
    function err(message) {
      errors.push(message)
    }

    var state = stateOverride || 'scheme start',
        cursor = 0,
        buffer = '',
        seenAt = false,
        seenBracket = false,
        errors = [];

    loop: while ((input[cursor - 1] != EOF || cursor == 0) && !this._isInvalid) {
      var c = input[cursor];
      switch (state) {
        case 'scheme start':
          if (c && ALPHA.test(c)) {
            buffer += c.toLowerCase(); // ASCII-safe
            state = 'scheme';
          } else if (!stateOverride) {
            buffer = '';
            state = 'no scheme';
            continue;
          } else {
            err('Invalid scheme.');
            break loop;
          }
          break;

        case 'scheme':
          if (c && ALPHANUMERIC.test(c)) {
            buffer += c.toLowerCase(); // ASCII-safe
          } else if (':' == c) {
            this._scheme = buffer;
            buffer = '';
            if (stateOverride) {
              break loop;
            }
            if (isRelativeScheme(this._scheme)) {
              this._isRelative = true;
            }
            if ('file' == this._scheme) {
              state = 'relative';
            } else if (this._isRelative && base && base._scheme == this._scheme) {
              state = 'relative or authority';
            } else if (this._isRelative) {
              state = 'authority first slash';
            } else {
              state = 'scheme data';
            }
          } else if (!stateOverride) {
            buffer = '';
            cursor = 0;
            state = 'no scheme';
            continue;
          } else if (EOF == c) {
            break loop;
          } else {
            err('Code point not allowed in scheme: ' + c)
            break loop;
          }
          break;

        case 'scheme data':
          if ('?' == c) {
            this._query = '?';
            state = 'query';
          } else if ('#' == c) {
            this._fragment = '#';
            state = 'fragment';
          } else {
            // XXX error handling
            if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
              this._schemeData += percentEscape(c);
            }
          }
          break;

        case 'no scheme':
          if (!base || !(isRelativeScheme(base._scheme))) {
            err('Missing scheme.');
            invalid.call(this);
          } else {
            state = 'relative';
            continue;
          }
          break;

        case 'relative or authority':
          if ('/' == c && '/' == input[cursor+1]) {
            state = 'authority ignore slashes';
          } else {
            err('Expected /, got: ' + c);
            state = 'relative';
            continue
          }
          break;

        case 'relative':
          this._isRelative = true;
          if ('file' != this._scheme)
            this._scheme = base._scheme;
          if (EOF == c) {
            this._host = base._host;
            this._port = base._port;
            this._path = base._path.slice();
            this._query = base._query;
            this._username = base._username;
            this._password = base._password;
            break loop;
          } else if ('/' == c || '\\' == c) {
            if ('\\' == c)
              err('\\ is an invalid code point.');
            state = 'relative slash';
          } else if ('?' == c) {
            this._host = base._host;
            this._port = base._port;
            this._path = base._path.slice();
            this._query = '?';
            this._username = base._username;
            this._password = base._password;
            state = 'query';
          } else if ('#' == c) {
            this._host = base._host;
            this._port = base._port;
            this._path = base._path.slice();
            this._query = base._query;
            this._fragment = '#';
            this._username = base._username;
            this._password = base._password;
            state = 'fragment';
          } else {
            var nextC = input[cursor+1]
            var nextNextC = input[cursor+2]
            if (
              'file' != this._scheme || !ALPHA.test(c) ||
              (nextC != ':' && nextC != '|') ||
              (EOF != nextNextC && '/' != nextNextC && '\\' != nextNextC && '?' != nextNextC && '#' != nextNextC)) {
              this._host = base._host;
              this._port = base._port;
              this._username = base._username;
              this._password = base._password;
              this._path = base._path.slice();
              this._path.pop();
            }
            state = 'relative path';
            continue;
          }
          break;

        case 'relative slash':
          if ('/' == c || '\\' == c) {
            if ('\\' == c) {
              err('\\ is an invalid code point.');
            }
            if ('file' == this._scheme) {
              state = 'file host';
            } else {
              state = 'authority ignore slashes';
            }
          } else {
            if ('file' != this._scheme) {
              this._host = base._host;
              this._port = base._port;
              this._username = base._username;
              this._password = base._password;
            }
            state = 'relative path';
            continue;
          }
          break;

        case 'authority first slash':
          if ('/' == c) {
            state = 'authority second slash';
          } else {
            err("Expected '/', got: " + c);
            state = 'authority ignore slashes';
            continue;
          }
          break;

        case 'authority second slash':
          state = 'authority ignore slashes';
          if ('/' != c) {
            err("Expected '/', got: " + c);
            continue;
          }
          break;

        case 'authority ignore slashes':
          if ('/' != c && '\\' != c) {
            state = 'authority';
            continue;
          } else {
            err('Expected authority, got: ' + c);
          }
          break;

        case 'authority':
          if ('@' == c) {
            if (seenAt) {
              err('@ already seen.');
              buffer += '%40';
            }
            seenAt = true;
            for (var i = 0; i < buffer.length; i++) {
              var cp = buffer[i];
              if ('\t' == cp || '\n' == cp || '\r' == cp) {
                err('Invalid whitespace in authority.');
                continue;
              }
              // XXX check URL code points
              if (':' == cp && null === this._password) {
                this._password = '';
                continue;
              }
              var tempC = percentEscape(cp);
              (null !== this._password) ? this._password += tempC : this._username += tempC;
            }
            buffer = '';
          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
            cursor -= buffer.length;
            buffer = '';
            state = 'host';
            continue;
          } else {
            buffer += c;
          }
          break;

        case 'file host':
          if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
            if (buffer.length == 2 && ALPHA.test(buffer[0]) && (buffer[1] == ':' || buffer[1] == '|')) {
              state = 'relative path';
            } else if (buffer.length == 0) {
              state = 'relative path start';
            } else {
              this._host = IDNAToASCII.call(this, buffer);
              buffer = '';
              state = 'relative path start';
            }
            continue;
          } else if ('\t' == c || '\n' == c || '\r' == c) {
            err('Invalid whitespace in file host.');
          } else {
            buffer += c;
          }
          break;

        case 'host':
        case 'hostname':
          if (':' == c && !seenBracket) {
            // XXX host parsing
            this._host = IDNAToASCII.call(this, buffer);
            buffer = '';
            state = 'port';
            if ('hostname' == stateOverride) {
              break loop;
            }
          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c) {
            this._host = IDNAToASCII.call(this, buffer);
            buffer = '';
            state = 'relative path start';
            if (stateOverride) {
              break loop;
            }
            continue;
          } else if ('\t' != c && '\n' != c && '\r' != c) {
            if ('[' == c) {
              seenBracket = true;
            } else if (']' == c) {
              seenBracket = false;
            }
            buffer += c;
          } else {
            err('Invalid code point in host/hostname: ' + c);
          }
          break;

        case 'port':
          if (/[0-9]/.test(c)) {
            buffer += c;
          } else if (EOF == c || '/' == c || '\\' == c || '?' == c || '#' == c || stateOverride) {
            if ('' != buffer) {
              var temp = parseInt(buffer, 10);
              if (temp != relative[this._scheme]) {
                this._port = temp + '';
              }
              buffer = '';
            }
            if (stateOverride) {
              break loop;
            }
            state = 'relative path start';
            continue;
          } else if ('\t' == c || '\n' == c || '\r' == c) {
            err('Invalid code point in port: ' + c);
          } else {
            invalid.call(this);
          }
          break;

        case 'relative path start':
          if ('\\' == c)
            err("'\\' not allowed in path.");
          state = 'relative path';
          if ('/' != c && '\\' != c) {
            continue;
          }
          break;

        case 'relative path':
          if (EOF == c || '/' == c || '\\' == c || (!stateOverride && ('?' == c || '#' == c))) {
            if ('\\' == c) {
              err('\\ not allowed in relative path.');
            }
            var tmp;
            if (tmp = relativePathDotMapping[buffer.toLowerCase()]) {
              buffer = tmp;
            }
            if ('..' == buffer) {
              this._path.pop();
              if ('/' != c && '\\' != c) {
                this._path.push('');
              }
            } else if ('.' == buffer && '/' != c && '\\' != c) {
              this._path.push('');
            } else if ('.' != buffer) {
              if ('file' == this._scheme && this._path.length == 0 && buffer.length == 2 && ALPHA.test(buffer[0]) && buffer[1] == '|') {
                buffer = buffer[0] + ':';
              }
              this._path.push(buffer);
            }
            buffer = '';
            if ('?' == c) {
              this._query = '?';
              state = 'query';
            } else if ('#' == c) {
              this._fragment = '#';
              state = 'fragment';
            }
          } else if ('\t' != c && '\n' != c && '\r' != c) {
            buffer += percentEscape(c);
          }
          break;

        case 'query':
          if (!stateOverride && '#' == c) {
            this._fragment = '#';
            state = 'fragment';
          } else if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
            this._query += percentEscapeQuery(c);
          }
          break;

        case 'fragment':
          if (EOF != c && '\t' != c && '\n' != c && '\r' != c) {
            this._fragment += c;
          }
          break;
      }

      cursor++;
    }
  }

  function clear() {
    this._scheme = '';
    this._schemeData = '';
    this._username = '';
    this._password = null;
    this._host = '';
    this._port = '';
    this._path = [];
    this._query = '';
    this._fragment = '';
    this._isInvalid = false;
    this._isRelative = false;
  }

  // Does not process domain names or IP addresses.
  // Does not handle encoding for the query parameter.
  function jURL(url, base /* , encoding */) {
    if (base !== undefined && !(base instanceof jURL))
      base = new jURL(String(base));

    this._url = url;
    clear.call(this);

    var input = url.replace(/^[ \t\r\n\f]+|[ \t\r\n\f]+$/g, '');
    // encoding = encoding || 'utf-8'

    parse.call(this, input, null, base);
  }

  jURL.prototype = {
    toString: function() {
      return this.href;
    },
    get href() {
      if (this._isInvalid)
        return this._url;

      var authority = '';
      if ('' != this._username || null != this._password) {
        authority = this._username +
            (null != this._password ? ':' + this._password : '') + '@';
      }

      return this.protocol +
          (this._isRelative ? '//' + authority + this.host : '') +
          this.pathname + this._query + this._fragment;
    },
    set href(href) {
      clear.call(this);
      parse.call(this, href);
    },

    get protocol() {
      return this._scheme + ':';
    },
    set protocol(protocol) {
      if (this._isInvalid)
        return;
      parse.call(this, protocol + ':', 'scheme start');
    },

    get host() {
      return this._isInvalid ? '' : this._port ?
          this._host + ':' + this._port : this._host;
    },
    set host(host) {
      if (this._isInvalid || !this._isRelative)
        return;
      parse.call(this, host, 'host');
    },

    get hostname() {
      return this._host;
    },
    set hostname(hostname) {
      if (this._isInvalid || !this._isRelative)
        return;
      parse.call(this, hostname, 'hostname');
    },

    get port() {
      return this._port;
    },
    set port(port) {
      if (this._isInvalid || !this._isRelative)
        return;
      parse.call(this, port, 'port');
    },

    get pathname() {
      return this._isInvalid ? '' : this._isRelative ?
          '/' + this._path.join('/') : this._schemeData;
    },
    set pathname(pathname) {
      if (this._isInvalid || !this._isRelative)
        return;
      this._path = [];
      parse.call(this, pathname, 'relative path start');
    },

    get search() {
      return this._isInvalid || !this._query || '?' == this._query ?
          '' : this._query;
    },
    set search(search) {
      if (this._isInvalid || !this._isRelative)
        return;
      this._query = '?';
      if ('?' == search[0])
        search = search.slice(1);
      parse.call(this, search, 'query');
    },

    get hash() {
      return this._isInvalid || !this._fragment || '#' == this._fragment ?
          '' : this._fragment;
    },
    set hash(hash) {
      if (this._isInvalid)
        return;
      this._fragment = '#';
      if ('#' == hash[0])
        hash = hash.slice(1);
      parse.call(this, hash, 'fragment');
    },

    get origin() {
      var host;
      if (this._isInvalid || !this._scheme) {
        return '';
      }
      // javascript: Gecko returns String(""), WebKit/Blink String("null")
      // Gecko throws error for "data://"
      // data: Gecko returns "", Blink returns "data://", WebKit returns "null"
      // Gecko returns String("") for file: mailto:
      // WebKit/Blink returns String("SCHEME://") for file: mailto:
      switch (this._scheme) {
        case 'file':
          return 'file://' // EPUBJS Added
        case 'data':
        case 'javascript':
        case 'mailto':
          return 'null';
      }
      host = this.host;
      if (!host) {
        return '';
      }
      return this._scheme + '://' + host;
    }
  };

  // Copy over the static methods
  var OriginalURL = scope.URL;
  if (OriginalURL) {
    jURL.createObjectURL = function(blob) {
      // IE extension allows a second optional options argument.
      // http://msdn.microsoft.com/en-us/library/ie/hh772302(v=vs.85).aspx
      return OriginalURL.createObjectURL.apply(OriginalURL, arguments);
    };
    jURL.revokeObjectURL = function(url) {
      OriginalURL.revokeObjectURL(url);
    };
  }

  return jURL;
}));


/***/ }),

/***/ 6458:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "requestAnimationFrame": () => (/* binding */ requestAnimationFrame),
/* harmony export */   "uuid": () => (/* binding */ uuid),
/* harmony export */   "documentHeight": () => (/* binding */ documentHeight),
/* harmony export */   "isElement": () => (/* binding */ isElement),
/* harmony export */   "isNumber": () => (/* binding */ isNumber),
/* harmony export */   "isFloat": () => (/* binding */ isFloat),
/* harmony export */   "prefixed": () => (/* binding */ prefixed),
/* harmony export */   "defaults": () => (/* binding */ defaults),
/* harmony export */   "extend": () => (/* binding */ extend),
/* harmony export */   "insert": () => (/* binding */ insert),
/* harmony export */   "locationOf": () => (/* binding */ locationOf),
/* harmony export */   "indexOfSorted": () => (/* binding */ indexOfSorted),
/* harmony export */   "bounds": () => (/* binding */ bounds),
/* harmony export */   "borders": () => (/* binding */ borders),
/* harmony export */   "nodeBounds": () => (/* binding */ nodeBounds),
/* harmony export */   "windowBounds": () => (/* binding */ windowBounds),
/* harmony export */   "indexOfNode": () => (/* binding */ indexOfNode),
/* harmony export */   "indexOfTextNode": () => (/* binding */ indexOfTextNode),
/* harmony export */   "indexOfElementNode": () => (/* binding */ indexOfElementNode),
/* harmony export */   "isXml": () => (/* binding */ isXml),
/* harmony export */   "createBlob": () => (/* binding */ createBlob),
/* harmony export */   "createBlobUrl": () => (/* binding */ createBlobUrl),
/* harmony export */   "revokeBlobUrl": () => (/* binding */ revokeBlobUrl),
/* harmony export */   "createBase64Url": () => (/* binding */ createBase64Url),
/* harmony export */   "type": () => (/* binding */ type),
/* harmony export */   "parse": () => (/* binding */ parse),
/* harmony export */   "qs": () => (/* binding */ qs),
/* harmony export */   "qsa": () => (/* binding */ qsa),
/* harmony export */   "qsp": () => (/* binding */ qsp),
/* harmony export */   "sprint": () => (/* binding */ sprint),
/* harmony export */   "treeWalker": () => (/* binding */ treeWalker),
/* harmony export */   "walk": () => (/* binding */ walk),
/* harmony export */   "blob2base64": () => (/* binding */ blob2base64),
/* harmony export */   "defer": () => (/* binding */ defer),
/* harmony export */   "querySelectorByType": () => (/* binding */ querySelectorByType),
/* harmony export */   "findChildren": () => (/* binding */ findChildren),
/* harmony export */   "parents": () => (/* binding */ parents),
/* harmony export */   "filterChildren": () => (/* binding */ filterChildren),
/* harmony export */   "getParentByTagName": () => (/* binding */ getParentByTagName),
/* harmony export */   "RangeObject": () => (/* binding */ RangeObject)
/* harmony export */ });
/**
 * Core Utilities and Helpers
 * @module Core
*/

/**
 * Vendor prefixed requestAnimationFrame
 * @returns {function} requestAnimationFrame
 * @memberof Core
 */
const requestAnimationFrame = (typeof window != "undefined") ? (window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame) : false;
const ELEMENT_NODE = 1;
const TEXT_NODE = 3;
const COMMENT_NODE = 8;
const DOCUMENT_NODE = 9;
const _URL = typeof URL != "undefined" ? URL : (typeof window != "undefined" ? (window.URL || window.webkitURL || window.mozURL) : undefined);

/**
 * Generates a UUID
 * based on: http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
 * @returns {string} uuid
 * @memberof Core
 */
function uuid() {
	var d = new Date().getTime();
	var uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
		var r = (d + Math.random()*16)%16 | 0;
		d = Math.floor(d/16);
		return (c=="x" ? r : (r&0x7|0x8)).toString(16);
	});
	return uuid;
}

/**
 * Gets the height of a document
 * @returns {number} height
 * @memberof Core
 */
function documentHeight() {
	return Math.max(
			document.documentElement.clientHeight,
			document.body.scrollHeight,
			document.documentElement.scrollHeight,
			document.body.offsetHeight,
			document.documentElement.offsetHeight
	);
}

/**
 * Checks if a node is an element
 * @param {object} obj
 * @returns {boolean}
 * @memberof Core
 */
function isElement(obj) {
	return !!(obj && obj.nodeType == 1);
}

/**
 * @param {any} n
 * @returns {boolean}
 * @memberof Core
 */
function isNumber(n) {
	return !isNaN(parseFloat(n)) && isFinite(n);
}

/**
 * @param {any} n
 * @returns {boolean}
 * @memberof Core
 */
function isFloat(n) {
	let f = parseFloat(n);

	if (isNumber(n) === false) {
		return false;
	}

	if (typeof n === "string" && n.indexOf(".") > -1) {
		return true;
	}

	return Math.floor(f) !== f;
}

/**
 * Get a prefixed css property
 * @param {string} unprefixed
 * @returns {string}
 * @memberof Core
 */
function prefixed(unprefixed) {
	var vendors = ["Webkit", "webkit", "Moz", "O", "ms" ];
	var prefixes = ["-webkit-", "-webkit-", "-moz-", "-o-", "-ms-"];
	var upper = unprefixed[0].toUpperCase() + unprefixed.slice(1);
	var length = vendors.length;

	if (typeof(document) === "undefined" || typeof(document.body.style[unprefixed]) != "undefined") {
		return unprefixed;
	}

	for ( var i=0; i < length; i++ ) {
		if (typeof(document.body.style[vendors[i] + upper]) != "undefined") {
			return prefixes[i] + unprefixed;
		}
	}

	return unprefixed;
}

/**
 * Apply defaults to an object
 * @param {object} obj
 * @returns {object}
 * @memberof Core
 */
function defaults(obj) {
	for (var i = 1, length = arguments.length; i < length; i++) {
		var source = arguments[i];
		for (var prop in source) {
			if (obj[prop] === void 0) obj[prop] = source[prop];
		}
	}
	return obj;
}

/**
 * Extend properties of an object
 * @param {object} target
 * @returns {object}
 * @memberof Core
 */
function extend(target) {
	var sources = [].slice.call(arguments, 1);
	sources.forEach(function (source) {
		if(!source) return;
		Object.getOwnPropertyNames(source).forEach(function(propName) {
			Object.defineProperty(target, propName, Object.getOwnPropertyDescriptor(source, propName));
		});
	});
	return target;
}

/**
 * Fast quicksort insert for sorted array -- based on:
 *  http://stackoverflow.com/questions/1344500/efficient-way-to-insert-a-number-into-a-sorted-array-of-numbers
 * @param {any} item
 * @param {array} array
 * @param {function} [compareFunction]
 * @returns {number} location (in array)
 * @memberof Core
 */
function insert(item, array, compareFunction) {
	var location = locationOf(item, array, compareFunction);
	array.splice(location, 0, item);

	return location;
}

/**
 * Finds where something would fit into a sorted array
 * @param {any} item
 * @param {array} array
 * @param {function} [compareFunction]
 * @param {function} [_start]
 * @param {function} [_end]
 * @returns {number} location (in array)
 * @memberof Core
 */
function locationOf(item, array, compareFunction, _start, _end) {
	var start = _start || 0;
	var end = _end || array.length;
	var pivot = parseInt(start + (end - start) / 2);
	var compared;
	if(!compareFunction){
		compareFunction = function(a, b) {
			if(a > b) return 1;
			if(a < b) return -1;
			if(a == b) return 0;
		};
	}
	if(end-start <= 0) {
		return pivot;
	}

	compared = compareFunction(array[pivot], item);
	if(end-start === 1) {
		return compared >= 0 ? pivot : pivot + 1;
	}
	if(compared === 0) {
		return pivot;
	}
	if(compared === -1) {
		return locationOf(item, array, compareFunction, pivot, end);
	} else{
		return locationOf(item, array, compareFunction, start, pivot);
	}
}

/**
 * Finds index of something in a sorted array
 * Returns -1 if not found
 * @param {any} item
 * @param {array} array
 * @param {function} [compareFunction]
 * @param {function} [_start]
 * @param {function} [_end]
 * @returns {number} index (in array) or -1
 * @memberof Core
 */
function indexOfSorted(item, array, compareFunction, _start, _end) {
	var start = _start || 0;
	var end = _end || array.length;
	var pivot = parseInt(start + (end - start) / 2);
	var compared;
	if(!compareFunction){
		compareFunction = function(a, b) {
			if(a > b) return 1;
			if(a < b) return -1;
			if(a == b) return 0;
		};
	}
	if(end-start <= 0) {
		return -1; // Not found
	}

	compared = compareFunction(array[pivot], item);
	if(end-start === 1) {
		return compared === 0 ? pivot : -1;
	}
	if(compared === 0) {
		return pivot; // Found
	}
	if(compared === -1) {
		return indexOfSorted(item, array, compareFunction, pivot, end);
	} else{
		return indexOfSorted(item, array, compareFunction, start, pivot);
	}
}
/**
 * Find the bounds of an element
 * taking padding and margin into account
 * @param {element} el
 * @returns {{ width: Number, height: Number}}
 * @memberof Core
 */
function bounds(el) {

	var style = window.getComputedStyle(el);
	var widthProps = ["width", "paddingRight", "paddingLeft", "marginRight", "marginLeft", "borderRightWidth", "borderLeftWidth"];
	var heightProps = ["height", "paddingTop", "paddingBottom", "marginTop", "marginBottom", "borderTopWidth", "borderBottomWidth"];

	var width = 0;
	var height = 0;

	widthProps.forEach(function(prop){
		width += parseFloat(style[prop]) || 0;
	});

	heightProps.forEach(function(prop){
		height += parseFloat(style[prop]) || 0;
	});

	return {
		height: height,
		width: width
	};

}

/**
 * Find the bounds of an element
 * taking padding, margin and borders into account
 * @param {element} el
 * @returns {{ width: Number, height: Number}}
 * @memberof Core
 */
function borders(el) {

	var style = window.getComputedStyle(el);
	var widthProps = ["paddingRight", "paddingLeft", "marginRight", "marginLeft", "borderRightWidth", "borderLeftWidth"];
	var heightProps = ["paddingTop", "paddingBottom", "marginTop", "marginBottom", "borderTopWidth", "borderBottomWidth"];

	var width = 0;
	var height = 0;

	widthProps.forEach(function(prop){
		width += parseFloat(style[prop]) || 0;
	});

	heightProps.forEach(function(prop){
		height += parseFloat(style[prop]) || 0;
	});

	return {
		height: height,
		width: width
	};

}

/**
 * Find the bounds of any node
 * allows for getting bounds of text nodes by wrapping them in a range
 * @param {node} node
 * @returns {BoundingClientRect}
 * @memberof Core
 */
function nodeBounds(node) {
	let elPos;
	let doc = node.ownerDocument;
	if(node.nodeType == Node.TEXT_NODE){
		let elRange = doc.createRange();
		elRange.selectNodeContents(node);
		elPos = elRange.getBoundingClientRect();
	} else {
		elPos = node.getBoundingClientRect();
	}
	return elPos;
}

/**
 * Find the equivelent of getBoundingClientRect of a browser window
 * @returns {{ width: Number, height: Number, top: Number, left: Number, right: Number, bottom: Number }}
 * @memberof Core
 */
function windowBounds() {

	var width = window.innerWidth;
	var height = window.innerHeight;

	return {
		top: 0,
		left: 0,
		right: width,
		bottom: height,
		width: width,
		height: height
	};

}

/**
 * Gets the index of a node in its parent
 * @param {Node} node
 * @param {string} typeId
 * @return {number} index
 * @memberof Core
 */
function indexOfNode(node, typeId) {
	var parent = node.parentNode;
	var children = parent.childNodes;
	var sib;
	var index = -1;
	for (var i = 0; i < children.length; i++) {
		sib = children[i];
		if (sib.nodeType === typeId) {
			index++;
		}
		if (sib == node) break;
	}

	return index;
}

/**
 * Gets the index of a text node in its parent
 * @param {node} textNode
 * @returns {number} index
 * @memberof Core
 */
function indexOfTextNode(textNode) {
	return indexOfNode(textNode, TEXT_NODE);
}

/**
 * Gets the index of an element node in its parent
 * @param {element} elementNode
 * @returns {number} index
 * @memberof Core
 */
function indexOfElementNode(elementNode) {
	return indexOfNode(elementNode, ELEMENT_NODE);
}

/**
 * Check if extension is xml
 * @param {string} ext
 * @returns {boolean}
 * @memberof Core
 */
function isXml(ext) {
	return ["xml", "opf", "ncx"].indexOf(ext) > -1;
}

/**
 * Create a new blob
 * @param {any} content
 * @param {string} mime
 * @returns {Blob}
 * @memberof Core
 */
function createBlob(content, mime){
	return new Blob([content], {type : mime });
}

/**
 * Create a new blob url
 * @param {any} content
 * @param {string} mime
 * @returns {string} url
 * @memberof Core
 */
function createBlobUrl(content, mime){
	var tempUrl;
	var blob = createBlob(content, mime);

	tempUrl = _URL.createObjectURL(blob);

	return tempUrl;
}

/**
 * Remove a blob url
 * @param {string} url
 * @memberof Core
 */
function revokeBlobUrl(url){
	return _URL.revokeObjectURL(url);
}

/**
 * Create a new base64 encoded url
 * @param {any} content
 * @param {string} mime
 * @returns {string} url
 * @memberof Core
 */
function createBase64Url(content, mime){
	var data;
	var datauri;

	if (typeof(content) !== "string") {
		// Only handles strings
		return;
	}

	data = btoa(encodeURIComponent(content));

	datauri = "data:" + mime + ";base64," + data;

	return datauri;
}

/**
 * Get type of an object
 * @param {object} obj
 * @returns {string} type
 * @memberof Core
 */
function type(obj){
	return Object.prototype.toString.call(obj).slice(8, -1);
}

/**
 * Parse xml (or html) markup
 * @param {string} markup
 * @param {string} mime
 * @param {boolean} forceXMLDom force using xmlDom to parse instead of native parser
 * @returns {document} document
 * @memberof Core
 */
function parse(markup, mime, forceXMLDom) {
	var doc;
	var Parser;

	if (typeof DOMParser === "undefined" || forceXMLDom) {
		Parser = __webpack_require__(5348).DOMParser;
	} else {
		Parser = DOMParser;
	}

	// Remove byte order mark before parsing
	// https://www.w3.org/International/questions/qa-byte-order-mark
	if(markup.charCodeAt(0) === 0xFEFF) {
		markup = markup.slice(1);
	}

	doc = new Parser().parseFromString(markup, mime);

	return doc;
}

/**
 * querySelector polyfill
 * @param {element} el
 * @param {string} sel selector string
 * @returns {element} element
 * @memberof Core
 */
function qs(el, sel) {
	var elements;
	if (!el) {
		throw new Error("No Element Provided");
	}

	if (typeof el.querySelector != "undefined") {
		return el.querySelector(sel);
	} else {
		elements = el.getElementsByTagName(sel);
		if (elements.length) {
			return elements[0];
		}
	}
}

/**
 * querySelectorAll polyfill
 * @param {element} el
 * @param {string} sel selector string
 * @returns {element[]} elements
 * @memberof Core
 */
function qsa(el, sel) {

	if (typeof el.querySelector != "undefined") {
		return el.querySelectorAll(sel);
	} else {
		return el.getElementsByTagName(sel);
	}
}

/**
 * querySelector by property
 * @param {element} el
 * @param {string} sel selector string
 * @param {object[]} props
 * @returns {element[]} elements
 * @memberof Core
 */
function qsp(el, sel, props) {
	var q, filtered;
	if (typeof el.querySelector != "undefined") {
		sel += "[";
		for (var prop in props) {
			sel += prop + "~='" + props[prop] + "'";
		}
		sel += "]";
		return el.querySelector(sel);
	} else {
		q = el.getElementsByTagName(sel);
		filtered = Array.prototype.slice.call(q, 0).filter(function(el) {
			for (var prop in props) {
				if(el.getAttribute(prop) === props[prop]){
					return true;
				}
			}
			return false;
		});

		if (filtered) {
			return filtered[0];
		}
	}
}

/**
 * Sprint through all text nodes in a document
 * @memberof Core
 * @param  {element} root element to start with
 * @param  {function} func function to run on each element
 */
function sprint(root, func) {
	var doc = root.ownerDocument || root;
	if (typeof(doc.createTreeWalker) !== "undefined") {
		treeWalker(root, func, NodeFilter.SHOW_TEXT);
	} else {
		walk(root, function(node) {
			if (node && node.nodeType === 3) { // Node.TEXT_NODE
				func(node);
			}
		}, true);
	}
}

/**
 * Create a treeWalker
 * @memberof Core
 * @param  {element} root element to start with
 * @param  {function} func function to run on each element
 * @param  {function | object} filter funtion or object to filter with
 */
function treeWalker(root, func, filter) {
	var treeWalker = document.createTreeWalker(root, filter, null, false);
	let node;
	while ((node = treeWalker.nextNode())) {
		func(node);
	}
}

/**
 * @memberof Core
 * @param {node} node
 * @param {callback} return false for continue,true for break inside callback
 */
function walk(node,callback){
	if(callback(node)){
		return true;
	}
	node = node.firstChild;
	if(node){
		do{
			let walked = walk(node,callback);
			if(walked){
				return true;
			}
			node = node.nextSibling;
		} while(node);
	}
}

/**
 * Convert a blob to a base64 encoded string
 * @param {Blog} blob
 * @returns {string}
 * @memberof Core
 */
function blob2base64(blob) {
	return new Promise(function(resolve, reject) {
		var reader = new FileReader();
		reader.readAsDataURL(blob);
		reader.onloadend = function() {
			resolve(reader.result);
		};
	});
}


/**
 * Creates a new pending promise and provides methods to resolve or reject it.
 * From: https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/Promise.jsm/Deferred#backwards_forwards_compatible
 * @memberof Core
 */
function defer() {
	/* A method to resolve the associated Promise with the value passed.
	 * If the promise is already settled it does nothing.
	 *
	 * @param {anything} value : This value is used to resolve the promise
	 * If the value is a Promise then the associated promise assumes the state
	 * of Promise passed as value.
	 */
	this.resolve = null;

	/* A method to reject the assocaited Promise with the value passed.
	 * If the promise is already settled it does nothing.
	 *
	 * @param {anything} reason: The reason for the rejection of the Promise.
	 * Generally its an Error object. If however a Promise is passed, then the Promise
	 * itself will be the reason for rejection no matter the state of the Promise.
	 */
	this.reject = null;

	this.id = uuid();

	/* A newly created Pomise object.
	 * Initially in pending state.
	 */
	this.promise = new Promise((resolve, reject) => {
		this.resolve = resolve;
		this.reject = reject;
	});
	Object.freeze(this);
}

/**
 * querySelector with filter by epub type
 * @param {element} html
 * @param {string} element element type to find
 * @param {string} type epub type to find
 * @returns {element[]} elements
 * @memberof Core
 */
function querySelectorByType(html, element, type){
	var query;
	if (typeof html.querySelector != "undefined") {
		query = html.querySelector(`${element}[*|type="${type}"]`);
	}
	// Handle IE not supporting namespaced epub:type in querySelector
	if(!query || query.length === 0) {
		query = qsa(html, element);
		for (var i = 0; i < query.length; i++) {
			if(query[i].getAttributeNS("http://www.idpf.org/2007/ops", "type") === type ||
				 query[i].getAttribute("epub:type") === type) {
				return query[i];
			}
		}
	} else {
		return query;
	}
}

/**
 * Find direct decendents of an element
 * @param {element} el
 * @returns {element[]} children
 * @memberof Core
 */
function findChildren(el) {
	var result = [];
	var childNodes = el.childNodes;
	for (var i = 0; i < childNodes.length; i++) {
		let node = childNodes[i];
		if (node.nodeType === 1) {
			result.push(node);
		}
	}
	return result;
}

/**
 * Find all parents (ancestors) of an element
 * @param {element} node
 * @returns {element[]} parents
 * @memberof Core
 */
function parents(node) {
	var nodes = [node];
	for (; node; node = node.parentNode) {
		nodes.unshift(node);
	}
	return nodes
}

/**
 * Find all direct decendents of a specific type
 * @param {element} el
 * @param {string} nodeName
 * @param {boolean} [single]
 * @returns {element[]} children
 * @memberof Core
 */
function filterChildren(el, nodeName, single) {
	var result = [];
	var childNodes = el.childNodes;
	for (var i = 0; i < childNodes.length; i++) {
		let node = childNodes[i];
		if (node.nodeType === 1 && node.nodeName.toLowerCase() === nodeName) {
			if (single) {
				return node;
			} else {
				result.push(node);
			}
		}
	}
	if (!single) {
		return result;
	}
}

/**
 * Filter all parents (ancestors) with tag name
 * @param {element} node
 * @param {string} tagname
 * @returns {element[]} parents
 * @memberof Core
 */
function getParentByTagName(node, tagname) {
	let parent;
	if (node === null || tagname === '') return;
	parent = node.parentNode;
	while (parent.nodeType === 1) {
		if (parent.tagName.toLowerCase() === tagname) {
			return parent;
		}
		parent = parent.parentNode;
	}
}

/**
 * Lightweight Polyfill for DOM Range
 * @class
 * @memberof Core
 */
class RangeObject {
	constructor() {
		this.collapsed = false;
		this.commonAncestorContainer = undefined;
		this.endContainer = undefined;
		this.endOffset = undefined;
		this.startContainer = undefined;
		this.startOffset = undefined;
	}

	setStart(startNode, startOffset) {
		this.startContainer = startNode;
		this.startOffset = startOffset;

		if (!this.endContainer) {
			this.collapse(true);
		} else {
			this.commonAncestorContainer = this._commonAncestorContainer();
		}

		this._checkCollapsed();
	}

	setEnd(endNode, endOffset) {
		this.endContainer = endNode;
		this.endOffset = endOffset;

		if (!this.startContainer) {
			this.collapse(false);
		} else {
			this.collapsed = false;
			this.commonAncestorContainer = this._commonAncestorContainer();
		}

		this._checkCollapsed();
	}

	collapse(toStart) {
		this.collapsed = true;
		if (toStart) {
			this.endContainer = this.startContainer;
			this.endOffset = this.startOffset;
			this.commonAncestorContainer = this.startContainer.parentNode;
		} else {
			this.startContainer = this.endContainer;
			this.startOffset = this.endOffset;
			this.commonAncestorContainer = this.endOffset.parentNode;
		}
	}

	selectNode(referenceNode) {
		let parent = referenceNode.parentNode;
		let index = Array.prototype.indexOf.call(parent.childNodes, referenceNode);
		this.setStart(parent, index);
		this.setEnd(parent, index + 1);
	}

	selectNodeContents(referenceNode) {
		let end = referenceNode.childNodes[referenceNode.childNodes - 1];
		let endIndex = (referenceNode.nodeType === 3) ?
				referenceNode.textContent.length : parent.childNodes.length;
		this.setStart(referenceNode, 0);
		this.setEnd(referenceNode, endIndex);
	}

	_commonAncestorContainer(startContainer, endContainer) {
		var startParents = parents(startContainer || this.startContainer);
		var endParents = parents(endContainer || this.endContainer);

		if (startParents[0] != endParents[0]) return undefined;

		for (var i = 0; i < startParents.length; i++) {
			if (startParents[i] != endParents[i]) {
				return startParents[i - 1];
			}
		}
	}

	_checkCollapsed() {
		if (this.startContainer === this.endContainer &&
				this.startOffset === this.endOffset) {
			this.collapsed = true;
		} else {
			this.collapsed = false;
		}
	}

	toString() {
		// TODO: implement walking between start and end to find text
	}
}


/***/ }),

/***/ 5233:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "Z": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var path_webpack__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(9294);
/* harmony import */ var path_webpack__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(path_webpack__WEBPACK_IMPORTED_MODULE_0__);


/**
 * Creates a Path object for parsing and manipulation of a path strings
 *
 * Uses a polyfill for Nodejs path: https://nodejs.org/api/path.html
 * @param	{string} pathString	a url string (relative or absolute)
 * @class
 */
class Path {
	constructor(pathString) {
		var protocol;
		var parsed;

		protocol = pathString.indexOf("://");
		if (protocol > -1) {
			pathString = new URL(pathString).pathname;
		}

		parsed = this.parse(pathString);

		this.path = pathString;

		if (this.isDirectory(pathString)) {
			this.directory = pathString;
		} else {
			this.directory = parsed.dir + "/";
		}

		this.filename = parsed.base;
		this.extension = parsed.ext.slice(1);

	}

	/**
	 * Parse the path: https://nodejs.org/api/path.html#path_path_parse_path
	 * @param	{string} what
	 * @returns {object}
	 */
	parse (what) {
		return path_webpack__WEBPACK_IMPORTED_MODULE_0___default().parse(what);
	}

	/**
	 * @param	{string} what
	 * @returns {boolean}
	 */
	isAbsolute (what) {
		return path_webpack__WEBPACK_IMPORTED_MODULE_0___default().isAbsolute(what || this.path);
	}

	/**
	 * Check if path ends with a directory
	 * @param	{string} what
	 * @returns {boolean}
	 */
	isDirectory (what) {
		return (what.charAt(what.length-1) === "/");
	}

	/**
	 * Resolve a path against the directory of the Path
	 *
	 * https://nodejs.org/api/path.html#path_path_resolve_paths
	 * @param	{string} what
	 * @returns {string} resolved
	 */
	resolve (what) {
		return path_webpack__WEBPACK_IMPORTED_MODULE_0___default().resolve(this.directory, what);
	}

	/**
	 * Resolve a path relative to the directory of the Path
	 *
	 * https://nodejs.org/api/path.html#path_path_relative_from_to
	 * @param	{string} what
	 * @returns {string} relative
	 */
	relative (what) {
		var isAbsolute = what && (what.indexOf("://") > -1);

		if (isAbsolute) {
			return what;
		}

		return path_webpack__WEBPACK_IMPORTED_MODULE_0___default().relative(this.directory, what);
	}

	splitPath(filename) {
		return this.splitPathRe.exec(filename).slice(1);
	}

	/**
	 * Return the path string
	 * @returns {string} path
	 */
	toString () {
		return this.path;
	}
}

/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (Path);


/***/ }),

/***/ 5817:
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(6458);
/* harmony import */ var _path__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(5233);



function request(url, type, withCredentials, headers) {
	var supportsURL = (typeof window != "undefined") ? window.URL : false; // TODO: fallback for url if window isn't defined
	var BLOB_RESPONSE = supportsURL ? "blob" : "arraybuffer";

	var deferred = new _core__WEBPACK_IMPORTED_MODULE_0__.defer();

	var xhr = new XMLHttpRequest();

	//-- Check from PDF.js:
	//   https://github.com/mozilla/pdf.js/blob/master/web/compatibility.js
	var xhrPrototype = XMLHttpRequest.prototype;

	var header;

	if (!("overrideMimeType" in xhrPrototype)) {
		// IE10 might have response, but not overrideMimeType
		Object.defineProperty(xhrPrototype, "overrideMimeType", {
			value: function xmlHttpRequestOverrideMimeType() {}
		});
	}

	if(withCredentials) {
		xhr.withCredentials = true;
	}

	xhr.onreadystatechange = handler;
	xhr.onerror = err;

	xhr.open("GET", url, true);

	for(header in headers) {
		xhr.setRequestHeader(header, headers[header]);
	}

	if(type == "json") {
		xhr.setRequestHeader("Accept", "application/json");
	}

	// If type isn"t set, determine it from the file extension
	if(!type) {
		type = new _path__WEBPACK_IMPORTED_MODULE_1__/* .default */ .Z(url).extension;
	}

	if(type == "blob"){
		xhr.responseType = BLOB_RESPONSE;
	}


	if((0,_core__WEBPACK_IMPORTED_MODULE_0__.isXml)(type)) {
		// xhr.responseType = "document";
		xhr.overrideMimeType("text/xml"); // for OPF parsing
	}

	if(type == "xhtml") {
		// xhr.responseType = "document";
	}

	if(type == "html" || type == "htm") {
		// xhr.responseType = "document";
	}

	if(type == "binary") {
		xhr.responseType = "arraybuffer";
	}

	xhr.send();

	function err(e) {
		deferred.reject(e);
	}

	function handler() {
		if (this.readyState === XMLHttpRequest.DONE) {
			var responseXML = false;

			if(this.responseType === "" || this.responseType === "document") {
				responseXML = this.responseXML;
			}

			if (this.status === 200 || this.status === 0 || responseXML) { //-- Firefox is reporting 0 for blob urls
				var r;

				if (!this.response && !responseXML) {
					deferred.reject({
						status: this.status,
						message : "Empty Response",
						stack : new Error().stack
					});
					return deferred.promise;
				}

				if (this.status === 403) {
					deferred.reject({
						status: this.status,
						response: this.response,
						message : "Forbidden",
						stack : new Error().stack
					});
					return deferred.promise;
				}
				if(responseXML){
					r = this.responseXML;
				} else
				if((0,_core__WEBPACK_IMPORTED_MODULE_0__.isXml)(type)){
					// xhr.overrideMimeType("text/xml"); // for OPF parsing
					// If this.responseXML wasn't set, try to parse using a DOMParser from text
					r = (0,_core__WEBPACK_IMPORTED_MODULE_0__.parse)(this.response, "text/xml");
				}else
				if(type == "xhtml"){
					r = (0,_core__WEBPACK_IMPORTED_MODULE_0__.parse)(this.response, "application/xhtml+xml");
				}else
				if(type == "html" || type == "htm"){
					r = (0,_core__WEBPACK_IMPORTED_MODULE_0__.parse)(this.response, "text/html");
				}else
				if(type == "json"){
					r = JSON.parse(this.response);
				}else
				if(type == "blob"){

					if(supportsURL) {
						r = this.response;
					} else {
						//-- Safari doesn't support responseType blob, so create a blob from arraybuffer
						r = new Blob([this.response]);
					}

				}else{
					r = this.response;
				}

				deferred.resolve(r);
			} else {

				deferred.reject({
					status: this.status,
					message : this.response,
					stack : new Error().stack
				});

			}
		}
	}

	return deferred.promise;
}

/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (request);


/***/ }),

/***/ 430:
/***/ ((module) => {

"use strict";


// eslint-disable-next-line no-empty-function
module.exports = function () {};


/***/ }),

/***/ 7191:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


module.exports = __webpack_require__(2429)() ? Object.assign : __webpack_require__(7346);


/***/ }),

/***/ 2429:
/***/ ((module) => {

"use strict";


module.exports = function () {
	var assign = Object.assign, obj;
	if (typeof assign !== "function") return false;
	obj = { foo: "raz" };
	assign(obj, { bar: "dwa" }, { trzy: "trzy" });
	return obj.foo + obj.bar + obj.trzy === "razdwatrzy";
};


/***/ }),

/***/ 7346:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var keys  = __webpack_require__(5103)
  , value = __webpack_require__(2745)
  , max   = Math.max;

module.exports = function (dest, src/*, …srcn*/) {
	var error, i, length = max(arguments.length, 2), assign;
	dest = Object(value(dest));
	assign = function (key) {
		try {
			dest[key] = src[key];
		} catch (e) {
			if (!error) error = e;
		}
	};
	for (i = 1; i < length; ++i) {
		src = arguments[i];
		keys(src).forEach(assign);
	}
	if (error !== undefined) throw error;
	return dest;
};


/***/ }),

/***/ 6914:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var _undefined = __webpack_require__(430)(); // Support ES3 engines

module.exports = function (val) { return val !== _undefined && val !== null; };


/***/ }),

/***/ 5103:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


module.exports = __webpack_require__(7446)() ? Object.keys : __webpack_require__(6137);


/***/ }),

/***/ 7446:
/***/ ((module) => {

"use strict";


module.exports = function () {
	try {
		Object.keys("primitive");
		return true;
	} catch (e) {
		return false;
	}
};


/***/ }),

/***/ 6137:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isValue = __webpack_require__(6914);

var keys = Object.keys;

module.exports = function (object) { return keys(isValue(object) ? Object(object) : object); };


/***/ }),

/***/ 5516:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isValue = __webpack_require__(6914);

var forEach = Array.prototype.forEach, create = Object.create;

var process = function (src, obj) {
	var key;
	for (key in src) obj[key] = src[key];
};

// eslint-disable-next-line no-unused-vars
module.exports = function (opts1/*, …options*/) {
	var result = create(null);
	forEach.call(arguments, function (options) {
		if (!isValue(options)) return;
		process(Object(options), result);
	});
	return result;
};


/***/ }),

/***/ 1290:
/***/ ((module) => {

"use strict";


module.exports = function (fn) {
	if (typeof fn !== "function") throw new TypeError(fn + " is not a function");
	return fn;
};


/***/ }),

/***/ 2745:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isValue = __webpack_require__(6914);

module.exports = function (value) {
	if (!isValue(value)) throw new TypeError("Cannot use null or undefined");
	return value;
};


/***/ }),

/***/ 9981:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


module.exports = __webpack_require__(3591)() ? String.prototype.contains : __webpack_require__(6042);


/***/ }),

/***/ 3591:
/***/ ((module) => {

"use strict";


var str = "razdwatrzy";

module.exports = function () {
	if (typeof str.contains !== "function") return false;
	return str.contains("dwa") === true && str.contains("foo") === false;
};


/***/ }),

/***/ 6042:
/***/ ((module) => {

"use strict";


var indexOf = String.prototype.indexOf;

module.exports = function (searchString/*, position*/) {
	return indexOf.call(this, searchString, arguments[1]) > -1;
};


/***/ }),

/***/ 8370:
/***/ ((module, exports, __webpack_require__) => {

"use strict";


var d        = __webpack_require__(1804)
  , callable = __webpack_require__(1290)

  , apply = Function.prototype.apply, call = Function.prototype.call
  , create = Object.create, defineProperty = Object.defineProperty
  , defineProperties = Object.defineProperties
  , hasOwnProperty = Object.prototype.hasOwnProperty
  , descriptor = { configurable: true, enumerable: false, writable: true }

  , on, once, off, emit, methods, descriptors, base;

on = function (type, listener) {
	var data;

	callable(listener);

	if (!hasOwnProperty.call(this, '__ee__')) {
		data = descriptor.value = create(null);
		defineProperty(this, '__ee__', descriptor);
		descriptor.value = null;
	} else {
		data = this.__ee__;
	}
	if (!data[type]) data[type] = listener;
	else if (typeof data[type] === 'object') data[type].push(listener);
	else data[type] = [data[type], listener];

	return this;
};

once = function (type, listener) {
	var once, self;

	callable(listener);
	self = this;
	on.call(this, type, once = function () {
		off.call(self, type, once);
		apply.call(listener, this, arguments);
	});

	once.__eeOnceListener__ = listener;
	return this;
};

off = function (type, listener) {
	var data, listeners, candidate, i;

	callable(listener);

	if (!hasOwnProperty.call(this, '__ee__')) return this;
	data = this.__ee__;
	if (!data[type]) return this;
	listeners = data[type];

	if (typeof listeners === 'object') {
		for (i = 0; (candidate = listeners[i]); ++i) {
			if ((candidate === listener) ||
					(candidate.__eeOnceListener__ === listener)) {
				if (listeners.length === 2) data[type] = listeners[i ? 0 : 1];
				else listeners.splice(i, 1);
			}
		}
	} else {
		if ((listeners === listener) ||
				(listeners.__eeOnceListener__ === listener)) {
			delete data[type];
		}
	}

	return this;
};

emit = function (type) {
	var i, l, listener, listeners, args;

	if (!hasOwnProperty.call(this, '__ee__')) return;
	listeners = this.__ee__[type];
	if (!listeners) return;

	if (typeof listeners === 'object') {
		l = arguments.length;
		args = new Array(l - 1);
		for (i = 1; i < l; ++i) args[i - 1] = arguments[i];

		listeners = listeners.slice();
		for (i = 0; (listener = listeners[i]); ++i) {
			apply.call(listener, this, args);
		}
	} else {
		switch (arguments.length) {
		case 1:
			call.call(listeners, this);
			break;
		case 2:
			call.call(listeners, this, arguments[1]);
			break;
		case 3:
			call.call(listeners, this, arguments[1], arguments[2]);
			break;
		default:
			l = arguments.length;
			args = new Array(l - 1);
			for (i = 1; i < l; ++i) {
				args[i - 1] = arguments[i];
			}
			apply.call(listeners, this, args);
		}
	}
};

methods = {
	on: on,
	once: once,
	off: off,
	emit: emit
};

descriptors = {
	on: d(on),
	once: d(once),
	off: d(off),
	emit: d(emit)
};

base = defineProperties({}, descriptors);

module.exports = exports = function (o) {
	return (o == null) ? create(base) : defineProperties(Object(o), descriptors);
};
exports.methods = methods;


/***/ }),

/***/ 5733:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

/*!

JSZip v3.6.0 - A JavaScript class for generating and reading zip files
<http://stuartk.com/jszip>

(c) 2009-2016 Stuart Knightley <stuart [at] stuartk.com>
Dual licenced under the MIT license or GPLv3. See https://raw.github.com/Stuk/jszip/master/LICENSE.markdown.

JSZip uses the library pako released under the MIT license :
https://github.com/nodeca/pako/blob/master/LICENSE
*/

!function(e){if(true)module.exports=e();else {}}(function(){return function s(a,o,u){function h(r,e){if(!o[r]){if(!a[r]){var t=undefined;if(!e&&t)return require(r,!0);if(f)return f(r,!0);var n=new Error("Cannot find module '"+r+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[r]={exports:{}};a[r][0].call(i.exports,function(e){var t=a[r][1][e];return h(t||e)},i,i.exports,s,a,o,u)}return o[r].exports}for(var f=undefined,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(l,t,n){(function(r){!function(e){"object"==typeof n&&void 0!==t?t.exports=e():("undefined"!=typeof window?window:void 0!==r?r:"undefined"!=typeof self?self:this).JSZip=e()}(function(){return function s(a,o,u){function h(t,e){if(!o[t]){if(!a[t]){var r="function"==typeof l&&l;if(!e&&r)return r(t,!0);if(f)return f(t,!0);var n=new Error("Cannot find module '"+t+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[t]={exports:{}};a[t][0].call(i.exports,function(e){return h(a[t][1][e]||e)},i,i.exports,s,a,o,u)}return o[t].exports}for(var f="function"==typeof l&&l,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(l,t,n){(function(r){!function(e){"object"==typeof n&&void 0!==t?t.exports=e():("undefined"!=typeof window?window:void 0!==r?r:"undefined"!=typeof self?self:this).JSZip=e()}(function(){return function s(a,o,u){function h(t,e){if(!o[t]){if(!a[t]){var r="function"==typeof l&&l;if(!e&&r)return r(t,!0);if(f)return f(t,!0);var n=new Error("Cannot find module '"+t+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[t]={exports:{}};a[t][0].call(i.exports,function(e){return h(a[t][1][e]||e)},i,i.exports,s,a,o,u)}return o[t].exports}for(var f="function"==typeof l&&l,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(l,t,n){(function(r){!function(e){"object"==typeof n&&void 0!==t?t.exports=e():("undefined"!=typeof window?window:void 0!==r?r:"undefined"!=typeof self?self:this).JSZip=e()}(function(){return function s(a,o,u){function h(t,e){if(!o[t]){if(!a[t]){var r="function"==typeof l&&l;if(!e&&r)return r(t,!0);if(f)return f(t,!0);var n=new Error("Cannot find module '"+t+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[t]={exports:{}};a[t][0].call(i.exports,function(e){return h(a[t][1][e]||e)},i,i.exports,s,a,o,u)}return o[t].exports}for(var f="function"==typeof l&&l,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(l,t,n){(function(r){!function(e){"object"==typeof n&&void 0!==t?t.exports=e():("undefined"!=typeof window?window:void 0!==r?r:"undefined"!=typeof self?self:this).JSZip=e()}(function(){return function s(a,o,u){function h(t,e){if(!o[t]){if(!a[t]){var r="function"==typeof l&&l;if(!e&&r)return r(t,!0);if(f)return f(t,!0);var n=new Error("Cannot find module '"+t+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[t]={exports:{}};a[t][0].call(i.exports,function(e){return h(a[t][1][e]||e)},i,i.exports,s,a,o,u)}return o[t].exports}for(var f="function"==typeof l&&l,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(l,t,n){(function(r){!function(e){"object"==typeof n&&void 0!==t?t.exports=e():("undefined"!=typeof window?window:void 0!==r?r:"undefined"!=typeof self?self:this).JSZip=e()}(function(){return function s(a,o,u){function h(t,e){if(!o[t]){if(!a[t]){var r="function"==typeof l&&l;if(!e&&r)return r(t,!0);if(f)return f(t,!0);var n=new Error("Cannot find module '"+t+"'");throw n.code="MODULE_NOT_FOUND",n}var i=o[t]={exports:{}};a[t][0].call(i.exports,function(e){return h(a[t][1][e]||e)},i,i.exports,s,a,o,u)}return o[t].exports}for(var f="function"==typeof l&&l,e=0;e<u.length;e++)h(u[e]);return h}({1:[function(e,t,r){"use strict";var c=e("./utils"),l=e("./support"),p="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";r.encode=function(e){for(var t,r,n,i,s,a,o,u=[],h=0,f=e.length,l=f,d="string"!==c.getTypeOf(e);h<e.length;)l=f-h,n=d?(t=e[h++],r=h<f?e[h++]:0,h<f?e[h++]:0):(t=e.charCodeAt(h++),r=h<f?e.charCodeAt(h++):0,h<f?e.charCodeAt(h++):0),i=t>>2,s=(3&t)<<4|r>>4,a=1<l?(15&r)<<2|n>>6:64,o=2<l?63&n:64,u.push(p.charAt(i)+p.charAt(s)+p.charAt(a)+p.charAt(o));return u.join("")},r.decode=function(e){var t,r,n,i,s,a,o=0,u=0;if("data:"===e.substr(0,"data:".length))throw new Error("Invalid base64 input, it looks like a data url.");var h,f=3*(e=e.replace(/[^A-Za-z0-9\+\/\=]/g,"")).length/4;if(e.charAt(e.length-1)===p.charAt(64)&&f--,e.charAt(e.length-2)===p.charAt(64)&&f--,f%1!=0)throw new Error("Invalid base64 input, bad content length.");for(h=l.uint8array?new Uint8Array(0|f):new Array(0|f);o<e.length;)t=p.indexOf(e.charAt(o++))<<2|(i=p.indexOf(e.charAt(o++)))>>4,r=(15&i)<<4|(s=p.indexOf(e.charAt(o++)))>>2,n=(3&s)<<6|(a=p.indexOf(e.charAt(o++))),h[u++]=t,64!==s&&(h[u++]=r),64!==a&&(h[u++]=n);return h}},{"./support":30,"./utils":32}],2:[function(e,t,r){"use strict";var n=e("./external"),i=e("./stream/DataWorker"),s=e("./stream/Crc32Probe"),a=e("./stream/DataLengthProbe");function o(e,t,r,n,i){this.compressedSize=e,this.uncompressedSize=t,this.crc32=r,this.compression=n,this.compressedContent=i}o.prototype={getContentWorker:function(){var e=new i(n.Promise.resolve(this.compressedContent)).pipe(this.compression.uncompressWorker()).pipe(new a("data_length")),t=this;return e.on("end",function(){if(this.streamInfo.data_length!==t.uncompressedSize)throw new Error("Bug : uncompressed data size mismatch")}),e},getCompressedWorker:function(){return new i(n.Promise.resolve(this.compressedContent)).withStreamInfo("compressedSize",this.compressedSize).withStreamInfo("uncompressedSize",this.uncompressedSize).withStreamInfo("crc32",this.crc32).withStreamInfo("compression",this.compression)}},o.createWorkerFrom=function(e,t,r){return e.pipe(new s).pipe(new a("uncompressedSize")).pipe(t.compressWorker(r)).pipe(new a("compressedSize")).withStreamInfo("compression",t)},t.exports=o},{"./external":6,"./stream/Crc32Probe":25,"./stream/DataLengthProbe":26,"./stream/DataWorker":27}],3:[function(e,t,r){"use strict";var n=e("./stream/GenericWorker");r.STORE={magic:"\0\0",compressWorker:function(e){return new n("STORE compression")},uncompressWorker:function(){return new n("STORE decompression")}},r.DEFLATE=e("./flate")},{"./flate":7,"./stream/GenericWorker":28}],4:[function(e,t,r){"use strict";var n=e("./utils"),a=function(){for(var e,t=[],r=0;r<256;r++){e=r;for(var n=0;n<8;n++)e=1&e?3988292384^e>>>1:e>>>1;t[r]=e}return t}();t.exports=function(e,t){return void 0!==e&&e.length?"string"!==n.getTypeOf(e)?function(e,t,r){var n=a,i=0+r;e^=-1;for(var s=0;s<i;s++)e=e>>>8^n[255&(e^t[s])];return-1^e}(0|t,e,e.length):function(e,t,r){var n=a,i=0+r;e^=-1;for(var s=0;s<i;s++)e=e>>>8^n[255&(e^t.charCodeAt(s))];return-1^e}(0|t,e,e.length):0}},{"./utils":32}],5:[function(e,t,r){"use strict";r.base64=!1,r.binary=!1,r.dir=!1,r.createFolders=!0,r.date=null,r.compression=null,r.compressionOptions=null,r.comment=null,r.unixPermissions=null,r.dosPermissions=null},{}],6:[function(e,t,r){"use strict";var n;n="undefined"!=typeof Promise?Promise:e("lie"),t.exports={Promise:n}},{lie:37}],7:[function(e,t,r){"use strict";var n="undefined"!=typeof Uint8Array&&"undefined"!=typeof Uint16Array&&"undefined"!=typeof Uint32Array,i=e("pako"),s=e("./utils"),a=e("./stream/GenericWorker"),o=n?"uint8array":"array";function u(e,t){a.call(this,"FlateWorker/"+e),this._pako=null,this._pakoAction=e,this._pakoOptions=t,this.meta={}}r.magic="\b\0",s.inherits(u,a),u.prototype.processChunk=function(e){this.meta=e.meta,null===this._pako&&this._createPako(),this._pako.push(s.transformTo(o,e.data),!1)},u.prototype.flush=function(){a.prototype.flush.call(this),null===this._pako&&this._createPako(),this._pako.push([],!0)},u.prototype.cleanUp=function(){a.prototype.cleanUp.call(this),this._pako=null},u.prototype._createPako=function(){this._pako=new i[this._pakoAction]({raw:!0,level:this._pakoOptions.level||-1});var t=this;this._pako.onData=function(e){t.push({data:e,meta:t.meta})}},r.compressWorker=function(e){return new u("Deflate",e)},r.uncompressWorker=function(){return new u("Inflate",{})}},{"./stream/GenericWorker":28,"./utils":32,pako:38}],8:[function(e,t,r){"use strict";function I(e,t){var r,n="";for(r=0;r<t;r++)n+=String.fromCharCode(255&e),e>>>=8;return n}function i(e,t,r,n,i,s){var a,o,u=e.file,h=e.compression,f=s!==B.utf8encode,l=O.transformTo("string",s(u.name)),d=O.transformTo("string",B.utf8encode(u.name)),c=u.comment,p=O.transformTo("string",s(c)),m=O.transformTo("string",B.utf8encode(c)),_=d.length!==u.name.length,g=m.length!==c.length,v="",b="",w="",y=u.dir,k=u.date,x={crc32:0,compressedSize:0,uncompressedSize:0};t&&!r||(x.crc32=e.crc32,x.compressedSize=e.compressedSize,x.uncompressedSize=e.uncompressedSize);var S=0;t&&(S|=8),f||!_&&!g||(S|=2048);var z,E=0,C=0;y&&(E|=16),"UNIX"===i?(C=798,E|=((z=u.unixPermissions)||(z=y?16893:33204),(65535&z)<<16)):(C=20,E|=63&(u.dosPermissions||0)),a=k.getUTCHours(),a<<=6,a|=k.getUTCMinutes(),a<<=5,a|=k.getUTCSeconds()/2,o=k.getUTCFullYear()-1980,o<<=4,o|=k.getUTCMonth()+1,o<<=5,o|=k.getUTCDate(),_&&(v+="up"+I((b=I(1,1)+I(T(l),4)+d).length,2)+b),g&&(v+="uc"+I((w=I(1,1)+I(T(p),4)+m).length,2)+w);var A="";return A+="\n\0",A+=I(S,2),A+=h.magic,A+=I(a,2),A+=I(o,2),A+=I(x.crc32,4),A+=I(x.compressedSize,4),A+=I(x.uncompressedSize,4),A+=I(l.length,2),A+=I(v.length,2),{fileRecord:R.LOCAL_FILE_HEADER+A+l+v,dirRecord:R.CENTRAL_FILE_HEADER+I(C,2)+A+I(p.length,2)+"\0\0\0\0"+I(E,4)+I(n,4)+l+v+p}}var O=e("../utils"),s=e("../stream/GenericWorker"),B=e("../utf8"),T=e("../crc32"),R=e("../signature");function n(e,t,r,n){s.call(this,"ZipFileWorker"),this.bytesWritten=0,this.zipComment=t,this.zipPlatform=r,this.encodeFileName=n,this.streamFiles=e,this.accumulate=!1,this.contentBuffer=[],this.dirRecords=[],this.currentSourceOffset=0,this.entriesCount=0,this.currentFile=null,this._sources=[]}O.inherits(n,s),n.prototype.push=function(e){var t=e.meta.percent||0,r=this.entriesCount,n=this._sources.length;this.accumulate?this.contentBuffer.push(e):(this.bytesWritten+=e.data.length,s.prototype.push.call(this,{data:e.data,meta:{currentFile:this.currentFile,percent:r?(t+100*(r-n-1))/r:100}}))},n.prototype.openedSource=function(e){this.currentSourceOffset=this.bytesWritten,this.currentFile=e.file.name;var t=this.streamFiles&&!e.file.dir;if(t){var r=i(e,t,!1,this.currentSourceOffset,this.zipPlatform,this.encodeFileName);this.push({data:r.fileRecord,meta:{percent:0}})}else this.accumulate=!0},n.prototype.closedSource=function(e){this.accumulate=!1;var t,r=this.streamFiles&&!e.file.dir,n=i(e,r,!0,this.currentSourceOffset,this.zipPlatform,this.encodeFileName);if(this.dirRecords.push(n.dirRecord),r)this.push({data:(t=e,R.DATA_DESCRIPTOR+I(t.crc32,4)+I(t.compressedSize,4)+I(t.uncompressedSize,4)),meta:{percent:100}});else for(this.push({data:n.fileRecord,meta:{percent:0}});this.contentBuffer.length;)this.push(this.contentBuffer.shift());this.currentFile=null},n.prototype.flush=function(){for(var e=this.bytesWritten,t=0;t<this.dirRecords.length;t++)this.push({data:this.dirRecords[t],meta:{percent:100}});var r,n,i,s,a,o,u=this.bytesWritten-e,h=(r=this.dirRecords.length,n=u,i=e,s=this.zipComment,a=this.encodeFileName,o=O.transformTo("string",a(s)),R.CENTRAL_DIRECTORY_END+"\0\0\0\0"+I(r,2)+I(r,2)+I(n,4)+I(i,4)+I(o.length,2)+o);this.push({data:h,meta:{percent:100}})},n.prototype.prepareNextSource=function(){this.previous=this._sources.shift(),this.openedSource(this.previous.streamInfo),this.isPaused?this.previous.pause():this.previous.resume()},n.prototype.registerPrevious=function(e){this._sources.push(e);var t=this;return e.on("data",function(e){t.processChunk(e)}),e.on("end",function(){t.closedSource(t.previous.streamInfo),t._sources.length?t.prepareNextSource():t.end()}),e.on("error",function(e){t.error(e)}),this},n.prototype.resume=function(){return!!s.prototype.resume.call(this)&&(!this.previous&&this._sources.length?(this.prepareNextSource(),!0):this.previous||this._sources.length||this.generatedError?void 0:(this.end(),!0))},n.prototype.error=function(e){var t=this._sources;if(!s.prototype.error.call(this,e))return!1;for(var r=0;r<t.length;r++)try{t[r].error(e)}catch(e){}return!0},n.prototype.lock=function(){s.prototype.lock.call(this);for(var e=this._sources,t=0;t<e.length;t++)e[t].lock()},t.exports=n},{"../crc32":4,"../signature":23,"../stream/GenericWorker":28,"../utf8":31,"../utils":32}],9:[function(e,t,r){"use strict";var h=e("../compressions"),n=e("./ZipFileWorker");r.generateWorker=function(e,a,t){var o=new n(a.streamFiles,t,a.platform,a.encodeFileName),u=0;try{e.forEach(function(e,t){u++;var r=function(e,t){var r=e||t,n=h[r];if(!n)throw new Error(r+" is not a valid compression method !");return n}(t.options.compression,a.compression),n=t.options.compressionOptions||a.compressionOptions||{},i=t.dir,s=t.date;t._compressWorker(r,n).withStreamInfo("file",{name:e,dir:i,date:s,comment:t.comment||"",unixPermissions:t.unixPermissions,dosPermissions:t.dosPermissions}).pipe(o)}),o.entriesCount=u}catch(e){o.error(e)}return o}},{"../compressions":3,"./ZipFileWorker":8}],10:[function(e,t,r){"use strict";function n(){if(!(this instanceof n))return new n;if(arguments.length)throw new Error("The constructor with parameters has been removed in JSZip 3.0, please check the upgrade guide.");this.files={},this.comment=null,this.root="",this.clone=function(){var e=new n;for(var t in this)"function"!=typeof this[t]&&(e[t]=this[t]);return e}}(n.prototype=e("./object")).loadAsync=e("./load"),n.support=e("./support"),n.defaults=e("./defaults"),n.version="3.5.0",n.loadAsync=function(e,t){return(new n).loadAsync(e,t)},n.external=e("./external"),t.exports=n},{"./defaults":5,"./external":6,"./load":11,"./object":15,"./support":30}],11:[function(e,t,r){"use strict";var n=e("./utils"),i=e("./external"),o=e("./utf8"),u=e("./zipEntries"),s=e("./stream/Crc32Probe"),h=e("./nodejsUtils");function f(n){return new i.Promise(function(e,t){var r=n.decompressed.getContentWorker().pipe(new s);r.on("error",function(e){t(e)}).on("end",function(){r.streamInfo.crc32!==n.decompressed.crc32?t(new Error("Corrupted zip : CRC32 mismatch")):e()}).resume()})}t.exports=function(e,s){var a=this;return s=n.extend(s||{},{base64:!1,checkCRC32:!1,optimizedBinaryString:!1,createFolders:!1,decodeFileName:o.utf8decode}),h.isNode&&h.isStream(e)?i.Promise.reject(new Error("JSZip can't accept a stream when loading a zip file.")):n.prepareContent("the loaded zip file",e,!0,s.optimizedBinaryString,s.base64).then(function(e){var t=new u(s);return t.load(e),t}).then(function(e){var t=[i.Promise.resolve(e)],r=e.files;if(s.checkCRC32)for(var n=0;n<r.length;n++)t.push(f(r[n]));return i.Promise.all(t)}).then(function(e){for(var t=e.shift(),r=t.files,n=0;n<r.length;n++){var i=r[n];a.file(i.fileNameStr,i.decompressed,{binary:!0,optimizedBinaryString:!0,date:i.date,dir:i.dir,comment:i.fileCommentStr.length?i.fileCommentStr:null,unixPermissions:i.unixPermissions,dosPermissions:i.dosPermissions,createFolders:s.createFolders})}return t.zipComment.length&&(a.comment=t.zipComment),a})}},{"./external":6,"./nodejsUtils":14,"./stream/Crc32Probe":25,"./utf8":31,"./utils":32,"./zipEntries":33}],12:[function(e,t,r){"use strict";var n=e("../utils"),i=e("../stream/GenericWorker");function s(e,t){i.call(this,"Nodejs stream input adapter for "+e),this._upstreamEnded=!1,this._bindStream(t)}n.inherits(s,i),s.prototype._bindStream=function(e){var t=this;(this._stream=e).pause(),e.on("data",function(e){t.push({data:e,meta:{percent:0}})}).on("error",function(e){t.isPaused?this.generatedError=e:t.error(e)}).on("end",function(){t.isPaused?t._upstreamEnded=!0:t.end()})},s.prototype.pause=function(){return!!i.prototype.pause.call(this)&&(this._stream.pause(),!0)},s.prototype.resume=function(){return!!i.prototype.resume.call(this)&&(this._upstreamEnded?this.end():this._stream.resume(),!0)},t.exports=s},{"../stream/GenericWorker":28,"../utils":32}],13:[function(e,t,r){"use strict";var i=e("readable-stream").Readable;function n(e,t,r){i.call(this,t),this._helper=e;var n=this;e.on("data",function(e,t){n.push(e)||n._helper.pause(),r&&r(t)}).on("error",function(e){n.emit("error",e)}).on("end",function(){n.push(null)})}e("../utils").inherits(n,i),n.prototype._read=function(){this._helper.resume()},t.exports=n},{"../utils":32,"readable-stream":16}],14:[function(e,t,r){"use strict";t.exports={isNode:"undefined"!=typeof Buffer,newBufferFrom:function(e,t){if(Buffer.from&&Buffer.from!==Uint8Array.from)return Buffer.from(e,t);if("number"==typeof e)throw new Error('The "data" argument must not be a number');return new Buffer(e,t)},allocBuffer:function(e){if(Buffer.alloc)return Buffer.alloc(e);var t=new Buffer(e);return t.fill(0),t},isBuffer:function(e){return Buffer.isBuffer(e)},isStream:function(e){return e&&"function"==typeof e.on&&"function"==typeof e.pause&&"function"==typeof e.resume}}},{}],15:[function(e,t,r){"use strict";function s(e,t,r){var n,i=f.getTypeOf(t),s=f.extend(r||{},d);s.date=s.date||new Date,null!==s.compression&&(s.compression=s.compression.toUpperCase()),"string"==typeof s.unixPermissions&&(s.unixPermissions=parseInt(s.unixPermissions,8)),s.unixPermissions&&16384&s.unixPermissions&&(s.dir=!0),s.dosPermissions&&16&s.dosPermissions&&(s.dir=!0),s.dir&&(e=h(e)),s.createFolders&&(n=function(e){"/"===e.slice(-1)&&(e=e.substring(0,e.length-1));var t=e.lastIndexOf("/");return 0<t?e.substring(0,t):""}(e))&&g.call(this,n,!0);var a,o="string"===i&&!1===s.binary&&!1===s.base64;r&&void 0!==r.binary||(s.binary=!o),(t instanceof c&&0===t.uncompressedSize||s.dir||!t||0===t.length)&&(s.base64=!1,s.binary=!0,t="",s.compression="STORE",i="string"),a=t instanceof c||t instanceof l?t:m.isNode&&m.isStream(t)?new _(e,t):f.prepareContent(e,t,s.binary,s.optimizedBinaryString,s.base64);var u=new p(e,a,s);this.files[e]=u}function h(e){return"/"!==e.slice(-1)&&(e+="/"),e}var i=e("./utf8"),f=e("./utils"),l=e("./stream/GenericWorker"),a=e("./stream/StreamHelper"),d=e("./defaults"),c=e("./compressedObject"),p=e("./zipObject"),o=e("./generate"),m=e("./nodejsUtils"),_=e("./nodejs/NodejsStreamInputAdapter"),g=function(e,t){return t=void 0!==t?t:d.createFolders,e=h(e),this.files[e]||s.call(this,e,null,{dir:!0,createFolders:t}),this.files[e]};function u(e){return"[object RegExp]"===Object.prototype.toString.call(e)}var n={load:function(){throw new Error("This method has been removed in JSZip 3.0, please check the upgrade guide.")},forEach:function(e){var t,r,n;for(t in this.files)this.files.hasOwnProperty(t)&&(n=this.files[t],(r=t.slice(this.root.length,t.length))&&t.slice(0,this.root.length)===this.root&&e(r,n))},filter:function(r){var n=[];return this.forEach(function(e,t){r(e,t)&&n.push(t)}),n},file:function(e,t,r){if(1!==arguments.length)return e=this.root+e,s.call(this,e,t,r),this;if(u(e)){var n=e;return this.filter(function(e,t){return!t.dir&&n.test(e)})}var i=this.files[this.root+e];return i&&!i.dir?i:null},folder:function(r){if(!r)return this;if(u(r))return this.filter(function(e,t){return t.dir&&r.test(e)});var e=this.root+r,t=g.call(this,e),n=this.clone();return n.root=t.name,n},remove:function(r){r=this.root+r;var e=this.files[r];if(e||("/"!==r.slice(-1)&&(r+="/"),e=this.files[r]),e&&!e.dir)delete this.files[r];else for(var t=this.filter(function(e,t){return t.name.slice(0,r.length)===r}),n=0;n<t.length;n++)delete this.files[t[n].name];return this},generate:function(e){throw new Error("This method has been removed in JSZip 3.0, please check the upgrade guide.")},generateInternalStream:function(e){var t,r={};try{if((r=f.extend(e||{},{streamFiles:!1,compression:"STORE",compressionOptions:null,type:"",platform:"DOS",comment:null,mimeType:"application/zip",encodeFileName:i.utf8encode})).type=r.type.toLowerCase(),r.compression=r.compression.toUpperCase(),"binarystring"===r.type&&(r.type="string"),!r.type)throw new Error("No output type specified.");f.checkSupport(r.type),"darwin"!==r.platform&&"freebsd"!==r.platform&&"linux"!==r.platform&&"sunos"!==r.platform||(r.platform="UNIX"),"win32"===r.platform&&(r.platform="DOS");var n=r.comment||this.comment||"";t=o.generateWorker(this,r,n)}catch(e){(t=new l("error")).error(e)}return new a(t,r.type||"string",r.mimeType)},generateAsync:function(e,t){return this.generateInternalStream(e).accumulate(t)},generateNodeStream:function(e,t){return(e=e||{}).type||(e.type="nodebuffer"),this.generateInternalStream(e).toNodejsStream(t)}};t.exports=n},{"./compressedObject":2,"./defaults":5,"./generate":9,"./nodejs/NodejsStreamInputAdapter":12,"./nodejsUtils":14,"./stream/GenericWorker":28,"./stream/StreamHelper":29,"./utf8":31,"./utils":32,"./zipObject":35}],16:[function(e,t,r){t.exports=e("stream")},{stream:void 0}],17:[function(e,t,r){"use strict";var n=e("./DataReader");function i(e){n.call(this,e);for(var t=0;t<this.data.length;t++)e[t]=255&e[t]}e("../utils").inherits(i,n),i.prototype.byteAt=function(e){return this.data[this.zero+e]},i.prototype.lastIndexOfSignature=function(e){for(var t=e.charCodeAt(0),r=e.charCodeAt(1),n=e.charCodeAt(2),i=e.charCodeAt(3),s=this.length-4;0<=s;--s)if(this.data[s]===t&&this.data[s+1]===r&&this.data[s+2]===n&&this.data[s+3]===i)return s-this.zero;return-1},i.prototype.readAndCheckSignature=function(e){var t=e.charCodeAt(0),r=e.charCodeAt(1),n=e.charCodeAt(2),i=e.charCodeAt(3),s=this.readData(4);return t===s[0]&&r===s[1]&&n===s[2]&&i===s[3]},i.prototype.readData=function(e){if(this.checkOffset(e),0===e)return[];var t=this.data.slice(this.zero+this.index,this.zero+this.index+e);return this.index+=e,t},t.exports=i},{"../utils":32,"./DataReader":18}],18:[function(e,t,r){"use strict";var n=e("../utils");function i(e){this.data=e,this.length=e.length,this.index=0,this.zero=0}i.prototype={checkOffset:function(e){this.checkIndex(this.index+e)},checkIndex:function(e){if(this.length<this.zero+e||e<0)throw new Error("End of data reached (data length = "+this.length+", asked index = "+e+"). Corrupted zip ?")},setIndex:function(e){this.checkIndex(e),this.index=e},skip:function(e){this.setIndex(this.index+e)},byteAt:function(e){},readInt:function(e){var t,r=0;for(this.checkOffset(e),t=this.index+e-1;t>=this.index;t--)r=(r<<8)+this.byteAt(t);return this.index+=e,r},readString:function(e){return n.transformTo("string",this.readData(e))},readData:function(e){},lastIndexOfSignature:function(e){},readAndCheckSignature:function(e){},readDate:function(){var e=this.readInt(4);return new Date(Date.UTC(1980+(e>>25&127),(e>>21&15)-1,e>>16&31,e>>11&31,e>>5&63,(31&e)<<1))}},t.exports=i},{"../utils":32}],19:[function(e,t,r){"use strict";var n=e("./Uint8ArrayReader");function i(e){n.call(this,e)}e("../utils").inherits(i,n),i.prototype.readData=function(e){this.checkOffset(e);var t=this.data.slice(this.zero+this.index,this.zero+this.index+e);return this.index+=e,t},t.exports=i},{"../utils":32,"./Uint8ArrayReader":21}],20:[function(e,t,r){"use strict";var n=e("./DataReader");function i(e){n.call(this,e)}e("../utils").inherits(i,n),i.prototype.byteAt=function(e){return this.data.charCodeAt(this.zero+e)},i.prototype.lastIndexOfSignature=function(e){return this.data.lastIndexOf(e)-this.zero},i.prototype.readAndCheckSignature=function(e){return e===this.readData(4)},i.prototype.readData=function(e){this.checkOffset(e);var t=this.data.slice(this.zero+this.index,this.zero+this.index+e);return this.index+=e,t},t.exports=i},{"../utils":32,"./DataReader":18}],21:[function(e,t,r){"use strict";var n=e("./ArrayReader");function i(e){n.call(this,e)}e("../utils").inherits(i,n),i.prototype.readData=function(e){if(this.checkOffset(e),0===e)return new Uint8Array(0);var t=this.data.subarray(this.zero+this.index,this.zero+this.index+e);return this.index+=e,t},t.exports=i},{"../utils":32,"./ArrayReader":17}],22:[function(e,t,r){"use strict";var n=e("../utils"),i=e("../support"),s=e("./ArrayReader"),a=e("./StringReader"),o=e("./NodeBufferReader"),u=e("./Uint8ArrayReader");t.exports=function(e){var t=n.getTypeOf(e);return n.checkSupport(t),"string"!==t||i.uint8array?"nodebuffer"===t?new o(e):i.uint8array?new u(n.transformTo("uint8array",e)):new s(n.transformTo("array",e)):new a(e)}},{"../support":30,"../utils":32,"./ArrayReader":17,"./NodeBufferReader":19,"./StringReader":20,"./Uint8ArrayReader":21}],23:[function(e,t,r){"use strict";r.LOCAL_FILE_HEADER="PK",r.CENTRAL_FILE_HEADER="PK",r.CENTRAL_DIRECTORY_END="PK",r.ZIP64_CENTRAL_DIRECTORY_LOCATOR="PK",r.ZIP64_CENTRAL_DIRECTORY_END="PK",r.DATA_DESCRIPTOR="PK\b"},{}],24:[function(e,t,r){"use strict";var n=e("./GenericWorker"),i=e("../utils");function s(e){n.call(this,"ConvertWorker to "+e),this.destType=e}i.inherits(s,n),s.prototype.processChunk=function(e){this.push({data:i.transformTo(this.destType,e.data),meta:e.meta})},t.exports=s},{"../utils":32,"./GenericWorker":28}],25:[function(e,t,r){"use strict";var n=e("./GenericWorker"),i=e("../crc32");function s(){n.call(this,"Crc32Probe"),this.withStreamInfo("crc32",0)}e("../utils").inherits(s,n),s.prototype.processChunk=function(e){this.streamInfo.crc32=i(e.data,this.streamInfo.crc32||0),this.push(e)},t.exports=s},{"../crc32":4,"../utils":32,"./GenericWorker":28}],26:[function(e,t,r){"use strict";var n=e("../utils"),i=e("./GenericWorker");function s(e){i.call(this,"DataLengthProbe for "+e),this.propName=e,this.withStreamInfo(e,0)}n.inherits(s,i),s.prototype.processChunk=function(e){if(e){var t=this.streamInfo[this.propName]||0;this.streamInfo[this.propName]=t+e.data.length}i.prototype.processChunk.call(this,e)},t.exports=s},{"../utils":32,"./GenericWorker":28}],27:[function(e,t,r){"use strict";var n=e("../utils"),i=e("./GenericWorker");function s(e){i.call(this,"DataWorker");var t=this;this.dataIsReady=!1,this.index=0,this.max=0,this.data=null,this.type="",this._tickScheduled=!1,e.then(function(e){t.dataIsReady=!0,t.data=e,t.max=e&&e.length||0,t.type=n.getTypeOf(e),t.isPaused||t._tickAndRepeat()},function(e){t.error(e)})}n.inherits(s,i),s.prototype.cleanUp=function(){i.prototype.cleanUp.call(this),this.data=null},s.prototype.resume=function(){return!!i.prototype.resume.call(this)&&(!this._tickScheduled&&this.dataIsReady&&(this._tickScheduled=!0,n.delay(this._tickAndRepeat,[],this)),!0)},s.prototype._tickAndRepeat=function(){this._tickScheduled=!1,this.isPaused||this.isFinished||(this._tick(),this.isFinished||(n.delay(this._tickAndRepeat,[],this),this._tickScheduled=!0))},s.prototype._tick=function(){if(this.isPaused||this.isFinished)return!1;var e=null,t=Math.min(this.max,this.index+16384);if(this.index>=this.max)return this.end();switch(this.type){case"string":e=this.data.substring(this.index,t);break;case"uint8array":e=this.data.subarray(this.index,t);break;case"array":case"nodebuffer":e=this.data.slice(this.index,t)}return this.index=t,this.push({data:e,meta:{percent:this.max?this.index/this.max*100:0}})},t.exports=s},{"../utils":32,"./GenericWorker":28}],28:[function(e,t,r){"use strict";function n(e){this.name=e||"default",this.streamInfo={},this.generatedError=null,this.extraStreamInfo={},this.isPaused=!0,this.isFinished=!1,this.isLocked=!1,this._listeners={data:[],end:[],error:[]},this.previous=null}n.prototype={push:function(e){this.emit("data",e)},end:function(){if(this.isFinished)return!1;this.flush();try{this.emit("end"),this.cleanUp(),this.isFinished=!0}catch(e){this.emit("error",e)}return!0},error:function(e){return!this.isFinished&&(this.isPaused?this.generatedError=e:(this.isFinished=!0,this.emit("error",e),this.previous&&this.previous.error(e),this.cleanUp()),!0)},on:function(e,t){return this._listeners[e].push(t),this},cleanUp:function(){this.streamInfo=this.generatedError=this.extraStreamInfo=null,this._listeners=[]},emit:function(e,t){if(this._listeners[e])for(var r=0;r<this._listeners[e].length;r++)this._listeners[e][r].call(this,t)},pipe:function(e){return e.registerPrevious(this)},registerPrevious:function(e){if(this.isLocked)throw new Error("The stream '"+this+"' has already been used.");this.streamInfo=e.streamInfo,this.mergeStreamInfo(),this.previous=e;var t=this;return e.on("data",function(e){t.processChunk(e)}),e.on("end",function(){t.end()}),e.on("error",function(e){t.error(e)}),this},pause:function(){return!this.isPaused&&!this.isFinished&&(this.isPaused=!0,this.previous&&this.previous.pause(),!0)},resume:function(){if(!this.isPaused||this.isFinished)return!1;var e=this.isPaused=!1;return this.generatedError&&(this.error(this.generatedError),e=!0),this.previous&&this.previous.resume(),!e},flush:function(){},processChunk:function(e){this.push(e)},withStreamInfo:function(e,t){return this.extraStreamInfo[e]=t,this.mergeStreamInfo(),this},mergeStreamInfo:function(){for(var e in this.extraStreamInfo)this.extraStreamInfo.hasOwnProperty(e)&&(this.streamInfo[e]=this.extraStreamInfo[e])},lock:function(){if(this.isLocked)throw new Error("The stream '"+this+"' has already been used.");this.isLocked=!0,this.previous&&this.previous.lock()},toString:function(){var e="Worker "+this.name;return this.previous?this.previous+" -> "+e:e}},t.exports=n},{}],29:[function(e,t,r){"use strict";var h=e("../utils"),i=e("./ConvertWorker"),s=e("./GenericWorker"),f=e("../base64"),n=e("../support"),a=e("../external"),o=null;if(n.nodestream)try{o=e("../nodejs/NodejsStreamOutputAdapter")}catch(e){}function u(e,t,r){var n=t;switch(t){case"blob":case"arraybuffer":n="uint8array";break;case"base64":n="string"}try{this._internalType=n,this._outputType=t,this._mimeType=r,h.checkSupport(n),this._worker=e.pipe(new i(n)),e.lock()}catch(e){this._worker=new s("error"),this._worker.error(e)}}u.prototype={accumulate:function(e){return o=this,u=e,new a.Promise(function(t,r){var n=[],i=o._internalType,s=o._outputType,a=o._mimeType;o.on("data",function(e,t){n.push(e),u&&u(t)}).on("error",function(e){n=[],r(e)}).on("end",function(){try{var e=function(e,t,r){switch(e){case"blob":return h.newBlob(h.transformTo("arraybuffer",t),r);case"base64":return f.encode(t);default:return h.transformTo(e,t)}}(s,function(e,t){var r,n=0,i=null,s=0;for(r=0;r<t.length;r++)s+=t[r].length;switch(e){case"string":return t.join("");case"array":return Array.prototype.concat.apply([],t);case"uint8array":for(i=new Uint8Array(s),r=0;r<t.length;r++)i.set(t[r],n),n+=t[r].length;return i;case"nodebuffer":return Buffer.concat(t);default:throw new Error("concat : unsupported type '"+e+"'")}}(i,n),a);t(e)}catch(e){r(e)}n=[]}).resume()});var o,u},on:function(e,t){var r=this;return"data"===e?this._worker.on(e,function(e){t.call(r,e.data,e.meta)}):this._worker.on(e,function(){h.delay(t,arguments,r)}),this},resume:function(){return h.delay(this._worker.resume,[],this._worker),this},pause:function(){return this._worker.pause(),this},toNodejsStream:function(e){if(h.checkSupport("nodestream"),"nodebuffer"!==this._outputType)throw new Error(this._outputType+" is not supported by this method");return new o(this,{objectMode:"nodebuffer"!==this._outputType},e)}},t.exports=u},{"../base64":1,"../external":6,"../nodejs/NodejsStreamOutputAdapter":13,"../support":30,"../utils":32,"./ConvertWorker":24,"./GenericWorker":28}],30:[function(e,t,r){"use strict";if(r.base64=!0,r.array=!0,r.string=!0,r.arraybuffer="undefined"!=typeof ArrayBuffer&&"undefined"!=typeof Uint8Array,r.nodebuffer="undefined"!=typeof Buffer,r.uint8array="undefined"!=typeof Uint8Array,"undefined"==typeof ArrayBuffer)r.blob=!1;else{var n=new ArrayBuffer(0);try{r.blob=0===new Blob([n],{type:"application/zip"}).size}catch(e){try{var i=new(self.BlobBuilder||self.WebKitBlobBuilder||self.MozBlobBuilder||self.MSBlobBuilder);i.append(n),r.blob=0===i.getBlob("application/zip").size}catch(e){r.blob=!1}}}try{r.nodestream=!!e("readable-stream").Readable}catch(e){r.nodestream=!1}},{"readable-stream":16}],31:[function(e,t,s){"use strict";for(var o=e("./utils"),u=e("./support"),r=e("./nodejsUtils"),n=e("./stream/GenericWorker"),h=new Array(256),i=0;i<256;i++)h[i]=252<=i?6:248<=i?5:240<=i?4:224<=i?3:192<=i?2:1;function a(){n.call(this,"utf-8 decode"),this.leftOver=null}function f(){n.call(this,"utf-8 encode")}h[254]=h[254]=1,s.utf8encode=function(e){return u.nodebuffer?r.newBufferFrom(e,"utf-8"):function(e){var t,r,n,i,s,a=e.length,o=0;for(i=0;i<a;i++)55296==(64512&(r=e.charCodeAt(i)))&&i+1<a&&56320==(64512&(n=e.charCodeAt(i+1)))&&(r=65536+(r-55296<<10)+(n-56320),i++),o+=r<128?1:r<2048?2:r<65536?3:4;for(t=u.uint8array?new Uint8Array(o):new Array(o),i=s=0;s<o;i++)55296==(64512&(r=e.charCodeAt(i)))&&i+1<a&&56320==(64512&(n=e.charCodeAt(i+1)))&&(r=65536+(r-55296<<10)+(n-56320),i++),r<128?t[s++]=r:(r<2048?t[s++]=192|r>>>6:(r<65536?t[s++]=224|r>>>12:(t[s++]=240|r>>>18,t[s++]=128|r>>>12&63),t[s++]=128|r>>>6&63),t[s++]=128|63&r);return t}(e)},s.utf8decode=function(e){return u.nodebuffer?o.transformTo("nodebuffer",e).toString("utf-8"):function(e){var t,r,n,i,s=e.length,a=new Array(2*s);for(t=r=0;t<s;)if((n=e[t++])<128)a[r++]=n;else if(4<(i=h[n]))a[r++]=65533,t+=i-1;else{for(n&=2===i?31:3===i?15:7;1<i&&t<s;)n=n<<6|63&e[t++],i--;1<i?a[r++]=65533:n<65536?a[r++]=n:(n-=65536,a[r++]=55296|n>>10&1023,a[r++]=56320|1023&n)}return a.length!==r&&(a.subarray?a=a.subarray(0,r):a.length=r),o.applyFromCharCode(a)}(e=o.transformTo(u.uint8array?"uint8array":"array",e))},o.inherits(a,n),a.prototype.processChunk=function(e){var t=o.transformTo(u.uint8array?"uint8array":"array",e.data);if(this.leftOver&&this.leftOver.length){if(u.uint8array){var r=t;(t=new Uint8Array(r.length+this.leftOver.length)).set(this.leftOver,0),t.set(r,this.leftOver.length)}else t=this.leftOver.concat(t);this.leftOver=null}var n=function(e,t){var r;for((t=t||e.length)>e.length&&(t=e.length),r=t-1;0<=r&&128==(192&e[r]);)r--;return r<0?t:0===r?t:r+h[e[r]]>t?r:t}(t),i=t;n!==t.length&&(u.uint8array?(i=t.subarray(0,n),this.leftOver=t.subarray(n,t.length)):(i=t.slice(0,n),this.leftOver=t.slice(n,t.length))),this.push({data:s.utf8decode(i),meta:e.meta})},a.prototype.flush=function(){this.leftOver&&this.leftOver.length&&(this.push({data:s.utf8decode(this.leftOver),meta:{}}),this.leftOver=null)},s.Utf8DecodeWorker=a,o.inherits(f,n),f.prototype.processChunk=function(e){this.push({data:s.utf8encode(e.data),meta:e.meta})},s.Utf8EncodeWorker=f},{"./nodejsUtils":14,"./stream/GenericWorker":28,"./support":30,"./utils":32}],32:[function(e,t,o){"use strict";var u=e("./support"),h=e("./base64"),r=e("./nodejsUtils"),n=e("set-immediate-shim"),f=e("./external");function i(e){return e}function l(e,t){for(var r=0;r<e.length;++r)t[r]=255&e.charCodeAt(r);return t}o.newBlob=function(t,r){o.checkSupport("blob");try{return new Blob([t],{type:r})}catch(e){try{var n=new(self.BlobBuilder||self.WebKitBlobBuilder||self.MozBlobBuilder||self.MSBlobBuilder);return n.append(t),n.getBlob(r)}catch(e){throw new Error("Bug : can't construct the Blob.")}}};var s={stringifyByChunk:function(e,t,r){var n=[],i=0,s=e.length;if(s<=r)return String.fromCharCode.apply(null,e);for(;i<s;)"array"===t||"nodebuffer"===t?n.push(String.fromCharCode.apply(null,e.slice(i,Math.min(i+r,s)))):n.push(String.fromCharCode.apply(null,e.subarray(i,Math.min(i+r,s)))),i+=r;return n.join("")},stringifyByChar:function(e){for(var t="",r=0;r<e.length;r++)t+=String.fromCharCode(e[r]);return t},applyCanBeUsed:{uint8array:function(){try{return u.uint8array&&1===String.fromCharCode.apply(null,new Uint8Array(1)).length}catch(e){return!1}}(),nodebuffer:function(){try{return u.nodebuffer&&1===String.fromCharCode.apply(null,r.allocBuffer(1)).length}catch(e){return!1}}()}};function a(e){var t=65536,r=o.getTypeOf(e),n=!0;if("uint8array"===r?n=s.applyCanBeUsed.uint8array:"nodebuffer"===r&&(n=s.applyCanBeUsed.nodebuffer),n)for(;1<t;)try{return s.stringifyByChunk(e,r,t)}catch(e){t=Math.floor(t/2)}return s.stringifyByChar(e)}function d(e,t){for(var r=0;r<e.length;r++)t[r]=e[r];return t}o.applyFromCharCode=a;var c={};c.string={string:i,array:function(e){return l(e,new Array(e.length))},arraybuffer:function(e){return c.string.uint8array(e).buffer},uint8array:function(e){return l(e,new Uint8Array(e.length))},nodebuffer:function(e){return l(e,r.allocBuffer(e.length))}},c.array={string:a,array:i,arraybuffer:function(e){return new Uint8Array(e).buffer},uint8array:function(e){return new Uint8Array(e)},nodebuffer:function(e){return r.newBufferFrom(e)}},c.arraybuffer={string:function(e){return a(new Uint8Array(e))},array:function(e){return d(new Uint8Array(e),new Array(e.byteLength))},arraybuffer:i,uint8array:function(e){return new Uint8Array(e)},nodebuffer:function(e){return r.newBufferFrom(new Uint8Array(e))}},c.uint8array={string:a,array:function(e){return d(e,new Array(e.length))},arraybuffer:function(e){return e.buffer},uint8array:i,nodebuffer:function(e){return r.newBufferFrom(e)}},c.nodebuffer={string:a,array:function(e){return d(e,new Array(e.length))},arraybuffer:function(e){return c.nodebuffer.uint8array(e).buffer},uint8array:function(e){return d(e,new Uint8Array(e.length))},nodebuffer:i},o.transformTo=function(e,t){if(t=t||"",!e)return t;o.checkSupport(e);var r=o.getTypeOf(t);return c[r][e](t)},o.getTypeOf=function(e){return"string"==typeof e?"string":"[object Array]"===Object.prototype.toString.call(e)?"array":u.nodebuffer&&r.isBuffer(e)?"nodebuffer":u.uint8array&&e instanceof Uint8Array?"uint8array":u.arraybuffer&&e instanceof ArrayBuffer?"arraybuffer":void 0},o.checkSupport=function(e){if(!u[e.toLowerCase()])throw new Error(e+" is not supported by this platform")},o.MAX_VALUE_16BITS=65535,o.MAX_VALUE_32BITS=-1,o.pretty=function(e){var t,r,n="";for(r=0;r<(e||"").length;r++)n+="\\x"+((t=e.charCodeAt(r))<16?"0":"")+t.toString(16).toUpperCase();return n},o.delay=function(e,t,r){n(function(){e.apply(r||null,t||[])})},o.inherits=function(e,t){function r(){}r.prototype=t.prototype,e.prototype=new r},o.extend=function(){var e,t,r={};for(e=0;e<arguments.length;e++)for(t in arguments[e])arguments[e].hasOwnProperty(t)&&void 0===r[t]&&(r[t]=arguments[e][t]);return r},o.prepareContent=function(n,e,i,s,a){return f.Promise.resolve(e).then(function(n){return u.blob&&(n instanceof Blob||-1!==["[object File]","[object Blob]"].indexOf(Object.prototype.toString.call(n)))&&"undefined"!=typeof FileReader?new f.Promise(function(t,r){var e=new FileReader;e.onload=function(e){t(e.target.result)},e.onerror=function(e){r(e.target.error)},e.readAsArrayBuffer(n)}):n}).then(function(e){var t,r=o.getTypeOf(e);return r?("arraybuffer"===r?e=o.transformTo("uint8array",e):"string"===r&&(a?e=h.decode(e):i&&!0!==s&&(e=l(t=e,u.uint8array?new Uint8Array(t.length):new Array(t.length)))),e):f.Promise.reject(new Error("Can't read the data of '"+n+"'. Is it in a supported JavaScript type (String, Blob, ArrayBuffer, etc) ?"))})}},{"./base64":1,"./external":6,"./nodejsUtils":14,"./support":30,"set-immediate-shim":54}],33:[function(e,t,r){"use strict";var n=e("./reader/readerFor"),i=e("./utils"),s=e("./signature"),a=e("./zipEntry"),o=(e("./utf8"),e("./support"));function u(e){this.files=[],this.loadOptions=e}u.prototype={checkSignature:function(e){if(!this.reader.readAndCheckSignature(e)){this.reader.index-=4;var t=this.reader.readString(4);throw new Error("Corrupted zip or bug: unexpected signature ("+i.pretty(t)+", expected "+i.pretty(e)+")")}},isSignature:function(e,t){var r=this.reader.index;this.reader.setIndex(e);var n=this.reader.readString(4)===t;return this.reader.setIndex(r),n},readBlockEndOfCentral:function(){this.diskNumber=this.reader.readInt(2),this.diskWithCentralDirStart=this.reader.readInt(2),this.centralDirRecordsOnThisDisk=this.reader.readInt(2),this.centralDirRecords=this.reader.readInt(2),this.centralDirSize=this.reader.readInt(4),this.centralDirOffset=this.reader.readInt(4),this.zipCommentLength=this.reader.readInt(2);var e=this.reader.readData(this.zipCommentLength),t=o.uint8array?"uint8array":"array",r=i.transformTo(t,e);this.zipComment=this.loadOptions.decodeFileName(r)},readBlockZip64EndOfCentral:function(){this.zip64EndOfCentralSize=this.reader.readInt(8),this.reader.skip(4),this.diskNumber=this.reader.readInt(4),this.diskWithCentralDirStart=this.reader.readInt(4),this.centralDirRecordsOnThisDisk=this.reader.readInt(8),this.centralDirRecords=this.reader.readInt(8),this.centralDirSize=this.reader.readInt(8),this.centralDirOffset=this.reader.readInt(8),this.zip64ExtensibleData={};for(var e,t,r,n=this.zip64EndOfCentralSize-44;0<n;)e=this.reader.readInt(2),t=this.reader.readInt(4),r=this.reader.readData(t),this.zip64ExtensibleData[e]={id:e,length:t,value:r}},readBlockZip64EndOfCentralLocator:function(){if(this.diskWithZip64CentralDirStart=this.reader.readInt(4),this.relativeOffsetEndOfZip64CentralDir=this.reader.readInt(8),this.disksCount=this.reader.readInt(4),1<this.disksCount)throw new Error("Multi-volumes zip are not supported")},readLocalFiles:function(){var e,t;for(e=0;e<this.files.length;e++)t=this.files[e],this.reader.setIndex(t.localHeaderOffset),this.checkSignature(s.LOCAL_FILE_HEADER),t.readLocalPart(this.reader),t.handleUTF8(),t.processAttributes()},readCentralDir:function(){var e;for(this.reader.setIndex(this.centralDirOffset);this.reader.readAndCheckSignature(s.CENTRAL_FILE_HEADER);)(e=new a({zip64:this.zip64},this.loadOptions)).readCentralPart(this.reader),this.files.push(e);if(this.centralDirRecords!==this.files.length&&0!==this.centralDirRecords&&0===this.files.length)throw new Error("Corrupted zip or bug: expected "+this.centralDirRecords+" records in central dir, got "+this.files.length)},readEndOfCentral:function(){var e=this.reader.lastIndexOfSignature(s.CENTRAL_DIRECTORY_END);if(e<0)throw this.isSignature(0,s.LOCAL_FILE_HEADER)?new Error("Corrupted zip: can't find end of central directory"):new Error("Can't find end of central directory : is this a zip file ? If it is, see https://stuk.github.io/jszip/documentation/howto/read_zip.html");this.reader.setIndex(e);var t=e;if(this.checkSignature(s.CENTRAL_DIRECTORY_END),this.readBlockEndOfCentral(),this.diskNumber===i.MAX_VALUE_16BITS||this.diskWithCentralDirStart===i.MAX_VALUE_16BITS||this.centralDirRecordsOnThisDisk===i.MAX_VALUE_16BITS||this.centralDirRecords===i.MAX_VALUE_16BITS||this.centralDirSize===i.MAX_VALUE_32BITS||this.centralDirOffset===i.MAX_VALUE_32BITS){if(this.zip64=!0,(e=this.reader.lastIndexOfSignature(s.ZIP64_CENTRAL_DIRECTORY_LOCATOR))<0)throw new Error("Corrupted zip: can't find the ZIP64 end of central directory locator");if(this.reader.setIndex(e),this.checkSignature(s.ZIP64_CENTRAL_DIRECTORY_LOCATOR),this.readBlockZip64EndOfCentralLocator(),!this.isSignature(this.relativeOffsetEndOfZip64CentralDir,s.ZIP64_CENTRAL_DIRECTORY_END)&&(this.relativeOffsetEndOfZip64CentralDir=this.reader.lastIndexOfSignature(s.ZIP64_CENTRAL_DIRECTORY_END),this.relativeOffsetEndOfZip64CentralDir<0))throw new Error("Corrupted zip: can't find the ZIP64 end of central directory");this.reader.setIndex(this.relativeOffsetEndOfZip64CentralDir),this.checkSignature(s.ZIP64_CENTRAL_DIRECTORY_END),this.readBlockZip64EndOfCentral()}var r=this.centralDirOffset+this.centralDirSize;this.zip64&&(r+=20,r+=12+this.zip64EndOfCentralSize);var n=t-r;if(0<n)this.isSignature(t,s.CENTRAL_FILE_HEADER)||(this.reader.zero=n);else if(n<0)throw new Error("Corrupted zip: missing "+Math.abs(n)+" bytes.")},prepareReader:function(e){this.reader=n(e)},load:function(e){this.prepareReader(e),this.readEndOfCentral(),this.readCentralDir(),this.readLocalFiles()}},t.exports=u},{"./reader/readerFor":22,"./signature":23,"./support":30,"./utf8":31,"./utils":32,"./zipEntry":34}],34:[function(e,t,r){"use strict";var n=e("./reader/readerFor"),s=e("./utils"),i=e("./compressedObject"),a=e("./crc32"),o=e("./utf8"),u=e("./compressions"),h=e("./support");function f(e,t){this.options=e,this.loadOptions=t}f.prototype={isEncrypted:function(){return 1==(1&this.bitFlag)},useUTF8:function(){return 2048==(2048&this.bitFlag)},readLocalPart:function(e){var t,r;if(e.skip(22),this.fileNameLength=e.readInt(2),r=e.readInt(2),this.fileName=e.readData(this.fileNameLength),e.skip(r),-1===this.compressedSize||-1===this.uncompressedSize)throw new Error("Bug or corrupted zip : didn't get enough information from the central directory (compressedSize === -1 || uncompressedSize === -1)");if(null===(t=function(e){for(var t in u)if(u.hasOwnProperty(t)&&u[t].magic===e)return u[t];return null}(this.compressionMethod)))throw new Error("Corrupted zip : compression "+s.pretty(this.compressionMethod)+" unknown (inner file : "+s.transformTo("string",this.fileName)+")");this.decompressed=new i(this.compressedSize,this.uncompressedSize,this.crc32,t,e.readData(this.compressedSize))},readCentralPart:function(e){this.versionMadeBy=e.readInt(2),e.skip(2),this.bitFlag=e.readInt(2),this.compressionMethod=e.readString(2),this.date=e.readDate(),this.crc32=e.readInt(4),this.compressedSize=e.readInt(4),this.uncompressedSize=e.readInt(4);var t=e.readInt(2);if(this.extraFieldsLength=e.readInt(2),this.fileCommentLength=e.readInt(2),this.diskNumberStart=e.readInt(2),this.internalFileAttributes=e.readInt(2),this.externalFileAttributes=e.readInt(4),this.localHeaderOffset=e.readInt(4),this.isEncrypted())throw new Error("Encrypted zip are not supported");e.skip(t),this.readExtraFields(e),this.parseZIP64ExtraField(e),this.fileComment=e.readData(this.fileCommentLength)},processAttributes:function(){this.unixPermissions=null,this.dosPermissions=null;var e=this.versionMadeBy>>8;this.dir=!!(16&this.externalFileAttributes),0==e&&(this.dosPermissions=63&this.externalFileAttributes),3==e&&(this.unixPermissions=this.externalFileAttributes>>16&65535),this.dir||"/"!==this.fileNameStr.slice(-1)||(this.dir=!0)},parseZIP64ExtraField:function(e){if(this.extraFields[1]){var t=n(this.extraFields[1].value);this.uncompressedSize===s.MAX_VALUE_32BITS&&(this.uncompressedSize=t.readInt(8)),this.compressedSize===s.MAX_VALUE_32BITS&&(this.compressedSize=t.readInt(8)),this.localHeaderOffset===s.MAX_VALUE_32BITS&&(this.localHeaderOffset=t.readInt(8)),this.diskNumberStart===s.MAX_VALUE_32BITS&&(this.diskNumberStart=t.readInt(4))}},readExtraFields:function(e){var t,r,n,i=e.index+this.extraFieldsLength;for(this.extraFields||(this.extraFields={});e.index+4<i;)t=e.readInt(2),r=e.readInt(2),n=e.readData(r),this.extraFields[t]={id:t,length:r,value:n};e.setIndex(i)},handleUTF8:function(){var e=h.uint8array?"uint8array":"array";if(this.useUTF8())this.fileNameStr=o.utf8decode(this.fileName),this.fileCommentStr=o.utf8decode(this.fileComment);else{var t=this.findExtraFieldUnicodePath();if(null!==t)this.fileNameStr=t;else{var r=s.transformTo(e,this.fileName);this.fileNameStr=this.loadOptions.decodeFileName(r)}var n=this.findExtraFieldUnicodeComment();if(null!==n)this.fileCommentStr=n;else{var i=s.transformTo(e,this.fileComment);this.fileCommentStr=this.loadOptions.decodeFileName(i)}}},findExtraFieldUnicodePath:function(){var e=this.extraFields[28789];if(e){var t=n(e.value);return 1!==t.readInt(1)?null:a(this.fileName)!==t.readInt(4)?null:o.utf8decode(t.readData(e.length-5))}return null},findExtraFieldUnicodeComment:function(){var e=this.extraFields[25461];if(e){var t=n(e.value);return 1!==t.readInt(1)?null:a(this.fileComment)!==t.readInt(4)?null:o.utf8decode(t.readData(e.length-5))}return null}},t.exports=f},{"./compressedObject":2,"./compressions":3,"./crc32":4,"./reader/readerFor":22,"./support":30,"./utf8":31,"./utils":32}],35:[function(e,t,r){"use strict";function n(e,t,r){this.name=e,this.dir=r.dir,this.date=r.date,this.comment=r.comment,this.unixPermissions=r.unixPermissions,this.dosPermissions=r.dosPermissions,this._data=t,this._dataBinary=r.binary,this.options={compression:r.compression,compressionOptions:r.compressionOptions}}var s=e("./stream/StreamHelper"),i=e("./stream/DataWorker"),a=e("./utf8"),o=e("./compressedObject"),u=e("./stream/GenericWorker");n.prototype={internalStream:function(e){var t=null,r="string";try{if(!e)throw new Error("No output type specified.");var n="string"===(r=e.toLowerCase())||"text"===r;"binarystring"!==r&&"text"!==r||(r="string"),t=this._decompressWorker();var i=!this._dataBinary;i&&!n&&(t=t.pipe(new a.Utf8EncodeWorker)),!i&&n&&(t=t.pipe(new a.Utf8DecodeWorker))}catch(e){(t=new u("error")).error(e)}return new s(t,r,"")},async:function(e,t){return this.internalStream(e).accumulate(t)},nodeStream:function(e,t){return this.internalStream(e||"nodebuffer").toNodejsStream(t)},_compressWorker:function(e,t){if(this._data instanceof o&&this._data.compression.magic===e.magic)return this._data.getCompressedWorker();var r=this._decompressWorker();return this._dataBinary||(r=r.pipe(new a.Utf8EncodeWorker)),o.createWorkerFrom(r,e,t)},_decompressWorker:function(){return this._data instanceof o?this._data.getContentWorker():this._data instanceof u?this._data:new i(this._data)}};for(var h=["asText","asBinary","asNodeBuffer","asUint8Array","asArrayBuffer"],f=function(){throw new Error("This method has been removed in JSZip 3.0, please check the upgrade guide.")},l=0;l<h.length;l++)n.prototype[h[l]]=f;t.exports=n},{"./compressedObject":2,"./stream/DataWorker":27,"./stream/GenericWorker":28,"./stream/StreamHelper":29,"./utf8":31}],36:[function(e,f,t){(function(t){"use strict";var r,n,e=t.MutationObserver||t.WebKitMutationObserver;if(e){var i=0,s=new e(h),a=t.document.createTextNode("");s.observe(a,{characterData:!0}),r=function(){a.data=i=++i%2}}else if(t.setImmediate||void 0===t.MessageChannel)r="document"in t&&"onreadystatechange"in t.document.createElement("script")?function(){var e=t.document.createElement("script");e.onreadystatechange=function(){h(),e.onreadystatechange=null,e.parentNode.removeChild(e),e=null},t.document.documentElement.appendChild(e)}:function(){setTimeout(h,0)};else{var o=new t.MessageChannel;o.port1.onmessage=h,r=function(){o.port2.postMessage(0)}}var u=[];function h(){var e,t;n=!0;for(var r=u.length;r;){for(t=u,u=[],e=-1;++e<r;)t[e]();r=u.length}n=!1}f.exports=function(e){1!==u.push(e)||n||r()}}).call(this,void 0!==r?r:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}],37:[function(e,t,r){"use strict";var i=e("immediate");function h(){}var f={},s=["REJECTED"],a=["FULFILLED"],n=["PENDING"];function o(e){if("function"!=typeof e)throw new TypeError("resolver must be a function");this.state=n,this.queue=[],this.outcome=void 0,e!==h&&c(this,e)}function u(e,t,r){this.promise=e,"function"==typeof t&&(this.onFulfilled=t,this.callFulfilled=this.otherCallFulfilled),"function"==typeof r&&(this.onRejected=r,this.callRejected=this.otherCallRejected)}function l(t,r,n){i(function(){var e;try{e=r(n)}catch(e){return f.reject(t,e)}e===t?f.reject(t,new TypeError("Cannot resolve promise with itself")):f.resolve(t,e)})}function d(e){var t=e&&e.then;if(e&&("object"==typeof e||"function"==typeof e)&&"function"==typeof t)return function(){t.apply(e,arguments)}}function c(t,e){var r=!1;function n(e){r||(r=!0,f.reject(t,e))}function i(e){r||(r=!0,f.resolve(t,e))}var s=p(function(){e(i,n)});"error"===s.status&&n(s.value)}function p(e,t){var r={};try{r.value=e(t),r.status="success"}catch(e){r.status="error",r.value=e}return r}(t.exports=o).prototype.finally=function(t){if("function"!=typeof t)return this;var r=this.constructor;return this.then(function(e){return r.resolve(t()).then(function(){return e})},function(e){return r.resolve(t()).then(function(){throw e})})},o.prototype.catch=function(e){return this.then(null,e)},o.prototype.then=function(e,t){if("function"!=typeof e&&this.state===a||"function"!=typeof t&&this.state===s)return this;var r=new this.constructor(h);return this.state!==n?l(r,this.state===a?e:t,this.outcome):this.queue.push(new u(r,e,t)),r},u.prototype.callFulfilled=function(e){f.resolve(this.promise,e)},u.prototype.otherCallFulfilled=function(e){l(this.promise,this.onFulfilled,e)},u.prototype.callRejected=function(e){f.reject(this.promise,e)},u.prototype.otherCallRejected=function(e){l(this.promise,this.onRejected,e)},f.resolve=function(e,t){var r=p(d,t);if("error"===r.status)return f.reject(e,r.value);var n=r.value;if(n)c(e,n);else{e.state=a,e.outcome=t;for(var i=-1,s=e.queue.length;++i<s;)e.queue[i].callFulfilled(t)}return e},f.reject=function(e,t){e.state=s,e.outcome=t;for(var r=-1,n=e.queue.length;++r<n;)e.queue[r].callRejected(t);return e},o.resolve=function(e){return e instanceof this?e:f.resolve(new this(h),e)},o.reject=function(e){var t=new this(h);return f.reject(t,e)},o.all=function(e){var r=this;if("[object Array]"!==Object.prototype.toString.call(e))return this.reject(new TypeError("must be an array"));var n=e.length,i=!1;if(!n)return this.resolve([]);for(var s=new Array(n),a=0,t=-1,o=new this(h);++t<n;)u(e[t],t);return o;function u(e,t){r.resolve(e).then(function(e){s[t]=e,++a!==n||i||(i=!0,f.resolve(o,s))},function(e){i||(i=!0,f.reject(o,e))})}},o.race=function(e){if("[object Array]"!==Object.prototype.toString.call(e))return this.reject(new TypeError("must be an array"));var t=e.length,r=!1;if(!t)return this.resolve([]);for(var n,i=-1,s=new this(h);++i<t;)n=e[i],this.resolve(n).then(function(e){r||(r=!0,f.resolve(s,e))},function(e){r||(r=!0,f.reject(s,e))});return s}},{immediate:36}],38:[function(e,t,r){"use strict";var n={};(0,e("./lib/utils/common").assign)(n,e("./lib/deflate"),e("./lib/inflate"),e("./lib/zlib/constants")),t.exports=n},{"./lib/deflate":39,"./lib/inflate":40,"./lib/utils/common":41,"./lib/zlib/constants":44}],39:[function(e,t,r){"use strict";var a=e("./zlib/deflate"),o=e("./utils/common"),u=e("./utils/strings"),i=e("./zlib/messages"),s=e("./zlib/zstream"),h=Object.prototype.toString,f=0,l=-1,d=0,c=8;function p(e){if(!(this instanceof p))return new p(e);this.options=o.assign({level:l,method:c,chunkSize:16384,windowBits:15,memLevel:8,strategy:d,to:""},e||{});var t=this.options;t.raw&&0<t.windowBits?t.windowBits=-t.windowBits:t.gzip&&0<t.windowBits&&t.windowBits<16&&(t.windowBits+=16),this.err=0,this.msg="",this.ended=!1,this.chunks=[],this.strm=new s,this.strm.avail_out=0;var r=a.deflateInit2(this.strm,t.level,t.method,t.windowBits,t.memLevel,t.strategy);if(r!==f)throw new Error(i[r]);if(t.header&&a.deflateSetHeader(this.strm,t.header),t.dictionary){var n;if(n="string"==typeof t.dictionary?u.string2buf(t.dictionary):"[object ArrayBuffer]"===h.call(t.dictionary)?new Uint8Array(t.dictionary):t.dictionary,(r=a.deflateSetDictionary(this.strm,n))!==f)throw new Error(i[r]);this._dict_set=!0}}function n(e,t){var r=new p(t);if(r.push(e,!0),r.err)throw r.msg||i[r.err];return r.result}p.prototype.push=function(e,t){var r,n,i=this.strm,s=this.options.chunkSize;if(this.ended)return!1;n=t===~~t?t:!0===t?4:0,"string"==typeof e?i.input=u.string2buf(e):"[object ArrayBuffer]"===h.call(e)?i.input=new Uint8Array(e):i.input=e,i.next_in=0,i.avail_in=i.input.length;do{if(0===i.avail_out&&(i.output=new o.Buf8(s),i.next_out=0,i.avail_out=s),1!==(r=a.deflate(i,n))&&r!==f)return this.onEnd(r),!(this.ended=!0);0!==i.avail_out&&(0!==i.avail_in||4!==n&&2!==n)||("string"===this.options.to?this.onData(u.buf2binstring(o.shrinkBuf(i.output,i.next_out))):this.onData(o.shrinkBuf(i.output,i.next_out)))}while((0<i.avail_in||0===i.avail_out)&&1!==r);return 4===n?(r=a.deflateEnd(this.strm),this.onEnd(r),this.ended=!0,r===f):2!==n||(this.onEnd(f),!(i.avail_out=0))},p.prototype.onData=function(e){this.chunks.push(e)},p.prototype.onEnd=function(e){e===f&&("string"===this.options.to?this.result=this.chunks.join(""):this.result=o.flattenChunks(this.chunks)),this.chunks=[],this.err=e,this.msg=this.strm.msg},r.Deflate=p,r.deflate=n,r.deflateRaw=function(e,t){return(t=t||{}).raw=!0,n(e,t)},r.gzip=function(e,t){return(t=t||{}).gzip=!0,n(e,t)}},{"./utils/common":41,"./utils/strings":42,"./zlib/deflate":46,"./zlib/messages":51,"./zlib/zstream":53}],40:[function(e,t,r){"use strict";var d=e("./zlib/inflate"),c=e("./utils/common"),p=e("./utils/strings"),m=e("./zlib/constants"),n=e("./zlib/messages"),i=e("./zlib/zstream"),s=e("./zlib/gzheader"),_=Object.prototype.toString;function a(e){if(!(this instanceof a))return new a(e);this.options=c.assign({chunkSize:16384,windowBits:0,to:""},e||{});var t=this.options;t.raw&&0<=t.windowBits&&t.windowBits<16&&(t.windowBits=-t.windowBits,0===t.windowBits&&(t.windowBits=-15)),!(0<=t.windowBits&&t.windowBits<16)||e&&e.windowBits||(t.windowBits+=32),15<t.windowBits&&t.windowBits<48&&0==(15&t.windowBits)&&(t.windowBits|=15),this.err=0,this.msg="",this.ended=!1,this.chunks=[],this.strm=new i,this.strm.avail_out=0;var r=d.inflateInit2(this.strm,t.windowBits);if(r!==m.Z_OK)throw new Error(n[r]);this.header=new s,d.inflateGetHeader(this.strm,this.header)}function o(e,t){var r=new a(t);if(r.push(e,!0),r.err)throw r.msg||n[r.err];return r.result}a.prototype.push=function(e,t){var r,n,i,s,a,o,u=this.strm,h=this.options.chunkSize,f=this.options.dictionary,l=!1;if(this.ended)return!1;n=t===~~t?t:!0===t?m.Z_FINISH:m.Z_NO_FLUSH,"string"==typeof e?u.input=p.binstring2buf(e):"[object ArrayBuffer]"===_.call(e)?u.input=new Uint8Array(e):u.input=e,u.next_in=0,u.avail_in=u.input.length;do{if(0===u.avail_out&&(u.output=new c.Buf8(h),u.next_out=0,u.avail_out=h),(r=d.inflate(u,m.Z_NO_FLUSH))===m.Z_NEED_DICT&&f&&(o="string"==typeof f?p.string2buf(f):"[object ArrayBuffer]"===_.call(f)?new Uint8Array(f):f,r=d.inflateSetDictionary(this.strm,o)),r===m.Z_BUF_ERROR&&!0===l&&(r=m.Z_OK,l=!1),r!==m.Z_STREAM_END&&r!==m.Z_OK)return this.onEnd(r),!(this.ended=!0);u.next_out&&(0!==u.avail_out&&r!==m.Z_STREAM_END&&(0!==u.avail_in||n!==m.Z_FINISH&&n!==m.Z_SYNC_FLUSH)||("string"===this.options.to?(i=p.utf8border(u.output,u.next_out),s=u.next_out-i,a=p.buf2string(u.output,i),u.next_out=s,u.avail_out=h-s,s&&c.arraySet(u.output,u.output,i,s,0),this.onData(a)):this.onData(c.shrinkBuf(u.output,u.next_out)))),0===u.avail_in&&0===u.avail_out&&(l=!0)}while((0<u.avail_in||0===u.avail_out)&&r!==m.Z_STREAM_END);return r===m.Z_STREAM_END&&(n=m.Z_FINISH),n===m.Z_FINISH?(r=d.inflateEnd(this.strm),this.onEnd(r),this.ended=!0,r===m.Z_OK):n!==m.Z_SYNC_FLUSH||(this.onEnd(m.Z_OK),!(u.avail_out=0))},a.prototype.onData=function(e){this.chunks.push(e)},a.prototype.onEnd=function(e){e===m.Z_OK&&("string"===this.options.to?this.result=this.chunks.join(""):this.result=c.flattenChunks(this.chunks)),this.chunks=[],this.err=e,this.msg=this.strm.msg},r.Inflate=a,r.inflate=o,r.inflateRaw=function(e,t){return(t=t||{}).raw=!0,o(e,t)},r.ungzip=o},{"./utils/common":41,"./utils/strings":42,"./zlib/constants":44,"./zlib/gzheader":47,"./zlib/inflate":49,"./zlib/messages":51,"./zlib/zstream":53}],41:[function(e,t,r){"use strict";var n="undefined"!=typeof Uint8Array&&"undefined"!=typeof Uint16Array&&"undefined"!=typeof Int32Array;r.assign=function(e){for(var t=Array.prototype.slice.call(arguments,1);t.length;){var r=t.shift();if(r){if("object"!=typeof r)throw new TypeError(r+"must be non-object");for(var n in r)r.hasOwnProperty(n)&&(e[n]=r[n])}}return e},r.shrinkBuf=function(e,t){return e.length===t?e:e.subarray?e.subarray(0,t):(e.length=t,e)};var i={arraySet:function(e,t,r,n,i){if(t.subarray&&e.subarray)e.set(t.subarray(r,r+n),i);else for(var s=0;s<n;s++)e[i+s]=t[r+s]},flattenChunks:function(e){var t,r,n,i,s,a;for(t=n=0,r=e.length;t<r;t++)n+=e[t].length;for(a=new Uint8Array(n),t=i=0,r=e.length;t<r;t++)s=e[t],a.set(s,i),i+=s.length;return a}},s={arraySet:function(e,t,r,n,i){for(var s=0;s<n;s++)e[i+s]=t[r+s]},flattenChunks:function(e){return[].concat.apply([],e)}};r.setTyped=function(e){e?(r.Buf8=Uint8Array,r.Buf16=Uint16Array,r.Buf32=Int32Array,r.assign(r,i)):(r.Buf8=Array,r.Buf16=Array,r.Buf32=Array,r.assign(r,s))},r.setTyped(n)},{}],42:[function(e,t,r){"use strict";var u=e("./common"),i=!0,s=!0;try{String.fromCharCode.apply(null,[0])}catch(e){i=!1}try{String.fromCharCode.apply(null,new Uint8Array(1))}catch(e){s=!1}for(var h=new u.Buf8(256),n=0;n<256;n++)h[n]=252<=n?6:248<=n?5:240<=n?4:224<=n?3:192<=n?2:1;function f(e,t){if(t<65537&&(e.subarray&&s||!e.subarray&&i))return String.fromCharCode.apply(null,u.shrinkBuf(e,t));for(var r="",n=0;n<t;n++)r+=String.fromCharCode(e[n]);return r}h[254]=h[254]=1,r.string2buf=function(e){var t,r,n,i,s,a=e.length,o=0;for(i=0;i<a;i++)55296==(64512&(r=e.charCodeAt(i)))&&i+1<a&&56320==(64512&(n=e.charCodeAt(i+1)))&&(r=65536+(r-55296<<10)+(n-56320),i++),o+=r<128?1:r<2048?2:r<65536?3:4;for(t=new u.Buf8(o),i=s=0;s<o;i++)55296==(64512&(r=e.charCodeAt(i)))&&i+1<a&&56320==(64512&(n=e.charCodeAt(i+1)))&&(r=65536+(r-55296<<10)+(n-56320),i++),r<128?t[s++]=r:(r<2048?t[s++]=192|r>>>6:(r<65536?t[s++]=224|r>>>12:(t[s++]=240|r>>>18,t[s++]=128|r>>>12&63),t[s++]=128|r>>>6&63),t[s++]=128|63&r);return t},r.buf2binstring=function(e){return f(e,e.length)},r.binstring2buf=function(e){for(var t=new u.Buf8(e.length),r=0,n=t.length;r<n;r++)t[r]=e.charCodeAt(r);return t},r.buf2string=function(e,t){var r,n,i,s,a=t||e.length,o=new Array(2*a);for(r=n=0;r<a;)if((i=e[r++])<128)o[n++]=i;else if(4<(s=h[i]))o[n++]=65533,r+=s-1;else{for(i&=2===s?31:3===s?15:7;1<s&&r<a;)i=i<<6|63&e[r++],s--;1<s?o[n++]=65533:i<65536?o[n++]=i:(i-=65536,o[n++]=55296|i>>10&1023,o[n++]=56320|1023&i)}return f(o,n)},r.utf8border=function(e,t){var r;for((t=t||e.length)>e.length&&(t=e.length),r=t-1;0<=r&&128==(192&e[r]);)r--;return r<0?t:0===r?t:r+h[e[r]]>t?r:t}},{"./common":41}],43:[function(e,t,r){"use strict";t.exports=function(e,t,r,n){for(var i=65535&e|0,s=e>>>16&65535|0,a=0;0!==r;){for(r-=a=2e3<r?2e3:r;s=s+(i=i+t[n++]|0)|0,--a;);i%=65521,s%=65521}return i|s<<16|0}},{}],44:[function(e,t,r){"use strict";t.exports={Z_NO_FLUSH:0,Z_PARTIAL_FLUSH:1,Z_SYNC_FLUSH:2,Z_FULL_FLUSH:3,Z_FINISH:4,Z_BLOCK:5,Z_TREES:6,Z_OK:0,Z_STREAM_END:1,Z_NEED_DICT:2,Z_ERRNO:-1,Z_STREAM_ERROR:-2,Z_DATA_ERROR:-3,Z_BUF_ERROR:-5,Z_NO_COMPRESSION:0,Z_BEST_SPEED:1,Z_BEST_COMPRESSION:9,Z_DEFAULT_COMPRESSION:-1,Z_FILTERED:1,Z_HUFFMAN_ONLY:2,Z_RLE:3,Z_FIXED:4,Z_DEFAULT_STRATEGY:0,Z_BINARY:0,Z_TEXT:1,Z_UNKNOWN:2,Z_DEFLATED:8}},{}],45:[function(e,t,r){"use strict";var o=function(){for(var e,t=[],r=0;r<256;r++){e=r;for(var n=0;n<8;n++)e=1&e?3988292384^e>>>1:e>>>1;t[r]=e}return t}();t.exports=function(e,t,r,n){var i=o,s=n+r;e^=-1;for(var a=n;a<s;a++)e=e>>>8^i[255&(e^t[a])];return-1^e}},{}],46:[function(e,t,r){"use strict";var u,d=e("../utils/common"),h=e("./trees"),c=e("./adler32"),p=e("./crc32"),n=e("./messages"),f=0,l=0,m=-2,i=2,_=8,s=286,a=30,o=19,g=2*s+1,v=15,b=3,w=258,y=w+b+1,k=42,x=113;function S(e,t){return e.msg=n[t],t}function z(e){return(e<<1)-(4<e?9:0)}function E(e){for(var t=e.length;0<=--t;)e[t]=0}function C(e){var t=e.state,r=t.pending;r>e.avail_out&&(r=e.avail_out),0!==r&&(d.arraySet(e.output,t.pending_buf,t.pending_out,r,e.next_out),e.next_out+=r,t.pending_out+=r,e.total_out+=r,e.avail_out-=r,t.pending-=r,0===t.pending&&(t.pending_out=0))}function A(e,t){h._tr_flush_block(e,0<=e.block_start?e.block_start:-1,e.strstart-e.block_start,t),e.block_start=e.strstart,C(e.strm)}function I(e,t){e.pending_buf[e.pending++]=t}function O(e,t){e.pending_buf[e.pending++]=t>>>8&255,e.pending_buf[e.pending++]=255&t}function B(e,t){var r,n,i=e.max_chain_length,s=e.strstart,a=e.prev_length,o=e.nice_match,u=e.strstart>e.w_size-y?e.strstart-(e.w_size-y):0,h=e.window,f=e.w_mask,l=e.prev,d=e.strstart+w,c=h[s+a-1],p=h[s+a];e.prev_length>=e.good_match&&(i>>=2),o>e.lookahead&&(o=e.lookahead);do{if(h[(r=t)+a]===p&&h[r+a-1]===c&&h[r]===h[s]&&h[++r]===h[s+1]){s+=2,r++;do{}while(h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&h[++s]===h[++r]&&s<d);if(n=w-(d-s),s=d-w,a<n){if(e.match_start=t,o<=(a=n))break;c=h[s+a-1],p=h[s+a]}}}while((t=l[t&f])>u&&0!=--i);return a<=e.lookahead?a:e.lookahead}function T(e){var t,r,n,i,s,a,o,u,h,f,l=e.w_size;do{if(i=e.window_size-e.lookahead-e.strstart,e.strstart>=l+(l-y)){for(d.arraySet(e.window,e.window,l,l,0),e.match_start-=l,e.strstart-=l,e.block_start-=l,t=r=e.hash_size;n=e.head[--t],e.head[t]=l<=n?n-l:0,--r;);for(t=r=l;n=e.prev[--t],e.prev[t]=l<=n?n-l:0,--r;);i+=l}if(0===e.strm.avail_in)break;if(a=e.strm,o=e.window,u=e.strstart+e.lookahead,f=void 0,(h=i)<(f=a.avail_in)&&(f=h),r=0===f?0:(a.avail_in-=f,d.arraySet(o,a.input,a.next_in,f,u),1===a.state.wrap?a.adler=c(a.adler,o,f,u):2===a.state.wrap&&(a.adler=p(a.adler,o,f,u)),a.next_in+=f,a.total_in+=f,f),e.lookahead+=r,e.lookahead+e.insert>=b)for(s=e.strstart-e.insert,e.ins_h=e.window[s],e.ins_h=(e.ins_h<<e.hash_shift^e.window[s+1])&e.hash_mask;e.insert&&(e.ins_h=(e.ins_h<<e.hash_shift^e.window[s+b-1])&e.hash_mask,e.prev[s&e.w_mask]=e.head[e.ins_h],e.head[e.ins_h]=s,s++,e.insert--,!(e.lookahead+e.insert<b)););}while(e.lookahead<y&&0!==e.strm.avail_in)}function R(e,t){for(var r,n;;){if(e.lookahead<y){if(T(e),e.lookahead<y&&t===f)return 1;if(0===e.lookahead)break}if(r=0,e.lookahead>=b&&(e.ins_h=(e.ins_h<<e.hash_shift^e.window[e.strstart+b-1])&e.hash_mask,r=e.prev[e.strstart&e.w_mask]=e.head[e.ins_h],e.head[e.ins_h]=e.strstart),0!==r&&e.strstart-r<=e.w_size-y&&(e.match_length=B(e,r)),e.match_length>=b)if(n=h._tr_tally(e,e.strstart-e.match_start,e.match_length-b),e.lookahead-=e.match_length,e.match_length<=e.max_lazy_match&&e.lookahead>=b){for(e.match_length--;e.strstart++,e.ins_h=(e.ins_h<<e.hash_shift^e.window[e.strstart+b-1])&e.hash_mask,r=e.prev[e.strstart&e.w_mask]=e.head[e.ins_h],e.head[e.ins_h]=e.strstart,0!=--e.match_length;);e.strstart++}else e.strstart+=e.match_length,e.match_length=0,e.ins_h=e.window[e.strstart],e.ins_h=(e.ins_h<<e.hash_shift^e.window[e.strstart+1])&e.hash_mask;else n=h._tr_tally(e,0,e.window[e.strstart]),e.lookahead--,e.strstart++;if(n&&(A(e,!1),0===e.strm.avail_out))return 1}return e.insert=e.strstart<b-1?e.strstart:b-1,4===t?(A(e,!0),0===e.strm.avail_out?3:4):e.last_lit&&(A(e,!1),0===e.strm.avail_out)?1:2}function D(e,t){for(var r,n,i;;){if(e.lookahead<y){if(T(e),e.lookahead<y&&t===f)return 1;if(0===e.lookahead)break}if(r=0,e.lookahead>=b&&(e.ins_h=(e.ins_h<<e.hash_shift^e.window[e.strstart+b-1])&e.hash_mask,r=e.prev[e.strstart&e.w_mask]=e.head[e.ins_h],e.head[e.ins_h]=e.strstart),e.prev_length=e.match_length,e.prev_match=e.match_start,e.match_length=b-1,0!==r&&e.prev_length<e.max_lazy_match&&e.strstart-r<=e.w_size-y&&(e.match_length=B(e,r),e.match_length<=5&&(1===e.strategy||e.match_length===b&&4096<e.strstart-e.match_start)&&(e.match_length=b-1)),e.prev_length>=b&&e.match_length<=e.prev_length){for(i=e.strstart+e.lookahead-b,n=h._tr_tally(e,e.strstart-1-e.prev_match,e.prev_length-b),e.lookahead-=e.prev_length-1,e.prev_length-=2;++e.strstart<=i&&(e.ins_h=(e.ins_h<<e.hash_shift^e.window[e.strstart+b-1])&e.hash_mask,r=e.prev[e.strstart&e.w_mask]=e.head[e.ins_h],e.head[e.ins_h]=e.strstart),0!=--e.prev_length;);if(e.match_available=0,e.match_length=b-1,e.strstart++,n&&(A(e,!1),0===e.strm.avail_out))return 1}else if(e.match_available){if((n=h._tr_tally(e,0,e.window[e.strstart-1]))&&A(e,!1),e.strstart++,e.lookahead--,0===e.strm.avail_out)return 1}else e.match_available=1,e.strstart++,e.lookahead--}return e.match_available&&(n=h._tr_tally(e,0,e.window[e.strstart-1]),e.match_available=0),e.insert=e.strstart<b-1?e.strstart:b-1,4===t?(A(e,!0),0===e.strm.avail_out?3:4):e.last_lit&&(A(e,!1),0===e.strm.avail_out)?1:2}function F(e,t,r,n,i){this.good_length=e,this.max_lazy=t,this.nice_length=r,this.max_chain=n,this.func=i}function N(){this.strm=null,this.status=0,this.pending_buf=null,this.pending_buf_size=0,this.pending_out=0,this.pending=0,this.wrap=0,this.gzhead=null,this.gzindex=0,this.method=_,this.last_flush=-1,this.w_size=0,this.w_bits=0,this.w_mask=0,this.window=null,this.window_size=0,this.prev=null,this.head=null,this.ins_h=0,this.hash_size=0,this.hash_bits=0,this.hash_mask=0,this.hash_shift=0,this.block_start=0,this.match_length=0,this.prev_match=0,this.match_available=0,this.strstart=0,this.match_start=0,this.lookahead=0,this.prev_length=0,this.max_chain_length=0,this.max_lazy_match=0,this.level=0,this.strategy=0,this.good_match=0,this.nice_match=0,this.dyn_ltree=new d.Buf16(2*g),this.dyn_dtree=new d.Buf16(2*(2*a+1)),this.bl_tree=new d.Buf16(2*(2*o+1)),E(this.dyn_ltree),E(this.dyn_dtree),E(this.bl_tree),this.l_desc=null,this.d_desc=null,this.bl_desc=null,this.bl_count=new d.Buf16(v+1),this.heap=new d.Buf16(2*s+1),E(this.heap),this.heap_len=0,this.heap_max=0,this.depth=new d.Buf16(2*s+1),E(this.depth),this.l_buf=0,this.lit_bufsize=0,this.last_lit=0,this.d_buf=0,this.opt_len=0,this.static_len=0,this.matches=0,this.insert=0,this.bi_buf=0,this.bi_valid=0}function U(e){var t;return e&&e.state?(e.total_in=e.total_out=0,e.data_type=i,(t=e.state).pending=0,t.pending_out=0,t.wrap<0&&(t.wrap=-t.wrap),t.status=t.wrap?k:x,e.adler=2===t.wrap?0:1,t.last_flush=f,h._tr_init(t),l):S(e,m)}function P(e){var t,r=U(e);return r===l&&((t=e.state).window_size=2*t.w_size,E(t.head),t.max_lazy_match=u[t.level].max_lazy,t.good_match=u[t.level].good_length,t.nice_match=u[t.level].nice_length,t.max_chain_length=u[t.level].max_chain,t.strstart=0,t.block_start=0,t.lookahead=0,t.insert=0,t.match_length=t.prev_length=b-1,t.match_available=0,t.ins_h=0),r}function L(e,t,r,n,i,s){if(!e)return m;var a=1;if(-1===t&&(t=6),n<0?(a=0,n=-n):15<n&&(a=2,n-=16),i<1||9<i||r!==_||n<8||15<n||t<0||9<t||s<0||4<s)return S(e,m);8===n&&(n=9);var o=new N;return(e.state=o).strm=e,o.wrap=a,o.gzhead=null,o.w_bits=n,o.w_size=1<<o.w_bits,o.w_mask=o.w_size-1,o.hash_bits=i+7,o.hash_size=1<<o.hash_bits,o.hash_mask=o.hash_size-1,o.hash_shift=~~((o.hash_bits+b-1)/b),o.window=new d.Buf8(2*o.w_size),o.head=new d.Buf16(o.hash_size),o.prev=new d.Buf16(o.w_size),o.lit_bufsize=1<<i+6,o.pending_buf_size=4*o.lit_bufsize,o.pending_buf=new d.Buf8(o.pending_buf_size),o.d_buf=1*o.lit_bufsize,o.l_buf=3*o.lit_bufsize,o.level=t,o.strategy=s,o.method=r,P(e)}u=[new F(0,0,0,0,function(e,t){var r=65535;for(r>e.pending_buf_size-5&&(r=e.pending_buf_size-5);;){if(e.lookahead<=1){if(T(e),0===e.lookahead&&t===f)return 1;if(0===e.lookahead)break}e.strstart+=e.lookahead,e.lookahead=0;var n=e.block_start+r;if((0===e.strstart||e.strstart>=n)&&(e.lookahead=e.strstart-n,e.strstart=n,A(e,!1),0===e.strm.avail_out))return 1;if(e.strstart-e.block_start>=e.w_size-y&&(A(e,!1),0===e.strm.avail_out))return 1}return e.insert=0,4===t?(A(e,!0),0===e.strm.avail_out?3:4):(e.strstart>e.block_start&&(A(e,!1),e.strm.avail_out),1)}),new F(4,4,8,4,R),new F(4,5,16,8,R),new F(4,6,32,32,R),new F(4,4,16,16,D),new F(8,16,32,32,D),new F(8,16,128,128,D),new F(8,32,128,256,D),new F(32,128,258,1024,D),new F(32,258,258,4096,D)],r.deflateInit=function(e,t){return L(e,t,_,15,8,0)},r.deflateInit2=L,r.deflateReset=P,r.deflateResetKeep=U,r.deflateSetHeader=function(e,t){return e&&e.state?2!==e.state.wrap?m:(e.state.gzhead=t,l):m},r.deflate=function(e,t){var r,n,i,s;if(!e||!e.state||5<t||t<0)return e?S(e,m):m;if(n=e.state,!e.output||!e.input&&0!==e.avail_in||666===n.status&&4!==t)return S(e,0===e.avail_out?-5:m);if(n.strm=e,r=n.last_flush,n.last_flush=t,n.status===k)if(2===n.wrap)e.adler=0,I(n,31),I(n,139),I(n,8),n.gzhead?(I(n,(n.gzhead.text?1:0)+(n.gzhead.hcrc?2:0)+(n.gzhead.extra?4:0)+(n.gzhead.name?8:0)+(n.gzhead.comment?16:0)),I(n,255&n.gzhead.time),I(n,n.gzhead.time>>8&255),I(n,n.gzhead.time>>16&255),I(n,n.gzhead.time>>24&255),I(n,9===n.level?2:2<=n.strategy||n.level<2?4:0),I(n,255&n.gzhead.os),n.gzhead.extra&&n.gzhead.extra.length&&(I(n,255&n.gzhead.extra.length),I(n,n.gzhead.extra.length>>8&255)),n.gzhead.hcrc&&(e.adler=p(e.adler,n.pending_buf,n.pending,0)),n.gzindex=0,n.status=69):(I(n,0),I(n,0),I(n,0),I(n,0),I(n,0),I(n,9===n.level?2:2<=n.strategy||n.level<2?4:0),I(n,3),n.status=x);else{var a=_+(n.w_bits-8<<4)<<8;a|=(2<=n.strategy||n.level<2?0:n.level<6?1:6===n.level?2:3)<<6,0!==n.strstart&&(a|=32),a+=31-a%31,n.status=x,O(n,a),0!==n.strstart&&(O(n,e.adler>>>16),O(n,65535&e.adler)),e.adler=1}if(69===n.status)if(n.gzhead.extra){for(i=n.pending;n.gzindex<(65535&n.gzhead.extra.length)&&(n.pending!==n.pending_buf_size||(n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),C(e),i=n.pending,n.pending!==n.pending_buf_size));)I(n,255&n.gzhead.extra[n.gzindex]),n.gzindex++;n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),n.gzindex===n.gzhead.extra.length&&(n.gzindex=0,n.status=73)}else n.status=73;if(73===n.status)if(n.gzhead.name){i=n.pending;do{if(n.pending===n.pending_buf_size&&(n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),C(e),i=n.pending,n.pending===n.pending_buf_size)){s=1;break}s=n.gzindex<n.gzhead.name.length?255&n.gzhead.name.charCodeAt(n.gzindex++):0,I(n,s)}while(0!==s);n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),0===s&&(n.gzindex=0,n.status=91)}else n.status=91;if(91===n.status)if(n.gzhead.comment){i=n.pending;do{if(n.pending===n.pending_buf_size&&(n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),C(e),i=n.pending,n.pending===n.pending_buf_size)){s=1;break}s=n.gzindex<n.gzhead.comment.length?255&n.gzhead.comment.charCodeAt(n.gzindex++):0,I(n,s)}while(0!==s);n.gzhead.hcrc&&n.pending>i&&(e.adler=p(e.adler,n.pending_buf,n.pending-i,i)),0===s&&(n.status=103)}else n.status=103;if(103===n.status&&(n.gzhead.hcrc?(n.pending+2>n.pending_buf_size&&C(e),n.pending+2<=n.pending_buf_size&&(I(n,255&e.adler),I(n,e.adler>>8&255),e.adler=0,n.status=x)):n.status=x),0!==n.pending){if(C(e),0===e.avail_out)return n.last_flush=-1,l}else if(0===e.avail_in&&z(t)<=z(r)&&4!==t)return S(e,-5);if(666===n.status&&0!==e.avail_in)return S(e,-5);if(0!==e.avail_in||0!==n.lookahead||t!==f&&666!==n.status){var o=2===n.strategy?function(e,t){for(var r;;){if(0===e.lookahead&&(T(e),0===e.lookahead)){if(t===f)return 1;break}if(e.match_length=0,r=h._tr_tally(e,0,e.window[e.strstart]),e.lookahead--,e.strstart++,r&&(A(e,!1),0===e.strm.avail_out))return 1}return e.insert=0,4===t?(A(e,!0),0===e.strm.avail_out?3:4):e.last_lit&&(A(e,!1),0===e.strm.avail_out)?1:2}(n,t):3===n.strategy?function(e,t){for(var r,n,i,s,a=e.window;;){if(e.lookahead<=w){if(T(e),e.lookahead<=w&&t===f)return 1;if(0===e.lookahead)break}if(e.match_length=0,e.lookahead>=b&&0<e.strstart&&(n=a[i=e.strstart-1])===a[++i]&&n===a[++i]&&n===a[++i]){s=e.strstart+w;do{}while(n===a[++i]&&n===a[++i]&&n===a[++i]&&n===a[++i]&&n===a[++i]&&n===a[++i]&&n===a[++i]&&n===a[++i]&&i<s);e.match_length=w-(s-i),e.match_length>e.lookahead&&(e.match_length=e.lookahead)}if(e.match_length>=b?(r=h._tr_tally(e,1,e.match_length-b),e.lookahead-=e.match_length,e.strstart+=e.match_length,e.match_length=0):(r=h._tr_tally(e,0,e.window[e.strstart]),e.lookahead--,e.strstart++),r&&(A(e,!1),0===e.strm.avail_out))return 1}return e.insert=0,4===t?(A(e,!0),0===e.strm.avail_out?3:4):e.last_lit&&(A(e,!1),0===e.strm.avail_out)?1:2}(n,t):u[n.level].func(n,t);if(3!==o&&4!==o||(n.status=666),1===o||3===o)return 0===e.avail_out&&(n.last_flush=-1),l;if(2===o&&(1===t?h._tr_align(n):5!==t&&(h._tr_stored_block(n,0,0,!1),3===t&&(E(n.head),0===n.lookahead&&(n.strstart=0,n.block_start=0,n.insert=0))),C(e),0===e.avail_out))return n.last_flush=-1,l}return 4!==t?l:n.wrap<=0?1:(2===n.wrap?(I(n,255&e.adler),I(n,e.adler>>8&255),I(n,e.adler>>16&255),I(n,e.adler>>24&255),I(n,255&e.total_in),I(n,e.total_in>>8&255),I(n,e.total_in>>16&255),I(n,e.total_in>>24&255)):(O(n,e.adler>>>16),O(n,65535&e.adler)),C(e),0<n.wrap&&(n.wrap=-n.wrap),0!==n.pending?l:1)},r.deflateEnd=function(e){var t;return e&&e.state?(t=e.state.status)!==k&&69!==t&&73!==t&&91!==t&&103!==t&&t!==x&&666!==t?S(e,m):(e.state=null,t===x?S(e,-3):l):m},r.deflateSetDictionary=function(e,t){var r,n,i,s,a,o,u,h,f=t.length;if(!e||!e.state)return m;if(2===(s=(r=e.state).wrap)||1===s&&r.status!==k||r.lookahead)return m;for(1===s&&(e.adler=c(e.adler,t,f,0)),r.wrap=0,f>=r.w_size&&(0===s&&(E(r.head),r.strstart=0,r.block_start=0,r.insert=0),h=new d.Buf8(r.w_size),d.arraySet(h,t,f-r.w_size,r.w_size,0),t=h,f=r.w_size),a=e.avail_in,o=e.next_in,u=e.input,e.avail_in=f,e.next_in=0,e.input=t,T(r);r.lookahead>=b;){for(n=r.strstart,i=r.lookahead-(b-1);r.ins_h=(r.ins_h<<r.hash_shift^r.window[n+b-1])&r.hash_mask,r.prev[n&r.w_mask]=r.head[r.ins_h],r.head[r.ins_h]=n,n++,--i;);r.strstart=n,r.lookahead=b-1,T(r)}return r.strstart+=r.lookahead,r.block_start=r.strstart,r.insert=r.lookahead,r.lookahead=0,r.match_length=r.prev_length=b-1,r.match_available=0,e.next_in=o,e.input=u,e.avail_in=a,r.wrap=s,l},r.deflateInfo="pako deflate (from Nodeca project)"},{"../utils/common":41,"./adler32":43,"./crc32":45,"./messages":51,"./trees":52}],47:[function(e,t,r){"use strict";t.exports=function(){this.text=0,this.time=0,this.xflags=0,this.os=0,this.extra=null,this.extra_len=0,this.name="",this.comment="",this.hcrc=0,this.done=!1}},{}],48:[function(e,t,r){"use strict";t.exports=function(e,t){var r,n,i,s,a,o,u,h,f,l,d,c,p,m,_,g,v,b,w,y,k,x,S,z,E;r=e.state,n=e.next_in,z=e.input,i=n+(e.avail_in-5),s=e.next_out,E=e.output,a=s-(t-e.avail_out),o=s+(e.avail_out-257),u=r.dmax,h=r.wsize,f=r.whave,l=r.wnext,d=r.window,c=r.hold,p=r.bits,m=r.lencode,_=r.distcode,g=(1<<r.lenbits)-1,v=(1<<r.distbits)-1;e:do{p<15&&(c+=z[n++]<<p,p+=8,c+=z[n++]<<p,p+=8),b=m[c&g];t:for(;;){if(c>>>=w=b>>>24,p-=w,0==(w=b>>>16&255))E[s++]=65535&b;else{if(!(16&w)){if(0==(64&w)){b=m[(65535&b)+(c&(1<<w)-1)];continue t}if(32&w){r.mode=12;break e}e.msg="invalid literal/length code",r.mode=30;break e}y=65535&b,(w&=15)&&(p<w&&(c+=z[n++]<<p,p+=8),y+=c&(1<<w)-1,c>>>=w,p-=w),p<15&&(c+=z[n++]<<p,p+=8,c+=z[n++]<<p,p+=8),b=_[c&v];r:for(;;){if(c>>>=w=b>>>24,p-=w,!(16&(w=b>>>16&255))){if(0==(64&w)){b=_[(65535&b)+(c&(1<<w)-1)];continue r}e.msg="invalid distance code",r.mode=30;break e}if(k=65535&b,p<(w&=15)&&(c+=z[n++]<<p,(p+=8)<w&&(c+=z[n++]<<p,p+=8)),u<(k+=c&(1<<w)-1)){e.msg="invalid distance too far back",r.mode=30;break e}if(c>>>=w,p-=w,(w=s-a)<k){if(f<(w=k-w)&&r.sane){e.msg="invalid distance too far back",r.mode=30;break e}if(S=d,(x=0)===l){if(x+=h-w,w<y){for(y-=w;E[s++]=d[x++],--w;);x=s-k,S=E}}else if(l<w){if(x+=h+l-w,(w-=l)<y){for(y-=w;E[s++]=d[x++],--w;);if(x=0,l<y){for(y-=w=l;E[s++]=d[x++],--w;);x=s-k,S=E}}}else if(x+=l-w,w<y){for(y-=w;E[s++]=d[x++],--w;);x=s-k,S=E}for(;2<y;)E[s++]=S[x++],E[s++]=S[x++],E[s++]=S[x++],y-=3;y&&(E[s++]=S[x++],1<y&&(E[s++]=S[x++]))}else{for(x=s-k;E[s++]=E[x++],E[s++]=E[x++],E[s++]=E[x++],2<(y-=3););y&&(E[s++]=E[x++],1<y&&(E[s++]=E[x++]))}break}}break}}while(n<i&&s<o);n-=y=p>>3,c&=(1<<(p-=y<<3))-1,e.next_in=n,e.next_out=s,e.avail_in=n<i?i-n+5:5-(n-i),e.avail_out=s<o?o-s+257:257-(s-o),r.hold=c,r.bits=p}},{}],49:[function(e,t,r){"use strict";var I=e("../utils/common"),O=e("./adler32"),B=e("./crc32"),T=e("./inffast"),R=e("./inftrees"),D=1,F=2,N=0,U=-2,P=1,n=852,i=592;function L(e){return(e>>>24&255)+(e>>>8&65280)+((65280&e)<<8)+((255&e)<<24)}function s(){this.mode=0,this.last=!1,this.wrap=0,this.havedict=!1,this.flags=0,this.dmax=0,this.check=0,this.total=0,this.head=null,this.wbits=0,this.wsize=0,this.whave=0,this.wnext=0,this.window=null,this.hold=0,this.bits=0,this.length=0,this.offset=0,this.extra=0,this.lencode=null,this.distcode=null,this.lenbits=0,this.distbits=0,this.ncode=0,this.nlen=0,this.ndist=0,this.have=0,this.next=null,this.lens=new I.Buf16(320),this.work=new I.Buf16(288),this.lendyn=null,this.distdyn=null,this.sane=0,this.back=0,this.was=0}function a(e){var t;return e&&e.state?(t=e.state,e.total_in=e.total_out=t.total=0,e.msg="",t.wrap&&(e.adler=1&t.wrap),t.mode=P,t.last=0,t.havedict=0,t.dmax=32768,t.head=null,t.hold=0,t.bits=0,t.lencode=t.lendyn=new I.Buf32(n),t.distcode=t.distdyn=new I.Buf32(i),t.sane=1,t.back=-1,N):U}function o(e){var t;return e&&e.state?((t=e.state).wsize=0,t.whave=0,t.wnext=0,a(e)):U}function u(e,t){var r,n;return e&&e.state?(n=e.state,t<0?(r=0,t=-t):(r=1+(t>>4),t<48&&(t&=15)),t&&(t<8||15<t)?U:(null!==n.window&&n.wbits!==t&&(n.window=null),n.wrap=r,n.wbits=t,o(e))):U}function h(e,t){var r,n;return e?(n=new s,(e.state=n).window=null,(r=u(e,t))!==N&&(e.state=null),r):U}var f,l,d=!0;function j(e){if(d){var t;for(f=new I.Buf32(512),l=new I.Buf32(32),t=0;t<144;)e.lens[t++]=8;for(;t<256;)e.lens[t++]=9;for(;t<280;)e.lens[t++]=7;for(;t<288;)e.lens[t++]=8;for(R(D,e.lens,0,288,f,0,e.work,{bits:9}),t=0;t<32;)e.lens[t++]=5;R(F,e.lens,0,32,l,0,e.work,{bits:5}),d=!1}e.lencode=f,e.lenbits=9,e.distcode=l,e.distbits=5}function Z(e,t,r,n){var i,s=e.state;return null===s.window&&(s.wsize=1<<s.wbits,s.wnext=0,s.whave=0,s.window=new I.Buf8(s.wsize)),n>=s.wsize?(I.arraySet(s.window,t,r-s.wsize,s.wsize,0),s.wnext=0,s.whave=s.wsize):(n<(i=s.wsize-s.wnext)&&(i=n),I.arraySet(s.window,t,r-n,i,s.wnext),(n-=i)?(I.arraySet(s.window,t,r-n,n,0),s.wnext=n,s.whave=s.wsize):(s.wnext+=i,s.wnext===s.wsize&&(s.wnext=0),s.whave<s.wsize&&(s.whave+=i))),0}r.inflateReset=o,r.inflateReset2=u,r.inflateResetKeep=a,r.inflateInit=function(e){return h(e,15)},r.inflateInit2=h,r.inflate=function(e,t){var r,n,i,s,a,o,u,h,f,l,d,c,p,m,_,g,v,b,w,y,k,x,S,z,E=0,C=new I.Buf8(4),A=[16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];if(!e||!e.state||!e.output||!e.input&&0!==e.avail_in)return U;12===(r=e.state).mode&&(r.mode=13),a=e.next_out,i=e.output,u=e.avail_out,s=e.next_in,n=e.input,o=e.avail_in,h=r.hold,f=r.bits,l=o,d=u,x=N;e:for(;;)switch(r.mode){case P:if(0===r.wrap){r.mode=13;break}for(;f<16;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(2&r.wrap&&35615===h){C[r.check=0]=255&h,C[1]=h>>>8&255,r.check=B(r.check,C,2,0),f=h=0,r.mode=2;break}if(r.flags=0,r.head&&(r.head.done=!1),!(1&r.wrap)||(((255&h)<<8)+(h>>8))%31){e.msg="incorrect header check",r.mode=30;break}if(8!=(15&h)){e.msg="unknown compression method",r.mode=30;break}if(f-=4,k=8+(15&(h>>>=4)),0===r.wbits)r.wbits=k;else if(k>r.wbits){e.msg="invalid window size",r.mode=30;break}r.dmax=1<<k,e.adler=r.check=1,r.mode=512&h?10:12,f=h=0;break;case 2:for(;f<16;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(r.flags=h,8!=(255&r.flags)){e.msg="unknown compression method",r.mode=30;break}if(57344&r.flags){e.msg="unknown header flags set",r.mode=30;break}r.head&&(r.head.text=h>>8&1),512&r.flags&&(C[0]=255&h,C[1]=h>>>8&255,r.check=B(r.check,C,2,0)),f=h=0,r.mode=3;case 3:for(;f<32;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.head&&(r.head.time=h),512&r.flags&&(C[0]=255&h,C[1]=h>>>8&255,C[2]=h>>>16&255,C[3]=h>>>24&255,r.check=B(r.check,C,4,0)),f=h=0,r.mode=4;case 4:for(;f<16;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.head&&(r.head.xflags=255&h,r.head.os=h>>8),512&r.flags&&(C[0]=255&h,C[1]=h>>>8&255,r.check=B(r.check,C,2,0)),f=h=0,r.mode=5;case 5:if(1024&r.flags){for(;f<16;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.length=h,r.head&&(r.head.extra_len=h),512&r.flags&&(C[0]=255&h,C[1]=h>>>8&255,r.check=B(r.check,C,2,0)),f=h=0}else r.head&&(r.head.extra=null);r.mode=6;case 6:if(1024&r.flags&&(o<(c=r.length)&&(c=o),c&&(r.head&&(k=r.head.extra_len-r.length,r.head.extra||(r.head.extra=new Array(r.head.extra_len)),I.arraySet(r.head.extra,n,s,c,k)),512&r.flags&&(r.check=B(r.check,n,c,s)),o-=c,s+=c,r.length-=c),r.length))break e;r.length=0,r.mode=7;case 7:if(2048&r.flags){if(0===o)break e;for(c=0;k=n[s+c++],r.head&&k&&r.length<65536&&(r.head.name+=String.fromCharCode(k)),k&&c<o;);if(512&r.flags&&(r.check=B(r.check,n,c,s)),o-=c,s+=c,k)break e}else r.head&&(r.head.name=null);r.length=0,r.mode=8;case 8:if(4096&r.flags){if(0===o)break e;for(c=0;k=n[s+c++],r.head&&k&&r.length<65536&&(r.head.comment+=String.fromCharCode(k)),k&&c<o;);if(512&r.flags&&(r.check=B(r.check,n,c,s)),o-=c,s+=c,k)break e}else r.head&&(r.head.comment=null);r.mode=9;case 9:if(512&r.flags){for(;f<16;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(h!==(65535&r.check)){e.msg="header crc mismatch",r.mode=30;break}f=h=0}r.head&&(r.head.hcrc=r.flags>>9&1,r.head.done=!0),e.adler=r.check=0,r.mode=12;break;case 10:for(;f<32;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}e.adler=r.check=L(h),f=h=0,r.mode=11;case 11:if(0===r.havedict)return e.next_out=a,e.avail_out=u,e.next_in=s,e.avail_in=o,r.hold=h,r.bits=f,2;e.adler=r.check=1,r.mode=12;case 12:if(5===t||6===t)break e;case 13:if(r.last){h>>>=7&f,f-=7&f,r.mode=27;break}for(;f<3;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}switch(r.last=1&h,f-=1,3&(h>>>=1)){case 0:r.mode=14;break;case 1:if(j(r),r.mode=20,6!==t)break;h>>>=2,f-=2;break e;case 2:r.mode=17;break;case 3:e.msg="invalid block type",r.mode=30}h>>>=2,f-=2;break;case 14:for(h>>>=7&f,f-=7&f;f<32;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if((65535&h)!=(h>>>16^65535)){e.msg="invalid stored block lengths",r.mode=30;break}if(r.length=65535&h,f=h=0,r.mode=15,6===t)break e;case 15:r.mode=16;case 16:if(c=r.length){if(o<c&&(c=o),u<c&&(c=u),0===c)break e;I.arraySet(i,n,s,c,a),o-=c,s+=c,u-=c,a+=c,r.length-=c;break}r.mode=12;break;case 17:for(;f<14;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(r.nlen=257+(31&h),h>>>=5,f-=5,r.ndist=1+(31&h),h>>>=5,f-=5,r.ncode=4+(15&h),h>>>=4,f-=4,286<r.nlen||30<r.ndist){e.msg="too many length or distance symbols",r.mode=30;break}r.have=0,r.mode=18;case 18:for(;r.have<r.ncode;){for(;f<3;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.lens[A[r.have++]]=7&h,h>>>=3,f-=3}for(;r.have<19;)r.lens[A[r.have++]]=0;if(r.lencode=r.lendyn,r.lenbits=7,S={bits:r.lenbits},x=R(0,r.lens,0,19,r.lencode,0,r.work,S),r.lenbits=S.bits,x){e.msg="invalid code lengths set",r.mode=30;break}r.have=0,r.mode=19;case 19:for(;r.have<r.nlen+r.ndist;){for(;g=(E=r.lencode[h&(1<<r.lenbits)-1])>>>16&255,v=65535&E,!((_=E>>>24)<=f);){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(v<16)h>>>=_,f-=_,r.lens[r.have++]=v;else{if(16===v){for(z=_+2;f<z;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(h>>>=_,f-=_,0===r.have){e.msg="invalid bit length repeat",r.mode=30;break}k=r.lens[r.have-1],c=3+(3&h),h>>>=2,f-=2}else if(17===v){for(z=_+3;f<z;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}f-=_,k=0,c=3+(7&(h>>>=_)),h>>>=3,f-=3}else{for(z=_+7;f<z;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}f-=_,k=0,c=11+(127&(h>>>=_)),h>>>=7,f-=7}if(r.have+c>r.nlen+r.ndist){e.msg="invalid bit length repeat",r.mode=30;break}for(;c--;)r.lens[r.have++]=k}}if(30===r.mode)break;if(0===r.lens[256]){e.msg="invalid code -- missing end-of-block",r.mode=30;break}if(r.lenbits=9,S={bits:r.lenbits},x=R(D,r.lens,0,r.nlen,r.lencode,0,r.work,S),r.lenbits=S.bits,x){e.msg="invalid literal/lengths set",r.mode=30;break}if(r.distbits=6,r.distcode=r.distdyn,S={bits:r.distbits},x=R(F,r.lens,r.nlen,r.ndist,r.distcode,0,r.work,S),r.distbits=S.bits,x){e.msg="invalid distances set",r.mode=30;break}if(r.mode=20,6===t)break e;case 20:r.mode=21;case 21:if(6<=o&&258<=u){e.next_out=a,e.avail_out=u,e.next_in=s,e.avail_in=o,r.hold=h,r.bits=f,T(e,d),a=e.next_out,i=e.output,u=e.avail_out,s=e.next_in,n=e.input,o=e.avail_in,h=r.hold,f=r.bits,12===r.mode&&(r.back=-1);break}for(r.back=0;g=(E=r.lencode[h&(1<<r.lenbits)-1])>>>16&255,v=65535&E,!((_=E>>>24)<=f);){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(g&&0==(240&g)){for(b=_,w=g,y=v;g=(E=r.lencode[y+((h&(1<<b+w)-1)>>b)])>>>16&255,v=65535&E,!(b+(_=E>>>24)<=f);){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}h>>>=b,f-=b,r.back+=b}if(h>>>=_,f-=_,r.back+=_,r.length=v,0===g){r.mode=26;break}if(32&g){r.back=-1,r.mode=12;break}if(64&g){e.msg="invalid literal/length code",r.mode=30;break}r.extra=15&g,r.mode=22;case 22:if(r.extra){for(z=r.extra;f<z;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.length+=h&(1<<r.extra)-1,h>>>=r.extra,f-=r.extra,r.back+=r.extra}r.was=r.length,r.mode=23;case 23:for(;g=(E=r.distcode[h&(1<<r.distbits)-1])>>>16&255,v=65535&E,!((_=E>>>24)<=f);){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(0==(240&g)){for(b=_,w=g,y=v;g=(E=r.distcode[y+((h&(1<<b+w)-1)>>b)])>>>16&255,v=65535&E,!(b+(_=E>>>24)<=f);){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}h>>>=b,f-=b,r.back+=b}if(h>>>=_,f-=_,r.back+=_,64&g){e.msg="invalid distance code",r.mode=30;break}r.offset=v,r.extra=15&g,r.mode=24;case 24:if(r.extra){for(z=r.extra;f<z;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}r.offset+=h&(1<<r.extra)-1,h>>>=r.extra,f-=r.extra,r.back+=r.extra}if(r.offset>r.dmax){e.msg="invalid distance too far back",r.mode=30;break}r.mode=25;case 25:if(0===u)break e;if(c=d-u,r.offset>c){if((c=r.offset-c)>r.whave&&r.sane){e.msg="invalid distance too far back",r.mode=30;break}p=c>r.wnext?(c-=r.wnext,r.wsize-c):r.wnext-c,c>r.length&&(c=r.length),m=r.window}else m=i,p=a-r.offset,c=r.length;for(u<c&&(c=u),u-=c,r.length-=c;i[a++]=m[p++],--c;);0===r.length&&(r.mode=21);break;case 26:if(0===u)break e;i[a++]=r.length,u--,r.mode=21;break;case 27:if(r.wrap){for(;f<32;){if(0===o)break e;o--,h|=n[s++]<<f,f+=8}if(d-=u,e.total_out+=d,r.total+=d,d&&(e.adler=r.check=r.flags?B(r.check,i,d,a-d):O(r.check,i,d,a-d)),d=u,(r.flags?h:L(h))!==r.check){e.msg="incorrect data check",r.mode=30;break}f=h=0}r.mode=28;case 28:if(r.wrap&&r.flags){for(;f<32;){if(0===o)break e;o--,h+=n[s++]<<f,f+=8}if(h!==(4294967295&r.total)){e.msg="incorrect length check",r.mode=30;break}f=h=0}r.mode=29;case 29:x=1;break e;case 30:x=-3;break e;case 31:return-4;case 32:default:return U}return e.next_out=a,e.avail_out=u,e.next_in=s,e.avail_in=o,r.hold=h,r.bits=f,(r.wsize||d!==e.avail_out&&r.mode<30&&(r.mode<27||4!==t))&&Z(e,e.output,e.next_out,d-e.avail_out)?(r.mode=31,-4):(l-=e.avail_in,d-=e.avail_out,e.total_in+=l,e.total_out+=d,r.total+=d,r.wrap&&d&&(e.adler=r.check=r.flags?B(r.check,i,d,e.next_out-d):O(r.check,i,d,e.next_out-d)),e.data_type=r.bits+(r.last?64:0)+(12===r.mode?128:0)+(20===r.mode||15===r.mode?256:0),(0==l&&0===d||4===t)&&x===N&&(x=-5),x)},r.inflateEnd=function(e){if(!e||!e.state)return U;var t=e.state;return t.window&&(t.window=null),e.state=null,N},r.inflateGetHeader=function(e,t){var r;return e&&e.state?0==(2&(r=e.state).wrap)?U:((r.head=t).done=!1,N):U},r.inflateSetDictionary=function(e,t){var r,n=t.length;return e&&e.state?0!==(r=e.state).wrap&&11!==r.mode?U:11===r.mode&&O(1,t,n,0)!==r.check?-3:Z(e,t,n,n)?(r.mode=31,-4):(r.havedict=1,N):U},r.inflateInfo="pako inflate (from Nodeca project)"},{"../utils/common":41,"./adler32":43,"./crc32":45,"./inffast":48,"./inftrees":50}],50:[function(e,t,r){"use strict";var D=e("../utils/common"),F=[3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258,0,0],N=[16,16,16,16,16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,21,21,21,21,16,72,78],U=[1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,0,0],P=[16,16,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29,64,64];t.exports=function(e,t,r,n,i,s,a,o){var u,h,f,l,d,c,p,m,_,g=o.bits,v=0,b=0,w=0,y=0,k=0,x=0,S=0,z=0,E=0,C=0,A=null,I=0,O=new D.Buf16(16),B=new D.Buf16(16),T=null,R=0;for(v=0;v<=15;v++)O[v]=0;for(b=0;b<n;b++)O[t[r+b]]++;for(k=g,y=15;1<=y&&0===O[y];y--);if(y<k&&(k=y),0===y)return i[s++]=20971520,i[s++]=20971520,o.bits=1,0;for(w=1;w<y&&0===O[w];w++);for(k<w&&(k=w),v=z=1;v<=15;v++)if(z<<=1,(z-=O[v])<0)return-1;if(0<z&&(0===e||1!==y))return-1;for(B[1]=0,v=1;v<15;v++)B[v+1]=B[v]+O[v];for(b=0;b<n;b++)0!==t[r+b]&&(a[B[t[r+b]]++]=b);if(c=0===e?(A=T=a,19):1===e?(A=F,I-=257,T=N,R-=257,256):(A=U,T=P,-1),v=w,d=s,S=b=C=0,f=-1,l=(E=1<<(x=k))-1,1===e&&852<E||2===e&&592<E)return 1;for(;;){for(p=v-S,_=a[b]<c?(m=0,a[b]):a[b]>c?(m=T[R+a[b]],A[I+a[b]]):(m=96,0),u=1<<v-S,w=h=1<<x;i[d+(C>>S)+(h-=u)]=p<<24|m<<16|_|0,0!==h;);for(u=1<<v-1;C&u;)u>>=1;if(0!==u?(C&=u-1,C+=u):C=0,b++,0==--O[v]){if(v===y)break;v=t[r+a[b]]}if(k<v&&(C&l)!==f){for(0===S&&(S=k),d+=w,z=1<<(x=v-S);x+S<y&&!((z-=O[x+S])<=0);)x++,z<<=1;if(E+=1<<x,1===e&&852<E||2===e&&592<E)return 1;i[f=C&l]=k<<24|x<<16|d-s|0}}return 0!==C&&(i[d+C]=v-S<<24|64<<16|0),o.bits=k,0}},{"../utils/common":41}],51:[function(e,t,r){"use strict";t.exports={2:"need dictionary",1:"stream end",0:"","-1":"file error","-2":"stream error","-3":"data error","-4":"insufficient memory","-5":"buffer error","-6":"incompatible version"}},{}],52:[function(e,t,r){"use strict";var o=e("../utils/common");function n(e){for(var t=e.length;0<=--t;)e[t]=0}var _=15,i=16,u=[0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0],h=[0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13],a=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,3,7],f=[16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15],l=new Array(576);n(l);var d=new Array(60);n(d);var c=new Array(512);n(c);var p=new Array(256);n(p);var m=new Array(29);n(m);var g,v,b,w=new Array(30);function y(e,t,r,n,i){this.static_tree=e,this.extra_bits=t,this.extra_base=r,this.elems=n,this.max_length=i,this.has_stree=e&&e.length}function s(e,t){this.dyn_tree=e,this.max_code=0,this.stat_desc=t}function k(e){return e<256?c[e]:c[256+(e>>>7)]}function x(e,t){e.pending_buf[e.pending++]=255&t,e.pending_buf[e.pending++]=t>>>8&255}function S(e,t,r){e.bi_valid>i-r?(e.bi_buf|=t<<e.bi_valid&65535,x(e,e.bi_buf),e.bi_buf=t>>i-e.bi_valid,e.bi_valid+=r-i):(e.bi_buf|=t<<e.bi_valid&65535,e.bi_valid+=r)}function z(e,t,r){S(e,r[2*t],r[2*t+1])}function E(e,t){for(var r=0;r|=1&e,e>>>=1,r<<=1,0<--t;);return r>>>1}function C(e,t,r){var n,i,s=new Array(_+1),a=0;for(n=1;n<=_;n++)s[n]=a=a+r[n-1]<<1;for(i=0;i<=t;i++){var o=e[2*i+1];0!==o&&(e[2*i]=E(s[o]++,o))}}function A(e){var t;for(t=0;t<286;t++)e.dyn_ltree[2*t]=0;for(t=0;t<30;t++)e.dyn_dtree[2*t]=0;for(t=0;t<19;t++)e.bl_tree[2*t]=0;e.dyn_ltree[512]=1,e.opt_len=e.static_len=0,e.last_lit=e.matches=0}function I(e){8<e.bi_valid?x(e,e.bi_buf):0<e.bi_valid&&(e.pending_buf[e.pending++]=e.bi_buf),e.bi_buf=0,e.bi_valid=0}function O(e,t,r,n){var i=2*t,s=2*r;return e[i]<e[s]||e[i]===e[s]&&n[t]<=n[r]}function B(e,t,r){for(var n=e.heap[r],i=r<<1;i<=e.heap_len&&(i<e.heap_len&&O(t,e.heap[i+1],e.heap[i],e.depth)&&i++,!O(t,n,e.heap[i],e.depth));)e.heap[r]=e.heap[i],r=i,i<<=1;e.heap[r]=n}function T(e,t,r){var n,i,s,a,o=0;if(0!==e.last_lit)for(;n=e.pending_buf[e.d_buf+2*o]<<8|e.pending_buf[e.d_buf+2*o+1],i=e.pending_buf[e.l_buf+o],o++,0===n?z(e,i,t):(z(e,(s=p[i])+256+1,t),0!==(a=u[s])&&S(e,i-=m[s],a),z(e,s=k(--n),r),0!==(a=h[s])&&S(e,n-=w[s],a)),o<e.last_lit;);z(e,256,t)}function R(e,t){var r,n,i,s=t.dyn_tree,a=t.stat_desc.static_tree,o=t.stat_desc.has_stree,u=t.stat_desc.elems,h=-1;for(e.heap_len=0,e.heap_max=573,r=0;r<u;r++)0!==s[2*r]?(e.heap[++e.heap_len]=h=r,e.depth[r]=0):s[2*r+1]=0;for(;e.heap_len<2;)s[2*(i=e.heap[++e.heap_len]=h<2?++h:0)]=1,e.depth[i]=0,e.opt_len--,o&&(e.static_len-=a[2*i+1]);for(t.max_code=h,r=e.heap_len>>1;1<=r;r--)B(e,s,r);for(i=u;r=e.heap[1],e.heap[1]=e.heap[e.heap_len--],B(e,s,1),n=e.heap[1],e.heap[--e.heap_max]=r,e.heap[--e.heap_max]=n,s[2*i]=s[2*r]+s[2*n],e.depth[i]=(e.depth[r]>=e.depth[n]?e.depth[r]:e.depth[n])+1,s[2*r+1]=s[2*n+1]=i,e.heap[1]=i++,B(e,s,1),2<=e.heap_len;);e.heap[--e.heap_max]=e.heap[1],function(e,t){var r,n,i,s,a,o,u=t.dyn_tree,h=t.max_code,f=t.stat_desc.static_tree,l=t.stat_desc.has_stree,d=t.stat_desc.extra_bits,c=t.stat_desc.extra_base,p=t.stat_desc.max_length,m=0;for(s=0;s<=_;s++)e.bl_count[s]=0;for(u[2*e.heap[e.heap_max]+1]=0,r=e.heap_max+1;r<573;r++)p<(s=u[2*u[2*(n=e.heap[r])+1]+1]+1)&&(s=p,m++),u[2*n+1]=s,h<n||(e.bl_count[s]++,a=0,c<=n&&(a=d[n-c]),o=u[2*n],e.opt_len+=o*(s+a),l&&(e.static_len+=o*(f[2*n+1]+a)));if(0!==m){do{for(s=p-1;0===e.bl_count[s];)s--;e.bl_count[s]--,e.bl_count[s+1]+=2,e.bl_count[p]--,m-=2}while(0<m);for(s=p;0!==s;s--)for(n=e.bl_count[s];0!==n;)h<(i=e.heap[--r])||(u[2*i+1]!==s&&(e.opt_len+=(s-u[2*i+1])*u[2*i],u[2*i+1]=s),n--)}}(e,t),C(s,h,e.bl_count)}function D(e,t,r){var n,i,s=-1,a=t[1],o=0,u=7,h=4;for(0===a&&(u=138,h=3),t[2*(r+1)+1]=65535,n=0;n<=r;n++)i=a,a=t[2*(n+1)+1],++o<u&&i===a||(o<h?e.bl_tree[2*i]+=o:0!==i?(i!==s&&e.bl_tree[2*i]++,e.bl_tree[32]++):o<=10?e.bl_tree[34]++:e.bl_tree[36]++,s=i,h=(o=0)===a?(u=138,3):i===a?(u=6,3):(u=7,4))}function F(e,t,r){var n,i,s=-1,a=t[1],o=0,u=7,h=4;for(0===a&&(u=138,h=3),n=0;n<=r;n++)if(i=a,a=t[2*(n+1)+1],!(++o<u&&i===a)){if(o<h)for(;z(e,i,e.bl_tree),0!=--o;);else 0!==i?(i!==s&&(z(e,i,e.bl_tree),o--),z(e,16,e.bl_tree),S(e,o-3,2)):o<=10?(z(e,17,e.bl_tree),S(e,o-3,3)):(z(e,18,e.bl_tree),S(e,o-11,7));s=i,h=(o=0)===a?(u=138,3):i===a?(u=6,3):(u=7,4)}}n(w);var N=!1;function U(e,t,r,n){var i,s,a;S(e,0+(n?1:0),3),s=t,a=r,I(i=e),x(i,a),x(i,~a),o.arraySet(i.pending_buf,i.window,s,a,i.pending),i.pending+=a}r._tr_init=function(e){N||(function(){var e,t,r,n,i,s=new Array(_+1);for(n=r=0;n<28;n++)for(m[n]=r,e=0;e<1<<u[n];e++)p[r++]=n;for(p[r-1]=n,n=i=0;n<16;n++)for(w[n]=i,e=0;e<1<<h[n];e++)c[i++]=n;for(i>>=7;n<30;n++)for(w[n]=i<<7,e=0;e<1<<h[n]-7;e++)c[256+i++]=n;for(t=0;t<=_;t++)s[t]=0;for(e=0;e<=143;)l[2*e+1]=8,e++,s[8]++;for(;e<=255;)l[2*e+1]=9,e++,s[9]++;for(;e<=279;)l[2*e+1]=7,e++,s[7]++;for(;e<=287;)l[2*e+1]=8,e++,s[8]++;for(C(l,287,s),e=0;e<30;e++)d[2*e+1]=5,d[2*e]=E(e,5);g=new y(l,u,257,286,_),v=new y(d,h,0,30,_),b=new y(new Array(0),a,0,19,7)}(),N=!0),e.l_desc=new s(e.dyn_ltree,g),e.d_desc=new s(e.dyn_dtree,v),e.bl_desc=new s(e.bl_tree,b),e.bi_buf=0,e.bi_valid=0,A(e)},r._tr_stored_block=U,r._tr_flush_block=function(e,t,r,n){var i,s,a=0;0<e.level?(2===e.strm.data_type&&(e.strm.data_type=function(e){var t,r=4093624447;for(t=0;t<=31;t++,r>>>=1)if(1&r&&0!==e.dyn_ltree[2*t])return 0;if(0!==e.dyn_ltree[18]||0!==e.dyn_ltree[20]||0!==e.dyn_ltree[26])return 1;for(t=32;t<256;t++)if(0!==e.dyn_ltree[2*t])return 1;return 0}(e)),R(e,e.l_desc),R(e,e.d_desc),a=function(e){var t;for(D(e,e.dyn_ltree,e.l_desc.max_code),D(e,e.dyn_dtree,e.d_desc.max_code),R(e,e.bl_desc),t=18;3<=t&&0===e.bl_tree[2*f[t]+1];t--);return e.opt_len+=3*(t+1)+5+5+4,t}(e),i=e.opt_len+3+7>>>3,(s=e.static_len+3+7>>>3)<=i&&(i=s)):i=s=r+5,r+4<=i&&-1!==t?U(e,t,r,n):4===e.strategy||s===i?(S(e,2+(n?1:0),3),T(e,l,d)):(S(e,4+(n?1:0),3),function(e,t,r,n){var i;for(S(e,t-257,5),S(e,r-1,5),S(e,n-4,4),i=0;i<n;i++)S(e,e.bl_tree[2*f[i]+1],3);F(e,e.dyn_ltree,t-1),F(e,e.dyn_dtree,r-1)}(e,e.l_desc.max_code+1,e.d_desc.max_code+1,a+1),T(e,e.dyn_ltree,e.dyn_dtree)),A(e),n&&I(e)},r._tr_tally=function(e,t,r){return e.pending_buf[e.d_buf+2*e.last_lit]=t>>>8&255,e.pending_buf[e.d_buf+2*e.last_lit+1]=255&t,e.pending_buf[e.l_buf+e.last_lit]=255&r,e.last_lit++,0===t?e.dyn_ltree[2*r]++:(e.matches++,t--,e.dyn_ltree[2*(p[r]+256+1)]++,e.dyn_dtree[2*k(t)]++),e.last_lit===e.lit_bufsize-1},r._tr_align=function(e){var t;S(e,2,3),z(e,256,l),16===(t=e).bi_valid?(x(t,t.bi_buf),t.bi_buf=0,t.bi_valid=0):8<=t.bi_valid&&(t.pending_buf[t.pending++]=255&t.bi_buf,t.bi_buf>>=8,t.bi_valid-=8)}},{"../utils/common":41}],53:[function(e,t,r){"use strict";t.exports=function(){this.input=null,this.next_in=0,this.avail_in=0,this.total_in=0,this.output=null,this.next_out=0,this.avail_out=0,this.total_out=0,this.msg="",this.state=null,this.data_type=2,this.adler=0}},{}],54:[function(e,t,r){"use strict";t.exports="function"==typeof setImmediate?setImmediate:function(){var e=[].slice.apply(arguments);e.splice(1,0,0),setTimeout.apply(null,e)}},{}]},{},[10])(10)})}).call(this,void 0!==r?r:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}]},{},[1])(1)})}).call(this,void 0!==r?r:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}]},{},[1])(1)})}).call(this,void 0!==r?r:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}]},{},[1])(1)})}).call(this,void 0!==r?r:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}]},{},[1])(1)})}).call(this,"undefined"!=typeof __webpack_require__.g?__webpack_require__.g:"undefined"!=typeof self?self:"undefined"!=typeof window?window:{})},{}]},{},[1])(1)});

/***/ }),

/***/ 9483:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

/*!
    localForage -- Offline Storage, Improved
    Version 1.9.0
    https://localforage.github.io/localForage
    (c) 2013-2017 Mozilla, Apache License 2.0
*/
(function(f){if(true){module.exports=f()}else { var g; }})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=undefined;if(!u&&a)return require(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw (f.code="MODULE_NOT_FOUND", f)}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=undefined;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
(function (global){
'use strict';
var Mutation = global.MutationObserver || global.WebKitMutationObserver;

var scheduleDrain;

{
  if (Mutation) {
    var called = 0;
    var observer = new Mutation(nextTick);
    var element = global.document.createTextNode('');
    observer.observe(element, {
      characterData: true
    });
    scheduleDrain = function () {
      element.data = (called = ++called % 2);
    };
  } else if (!global.setImmediate && typeof global.MessageChannel !== 'undefined') {
    var channel = new global.MessageChannel();
    channel.port1.onmessage = nextTick;
    scheduleDrain = function () {
      channel.port2.postMessage(0);
    };
  } else if ('document' in global && 'onreadystatechange' in global.document.createElement('script')) {
    scheduleDrain = function () {

      // Create a <script> element; its readystatechange event will be fired asynchronously once it is inserted
      // into the document. Do so, thus queuing up the task. Remember to clean up once it's been called.
      var scriptEl = global.document.createElement('script');
      scriptEl.onreadystatechange = function () {
        nextTick();

        scriptEl.onreadystatechange = null;
        scriptEl.parentNode.removeChild(scriptEl);
        scriptEl = null;
      };
      global.document.documentElement.appendChild(scriptEl);
    };
  } else {
    scheduleDrain = function () {
      setTimeout(nextTick, 0);
    };
  }
}

var draining;
var queue = [];
//named nextTick for less confusing stack traces
function nextTick() {
  draining = true;
  var i, oldQueue;
  var len = queue.length;
  while (len) {
    oldQueue = queue;
    queue = [];
    i = -1;
    while (++i < len) {
      oldQueue[i]();
    }
    len = queue.length;
  }
  draining = false;
}

module.exports = immediate;
function immediate(task) {
  if (queue.push(task) === 1 && !draining) {
    scheduleDrain();
  }
}

}).call(this,typeof __webpack_require__.g !== "undefined" ? __webpack_require__.g : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{}],2:[function(_dereq_,module,exports){
'use strict';
var immediate = _dereq_(1);

/* istanbul ignore next */
function INTERNAL() {}

var handlers = {};

var REJECTED = ['REJECTED'];
var FULFILLED = ['FULFILLED'];
var PENDING = ['PENDING'];

module.exports = Promise;

function Promise(resolver) {
  if (typeof resolver !== 'function') {
    throw new TypeError('resolver must be a function');
  }
  this.state = PENDING;
  this.queue = [];
  this.outcome = void 0;
  if (resolver !== INTERNAL) {
    safelyResolveThenable(this, resolver);
  }
}

Promise.prototype["catch"] = function (onRejected) {
  return this.then(null, onRejected);
};
Promise.prototype.then = function (onFulfilled, onRejected) {
  if (typeof onFulfilled !== 'function' && this.state === FULFILLED ||
    typeof onRejected !== 'function' && this.state === REJECTED) {
    return this;
  }
  var promise = new this.constructor(INTERNAL);
  if (this.state !== PENDING) {
    var resolver = this.state === FULFILLED ? onFulfilled : onRejected;
    unwrap(promise, resolver, this.outcome);
  } else {
    this.queue.push(new QueueItem(promise, onFulfilled, onRejected));
  }

  return promise;
};
function QueueItem(promise, onFulfilled, onRejected) {
  this.promise = promise;
  if (typeof onFulfilled === 'function') {
    this.onFulfilled = onFulfilled;
    this.callFulfilled = this.otherCallFulfilled;
  }
  if (typeof onRejected === 'function') {
    this.onRejected = onRejected;
    this.callRejected = this.otherCallRejected;
  }
}
QueueItem.prototype.callFulfilled = function (value) {
  handlers.resolve(this.promise, value);
};
QueueItem.prototype.otherCallFulfilled = function (value) {
  unwrap(this.promise, this.onFulfilled, value);
};
QueueItem.prototype.callRejected = function (value) {
  handlers.reject(this.promise, value);
};
QueueItem.prototype.otherCallRejected = function (value) {
  unwrap(this.promise, this.onRejected, value);
};

function unwrap(promise, func, value) {
  immediate(function () {
    var returnValue;
    try {
      returnValue = func(value);
    } catch (e) {
      return handlers.reject(promise, e);
    }
    if (returnValue === promise) {
      handlers.reject(promise, new TypeError('Cannot resolve promise with itself'));
    } else {
      handlers.resolve(promise, returnValue);
    }
  });
}

handlers.resolve = function (self, value) {
  var result = tryCatch(getThen, value);
  if (result.status === 'error') {
    return handlers.reject(self, result.value);
  }
  var thenable = result.value;

  if (thenable) {
    safelyResolveThenable(self, thenable);
  } else {
    self.state = FULFILLED;
    self.outcome = value;
    var i = -1;
    var len = self.queue.length;
    while (++i < len) {
      self.queue[i].callFulfilled(value);
    }
  }
  return self;
};
handlers.reject = function (self, error) {
  self.state = REJECTED;
  self.outcome = error;
  var i = -1;
  var len = self.queue.length;
  while (++i < len) {
    self.queue[i].callRejected(error);
  }
  return self;
};

function getThen(obj) {
  // Make sure we only access the accessor once as required by the spec
  var then = obj && obj.then;
  if (obj && (typeof obj === 'object' || typeof obj === 'function') && typeof then === 'function') {
    return function appyThen() {
      then.apply(obj, arguments);
    };
  }
}

function safelyResolveThenable(self, thenable) {
  // Either fulfill, reject or reject with error
  var called = false;
  function onError(value) {
    if (called) {
      return;
    }
    called = true;
    handlers.reject(self, value);
  }

  function onSuccess(value) {
    if (called) {
      return;
    }
    called = true;
    handlers.resolve(self, value);
  }

  function tryToUnwrap() {
    thenable(onSuccess, onError);
  }

  var result = tryCatch(tryToUnwrap);
  if (result.status === 'error') {
    onError(result.value);
  }
}

function tryCatch(func, value) {
  var out = {};
  try {
    out.value = func(value);
    out.status = 'success';
  } catch (e) {
    out.status = 'error';
    out.value = e;
  }
  return out;
}

Promise.resolve = resolve;
function resolve(value) {
  if (value instanceof this) {
    return value;
  }
  return handlers.resolve(new this(INTERNAL), value);
}

Promise.reject = reject;
function reject(reason) {
  var promise = new this(INTERNAL);
  return handlers.reject(promise, reason);
}

Promise.all = all;
function all(iterable) {
  var self = this;
  if (Object.prototype.toString.call(iterable) !== '[object Array]') {
    return this.reject(new TypeError('must be an array'));
  }

  var len = iterable.length;
  var called = false;
  if (!len) {
    return this.resolve([]);
  }

  var values = new Array(len);
  var resolved = 0;
  var i = -1;
  var promise = new this(INTERNAL);

  while (++i < len) {
    allResolver(iterable[i], i);
  }
  return promise;
  function allResolver(value, i) {
    self.resolve(value).then(resolveFromAll, function (error) {
      if (!called) {
        called = true;
        handlers.reject(promise, error);
      }
    });
    function resolveFromAll(outValue) {
      values[i] = outValue;
      if (++resolved === len && !called) {
        called = true;
        handlers.resolve(promise, values);
      }
    }
  }
}

Promise.race = race;
function race(iterable) {
  var self = this;
  if (Object.prototype.toString.call(iterable) !== '[object Array]') {
    return this.reject(new TypeError('must be an array'));
  }

  var len = iterable.length;
  var called = false;
  if (!len) {
    return this.resolve([]);
  }

  var i = -1;
  var promise = new this(INTERNAL);

  while (++i < len) {
    resolver(iterable[i]);
  }
  return promise;
  function resolver(value) {
    self.resolve(value).then(function (response) {
      if (!called) {
        called = true;
        handlers.resolve(promise, response);
      }
    }, function (error) {
      if (!called) {
        called = true;
        handlers.reject(promise, error);
      }
    });
  }
}

},{"1":1}],3:[function(_dereq_,module,exports){
(function (global){
'use strict';
if (typeof global.Promise !== 'function') {
  global.Promise = _dereq_(2);
}

}).call(this,typeof __webpack_require__.g !== "undefined" ? __webpack_require__.g : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"2":2}],4:[function(_dereq_,module,exports){
'use strict';

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function getIDB() {
    /* global indexedDB,webkitIndexedDB,mozIndexedDB,OIndexedDB,msIndexedDB */
    try {
        if (typeof indexedDB !== 'undefined') {
            return indexedDB;
        }
        if (typeof webkitIndexedDB !== 'undefined') {
            return webkitIndexedDB;
        }
        if (typeof mozIndexedDB !== 'undefined') {
            return mozIndexedDB;
        }
        if (typeof OIndexedDB !== 'undefined') {
            return OIndexedDB;
        }
        if (typeof msIndexedDB !== 'undefined') {
            return msIndexedDB;
        }
    } catch (e) {
        return;
    }
}

var idb = getIDB();

function isIndexedDBValid() {
    try {
        // Initialize IndexedDB; fall back to vendor-prefixed versions
        // if needed.
        if (!idb || !idb.open) {
            return false;
        }
        // We mimic PouchDB here;
        //
        // We test for openDatabase because IE Mobile identifies itself
        // as Safari. Oh the lulz...
        var isSafari = typeof openDatabase !== 'undefined' && /(Safari|iPhone|iPad|iPod)/.test(navigator.userAgent) && !/Chrome/.test(navigator.userAgent) && !/BlackBerry/.test(navigator.platform);

        var hasFetch = typeof fetch === 'function' && fetch.toString().indexOf('[native code') !== -1;

        // Safari <10.1 does not meet our requirements for IDB support
        // (see: https://github.com/pouchdb/pouchdb/issues/5572).
        // Safari 10.1 shipped with fetch, we can use that to detect it.
        // Note: this creates issues with `window.fetch` polyfills and
        // overrides; see:
        // https://github.com/localForage/localForage/issues/856
        return (!isSafari || hasFetch) && typeof indexedDB !== 'undefined' &&
        // some outdated implementations of IDB that appear on Samsung
        // and HTC Android devices <4.4 are missing IDBKeyRange
        // See: https://github.com/mozilla/localForage/issues/128
        // See: https://github.com/mozilla/localForage/issues/272
        typeof IDBKeyRange !== 'undefined';
    } catch (e) {
        return false;
    }
}

// Abstracts constructing a Blob object, so it also works in older
// browsers that don't support the native Blob constructor. (i.e.
// old QtWebKit versions, at least).
// Abstracts constructing a Blob object, so it also works in older
// browsers that don't support the native Blob constructor. (i.e.
// old QtWebKit versions, at least).
function createBlob(parts, properties) {
    /* global BlobBuilder,MSBlobBuilder,MozBlobBuilder,WebKitBlobBuilder */
    parts = parts || [];
    properties = properties || {};
    try {
        return new Blob(parts, properties);
    } catch (e) {
        if (e.name !== 'TypeError') {
            throw e;
        }
        var Builder = typeof BlobBuilder !== 'undefined' ? BlobBuilder : typeof MSBlobBuilder !== 'undefined' ? MSBlobBuilder : typeof MozBlobBuilder !== 'undefined' ? MozBlobBuilder : WebKitBlobBuilder;
        var builder = new Builder();
        for (var i = 0; i < parts.length; i += 1) {
            builder.append(parts[i]);
        }
        return builder.getBlob(properties.type);
    }
}

// This is CommonJS because lie is an external dependency, so Rollup
// can just ignore it.
if (typeof Promise === 'undefined') {
    // In the "nopromises" build this will just throw if you don't have
    // a global promise object, but it would throw anyway later.
    _dereq_(3);
}
var Promise$1 = Promise;

function executeCallback(promise, callback) {
    if (callback) {
        promise.then(function (result) {
            callback(null, result);
        }, function (error) {
            callback(error);
        });
    }
}

function executeTwoCallbacks(promise, callback, errorCallback) {
    if (typeof callback === 'function') {
        promise.then(callback);
    }

    if (typeof errorCallback === 'function') {
        promise["catch"](errorCallback);
    }
}

function normalizeKey(key) {
    // Cast the key to a string, as that's all we can set as a key.
    if (typeof key !== 'string') {
        console.warn(key + ' used as a key, but it is not a string.');
        key = String(key);
    }

    return key;
}

function getCallback() {
    if (arguments.length && typeof arguments[arguments.length - 1] === 'function') {
        return arguments[arguments.length - 1];
    }
}

// Some code originally from async_storage.js in
// [Gaia](https://github.com/mozilla-b2g/gaia).

var DETECT_BLOB_SUPPORT_STORE = 'local-forage-detect-blob-support';
var supportsBlobs = void 0;
var dbContexts = {};
var toString = Object.prototype.toString;

// Transaction Modes
var READ_ONLY = 'readonly';
var READ_WRITE = 'readwrite';

// Transform a binary string to an array buffer, because otherwise
// weird stuff happens when you try to work with the binary string directly.
// It is known.
// From http://stackoverflow.com/questions/14967647/ (continues on next line)
// encode-decode-image-with-base64-breaks-image (2013-04-21)
function _binStringToArrayBuffer(bin) {
    var length = bin.length;
    var buf = new ArrayBuffer(length);
    var arr = new Uint8Array(buf);
    for (var i = 0; i < length; i++) {
        arr[i] = bin.charCodeAt(i);
    }
    return buf;
}

//
// Blobs are not supported in all versions of IndexedDB, notably
// Chrome <37 and Android <5. In those versions, storing a blob will throw.
//
// Various other blob bugs exist in Chrome v37-42 (inclusive).
// Detecting them is expensive and confusing to users, and Chrome 37-42
// is at very low usage worldwide, so we do a hacky userAgent check instead.
//
// content-type bug: https://code.google.com/p/chromium/issues/detail?id=408120
// 404 bug: https://code.google.com/p/chromium/issues/detail?id=447916
// FileReader bug: https://code.google.com/p/chromium/issues/detail?id=447836
//
// Code borrowed from PouchDB. See:
// https://github.com/pouchdb/pouchdb/blob/master/packages/node_modules/pouchdb-adapter-idb/src/blobSupport.js
//
function _checkBlobSupportWithoutCaching(idb) {
    return new Promise$1(function (resolve) {
        var txn = idb.transaction(DETECT_BLOB_SUPPORT_STORE, READ_WRITE);
        var blob = createBlob(['']);
        txn.objectStore(DETECT_BLOB_SUPPORT_STORE).put(blob, 'key');

        txn.onabort = function (e) {
            // If the transaction aborts now its due to not being able to
            // write to the database, likely due to the disk being full
            e.preventDefault();
            e.stopPropagation();
            resolve(false);
        };

        txn.oncomplete = function () {
            var matchedChrome = navigator.userAgent.match(/Chrome\/(\d+)/);
            var matchedEdge = navigator.userAgent.match(/Edge\//);
            // MS Edge pretends to be Chrome 42:
            // https://msdn.microsoft.com/en-us/library/hh869301%28v=vs.85%29.aspx
            resolve(matchedEdge || !matchedChrome || parseInt(matchedChrome[1], 10) >= 43);
        };
    })["catch"](function () {
        return false; // error, so assume unsupported
    });
}

function _checkBlobSupport(idb) {
    if (typeof supportsBlobs === 'boolean') {
        return Promise$1.resolve(supportsBlobs);
    }
    return _checkBlobSupportWithoutCaching(idb).then(function (value) {
        supportsBlobs = value;
        return supportsBlobs;
    });
}

function _deferReadiness(dbInfo) {
    var dbContext = dbContexts[dbInfo.name];

    // Create a deferred object representing the current database operation.
    var deferredOperation = {};

    deferredOperation.promise = new Promise$1(function (resolve, reject) {
        deferredOperation.resolve = resolve;
        deferredOperation.reject = reject;
    });

    // Enqueue the deferred operation.
    dbContext.deferredOperations.push(deferredOperation);

    // Chain its promise to the database readiness.
    if (!dbContext.dbReady) {
        dbContext.dbReady = deferredOperation.promise;
    } else {
        dbContext.dbReady = dbContext.dbReady.then(function () {
            return deferredOperation.promise;
        });
    }
}

function _advanceReadiness(dbInfo) {
    var dbContext = dbContexts[dbInfo.name];

    // Dequeue a deferred operation.
    var deferredOperation = dbContext.deferredOperations.pop();

    // Resolve its promise (which is part of the database readiness
    // chain of promises).
    if (deferredOperation) {
        deferredOperation.resolve();
        return deferredOperation.promise;
    }
}

function _rejectReadiness(dbInfo, err) {
    var dbContext = dbContexts[dbInfo.name];

    // Dequeue a deferred operation.
    var deferredOperation = dbContext.deferredOperations.pop();

    // Reject its promise (which is part of the database readiness
    // chain of promises).
    if (deferredOperation) {
        deferredOperation.reject(err);
        return deferredOperation.promise;
    }
}

function _getConnection(dbInfo, upgradeNeeded) {
    return new Promise$1(function (resolve, reject) {
        dbContexts[dbInfo.name] = dbContexts[dbInfo.name] || createDbContext();

        if (dbInfo.db) {
            if (upgradeNeeded) {
                _deferReadiness(dbInfo);
                dbInfo.db.close();
            } else {
                return resolve(dbInfo.db);
            }
        }

        var dbArgs = [dbInfo.name];

        if (upgradeNeeded) {
            dbArgs.push(dbInfo.version);
        }

        var openreq = idb.open.apply(idb, dbArgs);

        if (upgradeNeeded) {
            openreq.onupgradeneeded = function (e) {
                var db = openreq.result;
                try {
                    db.createObjectStore(dbInfo.storeName);
                    if (e.oldVersion <= 1) {
                        // Added when support for blob shims was added
                        db.createObjectStore(DETECT_BLOB_SUPPORT_STORE);
                    }
                } catch (ex) {
                    if (ex.name === 'ConstraintError') {
                        console.warn('The database "' + dbInfo.name + '"' + ' has been upgraded from version ' + e.oldVersion + ' to version ' + e.newVersion + ', but the storage "' + dbInfo.storeName + '" already exists.');
                    } else {
                        throw ex;
                    }
                }
            };
        }

        openreq.onerror = function (e) {
            e.preventDefault();
            reject(openreq.error);
        };

        openreq.onsuccess = function () {
            resolve(openreq.result);
            _advanceReadiness(dbInfo);
        };
    });
}

function _getOriginalConnection(dbInfo) {
    return _getConnection(dbInfo, false);
}

function _getUpgradedConnection(dbInfo) {
    return _getConnection(dbInfo, true);
}

function _isUpgradeNeeded(dbInfo, defaultVersion) {
    if (!dbInfo.db) {
        return true;
    }

    var isNewStore = !dbInfo.db.objectStoreNames.contains(dbInfo.storeName);
    var isDowngrade = dbInfo.version < dbInfo.db.version;
    var isUpgrade = dbInfo.version > dbInfo.db.version;

    if (isDowngrade) {
        // If the version is not the default one
        // then warn for impossible downgrade.
        if (dbInfo.version !== defaultVersion) {
            console.warn('The database "' + dbInfo.name + '"' + " can't be downgraded from version " + dbInfo.db.version + ' to version ' + dbInfo.version + '.');
        }
        // Align the versions to prevent errors.
        dbInfo.version = dbInfo.db.version;
    }

    if (isUpgrade || isNewStore) {
        // If the store is new then increment the version (if needed).
        // This will trigger an "upgradeneeded" event which is required
        // for creating a store.
        if (isNewStore) {
            var incVersion = dbInfo.db.version + 1;
            if (incVersion > dbInfo.version) {
                dbInfo.version = incVersion;
            }
        }

        return true;
    }

    return false;
}

// encode a blob for indexeddb engines that don't support blobs
function _encodeBlob(blob) {
    return new Promise$1(function (resolve, reject) {
        var reader = new FileReader();
        reader.onerror = reject;
        reader.onloadend = function (e) {
            var base64 = btoa(e.target.result || '');
            resolve({
                __local_forage_encoded_blob: true,
                data: base64,
                type: blob.type
            });
        };
        reader.readAsBinaryString(blob);
    });
}

// decode an encoded blob
function _decodeBlob(encodedBlob) {
    var arrayBuff = _binStringToArrayBuffer(atob(encodedBlob.data));
    return createBlob([arrayBuff], { type: encodedBlob.type });
}

// is this one of our fancy encoded blobs?
function _isEncodedBlob(value) {
    return value && value.__local_forage_encoded_blob;
}

// Specialize the default `ready()` function by making it dependent
// on the current database operations. Thus, the driver will be actually
// ready when it's been initialized (default) *and* there are no pending
// operations on the database (initiated by some other instances).
function _fullyReady(callback) {
    var self = this;

    var promise = self._initReady().then(function () {
        var dbContext = dbContexts[self._dbInfo.name];

        if (dbContext && dbContext.dbReady) {
            return dbContext.dbReady;
        }
    });

    executeTwoCallbacks(promise, callback, callback);
    return promise;
}

// Try to establish a new db connection to replace the
// current one which is broken (i.e. experiencing
// InvalidStateError while creating a transaction).
function _tryReconnect(dbInfo) {
    _deferReadiness(dbInfo);

    var dbContext = dbContexts[dbInfo.name];
    var forages = dbContext.forages;

    for (var i = 0; i < forages.length; i++) {
        var forage = forages[i];
        if (forage._dbInfo.db) {
            forage._dbInfo.db.close();
            forage._dbInfo.db = null;
        }
    }
    dbInfo.db = null;

    return _getOriginalConnection(dbInfo).then(function (db) {
        dbInfo.db = db;
        if (_isUpgradeNeeded(dbInfo)) {
            // Reopen the database for upgrading.
            return _getUpgradedConnection(dbInfo);
        }
        return db;
    }).then(function (db) {
        // store the latest db reference
        // in case the db was upgraded
        dbInfo.db = dbContext.db = db;
        for (var i = 0; i < forages.length; i++) {
            forages[i]._dbInfo.db = db;
        }
    })["catch"](function (err) {
        _rejectReadiness(dbInfo, err);
        throw err;
    });
}

// FF doesn't like Promises (micro-tasks) and IDDB store operations,
// so we have to do it with callbacks
function createTransaction(dbInfo, mode, callback, retries) {
    if (retries === undefined) {
        retries = 1;
    }

    try {
        var tx = dbInfo.db.transaction(dbInfo.storeName, mode);
        callback(null, tx);
    } catch (err) {
        if (retries > 0 && (!dbInfo.db || err.name === 'InvalidStateError' || err.name === 'NotFoundError')) {
            return Promise$1.resolve().then(function () {
                if (!dbInfo.db || err.name === 'NotFoundError' && !dbInfo.db.objectStoreNames.contains(dbInfo.storeName) && dbInfo.version <= dbInfo.db.version) {
                    // increase the db version, to create the new ObjectStore
                    if (dbInfo.db) {
                        dbInfo.version = dbInfo.db.version + 1;
                    }
                    // Reopen the database for upgrading.
                    return _getUpgradedConnection(dbInfo);
                }
            }).then(function () {
                return _tryReconnect(dbInfo).then(function () {
                    createTransaction(dbInfo, mode, callback, retries - 1);
                });
            })["catch"](callback);
        }

        callback(err);
    }
}

function createDbContext() {
    return {
        // Running localForages sharing a database.
        forages: [],
        // Shared database.
        db: null,
        // Database readiness (promise).
        dbReady: null,
        // Deferred operations on the database.
        deferredOperations: []
    };
}

// Open the IndexedDB database (automatically creates one if one didn't
// previously exist), using any options set in the config.
function _initStorage(options) {
    var self = this;
    var dbInfo = {
        db: null
    };

    if (options) {
        for (var i in options) {
            dbInfo[i] = options[i];
        }
    }

    // Get the current context of the database;
    var dbContext = dbContexts[dbInfo.name];

    // ...or create a new context.
    if (!dbContext) {
        dbContext = createDbContext();
        // Register the new context in the global container.
        dbContexts[dbInfo.name] = dbContext;
    }

    // Register itself as a running localForage in the current context.
    dbContext.forages.push(self);

    // Replace the default `ready()` function with the specialized one.
    if (!self._initReady) {
        self._initReady = self.ready;
        self.ready = _fullyReady;
    }

    // Create an array of initialization states of the related localForages.
    var initPromises = [];

    function ignoreErrors() {
        // Don't handle errors here,
        // just makes sure related localForages aren't pending.
        return Promise$1.resolve();
    }

    for (var j = 0; j < dbContext.forages.length; j++) {
        var forage = dbContext.forages[j];
        if (forage !== self) {
            // Don't wait for itself...
            initPromises.push(forage._initReady()["catch"](ignoreErrors));
        }
    }

    // Take a snapshot of the related localForages.
    var forages = dbContext.forages.slice(0);

    // Initialize the connection process only when
    // all the related localForages aren't pending.
    return Promise$1.all(initPromises).then(function () {
        dbInfo.db = dbContext.db;
        // Get the connection or open a new one without upgrade.
        return _getOriginalConnection(dbInfo);
    }).then(function (db) {
        dbInfo.db = db;
        if (_isUpgradeNeeded(dbInfo, self._defaultConfig.version)) {
            // Reopen the database for upgrading.
            return _getUpgradedConnection(dbInfo);
        }
        return db;
    }).then(function (db) {
        dbInfo.db = dbContext.db = db;
        self._dbInfo = dbInfo;
        // Share the final connection amongst related localForages.
        for (var k = 0; k < forages.length; k++) {
            var forage = forages[k];
            if (forage !== self) {
                // Self is already up-to-date.
                forage._dbInfo.db = dbInfo.db;
                forage._dbInfo.version = dbInfo.version;
            }
        }
    });
}

function getItem(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_ONLY, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var req = store.get(key);

                    req.onsuccess = function () {
                        var value = req.result;
                        if (value === undefined) {
                            value = null;
                        }
                        if (_isEncodedBlob(value)) {
                            value = _decodeBlob(value);
                        }
                        resolve(value);
                    };

                    req.onerror = function () {
                        reject(req.error);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

// Iterate over all items stored in database.
function iterate(iterator, callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_ONLY, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var req = store.openCursor();
                    var iterationNumber = 1;

                    req.onsuccess = function () {
                        var cursor = req.result;

                        if (cursor) {
                            var value = cursor.value;
                            if (_isEncodedBlob(value)) {
                                value = _decodeBlob(value);
                            }
                            var result = iterator(value, cursor.key, iterationNumber++);

                            // when the iterator callback returns any
                            // (non-`undefined`) value, then we stop
                            // the iteration immediately
                            if (result !== void 0) {
                                resolve(result);
                            } else {
                                cursor["continue"]();
                            }
                        } else {
                            resolve();
                        }
                    };

                    req.onerror = function () {
                        reject(req.error);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);

    return promise;
}

function setItem(key, value, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        var dbInfo;
        self.ready().then(function () {
            dbInfo = self._dbInfo;
            if (toString.call(value) === '[object Blob]') {
                return _checkBlobSupport(dbInfo.db).then(function (blobSupport) {
                    if (blobSupport) {
                        return value;
                    }
                    return _encodeBlob(value);
                });
            }
            return value;
        }).then(function (value) {
            createTransaction(self._dbInfo, READ_WRITE, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);

                    // The reason we don't _save_ null is because IE 10 does
                    // not support saving the `null` type in IndexedDB. How
                    // ironic, given the bug below!
                    // See: https://github.com/mozilla/localForage/issues/161
                    if (value === null) {
                        value = undefined;
                    }

                    var req = store.put(value, key);

                    transaction.oncomplete = function () {
                        // Cast to undefined so the value passed to
                        // callback/promise is the same as what one would get out
                        // of `getItem()` later. This leads to some weirdness
                        // (setItem('foo', undefined) will return `null`), but
                        // it's not my fault localStorage is our baseline and that
                        // it's weird.
                        if (value === undefined) {
                            value = null;
                        }

                        resolve(value);
                    };
                    transaction.onabort = transaction.onerror = function () {
                        var err = req.error ? req.error : req.transaction.error;
                        reject(err);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function removeItem(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_WRITE, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    // We use a Grunt task to make this safe for IE and some
                    // versions of Android (including those used by Cordova).
                    // Normally IE won't like `.delete()` and will insist on
                    // using `['delete']()`, but we have a build step that
                    // fixes this for us now.
                    var req = store["delete"](key);
                    transaction.oncomplete = function () {
                        resolve();
                    };

                    transaction.onerror = function () {
                        reject(req.error);
                    };

                    // The request will be also be aborted if we've exceeded our storage
                    // space.
                    transaction.onabort = function () {
                        var err = req.error ? req.error : req.transaction.error;
                        reject(err);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function clear(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_WRITE, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var req = store.clear();

                    transaction.oncomplete = function () {
                        resolve();
                    };

                    transaction.onabort = transaction.onerror = function () {
                        var err = req.error ? req.error : req.transaction.error;
                        reject(err);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function length(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_ONLY, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var req = store.count();

                    req.onsuccess = function () {
                        resolve(req.result);
                    };

                    req.onerror = function () {
                        reject(req.error);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function key(n, callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        if (n < 0) {
            resolve(null);

            return;
        }

        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_ONLY, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var advanced = false;
                    var req = store.openKeyCursor();

                    req.onsuccess = function () {
                        var cursor = req.result;
                        if (!cursor) {
                            // this means there weren't enough keys
                            resolve(null);

                            return;
                        }

                        if (n === 0) {
                            // We have the first key, return it if that's what they
                            // wanted.
                            resolve(cursor.key);
                        } else {
                            if (!advanced) {
                                // Otherwise, ask the cursor to skip ahead n
                                // records.
                                advanced = true;
                                cursor.advance(n);
                            } else {
                                // When we get here, we've got the nth key.
                                resolve(cursor.key);
                            }
                        }
                    };

                    req.onerror = function () {
                        reject(req.error);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function keys(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            createTransaction(self._dbInfo, READ_ONLY, function (err, transaction) {
                if (err) {
                    return reject(err);
                }

                try {
                    var store = transaction.objectStore(self._dbInfo.storeName);
                    var req = store.openKeyCursor();
                    var keys = [];

                    req.onsuccess = function () {
                        var cursor = req.result;

                        if (!cursor) {
                            resolve(keys);
                            return;
                        }

                        keys.push(cursor.key);
                        cursor["continue"]();
                    };

                    req.onerror = function () {
                        reject(req.error);
                    };
                } catch (e) {
                    reject(e);
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function dropInstance(options, callback) {
    callback = getCallback.apply(this, arguments);

    var currentConfig = this.config();
    options = typeof options !== 'function' && options || {};
    if (!options.name) {
        options.name = options.name || currentConfig.name;
        options.storeName = options.storeName || currentConfig.storeName;
    }

    var self = this;
    var promise;
    if (!options.name) {
        promise = Promise$1.reject('Invalid arguments');
    } else {
        var isCurrentDb = options.name === currentConfig.name && self._dbInfo.db;

        var dbPromise = isCurrentDb ? Promise$1.resolve(self._dbInfo.db) : _getOriginalConnection(options).then(function (db) {
            var dbContext = dbContexts[options.name];
            var forages = dbContext.forages;
            dbContext.db = db;
            for (var i = 0; i < forages.length; i++) {
                forages[i]._dbInfo.db = db;
            }
            return db;
        });

        if (!options.storeName) {
            promise = dbPromise.then(function (db) {
                _deferReadiness(options);

                var dbContext = dbContexts[options.name];
                var forages = dbContext.forages;

                db.close();
                for (var i = 0; i < forages.length; i++) {
                    var forage = forages[i];
                    forage._dbInfo.db = null;
                }

                var dropDBPromise = new Promise$1(function (resolve, reject) {
                    var req = idb.deleteDatabase(options.name);

                    req.onerror = req.onblocked = function (err) {
                        var db = req.result;
                        if (db) {
                            db.close();
                        }
                        reject(err);
                    };

                    req.onsuccess = function () {
                        var db = req.result;
                        if (db) {
                            db.close();
                        }
                        resolve(db);
                    };
                });

                return dropDBPromise.then(function (db) {
                    dbContext.db = db;
                    for (var i = 0; i < forages.length; i++) {
                        var _forage = forages[i];
                        _advanceReadiness(_forage._dbInfo);
                    }
                })["catch"](function (err) {
                    (_rejectReadiness(options, err) || Promise$1.resolve())["catch"](function () {});
                    throw err;
                });
            });
        } else {
            promise = dbPromise.then(function (db) {
                if (!db.objectStoreNames.contains(options.storeName)) {
                    return;
                }

                var newVersion = db.version + 1;

                _deferReadiness(options);

                var dbContext = dbContexts[options.name];
                var forages = dbContext.forages;

                db.close();
                for (var i = 0; i < forages.length; i++) {
                    var forage = forages[i];
                    forage._dbInfo.db = null;
                    forage._dbInfo.version = newVersion;
                }

                var dropObjectPromise = new Promise$1(function (resolve, reject) {
                    var req = idb.open(options.name, newVersion);

                    req.onerror = function (err) {
                        var db = req.result;
                        db.close();
                        reject(err);
                    };

                    req.onupgradeneeded = function () {
                        var db = req.result;
                        db.deleteObjectStore(options.storeName);
                    };

                    req.onsuccess = function () {
                        var db = req.result;
                        db.close();
                        resolve(db);
                    };
                });

                return dropObjectPromise.then(function (db) {
                    dbContext.db = db;
                    for (var j = 0; j < forages.length; j++) {
                        var _forage2 = forages[j];
                        _forage2._dbInfo.db = db;
                        _advanceReadiness(_forage2._dbInfo);
                    }
                })["catch"](function (err) {
                    (_rejectReadiness(options, err) || Promise$1.resolve())["catch"](function () {});
                    throw err;
                });
            });
        }
    }

    executeCallback(promise, callback);
    return promise;
}

var asyncStorage = {
    _driver: 'asyncStorage',
    _initStorage: _initStorage,
    _support: isIndexedDBValid(),
    iterate: iterate,
    getItem: getItem,
    setItem: setItem,
    removeItem: removeItem,
    clear: clear,
    length: length,
    key: key,
    keys: keys,
    dropInstance: dropInstance
};

function isWebSQLValid() {
    return typeof openDatabase === 'function';
}

// Sadly, the best way to save binary data in WebSQL/localStorage is serializing
// it to Base64, so this is how we store it to prevent very strange errors with less
// verbose ways of binary <-> string data storage.
var BASE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

var BLOB_TYPE_PREFIX = '~~local_forage_type~';
var BLOB_TYPE_PREFIX_REGEX = /^~~local_forage_type~([^~]+)~/;

var SERIALIZED_MARKER = '__lfsc__:';
var SERIALIZED_MARKER_LENGTH = SERIALIZED_MARKER.length;

// OMG the serializations!
var TYPE_ARRAYBUFFER = 'arbf';
var TYPE_BLOB = 'blob';
var TYPE_INT8ARRAY = 'si08';
var TYPE_UINT8ARRAY = 'ui08';
var TYPE_UINT8CLAMPEDARRAY = 'uic8';
var TYPE_INT16ARRAY = 'si16';
var TYPE_INT32ARRAY = 'si32';
var TYPE_UINT16ARRAY = 'ur16';
var TYPE_UINT32ARRAY = 'ui32';
var TYPE_FLOAT32ARRAY = 'fl32';
var TYPE_FLOAT64ARRAY = 'fl64';
var TYPE_SERIALIZED_MARKER_LENGTH = SERIALIZED_MARKER_LENGTH + TYPE_ARRAYBUFFER.length;

var toString$1 = Object.prototype.toString;

function stringToBuffer(serializedString) {
    // Fill the string into a ArrayBuffer.
    var bufferLength = serializedString.length * 0.75;
    var len = serializedString.length;
    var i;
    var p = 0;
    var encoded1, encoded2, encoded3, encoded4;

    if (serializedString[serializedString.length - 1] === '=') {
        bufferLength--;
        if (serializedString[serializedString.length - 2] === '=') {
            bufferLength--;
        }
    }

    var buffer = new ArrayBuffer(bufferLength);
    var bytes = new Uint8Array(buffer);

    for (i = 0; i < len; i += 4) {
        encoded1 = BASE_CHARS.indexOf(serializedString[i]);
        encoded2 = BASE_CHARS.indexOf(serializedString[i + 1]);
        encoded3 = BASE_CHARS.indexOf(serializedString[i + 2]);
        encoded4 = BASE_CHARS.indexOf(serializedString[i + 3]);

        /*jslint bitwise: true */
        bytes[p++] = encoded1 << 2 | encoded2 >> 4;
        bytes[p++] = (encoded2 & 15) << 4 | encoded3 >> 2;
        bytes[p++] = (encoded3 & 3) << 6 | encoded4 & 63;
    }
    return buffer;
}

// Converts a buffer to a string to store, serialized, in the backend
// storage library.
function bufferToString(buffer) {
    // base64-arraybuffer
    var bytes = new Uint8Array(buffer);
    var base64String = '';
    var i;

    for (i = 0; i < bytes.length; i += 3) {
        /*jslint bitwise: true */
        base64String += BASE_CHARS[bytes[i] >> 2];
        base64String += BASE_CHARS[(bytes[i] & 3) << 4 | bytes[i + 1] >> 4];
        base64String += BASE_CHARS[(bytes[i + 1] & 15) << 2 | bytes[i + 2] >> 6];
        base64String += BASE_CHARS[bytes[i + 2] & 63];
    }

    if (bytes.length % 3 === 2) {
        base64String = base64String.substring(0, base64String.length - 1) + '=';
    } else if (bytes.length % 3 === 1) {
        base64String = base64String.substring(0, base64String.length - 2) + '==';
    }

    return base64String;
}

// Serialize a value, afterwards executing a callback (which usually
// instructs the `setItem()` callback/promise to be executed). This is how
// we store binary data with localStorage.
function serialize(value, callback) {
    var valueType = '';
    if (value) {
        valueType = toString$1.call(value);
    }

    // Cannot use `value instanceof ArrayBuffer` or such here, as these
    // checks fail when running the tests using casper.js...
    //
    // TODO: See why those tests fail and use a better solution.
    if (value && (valueType === '[object ArrayBuffer]' || value.buffer && toString$1.call(value.buffer) === '[object ArrayBuffer]')) {
        // Convert binary arrays to a string and prefix the string with
        // a special marker.
        var buffer;
        var marker = SERIALIZED_MARKER;

        if (value instanceof ArrayBuffer) {
            buffer = value;
            marker += TYPE_ARRAYBUFFER;
        } else {
            buffer = value.buffer;

            if (valueType === '[object Int8Array]') {
                marker += TYPE_INT8ARRAY;
            } else if (valueType === '[object Uint8Array]') {
                marker += TYPE_UINT8ARRAY;
            } else if (valueType === '[object Uint8ClampedArray]') {
                marker += TYPE_UINT8CLAMPEDARRAY;
            } else if (valueType === '[object Int16Array]') {
                marker += TYPE_INT16ARRAY;
            } else if (valueType === '[object Uint16Array]') {
                marker += TYPE_UINT16ARRAY;
            } else if (valueType === '[object Int32Array]') {
                marker += TYPE_INT32ARRAY;
            } else if (valueType === '[object Uint32Array]') {
                marker += TYPE_UINT32ARRAY;
            } else if (valueType === '[object Float32Array]') {
                marker += TYPE_FLOAT32ARRAY;
            } else if (valueType === '[object Float64Array]') {
                marker += TYPE_FLOAT64ARRAY;
            } else {
                callback(new Error('Failed to get type for BinaryArray'));
            }
        }

        callback(marker + bufferToString(buffer));
    } else if (valueType === '[object Blob]') {
        // Conver the blob to a binaryArray and then to a string.
        var fileReader = new FileReader();

        fileReader.onload = function () {
            // Backwards-compatible prefix for the blob type.
            var str = BLOB_TYPE_PREFIX + value.type + '~' + bufferToString(this.result);

            callback(SERIALIZED_MARKER + TYPE_BLOB + str);
        };

        fileReader.readAsArrayBuffer(value);
    } else {
        try {
            callback(JSON.stringify(value));
        } catch (e) {
            console.error("Couldn't convert value into a JSON string: ", value);

            callback(null, e);
        }
    }
}

// Deserialize data we've inserted into a value column/field. We place
// special markers into our strings to mark them as encoded; this isn't
// as nice as a meta field, but it's the only sane thing we can do whilst
// keeping localStorage support intact.
//
// Oftentimes this will just deserialize JSON content, but if we have a
// special marker (SERIALIZED_MARKER, defined above), we will extract
// some kind of arraybuffer/binary data/typed array out of the string.
function deserialize(value) {
    // If we haven't marked this string as being specially serialized (i.e.
    // something other than serialized JSON), we can just return it and be
    // done with it.
    if (value.substring(0, SERIALIZED_MARKER_LENGTH) !== SERIALIZED_MARKER) {
        return JSON.parse(value);
    }

    // The following code deals with deserializing some kind of Blob or
    // TypedArray. First we separate out the type of data we're dealing
    // with from the data itself.
    var serializedString = value.substring(TYPE_SERIALIZED_MARKER_LENGTH);
    var type = value.substring(SERIALIZED_MARKER_LENGTH, TYPE_SERIALIZED_MARKER_LENGTH);

    var blobType;
    // Backwards-compatible blob type serialization strategy.
    // DBs created with older versions of localForage will simply not have the blob type.
    if (type === TYPE_BLOB && BLOB_TYPE_PREFIX_REGEX.test(serializedString)) {
        var matcher = serializedString.match(BLOB_TYPE_PREFIX_REGEX);
        blobType = matcher[1];
        serializedString = serializedString.substring(matcher[0].length);
    }
    var buffer = stringToBuffer(serializedString);

    // Return the right type based on the code/type set during
    // serialization.
    switch (type) {
        case TYPE_ARRAYBUFFER:
            return buffer;
        case TYPE_BLOB:
            return createBlob([buffer], { type: blobType });
        case TYPE_INT8ARRAY:
            return new Int8Array(buffer);
        case TYPE_UINT8ARRAY:
            return new Uint8Array(buffer);
        case TYPE_UINT8CLAMPEDARRAY:
            return new Uint8ClampedArray(buffer);
        case TYPE_INT16ARRAY:
            return new Int16Array(buffer);
        case TYPE_UINT16ARRAY:
            return new Uint16Array(buffer);
        case TYPE_INT32ARRAY:
            return new Int32Array(buffer);
        case TYPE_UINT32ARRAY:
            return new Uint32Array(buffer);
        case TYPE_FLOAT32ARRAY:
            return new Float32Array(buffer);
        case TYPE_FLOAT64ARRAY:
            return new Float64Array(buffer);
        default:
            throw new Error('Unkown type: ' + type);
    }
}

var localforageSerializer = {
    serialize: serialize,
    deserialize: deserialize,
    stringToBuffer: stringToBuffer,
    bufferToString: bufferToString
};

/*
 * Includes code from:
 *
 * base64-arraybuffer
 * https://github.com/niklasvh/base64-arraybuffer
 *
 * Copyright (c) 2012 Niklas von Hertzen
 * Licensed under the MIT license.
 */

function createDbTable(t, dbInfo, callback, errorCallback) {
    t.executeSql('CREATE TABLE IF NOT EXISTS ' + dbInfo.storeName + ' ' + '(id INTEGER PRIMARY KEY, key unique, value)', [], callback, errorCallback);
}

// Open the WebSQL database (automatically creates one if one didn't
// previously exist), using any options set in the config.
function _initStorage$1(options) {
    var self = this;
    var dbInfo = {
        db: null
    };

    if (options) {
        for (var i in options) {
            dbInfo[i] = typeof options[i] !== 'string' ? options[i].toString() : options[i];
        }
    }

    var dbInfoPromise = new Promise$1(function (resolve, reject) {
        // Open the database; the openDatabase API will automatically
        // create it for us if it doesn't exist.
        try {
            dbInfo.db = openDatabase(dbInfo.name, String(dbInfo.version), dbInfo.description, dbInfo.size);
        } catch (e) {
            return reject(e);
        }

        // Create our key/value table if it doesn't exist.
        dbInfo.db.transaction(function (t) {
            createDbTable(t, dbInfo, function () {
                self._dbInfo = dbInfo;
                resolve();
            }, function (t, error) {
                reject(error);
            });
        }, reject);
    });

    dbInfo.serializer = localforageSerializer;
    return dbInfoPromise;
}

function tryExecuteSql(t, dbInfo, sqlStatement, args, callback, errorCallback) {
    t.executeSql(sqlStatement, args, callback, function (t, error) {
        if (error.code === error.SYNTAX_ERR) {
            t.executeSql('SELECT name FROM sqlite_master ' + "WHERE type='table' AND name = ?", [dbInfo.storeName], function (t, results) {
                if (!results.rows.length) {
                    // if the table is missing (was deleted)
                    // re-create it table and retry
                    createDbTable(t, dbInfo, function () {
                        t.executeSql(sqlStatement, args, callback, errorCallback);
                    }, errorCallback);
                } else {
                    errorCallback(t, error);
                }
            }, errorCallback);
        } else {
            errorCallback(t, error);
        }
    }, errorCallback);
}

function getItem$1(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'SELECT * FROM ' + dbInfo.storeName + ' WHERE key = ? LIMIT 1', [key], function (t, results) {
                    var result = results.rows.length ? results.rows.item(0).value : null;

                    // Check to see if this is serialized content we need to
                    // unpack.
                    if (result) {
                        result = dbInfo.serializer.deserialize(result);
                    }

                    resolve(result);
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function iterate$1(iterator, callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;

            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'SELECT * FROM ' + dbInfo.storeName, [], function (t, results) {
                    var rows = results.rows;
                    var length = rows.length;

                    for (var i = 0; i < length; i++) {
                        var item = rows.item(i);
                        var result = item.value;

                        // Check to see if this is serialized content
                        // we need to unpack.
                        if (result) {
                            result = dbInfo.serializer.deserialize(result);
                        }

                        result = iterator(result, item.key, i + 1);

                        // void(0) prevents problems with redefinition
                        // of `undefined`.
                        if (result !== void 0) {
                            resolve(result);
                            return;
                        }
                    }

                    resolve();
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function _setItem(key, value, callback, retriesLeft) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            // The localStorage API doesn't return undefined values in an
            // "expected" way, so undefined is always cast to null in all
            // drivers. See: https://github.com/mozilla/localForage/pull/42
            if (value === undefined) {
                value = null;
            }

            // Save the original value to pass to the callback.
            var originalValue = value;

            var dbInfo = self._dbInfo;
            dbInfo.serializer.serialize(value, function (value, error) {
                if (error) {
                    reject(error);
                } else {
                    dbInfo.db.transaction(function (t) {
                        tryExecuteSql(t, dbInfo, 'INSERT OR REPLACE INTO ' + dbInfo.storeName + ' ' + '(key, value) VALUES (?, ?)', [key, value], function () {
                            resolve(originalValue);
                        }, function (t, error) {
                            reject(error);
                        });
                    }, function (sqlError) {
                        // The transaction failed; check
                        // to see if it's a quota error.
                        if (sqlError.code === sqlError.QUOTA_ERR) {
                            // We reject the callback outright for now, but
                            // it's worth trying to re-run the transaction.
                            // Even if the user accepts the prompt to use
                            // more storage on Safari, this error will
                            // be called.
                            //
                            // Try to re-run the transaction.
                            if (retriesLeft > 0) {
                                resolve(_setItem.apply(self, [key, originalValue, callback, retriesLeft - 1]));
                                return;
                            }
                            reject(sqlError);
                        }
                    });
                }
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function setItem$1(key, value, callback) {
    return _setItem.apply(this, [key, value, callback, 1]);
}

function removeItem$1(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'DELETE FROM ' + dbInfo.storeName + ' WHERE key = ?', [key], function () {
                    resolve();
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

// Deletes every item in the table.
// TODO: Find out if this resets the AUTO_INCREMENT number.
function clear$1(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'DELETE FROM ' + dbInfo.storeName, [], function () {
                    resolve();
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

// Does a simple `COUNT(key)` to get the number of items stored in
// localForage.
function length$1(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                // Ahhh, SQL makes this one soooooo easy.
                tryExecuteSql(t, dbInfo, 'SELECT COUNT(key) as c FROM ' + dbInfo.storeName, [], function (t, results) {
                    var result = results.rows.item(0).c;
                    resolve(result);
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

// Return the key located at key index X; essentially gets the key from a
// `WHERE id = ?`. This is the most efficient way I can think to implement
// this rarely-used (in my experience) part of the API, but it can seem
// inconsistent, because we do `INSERT OR REPLACE INTO` on `setItem()`, so
// the ID of each key will change every time it's updated. Perhaps a stored
// procedure for the `setItem()` SQL would solve this problem?
// TODO: Don't change ID on `setItem()`.
function key$1(n, callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'SELECT key FROM ' + dbInfo.storeName + ' WHERE id = ? LIMIT 1', [n + 1], function (t, results) {
                    var result = results.rows.length ? results.rows.item(0).key : null;
                    resolve(result);
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

function keys$1(callback) {
    var self = this;

    var promise = new Promise$1(function (resolve, reject) {
        self.ready().then(function () {
            var dbInfo = self._dbInfo;
            dbInfo.db.transaction(function (t) {
                tryExecuteSql(t, dbInfo, 'SELECT key FROM ' + dbInfo.storeName, [], function (t, results) {
                    var keys = [];

                    for (var i = 0; i < results.rows.length; i++) {
                        keys.push(results.rows.item(i).key);
                    }

                    resolve(keys);
                }, function (t, error) {
                    reject(error);
                });
            });
        })["catch"](reject);
    });

    executeCallback(promise, callback);
    return promise;
}

// https://www.w3.org/TR/webdatabase/#databases
// > There is no way to enumerate or delete the databases available for an origin from this API.
function getAllStoreNames(db) {
    return new Promise$1(function (resolve, reject) {
        db.transaction(function (t) {
            t.executeSql('SELECT name FROM sqlite_master ' + "WHERE type='table' AND name <> '__WebKitDatabaseInfoTable__'", [], function (t, results) {
                var storeNames = [];

                for (var i = 0; i < results.rows.length; i++) {
                    storeNames.push(results.rows.item(i).name);
                }

                resolve({
                    db: db,
                    storeNames: storeNames
                });
            }, function (t, error) {
                reject(error);
            });
        }, function (sqlError) {
            reject(sqlError);
        });
    });
}

function dropInstance$1(options, callback) {
    callback = getCallback.apply(this, arguments);

    var currentConfig = this.config();
    options = typeof options !== 'function' && options || {};
    if (!options.name) {
        options.name = options.name || currentConfig.name;
        options.storeName = options.storeName || currentConfig.storeName;
    }

    var self = this;
    var promise;
    if (!options.name) {
        promise = Promise$1.reject('Invalid arguments');
    } else {
        promise = new Promise$1(function (resolve) {
            var db;
            if (options.name === currentConfig.name) {
                // use the db reference of the current instance
                db = self._dbInfo.db;
            } else {
                db = openDatabase(options.name, '', '', 0);
            }

            if (!options.storeName) {
                // drop all database tables
                resolve(getAllStoreNames(db));
            } else {
                resolve({
                    db: db,
                    storeNames: [options.storeName]
                });
            }
        }).then(function (operationInfo) {
            return new Promise$1(function (resolve, reject) {
                operationInfo.db.transaction(function (t) {
                    function dropTable(storeName) {
                        return new Promise$1(function (resolve, reject) {
                            t.executeSql('DROP TABLE IF EXISTS ' + storeName, [], function () {
                                resolve();
                            }, function (t, error) {
                                reject(error);
                            });
                        });
                    }

                    var operations = [];
                    for (var i = 0, len = operationInfo.storeNames.length; i < len; i++) {
                        operations.push(dropTable(operationInfo.storeNames[i]));
                    }

                    Promise$1.all(operations).then(function () {
                        resolve();
                    })["catch"](function (e) {
                        reject(e);
                    });
                }, function (sqlError) {
                    reject(sqlError);
                });
            });
        });
    }

    executeCallback(promise, callback);
    return promise;
}

var webSQLStorage = {
    _driver: 'webSQLStorage',
    _initStorage: _initStorage$1,
    _support: isWebSQLValid(),
    iterate: iterate$1,
    getItem: getItem$1,
    setItem: setItem$1,
    removeItem: removeItem$1,
    clear: clear$1,
    length: length$1,
    key: key$1,
    keys: keys$1,
    dropInstance: dropInstance$1
};

function isLocalStorageValid() {
    try {
        return typeof localStorage !== 'undefined' && 'setItem' in localStorage &&
        // in IE8 typeof localStorage.setItem === 'object'
        !!localStorage.setItem;
    } catch (e) {
        return false;
    }
}

function _getKeyPrefix(options, defaultConfig) {
    var keyPrefix = options.name + '/';

    if (options.storeName !== defaultConfig.storeName) {
        keyPrefix += options.storeName + '/';
    }
    return keyPrefix;
}

// Check if localStorage throws when saving an item
function checkIfLocalStorageThrows() {
    var localStorageTestKey = '_localforage_support_test';

    try {
        localStorage.setItem(localStorageTestKey, true);
        localStorage.removeItem(localStorageTestKey);

        return false;
    } catch (e) {
        return true;
    }
}

// Check if localStorage is usable and allows to save an item
// This method checks if localStorage is usable in Safari Private Browsing
// mode, or in any other case where the available quota for localStorage
// is 0 and there wasn't any saved items yet.
function _isLocalStorageUsable() {
    return !checkIfLocalStorageThrows() || localStorage.length > 0;
}

// Config the localStorage backend, using options set in the config.
function _initStorage$2(options) {
    var self = this;
    var dbInfo = {};
    if (options) {
        for (var i in options) {
            dbInfo[i] = options[i];
        }
    }

    dbInfo.keyPrefix = _getKeyPrefix(options, self._defaultConfig);

    if (!_isLocalStorageUsable()) {
        return Promise$1.reject();
    }

    self._dbInfo = dbInfo;
    dbInfo.serializer = localforageSerializer;

    return Promise$1.resolve();
}

// Remove all keys from the datastore, effectively destroying all data in
// the app's key/value store!
function clear$2(callback) {
    var self = this;
    var promise = self.ready().then(function () {
        var keyPrefix = self._dbInfo.keyPrefix;

        for (var i = localStorage.length - 1; i >= 0; i--) {
            var key = localStorage.key(i);

            if (key.indexOf(keyPrefix) === 0) {
                localStorage.removeItem(key);
            }
        }
    });

    executeCallback(promise, callback);
    return promise;
}

// Retrieve an item from the store. Unlike the original async_storage
// library in Gaia, we don't modify return values at all. If a key's value
// is `undefined`, we pass that value to the callback function.
function getItem$2(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = self.ready().then(function () {
        var dbInfo = self._dbInfo;
        var result = localStorage.getItem(dbInfo.keyPrefix + key);

        // If a result was found, parse it from the serialized
        // string into a JS object. If result isn't truthy, the key
        // is likely undefined and we'll pass it straight to the
        // callback.
        if (result) {
            result = dbInfo.serializer.deserialize(result);
        }

        return result;
    });

    executeCallback(promise, callback);
    return promise;
}

// Iterate over all items in the store.
function iterate$2(iterator, callback) {
    var self = this;

    var promise = self.ready().then(function () {
        var dbInfo = self._dbInfo;
        var keyPrefix = dbInfo.keyPrefix;
        var keyPrefixLength = keyPrefix.length;
        var length = localStorage.length;

        // We use a dedicated iterator instead of the `i` variable below
        // so other keys we fetch in localStorage aren't counted in
        // the `iterationNumber` argument passed to the `iterate()`
        // callback.
        //
        // See: github.com/mozilla/localForage/pull/435#discussion_r38061530
        var iterationNumber = 1;

        for (var i = 0; i < length; i++) {
            var key = localStorage.key(i);
            if (key.indexOf(keyPrefix) !== 0) {
                continue;
            }
            var value = localStorage.getItem(key);

            // If a result was found, parse it from the serialized
            // string into a JS object. If result isn't truthy, the
            // key is likely undefined and we'll pass it straight
            // to the iterator.
            if (value) {
                value = dbInfo.serializer.deserialize(value);
            }

            value = iterator(value, key.substring(keyPrefixLength), iterationNumber++);

            if (value !== void 0) {
                return value;
            }
        }
    });

    executeCallback(promise, callback);
    return promise;
}

// Same as localStorage's key() method, except takes a callback.
function key$2(n, callback) {
    var self = this;
    var promise = self.ready().then(function () {
        var dbInfo = self._dbInfo;
        var result;
        try {
            result = localStorage.key(n);
        } catch (error) {
            result = null;
        }

        // Remove the prefix from the key, if a key is found.
        if (result) {
            result = result.substring(dbInfo.keyPrefix.length);
        }

        return result;
    });

    executeCallback(promise, callback);
    return promise;
}

function keys$2(callback) {
    var self = this;
    var promise = self.ready().then(function () {
        var dbInfo = self._dbInfo;
        var length = localStorage.length;
        var keys = [];

        for (var i = 0; i < length; i++) {
            var itemKey = localStorage.key(i);
            if (itemKey.indexOf(dbInfo.keyPrefix) === 0) {
                keys.push(itemKey.substring(dbInfo.keyPrefix.length));
            }
        }

        return keys;
    });

    executeCallback(promise, callback);
    return promise;
}

// Supply the number of keys in the datastore to the callback function.
function length$2(callback) {
    var self = this;
    var promise = self.keys().then(function (keys) {
        return keys.length;
    });

    executeCallback(promise, callback);
    return promise;
}

// Remove an item from the store, nice and simple.
function removeItem$2(key, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = self.ready().then(function () {
        var dbInfo = self._dbInfo;
        localStorage.removeItem(dbInfo.keyPrefix + key);
    });

    executeCallback(promise, callback);
    return promise;
}

// Set a key's value and run an optional callback once the value is set.
// Unlike Gaia's implementation, the callback function is passed the value,
// in case you want to operate on that value only after you're sure it
// saved, or something like that.
function setItem$2(key, value, callback) {
    var self = this;

    key = normalizeKey(key);

    var promise = self.ready().then(function () {
        // Convert undefined values to null.
        // https://github.com/mozilla/localForage/pull/42
        if (value === undefined) {
            value = null;
        }

        // Save the original value to pass to the callback.
        var originalValue = value;

        return new Promise$1(function (resolve, reject) {
            var dbInfo = self._dbInfo;
            dbInfo.serializer.serialize(value, function (value, error) {
                if (error) {
                    reject(error);
                } else {
                    try {
                        localStorage.setItem(dbInfo.keyPrefix + key, value);
                        resolve(originalValue);
                    } catch (e) {
                        // localStorage capacity exceeded.
                        // TODO: Make this a specific error/event.
                        if (e.name === 'QuotaExceededError' || e.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
                            reject(e);
                        }
                        reject(e);
                    }
                }
            });
        });
    });

    executeCallback(promise, callback);
    return promise;
}

function dropInstance$2(options, callback) {
    callback = getCallback.apply(this, arguments);

    options = typeof options !== 'function' && options || {};
    if (!options.name) {
        var currentConfig = this.config();
        options.name = options.name || currentConfig.name;
        options.storeName = options.storeName || currentConfig.storeName;
    }

    var self = this;
    var promise;
    if (!options.name) {
        promise = Promise$1.reject('Invalid arguments');
    } else {
        promise = new Promise$1(function (resolve) {
            if (!options.storeName) {
                resolve(options.name + '/');
            } else {
                resolve(_getKeyPrefix(options, self._defaultConfig));
            }
        }).then(function (keyPrefix) {
            for (var i = localStorage.length - 1; i >= 0; i--) {
                var key = localStorage.key(i);

                if (key.indexOf(keyPrefix) === 0) {
                    localStorage.removeItem(key);
                }
            }
        });
    }

    executeCallback(promise, callback);
    return promise;
}

var localStorageWrapper = {
    _driver: 'localStorageWrapper',
    _initStorage: _initStorage$2,
    _support: isLocalStorageValid(),
    iterate: iterate$2,
    getItem: getItem$2,
    setItem: setItem$2,
    removeItem: removeItem$2,
    clear: clear$2,
    length: length$2,
    key: key$2,
    keys: keys$2,
    dropInstance: dropInstance$2
};

var sameValue = function sameValue(x, y) {
    return x === y || typeof x === 'number' && typeof y === 'number' && isNaN(x) && isNaN(y);
};

var includes = function includes(array, searchElement) {
    var len = array.length;
    var i = 0;
    while (i < len) {
        if (sameValue(array[i], searchElement)) {
            return true;
        }
        i++;
    }

    return false;
};

var isArray = Array.isArray || function (arg) {
    return Object.prototype.toString.call(arg) === '[object Array]';
};

// Drivers are stored here when `defineDriver()` is called.
// They are shared across all instances of localForage.
var DefinedDrivers = {};

var DriverSupport = {};

var DefaultDrivers = {
    INDEXEDDB: asyncStorage,
    WEBSQL: webSQLStorage,
    LOCALSTORAGE: localStorageWrapper
};

var DefaultDriverOrder = [DefaultDrivers.INDEXEDDB._driver, DefaultDrivers.WEBSQL._driver, DefaultDrivers.LOCALSTORAGE._driver];

var OptionalDriverMethods = ['dropInstance'];

var LibraryMethods = ['clear', 'getItem', 'iterate', 'key', 'keys', 'length', 'removeItem', 'setItem'].concat(OptionalDriverMethods);

var DefaultConfig = {
    description: '',
    driver: DefaultDriverOrder.slice(),
    name: 'localforage',
    // Default DB size is _JUST UNDER_ 5MB, as it's the highest size
    // we can use without a prompt.
    size: 4980736,
    storeName: 'keyvaluepairs',
    version: 1.0
};

function callWhenReady(localForageInstance, libraryMethod) {
    localForageInstance[libraryMethod] = function () {
        var _args = arguments;
        return localForageInstance.ready().then(function () {
            return localForageInstance[libraryMethod].apply(localForageInstance, _args);
        });
    };
}

function extend() {
    for (var i = 1; i < arguments.length; i++) {
        var arg = arguments[i];

        if (arg) {
            for (var _key in arg) {
                if (arg.hasOwnProperty(_key)) {
                    if (isArray(arg[_key])) {
                        arguments[0][_key] = arg[_key].slice();
                    } else {
                        arguments[0][_key] = arg[_key];
                    }
                }
            }
        }
    }

    return arguments[0];
}

var LocalForage = function () {
    function LocalForage(options) {
        _classCallCheck(this, LocalForage);

        for (var driverTypeKey in DefaultDrivers) {
            if (DefaultDrivers.hasOwnProperty(driverTypeKey)) {
                var driver = DefaultDrivers[driverTypeKey];
                var driverName = driver._driver;
                this[driverTypeKey] = driverName;

                if (!DefinedDrivers[driverName]) {
                    // we don't need to wait for the promise,
                    // since the default drivers can be defined
                    // in a blocking manner
                    this.defineDriver(driver);
                }
            }
        }

        this._defaultConfig = extend({}, DefaultConfig);
        this._config = extend({}, this._defaultConfig, options);
        this._driverSet = null;
        this._initDriver = null;
        this._ready = false;
        this._dbInfo = null;

        this._wrapLibraryMethodsWithReady();
        this.setDriver(this._config.driver)["catch"](function () {});
    }

    // Set any config values for localForage; can be called anytime before
    // the first API call (e.g. `getItem`, `setItem`).
    // We loop through options so we don't overwrite existing config
    // values.


    LocalForage.prototype.config = function config(options) {
        // If the options argument is an object, we use it to set values.
        // Otherwise, we return either a specified config value or all
        // config values.
        if ((typeof options === 'undefined' ? 'undefined' : _typeof(options)) === 'object') {
            // If localforage is ready and fully initialized, we can't set
            // any new configuration values. Instead, we return an error.
            if (this._ready) {
                return new Error("Can't call config() after localforage " + 'has been used.');
            }

            for (var i in options) {
                if (i === 'storeName') {
                    options[i] = options[i].replace(/\W/g, '_');
                }

                if (i === 'version' && typeof options[i] !== 'number') {
                    return new Error('Database version must be a number.');
                }

                this._config[i] = options[i];
            }

            // after all config options are set and
            // the driver option is used, try setting it
            if ('driver' in options && options.driver) {
                return this.setDriver(this._config.driver);
            }

            return true;
        } else if (typeof options === 'string') {
            return this._config[options];
        } else {
            return this._config;
        }
    };

    // Used to define a custom driver, shared across all instances of
    // localForage.


    LocalForage.prototype.defineDriver = function defineDriver(driverObject, callback, errorCallback) {
        var promise = new Promise$1(function (resolve, reject) {
            try {
                var driverName = driverObject._driver;
                var complianceError = new Error('Custom driver not compliant; see ' + 'https://mozilla.github.io/localForage/#definedriver');

                // A driver name should be defined and not overlap with the
                // library-defined, default drivers.
                if (!driverObject._driver) {
                    reject(complianceError);
                    return;
                }

                var driverMethods = LibraryMethods.concat('_initStorage');
                for (var i = 0, len = driverMethods.length; i < len; i++) {
                    var driverMethodName = driverMethods[i];

                    // when the property is there,
                    // it should be a method even when optional
                    var isRequired = !includes(OptionalDriverMethods, driverMethodName);
                    if ((isRequired || driverObject[driverMethodName]) && typeof driverObject[driverMethodName] !== 'function') {
                        reject(complianceError);
                        return;
                    }
                }

                var configureMissingMethods = function configureMissingMethods() {
                    var methodNotImplementedFactory = function methodNotImplementedFactory(methodName) {
                        return function () {
                            var error = new Error('Method ' + methodName + ' is not implemented by the current driver');
                            var promise = Promise$1.reject(error);
                            executeCallback(promise, arguments[arguments.length - 1]);
                            return promise;
                        };
                    };

                    for (var _i = 0, _len = OptionalDriverMethods.length; _i < _len; _i++) {
                        var optionalDriverMethod = OptionalDriverMethods[_i];
                        if (!driverObject[optionalDriverMethod]) {
                            driverObject[optionalDriverMethod] = methodNotImplementedFactory(optionalDriverMethod);
                        }
                    }
                };

                configureMissingMethods();

                var setDriverSupport = function setDriverSupport(support) {
                    if (DefinedDrivers[driverName]) {
                        console.info('Redefining LocalForage driver: ' + driverName);
                    }
                    DefinedDrivers[driverName] = driverObject;
                    DriverSupport[driverName] = support;
                    // don't use a then, so that we can define
                    // drivers that have simple _support methods
                    // in a blocking manner
                    resolve();
                };

                if ('_support' in driverObject) {
                    if (driverObject._support && typeof driverObject._support === 'function') {
                        driverObject._support().then(setDriverSupport, reject);
                    } else {
                        setDriverSupport(!!driverObject._support);
                    }
                } else {
                    setDriverSupport(true);
                }
            } catch (e) {
                reject(e);
            }
        });

        executeTwoCallbacks(promise, callback, errorCallback);
        return promise;
    };

    LocalForage.prototype.driver = function driver() {
        return this._driver || null;
    };

    LocalForage.prototype.getDriver = function getDriver(driverName, callback, errorCallback) {
        var getDriverPromise = DefinedDrivers[driverName] ? Promise$1.resolve(DefinedDrivers[driverName]) : Promise$1.reject(new Error('Driver not found.'));

        executeTwoCallbacks(getDriverPromise, callback, errorCallback);
        return getDriverPromise;
    };

    LocalForage.prototype.getSerializer = function getSerializer(callback) {
        var serializerPromise = Promise$1.resolve(localforageSerializer);
        executeTwoCallbacks(serializerPromise, callback);
        return serializerPromise;
    };

    LocalForage.prototype.ready = function ready(callback) {
        var self = this;

        var promise = self._driverSet.then(function () {
            if (self._ready === null) {
                self._ready = self._initDriver();
            }

            return self._ready;
        });

        executeTwoCallbacks(promise, callback, callback);
        return promise;
    };

    LocalForage.prototype.setDriver = function setDriver(drivers, callback, errorCallback) {
        var self = this;

        if (!isArray(drivers)) {
            drivers = [drivers];
        }

        var supportedDrivers = this._getSupportedDrivers(drivers);

        function setDriverToConfig() {
            self._config.driver = self.driver();
        }

        function extendSelfWithDriver(driver) {
            self._extend(driver);
            setDriverToConfig();

            self._ready = self._initStorage(self._config);
            return self._ready;
        }

        function initDriver(supportedDrivers) {
            return function () {
                var currentDriverIndex = 0;

                function driverPromiseLoop() {
                    while (currentDriverIndex < supportedDrivers.length) {
                        var driverName = supportedDrivers[currentDriverIndex];
                        currentDriverIndex++;

                        self._dbInfo = null;
                        self._ready = null;

                        return self.getDriver(driverName).then(extendSelfWithDriver)["catch"](driverPromiseLoop);
                    }

                    setDriverToConfig();
                    var error = new Error('No available storage method found.');
                    self._driverSet = Promise$1.reject(error);
                    return self._driverSet;
                }

                return driverPromiseLoop();
            };
        }

        // There might be a driver initialization in progress
        // so wait for it to finish in order to avoid a possible
        // race condition to set _dbInfo
        var oldDriverSetDone = this._driverSet !== null ? this._driverSet["catch"](function () {
            return Promise$1.resolve();
        }) : Promise$1.resolve();

        this._driverSet = oldDriverSetDone.then(function () {
            var driverName = supportedDrivers[0];
            self._dbInfo = null;
            self._ready = null;

            return self.getDriver(driverName).then(function (driver) {
                self._driver = driver._driver;
                setDriverToConfig();
                self._wrapLibraryMethodsWithReady();
                self._initDriver = initDriver(supportedDrivers);
            });
        })["catch"](function () {
            setDriverToConfig();
            var error = new Error('No available storage method found.');
            self._driverSet = Promise$1.reject(error);
            return self._driverSet;
        });

        executeTwoCallbacks(this._driverSet, callback, errorCallback);
        return this._driverSet;
    };

    LocalForage.prototype.supports = function supports(driverName) {
        return !!DriverSupport[driverName];
    };

    LocalForage.prototype._extend = function _extend(libraryMethodsAndProperties) {
        extend(this, libraryMethodsAndProperties);
    };

    LocalForage.prototype._getSupportedDrivers = function _getSupportedDrivers(drivers) {
        var supportedDrivers = [];
        for (var i = 0, len = drivers.length; i < len; i++) {
            var driverName = drivers[i];
            if (this.supports(driverName)) {
                supportedDrivers.push(driverName);
            }
        }
        return supportedDrivers;
    };

    LocalForage.prototype._wrapLibraryMethodsWithReady = function _wrapLibraryMethodsWithReady() {
        // Add a stub for each driver API method that delays the call to the
        // corresponding driver method until localForage is ready. These stubs
        // will be replaced by the driver methods as soon as the driver is
        // loaded, so there is no performance impact.
        for (var i = 0, len = LibraryMethods.length; i < len; i++) {
            callWhenReady(this, LibraryMethods[i]);
        }
    };

    LocalForage.prototype.createInstance = function createInstance(options) {
        return new LocalForage(options);
    };

    return LocalForage;
}();

// The actual localForage object that we expose as a module or via a
// global. It's extended by pulling in one of our other libraries.


var localforage_js = new LocalForage();

module.exports = localforage_js;

},{"3":3}]},{},[4])(4)
});


/***/ }),

/***/ 2705:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(5639);

/** Built-in value references. */
var Symbol = root.Symbol;

module.exports = Symbol;


/***/ }),

/***/ 6874:
/***/ ((module) => {

/**
 * A faster alternative to `Function#apply`, this function invokes `func`
 * with the `this` binding of `thisArg` and the arguments of `args`.
 *
 * @private
 * @param {Function} func The function to invoke.
 * @param {*} thisArg The `this` binding of `func`.
 * @param {Array} args The arguments to invoke `func` with.
 * @returns {*} Returns the result of `func`.
 */
function apply(func, thisArg, args) {
  switch (args.length) {
    case 0: return func.call(thisArg);
    case 1: return func.call(thisArg, args[0]);
    case 2: return func.call(thisArg, args[0], args[1]);
    case 3: return func.call(thisArg, args[0], args[1], args[2]);
  }
  return func.apply(thisArg, args);
}

module.exports = apply;


/***/ }),

/***/ 4636:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseTimes = __webpack_require__(2545),
    isArguments = __webpack_require__(5694),
    isArray = __webpack_require__(1469),
    isBuffer = __webpack_require__(4144),
    isIndex = __webpack_require__(5776),
    isTypedArray = __webpack_require__(6719);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Creates an array of the enumerable property names of the array-like `value`.
 *
 * @private
 * @param {*} value The value to query.
 * @param {boolean} inherited Specify returning inherited property names.
 * @returns {Array} Returns the array of property names.
 */
function arrayLikeKeys(value, inherited) {
  var isArr = isArray(value),
      isArg = !isArr && isArguments(value),
      isBuff = !isArr && !isArg && isBuffer(value),
      isType = !isArr && !isArg && !isBuff && isTypedArray(value),
      skipIndexes = isArr || isArg || isBuff || isType,
      result = skipIndexes ? baseTimes(value.length, String) : [],
      length = result.length;

  for (var key in value) {
    if ((inherited || hasOwnProperty.call(value, key)) &&
        !(skipIndexes && (
           // Safari 9 has enumerable `arguments.length` in strict mode.
           key == 'length' ||
           // Node.js 0.10 has enumerable non-index properties on buffers.
           (isBuff && (key == 'offset' || key == 'parent')) ||
           // PhantomJS 2 has enumerable non-index properties on typed arrays.
           (isType && (key == 'buffer' || key == 'byteLength' || key == 'byteOffset')) ||
           // Skip index properties.
           isIndex(key, length)
        ))) {
      result.push(key);
    }
  }
  return result;
}

module.exports = arrayLikeKeys;


/***/ }),

/***/ 4865:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseAssignValue = __webpack_require__(9465),
    eq = __webpack_require__(7813);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Assigns `value` to `key` of `object` if the existing value is not equivalent
 * using [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
 * for equality comparisons.
 *
 * @private
 * @param {Object} object The object to modify.
 * @param {string} key The key of the property to assign.
 * @param {*} value The value to assign.
 */
function assignValue(object, key, value) {
  var objValue = object[key];
  if (!(hasOwnProperty.call(object, key) && eq(objValue, value)) ||
      (value === undefined && !(key in object))) {
    baseAssignValue(object, key, value);
  }
}

module.exports = assignValue;


/***/ }),

/***/ 9465:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var defineProperty = __webpack_require__(8777);

/**
 * The base implementation of `assignValue` and `assignMergeValue` without
 * value checks.
 *
 * @private
 * @param {Object} object The object to modify.
 * @param {string} key The key of the property to assign.
 * @param {*} value The value to assign.
 */
function baseAssignValue(object, key, value) {
  if (key == '__proto__' && defineProperty) {
    defineProperty(object, key, {
      'configurable': true,
      'enumerable': true,
      'value': value,
      'writable': true
    });
  } else {
    object[key] = value;
  }
}

module.exports = baseAssignValue;


/***/ }),

/***/ 4239:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Symbol = __webpack_require__(2705),
    getRawTag = __webpack_require__(9607),
    objectToString = __webpack_require__(2333);

/** `Object#toString` result references. */
var nullTag = '[object Null]',
    undefinedTag = '[object Undefined]';

/** Built-in value references. */
var symToStringTag = Symbol ? Symbol.toStringTag : undefined;

/**
 * The base implementation of `getTag` without fallbacks for buggy environments.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the `toStringTag`.
 */
function baseGetTag(value) {
  if (value == null) {
    return value === undefined ? undefinedTag : nullTag;
  }
  return (symToStringTag && symToStringTag in Object(value))
    ? getRawTag(value)
    : objectToString(value);
}

module.exports = baseGetTag;


/***/ }),

/***/ 9454:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(4239),
    isObjectLike = __webpack_require__(7005);

/** `Object#toString` result references. */
var argsTag = '[object Arguments]';

/**
 * The base implementation of `_.isArguments`.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
 */
function baseIsArguments(value) {
  return isObjectLike(value) && baseGetTag(value) == argsTag;
}

module.exports = baseIsArguments;


/***/ }),

/***/ 8458:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isFunction = __webpack_require__(3560),
    isMasked = __webpack_require__(5346),
    isObject = __webpack_require__(3218),
    toSource = __webpack_require__(346);

/**
 * Used to match `RegExp`
 * [syntax characters](http://ecma-international.org/ecma-262/7.0/#sec-patterns).
 */
var reRegExpChar = /[\\^$.*+?()[\]{}|]/g;

/** Used to detect host constructors (Safari). */
var reIsHostCtor = /^\[object .+?Constructor\]$/;

/** Used for built-in method references. */
var funcProto = Function.prototype,
    objectProto = Object.prototype;

/** Used to resolve the decompiled source of functions. */
var funcToString = funcProto.toString;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/** Used to detect if a method is native. */
var reIsNative = RegExp('^' +
  funcToString.call(hasOwnProperty).replace(reRegExpChar, '\\$&')
  .replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g, '$1.*?') + '$'
);

/**
 * The base implementation of `_.isNative` without bad shim checks.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a native function,
 *  else `false`.
 */
function baseIsNative(value) {
  if (!isObject(value) || isMasked(value)) {
    return false;
  }
  var pattern = isFunction(value) ? reIsNative : reIsHostCtor;
  return pattern.test(toSource(value));
}

module.exports = baseIsNative;


/***/ }),

/***/ 8749:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(4239),
    isLength = __webpack_require__(1780),
    isObjectLike = __webpack_require__(7005);

/** `Object#toString` result references. */
var argsTag = '[object Arguments]',
    arrayTag = '[object Array]',
    boolTag = '[object Boolean]',
    dateTag = '[object Date]',
    errorTag = '[object Error]',
    funcTag = '[object Function]',
    mapTag = '[object Map]',
    numberTag = '[object Number]',
    objectTag = '[object Object]',
    regexpTag = '[object RegExp]',
    setTag = '[object Set]',
    stringTag = '[object String]',
    weakMapTag = '[object WeakMap]';

var arrayBufferTag = '[object ArrayBuffer]',
    dataViewTag = '[object DataView]',
    float32Tag = '[object Float32Array]',
    float64Tag = '[object Float64Array]',
    int8Tag = '[object Int8Array]',
    int16Tag = '[object Int16Array]',
    int32Tag = '[object Int32Array]',
    uint8Tag = '[object Uint8Array]',
    uint8ClampedTag = '[object Uint8ClampedArray]',
    uint16Tag = '[object Uint16Array]',
    uint32Tag = '[object Uint32Array]';

/** Used to identify `toStringTag` values of typed arrays. */
var typedArrayTags = {};
typedArrayTags[float32Tag] = typedArrayTags[float64Tag] =
typedArrayTags[int8Tag] = typedArrayTags[int16Tag] =
typedArrayTags[int32Tag] = typedArrayTags[uint8Tag] =
typedArrayTags[uint8ClampedTag] = typedArrayTags[uint16Tag] =
typedArrayTags[uint32Tag] = true;
typedArrayTags[argsTag] = typedArrayTags[arrayTag] =
typedArrayTags[arrayBufferTag] = typedArrayTags[boolTag] =
typedArrayTags[dataViewTag] = typedArrayTags[dateTag] =
typedArrayTags[errorTag] = typedArrayTags[funcTag] =
typedArrayTags[mapTag] = typedArrayTags[numberTag] =
typedArrayTags[objectTag] = typedArrayTags[regexpTag] =
typedArrayTags[setTag] = typedArrayTags[stringTag] =
typedArrayTags[weakMapTag] = false;

/**
 * The base implementation of `_.isTypedArray` without Node.js optimizations.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
 */
function baseIsTypedArray(value) {
  return isObjectLike(value) &&
    isLength(value.length) && !!typedArrayTags[baseGetTag(value)];
}

module.exports = baseIsTypedArray;


/***/ }),

/***/ 280:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isPrototype = __webpack_require__(5726),
    nativeKeys = __webpack_require__(6916);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * The base implementation of `_.keys` which doesn't treat sparse arrays as dense.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 */
function baseKeys(object) {
  if (!isPrototype(object)) {
    return nativeKeys(object);
  }
  var result = [];
  for (var key in Object(object)) {
    if (hasOwnProperty.call(object, key) && key != 'constructor') {
      result.push(key);
    }
  }
  return result;
}

module.exports = baseKeys;


/***/ }),

/***/ 5976:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var identity = __webpack_require__(6557),
    overRest = __webpack_require__(5357),
    setToString = __webpack_require__(61);

/**
 * The base implementation of `_.rest` which doesn't validate or coerce arguments.
 *
 * @private
 * @param {Function} func The function to apply a rest parameter to.
 * @param {number} [start=func.length-1] The start position of the rest parameter.
 * @returns {Function} Returns the new function.
 */
function baseRest(func, start) {
  return setToString(overRest(func, start, identity), func + '');
}

module.exports = baseRest;


/***/ }),

/***/ 6560:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var constant = __webpack_require__(5703),
    defineProperty = __webpack_require__(8777),
    identity = __webpack_require__(6557);

/**
 * The base implementation of `setToString` without support for hot loop shorting.
 *
 * @private
 * @param {Function} func The function to modify.
 * @param {Function} string The `toString` result.
 * @returns {Function} Returns `func`.
 */
var baseSetToString = !defineProperty ? identity : function(func, string) {
  return defineProperty(func, 'toString', {
    'configurable': true,
    'enumerable': false,
    'value': constant(string),
    'writable': true
  });
};

module.exports = baseSetToString;


/***/ }),

/***/ 2545:
/***/ ((module) => {

/**
 * The base implementation of `_.times` without support for iteratee shorthands
 * or max array length checks.
 *
 * @private
 * @param {number} n The number of times to invoke `iteratee`.
 * @param {Function} iteratee The function invoked per iteration.
 * @returns {Array} Returns the array of results.
 */
function baseTimes(n, iteratee) {
  var index = -1,
      result = Array(n);

  while (++index < n) {
    result[index] = iteratee(index);
  }
  return result;
}

module.exports = baseTimes;


/***/ }),

/***/ 1717:
/***/ ((module) => {

/**
 * The base implementation of `_.unary` without support for storing metadata.
 *
 * @private
 * @param {Function} func The function to cap arguments for.
 * @returns {Function} Returns the new capped function.
 */
function baseUnary(func) {
  return function(value) {
    return func(value);
  };
}

module.exports = baseUnary;


/***/ }),

/***/ 8363:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assignValue = __webpack_require__(4865),
    baseAssignValue = __webpack_require__(9465);

/**
 * Copies properties of `source` to `object`.
 *
 * @private
 * @param {Object} source The object to copy properties from.
 * @param {Array} props The property identifiers to copy.
 * @param {Object} [object={}] The object to copy properties to.
 * @param {Function} [customizer] The function to customize copied values.
 * @returns {Object} Returns `object`.
 */
function copyObject(source, props, object, customizer) {
  var isNew = !object;
  object || (object = {});

  var index = -1,
      length = props.length;

  while (++index < length) {
    var key = props[index];

    var newValue = customizer
      ? customizer(object[key], source[key], key, object, source)
      : undefined;

    if (newValue === undefined) {
      newValue = source[key];
    }
    if (isNew) {
      baseAssignValue(object, key, newValue);
    } else {
      assignValue(object, key, newValue);
    }
  }
  return object;
}

module.exports = copyObject;


/***/ }),

/***/ 4429:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(5639);

/** Used to detect overreaching core-js shims. */
var coreJsData = root['__core-js_shared__'];

module.exports = coreJsData;


/***/ }),

/***/ 1463:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseRest = __webpack_require__(5976),
    isIterateeCall = __webpack_require__(6612);

/**
 * Creates a function like `_.assign`.
 *
 * @private
 * @param {Function} assigner The function to assign values.
 * @returns {Function} Returns the new assigner function.
 */
function createAssigner(assigner) {
  return baseRest(function(object, sources) {
    var index = -1,
        length = sources.length,
        customizer = length > 1 ? sources[length - 1] : undefined,
        guard = length > 2 ? sources[2] : undefined;

    customizer = (assigner.length > 3 && typeof customizer == 'function')
      ? (length--, customizer)
      : undefined;

    if (guard && isIterateeCall(sources[0], sources[1], guard)) {
      customizer = length < 3 ? undefined : customizer;
      length = 1;
    }
    object = Object(object);
    while (++index < length) {
      var source = sources[index];
      if (source) {
        assigner(object, source, index, customizer);
      }
    }
    return object;
  });
}

module.exports = createAssigner;


/***/ }),

/***/ 8777:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(852);

var defineProperty = (function() {
  try {
    var func = getNative(Object, 'defineProperty');
    func({}, '', {});
    return func;
  } catch (e) {}
}());

module.exports = defineProperty;


/***/ }),

/***/ 1957:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

/** Detect free variable `global` from Node.js. */
var freeGlobal = typeof __webpack_require__.g == 'object' && __webpack_require__.g && __webpack_require__.g.Object === Object && __webpack_require__.g;

module.exports = freeGlobal;


/***/ }),

/***/ 852:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsNative = __webpack_require__(8458),
    getValue = __webpack_require__(7801);

/**
 * Gets the native function at `key` of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @param {string} key The key of the method to get.
 * @returns {*} Returns the function if it's native, else `undefined`.
 */
function getNative(object, key) {
  var value = getValue(object, key);
  return baseIsNative(value) ? value : undefined;
}

module.exports = getNative;


/***/ }),

/***/ 9607:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Symbol = __webpack_require__(2705);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */
var nativeObjectToString = objectProto.toString;

/** Built-in value references. */
var symToStringTag = Symbol ? Symbol.toStringTag : undefined;

/**
 * A specialized version of `baseGetTag` which ignores `Symbol.toStringTag` values.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the raw `toStringTag`.
 */
function getRawTag(value) {
  var isOwn = hasOwnProperty.call(value, symToStringTag),
      tag = value[symToStringTag];

  try {
    value[symToStringTag] = undefined;
    var unmasked = true;
  } catch (e) {}

  var result = nativeObjectToString.call(value);
  if (unmasked) {
    if (isOwn) {
      value[symToStringTag] = tag;
    } else {
      delete value[symToStringTag];
    }
  }
  return result;
}

module.exports = getRawTag;


/***/ }),

/***/ 7801:
/***/ ((module) => {

/**
 * Gets the value at `key` of `object`.
 *
 * @private
 * @param {Object} [object] The object to query.
 * @param {string} key The key of the property to get.
 * @returns {*} Returns the property value.
 */
function getValue(object, key) {
  return object == null ? undefined : object[key];
}

module.exports = getValue;


/***/ }),

/***/ 5776:
/***/ ((module) => {

/** Used as references for various `Number` constants. */
var MAX_SAFE_INTEGER = 9007199254740991;

/** Used to detect unsigned integer values. */
var reIsUint = /^(?:0|[1-9]\d*)$/;

/**
 * Checks if `value` is a valid array-like index.
 *
 * @private
 * @param {*} value The value to check.
 * @param {number} [length=MAX_SAFE_INTEGER] The upper bounds of a valid index.
 * @returns {boolean} Returns `true` if `value` is a valid index, else `false`.
 */
function isIndex(value, length) {
  var type = typeof value;
  length = length == null ? MAX_SAFE_INTEGER : length;

  return !!length &&
    (type == 'number' ||
      (type != 'symbol' && reIsUint.test(value))) &&
        (value > -1 && value % 1 == 0 && value < length);
}

module.exports = isIndex;


/***/ }),

/***/ 6612:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var eq = __webpack_require__(7813),
    isArrayLike = __webpack_require__(8612),
    isIndex = __webpack_require__(5776),
    isObject = __webpack_require__(3218);

/**
 * Checks if the given arguments are from an iteratee call.
 *
 * @private
 * @param {*} value The potential iteratee value argument.
 * @param {*} index The potential iteratee index or key argument.
 * @param {*} object The potential iteratee object argument.
 * @returns {boolean} Returns `true` if the arguments are from an iteratee call,
 *  else `false`.
 */
function isIterateeCall(value, index, object) {
  if (!isObject(object)) {
    return false;
  }
  var type = typeof index;
  if (type == 'number'
        ? (isArrayLike(object) && isIndex(index, object.length))
        : (type == 'string' && index in object)
      ) {
    return eq(object[index], value);
  }
  return false;
}

module.exports = isIterateeCall;


/***/ }),

/***/ 5346:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var coreJsData = __webpack_require__(4429);

/** Used to detect methods masquerading as native. */
var maskSrcKey = (function() {
  var uid = /[^.]+$/.exec(coreJsData && coreJsData.keys && coreJsData.keys.IE_PROTO || '');
  return uid ? ('Symbol(src)_1.' + uid) : '';
}());

/**
 * Checks if `func` has its source masked.
 *
 * @private
 * @param {Function} func The function to check.
 * @returns {boolean} Returns `true` if `func` is masked, else `false`.
 */
function isMasked(func) {
  return !!maskSrcKey && (maskSrcKey in func);
}

module.exports = isMasked;


/***/ }),

/***/ 5726:
/***/ ((module) => {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/**
 * Checks if `value` is likely a prototype object.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a prototype, else `false`.
 */
function isPrototype(value) {
  var Ctor = value && value.constructor,
      proto = (typeof Ctor == 'function' && Ctor.prototype) || objectProto;

  return value === proto;
}

module.exports = isPrototype;


/***/ }),

/***/ 6916:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var overArg = __webpack_require__(5569);

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeKeys = overArg(Object.keys, Object);

module.exports = nativeKeys;


/***/ }),

/***/ 1167:
/***/ ((module, exports, __webpack_require__) => {

/* module decorator */ module = __webpack_require__.nmd(module);
var freeGlobal = __webpack_require__(1957);

/** Detect free variable `exports`. */
var freeExports =  true && exports && !exports.nodeType && exports;

/** Detect free variable `module`. */
var freeModule = freeExports && "object" == 'object' && module && !module.nodeType && module;

/** Detect the popular CommonJS extension `module.exports`. */
var moduleExports = freeModule && freeModule.exports === freeExports;

/** Detect free variable `process` from Node.js. */
var freeProcess = moduleExports && freeGlobal.process;

/** Used to access faster Node.js helpers. */
var nodeUtil = (function() {
  try {
    // Use `util.types` for Node.js 10+.
    var types = freeModule && freeModule.require && freeModule.require('util').types;

    if (types) {
      return types;
    }

    // Legacy `process.binding('util')` for Node.js < 10.
    return freeProcess && freeProcess.binding && freeProcess.binding('util');
  } catch (e) {}
}());

module.exports = nodeUtil;


/***/ }),

/***/ 2333:
/***/ ((module) => {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */
var nativeObjectToString = objectProto.toString;

/**
 * Converts `value` to a string using `Object.prototype.toString`.
 *
 * @private
 * @param {*} value The value to convert.
 * @returns {string} Returns the converted string.
 */
function objectToString(value) {
  return nativeObjectToString.call(value);
}

module.exports = objectToString;


/***/ }),

/***/ 5569:
/***/ ((module) => {

/**
 * Creates a unary function that invokes `func` with its argument transformed.
 *
 * @private
 * @param {Function} func The function to wrap.
 * @param {Function} transform The argument transform.
 * @returns {Function} Returns the new function.
 */
function overArg(func, transform) {
  return function(arg) {
    return func(transform(arg));
  };
}

module.exports = overArg;


/***/ }),

/***/ 5357:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var apply = __webpack_require__(6874);

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeMax = Math.max;

/**
 * A specialized version of `baseRest` which transforms the rest array.
 *
 * @private
 * @param {Function} func The function to apply a rest parameter to.
 * @param {number} [start=func.length-1] The start position of the rest parameter.
 * @param {Function} transform The rest array transform.
 * @returns {Function} Returns the new function.
 */
function overRest(func, start, transform) {
  start = nativeMax(start === undefined ? (func.length - 1) : start, 0);
  return function() {
    var args = arguments,
        index = -1,
        length = nativeMax(args.length - start, 0),
        array = Array(length);

    while (++index < length) {
      array[index] = args[start + index];
    }
    index = -1;
    var otherArgs = Array(start + 1);
    while (++index < start) {
      otherArgs[index] = args[index];
    }
    otherArgs[start] = transform(array);
    return apply(func, this, otherArgs);
  };
}

module.exports = overRest;


/***/ }),

/***/ 5639:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var freeGlobal = __webpack_require__(1957);

/** Detect free variable `self`. */
var freeSelf = typeof self == 'object' && self && self.Object === Object && self;

/** Used as a reference to the global object. */
var root = freeGlobal || freeSelf || Function('return this')();

module.exports = root;


/***/ }),

/***/ 61:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseSetToString = __webpack_require__(6560),
    shortOut = __webpack_require__(1275);

/**
 * Sets the `toString` method of `func` to return `string`.
 *
 * @private
 * @param {Function} func The function to modify.
 * @param {Function} string The `toString` result.
 * @returns {Function} Returns `func`.
 */
var setToString = shortOut(baseSetToString);

module.exports = setToString;


/***/ }),

/***/ 1275:
/***/ ((module) => {

/** Used to detect hot functions by number of calls within a span of milliseconds. */
var HOT_COUNT = 800,
    HOT_SPAN = 16;

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeNow = Date.now;

/**
 * Creates a function that'll short out and invoke `identity` instead
 * of `func` when it's called `HOT_COUNT` or more times in `HOT_SPAN`
 * milliseconds.
 *
 * @private
 * @param {Function} func The function to restrict.
 * @returns {Function} Returns the new shortable function.
 */
function shortOut(func) {
  var count = 0,
      lastCalled = 0;

  return function() {
    var stamp = nativeNow(),
        remaining = HOT_SPAN - (stamp - lastCalled);

    lastCalled = stamp;
    if (remaining > 0) {
      if (++count >= HOT_COUNT) {
        return arguments[0];
      }
    } else {
      count = 0;
    }
    return func.apply(undefined, arguments);
  };
}

module.exports = shortOut;


/***/ }),

/***/ 346:
/***/ ((module) => {

/** Used for built-in method references. */
var funcProto = Function.prototype;

/** Used to resolve the decompiled source of functions. */
var funcToString = funcProto.toString;

/**
 * Converts `func` to its source code.
 *
 * @private
 * @param {Function} func The function to convert.
 * @returns {string} Returns the source code.
 */
function toSource(func) {
  if (func != null) {
    try {
      return funcToString.call(func);
    } catch (e) {}
    try {
      return (func + '');
    } catch (e) {}
  }
  return '';
}

module.exports = toSource;


/***/ }),

/***/ 8583:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assignValue = __webpack_require__(4865),
    copyObject = __webpack_require__(8363),
    createAssigner = __webpack_require__(1463),
    isArrayLike = __webpack_require__(8612),
    isPrototype = __webpack_require__(5726),
    keys = __webpack_require__(3674);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Assigns own enumerable string keyed properties of source objects to the
 * destination object. Source objects are applied from left to right.
 * Subsequent sources overwrite property assignments of previous sources.
 *
 * **Note:** This method mutates `object` and is loosely based on
 * [`Object.assign`](https://mdn.io/Object/assign).
 *
 * @static
 * @memberOf _
 * @since 0.10.0
 * @category Object
 * @param {Object} object The destination object.
 * @param {...Object} [sources] The source objects.
 * @returns {Object} Returns `object`.
 * @see _.assignIn
 * @example
 *
 * function Foo() {
 *   this.a = 1;
 * }
 *
 * function Bar() {
 *   this.c = 3;
 * }
 *
 * Foo.prototype.b = 2;
 * Bar.prototype.d = 4;
 *
 * _.assign({ 'a': 0 }, new Foo, new Bar);
 * // => { 'a': 1, 'c': 3 }
 */
var assign = createAssigner(function(object, source) {
  if (isPrototype(source) || isArrayLike(source)) {
    copyObject(source, keys(source), object);
    return;
  }
  for (var key in source) {
    if (hasOwnProperty.call(source, key)) {
      assignValue(object, key, source[key]);
    }
  }
});

module.exports = assign;


/***/ }),

/***/ 5703:
/***/ ((module) => {

/**
 * Creates a function that returns `value`.
 *
 * @static
 * @memberOf _
 * @since 2.4.0
 * @category Util
 * @param {*} value The value to return from the new function.
 * @returns {Function} Returns the new constant function.
 * @example
 *
 * var objects = _.times(2, _.constant({ 'a': 1 }));
 *
 * console.log(objects);
 * // => [{ 'a': 1 }, { 'a': 1 }]
 *
 * console.log(objects[0] === objects[1]);
 * // => true
 */
function constant(value) {
  return function() {
    return value;
  };
}

module.exports = constant;


/***/ }),

/***/ 3279:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isObject = __webpack_require__(3218),
    now = __webpack_require__(7771),
    toNumber = __webpack_require__(4841);

/** Error message constants. */
var FUNC_ERROR_TEXT = 'Expected a function';

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeMax = Math.max,
    nativeMin = Math.min;

/**
 * Creates a debounced function that delays invoking `func` until after `wait`
 * milliseconds have elapsed since the last time the debounced function was
 * invoked. The debounced function comes with a `cancel` method to cancel
 * delayed `func` invocations and a `flush` method to immediately invoke them.
 * Provide `options` to indicate whether `func` should be invoked on the
 * leading and/or trailing edge of the `wait` timeout. The `func` is invoked
 * with the last arguments provided to the debounced function. Subsequent
 * calls to the debounced function return the result of the last `func`
 * invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the debounced function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.debounce` and `_.throttle`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to debounce.
 * @param {number} [wait=0] The number of milliseconds to delay.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=false]
 *  Specify invoking on the leading edge of the timeout.
 * @param {number} [options.maxWait]
 *  The maximum time `func` is allowed to be delayed before it's invoked.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new debounced function.
 * @example
 *
 * // Avoid costly calculations while the window size is in flux.
 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
 *
 * // Invoke `sendMail` when clicked, debouncing subsequent calls.
 * jQuery(element).on('click', _.debounce(sendMail, 300, {
 *   'leading': true,
 *   'trailing': false
 * }));
 *
 * // Ensure `batchLog` is invoked once after 1 second of debounced calls.
 * var debounced = _.debounce(batchLog, 250, { 'maxWait': 1000 });
 * var source = new EventSource('/stream');
 * jQuery(source).on('message', debounced);
 *
 * // Cancel the trailing debounced invocation.
 * jQuery(window).on('popstate', debounced.cancel);
 */
function debounce(func, wait, options) {
  var lastArgs,
      lastThis,
      maxWait,
      result,
      timerId,
      lastCallTime,
      lastInvokeTime = 0,
      leading = false,
      maxing = false,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT);
  }
  wait = toNumber(wait) || 0;
  if (isObject(options)) {
    leading = !!options.leading;
    maxing = 'maxWait' in options;
    maxWait = maxing ? nativeMax(toNumber(options.maxWait) || 0, wait) : maxWait;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }

  function invokeFunc(time) {
    var args = lastArgs,
        thisArg = lastThis;

    lastArgs = lastThis = undefined;
    lastInvokeTime = time;
    result = func.apply(thisArg, args);
    return result;
  }

  function leadingEdge(time) {
    // Reset any `maxWait` timer.
    lastInvokeTime = time;
    // Start the timer for the trailing edge.
    timerId = setTimeout(timerExpired, wait);
    // Invoke the leading edge.
    return leading ? invokeFunc(time) : result;
  }

  function remainingWait(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime,
        timeWaiting = wait - timeSinceLastCall;

    return maxing
      ? nativeMin(timeWaiting, maxWait - timeSinceLastInvoke)
      : timeWaiting;
  }

  function shouldInvoke(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime;

    // Either this is the first call, activity has stopped and we're at the
    // trailing edge, the system time has gone backwards and we're treating
    // it as the trailing edge, or we've hit the `maxWait` limit.
    return (lastCallTime === undefined || (timeSinceLastCall >= wait) ||
      (timeSinceLastCall < 0) || (maxing && timeSinceLastInvoke >= maxWait));
  }

  function timerExpired() {
    var time = now();
    if (shouldInvoke(time)) {
      return trailingEdge(time);
    }
    // Restart the timer.
    timerId = setTimeout(timerExpired, remainingWait(time));
  }

  function trailingEdge(time) {
    timerId = undefined;

    // Only invoke if we have `lastArgs` which means `func` has been
    // debounced at least once.
    if (trailing && lastArgs) {
      return invokeFunc(time);
    }
    lastArgs = lastThis = undefined;
    return result;
  }

  function cancel() {
    if (timerId !== undefined) {
      clearTimeout(timerId);
    }
    lastInvokeTime = 0;
    lastArgs = lastCallTime = lastThis = timerId = undefined;
  }

  function flush() {
    return timerId === undefined ? result : trailingEdge(now());
  }

  function debounced() {
    var time = now(),
        isInvoking = shouldInvoke(time);

    lastArgs = arguments;
    lastThis = this;
    lastCallTime = time;

    if (isInvoking) {
      if (timerId === undefined) {
        return leadingEdge(lastCallTime);
      }
      if (maxing) {
        // Handle invocations in a tight loop.
        clearTimeout(timerId);
        timerId = setTimeout(timerExpired, wait);
        return invokeFunc(lastCallTime);
      }
    }
    if (timerId === undefined) {
      timerId = setTimeout(timerExpired, wait);
    }
    return result;
  }
  debounced.cancel = cancel;
  debounced.flush = flush;
  return debounced;
}

module.exports = debounce;


/***/ }),

/***/ 7813:
/***/ ((module) => {

/**
 * Performs a
 * [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
 * comparison between two values to determine if they are equivalent.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to compare.
 * @param {*} other The other value to compare.
 * @returns {boolean} Returns `true` if the values are equivalent, else `false`.
 * @example
 *
 * var object = { 'a': 1 };
 * var other = { 'a': 1 };
 *
 * _.eq(object, object);
 * // => true
 *
 * _.eq(object, other);
 * // => false
 *
 * _.eq('a', 'a');
 * // => true
 *
 * _.eq('a', Object('a'));
 * // => false
 *
 * _.eq(NaN, NaN);
 * // => true
 */
function eq(value, other) {
  return value === other || (value !== value && other !== other);
}

module.exports = eq;


/***/ }),

/***/ 6557:
/***/ ((module) => {

/**
 * This method returns the first argument it receives.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Util
 * @param {*} value Any value.
 * @returns {*} Returns `value`.
 * @example
 *
 * var object = { 'a': 1 };
 *
 * console.log(_.identity(object) === object);
 * // => true
 */
function identity(value) {
  return value;
}

module.exports = identity;


/***/ }),

/***/ 5694:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsArguments = __webpack_require__(9454),
    isObjectLike = __webpack_require__(7005);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/** Built-in value references. */
var propertyIsEnumerable = objectProto.propertyIsEnumerable;

/**
 * Checks if `value` is likely an `arguments` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
 *  else `false`.
 * @example
 *
 * _.isArguments(function() { return arguments; }());
 * // => true
 *
 * _.isArguments([1, 2, 3]);
 * // => false
 */
var isArguments = baseIsArguments(function() { return arguments; }()) ? baseIsArguments : function(value) {
  return isObjectLike(value) && hasOwnProperty.call(value, 'callee') &&
    !propertyIsEnumerable.call(value, 'callee');
};

module.exports = isArguments;


/***/ }),

/***/ 1469:
/***/ ((module) => {

/**
 * Checks if `value` is classified as an `Array` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an array, else `false`.
 * @example
 *
 * _.isArray([1, 2, 3]);
 * // => true
 *
 * _.isArray(document.body.children);
 * // => false
 *
 * _.isArray('abc');
 * // => false
 *
 * _.isArray(_.noop);
 * // => false
 */
var isArray = Array.isArray;

module.exports = isArray;


/***/ }),

/***/ 8612:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isFunction = __webpack_require__(3560),
    isLength = __webpack_require__(1780);

/**
 * Checks if `value` is array-like. A value is considered array-like if it's
 * not a function and has a `value.length` that's an integer greater than or
 * equal to `0` and less than or equal to `Number.MAX_SAFE_INTEGER`.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is array-like, else `false`.
 * @example
 *
 * _.isArrayLike([1, 2, 3]);
 * // => true
 *
 * _.isArrayLike(document.body.children);
 * // => true
 *
 * _.isArrayLike('abc');
 * // => true
 *
 * _.isArrayLike(_.noop);
 * // => false
 */
function isArrayLike(value) {
  return value != null && isLength(value.length) && !isFunction(value);
}

module.exports = isArrayLike;


/***/ }),

/***/ 4144:
/***/ ((module, exports, __webpack_require__) => {

/* module decorator */ module = __webpack_require__.nmd(module);
var root = __webpack_require__(5639),
    stubFalse = __webpack_require__(5062);

/** Detect free variable `exports`. */
var freeExports =  true && exports && !exports.nodeType && exports;

/** Detect free variable `module`. */
var freeModule = freeExports && "object" == 'object' && module && !module.nodeType && module;

/** Detect the popular CommonJS extension `module.exports`. */
var moduleExports = freeModule && freeModule.exports === freeExports;

/** Built-in value references. */
var Buffer = moduleExports ? root.Buffer : undefined;

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeIsBuffer = Buffer ? Buffer.isBuffer : undefined;

/**
 * Checks if `value` is a buffer.
 *
 * @static
 * @memberOf _
 * @since 4.3.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a buffer, else `false`.
 * @example
 *
 * _.isBuffer(new Buffer(2));
 * // => true
 *
 * _.isBuffer(new Uint8Array(2));
 * // => false
 */
var isBuffer = nativeIsBuffer || stubFalse;

module.exports = isBuffer;


/***/ }),

/***/ 3560:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(4239),
    isObject = __webpack_require__(3218);

/** `Object#toString` result references. */
var asyncTag = '[object AsyncFunction]',
    funcTag = '[object Function]',
    genTag = '[object GeneratorFunction]',
    proxyTag = '[object Proxy]';

/**
 * Checks if `value` is classified as a `Function` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a function, else `false`.
 * @example
 *
 * _.isFunction(_);
 * // => true
 *
 * _.isFunction(/abc/);
 * // => false
 */
function isFunction(value) {
  if (!isObject(value)) {
    return false;
  }
  // The use of `Object#toString` avoids issues with the `typeof` operator
  // in Safari 9 which returns 'object' for typed arrays and other constructors.
  var tag = baseGetTag(value);
  return tag == funcTag || tag == genTag || tag == asyncTag || tag == proxyTag;
}

module.exports = isFunction;


/***/ }),

/***/ 1780:
/***/ ((module) => {

/** Used as references for various `Number` constants. */
var MAX_SAFE_INTEGER = 9007199254740991;

/**
 * Checks if `value` is a valid array-like length.
 *
 * **Note:** This method is loosely based on
 * [`ToLength`](http://ecma-international.org/ecma-262/7.0/#sec-tolength).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a valid length, else `false`.
 * @example
 *
 * _.isLength(3);
 * // => true
 *
 * _.isLength(Number.MIN_VALUE);
 * // => false
 *
 * _.isLength(Infinity);
 * // => false
 *
 * _.isLength('3');
 * // => false
 */
function isLength(value) {
  return typeof value == 'number' &&
    value > -1 && value % 1 == 0 && value <= MAX_SAFE_INTEGER;
}

module.exports = isLength;


/***/ }),

/***/ 3218:
/***/ ((module) => {

/**
 * Checks if `value` is the
 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
 * @example
 *
 * _.isObject({});
 * // => true
 *
 * _.isObject([1, 2, 3]);
 * // => true
 *
 * _.isObject(_.noop);
 * // => true
 *
 * _.isObject(null);
 * // => false
 */
function isObject(value) {
  var type = typeof value;
  return value != null && (type == 'object' || type == 'function');
}

module.exports = isObject;


/***/ }),

/***/ 7005:
/***/ ((module) => {

/**
 * Checks if `value` is object-like. A value is object-like if it's not `null`
 * and has a `typeof` result of "object".
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
 * @example
 *
 * _.isObjectLike({});
 * // => true
 *
 * _.isObjectLike([1, 2, 3]);
 * // => true
 *
 * _.isObjectLike(_.noop);
 * // => false
 *
 * _.isObjectLike(null);
 * // => false
 */
function isObjectLike(value) {
  return value != null && typeof value == 'object';
}

module.exports = isObjectLike;


/***/ }),

/***/ 3448:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(4239),
    isObjectLike = __webpack_require__(7005);

/** `Object#toString` result references. */
var symbolTag = '[object Symbol]';

/**
 * Checks if `value` is classified as a `Symbol` primitive or object.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a symbol, else `false`.
 * @example
 *
 * _.isSymbol(Symbol.iterator);
 * // => true
 *
 * _.isSymbol('abc');
 * // => false
 */
function isSymbol(value) {
  return typeof value == 'symbol' ||
    (isObjectLike(value) && baseGetTag(value) == symbolTag);
}

module.exports = isSymbol;


/***/ }),

/***/ 6719:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsTypedArray = __webpack_require__(8749),
    baseUnary = __webpack_require__(1717),
    nodeUtil = __webpack_require__(1167);

/* Node.js helper references. */
var nodeIsTypedArray = nodeUtil && nodeUtil.isTypedArray;

/**
 * Checks if `value` is classified as a typed array.
 *
 * @static
 * @memberOf _
 * @since 3.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
 * @example
 *
 * _.isTypedArray(new Uint8Array);
 * // => true
 *
 * _.isTypedArray([]);
 * // => false
 */
var isTypedArray = nodeIsTypedArray ? baseUnary(nodeIsTypedArray) : baseIsTypedArray;

module.exports = isTypedArray;


/***/ }),

/***/ 3674:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayLikeKeys = __webpack_require__(4636),
    baseKeys = __webpack_require__(280),
    isArrayLike = __webpack_require__(8612);

/**
 * Creates an array of the own enumerable property names of `object`.
 *
 * **Note:** Non-object values are coerced to objects. See the
 * [ES spec](http://ecma-international.org/ecma-262/7.0/#sec-object.keys)
 * for more details.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Object
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 * @example
 *
 * function Foo() {
 *   this.a = 1;
 *   this.b = 2;
 * }
 *
 * Foo.prototype.c = 3;
 *
 * _.keys(new Foo);
 * // => ['a', 'b'] (iteration order is not guaranteed)
 *
 * _.keys('hi');
 * // => ['0', '1']
 */
function keys(object) {
  return isArrayLike(object) ? arrayLikeKeys(object) : baseKeys(object);
}

module.exports = keys;


/***/ }),

/***/ 7771:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(5639);

/**
 * Gets the timestamp of the number of milliseconds that have elapsed since
 * the Unix epoch (1 January 1970 00:00:00 UTC).
 *
 * @static
 * @memberOf _
 * @since 2.4.0
 * @category Date
 * @returns {number} Returns the timestamp.
 * @example
 *
 * _.defer(function(stamp) {
 *   console.log(_.now() - stamp);
 * }, _.now());
 * // => Logs the number of milliseconds it took for the deferred invocation.
 */
var now = function() {
  return root.Date.now();
};

module.exports = now;


/***/ }),

/***/ 5062:
/***/ ((module) => {

/**
 * This method returns `false`.
 *
 * @static
 * @memberOf _
 * @since 4.13.0
 * @category Util
 * @returns {boolean} Returns `false`.
 * @example
 *
 * _.times(2, _.stubFalse);
 * // => [false, false]
 */
function stubFalse() {
  return false;
}

module.exports = stubFalse;


/***/ }),

/***/ 3493:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var debounce = __webpack_require__(3279),
    isObject = __webpack_require__(3218);

/** Error message constants. */
var FUNC_ERROR_TEXT = 'Expected a function';

/**
 * Creates a throttled function that only invokes `func` at most once per
 * every `wait` milliseconds. The throttled function comes with a `cancel`
 * method to cancel delayed `func` invocations and a `flush` method to
 * immediately invoke them. Provide `options` to indicate whether `func`
 * should be invoked on the leading and/or trailing edge of the `wait`
 * timeout. The `func` is invoked with the last arguments provided to the
 * throttled function. Subsequent calls to the throttled function return the
 * result of the last `func` invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the throttled function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.throttle` and `_.debounce`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to throttle.
 * @param {number} [wait=0] The number of milliseconds to throttle invocations to.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=true]
 *  Specify invoking on the leading edge of the timeout.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new throttled function.
 * @example
 *
 * // Avoid excessively updating the position while scrolling.
 * jQuery(window).on('scroll', _.throttle(updatePosition, 100));
 *
 * // Invoke `renewToken` when the click event is fired, but not more than once every 5 minutes.
 * var throttled = _.throttle(renewToken, 300000, { 'trailing': false });
 * jQuery(element).on('click', throttled);
 *
 * // Cancel the trailing throttled invocation.
 * jQuery(window).on('popstate', throttled.cancel);
 */
function throttle(func, wait, options) {
  var leading = true,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT);
  }
  if (isObject(options)) {
    leading = 'leading' in options ? !!options.leading : leading;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }
  return debounce(func, wait, {
    'leading': leading,
    'maxWait': wait,
    'trailing': trailing
  });
}

module.exports = throttle;


/***/ }),

/***/ 4841:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isObject = __webpack_require__(3218),
    isSymbol = __webpack_require__(3448);

/** Used as references for various `Number` constants. */
var NAN = 0 / 0;

/** Used to match leading and trailing whitespace. */
var reTrim = /^\s+|\s+$/g;

/** Used to detect bad signed hexadecimal string values. */
var reIsBadHex = /^[-+]0x[0-9a-f]+$/i;

/** Used to detect binary string values. */
var reIsBinary = /^0b[01]+$/i;

/** Used to detect octal string values. */
var reIsOctal = /^0o[0-7]+$/i;

/** Built-in method references without a dependency on `root`. */
var freeParseInt = parseInt;

/**
 * Converts `value` to a number.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to process.
 * @returns {number} Returns the number.
 * @example
 *
 * _.toNumber(3.2);
 * // => 3.2
 *
 * _.toNumber(Number.MIN_VALUE);
 * // => 5e-324
 *
 * _.toNumber(Infinity);
 * // => Infinity
 *
 * _.toNumber('3.2');
 * // => 3.2
 */
function toNumber(value) {
  if (typeof value == 'number') {
    return value;
  }
  if (isSymbol(value)) {
    return NAN;
  }
  if (isObject(value)) {
    var other = typeof value.valueOf == 'function' ? value.valueOf() : value;
    value = isObject(other) ? (other + '') : other;
  }
  if (typeof value != 'string') {
    return value === 0 ? value : +value;
  }
  value = value.replace(reTrim, '');
  var isBinary = reIsBinary.test(value);
  return (isBinary || reIsOctal.test(value))
    ? freeParseInt(value.slice(2), isBinary ? 2 : 8)
    : (reIsBadHex.test(value) ? NAN : +value);
}

module.exports = toNumber;


/***/ }),

/***/ 9294:
/***/ ((module) => {

"use strict";


if (!process) {
  var process = {
    "cwd" : function () { return '/' }
  };
}

function assertPath(path) {
  if (typeof path !== 'string') {
    throw new TypeError('Path must be a string. Received ' + path);
  }
}

// Resolves . and .. elements in a path with directory names
function normalizeStringPosix(path, allowAboveRoot) {
  var res = '';
  var lastSlash = -1;
  var dots = 0;
  var code;
  for (var i = 0; i <= path.length; ++i) {
    if (i < path.length)
      code = path.charCodeAt(i);
    else if (code === 47/*/*/)
      break;
    else
      code = 47/*/*/;
    if (code === 47/*/*/) {
      if (lastSlash === i - 1 || dots === 1) {
        // NOOP
      } else if (lastSlash !== i - 1 && dots === 2) {
        if (res.length < 2 ||
            res.charCodeAt(res.length - 1) !== 46/*.*/ ||
            res.charCodeAt(res.length - 2) !== 46/*.*/) {
          if (res.length > 2) {
            var start = res.length - 1;
            var j = start;
            for (; j >= 0; --j) {
              if (res.charCodeAt(j) === 47/*/*/)
                break;
            }
            if (j !== start) {
              if (j === -1)
                res = '';
              else
                res = res.slice(0, j);
              lastSlash = i;
              dots = 0;
              continue;
            }
          } else if (res.length === 2 || res.length === 1) {
            res = '';
            lastSlash = i;
            dots = 0;
            continue;
          }
        }
        if (allowAboveRoot) {
          if (res.length > 0)
            res += '/..';
          else
            res = '..';
        }
      } else {
        if (res.length > 0)
          res += '/' + path.slice(lastSlash + 1, i);
        else
          res = path.slice(lastSlash + 1, i);
      }
      lastSlash = i;
      dots = 0;
    } else if (code === 46/*.*/ && dots !== -1) {
      ++dots;
    } else {
      dots = -1;
    }
  }
  return res;
}

function _format(sep, pathObject) {
  var dir = pathObject.dir || pathObject.root;
  var base = pathObject.base ||
    ((pathObject.name || '') + (pathObject.ext || ''));
  if (!dir) {
    return base;
  }
  if (dir === pathObject.root) {
    return dir + base;
  }
  return dir + sep + base;
}

var posix = {
  // path.resolve([from ...], to)
  resolve: function resolve() {
    var resolvedPath = '';
    var resolvedAbsolute = false;
    var cwd;

    for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
      var path;
      if (i >= 0)
        path = arguments[i];
      else {
        if (cwd === undefined)
          cwd = process.cwd();
        path = cwd;
      }

      assertPath(path);

      // Skip empty entries
      if (path.length === 0) {
        continue;
      }

      resolvedPath = path + '/' + resolvedPath;
      resolvedAbsolute = path.charCodeAt(0) === 47/*/*/;
    }

    // At this point the path should be resolved to a full absolute path, but
    // handle relative paths to be safe (might happen when process.cwd() fails)

    // Normalize the path
    resolvedPath = normalizeStringPosix(resolvedPath, !resolvedAbsolute);

    if (resolvedAbsolute) {
      if (resolvedPath.length > 0)
        return '/' + resolvedPath;
      else
        return '/';
    } else if (resolvedPath.length > 0) {
      return resolvedPath;
    } else {
      return '.';
    }
  },


  normalize: function normalize(path) {
    assertPath(path);

    if (path.length === 0)
      return '.';

    var isAbsolute = path.charCodeAt(0) === 47/*/*/;
    var trailingSeparator = path.charCodeAt(path.length - 1) === 47/*/*/;

    // Normalize the path
    path = normalizeStringPosix(path, !isAbsolute);

    if (path.length === 0 && !isAbsolute)
      path = '.';
    if (path.length > 0 && trailingSeparator)
      path += '/';

    if (isAbsolute)
      return '/' + path;
    return path;
  },


  isAbsolute: function isAbsolute(path) {
    assertPath(path);
    return path.length > 0 && path.charCodeAt(0) === 47/*/*/;
  },


  join: function join() {
    if (arguments.length === 0)
      return '.';
    var joined;
    for (var i = 0; i < arguments.length; ++i) {
      var arg = arguments[i];
      assertPath(arg);
      if (arg.length > 0) {
        if (joined === undefined)
          joined = arg;
        else
          joined += '/' + arg;
      }
    }
    if (joined === undefined)
      return '.';
    return posix.normalize(joined);
  },


  relative: function relative(from, to) {
    assertPath(from);
    assertPath(to);

    if (from === to)
      return '';

    from = posix.resolve(from);
    to = posix.resolve(to);

    if (from === to)
      return '';

    // Trim any leading backslashes
    var fromStart = 1;
    for (; fromStart < from.length; ++fromStart) {
      if (from.charCodeAt(fromStart) !== 47/*/*/)
        break;
    }
    var fromEnd = from.length;
    var fromLen = (fromEnd - fromStart);

    // Trim any leading backslashes
    var toStart = 1;
    for (; toStart < to.length; ++toStart) {
      if (to.charCodeAt(toStart) !== 47/*/*/)
        break;
    }
    var toEnd = to.length;
    var toLen = (toEnd - toStart);

    // Compare paths to find the longest common path from root
    var length = (fromLen < toLen ? fromLen : toLen);
    var lastCommonSep = -1;
    var i = 0;
    for (; i <= length; ++i) {
      if (i === length) {
        if (toLen > length) {
          if (to.charCodeAt(toStart + i) === 47/*/*/) {
            // We get here if `from` is the exact base path for `to`.
            // For example: from='/foo/bar'; to='/foo/bar/baz'
            return to.slice(toStart + i + 1);
          } else if (i === 0) {
            // We get here if `from` is the root
            // For example: from='/'; to='/foo'
            return to.slice(toStart + i);
          }
        } else if (fromLen > length) {
          if (from.charCodeAt(fromStart + i) === 47/*/*/) {
            // We get here if `to` is the exact base path for `from`.
            // For example: from='/foo/bar/baz'; to='/foo/bar'
            lastCommonSep = i;
          } else if (i === 0) {
            // We get here if `to` is the root.
            // For example: from='/foo'; to='/'
            lastCommonSep = 0;
          }
        }
        break;
      }
      var fromCode = from.charCodeAt(fromStart + i);
      var toCode = to.charCodeAt(toStart + i);
      if (fromCode !== toCode)
        break;
      else if (fromCode === 47/*/*/)
        lastCommonSep = i;
    }

    var out = '';
    // Generate the relative path based on the path difference between `to`
    // and `from`
    for (i = fromStart + lastCommonSep + 1; i <= fromEnd; ++i) {
      if (i === fromEnd || from.charCodeAt(i) === 47/*/*/) {
        if (out.length === 0)
          out += '..';
        else
          out += '/..';
      }
    }

    // Lastly, append the rest of the destination (`to`) path that comes after
    // the common path parts
    if (out.length > 0)
      return out + to.slice(toStart + lastCommonSep);
    else {
      toStart += lastCommonSep;
      if (to.charCodeAt(toStart) === 47/*/*/)
        ++toStart;
      return to.slice(toStart);
    }
  },


  _makeLong: function _makeLong(path) {
    return path;
  },


  dirname: function dirname(path) {
    assertPath(path);
    if (path.length === 0)
      return '.';
    var code = path.charCodeAt(0);
    var hasRoot = (code === 47/*/*/);
    var end = -1;
    var matchedSlash = true;
    for (var i = path.length - 1; i >= 1; --i) {
      code = path.charCodeAt(i);
      if (code === 47/*/*/) {
        if (!matchedSlash) {
          end = i;
          break;
        }
      } else {
        // We saw the first non-path separator
        matchedSlash = false;
      }
    }

    if (end === -1)
      return hasRoot ? '/' : '.';
    if (hasRoot && end === 1)
      return '//';
    return path.slice(0, end);
  },


  basename: function basename(path, ext) {
    if (ext !== undefined && typeof ext !== 'string')
      throw new TypeError('"ext" argument must be a string');
    assertPath(path);

    var start = 0;
    var end = -1;
    var matchedSlash = true;
    var i;

    if (ext !== undefined && ext.length > 0 && ext.length <= path.length) {
      if (ext.length === path.length && ext === path)
        return '';
      var extIdx = ext.length - 1;
      var firstNonSlashEnd = -1;
      for (i = path.length - 1; i >= 0; --i) {
        var code = path.charCodeAt(i);
        if (code === 47/*/*/) {
          // If we reached a path separator that was not part of a set of path
          // separators at the end of the string, stop now
          if (!matchedSlash) {
            start = i + 1;
            break;
          }
        } else {
          if (firstNonSlashEnd === -1) {
            // We saw the first non-path separator, remember this index in case
            // we need it if the extension ends up not matching
            matchedSlash = false;
            firstNonSlashEnd = i + 1;
          }
          if (extIdx >= 0) {
            // Try to match the explicit extension
            if (code === ext.charCodeAt(extIdx)) {
              if (--extIdx === -1) {
                // We matched the extension, so mark this as the end of our path
                // component
                end = i;
              }
            } else {
              // Extension does not match, so our result is the entire path
              // component
              extIdx = -1;
              end = firstNonSlashEnd;
            }
          }
        }
      }

      if (start === end)
        end = firstNonSlashEnd;
      else if (end === -1)
        end = path.length;
      return path.slice(start, end);
    } else {
      for (i = path.length - 1; i >= 0; --i) {
        if (path.charCodeAt(i) === 47/*/*/) {
          // If we reached a path separator that was not part of a set of path
          // separators at the end of the string, stop now
          if (!matchedSlash) {
            start = i + 1;
            break;
          }
        } else if (end === -1) {
          // We saw the first non-path separator, mark this as the end of our
          // path component
          matchedSlash = false;
          end = i + 1;
        }
      }

      if (end === -1)
        return '';
      return path.slice(start, end);
    }
  },


  extname: function extname(path) {
    assertPath(path);
    var startDot = -1;
    var startPart = 0;
    var end = -1;
    var matchedSlash = true;
    // Track the state of characters (if any) we see before our first dot and
    // after any path separator we find
    var preDotState = 0;
    for (var i = path.length - 1; i >= 0; --i) {
      var code = path.charCodeAt(i);
      if (code === 47/*/*/) {
        // If we reached a path separator that was not part of a set of path
        // separators at the end of the string, stop now
        if (!matchedSlash) {
          startPart = i + 1;
          break;
        }
        continue;
      }
      if (end === -1) {
        // We saw the first non-path separator, mark this as the end of our
        // extension
        matchedSlash = false;
        end = i + 1;
      }
      if (code === 46/*.*/) {
        // If this is our first dot, mark it as the start of our extension
        if (startDot === -1)
          startDot = i;
        else if (preDotState !== 1)
          preDotState = 1;
      } else if (startDot !== -1) {
        // We saw a non-dot and non-path separator before our dot, so we should
        // have a good chance at having a non-empty extension
        preDotState = -1;
      }
    }

    if (startDot === -1 ||
        end === -1 ||
        // We saw a non-dot character immediately before the dot
        preDotState === 0 ||
        // The (right-most) trimmed path component is exactly '..'
        (preDotState === 1 &&
         startDot === end - 1 &&
         startDot === startPart + 1)) {
      return '';
    }
    return path.slice(startDot, end);
  },


  format: function format(pathObject) {
    if (pathObject === null || typeof pathObject !== 'object') {
      throw new TypeError(
        'Parameter "pathObject" must be an object, not ' + typeof(pathObject)
      );
    }
    return _format('/', pathObject);
  },


  parse: function parse(path) {
    assertPath(path);

    var ret = { root: '', dir: '', base: '', ext: '', name: '' };
    if (path.length === 0)
      return ret;
    var code = path.charCodeAt(0);
    var isAbsolute = (code === 47/*/*/);
    var start;
    if (isAbsolute) {
      ret.root = '/';
      start = 1;
    } else {
      start = 0;
    }
    var startDot = -1;
    var startPart = 0;
    var end = -1;
    var matchedSlash = true;
    var i = path.length - 1;

    // Track the state of characters (if any) we see before our first dot and
    // after any path separator we find
    var preDotState = 0;

    // Get non-dir info
    for (; i >= start; --i) {
      code = path.charCodeAt(i);
      if (code === 47/*/*/) {
        // If we reached a path separator that was not part of a set of path
        // separators at the end of the string, stop now
        if (!matchedSlash) {
          startPart = i + 1;
          break;
        }
        continue;
      }
      if (end === -1) {
        // We saw the first non-path separator, mark this as the end of our
        // extension
        matchedSlash = false;
        end = i + 1;
      }
      if (code === 46/*.*/) {
        // If this is our first dot, mark it as the start of our extension
        if (startDot === -1)
          startDot = i;
        else if (preDotState !== 1)
          preDotState = 1;
      } else if (startDot !== -1) {
        // We saw a non-dot and non-path separator before our dot, so we should
        // have a good chance at having a non-empty extension
        preDotState = -1;
      }
    }

    if (startDot === -1 ||
        end === -1 ||
        // We saw a non-dot character immediately before the dot
        preDotState === 0 ||
        // The (right-most) trimmed path component is exactly '..'
        (preDotState === 1 &&
         startDot === end - 1 &&
         startDot === startPart + 1)) {
      if (end !== -1) {
        if (startPart === 0 && isAbsolute)
          ret.base = ret.name = path.slice(1, end);
        else
          ret.base = ret.name = path.slice(startPart, end);
      }
    } else {
      if (startPart === 0 && isAbsolute) {
        ret.name = path.slice(1, startDot);
        ret.base = path.slice(1, end);
      } else {
        ret.name = path.slice(startPart, startDot);
        ret.base = path.slice(startPart, end);
      }
      ret.ext = path.slice(startDot, end);
    }

    if (startPart > 0)
      ret.dir = path.slice(0, startPart - 1);
    else if (isAbsolute)
      ret.dir = '/';

    return ret;
  },


  sep: '/',
  delimiter: ':',
  posix: null
};


module.exports = posix;


/***/ }),

/***/ 372:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isPrototype = __webpack_require__(6060);

module.exports = function (value) {
	if (typeof value !== "function") return false;

	if (!hasOwnProperty.call(value, "length")) return false;

	try {
		if (typeof value.length !== "number") return false;
		if (typeof value.call !== "function") return false;
		if (typeof value.apply !== "function") return false;
	} catch (error) {
		return false;
	}

	return !isPrototype(value);
};


/***/ }),

/***/ 3940:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isValue = __webpack_require__(5618);

// prettier-ignore
var possibleTypes = { "object": true, "function": true, "undefined": true /* document.all */ };

module.exports = function (value) {
	if (!isValue(value)) return false;
	return hasOwnProperty.call(possibleTypes, typeof value);
};


/***/ }),

/***/ 7205:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isFunction = __webpack_require__(372);

var classRe = /^\s*class[\s{/}]/, functionToString = Function.prototype.toString;

module.exports = function (value) {
	if (!isFunction(value)) return false;
	if (classRe.test(functionToString.call(value))) return false;
	return true;
};


/***/ }),

/***/ 6060:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";


var isObject = __webpack_require__(3940);

module.exports = function (value) {
	if (!isObject(value)) return false;
	try {
		if (!value.constructor) return false;
		return value.constructor.prototype === value;
	} catch (error) {
		return false;
	}
};


/***/ }),

/***/ 5618:
/***/ ((module) => {

"use strict";


// ES3 safe
var _undefined = void 0;

module.exports = function (value) { return value !== _undefined && value !== null; };


/***/ }),

/***/ 5348:
/***/ ((module) => {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE__5348__;

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		if(__webpack_module_cache__[moduleId]) {
/******/ 			return __webpack_module_cache__[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			id: moduleId,
/******/ 			loaded: false,
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/compat get default export */
/******/ 	(() => {
/******/ 		// getDefaultExport function for compatibility with non-harmony modules
/******/ 		__webpack_require__.n = (module) => {
/******/ 			var getter = module && module.__esModule ?
/******/ 				() => (module['default']) :
/******/ 				() => (module);
/******/ 			__webpack_require__.d(getter, { a: getter });
/******/ 			return getter;
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/define property getters */
/******/ 	(() => {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = (exports, definition) => {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/global */
/******/ 	(() => {
/******/ 		__webpack_require__.g = (function() {
/******/ 			if (typeof globalThis === 'object') return globalThis;
/******/ 			try {
/******/ 				return this || new Function('return this')();
/******/ 			} catch (e) {
/******/ 				if (typeof window === 'object') return window;
/******/ 			}
/******/ 		})();
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	(() => {
/******/ 		__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/node module decorator */
/******/ 	(() => {
/******/ 		__webpack_require__.nmd = (module) => {
/******/ 			module.paths = [];
/******/ 			if (!module.children) module.children = [];
/******/ 			return module;
/******/ 		};
/******/ 	})();
/******/ 	
/************************************************************************/
/******/ 	// module exports must be returned from runtime so entry inlining is disabled
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(5324);
/******/ })()
.default;
});
//# sourceMappingURL=cozy-sun-bear.js.map