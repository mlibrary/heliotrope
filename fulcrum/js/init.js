(function($){
  $(function(){

    $('.button-collapse').sideNav();
    $('.parallax').parallax();
    $('.materialboxed').materialbox();
    $("#button--get-updates").click(function() {
    $('html, body').animate({
        scrollTop: $("#get-updates").offset().top
    }, 2000);
});

  }); // end of document ready
})(jQuery); // end of jQuery name space
