
var INTERACTIVE = {};
INTERACTIVE['A'] = true;
INTERACTIVE['SELECT'] = true;
INTERACTIVE['BUTTON'] = true;
INTERACTIVE['INPUT'] = true;

var installedResizeHandler = false;

function isInteractive(node) {
  if ( INTERACTIVE[node.nodeName] ) {
    // possibly...
    if ( node.nodeName == 'A' ) { return node.hasAttribute('href'); }
    return true;
  }
  return false;
}

function hideEverythingInContents(contents) {
  var elements = contents.document.querySelectorAll('body *');
  for(var i = 0; i < elements.length; i++) {
    if ( elements[i].nodeType == Node.ELEMENT_NODE ) {
      var element = elements[i];
      element.setAttribute('aria-hidden', true);
      element.setAttribute('tabindex', '-1');
    }
  }
}

function hideEverythingVisible(contents) {
  var elements = contents.document.querySelectorAll('[aria-hidden="false"]');
  for(var i = 0; i < elements.length; i++) {
    if ( elements[i].nodeType == Node.ELEMENT_NODE ) {
      elements[i].setAttribute('aria-hidden', true);
      if ( INTERACTIVE[elements[i].nodeName] ) {
        elements[i].setAttribute('tabindex', '-1');
      }
    }
  }
}

function findMatchingContents(contents, cfi) {
  for(var content of contents) {
    if ( cfi.indexOf(content.cfiBase) > -1 ) {
      return content;
    }
  }
  return null; // ???
}

function showEverythingVisible(container, range) {
  var selfOrElement = function(node) {
    return ( node.nodeType == Node.TEXT_NODE ) ? node.parentNode : node;
  }

  var showNode = function(node) {
    node.setAttribute('aria-hidden', false);
    if ( INTERACTIVE[node.nodeName] ) {
      var bounds = node.getBoundingClientRect();
      var x = bounds.x;
      var x2 = x + container.scrollLeft;
      // console.log("AHOY NODE BOUNDS", node, x, x2,
      //   "A",
      //   x > container.scrollLeft + container.offsetWidth,
      //   x < container.scrollLeft,
      //   "B",
      //   x2 > container.scrollLeft + container.offsetWidth,
      //   x2 < container.scrollLeft
      //   )
      if ( x > container.scrollLeft + container.offsetWidth ||
           x < container.scrollLeft ) {
      } else {
        node.setAttribute('tabindex', 0);
        node.addEventListener('focus', (event) => {
          // console.log("AHOY FOCUS", node, container.scrollLeft, container.dataset.scrollLeft);
          var scrollLeft = parseInt(container.dataset.scrollLeft, 10);
          setTimeout(() => {
            container.scrollLeft = scrollLeft;
          }, 0);
        })
      }
    }
    // node.setAttribute('tabindex', 0);
    for(var child of node.children){
      showNode(child);
    }
  }

  var showNodeAndSelf = function(node) {
    if ( node.getAttribute('aria-hidden') == 'true' ) {
      showNode(node);
      var parent = node.parentNode;
      while ( parent != node.ownerDocument.body ) {
        // console.log("AHOY ACTIVATING UP", parent);
        parent.setAttribute('aria-hidden', false);
        //node.setAttribute('tabindex', 0);
        parent = parent.parentNode;
      }
    }
  }

  var ancestor = selfOrElement(range.commonAncestorContainer);
  var startContainer = selfOrElement(range.startContainer);
  var endContainer = selfOrElement(range.endContainer);

  var _iterator = document.createNodeIterator(
    ancestor,
    NodeFilter.SHOW_ALL,
    {
      acceptNode: function(node) {
        return NodeFilter.FILTER_ACCEPT;
      }
    }
  )

  var _nodes = [];
  while ( _iterator.nextNode() ) {
    // console.log("AHOY ITERATOR", _nodes.length, _iterator.referenceNode, startContainer, _iterator.referenceNode !== startContainer);
    if (_nodes.length === 0 && _iterator.referenceNode !== startContainer) continue;
    _nodes.push(_iterator.referenceNode);
    if (_iterator.referenceNode === endContainer) break;
  }

  // console.log("AHOY NODES", _nodes, _nodes[0] == startContainer);
  if ( _nodes.length == 1 && _nodes[0] == startContainer ) {
    _nodes.pop();
    for(var child of startContainer.children) {
      _nodes.push(child);
    }
  }

  _nodes.forEach((node) => {
    if ( node.nodeType == Node.ELEMENT_NODE ) {
      showNodeAndSelf(node);
    } else {
      showNodeAndSelf(node.parentNode);
    }
  })
}

