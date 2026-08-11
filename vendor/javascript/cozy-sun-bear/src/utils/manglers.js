import Url from "epubjs/src/utils/url";
import * as Browser from '../core/Browser';

var BaseUpdater = class {
  constructor(options={}) {
    this.reader = options.reader;
    this.contents = options.contents;
    this.layout = this.reader._rendition.manager.layout;
  }

  test(element) {
    return ( element.matches(this.selector) );
  }

  stylesheet() {
    return {};
  }

  update(element) {

  }
}

var TableUpdater = class extends BaseUpdater {

  constructor(options={}) {
    super(options);
    this.selector = 'table:not([data-fulcrum-table="false"])';
  }

  test(element) {
    // clipping is buggy in IE
    return ( 
      super.test(element) && 
      ! ( Browser.ie || Browser.edge ) && 
      element.offsetHeight >= ( this.layout.height * 0.75 ) 
    );
  }

  stylesheet() {
    return {
      'table.cozy-mangled-clipped': {
        'break-inside': 'avoid',
        'width': `${this.layout.columnWidth * 0.95}px !important`,
        'table-layout': 'fixed'
      },
      'table.cozy-mangled-clipped tbody': {
        'height': `${this.layout.height * 0.25}px !important`,
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
        break: 'all'
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
    }
  }

  update(table) {
    var reader = this.reader;
    var contents = this.contents;

    // find a dang background color
    var element = table;
    var styles
    var bgcolor;
    while ( bgcolor === undefined && element instanceof HTMLElement ) {
      styles = window.getComputedStyle(element);
      if ( styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent' ) {
        bgcolor = styles.backgroundColor;
        break;
      }
      element = element.parentNode;
    }

    if ( ! bgcolor ) {
      // no background color defined in the EPUB, so what is cozy-sun-bear using?
      element = reader._panes['epub'];
      while ( bgcolor === undefined && element instanceof HTMLElement ) {
        styles = window.getComputedStyle(element);
        if ( styles.backgroundColor != 'rgba(0, 0, 0, 0)' && styles.backgroundColor != 'transparent' ) {
          bgcolor = styles.backgroundColor;
          break;
        }
        element = element.parentNode;
      }
    }

    if ( ! bgcolor ) { bgcolor = '#fff'; }

    var tableHTML = table.outerHTML;

    table.classList.add('cozy-mangled-clipped');

    var div = document.createElement('div');
    div.classList.add('cozy-mangled-popup-table--container');
    table.querySelector('tbody').appendChild(div);

    var button = document.createElement('button');
    button.classList.add('cozy-mangled-popup--action');
    button.innerText = 'Open table';

    var tableId = table.getAttribute('data-id');
    if ( ! tableId ) {
      var ts = ( new Date() ).getTime();
      tableId = "table" + ts + Math.random(ts);
      table.setAttribute('data-id', tableId);
    }

    reader._originalHTML[tableId] = tableHTML;
    // button.dataset.tableHTML = tableHTML;
    button.addEventListener('click', function(event) {
      event.preventDefault();

      var regex = /<body[^>]+>/;
      var index0 = contents._originalHTML.search(regex);
      var tableHTML = reader._originalHTML[tableId];
      var newHTML = contents._originalHTML.substr(0, index0) + `<body style="padding: 1.5rem; background: ${bgcolor}"><section>${tableHTML}</section></body></html>`;

      reader.popup({
        title: 'View Table',
        srcdoc: newHTML,
        onLoad: function(contentDocument, modal) {
          // adpated from epub.js#replaceLinks --- need to catch _any_ link
          // to close the modal
          var base = contentDocument.querySelector("base");
          var location = base ? base.getAttribute("href") : undefined;

          var links = contentDocument.querySelectorAll('a[href]');
          for(var i = 0; i < links.length; i++) {
            var link = links[i];
            var href = link.getAttribute('href');
            link.addEventListener('click', function(event) {
              modal.closeModal();
              var absolute = (href.indexOf('://') > -1);
              if ( absolute ) {
                link.setAttribute('target', '_blank');
              } else {
                var linkUrl = new Url(href, location);
                if (linkUrl) {
                  event.preventDefault();
                  reader.display(linkUrl.Path.path + ( linkUrl.hash ? linkUrl.hash : '' ));
                }
              }
            })
          }
        }
      })

    })

    div.appendChild(button);
  }
}

var EnhancedFigureUpdater = class extends BaseUpdater {
  constructor(options={}) {
    super(options);
    this.selector = '[data-resource-type]';
  }

  stylesheet() {
    return {
      '.cozy-mangled-popup-figure--container': {
        'text-align': 'center !important',
        'padding': '16px !important'
      }
    }
  }

  update(element) {
    var button = document.createElement('button');
    button.classList.add('cozy-mangled-popup--action');
    button.innerText = `Open ${element.dataset.resourceType.replace(/-/g, ' ')}`;

    var div = document.createElement('div');
    div.classList.add('cozy-mangled-popup-figure--container');
    var target = element.querySelector('[data-resource-trigger]');
    if ( target ) {
      // parent.innerHTML = '';
      target.replaceWith(div);
    } else {
      element.appendChild(div);
    }

    var iframe_href = element.dataset.href;
    var iframe_title = element.dataset.title;

    div.appendChild(button);
    button.addEventListener('click', function(event) {
      event.preventDefault();

      reader.popup({
        title: 'View ' + iframe_title,
        href: iframe_href,
        onLoad: function(contentDocument, modal) {
        }
      })

    })
  }
}

export function handlePopups(reader, contents) {
  // var selectors = [ table_config.selector ];
  var updaters = [];
  // if ( _rendition.manager.layout.name == 'reflowable' && ! ( Browser.ie || Browser.edge ) ) {
  // }
  updaters.push(new TableUpdater({reader, contents}));
  updaters.push(new EnhancedFigureUpdater({reader, contents}));

  var selectors = [];
  updaters.forEach((updater) => {
    selectors.push(updater.selector);
  })

  var elements = contents.document.querySelectorAll(selectors.join(','));

  var queue = [];
  for(var i = 0; i < elements.length; i++) {
    var element = elements[i];
    updaters.forEach((updater) => {
      var check = true;
      if ( ! updater.test(element) ) { return; }
      queue.push([element, updater])
    })
  }

  if ( ! queue.length ) { return ; }

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
  })

  var initialized = {};
  queue.forEach(([element, updater]) => {
    if ( ! initialized[updater.selector] ) { contents.addStylesheetRules(updater.stylesheet()) }
    updater.update(element);
  });

}
