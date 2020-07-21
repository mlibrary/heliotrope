$(document).on('turbolinks:load', function() {
  {
    displayNonModalSurvey();
  }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Display the survey, but
// if the users chooses to ignore the survey or clicks the link to the survey
// don't show the survey message again.

// This survey function is called from an onClick action in _survey_modal.html.erb
// When a user selects a format to download, the modal is activated
function displayModalSurvey() {
  var surveyStatus = Cookies.get('survey');
  if (( surveyStatus == 'ignore') || (surveyStatus == 'clicked')) {
    $('#surveyModal').modal('hide');
  } else {
    $('#surveyModal').modal('show');
  }
}

// This survey function is called above on document load and appears only in e-reader
// The survey is hidden by default to prevent a flash of the survey if 
// cookie surveyStatus = 'ignore' or 'clicked'
function displayNonModalSurvey() {
  var surveyStatus = Cookies.get('survey');
  if (( surveyStatus == 'ignore') || (surveyStatus == 'clicked')) {
    $('div.alert.survey').hide();
  } else {
    $('div.alert.survey').show();
  }
}


