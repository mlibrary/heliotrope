//disable right click over video
$(document).ready(function(){
   $('#video').bind('contextmenu',function() { return false; });
});
