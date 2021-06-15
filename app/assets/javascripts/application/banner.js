$(document).on('turbolinks:load', function () {
    if ($(".asset").length > 0 || (".monograph").length > 0) {
        displayBanner();
        displayEulaBanner();
        displayAcceptableUsePolicyBanner();
    }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display the banner, but
// if the users chooses to ignore the banner
// or clicks the link to buy access
// don't show the banner again.

function displayBanner() {
    var subdomain = $("body")[0].classList[0];
    var cookieName = subdomain + '_shared_press_banner';
    var bannerStatus = Cookies.get(cookieName);
    if ((bannerStatus == 'ignore') || (bannerStatus == 'clicked')) {
        $("div#" + cookieName).hide();
    } else {
        $("div#" + cookieName).show();
    }
}

function displayEulaBanner() {
    var subdomain = $("body")[0].classList[0];
    var cookieName = subdomain + '_eula_press_banner';
    var bannerStatus = Cookies.get(cookieName);
    if ( bannerStatus == 'eula_agreement' ) {
        $("div#" + cookieName).hide();
    } else {
        $("div#" + cookieName).show();
    }
}

function displayAcceptableUsePolicyBanner() {
    var cookieName = 'acceptable_use_policy_banner';
    var bannerStatus = Cookies.get(cookieName);
    if ( bannerStatus == 'acceptable_use_policy_agreement' ) {
        $("div#" + cookieName).hide();
    } else {
        $("div#" + cookieName).show();
    }
}
