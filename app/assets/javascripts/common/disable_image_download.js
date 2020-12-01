//disable right click over image
$(document).ready(function(){
  // disable right-click menu and click/drag
  $('.no-context-menu-or-drag').bind('contextmenu',function() { return false; });
  $('.no-context-menu-or-drag').mousedown(function(e){ e.preventDefault() });
});