export function updateFocus(reader, location) {
  if ( reader.settings.flow == 'scrolled-doc' ) { return ; }
  if ( reader.options.disableFocusHandling ) { return ; }
  setTimeout(() => {
    if ( location.start.cfi == reader._last_location_start_cfi &&
         location.end.cfi == reader._last_location_end_cfi ) {
      return;
    }
    reader._last_location_start_cfi = location.start.cfi;
    reader._last_location_end_cfi = location.end.cfi;
    __updateFocus(reader, location);
  }, 0);

  reader._last_location_start = location.start.href;
}

var elemsWithBoundingRects = [];
var getBoundingClientRect = function(element) {
  if ( ! element._boundingClientRect ) {

    // If not, get it then store it for future use.
    element._boundingClientRect = element.getBoundingClientRect();
    elemsWithBoundingRects.push( element );
  }
  return element._boundingClientRect;
}

var clearClientRects = function() {
  var i;
  for ( i = 0; i < elemsWithBoundingRects.length; i++ ) {
    if ( elemsWithBoundingRects[ i ] ) {
      elemsWithBoundingRects[ i ]._boundingClientRect = null;
    }
  }
  elemsWithBoundingRects = [];
}

export function __updateFocus(reader, location) {
  // don't use location

  var selfOrElement = function(node) {
    return ( node.nodeType == Node.TEXT_NODE ) ? node.parentNode : node;
  }

  var container = reader._rendition.manager.container;
  var contents = findMatchingContents(reader._rendition.manager.getContents(), location.start.cfi);
  hideEverythingVisible(contents);

  var containerX = container.scrollLeft;
  var containerX2 = container.scrollLeft + container.offsetWidth;

  var _showThisNode = function(node) {
    var bounds = getBoundingClientRect(node); // node.getBoundingClientRect();
    var x = bounds.left;
    var x2 = bounds.left + bounds.width;

    var isVisible = false;
    if ( x <= containerX && x2 >= containerX2 ) { isVisible = true; }
    else if ( x >= containerX && x < containerX2 ) { isVisible = true; }
    else if ( x2 > containerX && x2 <= containerX2 ) { isVisible = true; }
    // else if ( x <= containerX && x2 <= containerX2 ) { isVisible = true; }
    // else if ( x >= containerX && x2 <= containerX2 ) { isVisible = true; }
    // else if ( x >= containerX && x2 > containerX2 ) { isVisible = true; }

    if ( isVisible ) {
      // console.log("AHOY", isVisible, node, bounds, containerX, containerX2);
      node.setAttribute('aria-hidden', 'false');
      if ( isInteractive(node) ) {
        node.setAttribute('tabindex', '0');
      }
      var hasSeenVisibleChild = false;
      for(var child of node.children) {
        var retval = _showThisNode(child);
        if ( retval ) { hasSeenVisibleChild = true; }
        if ( ! retval && hasSeenVisibleChild ) {
          break;
        }
      }
    }

    return isVisible;
  }

  var startRange = new ePub.CFI(location.start.cfi).toRange(contents.document);
  var startNode = selfOrElement(startRange.startContainer);

  var _nodes = [];
  var checkNode = startNode;
  while ( checkNode != contents.document.body ) {
    var bounds = getBoundingClientRect(checkNode); // checkNode.getBoundingClientRect();
    var x = bounds.left;
    var x2 = bounds.left + bounds.width;

    var isVisible = false;
    // if ( x <= containerX && x2 >= containerX2 ) { isVisible = true; }
    if ( x >= containerX && x < containerX2 ) { isVisible = true; }
    else if ( x2 > containerX && x2 <= containerX2 ) { isVisible = true; }

    if ( isVisible ) {
      startNode = checkNode;
      checkNode = checkNode.parentNode;
    } else {
      break;
    }

  }

  var parentNode = startNode; // .parentNode;
  while ( parentNode != contents.document.body ) {
    parentNode.setAttribute('aria-hidden', false);
    parentNode = parentNode.parentNode;
  }

  _showThisNode(startNode);

  var children = startNode.parentNode.children;
  var doProcess = false;
  for (var nextNode of children) {
    if ( nextNode == startNode ) { doProcess = true; }
    else if ( doProcess ) {
      var isVisible = _showThisNode(nextNode);
      if ( ! isVisible ) { break; }
    }
  }

  if ( reader.__target ) {
    var possible = contents.document.querySelector(`#${reader.__target}`);
    if ( possible && ! reader.options.disableFocusTarget ) {
      possible.focus();
      correct_drift(reader);
      // console.log("AHOY FOCUSING", reader.__target, possible);
    }
    reader.__target = null;
  }
}

