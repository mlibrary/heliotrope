$(document).on('turbolinks:load', function() {
  // Store the tab last used on the monograph catalog page and amend it to URL
  // if it exists.
  storeTab();
  accessibleTabs();
  keyboardTabs();
  //Improve accessibility of tabs on monograph and asset pages

function storeTab() {
  // If monograph page, store the last used tab
  if ($('#main.monograph').length > 0) {
    // https://stackoverflow.com/a/10524697
    var monograph_id = '<%= @monograph_presenter.id %>';
    var previous_monograph_id = localStorage.getItem('monograph_id');
    localStorage.setItem('monograph_id', monograph_id);

    if (monograph_id !== previous_monograph_id) {
      localStorage.removeItem('lastTab');
    }

    // for bootstrap 3 use 'shown.bs.tab', for bootstrap 2 use 'shown' in the next line
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      // save the latest tab; use cookies if you like 'em better:
      localStorage.setItem('lastTab', $(e.target).attr('href'));
    });

    // go to the latest tab, apply aria semantics, if it exists in localStorage
    // if not the first tab, unset aria semantics for first tab
    var lastTab = localStorage.getItem('lastTab');
    var firstTab = $('ul[role="tablist"]').children().first().children('a[role="tab"]').attr('href');
    //.attr('href');
    console.log(firstTab);
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
  // a11y toggles for tab list items, fire on bootstrap tab events
  // https://getbootstrap.com/docs/3.3/javascript/#tabs-events
  // https://codepen.io/jwmcglone/pen/pVNLGB?editors=1010
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var newTabList = $(e.target);
    var oldTabList = $(e.relatedTarget);
    var newTabPanel = $(e.target).attr('href');
    var oldTabPanel = $(e.relatedTarget).attr('href');
    // modify previously active tab list item and tab panel
    // 1) change the old tabs values to aria-selected = false and aria-hidden = true
    $(oldTabList).attr('aria-selected', false);
    $(oldTabList).attr('tabindex', '-1');
    $(oldTabPanel).attr('aria-hidden', true);

    // modify newly active tab list item and tab panel
    // 2) change the new tab values to aria-selected = true and aria-hidden = false
    // 3) set the focus on the newly selected tab content .attr("tabindex", -1) and .focus();
    $(newTabList).attr("aria-selected", true);
    $(newTabList).attr('tabindex', '0');
    $(newTabPanel).attr("aria-hidden", false);
  });
}

function keyboardTabs() {
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
    //panels[oldIndex].setAttribute('class', 'active');
    $(panels[index]).tab('show');
    //('class', 'active');
  };

  // Add the tablist role to the first <ul> in the .tabbed container
  tablist.setAttribute('role', 'tablist');

  // Add semantics are remove user focusability for each tab
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
  //tabs[0].setAttribute('aria-selected', 'true');
  //panels[0].hidden = false;
}

});
