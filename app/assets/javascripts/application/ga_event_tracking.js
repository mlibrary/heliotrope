//$(document).on('turbolinks:load', function() {
$(document).ready(function() {
  // Register user events with google analytics

  if (typeof(ga) == typeof(Function)) {
    //
    // Press page
    //
    // header link
    $('a.navbar-brand').click(function() {
      ga('pressTracker.send', 'event', which_category(), 'click', $(this).attr('href'))
    });

    // press catalog listing of monographs, titles and title buttons
    $('#documents .document').each(function(index, value) {

      var title = $(value).find('h2.index_title a').text();

      $(value).find('h2.index_title a').click(function() {
        ga('pressTracker.send', 'event', 'press_page', 'click', title)
      });

      $(value).find('a.btn.btn-default').click(function() {
        ga('pressTracker.send', 'event', 'press_page', 'click_button', title)
      })
    });

    // footer links
    $('footer.press a').click(function() {
      ga('pressTracker.send', 'event', which_category(), 'click', $(this).attr('href'))
    });

    //
    // Search
    //
    // The search form on each "page type" is the same, so we try to guess where
    // the search came from for the event category.
    //
    $('#keyword-search-submit').click(function() {
      // console.log(which_category());
      ga('pressTracker.send', 'event', which_category(), 'search', $('#catalog_search').val());
    });

    //
    // Monograph page
    //
    // monograph catalog listing of file_sets/assets
    // This is *very* close the press_page catalog listing, it's just h4 instead of h2!
    $('#documents .document h4.index_title a').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'click', $(this).text());
    });

    // buy button
    $('#monograph-buy-btn').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'click_buy', $(this).attr('href'))
    });

    // sort
    $('#sort-dropdown ul.dropdown-menu li a').click(function() {
      //console.log($(this).attr('href').split("?")[1]);
      ga('pressTracker.send', 'event', 'monograph_page', 'sort', $(this).attr('href').split("?")[1]);
    });

    // facets
    //$('#facets a.facet_select').mouseover(function() {
    //  console.log($(this).text());
    //});
    // Repeating/hard coding this to get a little more detail in the 'action', but
    // probably could DRY it out with a little work...
    // Also, this doesn't work in the facet modal yet, just the top 5...
    $('#facet-section_title_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_section', $(this).text());
    });
    $('#facet-keywords_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_keywords', $(this).text());
    });
    $('#facet-creator_full_name_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_creator', $(this).text());
    });
    $('#facet-resource_type_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_format', $(this).text());
    });
    $('#facet-search_year_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_year', $(this).text());
    });
    $('#facet-exclusive_to_platform_sim a.facet_select').click(function() {
      ga('pressTracker.send', 'event', 'monograph_page', 'facet_exclusivity', $(this).text());
    });

    //
    // File Set/Asset page
    //
    // Leaflet image pan and zoom buttons
    $('a.leaflet-control-zoom-in').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'zoom_in', $('#asset-title').text());
    });
    $('a.leaflet-control-zoom-out').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'zoom_out', $('#asset-title').text());
    });
    $('a.leaflet-control-pan-up').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'pan_up', $('#asset-title').text());

    });
    $('a.leaflet-control-pan-down').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'pan_down', $('#asset-title').text());

    });
    $('a.leaflet-control-pan-left').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'pan_left', $('#asset-title').text());

    });
    $('a.leaflet-control-pan-right').click(function() {
      ga('pressTracker.send', 'event', 'file_set_page', 'pan_right', $('#asset-title').text());
    });

    // video and audio
    var video = $('#video').get(0)
    if (video) {
      video.addEventListener("play", function() {
        ga('pressTracker.send', 'event', 'file_set_page', 'play_video', $('#asset-title').text());
      });
      video.addEventListener("pause", function() {
        ga('pressTracker.send', 'event', 'file_set_page', 'stop_video', $('#asset-title').text());
      });
    }
    var audio = $('#audio').get(0)
    if (audio) {
      audio.addEventListener("play", function() {
        ga('pressTracker.send', 'event', 'file_set_page', 'start_audio', $('#asset-title').text());
      });
      audio.addEventListener("pause", function() {
        ga('pressTracker.send', 'event', 'file_set_page', 'stop_audio', $('#asset-title').text());
      });
    }

    // tabs
    $('ul.nav.nav-tabs li a').click(function() {
      var tab = $(this).attr('href').split('#')[1];
      ga('pressTracker.send', 'event', 'file_set_page', 'tab_' + tab, $('#asset-title').text());
    });
  }

  function which_category() {
    // Some events can be in multiple "pages", press, monograph or file_set
    // This tries to figure out where the user initiated the event
    var url = window.location.href.split("?")[0];
    var category = 'press_page';
    if (url.match(/monograph/g)) { category = 'monograph_page' }
    if (url.match(/file_set/g))  { category = 'file_set_page'  }
    return category
  }
});
