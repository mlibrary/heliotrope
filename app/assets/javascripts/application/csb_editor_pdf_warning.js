$(document).on('turbolinks:load', function() {
  // e-book download (dynamically-added modal, hence delegated `on()` binding)
  $("body").on('click', '#cozy-pdf-download-warning-required', function(e) {
    alert("Editors, please note that the PDF offered here is not the repository PDF.\nIt has been compressed and may be watermarked.\n\nDo not use this file for editing!");
  });
});
