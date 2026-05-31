import IframeView from "epubjs/src/managers/views/iframe";
import {extend, borders, uuid, isNumber, bounds, defer, createBlobUrl, revokeBlobUrl} from "epubjs/src/utils/core";

class ReusableIframeView extends IframeView {
    constructor(section, options) {
        super(section, options);
        // this._layout.height = null;
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

}

export default ReusableIframeView;
