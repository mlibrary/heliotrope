jQuery($(document).on('turbolinks:load', function (){

    var minimized_elements = $('.monograph-metadata .description');

    minimized_elements.each(function(){
        // TODO: Threshold should probably be passed in as a parameter.
        var threshold = 500;

        // Just return if content length less than threshold, nop
        if ($(this).text().length <= threshold) return;

        // Locate element to slice
        $md = $($.parseHTML($(this).html())); // extract elements from 'this'
        var m = $md.length; // number of elements
        var n = 0; // element to slice
        var content = ""; // element content buffer
        var length = 0; // running content length
        $(this).html(content); // start with no content in 'this'
        for(n=0; n<m; n++){
          // Text nodes have a nodeType of 3
          content = ($md[n].nodeType == 3) ? $md[n].data : $md[n].innerHTML;
          length += content.length;
          if (length > threshold) break;  // found element to slice, element n
          $(this).append($md[n]); // append element to 'this' content
        }

        // Determine index of where to slice element n
        var index = content.length - (length - threshold); // first guess
        var regexp = /<.+>.+<\/.+>/g;
        var buffer;
        while (buffer = regexp.exec(content)) {
          if (index < buffer.index) {
            break;
          }
          else if (index < regexp.lastIndex) {
            index = buffer.index;
            break;
          }
        }
        while ((content.charAt(index) != ' ') && (index > 0)) index--; // slice on space

        // Clone element n and truncate content at index
        $clone = $($md[n]).clone();
        // Text nodes have a nodeType of 3
        if ($md[n].nodeType == 3) {
          $clone[0].textContent = content.slice(0,index);
        } else {
          $clone[0].innerHTML = content.slice(0,index);
        }
        $clone[0].append(' ...');

        // Create less span and append truncated clone of element n
        $less = $('<span></span>');
        $less.append($clone[0]);
        $(this).append($less);
        $(this).append(' <a href="#" class="more"> More >></a>');

        // Create more span and append element n and the remaining elements
        $more = $('<span style="display:none;"></span>');
        for(; n<m; n++) {
          $more.append($md[n]);
        }
        $more.append(' <a href="#" class="less"><< Less</a>');
        $(this).append($more);
    });

    $('a.more', minimized_elements).click(function(event){
        event.preventDefault();
        $(this).hide().prev().hide();
        $(this).next().show();
    });

    $('a.less', minimized_elements).click(function(event){
        event.preventDefault();
        $(this).parent().hide().prev().show().prev().show();
    });
}));

