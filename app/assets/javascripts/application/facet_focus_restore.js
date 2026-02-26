// The idea is to use localStorage to hold the last facet link clicked as the page is being navigated away from, and
// then on page load find that same link and focus it.
//
// This is to improve keyboard accessibility for users who are drilling down into facets and want to stay in the
// same place in the facet list as they navigate in and out of the 'more>>' modals and the main page.
//
// To do this, given Blacklight constraints, we use both the ID of the facet content and the innerText of the facet link,
// ... which by the very nature of faceted search has to be a unique combination.


// This listener is called before the Turbolinks visit starts, so we can capture the active element before it's changed.'
document.addEventListener('turbolinks:before-visit', function () {
  var active = document.activeElement;

  // no action unless we're on a facet link or a remove 'x' link as we bail on the current page
  if (
    active &&
    (active.classList.contains('facet-label') ||
      active.classList.contains('facet-select') ||
      active.classList.contains('remove'))
  ) {


    // begin logic to grab the ID of the facet content we'll restore focus within
    var facetFocusAncestorId = null;

    // getting the ancestor ID *to which we want to return the focus* is trickier within the "more>>" modal, as there
    // is no context-giving ancestor with an ID at all, so we'll pull the facet field value from the alpha-sort button
    if (active.closest('.modal-body')) {
      var href = document.querySelector('a.sort_change.az').getAttribute('href');
      if (href) {
        // Match pattern like f[product_names_sim] or f%5Bproduct_names_sim%5D and use that to calculate the closest
        // ancestor ID on the main page
        // note that the to-be-added field name only appears as the first param in the modal, on the main page they
        // seem alpha-sorted
        var match = href.match(/f(?:%5B|\[)([^%\]]+)(?:%5D|\])/);
        if (match) {
          var facetFieldName = match[1];
          facetFocusAncestorId = 'facet-' + facetFieldName;
        }
      }
    } else {
      // on the results page sidebar we can just use the ID of `facet-content` itself, which is always present
      facetFocusAncestorId = active.closest('[id]').id;
    }

    if (facetFocusAncestorId) {
      // console.log('facetFocusAncestorId = "' + facetFocusAncestorId + '"');
      localStorage.setItem('facetFocusAncestorId', facetFocusAncestorId);
    }


    // begin logic to grab the innerText of the facet link we'll restore focus to (or near)
    var facetFocusText = null;

    // in the case of a click on a facet 'x' link, we need to get the innerText of the facet label that contains it,
    // which is the text of the span which will become a link again after the page is reloaded and this facet is removed
    if (active.classList.contains('remove')) {
      var facetLabel = active.closest('.facet-label');
      var selectedSpan = facetLabel ? facetLabel.querySelector('.selected') : null;
      facetFocusText = selectedSpan ? selectedSpan.innerText : null;
    } else {
      // otherwise we can just grab the innerText of the active element, which is the facet link itself
      facetFocusText = active.innerText;
    }

    if (facetFocusText) {
      // console.log('facetFocusText = "' + facetFocusText + '"');
      localStorage.setItem('facetFocusText', facetFocusText);
    }

  }
});

// This listener uses the stored values to figure out which value, if any, should be focused.
document.addEventListener('turbolinks:load', function () {
  var facetFocusText = localStorage.getItem('facetFocusText');
  var facetFocusAncestorId = localStorage.getItem('facetFocusAncestorId');

  if (facetFocusText && facetFocusAncestorId) {
    // console.log('Restoring facet focus. facetFocusText = "' + facetFocusText + '", facetFocusAncestorId = "' + facetFocusAncestorId + '"');
    var ancestor = document.getElementById(facetFocusAncestorId);
    if (ancestor) {
      if (!ancestor.classList.contains('show')) {
        var bsCollapse = new bootstrap.Collapse(ancestor, {toggle: false});
        bsCollapse.show();
      }

      var isFocusable = function (el) {
        return (
          typeof el.focus === 'function' &&
          !el.disabled &&
          ((el.tabIndex >= 0) ||
            (/^(A|INPUT|BUTTON|SELECT|TEXTAREA)$/.test(el.tagName)))
        );
      };

      // Find element with matching innerText
      var allElements = ancestor.querySelectorAll('*');
      var elementsArray = Array.prototype.slice.call(allElements);
      var match = null;
      for (var j = 0; j < elementsArray.length; j++) {
        if (elementsArray[j].innerText === facetFocusText) {
          match = elementsArray[j];
          break;
        }
      }

      // this block catches cases such as the facet which was just removed having too low a count to appear in the
      // sidebar facet content (i.e. it's buried inside the more>> modal after reload), se we'll just focus its
      // facet widget's button
      if (!match) {
        var facetButton = document.querySelector('button[data-bs-target="#' + facetFocusAncestorId + '"]');
        if(facetButton) { facetButton.focus(); }
        return;
      }

      if (isFocusable(match)) {
        match.focus();
      } else {
        var allDescendants = ancestor.querySelectorAll('*');
        var descendants = Array.prototype.slice.call(allDescendants);
        var startIdx = descendants.indexOf(match) + 1;

        for (var i = startIdx; i < descendants.length; i++) {
          if (isFocusable(descendants[i])) {
            descendants[i].focus();
            break;
          }
        }
      }
    }
  }
  // Clear localStorage
  localStorage.removeItem('facetFocusText');
  localStorage.removeItem('facetFocusAncestorId');
});
