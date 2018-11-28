$(document).on('turbolinks:load', function () {
  if ($(".asset").length > 0 || (".monograph").length > 0) {
    displayEbcBanner();
    closeEbcBanner();
  }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display the EBC banner, but
// if the users chooses to ignore the EBC banner or clicks the link to buy access
// don't show the banner again.

function displayEbcBanner() {
  var ebcBannerStatus = Cookies.get('ebc_' + (new Date().getFullYear().toString()) + '_banner');
  if (( ebcBannerStatus == 'ignore') || (ebcBannerStatus == 'clicked')) {
    $("div.ebc-banner").hide();
  } else {
    $("div.ebc-banner").show();
  }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function closeEbcBanner() {
  $(".ebc-banner a.close").click(function() {
    $("div.ebc-banner").hide();
  });

  $(".ebc-banner a.btn-primary").click(function() {
    $("div.ebc-banner").hide();
  });
}
