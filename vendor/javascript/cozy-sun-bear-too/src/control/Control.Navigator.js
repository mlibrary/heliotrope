import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Navigator = Control.extend({
  onAdd: function(reader) {
    var container = this._container;
    if ( container ) {
    } else {

      var className = this._className('navigator'),
          options = this.options;
      
      container = DomUtil.create('div', className);
    }
    this._setup(container);

    this._reader.on('updateLocations', function(locations) {      
      this._initializeNavigator(locations);
    }.bind(this));

    return container;
  },

  _setup: function(container) {
    this._control = container.querySelector("input[type=range]");
    if ( ! this._control ) {
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

  _createControl: function (container) {
    var template = `<div class="cozy-navigator-range">
        <label class="u-screenreader" for="cozy-navigator-range-input">Location: </label>
        <input class="cozy-navigator-range__input" id="cozy-navigator-range-input" type="range" name="locations-range-value" min="0" max="100" step="1" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" aria-valuetext="0% • Location 0 of ?" value="0" data-background-position="0" />
        <div class="cozy-navigator-range__background"></div>
      </div>
      <div class="cozy-navigator-range__status"><span class="currentPercentage">0%</span><span> • </span><span>Location <span class="currentLocation">0</span> of <span class="totalLocations">?</span><span class="currentPageLabel"></span></span></div>
    `;

    template = `<div class="cozy-navigator-range">
      <form>
        <label class="u-screenreader" for="cozy-navigator-range-input">Location: </label>
        <div class="cozy-navigator-range__background">
          <input class="cozy-navigator-range__input" id="cozy-navigator-range-input" type="range" name="locations-range-value" min="0" max="100" step="1" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" aria-valuetext="0% • Location 0 of ?" value="0" data-background-position="0" />
        </div>
      </form>
      </div>
      <div class="cozy-navigator-range__status"><span class="currentPercentage">0%</span><span> • </span><span>Location <span class="currentLocation">0</span> of <span class="totalLocations">?</span><span class="currentPageLabel"></span></span></div>`;

    var body = new DOMParser().parseFromString(template, "text/html").body;
    while ( body.children.length ) {
      container.appendChild(body.children[0]);
    }

    this._control = container.querySelector("input[type=range]");
  },

  _bindEvents: function() {
    var self = this;
    var isIE = window.navigator.userAgent.indexOf("Trident/") > -1;

    this._control.addEventListener("input", function() {
      if ( self._keyDown ) { self._keyDown = false; return; }
      self._update(false);
    }, false);
    this._control.addEventListener("change", function(event) { 
      if ( self._mouseDown ) { 
        if ( isIE ) { self._update(false); }
        return;
      }
      self._action(); 
    }, false);
    this._control.addEventListener("mousedown", function(event){
        self._mouseDown = true;
        self._container.classList.add('updating');
    }, false);
    this._control.addEventListener("mouseup", function(){
        self._mouseDown = false;
        self._container.classList.remove('updating');
        if ( isIE ) { self._action(); return; }
        self._update();
    }, false);
    this._control.addEventListener("keydown", function(event) {
      if ( event.key == 'ArrowLeft' || event.key == 'ArrowRight' ) {
        // do not fire input events if we're just keying around
        self._keyDown = true;
      }
    }, false);
    this._control.addEventListener("keyup", function(){
      // self._mouseDown = false;
    }, false);
  },

  _action: function() {
    var value = parseInt(this._control.value, 10);
    var cfi;
    var locations = this._reader.locations;
    if ( locations.cfiFromLocation ) {
      cfi = locations.cfiFromLocation(value);
    } else {
      // hopefully short-term compatibility
      var percent = value / this._total;
      cfi = locations.cfiFromPercentage(percent);
    }
    this._reader.tracking.action("navigator/go");
    // this._ignore = true;
    if ( this._watching == 'updateLocation' ) {
      setTimeout(() => {
        this._update();
      }, 100);
    }
    this._reader.gotoPage(cfi);
  },

  _update: function(current) {
    var self = this;

    var value = parseFloat(this._control.value, 10);
    var current_location = value;

    var max = parseFloat(this._control.max, 10);
    var percentage = (( value / max ) * 100.0)

    // this._background.setAttribute('style', 'background-position: ' + (-percentage) + '% 0%, left top;');
    var fill = this._fill; // '#2497e3';
    var end = this._end; // '#ffffff';
    this._control.style.background = `linear-gradient(to right, ${fill} 0%, ${fill} ${percentage}%, ${end} ${percentage}%, ${end} 100%)`;
    percentage = Math.ceil(percentage);
    this._spanCurrentPercentage.innerHTML = percentage + '%';

    this._control.setAttribute('data-background-position', percentage);
    this._spanCurrentLocation.innerHTML = ( current_location );

    var current_page = '';
    if ( this._reader.pageList ) { // && current !== false
      var pages;
      if ( typeof(current) != 'object' ) {
        var cfi = this._reader.locations.cfiFromLocation(current_location);
        pages = [ this._reader.pageList.pageFromCfi(cfi) ];
      } else {
        pages = this._reader.pageList.pagesFromLocation(current); 
      }
      var pageLabels = [];
      var label = 'p.';
      if ( pages.length ) {
        var p1 = pages.shift();
        pageLabels.push(this._reader.pageList.pageLabel(p1));
        if ( pages.length ) {
          var p2 = pages.pop();
          pageLabels.push(this._reader.pageList.pageLabel(p2));
          label = 'pp.';
        }
      }
      if ( pageLabels.length ) {
        current_page = ` (${label} ${pageLabels.join('-')})`;
      }
      this._spanCurrentPageLabel.innerHTML = current_page;
    }

    this._control.setAttribute('aria-valuenow', value);
    this._control.setAttribute('aria-valuetext', `${percentage}% • Location ${current_location} of ${this._total}${current_page}`);

    // var message = `Location ${current_location}; ${percentage}%${current_page}`;
    // this._reader.updateLiveStatus(message);
  },

  _initializeNavigator: function(locations) {
    var self = this;

    this._initiated = true;

    this._fill = window.getComputedStyle(this._background, ':before').getPropertyValue('background-color');
    this._end = window.getComputedStyle(this._background, ':after').getPropertyValue('background-color');

    if ( ! this._reader.pageList ) {
      this._spanCurrentPageLabel.style.display = 'none';
    }

    this._total = this._reader.locations.total;
    var max = this._total; var min = 1;
    if ( this._reader.locations.spine ) { max -= 1; min -= 1; }
    this._control.max = max;
    this._control.min = min;

    var current = this._reader.currentLocation();
    var value = this._parseLocation(current);
    this._control.value = value;
    this._last_value = this._control.value
    this._update(current);

    this._spanTotalLocations.innerHTML = this._total;

    if ( this._reader.locations.cfiFromLocation ) {
      this._watching = 'relocated';
      this._reader.on('relocated', function(location) {
        self._handle_relocated(location);
      });
    } else {
      // BACK COMPATIBILITY
      this._watching = 'updateLocation';
      this._reader.on('updateLocation', function(location) {
        console.log("AHOY NAVIGATOR updateLocation", location);
        self._handle_relocated(location);
      });
    }

    setTimeout(function() {
      DomUtil.addClass(this._container, 'initialized');
    }.bind(this), 0);
  },

  _handle_relocated: function(location) {
    var self = this;

    var value; var percentage;
    if ( ! self._initiated ) { return ; }
    if ( ! ( location && location.start ) ) { return ; }

    var value;
    if ( location.start && location.end ) {
      // EPUB
      value = parseInt(self._control.value, 10);
      var start = parseInt(location.start.location, 10);
      var end = parseInt(location.end.location, 10);

      if ( start == this._last_location_start && end == this._last_location_end ) {
        return;
      }

      this._last_location_start = start; this._last_location_end = end;

      // console.log("AHOY NAVIGATOR relocated", value, start, end, value < start, value > end);
      if ( value < start || value > end ) {
        self._last_value = value;
        self._control.value = ( value < start ) ? start : end;
      }
    } else {
      value = self._parseLocation(location);

      if ( value == this._last_value ) { return ; }

      self._last_value = value;
      self._control.value = value;
    }

    self._update(location);
    // var message = `Location ${current_location}; ${percentage}%${current_page}`;
    var message = this._control.getAttribute('aria-valuetext');
    this._reader.updateLiveStatus(message);
  },

  _parseLocation: function(location) {
    var self = this;
    var value;

    function handle_possible_pdf_location(location) {
      var start = location.start.cfi ? location.start.cfi : location.start;
      if ( typeof(start) == 'string' && start.indexOf('page=') > -1 ) {
        // dumb
        start = start.replace('epubcfi(page=','').replace(')', '');
      }
      return start;
    }

    if ( typeof(location.start) == 'undefined' ) {
        // If the window is being resized while the reader is still loading an EPUB chapter, then...
        // `location.start` will be undefined here. This causes the reader to appear to load forever.
        // I _think_ this is going to be a rarity in the wild, although clicking the full screen...
        // button too soon will also cause it. Also, it's actually very likely to happen when a ...
        // developer opens a "docked" dev tools dialog while CSB is loading a complex chapter.
        // In this event starting from scratch with a page reload seems like the best move.
        // Anything else causes a recursive, asynchronous mess.
        console.log("AHOY NAVIGATOR location lost. Window resized while loading? Reloading page.");
        window.location.reload(); // errors may still appear in the console before the reload occurs
    }
    else if ( typeof(location.start) == 'object' ) {
      if ( location.start.location != null ) {
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

export var navigator = function(options) {
  return new Navigator(options);
}
