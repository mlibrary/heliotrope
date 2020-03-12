//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This file is not the easiest to follow but you can take it that most of the top section is to do with adding...
// ARIA stuff and k/b naviagation for a11y concerns, whereas the bottom part is heliotrope-specific logic that...
// takes our Monograph/Score catalog customizations into account. Basically the fact that the resources tab may not...
// be the default (table of contents comes first for eBook reader Monographs) but needs to take precedence if the...
// user is interacting with Blacklight resources/assets/media results.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// The four places tabs are being used now are:
// 1) Monograph catalog page:
//    app/views/monograph_catalog/_index_monograph.html.erb
// 2) Score catalog page:
//    app/views/score_catalog/_index_score.html.erb
// 3) FileSet asset page:
//    app/views/hyrax/file_sets/_attributes.html.erb
// 4) Press statistics page:
//    app/views/press_statistics/index.html.erb
//
// Please update if more pages start using tabs.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// NB: Because this code is shared by all #tabs it's crucial that you verify that any work you do in this...
// file does not break expected tab behavior in any of the places tabs are used, i.e.
// - semantic structuring not broken (a11y headings)
// - keyboard navigation not broken (a11y)
// - `class="active",`aria-selected="<true|false>"` and `aria-expanded="<true|false>"` all work as intended whether...
//   tab activation is via mouse click or keyboard (a11y)
// - normal Bootstrap tab behavior not broken (URL fragments highlight the expected tab)
// - Blacklight resources results activate resources tab for both facet and text searches
// - browser back button navigates through tab loads as expected (see Hyrax's tabs.js linked below)
//
// Based on bugs we've fought previously (numerous times) you will at a minimum need to review these listed...
// behaviors on eBook Monographs/Score (with TOC tab first in line) and also look at other tab pages lke assets and...
// press statistics.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// The a11y overrides add click event listeners to all tabs, which ultimately call `show` in selectTab() below.
// This means if you separately handle a Bootstrap event like
// $('a#tab-link-id').on('show.bs.tab', function (e) {
// ...or...
// $('a#tab-link-id').on('shown.bs.tab', function (e) {
// ...in the section underneath, then that code will be triggered twice.
// Instead add the trigger to selectTab() below as is done for googleMapRefresh()
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Also note that this Hyrax tab stuff runs on every tab click as well, enabling Turbolinks to do its thing on...
// browser-back-button navigation. It doesn't seem to be interfering with our stuff. I think.
// https://github.com/samvera/hyrax/blob/master/app/assets/javascripts/hyrax/tabs.js
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

$(document).on('turbolinks:load', function() {
  // Improve accessibility and keyboard functionality of tabs

  if ($('#tabs').length > 0) {
    // Adapted from https://codepen.io/heydon/pen/veeaEa
    var tabbed = document.querySelector('#tabs');
    var tablist = tabbed.querySelector('ul');
    var tabs = tablist.querySelectorAll('a');
    var panels = tabbed.querySelectorAll('.tab-pane');

    // HELIO-3093
    var googleMapRefresh = function googleMapRefresh(tab) {
      if (($('a#tab-map-press-stats').length > 0) && tab.hash === '#map') {
        $('#map-wrapper').html($('#map-wrapper').html());
      }
    };

    var drawStats = function drawStats(tab) {
      if (tab.hash === '#stats') {
        throttleHeliotropeStatFlot(250);
        heliotropeStatsAlreadyDrawn = true;
      }
    };

    var selectTab = function selectTab(tab) {
      $(tab).tab('show');
      // Make the active tab focusable by the user (Tab key)
      tab.removeAttribute('tabindex');
      // Set the selected state
      tab.setAttribute('aria-selected', 'true');
      tab.setAttribute('aria-expanded', 'true');
      tab.closest('li').setAttribute('class', 'active');
      var index = Array.prototype.indexOf.call(tabs, tab);
      panels[index].setAttribute('aria-hidden', 'false');
      // HELIO-3093
      googleMapRefresh(tab);
      drawStats(tab);
    };

    var unselectTab = function unselectTab(tab, index) {
      tab.setAttribute('tabindex', '-1');
      tab.setAttribute('aria-selected', 'false');
      tab.setAttribute('aria-expanded', 'false');
      tab.closest('li').removeAttribute('class', 'active');
      panels[index].setAttribute('aria-hidden', 'true');
    };

    var unselectTabs = function unselectTabs() {
      Array.prototype.forEach.call(tabs, function (tab, index) {
        unselectTab(tab, index);
      });
    };

    var clickTab = function clickTab(tab) {
      unselectTabs();
      selectTab(tab);
      tab.focus();
    };

    Array.prototype.forEach.call(tabs, function (tab, i) {
      // Handle clicking of tabs for mouse users
      tab.addEventListener('click', function (e) {
        e.preventDefault();
        clickTab(e.currentTarget);
      });

      // Handle keydown events for keyboard users
      tab.addEventListener('keydown', function (e) {
        // Get the index of the current tab in the tabs node list
        var index = Array.prototype.indexOf.call(tabs, e.currentTarget);
        // Work out which key the user is pressing and
        // Calculate the new tab's index where appropriate
        var dir = e.which === 37 ? index - 1 : e.which === 39 ? index + 1 : e.which === 40 ? 'down' : null;
        if (dir !== null) {
          e.preventDefault();
          // If the down key is pressed, move focus to the open panel,
          // otherwise switch to the adjacent tab
          if (dir === 'down') {
            panels[index].focus();
          } else if (tabs[dir]) {
            tabs[dir].click();
          }
        }
      });
    });

    var blackLightSearchOngoing = function blackLightSearchOngoing() {
      // the presence of this div indicates text search and/or facet terms are present
      if ($('#appliedParams').val() !== undefined) return true;
      // the presence of these query parameters indicate the user is interacting with results (sorting, paging)
      var blacklight_params = ['page', 'per_page', 'sort', 'view'];
      var blacklight_param_found = false;
      window.location.search.substring(1).split('&').forEach(function(queryNameValue) {
        if (blacklight_params.includes(queryNameValue.split('=')[0])) {
          blacklight_param_found = true;
        }
      });
      return blacklight_param_found;
    };

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Here comes the actual heliotrope tab activation logic. Precedence is as follows:
    // 1) A tab is specifically called out in the URL as a fragment (#tab-id). This beats everything.
    // 2) Blacklight interactions come next in line, the user is interacting with Blacklight so the results must...
    //    ...be front and center on next page load.
    // 3) First tab listed in the HTML under #tabs is the fallback/default otherwise.
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 3) above... First tab, the default
    var activeTab = $(tabs[0]).attr('href');
    // 2) above... Monograph/score catalog pages need to trigger resources tab if Blacklight is in use. If we have...
    //    Blacklight results on another tabbed page in future it should just be a matter of detecting it in this `if`
    if ($('#main.monograph').length > 0 || $('#main.score').length > 0) {
      if (blackLightSearchOngoing()) {
        activeTab = '#resources';
      }
    }
    // 1) above... Override if there is a tab in the URL, i.e a URL fragment, '#tab-name'
    var stripped = document.location.href.split("#");
    if (stripped.length > 1) {
      activeTab = '#' + stripped[1];
    }

    // set tab using a11y-compatible method up top
    var tab = $('a[href="' + activeTab + '"]')[0];
    selectTab(tab);
  }
});
