// Override CC, see #778
// Once we move to Hyrax, this file can be deleted
Blacklight.onLoad(function() {
  $(document).on('scroll', function() {
    var workflowDiv = $('#workflow_controls');

    if($(window).scrollTop() + $(window).height() == $(document).height()){
      workflowDiv.removeClass('workflow-affix');
    }
    if($('.form-actions').position() && ($(window).scrollTop() + $(window).height() < $('.form-actions').position().top)) {
      workflowDiv.addClass('workflow-affix');
    }
  });
});
