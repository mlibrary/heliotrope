(function($){
  $.fn.BlacklightMasonry = function() {
    var container = this;
    if(container.length > 0) {
      container.imagesLoaded().progress(function(){
        container.masonry($.fn.BlacklightMasonry.options);
      });
    }
  }

  $.fn.BlacklightMasonry.options = { gutter: 8 };
})(jQuery);

Blacklight.onLoad(function() {
  $('.documents-masonry').BlacklightMasonry();
});
