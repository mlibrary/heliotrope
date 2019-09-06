// trap keyboard navigation within document.fullscreenElement, if active
$(document).on('turbolinks:load', function() {
  var $document = $(document);
  if ( $document.data('initKeyboardWatch') ) { return ; }

  $document.data('initKeyboardWatch', true);

  var FOCUSABLE_ELEMENTS = [
    'a[href]',
    'area[href]',
    'input:not([disabled]):not([type="hidden"])',
    'select:not([disabled])',
    'textarea:not([disabled])',
    'button:not([disabled])',
    'iframe',
    'object',
    'embed',
    '[contenteditable]',
    '[tabindex]:not([tabindex^="-"])'
  ].join(',');

  $(document).on('keydown', function(event) {
    var keyName = event.key;
    if ( keyName != 'Tab' ) { return ; }

    var fullscreenElement =
      document.fullscreenElement ||
      document.webkitFullscreenElement ||
      document.msFullscreenElement ||
      document.mozFullscreenElement;

    if ( ! fullscreenElement ) { return ; }

    var $focusableNodes = $(fullscreenElement).find(FOCUSABLE_ELEMENTS);
    var focusedItemIndex = $focusableNodes.index(document.activeElement);

    if ( focusedItemIndex < 0 ) {
      // tabbing from somewhere outside the element
      $focusableNodes[0].focus();
      event.preventDefault();
    }

    if ( event.shiftKey && focusedItemIndex === 0 ) {
      $focusableNodes[$focusableNodes.length - 1].focus();
      event.preventDefault();
    }

    if ( ! event.shiftKey && focusedItemIndex === $focusableNodes.length - 1 ) {
      $focusableNodes[0].focus();
      event.preventDefault();
    }

  });
});
