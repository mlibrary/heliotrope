$(document).on('turbolinks:load', function() {
  // Improve accessibility and keyboard functionality of tabs
  // For monograph and asset pages
  if ($('#tabs').length > 0) {
    // Adapted from https://codepen.io/heydon/pen/veeaEa
    var tabbed = document.querySelector('#tabs');
    var tablist = tabbed.querySelector('ul');
    var tabs = tablist.querySelectorAll('a');
    var panels = tabbed.querySelectorAll('.tab-pane');

    var selectTab = function selectTab(tab) {
      $(tab).tab('show');
      // Make the active tab focusable by the user (Tab key)
      tab.removeAttribute('tabindex');
      // Set the selected state
      tab.setAttribute('aria-selected', 'true');
      tab.setAttribute('aria-expanded', 'true');
      tab.closest('li').setAttribute('class', 'active');
      var index = Array.prototype.indexOf.call(tabs, tab);
      // $(panels[index]).tab('show');
      panels[index].setAttribute('aria-hidden', 'false');
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

    var lastTab = $(tabs[0]).attr('href');

    // Store the monograph ID and tab ID last used on the monograph catalog page
    // Amend the tab ID to URL if it exists.
    // If monograph page, store the last used tab
    if ($('#main.monograph').length > 0) {
      // https://stackoverflow.com/a/10524697
      var page_url = window.location.pathname.split('/');
      // getting the monograph id from the URL path is not as reliable as using the
      // monograph presenter
      var monograph_id = page_url[3];
      var previous_monograph_id = sessionStorage.getItem('monograph_id');
      sessionStorage.setItem('monograph_id', monograph_id);

      if (monograph_id !== previous_monograph_id) {
        sessionStorage.removeItem('lastTab');
      }

      // for bootstrap 3 use 'shown.bs.tab', for bootstrap 2 use 'shown' in the next line
      $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        // save the latest tab; use cookies if you like 'em better:
        sessionStorage.setItem('lastTab', $(e.target).attr('href'));
      });

      // go to the latest tab, apply aria semantics, if it exists in sessionStorage
      // if not the first tab, unset aria semantics for first tab
      lastTab = sessionStorage.getItem('lastTab');

      // If there is a value in the search field, heavy-handedly override
      // stored value so the resources tab is visible on load.
      if ($('#resources_search').val() !== undefined) {
        lastTab = '#resources';
      }

      // If the monograph page URL has an anchor (like the CSB Media button)
      // then we override with similar heavy-handedness.
      // https://stackoverflow.com/a/4108277
      var stripped = document.location.href.split("#");
      if (stripped.length > 1) {
        lastTab = '#' + stripped[1];
      }

      if (lastTab === undefined) {
        lastTab = $(tabs[0]).attr('href');
      }

      if ($('a[href="' + lastTab + '"]').val() === undefined) {
        lastTab = $(tabs[0]).attr('href');
      }
    }

    var tab = $('a[href="' + lastTab + '"]')[0];
    selectTab(tab);

    var index = Array.prototype.indexOf.call(tabs, tab);
    if ((index + 1) === tabs.length) {
      // #stats tab
      throttleHeliotropeStatFlot(250);
      heliotropeStatsAlreadyDrawn = true;
    }
  }
});
