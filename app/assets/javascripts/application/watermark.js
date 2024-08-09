$(document).on('turbolinks:load', function() {
  console.log("hidden?", $("#pdf-watermarker-download").is(":hidden"));
  const watermarkLink = $("#pdf-watermarker-download:hidden");
  const watermarkUrl = "/ebooks/" + watermarkLink.attr('data-ebook-noid') + "/watermark";

  watermarkLink.click(function(event) {
    event.preventDefault();
    console.log("watermark link clicked")
    $('#monograph-download-btn').removeClass('dropdown-toggle')
    $('#monograph-download-btn').html("<span class='spinner-border spinner-border-sm'><span class='sr-only'>Preparing Download</span>");


    $.ajax({
      type: "POST",
      url: watermarkUrl,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      },
      sucess: function(response) {
        console.log(response.status);
        console.log("success - redirecting to download page");
        console.log(response);
      },
      error: function(data) {
        console.log(response.status);
        console.log("error");
        console.log(response.message);
        console.log(response);
      }
    });
  });
});