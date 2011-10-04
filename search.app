module search

define page search(namespace:String, q:String){
  var query := q;
  var searcher := toSearcher(query, namespace);

  navigate(root()){"return to home"}
  includeJS("jquery-1.5.min.js")
  includeJS("jquery-ui-1.8.9.custom.min.js")
  includeCSS("jquery-ui.css")
  var source := "/autocompleteService"+"/"+namespace;
  <script>
  $(function() {
		$( "#searchfield" ).autocomplete({
			autoFocus: true,
			source: contextpath+"~source",
			minLength: 1,
			delay: 200
		});
	});
  </script>
  

  form {
  	<div class="ui-widget">
    input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()]
	submit action{return search(namespace,query);} {"search"}
	</div>    
  }  
  
  table{row{column{placeholder suggestionsOutputPh{} } } }
  
  action updateResults(){
    searcher := toSearcher(query,namespace); //update with entered query
    replace(resultArea,paginatedResults(searcher,1,10));
    //HTML5 feature, replace url without causing page reload
    runscript("window.history.replaceState('','','"+navigate(search(namespace,query))+"');");
  }
  
  paginatedTemplate(searcher, 10)
}

//[focus] 
//autocomplete service Entry contentcase
//AutoComplete(ent,props) ->  where props van ent
//declare:  service autocompleteServiceEnt(namespace:String,term : String)
//override autocomplete:
//balabl { <x>.autoocomplet  }
// principal is User with credentials username

service autocompleteService(namespace:String, term : String){ 

  var jsonArray := JSONArray();//<Entity> autoCompleteSuggest contentcase;  "213content"
  var results := EntrySearcher.autoCompleteSuggest(term,namespace,["contentcase","filename_autocomplete"], 10);
    
  for(sug : String in results){
    jsonArray.put(sug);    
    //jsonArray.put(sug.replace(term, "<b>"+term+"</b>"));
  }  
  return jsonArray;
}

function toSearcher(q:String, namespace:String) : EntrySearcher{
  var searcher := EntrySearcher();
  var patchedUserQuery := EntrySearcher.escapeQuery(q);	
  return searcher.defaultAnd().setNamespace(namespace).query(patchedUserQuery);
}
  
define ajax viewAutoComplete(suggestions : List<String>, namespace:String){
  if(suggestions.length > 0) {
    list{
      for(sug : String in suggestions){
        listitem{ navigate(search(namespace,sug)){output(sug)} }
      }
    }
  }
}


define highlightedResult(cf : Entry, searcher : EntrySearcher){
  //var code : String := rendertemplate(output(searcher.highlight("code",cf.code,"$OHL$","$CHL$"))).replace("\n","<br/>").replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>")
  div{ output(cf.url) }
    //for(line:Entry in cf.lines){
      for(s:String in highlightedResult(cf,searcher)){
        div { rawoutput(s) }
      }
    //} 
  <br/>
}

function highlightedResult(line:Entry,searcher : EntrySearcher):List<String>{
  var raw := searcher.highlight("content",line.content,"$OHL$","$CHL$");
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

  define paginatedTemplate(sq :EntrySearcher, resultsPerPage : Int){
    placeholder resultArea{
        paginatedResults(sq,1,resultsPerPage)
    }
  }

  define ajax paginatedResults(query : EntrySearcher, pagenumber : Int, resultsPerPage : Int){
    var resultList := query.firstResult((pagenumber - 1) * resultsPerPage).maxResults(resultsPerPage).list();
    var size := query.resultSize();
    var lastResult := size;
    init{
      if(size > pagenumber*resultsPerPage){
        lastResult := pagenumber * resultsPerPage;
      }
    }
    if(query.query().length()>0){
      par{
        output(size) " results found in " output(query.searchTimeAsString()) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
      }
      list{
      for (e : Entry in resultList){
        listitem{ highlightedResult(e, query)} 
      }}
      par{
        resultIndex(query, pagenumber, resultsPerPage)
      }
    }
  }
  
  define resultIndex (query: EntrySearcher, pagenumber : Int, resultsPerPage : Int){  		
    var totalPages := (query.resultSize().floatValue() / resultsPerPage.floatValue()).ceil()
    var start : Int := SearchHelper.firstIndexLink(pagenumber,totalPages, 9) //9 index links at most
    var end : Int := SearchHelper.lastIndexLink(pagenumber,totalPages, 9)
  if(totalPages > 1){
      if (pagenumber > 1){
        submit("|<<", showResultsPage(query, 1, resultsPerPage))
        submit("<", showResultsPage(query, pagenumber-1, resultsPerPage))
      }	
      for(pagenum:Int from start to pagenumber){
       gotoresultpage(query, pagenum, resultsPerPage)
      }
      "-"output(pagenumber)"-"  	
      for(pagenum:Int from pagenumber+1 to end+1){
       gotoresultpage(query, pagenum, resultsPerPage)	
      }	 
      if(pagenumber < totalPages){
        submit(">", showResultsPage(query, pagenumber+1, resultsPerPage))
        submit(">>|", showResultsPage(query, totalPages, resultsPerPage))
      }
    }
    action showResultsPage(query: EntrySearcher, pagenumber : Int, resultsPerPage : Int){replace(resultArea, paginatedResults(query, pagenumber, resultsPerPage));}
  }
  
  define gotoresultpage(query: EntrySearcher, pagenum: Int, resultsPerPage: Int){
    submit(pagenum, showResultsPage(query, pagenum, resultsPerPage))
    action showResultsPage(query: EntrySearcher, pagenumber : Int, resultsPerPage : Int){
      replace(resultArea, paginatedResults(query, pagenumber, resultsPerPage));
    }	
  } 

native class org.webdsl.search.SearchHelper as SearchHelper {
     static firstIndexLink(Int, Int, Int): Int
     static lastIndexLink(Int, Int, Int): Int
  }



