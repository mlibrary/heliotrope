import {Control} from './Control';
import {Reader} from '../reader/Reader';
import * as DomUtil from '../dom/DomUtil';
import * as DomEvent from '../dom/DomEvent';

export var Search = Control.extend({
  options: {
    label: 'Search',
    html: '<span>Search</span>'
  },

  defaultTemplate: `<button class="button--sm" data-toggle="open" aria-label="Search"><i class="icon-magnifying-glass oi" data-glyph="magnifying-glass" title="Search" aria-hidden="true"></i></button>`,

  onAdd: function(reader) {
    var self = this;
    var container = this._container;
    if ( container ) {
      //this._control = container.querySelector("[data-target=" + this.options.direction + "]");
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

    this._reader.on('updateContents', function(data) {
      self._createPanel();
    });

    this._control = container.closest("[data-toggle=open]") || container.querySelector('[data-toggle="open"]');
    this._control.setAttribute('id', 'action-' + this._id);
    this._control.setAttribute("data-modal-open", "");
    container.style.position = 'relative';
    DomEvent.on(this._control, 'click', function(event) {
      event.preventDefault();
      // HELIO-4287 "action" modal-opening buttons should both open *and* close their associated modal, and close others when opening.
      // use `aria-hidden` state to check open/close status of this modal. Seems weird but I think it's used this way elsewhere also.
      if (self._modal.modal.getAttribute('aria-hidden') == 'false') {
        // if it's visible, close it and return
        this._modal.deactivate();
        return;
      } else {
        // we're going to open this modal. Look for any currently-open modals to close first.
        var open_modals_close_buttons = self._modal.container.ownerDocument.querySelectorAll('.cozy-modal[aria-hidden="false"] button[data-modal-close]');
          // console.log(open_modals_close_buttons);
          open_modals_close_buttons.forEach((button) => {
            button.click();
          });
      }
      
      self._modal.activate();
    }, this)

    return container;
  },

  _createPanel: function() {
    var self = this;

    console.log("-- control.contents modal", self.options);
    this._modal = this._reader.modal({
      template: `
  <div class="cozy-search">
    <form class="search">
      <label class="u-screenreader" for="cozy-search-string">Search in this text</label>
      <input id="cozy-search-string" name="search" type="text" placeholder="Search in this text..." />
      <button class="button--sm" data-toggle="open" aria-label="Search" type="submit"><i class="icon-magnifying-glass oi" data-glyph="magnifying-glass" title="Search" aria-hidden="true"></i></button>
    </form>
  </div>
<article></article>`,
      title: 'Search',
      className: { container: 'cozy-modal-search' },
      region: 'left',
      modalContainer: self.options.modalContainer,
      seriously: 'wtf'
    });

    this._modal.callbacks.onClose = function() {
      if ( self._processing ) {
        self._canceled = true;
      }
    };

    this._article = this._modal._container.querySelector('article');

    this._modal.on('click', '.cozy-search form button', function(modal, target) {

      var form = target.parentNode;
      var searchString = form.querySelector('input[type="text"]').value;
      searchString = searchString.replace(/^\s*/, '').replace(/\s*$/, '');
      if ( ! searchString ) {
        // just punt
        return;
      }

      if ( searchString == this.searchString ) {
        // cached results
        self.openModalResults();
      } else {
        this.searchString = searchString;
        self.openModalWaiting();
        self.submitQuery(searchString);
      }
    }.bind(this));
    
    this._modal.on('click', 'a[class="search-result"]', function(modal, target) {
      target = target.getAttribute('href');
      this._reader.tracking.action('search/go/link');
      this._reader.display(target, function() {
        // return focus to epub iframe, CSB-259
        document.getElementsByTagName("iframe")[0].focus();
      });
      if ( this.options.closePanel === false ) {
        return false;
      }
      return true;
    }.bind(this));

    this._modal.on('click', 'a[class="feedback-link"]', function(modal, target) {
      window.open(target.href, '_blank');
    }.bind(this));

    this._modal.on('closed', function() {
      this._reader.tracking.action('contents/close');
    }.bind(this))

    // only add locations when they've been processed
    this._reader.on('updateLocations', function() {
      this._addLocation = true;
    }.bind(this));

    window.addEventListener('keydown', function(evt) {
      let cmd = (evt.ctrlKey ? 1 : 0) |
                (evt.altKey ? 2 : 0) |
                (evt.shiftKey ? 4 : 0) |
                (evt.metaKey ? 8 : 0);

      if (cmd === 1 || cmd === 8 || cmd === 5 || cmd === 12) {
        if ( evt.keyCode == '70' ) {
          // command/control-F
          evt.preventDefault();
          this._container.querySelector("#cozy-search-string").focus();
        }
      }
    }.bind(this));

  },

  openModalWaiting: function() {
    this._processing = true;
    this._emptyArticle();
    var value = this.searchString;
    this._article.innerHTML = '<p>Submitting query for <em>' + value + '</em>...</p>' + this._reader.loaderTemplate();
    //this._modal.activate();
  },

  openModalResults: function() {
    if ( this._canceled ) {
      this._canceled = false;
      return;
    }
    this._buildResults();
    //this._modal.activate();
    this._reader.tracking.action("search/open");
  },

  submitQuery: function() {
    var self = this;

    var url = this.options.searchUrl + encodeURIComponent(this.searchString);

    var request = new XMLHttpRequest();
    request.open('GET', url, true);

    request.onload = function() {
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

    request.onerror = function() {
      // There was a connection error of some sort
      self._data = null;
      self.openModalResults();
    };

    request.send();

  },

  _emptyArticle: function() {
    while (this._article && this._article.hasChildNodes()) {
      this._article.removeChild(this._article.lastChild);
    }
  },

  _buildResults: function() {
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
    var feedback_text = 'Not finding what you\'re looking for? '
    feedback = DomUtil.create("p")
    feedback.textContent = feedback_text;
    feedback.appendChild(feedback_link); 
    
    this._processing = false;

    self._emptyArticle();

    var reader = this._reader;
    reader.annotations.reset();

    if ( this._data ) {
      var highlight = true
      if (this._data.highlight_off == "yes") {
        highlight = false;
      }
      content = DomUtil.create('div');
      if ( this._data.search_results.length == 0) {
        no_results = DomUtil.create("p")
        no_results.textContent = 'No results found for "' + self.searchString + '"';
        content.appendChild(no_results);
        content.appendChild(feedback);
      } else {
        content.appendChild(feedback);

        results_list = DomUtil.create('ol'); 
        this._data.search_results.forEach(function(result) {
          var option = DomUtil.create('li');
          var anchor = DomUtil.create('a', null, option);
          var cfiRange = "epubcfi(" + result.cfi + ")";

          if (result.snippet) {
            // results for epubs
            if ( self._addLocation ) {
              var loc = reader.locations.locationFromCfi(cfiRange);
              var locText = "Location " + loc + " • ";
              if (cfiRange.match(/^epubcfi\(page/)) {
                // results for pdfs
                // see heliotrope: app/views/e_pubs/show_pdf.html.erb, _gatherResults()
                loc = cfiRange.split("=")[1]
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
      content = DomUtil.create("p")
      content.textContent = 'There was a problem processing this query.';
    }
    
    self._article.appendChild(content);
  },

  EOT: true
});

export var search = function(options) {
  console.log("-- control.contents", options);
  return new Search(options);
}