$(document).on('turbolinks:load', function() {
  // Register user events with google analytics
  if (typeof(ga) == typeof(Function)) {
    //
    // data-ga-event-* elements
    //
    //  data-ga-event-category if undefined then which_category()
    //  data-ga-event-action is required
    //  data-ga-event-label is recommended
    //  data-ga-event-value is optional (non-negative integer a.k.a. greater than or equal to zero)
    //
    $('[data-ga-event-action]').each (function(index, element) {
      $(element).click(function() {
        if ($(element).data('ga-event-category' === undefined)) {
          press_tracker_event(which_category(),
            $(element).data('ga-event-action'),
            $(element).data('ga-event-label'),
            $(element).data('ga-event-value'));
        } else {
          press_tracker_event($(element).data('ga-event-category'),
            $(element).data('ga-event-action'),
            $(element).data('ga-event-label'),
            $(element).data('ga-event-value'));
        }
      });
    });

    //
    // Press page
    //
    // header link
    $('a.navbar-brand').click(function() {
      press_tracker_event(which_category(), 'click', $(this).attr('href'));
    });

    // press catalog listing of monographs, titles and title buttons
    $('#documents .document').each(function(index, value) {
      var title = $(value).find('a h3.index_title').text();
      $(value).find('a').click(function() {
        press_tracker_event('press_page', 'click', title);
      });
    });

    // footer links
    $('footer.press a').click(function() {
      press_tracker_event(which_category(), 'click', $(this).attr('href'));
    });

    // EBC banner links
    $('#banner-librarians-link').click(function() {
      press_tracker_event(which_category(), 'click_banner', window.location.href);
    });

    //
    // Search
    //
    // The search form on each "page type" is the same, so we try to guess where
    // the search came from for the event category.
    //
    $('#keyword-search-submit').click(function() {
      // console.log(which_category());
      press_tracker_event(which_category(), 'search', $('#catalog_search').val());
    });

    //
    // Work page
    //
    // monograph catalog listing of file_sets/assets
    // This is *very* close the press_page catalog listing, it's just h4 instead of h2!
    $('#documents .document h4.index_title a').click(function() {
      press_tracker_event(which_category(), 'click', $(this).text());
    });

    // buy button
    $('#monograph-buy-btn').click(function() {
      press_tracker_event(which_category(), 'click_buy', $(this).attr('href'));
    });

    // sort
    $('#sort-dropdown ul.dropdown-menu li a').click(function() {
      //console.log($(this).attr('href').split("?")[1]);
      press_tracker_event(which_category(), 'sort', $(this).attr('href').split("?")[1]);
    });

    // e-book download
    $('ul.monograph-catalog-rep-downloads li a').click(function() {
      var type = $(this).attr('data-rep-type');
      press_tracker_event(which_category(), 'download_representative_' + type, window.location.href);
    });

    // tabs
    $('ul.nav.nav-tabs li a').click(function() {
      var tab = $(this).attr('href').split('#')[1];
      press_tracker_event(which_category(), 'tab_' + tab, $('#work-title').text());
    });

    //
    // File Set/Resource page
    //
    // download
    $('a.btn-heliotrope-download').click(function() {
      press_tracker_event('file_set_page', 'download', $('#asset-title').text());
    });

    // Leaflet image pan and zoom buttons
    $('a.leaflet-control-zoom-in').click(function() {
      press_tracker_event('file_set_page', 'zoom_in', $('#asset-title').text());
    });
    $('a.leaflet-control-zoom-out').click(function() {
      press_tracker_event('file_set_page', 'zoom_out', $('#asset-title').text());
    });
    $('a.leaflet-control-pan-up').click(function() {
      press_tracker_event('file_set_page', 'pan_up', $('#asset-title').text());
    });
    $('a.leaflet-control-pan-down').click(function() {
      press_tracker_event('file_set_page', 'pan_down', $('#asset-title').text());
    });
    $('a.leaflet-control-pan-left').click(function() {
      press_tracker_event('file_set_page', 'pan_left', $('#asset-title').text());
    });
    $('a.leaflet-control-pan-right').click(function() {
      press_tracker_event('file_set_page', 'pan_right', $('#asset-title').text());
    });
    $('a.leaflet-control-zoom-fullscreen').click(function() {
      press_tracker_event('file_set_page', 'fullscreen', $('#asset-title').text());
    });

    // video and audio
    var video = $('#video').get(0)
    if (video) {
      video.addEventListener("play", function() {
        press_tracker_event('file_set_page', 'play_video', $('#asset-title').text());
      });
      video.addEventListener("pause", function() {
        press_tracker_event('file_set_page', 'stop_video', $('#asset-title').text());
      });
    }
    var audio = $('#audio').get(0)
    if (audio) {
      audio.addEventListener("play", function() {
        press_tracker_event('file_set_page', 'start_audio', $('#asset-title').text());
      });
      audio.addEventListener("pause", function() {
        press_tracker_event('file_set_page', 'stop_audio', $('#asset-title').text());
      });
    }

    // tabs
    $('ul.nav.nav-tabs li a').click(function() {
      var tab = $(this).attr('href').split('#')[1];
      press_tracker_event('file_set_page', 'tab_' + tab, $('#asset-title').text());
    });

    //
    // EPUB tracking
    //
    // Read button on press and monograph pages
    $('#monograph-read-btn').click(function() {
      press_tracker_event(which_category(), 'read_epub', $(this).attr('href'));
    });

    // ToC links
    $('a.toc-link').click(function() {
      press_tracker_event(which_category(), 'read_epub_ToC', $(this).attr('href'));
    });

    // ToC download links
    $('a.toc-download-link').click(function() {
      press_tracker_event(which_category(), 'download_epub_ToC', $(this).attr('href'));
    });

    //
    // E-Reader event tracking
    // Citation, preferences, ToC selections handled in views/e_pubs/show.html.erb
    //
    // Forward and back navigation
    $('i[class^="icon-chevron"]').parent('a').click(function() {
      press_tracker_event('e_reader', 'nav', window.location.href);
    });

    // Full screen
    $('div.cozy-container-fullscreen button').click(function() {
      press_tracker_event('e_reader', 'fullscreen', window.location.href);
    });

    // Search
    $('div.cozy-control form.search button.button--sm').click(function() {
      press_tracker_event('e_reader', 'search', $('#cozy-search-string').val());
    });

    // Range input (nav)
    $('input#cozy-navigator-range-input').change(function() {
      press_tracker_event('e_reader', 'navbar', window.location.href);
    });

    // Close button
    $('button.cozy-close').click(function() {
      press_tracker_event('e_reader', 'close', window.location.href);
    });

    // Feedback button
    $('i.icon-comment-square').parent('a').click(function() {
      press_tracker_event('e_reader', 'feedback', window.location.href);
    });

    // e-book download (dynamically-added modal, hence delegated `on()` binding)
    $("body").on('click', '.cozy-modal-download footer button', function(e) {
      if($('div.cozy-modal-download input[name="format"][value="EPUB"]').is(':checked')) {
        press_tracker_event('e_reader', 'download_representative_epub', window.location.href);
      } else if($('div.cozy-modal-download input[name="format"][value="PDF"]').is(':checked')) {
        press_tracker_event('e_reader', 'download_representative_pdf', window.location.href);
      }
    });

    // citation copying (dynamically-added modal, hence delegated `on()` binding)
    $("body").on('click', '.cozy-modal-citation footer button', function(e) {
      if($('div.cozy-modal-citation input[name="format"][value="MLA"]').is(':checked')) {
        press_tracker_event('e_reader', 'citation_mla', window.location.href);
      } else if($('div.cozy-modal-citation input[name="format"][value="APA"]').is(':checked')) {
        press_tracker_event('e_reader', 'citation_apa', window.location.href);
      } else if($('div.cozy-modal-citation input[name="format"][value="Chicago"]').is(':checked')) {
        press_tracker_event('e_reader', 'citation_chicago', window.location.href);
      }
    });

    // preferences (dynamically-added modal, hence delegated `on()` binding)
    $("body").on('click', '.cozy-modal-preferences footer button', function(e) {
      press_tracker_event('e_reader', 'preferences', window.location.href);
    });

    // TOC (dynamically-added modal, hence delegated `on()` binding)
    $("body").on('click', '.cozy-modal-contents ul li a', function(e) {
      press_tracker_event('e_reader', 'toc', this.href);
    });
  }

  function which_category() {
    // Some events can be in multiple "pages", press, monograph or file_set
    // This tries to figure out where the user initiated the event
    var url = window.location.href.split("?")[0];
    var category = 'press_page';
    if (url.match(/monograph/g)) { category = 'monograph_page' }
    if (url.match(/score/g)) { category = 'score_page' }
    if (url.match(/file_set/g))  { category = 'file_set_page'  }
    return category
  }
});
