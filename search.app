module search

define page search(p:Project, q:String){
  var query := q;
  var searchQuery := EntrySearchQuery();
  navigate(root()){"return to home"}

  init {
  	if(q.length()>0){
  	  searchQuery := toSearchQuery(query,p.name);
  	}  	  
  }
  
  form {
    input(query)[autocomplete="off", onkeyup = action{replace(suggestionsOutputPh,viewAutoComplete(EntrySearchQuery.autoCompleteSuggest(query,["content"], 10),p));}]
    action ("search", action{return search(p,query);})[ajax]
  }  
  
  table{row{column{placeholder suggestionsOutputPh{} } } }
  
  placeholder results{
  	if(query.length()>0){
  		paginatedTemplate(searchQuery, 10)
  	}
  }
  		
}

function toSearchQuery(q:String, projectname: String) : EntrySearchQuery{
	var searchQuery := EntrySearchQuery();
	var patchedUserQuery := EntrySearchQuery.escapeQuery(q);	
	return searchQuery.defaultAnd().filterByField("projectname",projectname).query(patchedUserQuery);
}


  
define ajax viewAutoComplete(suggestions : List<String>, p:Project){
  if(suggestions.length > 0) {
    list{
      for(sug : String in suggestions){
        listitem{ navigate(search(p,sug)){output(sug)} }
      }
    }
  }
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



  define paginatedTemplate(sq : EntrySearchQuery, resultsPerPage : Int){  	
  	placeholder resultArea{
  		paginatedResults(sq,1,resultsPerPage)
  	}
  }

  define ajax paginatedResults(query : EntrySearchQuery, pagenumber : Int, resultsPerPage : Int){
  	var lastResult : Int;
  	var size := query.resultSize();
  	var resultList := query.firstResult((pagenumber - 1) * resultsPerPage).maxResults(resultsPerPage).list();
  	init{
  		if(size > pagenumber*resultsPerPage){
  			lastResult := pagenumber * resultsPerPage;
  		}
  	}
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
  
  define resultIndex (query: EntrySearchQuery, pagenumber : Int, resultsPerPage : Int){  		
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
  	action showResultsPage(query: EntrySearchQuery, pagenumber : Int, resultsPerPage : Int){replace(resultArea, paginatedResults(query, pagenumber, resultsPerPage));}
  }
  
  define gotoresultpage(query: EntrySearchQuery, pagenum: Int, resultsPerPage: Int){
  	submit(pagenum, showResultsPage(query, pagenum, resultsPerPage))
  	action showResultsPage(query: EntrySearchQuery, pagenumber : Int, resultsPerPage : Int){replace(resultArea, paginatedResults(query, pagenumber, resultsPerPage));}	
  } 

native class org.webdsl.search.SearchHelper as SearchHelper {
     static firstIndexLink(Int, Int, Int): Int
     static lastIndexLink(Int, Int, Int): Int
  }



