(function($){
  var Slideshow = function (element, options) {
    this.$element = $(element);
    this.options  = options;
    this.paused   = false;
    this.activeIndex = 0;

    this.init = function() {
      this.$items = this.$element.find('.item');
    }

    this.attachEvents();
    this.init();
  }


  Slideshow.prototype = {

    slide: function(item) {
      var $item     = $(item),
          $frame    = $item.find('.frame'),
          marginTop = 0;

      this.$items.hide();
      $item.show();

      marginTop = Math.round($item.height() - $frame.height())/2;
      this.activeIndex = this.$items.index(item);

      if (this.options.autoPlay && !this.paused) this.play();

      return this;
    },

    play: function() {
      this.paused = false;

      if (this.interval) clearInterval(this.interval);
      this.interval = setInterval($.proxy(this.next, this), this.options.interval);
    },

    pause: function() {
      this.paused = true;
      this.interval = clearInterval(this.interval);

      return this;
    },

    startAt: function(pos) {
      this.to(pos);
    },

    next: function() {
      return this.to('next');
    },

    to: function(pos) {
      if (pos === 'next') pos = this.activeIndex + 1;
      if (pos === 'prev') pos = this.activeIndex - 1;

      return this.slide(this.$items[this.getValidIndex(pos)]);
    },

    getValidIndex: function(index) {
      if (typeof index === 'undefined' || index > (this.$items.length - 1)) index = 0;
      if (index < 0) index = this.$items.length - 1;

      return index;
    },

    attachEvents: function() {
      var $img = this.$element.find('.frame img'),
          _this = this;

      $(document).on('click', '[data-behavior="pause-slideshow"]', function(e) {
        e.preventDefault();

        _this.pause();
      });

      $(document).on('click', '[data-behavior="start-slideshow"]', function(e) {
        e.preventDefault();

        _this.play();
      });

      $(document).on('click', '[data-slide], [data-slide-to]', function(e) {
        e.preventDefault();

        pos = parseInt($(this).attr('data-slide-to'), 10) || $(this).attr('data-slide');

        if (pos === 'next' || pos === 'prev') _this.pause();
        _this.to(pos);
      });

      // pause slideshow on modal close
      $('#slideshow-modal').on('hidden.bs.modal', function() {
        _this.pause();
      });
    }
  }


  Slideshow.DEFAULTS = {
    autoPlay: false,
    interval: 5000 // in milliseconds
  }


  $.fn.slideshow = function(option) {
    return this.each(function() {
      var $this = $(this);
      var data  = $this.data('slideshow');
      var options = $.extend({}, Slideshow.DEFAULTS, $this.data(), typeof option == 'object' && option);

      if (!data) $this.data('slideshow', (data = new Slideshow(this, options)));
    })
  }

})(jQuery);


Blacklight.onLoad(function() {
  $('.documents-slideshow').slideshow();
});
