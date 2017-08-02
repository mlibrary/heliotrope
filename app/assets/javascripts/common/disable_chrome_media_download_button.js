$(document).on('turbolinks:load', function() {
  if (bowser.chrome && bowser.version >= 55) {
    // #670 disable the chrome media download button
    $('#video').addClass('no-download');
    $('#audio').addClass('no-download');
  }
});