var _checkLayout = function(reader) {
  var scrollLeft = reader._manager.container.scrollLeft;
  var mod = scrollLeft % parseInt(reader._manager.layout.delta, 10);
  // console.log("AHOY checkLayout", scrollLeft, reader._manager.layout.delta, mod);
  return mod;
}

var correct_drift = function(reader, data={}) {
  var container = reader._rendition.manager.container;

  var mod;
  var delta;
  var x; var xyz;
  setTimeout(function() {
    var scrollLeft = container.scrollLeft;
    // mod = scrollLeft % parseInt(reader._rendition.manager.layout.delta, 10);
    mod = _checkLayout(reader);
    // console.log("AHOY AHOY keyDown TRAP", mod, mod / reader._rendition.manager.layout.delta,( mod / reader._rendition.manager.layout.delta ) < 0.99 );
    if ( mod > 0 && ( mod / reader._rendition.manager.layout.delta ) < 0.99 ) {
      x = Math.floor(container.scrollLeft / parseInt(reader._rendition.manager.layout.delta, 10));
      if ( data.shiftKey ) { x -= 0 ; }
      else { x += 1; }
      var y = container.scrollLeft;
      delta = ( x * reader._rendition.manager.layout.delta ) - y;
      xyz = ( x * reader._rendition.manager.layout.delta );
      // console.log("AHOY AHOY keyDown SHIFT", mod, reader._rendition.manager.layout.delta, x, delta);
      reader._rendition.manager.scrollBy(delta);
    }
  }, 0);    
}

export function setupFocusRules(reader) {

  if ( ! installedResizeHandler ) {
    installedResizeHandler = true;
    reader.on('resize', () => {
      clearClientRects();
    })
  }

  var contents = reader._rendition.getContents();
  contents.forEach( (content) => {

    if ( reader.options.debugFocusHandling ) {
      content.addStylesheetRules({
        '[aria-hidden="true"]': {
          'opacity': '0.25 !important'
        },
        ':focus': {
          'outline': '2px solid goldenrod',
          'padding': '4px',
          'background': 'lightgoldenrodyellow'
        }
      })
    }

    hideEverythingInContents(content);

    // --- attempts to heal safari/edge
    content.document.addEventListener('keydown', function(event) {
      if ( event.keyCode == 9 ) {

        var activeElement = content.document.activeElement;
        if ( activeElement ) {
          reader._manager.container.dataset.scrollLeft = reader._manager.container.scrollLeft;
        } else {
          reader._manager.container.dataset.scrollLeft = 0;
        }
      }
    })

    // --- capture internal link clicks?
    content.on('linkClicked', function(href) {
      if ( href.indexOf('#') > -1 ) {
        reader.__target = (href.split('#')[1]);
      }
    })
  });

  var __watchInterval;
  reader._watchLayout = function(delta=1000) {
    if ( __watchInterval ) { clearInterval(__watchInterval); return; }
    __watchInterval = setInterval(() => { return reader._checkLayout(reader) }, delta);
  }

  reader.on('keyDown', function(data) {
    reader._manager.container.dataset.scrollLeft = reader._manager.container.scrollLeft;
    correct_drift(reader, data);
  })
}
