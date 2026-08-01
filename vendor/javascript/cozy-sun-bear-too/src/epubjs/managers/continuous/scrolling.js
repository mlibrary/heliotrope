import EventEmitter from "event-emitter";
import {extend, defer, windowBounds, isNumber, requestAnimationFrame} from "epubjs/src/utils/core";
import Mapping from "epubjs/src/mapping";
import Queue from "epubjs/src/utils/queue";
import Stage from "epubjs/src/managers/helpers/stage";
import Views from "../helpers/scrolling_views";
import { EVENTS } from "epubjs/src/utils/constants";
import {inVp} from '../../../core/Util';

// import inVp from "in-vp";

class ScrollingContinuousViewManager {
  constructor(options) {

    this.name = "scrolling";
    this.optsSettings = options.settings;
    this.View = options.view;
    this.request = options.request;
    this.renditionQueue = options.queue;
    this.q = new Queue(this);

    this.settings = extend(this.settings || {}, {
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

    extend(this.settings, options.settings || {});

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
    this.settings.scale = this.settings.scale || 1.0;
    this.settings.xscale = this.settings.scale;

    this.fraction = 0.8;
    // this.settings.maxWidth = 1024;
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
    this.stage = new Stage({
      width: size.width,
      height: size.height,
      overflow: this.overflow,
      hidden: this.settings.hidden,
      axis: this.settings.axis,
      fullsize: this.settings.fullsize,
      direction: this.settings.direction,
      scale: 1.0 // this.settings.scale --- scrolling scales different
    });

    this.stage.attachTo(element);

    // Get this stage container div
    this.container = this.stage.getContainer();

    // Views array methods
    this.views = new Views(this.container, this.layout.name == 'pre-paginated');

    // Calculate Stage Size
    this._bounds = this.bounds();
    this._stageSize = this.stage.size();

    var ar = this._stageSize.width / this._stageSize.height;
    // console.log("AHOY STAGE", this._stageSize.width, this._stageSize.height, ">", ar);

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
    this._spine = [];

    this.views.on("view.preload", function({view}) {
      view.display(this.request).then(function() {
        view.show();
      })
    }.bind(this));

    this.views.on("view.display", function({ view, viewportState }) {
      // console.log("AHOY VIEWS scrolling.view.display", view.index);
      view.display(this.request).then(function() {
        view.show();
        this.gotoTarget(view);
        if ( true || this._forceLocationEvent ) {
          this.emit(EVENTS.MANAGERS.SCROLLED, {
            top: this.scrollTop,
            left: this.scrollLeft
          });
          this._forceLocationEvent = false;
        }
      }.bind(this))
    }.bind(this));
  }

  display(section, target) {
    var displaying = new defer();
    var displayed = displaying.promise;

    if ( ! this.views.length ) {
      this.initializeViews(section);
    }

    // Check if moving to target is needed
    if (target === section.href || isNumber(target)) {
      target = undefined;
    }

    var current = this.current();

    this.ignore = false;
    var visible = this.views.find(section);

    // console.log("AHOY scrolling display", section, visible, current, current == visible);

    if(target) {
      this._target = [ visible, target ];
    }

    // --- scrollIntoView is quirkily aggressive on mobile devices
    // visible.element.scrollIntoView();
    if ( visible.element.parentNode ) {
      visible.element.parentNode.scrollTop = visible.element.offsetTop;
    }

    if ( visible == current ) {
      this.gotoTarget(visible);
    }

    displaying.resolve();
    return displayed;
  }

  gotoTarget(view) {
    if ( this._target && this._target[0] == view ) {
      let offset = view.locationOf(this._target[1]);

      // -- this does not work; top varies.
      // offset.top += view.element.getBoundingClientRect().top;

      setTimeout(function() {
        offset.top += this.container.scrollTop;
        this.moveTo(offset);
        this._target = null;
      }.bind(this), 10);

      // var prev; var style;
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

  afterDisplayed(view){
    // if ( this._target && this._target[0] == view ) {
    //   let offset = view.locationOf(this._target[1]);
    //   this.moveTo(offset);
    //   this._target = null;
    // }
    this.emit(EVENTS.MANAGERS.ADDED, view);
  }

  afterResized(view){

    var bounds = this.container.getBoundingClientRect();
    var rect = view.element.getBoundingClientRect();

    this.ignore = true;

    // view.element.dataset.resizable = "true"
    view.reframeElement();

    var delta;
    if ( rect.bottom <= bounds.bottom && rect.top < 0 ) {
      requestAnimationFrame(function afterDisplayedAfterRAF() {
        delta = view.element.getBoundingClientRect().height - rect.height;
        // console.log("AHOY afterResized", view.index, view.element.getBoundingClientRect().height, rect.height, delta);
        this.container.scrollTop += Math.ceil(delta);        
      }.bind(this));
    }

    // the default manager emits EVENTS.MANAGERS.RESIZE when the view is resized
    // which causes the rendition to scroll to display the current location
    // since we've (in theory) adjusted that during the paint frame
    // don't emit
    // -- this.emit(EVENTS.MANAGERS.RESIZE, view.section);
  }

  moveTo(offset) {
    var distX = 0, distY = 0;
    distY = offset.top;
    // this.scrollTo(distX, this.container.scrollTop + distY, true);
    this.scrollTo(distX, distY, false);
  }

  initializeViews(section) {
    var self = this;

    this.ignore = true;

    // if ( self._spine.length == 0 ) {
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

      // if ( this.layout.name == 'pre-paginated' ) {
      //   // do something
      //   // viewSettings.layout.height = h;
      //   // viewSettings.layout.columnWidth = w;

      //   var r = this.layout.height / this.layout.columnWidth;

      //   viewSettings.layout.columnWidth = this.layout.columnWidth * 0.8;
      //   viewSettings.layout.height = this.layout.height * ( this.layout.columnWidth)

      // }
      var viewSettings = Object.assign({}, this.viewSettings);
      viewSettings.layout = Object.assign( Object.create( Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
      if ( this.layout.name == 'pre-paginated' ) {
        viewSettings.layout.columnWidth = this.calcuateWidth(viewSettings.layout.columnWidth); // *= ( this.fraction * this.settings.xscale );
        viewSettings.layout.width = this.calcuateWidth(viewSettings.layout.width); // *= ( this.fraction * this.settings.xscale );
        viewSettings.minHeight *= this.settings.xscale;
        viewSettings.maxHeight = viewSettings.height * this.settings.xscale;
        viewSettings.height = viewSettings.height * this.settings.xscale;
        viewSettings.layout.height = viewSettings.height;
        // console.log("AHOY new view", section.index, viewSettings.height);
      }

      var view = new this.View(section, viewSettings);
      view.onDisplayed = this.afterDisplayed.bind(this);
      view.onResize = this.afterResized.bind(this);
      view.on(EVENTS.VIEWS.AXIS, (axis) => {
        this.updateAxis(axis);
      });
      // view.on('BAMBOOZLE', (e) => {
      //   this.afterResizedBamboozled(view);
      // })
      this.views.append(view);
    }.bind(this));

    this.ignore = false;
  }

  direction(dir="ltr") {
    this.settings.direction = dir;

    this.stage && this.stage.direction(dir);

    this.viewSettings.direction = dir;

    this.updateLayout();
  }

  onOrientationChange(e) {

  }

  onResized(e) {
    // if ( this.resizeTimeout ) {
    //   clearTimeout(this.resizeTimeout);
    // } else {
    //   // this._current = this.current() && this.current().section;
    //   // this._current = { view: this.current(), location: this.currentLocation() };
    // }
    // this.resizeTimeout = setTimeout(this.resize.bind(this), 100);
    this.resize();
  }

  resize(width, height){
    let stageSize = this.stage.size(width, height);
    if ( this.resizeTimeout ) {
      clearTimeout(this.resizeTimeout);
      this.resizeTimeout = null;
    }

    this.ignore = true;

    // For Safari, wait for orientation to catch up
    // if the window is a square
    this.winBounds = windowBounds();
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

    // if ( ! this._resizeTarget ) {
    //   var current = this.current();
    //   if ( current ) {
    //     this._resizeTarget = current.section;
    //   }
    // }

    this.clear();

    // Update for new views
    this.viewSettings.width = this._stageSize.width;
    this.viewSettings.height = this._stageSize.height;

    this.updateLayout();

    // var section; var target;
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

  updateAxis(axis, forceUpdate) {
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
      this.mapping = new Mapping(this.layout.props, this.settings.direction, this.settings.axis);
    }

    if (this.layout) {
      this.layout.spread("none");
    }

  }

  updateFlow(flow) {
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

  getContents() {
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

  current(){
    var visible = this.visible();
    var view;
    if(visible.length){
      // Current is the last visible view
      var current = null;
      for(var i = 0; i < visible.length; i++) {
        view = visible[i];
        const { fully, partially, edges } = inVp(view.element, this.container);
        if ( ! current ) { current = view; current.percentage = edges.percentage; }
        else if ( edges.percentage > current.percentage ) {
          current = view;
          current.percentage = edges.percentage;
        }
      }
      if ( current ) { return current; }
      return visible[visible.length-1];
    }
    return null;
  }

  visible() {
    var visible = [];
    var views = this.views.displayed();
    var viewsLength = views.length;
    var visible = [];
    var isVisible;
    var view;

    return this.views.displayed();

    for(var i = 0; i < viewsLength; i++) {
      view = views[i];
      if ( view.displayed ) {
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

  scrollTo(x, y, silent) {
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

  onScroll() {
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
  }

  updateLayout() {
    if (!this.stage) {
      return;
    }

    this._stageSize = this.stage.size();
    this.layout.calculate(this._stageSize.width, this._stageSize.height);
    // this.layout.width = this.container.offsetWidth * 0.80;

    // Set the dimensions for views
    this.viewSettings.width = this.layout.width; //  * this.settings.scale;
    this.viewSettings.height = this.calculateHeight(this.layout.height);
    this.viewSettings.minHeight = this.viewSettings.height; // * this.settings.scale;

    this.setLayout(this.layout);
  }

  setLayout(layout){

    this.viewSettings.layout = layout;

    this.mapping = new Mapping(layout.props, this.settings.direction, this.settings.axis);

    if(this.views) {

     this.views._views.forEach(function(view) {
        var viewSettings = Object.assign({}, this.viewSettings);
        viewSettings.layout = Object.assign( Object.create( Object.getPrototypeOf(this.viewSettings.layout)), this.viewSettings.layout);
        if ( this.layout.name == 'pre-paginated' ) {
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
      })

      // this.views.forEach(function(view){
      //   if (view) {
      //     view.reframe(layout.width, layout.height);
      //     view.setLayout(layout);
      //   }
      // });

    }

  }

  addEventListeners() {
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

  next() {
    var next;
    var left;

    var displaying = new defer();
    var displayed = displaying.promise;

    let dir = this.settings.direction;

    if(!this.views.length) return;

    this.scrollTop = this.container.scrollTop;

    let top  = this.container.scrollTop + this.container.offsetHeight;

    this.scrollBy(0, this.layout.height, false);

    this.q.enqueue(function() {
      displaying.resolve();
      return displayed;
    })
  }

  prev() {
    var next;
    var left;

    var displaying = new defer();
    var displayed = displaying.promise;

    let dir = this.settings.direction;

    if(!this.views.length) return;

    this.scrollTop = this.container.scrollTop;

    let top  = this.container.scrollTop - this.container.offsetHeight;
    this.scrollBy(0, -this.layout.height, false);

    this.q.enqueue(function() {
      displaying.resolve();
      return displayed;
    })
  }

  clear () {

    // // this.q.clear();

    if (this.views) {
      this.views.hide();
      this.scrollTo(0,0, true);
      this.views.clear();
    }
  }

  currentLocation() {
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

      totalPages = pages.length;

      let mapping = this.mapping.page(view.contents, view.section.cfiBase, startPos, endPos);

      return {
        index,
        href,
        pages,
        totalPages,
        mapping
      };
    });

    if ( sections.length == 0 ) {
      self._forceLocationEvent = true;
    }

    return sections;
  }

  isRendered() {
    return this.rendered;
  }

  scale(s) {
    if ( s == null ) { s = 1.0; }
    this.settings.scale = this.settings.xscale = s;

    // if (this.stage) {
    //   this.stage.scale(s);
    // }

    this.clear();
    this.updateLayout();
    this.emit(EVENTS.MANAGERS.RESIZED, {
      width: this._stageSize.width,
      height: this._stageSize.height
    });
  }

  calcuateWidth(width) {
    var retval = width * this.fraction * this.settings.xscale;
    // if ( retval > this.settings.maxWidth * this.settings.xscale ) {
    //   retval = this.settings.maxWidth * this.settings.xscale;
    // }
    return retval;
  }

  calculateHeight(height) {
    var minHeight = this.layout.name == 'xxpre-paginated' ? 0 : this.settings.minHeight;
    return height > minHeight ? this.layout.height : this.settings.minHeight;
  }

}

ScrollingContinuousViewManager.toString = function() { return 'continuous'; }

//-- Enable binding events to Manager
EventEmitter(ScrollingContinuousViewManager.prototype);

export default ScrollingContinuousViewManager;

