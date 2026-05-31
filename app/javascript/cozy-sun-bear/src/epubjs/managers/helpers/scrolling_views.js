import EventEmitter from "event-emitter";

import {inVp} from '../../../core/Util';
window.inVp = inVp;

class Views {
    constructor(container, preloading=false) {
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

    all() {
        return this._views;
    }

    first() {
        // return this._views[0];
        return this.displayed()[0];
    }

    last() {
        var d = this.displayed();
        return d[d.length - 1];
        // return this._views[this._views.length-1];
    }

    prev(view) {
        var index = this.indexOf(view);
        return this.get(index - 1);
    }

    next(view) {
        var index = this.indexOf(view);
        return this.get(index + 1);
    }

    indexOf(view) {
        return this._views.indexOf(view);
    }

    slice() {
        return this._views.slice.apply(this._views, arguments);
    }

    get(i) {
        return i < 0 ? null : this._views[i];
    }

    append(view){
        this._views.push(view);
        if(this.container){
            this.container.appendChild(view.element);
            var threshold = {};
            var h = this.container.offsetHeight;
            threshold.top = - ( h * 0.25 );
            threshold.bottom = - ( h * 0.25 );
            // view.observer = ElementObserver(view.element, {
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

    handleObserver(entries, observer) {
        entries.forEach(entry => {
            var div = entry.target;
            var index = div.getAttribute('ref');
            var view = this.get(index);
            if ( entry.isIntersecting && entry.intersectionRatio > 0.0  ) {
                if ( ! view.displayed ) {
                    console.log("AHOY OBSERVING", entries.length, index, 'onEnter');
                    this.onEnter(view);
                }
            } else if ( view && view.displayed ) {
                console.log("AHOY OBSERVING", entries.length, index, 'onExit');
                this.onExit(view);
            }
        })
    }

    prepend(view){
        this._views.unshift(view);
        if(this.container){
            this.container.insertBefore(view.element, this.container.firstChild);
        }
        this.length++;
        return view;
    }

    // insert(view, index) {
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

    destroy(view) {
        // if(view.displayed){
        //     view.destroy();
        // }
        this.observer.unobserve(view.element);
        view.destroy();

        if(this.container){
             this.container.removeChild(view.element);
        }
        view = null;
    }

    // Iterators

    forEach() {
        // return this._views.forEach.apply(this._views, arguments);
        return this.displayed().forEach.apply(this._views, arguments);
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
        this.observer.disconnect();
    }

    updateLayout(options) {
        var width = options.width;
        var height = options.height;
        this._views.forEach(function(view) {
            view.size(width, height);
            if ( view.contents ) {
                view.contents.size(width, height);
            }
        })
    }

    find(section){

        var view;
        var len = this.length;

        for (var i = 0; i < len; i++) {
            view = this._views[i];
            // view.displayed
            if(view.section.index == section.index) {
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
            const { fully, partially, edges } = inVp(view.element, this.container);
            if ( ( fully || partially ) && edges.percentage > 0 && view.displayed ) {
                displayed.push(view);
            }
            // if(view.displayed){
            //     displayed.push(view);
            // }
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
                // console.log("AHOY VIEWS hide", view.index);
                view.hide();
            }
        }
        this.hidden = true;
    }

    onEnter(view, el, viewportState) {
        // console.log("AHOY VIEWS onEnter", view.index, view.preloaded, view.displayed);
        var preload = ! view.displayed || view.preloaded;
        if ( ! view.displayed ) {
            // console.log("AHOY SHOULD BE SHOWING", view);
            this.emit("view.display", { view: view, viewportState: viewportState });
        }
        if ( this.preloading && preload ) {
            // can we grab the next one?
            this.preload(this.next(view), view.index);
            this.preload(this.prev(view), view.index);
        }
        if ( ! view.displayed && view.preloaded ) {
            // console.log("AHOY VIEWS onEnter TOGGLE", view.index, view.preloaded, view.displayed);
            view.preloaded = false;
        }
    }

    preload(view, index) {
        if ( view && ! view.preloaded ) {
            view.preloaded = true;
            // console.log("AHOY VIEWS preload", index, ">", view.index);
            this.emit("view.preload", { view: view });
        }
    }

    onExit(view, el, viewportState) {
        // console.log("AHOY VIEWS onExit", view.index, view.preloaded);
        if ( view.preloaded ) { return ; }
        view.unload();
    }
}

EventEmitter(Views.prototype);
export default Views;
