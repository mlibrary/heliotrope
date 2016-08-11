//disable right click over audio
$(document).ready(function(){
   $('#audio').bind('contextmenu',function() { return false; });
});
