jQuery(function(){

    var minimized_elements = $('p.description');

    minimized_elements.each(function(){
        // TODO: Threshold should probably be passed in as a parameter.
        var threshold = 500;
        if ($(this).text().length <= threshold) return;

        $md = $($.parseHTML($(this).html()));
        var m = $md.length;
        var n = 0;
        var text = "";
        var total = 0;
        $(this).html(text);
        for(n=0; n<m; n++){
          // Text nodes have a nodeType of 3
          text = ($md[n].nodeType == 3) ? $md[n].data : $md[n].innerText;
          total += text.length;
          if (total > threshold) break;
          $(this).append($md[n]);
        }

        var index = text.length - (total - threshold);
        $clone = $($md[n]).clone();
        // Text nodes have a nodeType of 3
        if ($md[n].nodeType == 3) {
          $clone[0].textContent = text.slice(0,index);
          $md[n].textContent = text.slice(index,text.length);
        } else {
          $clone[0].innerHTML = text.slice(0,index);
          $md[n].innerHTML = text.slice(index,text.length);
        }
        $(this).append($clone[0]);
        $(this).append('<span>... </span><a href="#" class="more">More</a>');
        $less = $('<span style="display:none;"></span>');
        for(; n<m; n++){
          $less.append($md[n]);
        }
        $less.append(' <a href="#" class="less">Less</a>');
        $(this).append($less);
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
});
