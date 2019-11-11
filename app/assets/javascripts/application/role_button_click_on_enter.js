$(document).on('turbolinks:load', function() {
  $(document).on('keyup', function (event) {
    if ((event.keyCode === 13) && ($(document.activeElement).attr('role') === 'button')) {
      event.preventDefault();
      document.activeElement.click();
    }
  });
});
