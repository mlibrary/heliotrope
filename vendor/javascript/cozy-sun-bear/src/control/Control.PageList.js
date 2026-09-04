import {Control} from './Control';

export var PageList = Control.extend({
  defaultTemplate: `
<form class="cozy-page-list-form">
  <label class="u-screenreader" for="cozy-page-list-pagenum">Page Number</label>
  <input type="text" size="8" id="cozy-page-list-pagenum" placeholder="page number" autocomplete="off" />
  <button class="button--sm" type="submit">Go</button>
</form>`.trim(),

  onAdd: function(reader) {
    var container = document.createElement('div');
    container.className = this._className();
    container.style.display = 'none';
    container.setAttribute('aria-hidden', 'true');
    var body = new DOMParser().parseFromString(this.options.template || this.defaultTemplate, 'text/html').body;
    while (body.children.length) {
      container.appendChild(body.children[0]);
    }

    this._form = container.querySelector('form');
    this._input = this._form.querySelector('input[type="text"]');
    this._button = this._form.querySelector('button');
    this._bindEvents();
    return container;
  },

  _bindEvents: function() {
    this._form.addEventListener('submit', function(event) {
      event.preventDefault();
      this._goToPage();
    }.bind(this));

    this._reader.on('updateLocations', function() {
      if (!this._reader.pageList) {
        this._input.disabled = true;
        this._button.disabled = true;
        return;
      }

      this._container.style.display = '';
      this._container.setAttribute('aria-hidden', 'false');
      this._input.disabled = false;
      this._button.disabled = false;
    }.bind(this));
  },

  _goToPage: function() {
    if (!this._reader.pageList) {
      return false;
    }

    var value = this._input.value.trim();
    var page = value && this._reader.pageList.pageList.find(function(item) {
      return item.pageLabel == value;
    });

    if (!page) {
      var message = `Please enter a page number between ${this._reader.pageList.firstPageLabel}-${this._reader.pageList.lastPageLabel}.`;
      window.alert(message);
      this._reader.updateLiveStatus(message);
      return false;
    }

    this._reader.display(this._reader.pageList.cfiFromPage(page.page));
    return true;
  },

  EOT: true
});

export var pageList = function(options) {
  return new PageList(options);
};






