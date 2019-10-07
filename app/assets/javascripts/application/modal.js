$(document).on('turbolinks:load', function() {
  // Resolve HELIO-1793 Monograph catalog modals should keep focus until closed

  $(document).on('keydown', function(e) {
    var KEY_TAB = 9;

    function handleBackwardTab() {
      if ( document.activeElement === $('.modal').find(':focusable:first')[0] ) {
        e.preventDefault();
        $('.modal').find(':focusable:last').focus();
      }
    }
    function handleForwardTab() {
      if ( document.activeElement === $('.modal').find(':focusable:last')[0] ) {
        e.preventDefault();
        $('.modal').find(':focusable:first').focus();
      }
    }

    if ($('.modal:visible').length !== 0) {
      switch (e.keyCode) {
        case KEY_TAB:
          if ($('.modal').find(':focusable').length === 1) {
            e.preventDefault();
            break;
          }

          if (e.shiftKey) {
            handleBackwardTab();
          } else {
            handleForwardTab();
          }

          break;
        default:
          break;
      } // end switch
    }
  });
});
