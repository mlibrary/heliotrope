var heliotropeMobileUser = false;

$(document).on('turbolinks:load', function() {
  if (bowser.mobile || bowser.tablet)
    heliotropeMobileUser = true;
});
