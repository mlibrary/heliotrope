// This file is mostly the same as the one you'll find here:
// https://github.com/samvera/hyrax/blob/1e504c200fd9c39120f514ac33cd42cd843de9fa/app/assets/javascripts/hyrax/flot_stats.js

// Changes:
// 1) `hyrax_item_stats` changed to `heliotrope_item_stats`
// 2) made it "Turbolinks aware", triggering when the stats tab is already active on page load, or is clicked
// 3) added a flag so it doesn't redraw more than once per page load (resizing aside), as the user might have...
//    zoomed the graph etc.
// 4) added setTimeOut with 250ms, which overcomes two Flot issues which stem from plotting a graph in a hidden parent:
//   a) the graph never resizes appropriately to the space available (this one can also be solved by...
//      adding `jquery.flot.resize` to `application.js` but that causes a noticeable "jump" as the graph resizes)
//      see https://stackoverflow.com/a/26070749/3418063 and https://github.com/flot/flot/issues/1014
//   b) the labels can overlap the graph (most notably on the y-axis), again from not knowing available space exactly
//      see https://stackoverflow.com/q/18012123/3418063
// 5) used UTC functions (like getUTCDate etc.) for the tooltip on the graph points. The version in Hyrax (copied...
//    from Sufia) takes timezone into account on the tooltip but not the axis, so the former always seems a day ...
//    behind (west of GMT)
// 6) added windows resize function, throttled, so that the graphs can be responsive with a width in percent
// 7) changed "series" and "selection" color for both graphs to rgb(90, 145, 180)

// see 3) above ^
var heliotropeStatsAlreadyDrawn = false;

var heliotropeStatFlotTimer;
$(window).resize(function() {
  throttleHeliotropeStatFlot(50);
});

function throttleHeliotropeStatFlot(milliseconds) {
  clearTimeout (heliotropeStatFlotTimer);
  heliotropeStatFlotTimer = setTimeout(heliotropeStatFlot, milliseconds);
};

$(document).on('turbolinks:load', function() {
  // need to set this to false here for Turbolinks browser back/forward button (restoration) events
  heliotropeStatsAlreadyDrawn = false;

  if ($('#stats-tab').hasClass('active')) {
    throttleHeliotropeStatFlot(250);
  }

  $("a[href='#stats']").bind('click', function () {
    if(heliotropeStatsAlreadyDrawn == false) {
      throttleHeliotropeStatFlot(250);
    }
  });
});

function heliotropeStatFlot() {
  if (typeof heliotrope_item_stats === "undefined") {
    return;
  }

  function weekendAreas(axes) {
    var markings = [],
      d = new Date(axes.xaxis.min);

    // go to the first Saturday
    d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 1) % 7))
    d.setUTCSeconds(0);
    d.setUTCMinutes(0);
    d.setUTCHours(0);

    var i = d.getTime();

    // when we don't set yaxis, the rectangle automatically
    // extends to infinity upwards and downwards

    do {
      markings.push({xaxis: {from: i, to: i + 2 * 24 * 60 * 60 * 1000}});
      i += 7 * 24 * 60 * 60 * 1000;
    } while (i < axes.xaxis.max);

    return markings;
  }

  var options = {
    xaxis: {
      mode: "time",
      tickLength: 5
    },
    yaxis: {
      tickDecimals: 0,
      min: 0
    },
    series: {
      color: "rgb(90, 145, 180)",
      lines: {
        show: true,
        fill: true
      },
      points: {
        show: true,
        fill: true
      }
    },
    selection: {
      color: "rgb(90, 145, 180)",
      mode: "x"
    },
    grid: {
      hoverable: true,
      clickable: true,
      markings: weekendAreas
    }
  };

  var plot = $.plot("#usage-stats", heliotrope_item_stats, options);

  $("<div id='tooltip'></div>").css({
    position: "absolute",
    display: "none",
    border: "1px solid #bce8f1",
    padding: "2px",
    "background-color": "#d9edf7",
    opacity: 0.80
  }).appendTo("body");

  $("#usage-stats").bind("plothover", function (event, pos, item) {
    if (item) {
      date = new Date(item.datapoint[0]);
      months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]
      $("#tooltip").html("<strong>" + item.series.label + ": " + item.datapoint[1] + "</strong><br/>" + months[date.getUTCMonth()] + " " + date.getUTCDate() + ", " + date.getUTCFullYear())
        .css({top: item.pageY + 5, left: item.pageX + 5})
        .fadeIn(200);
    } else {
      $("#tooltip").fadeOut(100)
    }
  });

  var overview = $.plot("#overview", heliotrope_item_stats, {
    series: {
      color: "rgb(90, 145, 180)",
      lines: {
        show: true,
        lineWidth: 1
      },
      shadowSize: 0
    },
    xaxis: {
      ticks: [],
      mode: "time",
      minTickSize: [1, "day"]
    },
    yaxis: {
      ticks: [],
      min: 0,
      autoscaleMargin: 0.1
    },
    selection: {
      color: "rgb(90, 145, 180)",
      mode: "x"
    },
    legend: {
      show: false
    }
  });

  $("#usage-stats").bind("plotselected", function (event, ranges) {
    plot = $.plot("#usage-stats", heliotrope_item_stats, $.extend(true, {}, options, {
      xaxis: {
        min: ranges.xaxis.from,
        max: ranges.xaxis.to
      }
    }));
    overview.setSelection(ranges, true);
  });

  $("#overview").bind("plotselected", function (event, ranges) {
    plot.setSelection(ranges);
  });

  heliotropeStatsAlreadyDrawn = true;
};
