import IframeView from "epubjs/src/managers/views/iframe";
import Contents from "epubjs/src/contents";

import { EVENTS } from "epubjs/src/utils/constants";

import {extend, borders, uuid, isNumber, bounds, defer, createBlobUrl, revokeBlobUrl} from "epubjs/src/utils/core";

class StickyIframeView extends IframeView {
    constructor(section, options) {
        super(section, options);

        this.element.style.height = `${this.layout.height}px`;
        this.element.style.width = `${this.layout.width}px`;
        this.element.style.visibility = "hidden";

        // console.log("AHOY sticky NEW", this.layout.height);
    }

    container(axis) {
        var check = document.querySelector(`div[ref='${this.index}']`);
        if ( check ) {
            check.dataset.reused = 'true';
            return check;
        }

        var element = document.createElement("div");

        element.classList.add("epub-view");

        // this.element.style.minHeight = "100px";
        element.style.height = "0px";
        element.style.width = "0px";
        element.style.overflow = "hidden";
        element.style.position = "relative";
        element.style.display = "block";

        element.setAttribute('ref', this.index);

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

        if ( this.element.hasAttribute('layout-height') ) {
            var height = parseInt(this.element.getAttribute('layout-height'), 10);
            this._layout_height = height;
        }

        this.iframe = this.element.querySelector("iframe");
        if ( this.iframe ) {
            return this.iframe;
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
        this.element.classList.add('epub-view---loading');

        this.iframe.style.width = "0";
        this.iframe.style.height = "0";
        this._width = 0;
        this._height = 0;

        this.element.setAttribute("ref", this.index);
        this.element.setAttribute("data-href", this.section.href);

        // this.element.appendChild(this.iframe);
        this.added = true;

        this.elementBounds = bounds(this.element);

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

    reframe(width, height) {
        var size;

        var minHeight = this.settings.minHeight || 0;
        var maxHeight = this.settings.maxHeight || -1;

        // try to add some padding in the shortest pages
        minHeight *= 0.90;

        // console.log("AHOY AHOY reframe", this.index, width, height);

        if(isNumber(width)){
            this.element.style.width = width + "px";
            if ( this.iframe ) {
                this.iframe.style.width = width + "px";
            }
            this._width = width;
        }

        if(isNumber(height)){
            var checkMinHeight = ( this.settings.layout.name == 'reflowable' );
            height = checkMinHeight && ( height <= minHeight ) ? minHeight : height;

            var styles = window.getComputedStyle(this.element);
            // setting the element height is delayed
            if ( this.iframe ) {
                this.iframe.style.height = height + "px";
            }
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

        this.elementBounds = bounds(this.element);

    }

    queryReframeElement() {
        if ( ! this.iframe ) { return -1; }
        var height = this.iframe.offsetHeight;
        var styles = window.getComputedStyle(this.element);
        var new_height = ( height + parseInt(styles.paddingTop) + parseInt(styles.paddingBottom) )
        return new_height;
    }

    reframeElement() {
        if ( ! this.iframe ) { return; }
        var height = this.iframe.offsetHeight;
        var styles = window.getComputedStyle(this.element);
        var new_height = ( 
            height + 
            parseInt(styles.paddingTop, 10) + 
            parseInt(styles.paddingBottom, 10) + 
            parseInt(styles.borderTopWidth, 10) + 
            parseInt(styles.borderBottomWidth, 10)
        );
        var current_height = this.element.offsetHeight;

        // if this is the first re-load and the height doesn't match the current height
        // DO NOT alter the height because some override is going to be applied
        // which will alter the height.
        this.afterResizeCounter += 1;
        if ( this.unloaded && height != current_height && this.afterResizeCounter == 1 ) { 
            return ; 
        }

        this.element.style.height = `${new_height}px`;
    }

    display(request) {
        var displayed = new defer();

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
        super.show();
        this.element.classList.remove('epub-view---loading');
    }

    hide() {
        super.hide();
    }

    onLoad(event, promise) {

      this.window = this.iframe.contentWindow;
      this.document = this.iframe.contentDocument;

      this.contents = new Contents(this.document, this.document.body, this.section.cfiBase, this.section.index);
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

      this.contents.on(EVENTS.CONTENTS.EXPAND, () => {
        if(this.displayed && this.iframe) {
          this.expand();
          if (this.contents) {
            // console.log("AHOY EXPAND", this.index, this.layout.columnWidth, this.layout.height);
            this.layout.format(this.contents);
          }
        }
      });

      this.contents.on(EVENTS.CONTENTS.RESIZE, (e) => {
        if(this.displayed && this.iframe) {
          this.expand();
          if (this.contents) {
            // console.log("AHOY RESIZE", this.index, this.layout.columnWidth, this.layout.height);
            this.layout.format(this.contents);
          }
        }
      });

      promise.resolve(this.contents);
    }

    unload() {

        for (let cfiRange in this.highlights) {
            this.unhighlight(cfiRange);
        }

        for (let cfiRange in this.underlines) {
            this.ununderline(cfiRange);
        }

        for (let cfiRange in this.marks) {
            this.unmark(cfiRange);
        }

        if (this.pane) {
            this.element.removeChild(this.pane.element);
            this.pane = undefined;
        }

        if (this.blobUrl) {
            revokeBlobUrl(this.blobUrl);
        }

        if(this.displayed){
            this.displayed = false;

            this.removeListeners();

            this.stopExpanding = true;
            this.element.removeChild(this.iframe);
            this.element.style.visibility = "hidden";

            this.unloaded = true;

            this.iframe = undefined;
            this.contents = undefined;

            // this._textWidth = null;
            // this._textHeight = null;
            // this._width = null;
            // this._height = null;
        }

        // this.element.style.height = "0px";
        // this.element.style.width = "0px";
    }

    // setLayout(layout) {
        
    // }

}

export default StickyIframeView;

