// Extends app/assets/javascripts/blacklight/ajax_modal.js

// We keep all our data in Blacklight.ajaxModal object.
// Create lazily if someone else created first.
if (Blacklight.ajaxModal === undefined) {
  Blacklight.ajaxModal = {};
}

Blacklight.onLoad(function() {
  $('body').on('show.bs.modal', function () {
    if (!$('body').data('Blacklight.ajaxModelEx.lastFocusedElement')) {
      $('body').data('Blacklight.ajaxModelEx.lastFocusedElement', $(document.activeElement));
      $('body').children().attr('hidden', true);
      $('#ajax-modal').attr('hidden', false);
    }
  });

  $('body').on('shown.bs.modal', function () {
    $('.ajax-modal-close').focus();
  });

  $('body').on('hide.bs.modal', function () {
    $('body').children().attr('hidden', false);
    $('#ajax-modal').attr('hidden', true);
  });

  $('body').on('hidden.bs.modal', function () {
    $('body').data('Blacklight.ajaxModelEx.lastFocusedElement').focus();
    $('body').data('Blacklight.ajaxModelEx.lastFocusedElement', null);
  });
});
