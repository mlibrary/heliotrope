$(document).on('turbolinks:load', function () {
    if ($(".asset").length > 0 || (".monograph").length > 0) {
        displayBanner();
        closeBanner();
    }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display the banner, but
// if the users chooses to ignore the banner
// or clicks the link to buy access
// don't show the banner again.

function displayBanner() {
    var subdomain = $("body")[0].classList[0]
    var bannerStatus = Cookies.get(subdomain + '_shared_press_banner');
    if (( bannerStatus == 'ignore') || (bannerStatus == 'clicked')) {
        $("div.banner").hide();
    } else {
        $("div.banner").show();
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function closeBanner() {
    $(".banner a.close").click(function() {
        $("div.banner").hide();
    });

    $(".banner a.btn-primary").click(function() {
        $("div.banner").hide();
    });
}
