module search

define page search(p:Project){
  var query := ""
  var searchQuery := EntrySearchQuery();
  navigate(root()){"return to home"}
  form{
    input(query)
    action ("search", action{ replace(results, showResults(searchQuery.defaultAnd().query(EntrySearchQuery.escapeQuery(query)+" AND projectname:"+p.name)));})[ajax]
  }
  placeholder results{}
}

define ajax showResults(searchQuery : EntrySearchQuery){
  var results := searchQuery.maxResults(10).list();
  var count := searchQuery.resultSize();
  "# of results:" output(count)
    //list{
    for (cf : Entry in results){
      //listitem{ 
      highlightedResult(cf, searchQuery)
      //} 
    }
    //}
}
/*
   define ajax codeFragment(cf : CodeFragment){
     par{output(cf.title)}
     par{output(cf.lines)}
   }
*/
define highlightedResult(cf : Entry, searchQuery : EntrySearchQuery){
  //var code : String := rendertemplate(output(searchQuery.highlight("code",cf.code,"$OHL$","$CHL$"))).replace("\n","<br/>").replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>")
  div{ output(cf.url) }
    //for(line:Entry in cf.lines){
      for(s:String in highlightedResult(cf,searchQuery)){
        div { rawoutput(s) }
      }
    //} 
  <br/>
}

function highlightedResult(line:Entry,searchQuery : EntrySearchQuery):List<String>{
  var raw := searchQuery.highlight("content",line.content,"$OHL$","$CHL$");
  var highlighted := rendertemplate(output(raw)).replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>");
  var splitted := highlighted.split("\n");
  var list := List<String>();
  var previous := "";
  for(s:String in splitted){
    if(s!=""&&s.contains("<b>")){
      list.add(/*previous+"<br/>"+*/s);
    }
    previous := s;
  }
  return list;
}
