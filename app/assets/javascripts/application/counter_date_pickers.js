$(document).on('turbolinks:load', function() {
  $('.counter-start-date').datepicker({
    dateFormat: "yy-mm-dd",
    defaultDate: new Date(2018, 07, 01),
    minDate: new Date(2018, 07, 01) // we only started tracking in August 2018
  });
  $('.counter-end-date').datepicker({
    dateFormat: "yy-mm-dd",
    defaultDate: +0,
    minDate: new Date(2018, 08, 01)
  });
});
