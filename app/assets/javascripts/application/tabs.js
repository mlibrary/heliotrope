$(document).on('turbolinks:load', function() {
  // Store the monograph ID and tab ID last used on the monograph catalog page
  // Amend the tab ID to URL if it exists.
  storeTab();
  // Improve accessibility and keyboard functionality of tabs
  // For monograph and asset pages
  accessibleTabs();

function storeTab() {
  // If monograph page, store the last used tab
  if ($('#main.monograph').length > 0) {
    // https://stackoverflow.com/a/10524697
    var page_url = window.location.pathname.split( '/' );
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
    var lastTab = sessionStorage.getItem('lastTab');
    // If there is a value in the search field, heavy-handedly override
    // stored value so the media tab is visible on load.
    if ($('#catalog_search').val().length) {
      lastTab = '#media';
    }
    var firstTab = $('ul[role="tablist"]').children().first().children('a[role="tab"]').attr('href');
    if (lastTab) {
      $('a[href="' + lastTab + '"]').tab('show');
      $(lastTab).attr("aria-hidden", false);
      $('a[href="' + lastTab + '"]').attr("aria-selected", true);
      if (lastTab !== firstTab) {
        $(firstTab).attr("aria-hidden", true);
        $('a[href="' + firstTab + '"]').attr("aria-selected", false);
      }
    }
  }
}

function accessibleTabs() {
  if ($('#tabs').length > 0) {
    // Adapted from https://codepen.io/heydon/pen/veeaEa
    var tabbed = document.querySelector('#tabs');
    var tablist = tabbed.querySelector('ul');
    var tabs = tablist.querySelectorAll('a');
    var panels = tabbed.querySelectorAll('.tab-pane');

    // The tab switching function
    var switchTab = function switchTab(oldTab, newTab) {
      $(newTab).tab('show');
      newTab.focus();
      // Make the active tab focusable by the user (Tab key)
      newTab.removeAttribute('tabindex');
      // Set the selected state
      newTab.setAttribute('aria-selected', 'true');
      newTab.parentNode.setAttribute('class', 'active');
      oldTab.setAttribute('aria-selected', 'false');
      oldTab.parentNode.removeAttribute('class', 'active');
      oldTab.setAttribute('tabindex', '-1');
      // Get the indices of the new and old tabs to find the correct
      // tab panels to show and hide
      var index = Array.prototype.indexOf.call(tabs, newTab);
      var oldIndex = Array.prototype.indexOf.call(tabs, oldTab);
      panels[oldIndex].setAttribute('aria-hidden', 'true');
      $(panels[index]).tab('show');
      panels[index].setAttribute('aria-hidden', 'false');
      //('class', 'active');
    };

    // Add the tablist role to the first <ul> in the .tabbed container
    tablist.setAttribute('role', 'tablist');

    // Add aria semantics - remove user focusability for each tab
    Array.prototype.forEach.call(tabs, function (tab, i) {
      tab.setAttribute('role', 'tab');
      //tab.setAttribute('id', 'tab' + (i + 1));
      tab.setAttribute('tabindex', '-1');
      tab.parentNode.setAttribute('role', 'presentation');

      // Handle clicking of tabs for mouse users
      tab.addEventListener('click', function (e) {
        e.preventDefault();
        var currentTab = tablist.querySelector('[aria-selected]');
        if (e.currentTarget !== currentTab) {
          switchTab(currentTab, e.currentTarget);
        }
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
          dir === 'down' ? panels[i].focus() : tabs[dir] ? switchTab(e.currentTarget, tabs[dir]) : void 0;
        }
      });
    });

    // Initially activate the first tab and reveal the first tab panel
    tabs[0].removeAttribute('tabindex');
  }
}

});
