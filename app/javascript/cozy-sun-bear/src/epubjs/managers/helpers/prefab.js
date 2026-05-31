class PrefabViews {
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
		var check = false;
		this.forEach(function(v) {
			if ( v.section.href == view.section.href ) { check = true; }
		})
		if ( check ) { return view; }
		// if ( check ) { console.log("AHOY views.append WUT", view.section.href)}
		this._views.push(view);
		this._views.sort(function(a,b) {return (a.section.href > b.section.href) ? 1 : ((b.section.href > a.section.href) ? -1 : 0);});
		if(this.container && view.element.dataset.reused != 'true'){
			this.container.appendChild(view.element);
		}
		this.length++;
		return view;
	}

	dump() {
		return this._views.map(function(v) { return v.section.href });
	}

	prepend(view){
		this._views.unshift(view);
		if(this.container && view.element.dataset.reused != 'true'){
			this.container.insertBefore(view.element, this.container.firstChild);
		}
		this.length++;
		return view;
	}

	insert(view, index) {
		this._views.splice(index, 0, view);

		if(this.container && view.element.dataset.reused != 'true'){
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

		// if(this.container && view.element.dataset.reused != 'true'){
		// 	 this.container.removeChild(view.element);
		// }
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

export default PrefabViews;
