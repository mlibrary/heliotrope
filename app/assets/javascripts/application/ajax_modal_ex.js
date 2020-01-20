// Extends app/assets/javascripts/blacklight/ajax_modal.js

// We keep all our data in Blacklight.ajaxModal object.
// Create lazily if someone else created first.
if (Blacklight.ajaxModal === undefined) {
  Blacklight.ajaxModal = {};
}

Blacklight.onLoad(function() {
  $('#ajax-modal').attr('hidden', true);

  $('#ajax-modal').on('show.bs.modal', function () {
    if (!$('body').data('Blacklight.ajaxModelEx.lastFocusedElement')) {
      $('body').data('Blacklight.ajaxModelEx.lastFocusedElement', $(document.activeElement));
      $('body').children().attr('hidden', true);
      $('#ajax-modal').attr('hidden', false);
    }
  });

  $('#ajax-modal').on('shown.bs.modal', function () {
    $('.ajax-modal-close').focus();
  });

  $('#ajax-modal').on('hide.bs.modal', function () {
    $('body').children().attr('hidden', false);
    $('#ajax-modal').attr('hidden', true);
  });

  $('#ajax-modal').on('hidden.bs.modal', function () {
    $('body').data('Blacklight.ajaxModelEx.lastFocusedElement').focus();
    $('body').data('Blacklight.ajaxModelEx.lastFocusedElement', null);
  });
});
