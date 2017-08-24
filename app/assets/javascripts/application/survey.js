$(document).ready(function () {
  if ($(".asset").length > 0 || (".monograph").length > 0) {
    displaySurvey();
    closeSurvey();
  }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display the survey, but
// if the users chooses to ignore the survey or clicks the link to the survey
// don't show the survey message again.

function displaySurvey() {
  var surveyStatus = Cookies.get('survey');
  if (( surveyStatus == 'ignore') || (surveyStatus == 'clicked')) {
    $("div.survey").hide();
  } else {
    $("div.survey").show();
  }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function closeSurvey() {
  $(".survey a.close").click(function() {
    $("div.survey").hide();
  });

  $(".survey a.btn-primary").click(function() {
    $("div.survey").hide();
  });
}
