
function prettifyAndMakeClickable(projectName){
  $(function(){
    prettyPrint();
    // make words clickable to start a new search:
    $("span.pln, span.typ, span.kwd").each(function(index){ 
      if(projectName === undefined){
        var url = $(location).attr("href");
        var index = url.lastIndexOf('/');
        var urlstart = url.substr(0,index+1);
      }
      else{
        var urlstart = contextpath+"/search/"+projectName+"/";
      }
      var searchterm = $.trim($(this).html());
      //$(this).html("<a href='"+urlstart+$(this).html()+"'>"+$(this).html()+"</a>");
      $(this).click(function(){ window.open(urlstart+searchterm); });
      $(this).mouseover(function(){
        $(this).addClass('hover');
      });	         
      $(this).mouseout(function(){
        $(this).removeClass('hover');
      });
    });
  })
}
