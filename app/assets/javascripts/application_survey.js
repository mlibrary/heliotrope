$(document).on('turbolinks:load', displayNonModalSurvey);
$(document).ready(function() {
  // the PDF viewer doesn't trigger turbolinks:load, so trigger the non-modal survey here as a fallback
  if (typeof Turbolinks === 'undefined' || !Turbolinks.supported) {
    displayNonModalSurvey();
  }
});

// Wait for cookie consent before showing a survey, so both modals don't appear at the same time.
// Adds a short delay after consent is detected so the cookie banner can finish fading out first.
// If consent is already recorded, the callback fires after the delay; otherwise the callback is
// queued and fired when the 'fulcrum:cookie-consented' event is triggered by the cookie-consent component.
var _cookieConsentCallbacks = [];
var _cookieConsentDelay = 400;

function whenCookieConsented(callback) {
  if (Cookies.get('fulcrum_cookie_consent')) {
    setTimeout(callback, _cookieConsentDelay);
    return;
  }
  _cookieConsentCallbacks.push(callback);
}

// fulcrum:cookie-consented is triggered in app/views/shared/_cookie_consent.html.erb
// When the event is triggered, fire all queued callbacks and clear the queue.
// This is about keeping polling to a minimum, so we don't want to check for cookie consent
// every time we want to show a survey, but we also want to make sure the survey appears 
// as soon as possible after consent is given. 
// The delay is just to give the cookie banner time to finish fading out before the survey appears. 
// If the survey appears at the same time as the cookie banner, it can be jarring and 
// may cause users to dismiss the survey without reading it.
$(document).on('fulcrum:cookie-consented', function() {
  var callbacks = _cookieConsentCallbacks.splice(0);
  callbacks.forEach(function(cb) { setTimeout(cb, _cookieConsentDelay); });
});

$(document).on('turbolinks:before-cache', function() {
  _cookieConsentCallbacks = [];
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
    whenCookieConsented(function() { 
      $('#surveyModal').modal('show'); 
    });
  }
}

function displayBigTenModalSurvey() {
  var bigTenSurveyStatus = Cookies.get('survey_bigten');
  if (( bigTenSurveyStatus == 'ignore') || (bigTenSurveyStatus == 'clicked')) {
    $('#surveyBigTenModal').modal('hide');
  } else {
    whenCookieConsented(function() { $('#surveyBigTenModal').modal('show'); });
  }
}

function displayAberdeenModalSurvey() {
  var aberdeenSurveyStatus = Cookies.get('survey_aberdeenunipress');
  if (( aberdeenSurveyStatus == 'ignore') || (aberdeenSurveyStatus == 'clicked')) {
    $('#surveyAberdeenModal').modal('hide');
  } else {
    whenCookieConsented(function() { $('#surveyAberdeenModal').modal('show'); });
  }
}

function displayWestminsterModalSurvey() {
  var westminsterSurveyStatus = Cookies.get('survey_westminster');
  if (( westminsterSurveyStatus == 'ignore') || (westminsterSurveyStatus == 'clicked')) {
    $('#surveyWestminsterModal').modal('hide');
  } else {
    whenCookieConsented(function() { $('#surveyWestminsterModal').modal('show'); });
  }
}

function displayNewPrairiePressModalSurvey() {
  var newPrairiePressSurveyStatus = Cookies.get('survey_newprairiepress');
  if (( newPrairiePressSurveyStatus == 'ignore') || (newPrairiePressSurveyStatus == 'clicked')) {
    $('#surveyNewPrairiePressModal').modal('hide');
  } else {
    whenCookieConsented(function() { $('#surveyNewPrairiePressModal').modal('show'); });
  }
}


// This survey function is called above on document load and appears only in e-reader
// The survey is hidden by default to prevent a flash of the survey if 
// cookie surveyStatus = 'ignore' or 'clicked'
function displayNonModalSurvey() {
  var surveys = [
    { id: '#surveyNonModal', cookie: 'survey' },
    { id: '#surveyNonModalGabii', cookie: 'survey_gabii' },
    { id: '#surveyNonModalBigten', cookie: 'survey_bigten' },
    { id: '#surveyNonModalAberdeen', cookie: 'survey_aberdeenunipress' },
    { id: '#surveyNonModalWestminster', cookie: 'survey_westminster' },
    { id: '#surveyNonModalNewPrairiePress', cookie: 'survey_newprairiepress' }
  ];
  surveys.forEach(function(survey) {
    if ($(survey.id).length) {
      var status = Cookies.get(survey.cookie);
      if (status == 'ignore' || status == 'clicked') {
        $(survey.id).hide();
      } else {
        whenCookieConsented(function() { $(survey.id).fadeIn(800); });
      }
    }
  });
}

