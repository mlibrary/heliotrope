$(document).on('turbolinks:load', function() {
  // If we're interacting with resources/file_sets on the monograph_catalog page,
  // we want the focus of the window to have the list of resources
  // "above the fold" so that users are aware that they are there.

  if (withinResources()) {
    var bodyRect = document.body.getBoundingClientRect();
    var elemRect = document.querySelector("#resources").getBoundingClientRect();
    var offset   = elemRect.top - bodyRect.top;
    // Scroll so that the tabs are at the very top of the window
    window.scrollTo(0, offset);
  }

  function withinResources() {
    url = window.location.href;
    if (url.match(/concern\/monographs\/.*/)) {
      // an active search
      if (getURLParameter('q')) {
        return true;
      }
      // facet filter applied
      if ($("#appliedParams").length) {
        return true;
      }
      // sort applied
      if (getURLParameter('sort')) {
        return true;
      }
      // number of results to show applied
      if (getURLParameter('per_page')) {
        return true;
      }
      // gallery (or other) view applied
      if (getURLParameter('view')) {
        return true;
      }
    }
    return false;
  }

  // https://stackoverflow.com/a/11582513
  function getURLParameter(name) {
    return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [null, ''])[1].replace(/\+/g, '%20')) || null;
  }
});
