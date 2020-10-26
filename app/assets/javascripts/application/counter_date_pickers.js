function firstDayOfLastMonth() {
  let today = new Date();
  let thisYear = today.getFullYear();
  let thisMonth = today.getMonth();

  let lastMonth = thisMonth - 1;
  if (lastMonth <= 0) {
    return new Date(thisYear -1, 12, 1);
  } else {
    return new Date(thisYear, lastMonth, 1);
  }
}

function lastDayOfLastMonth() {
  let today = new Date();
  let thisYear = today.getFullYear();
  let thisMonth = today.getMonth();

  let lastMonth = thisMonth - 1;
  if (lastMonth <= 0) {
    return new Date(thisYear -1, 12, 31);
  } else {
    return new Date(thisYear, thisMonth, 0);
  }
}

$(document).on('turbolinks:load', function() {
  $('.counter-start-date').datepicker({
    dateFormat: "yy-mm-dd",
    defaultDate: firstDayOfLastMonth(),
    minDate: new Date(2018, 7, 1) // we only started tracking in August 2018
  });
  $('.counter-end-date').datepicker({
    dateFormat: "yy-mm-dd",
    defaultDate: lastDayOfLastMonth(),
    minDate: new Date(2018, 8, 1)
  });
});
