// Provides a11y additions to modal functionality from app/assets/javascripts/blacklight/blacklight.js

// We keep our "modal is opened or closed" flag in an arbitrarily-named Blacklight.modalEx data object on `body`.
// Create lazily if someone else created first.
if (Blacklight.modal === undefined) {
  Blacklight.modal = {};
}

Blacklight.onLoad(function() {
  $('#blacklight-modal').attr('hidden', true);

  $('#blacklight-modal').on('show.bs.modal', function () {
    if (!$('body').data('Blacklight.modalEx.lastFocusedElement')) {
      $('body').data('Blacklight.modalEx.lastFocusedElement', $(document.activeElement));
      $('body').children().attr('hidden', true);
      $('#blacklight-modal').attr('hidden', false);
    }
  });

  $('#blacklight-modal').on('shown.bs.modal', function () {
    $('.blacklight-modal-close').focus();
  });

  $('#blacklight-modal').on('hide.bs.modal', function () {
    $('body').children().attr('hidden', false);
    $('#blacklight-modal').attr('hidden', true);
  });

  $('#blacklight-modal').on('hidden.bs.modal', function () {
    $('body').data('Blacklight.modalEx.lastFocusedElement').focus();
    $('body').data('Blacklight.modalEx.lastFocusedElement', null);
  });
});
