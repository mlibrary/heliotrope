// Copied from Hyrax.
// Right now we don't include these workflow controls in our
// views everywhere hyrax expects them to be. So this file will
// sometimes throw errors:
// "Uncaught TypeError: Cannot read property 'top' of undefined"
// So we'll add "&& typeof $('.workflow-actions').offset() !== "undefined"" to quiet that.
// If we ever start using workflows we'll revisit this
Blacklight.onLoad(function() {
  if ($('.workflow-actions').length && typeof $('.workflow-actions').offset() !== "undefined") {
    $(document).on('scroll', function() {
      var workflowDiv = $('#workflow_controls');
      var workflowDivPos = $('.workflow-actions').offset().top + $('#workflow_controls').height();
      workflowDiv.removeClass('workflow-affix');
      if(workflowDivPos > ($(window).scrollTop() + $(window).height())){
        workflowDiv.addClass('workflow-affix');
      } else {
        workflowDiv.removeClass('workflow-affix');
      }
    });
  }
});
