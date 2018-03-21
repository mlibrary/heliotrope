var heliotropeMobileUser = false;

//$(document).on('turbolinks:load', function() {
$(document).ready(function() {
  if (bowser.mobile || bowser.tablet)
    heliotropeMobileUser = true;
});
