// Allow enter key to open the facet panels (a11y). See also https://tools.lib.umich.edu/jira/browse/CSB-248
$(document).on('turbolinks:load', function() {
  $('.panel-heading.facet-field-heading.collapse-toggle').on('keyup', function (event) {
    if ((event.keyCode === 13) && ($(document.activeElement).attr('role') === 'button')) {
      event.preventDefault();
      document.activeElement.click();
    }
  });
});
