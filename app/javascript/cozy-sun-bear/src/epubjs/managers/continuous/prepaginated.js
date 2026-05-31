import {extend, defer, requestAnimationFrame} from "epubjs/src/utils/core";
import DefaultViewManager from "epubjs/src/managers/default";
import ContinuousViewManager from "epubjs/src/managers/continuous/index" ;
import PrefabViews from "../helpers/prefab";

import { EVENTS } from "epubjs/src/utils/constants";
import debounce from "lodash/debounce";

class PrePaginatedContinuousViewManager extends ContinuousViewManager {
    constructor(options) {
    super(options);

    this.name = "prepaginated";

    this._manifest = null;
    this._spine = [];
    this.settings.scale = this.settings.scale || 1.0;
  }

  render(element, size){
    var scale = this.settings.scale;
    this.settings.scale = null; // we don't want the stage to scale
    ContinuousViewManager.prototype.render.call(this, element, size);
    // Views array methods
    // use prefab views
    this.settings.scale = scale;
    this.views = new PrefabViews(this.container);
  }

  onResized(e) {
    if (this.resizeTimeout) {
      clearTimeout(this.resizeTimeout);
    }
    console.log("AHOY PREPAGINATED onResized queued");
    this.resizeTimeout = setTimeout(function() {
      this.resize();
      console.log("AHOY PREPAGINATED onResized actual");
      this.resizeTimeout = null;
    }.bind(this), 500);
    // this.resize();
  }

  resize(width, height) {
    var self = this;

    ContinuousViewManager.prototype.resize.call(this, width, height);
    this._redrawViews();
  }

  _redrawViews() {
    var self = this;
    for(var i = 0; i < self._spine.length; i++) {
      var href = self._spine[i];
      // // console.log("AHOY DRAWING", href);
      var section_ = self._manifest[href];
      // // var r = self.container.offsetWidth / section_.viewport.width;
      // // var h = Math.floor(dim.height * r);
      // var w = self.layout.columnWidth + ( self.layout.columnWidth * 0.10 );
      // var r = w / section_.viewport.width;
      // var h = Math.floor(section_.viewport.height * r);

      var h, w;
      [ w, h ] = self.sizeToViewport(section_);

      var div = self.container.querySelector(`div.epub-view[ref="${section_.index}"]`);
      div.style.width = `${w}px`;
      div.style.height = `${h}px`;
      div.setAttribute('original-height', h);
      div.setAttribute('layout-height', h);

      var view = this.views.find(section_);
      if ( view ) {
          view.size(w, h);
      }
    }
  }

