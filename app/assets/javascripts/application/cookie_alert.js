$(document).on('turbolinks:load', function() {
  // display an alert if the user's browser doesn't accept cookies
  Cookies.set('browser_accepts_cookies', 'yes', { expires: 365 });
  var accepts_cookies = Cookies.get('browser_accepts_cookies');
  if (accepts_cookies !== 'yes') {
    $('#cookies-required-alert').show();
  }
});