  // RRE - debugging
  createView(section) {

    var view = this.views.find(section);
    if ( view ) {
      return view;
    }

    var w, h;
    [ w, h ] = this.sizeToViewport(section);
    var viewSettings = Object.assign({}, this.viewSettings);
    viewSettings.layout = Object.assign( Object.create( Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
    viewSettings.layout.height = h;
    viewSettings.layout.columnWidth = w;
    var view = new this.View(section, viewSettings);
    return view;
  }

  display(section, target){
    var self = this;
    var promises = [];

    this.q.clear();
    var display = new defer();
    var promises = [];
    this.faking = {};

    if ( ! this._manifest ) {
      this.emit("building");
      self._manifest = {};
      var _buildManifest = function(section_) {
        self._manifest[section_.href] = false;
        if ( self.settings.viewports && self.settings.viewports[section_.href] ) {
          section_.viewport = self.settings.viewports[section_.href];
          self._manifest[section_.href] = section_;
        } else {
          self.q.enqueue(() => {
            section_.load(self.request).then(function(contents) {
              var meta = contents.querySelector('meta[name="viewport"]');
              var value = meta.getAttribute('content');
              var tmp = value.split(",");
              var key = section_.href;
              var idx = self._spine.indexOf(key);
              self.emit("building", { index: idx + 1, total: self._spine.length });
              section_.viewport = {};
              self._manifest[key] = section_;
              // self._manifest[key] = { viewport : {} };
              // self._manifest[key].index = section_.index;
              // self._manifest[key].href = section_.href;
              var viewport_width = tmp[0].replace('width=','');
              var viewport_height = tmp[1].replace('height=','');
              if ( ! viewport_height.match(/^\d+$/) ) {
                viewport_width = viewport_height = 'auto';
              } else {
                viewport_width = parseInt(viewport_width, 10);
                viewport_height = parseInt(viewport_height, 10);
              }
              self._manifest[key].viewport.width = viewport_width;
              self._manifest[key].viewport.height = viewport_height;
              self.faking[key] = self._manifest[key].viewport;
            })
          });
        }
      }

      // can we build a manifest here?
      var prev_ = section.prev();
      while ( prev_ ) {
        self._spine.unshift(prev_.href);
        _buildManifest(prev_);
        prev_ = prev_.prev();
      }

      self._spine.push(section.href);
      _buildManifest(section);

      var next_ = section.next();
      while ( next_ ) {
        self._spine.push(next_.href);
        _buildManifest(next_);
        next_ = next_.next();
      }

      console.log("AHOY PRE-PAGINATED", promises.length);
    }

    var _display = function() {

      var check = document.querySelector('.epub-view');
      if ( ! check ) {
        self._max_height = self._max_viewport_height = 0;
        self._max_width = self._max_viewport_width = 0;
        console.log("AHOY DRAWING", self._spine.length);
        for(var i = 0; i < self._spine.length; i++) {
          var href = self._spine[i];
          var section_ = self._manifest[href];
          var w, h;
          [w, h] = self.sizeToViewport(section_);

          self.container.innerHTML += `<div class="epub-view" ref="${section_.index}" data-href="${section_.href}" style="width: ${w}px; height: ${h}px; text-align: center; margin-left: auto; margin-right: auto"></div>`;
          var div = self.container.querySelector(`div.epub-view[ref="${section_.index}"]`);
          // div.setAttribute('use-')
          div.setAttribute('original-height', h);
          div.setAttribute('layout-height', h);

          if ( window.debugManager ) {
            div.style.backgroundImage = `url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 32' width='300' height='32'%3e%3cstyle%3e.small %7b fill: rgba(0,0,0,0.3);%7d%3c/style%3e%3ctext x='0' y='25' class='small'%3e${section_.href}%3c/text%3e%3c/svg%3e")`;
            var colorR = Math.floor(Math.random() * 100).toString();
            var colorG = Math.floor(Math.random() * 100).toString();
            var colorB = Math.floor(Math.random() * 100).toString();
            div.style.backgroundColor = `#${colorR}${colorG}${colorB}`;
          }
        }
      }

      // find the <div> with this section
      // console.log("AHOY continuous.display START", section.href);
      var div = self.container.querySelector(`div.epub-view[ref="${section.index}"]`);
      div.scrollIntoView();

      // this.q.clear();
      // return check ? this.update() : this.check();
      // var retval = check ? this.update() : this.check();
      var retval = this.check();
            console.log("AHOY DISPLAY", check ? "UPDATE" : "CHECK", retval);
      retval.then(function() {
        this.q.clear();
                console.log("AHOY MANAGER BUILT");
        this.emit("built");
        return display.resolve();
      }.bind(this));

      // return DefaultViewManager.prototype.display.call(this, section, target)
      //  .then(function () {
      //    return this.fill();
      //  }.bind(this));

            return retval;
    }.bind(this);

    // // promises.push(_display);
    // while(promises.length) {
    //  this.q.enqueue(promises.shift);
    // }

    // console.log("AHOY PREPAGINATED", this.q._q.length);
    // this.q.enqueue().then((result) => {
    //  display.resolve();
    // })

    var q = function() {
      return this.q.enqueue((result) => {
        var waiting = 0;
        for(var i = 0; i < self._spine.length; i++) {
          var href = self._spine[i];
          var has_section = self._manifest[href];
          if ( has_section == false ) { waiting += 1; }
        }
        // console.log("AHOY PRE-PAGINATED WAITING", waiting);
        if ( waiting == 0 ) {
          return _display();
        } else {
          q();
        }
      })
    }.bind(this);

    return q();

    return display.promise;

  }

  _checkStillLoading() {
    this.q.enqueue((result) => {
      var waiting = 0;
      for(var i = 0; i < self._spine.length; i++) {
        var href = self._spine[i];
        var has_section = self._manifest[href];
        if ( has_section == false ) { waiting += 1; }
      }
      console.log("AHOY PRE-PAGINATED WAITING", waiting);
      if ( waiting == 0 ) {
        return _display();
      } else {
        q();
      }
    })
  }

  fill(_full) {
    var full = _full || new defer();

    this.q.enqueue(() => {
      return this._checkStillLoading();
    }).then((result) => {
      if (result) {
        this.fill(full);
      } else {
        full.resolve();
      }
    });

    return full.promise;
  }

  fillXX(_full){
    var full = _full || new defer();

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
      offsetY = offset.top+this.settings.offset;
    } else {
      distX = Math.floor(offset.left / this.layout.delta) * this.layout.delta;
      offsetX = distX+this.settings.offset;
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
      // do not do this
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

  prepend(section){
    var view = this.createView(section);

    view.on(EVENTS.VIEWS.RESIZED, (bounds) => {
      this.counter(bounds);
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

  counter(bounds){
    // return;
    if(this.settings.axis === "vertical") {
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

  updateXXX(_offset) {
    var offset = horizontal ? this.scrollLeft : this.scrollTop * dir;
    var visibleLength = horizontal ? bounds.width : bounds.height;
    var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

    var divs = document.querySelectorAll('.epub-view');
    var visible = [];
    for(var i = 0; i < divs.length; i++) {
      var div = divs[i];
      var rect = div.getBoundingClientRect();
      var marker = '';
      // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
      // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {
      if ( offset < ( div.offsetTop + rect.height ) && ( offset + bounds.height ) > div.offsetTop ) {
        marker = '**';
        var section = this._manifest[div.dataset.href];
        visible.push(section);
        // if ( ! div.querySelector('iframe') ) {
        //  newViews.push(this.append(section))
        // }
        // var idx = this._spine.indexOf(section.href);
        // if ( idx > 0 ) {
        //  visible.push(this._manifest[this._spine[idx - 1]]);
        // }
        // if ( idx < this._spine.length - 1 ) {
        //  visible.push(this._manifest[this._spine[idx + 1]]);
        // }
      }
      // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);
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

    var updating = new defer();
    var promises = [];
    var queued = {};
    for (var i = 0; i < viewsLength; i++) {
      view = views[i];

      isVisible = this.isVisible(view, offset, offset, container);
      if ( isVisible === true ) {
        queued[i] = true;
      }
    }

    for(var i = 0; i < viewsLength; i++) {
      view = views[i];
      var isVisible = queued[i];
      if(isVisible === true) {
        // console.log("visible " + view.index);

        if (!view.displayed) {
          // console.log("AHOY continuous.update !displayed", view.section.href);
          let displayed = view.display(this.request)
            .then(function (view) {
              view.show();
            }, (err) => {
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
    var checking = new defer();
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
    var visibleLength = horizontal ? bounds.width : bounds.height;
    var contentLength = horizontal ? this.container.scrollWidth : this.container.scrollHeight;

    var prePaginated = this.layout.props.name == 'pre-paginated';

    // console.log("continuous.check prePaginated =", prePaginated, "offset=",
    //  offset, "visibleLength =", visibleLength, "delta=", delta, ` (${offset + visibleLength + delta})`, " >= contentLength =", contentLength,
    //  " == ", offset + visibleLength + delta >= contentLength,
    //  " || ", offset - delta, "<", 0, " == ", offset - delta < 0 );

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

    var adjusted_top = offset - ( bounds.height * 8 );
    var adjusted_end = offset + ( bounds.height * 8 );
    // console.log("AHOY check", offset, "-", offset + bounds.height, "/", adjusted_top, "-", adjusted_end);

    // need to figure out which divs are viewable
    var divs = document.querySelectorAll('.epub-view');
    var visible = [];
    for(var i = 0; i < divs.length; i++) {
      var div = divs[i];
      var rect = div.getBoundingClientRect();
      var marker = '';
      // if ( rect.top > offset + bounds.height && ( rect.top + rect.height ) <= offset ) {
      // if ( adjusted_top < ( div.offsetTop + rect.height ) && adjusted_end > div.offsetTop ) {
      if ( offset < ( div.offsetTop + rect.height ) && ( offset + bounds.height ) > div.offsetTop ) {
        marker = '**';
        var section = this._manifest[div.dataset.href];
        visible.push(section);
        // if ( ! div.querySelector('iframe') ) {
        //  newViews.push(this.append(section))
        // }
        // var idx = this._spine.indexOf(section.href);
        // if ( idx > 0 ) {
        //  visible.push(this._manifest[this._spine[idx - 1]]);
        // }
        // if ( idx < this._spine.length - 1 ) {
        //  visible.push(this._manifest[this._spine[idx + 1]]);
        // }
      }
      // console.log("AHOY", div.dataset.href, rect.top, rect.height, "/", div.offsetTop, div.offsetHeight, "/", offset, bounds.height, marker);
    }

    this.__check_visible = visible;

    var section = visible[0];
    if ( section && section.index > 0 ) {
      visible.unshift(this._manifest[this._spine[section.index - 1]]);
    }
    if ( section ) {
      var tmp = this._spine[section.index + 1];
      if ( tmp ) {
        visible.push(this._manifest[tmp]);
      }
    }
    // if ( section && section.prev() ) {
    //  visible.unshift(section.prev());
    // }
    // section = visible[visible.length - 1];
    // if (section && section.next() ) {
    //  visible.push(section.next());
    // }

    for(var i = 0; i < visible.length; i++) {
      var section = visible[i];
      // var div = document.querySelector(`.epub-view[ref="${section.index}"]`);
      // if ( div.querySelector('iframe') ) {
      //  continue;
      // }
      newViews.push(this.append(section));
    }

    // let promises = newViews.map((view) => {
    //  return view.displayed;
    // });

    var promises = [];
    for(var i = 0; i < newViews.length; i++) {
      if ( newViews[i] ) {
        promises.push(newViews[i]);
      }
    }

    if(newViews.length){
      return Promise.all(promises)
        .then(() => {
          // return this.check();
          // if (this.layout.name === "pre-paginated" && this.layout.props.spread && this.layout.flow() != 'scrolled') {
          //   // console.log("AHOY check again");
          //   return this.check();
          // }
        })
        .then(() => {
          // Check to see if anything new is on screen after rendering
          // console.log("AHOY update again");
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
    var task = new defer();
    var displayed = this.views.displayed();
    var first = displayed[0];
    var last = displayed[displayed.length-1];
    var firstIndex = this.views.indexOf(first);
    var lastIndex = this.views.indexOf(last);
    var above = this.views.slice(0, firstIndex);
    var below = this.views.slice(lastIndex+1);

    // Erase all but last above
    for (var i = 0; i < above.length-3; i++) {
      if ( above[i] ) {
        // console.log("AHOY trim > above", first.section.href, ":", above[i].section.href);
        this.erase(above[i], above);
      }
    }

    // Erase all except first below
    for (var j = 3; j < below.length; j++) {
      if ( below[j] ) {
        // console.log("AHOY trim > below", last.section.href, ":", below[j].section.href);
        this.erase(below[j]);
      }
    }

    task.resolve();
    return task.promise;
  }

  erase(view, above){ //Trim

    var prevTop;
    var prevLeft;

    if(this.settings.height) {
      prevTop = this.container.scrollTop;
      prevLeft = this.container.scrollLeft;
    } else {
      prevTop = window.scrollY;
      prevLeft = window.scrollX;
    }

    var bounds = view.bounds();

    // console.log("AHOY erase", view.section.href, above);
    this.views.remove(view);

    if(above) {
      if(this.settings.axis === "vertical") {
        // this.scrollTo(0, prevTop - bounds.height, true);
      } else {
        this.scrollTo(prevLeft - bounds.width, 0, true);
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
  }

  addScrollListeners() {
    var scroller;

    this.tick = requestAnimationFrame;

    if(this.settings.height) {
      this.prevScrollTop = this.container.scrollTop;
      this.prevScrollLeft = this.container.scrollLeft;
    } else {
      this.prevScrollTop = window.scrollY;
      this.prevScrollLeft = window.scrollX;
    }

    this.scrollDeltaVert = 0;
    this.scrollDeltaHorz = 0;

    if(this.settings.height) {
      scroller = this.container;
      this.scrollTop = this.container.scrollTop;
      this.scrollLeft = this.container.scrollLeft;
    } else {
      scroller = window;
      this.scrollTop = window.scrollY;
      this.scrollLeft = window.scrollX;
    }

    scroller.addEventListener("scroll", this.onScroll.bind(this));
    this._scrolled = debounce(this.scrolled.bind(this), 30);
    // this.tick.call(window, this.onScroll.bind(this));

    this.didScroll = false;

  }

  removeEventListeners(){
    var scroller;

    if(this.settings.height) {
      scroller = this.container;
    } else {
      scroller = window;
    }

    scroller.removeEventListener("scroll", this.onScroll.bind(this));
  }

  onScroll(){
    let scrollTop;
    let scrollLeft;
    let dir = this.settings.direction === "rtl" ? -1 : 1;

    if(this.settings.height) {
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


    this.didScroll = false;

  }

  scrolled() {
    this.q.enqueue(function() {
      this.check();
      this.recenter();
      setTimeout(function() {
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

  next(){

    let dir = this.settings.direction;
    let delta = this.layout.props.name === "pre-paginated" &&
                this.layout.props.spread ? this.layout.props.delta * 2 : this.layout.props.delta;

    delta = this.container.offsetHeight / this.settings.scale;

    if(!this.views.length) return;

    if(this.isPaginated && this.settings.axis === "horizontal") {

      this.scrollBy(delta, 0, true);

    } else {

      // this.scrollBy(0, this.layout.height, true);
      this.scrollBy(0, delta, true);

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

  recenter() {
    var wrapper = this.container.parentElement;
    var w3 = ( wrapper.scrollWidth / 2 ) - ( wrapper.offsetWidth / 2 );
    wrapper.scrollLeft = w3;
  }

  sizeToViewport(section) {
    var h = this.layout.height;
    // reduce to 80% to avoid hacking epubjs/layout.js
    var w = this.layout.columnWidth * 0.8 * this.settings.scale;
    if ( section.viewport.height != 'auto' ) {
      if ( this.layout.columnWidth > section.viewport.width ) {
        w = section.viewport.width * this.settings.scale;
      }
      var r = w / section.viewport.width;
      h = Math.floor(section.viewport.height * r);
    }
    return [w, h];
  }

  sizeToViewport_X(section) {
    var h = this.layout.height;
    var w = this.layout.columnWidth * 0.80;

    if ( section.viewport.height != 'auto' ) {

      var r = w / section.viewport.width;
      h = section.viewport.height * r;
      var f = 1 / 0.60;
      var m = Math.min(( f * this.layout.height ) / h, 1.0);
      console.log("AHOY SHRINKING", `( ${f} * ${this.layout.height} ) / ${h} = ${m} :: ${h * m}`);
      h *= m;

      h *= this.settings.scale;
      if ( h > section.viewport.height ) {
        h = section.viewport.height;
      }

      r = h / section.viewport.height;
      w = section.viewport.width * r;

      h = Math.floor(h);
      w = Math.floor(w);
    }
    return [w, h];
  }

  scale(scale) {
    var self = this;
    this.settings.scale = scale;
    var current = this.currentLocation();
    var index = -1;
    if ( current[0] ) {
      index = current[0].index; 
    }

    this.views.hide();
    this.views.clear();
    this._redrawViews();
    this.views.show();
    setTimeout(function() {
      console.log("AHOY JUMPING TO", index);
      if ( index > -1 ) {
        var div = self.container.querySelector(`div.epub-view[ref="${index}"]`);
        div.scrollIntoView(true);
      }
      this.check().then(function() {
        this.onScroll();
      }.bind(this))
    }.bind(this), 0);
  }

  resetScale() {
    // NOOP
  }

}

PrePaginatedContinuousViewManager.toString = function() { return 'prepaginated'; }

export default PrePaginatedContinuousViewManager;

