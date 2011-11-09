module search

define page search(namespace:String, q:String){
  var query := q;
  var searcher := toSearcher(query, namespace);

  navigate(root()){"return to home"}
  includeJS("jquery-1.5.min.js")
  includeJS("jquery-ui-1.8.9.custom.min.js")
  includeCSS("jquery-ui.css")
  var source := "/autocompleteService"+"/"+namespace;
  includeJS("completion.js")
  <script>
    setupcompletion("~source");
  </script>
  

  form {
  	<div class="ui-widget">
    input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()]
	submit action{return search(namespace,query);} {"search"}
	</div>    
  }  
    
  action updateResults(){
    searcher := toSearcher(query,namespace); //update with entered query
    
    replace(resultAndfacetArea, paginatedTemplate(searcher,10,namespace));
    //HTML5 feature, replace url without causing page reload
    runscript("window.history.replaceState('','','"+navigate(search(namespace,query))+"');");
  }
  
  placeholder resultAndfacetArea{
	  if (q.length() > 0){
	  	 paginatedTemplate(searcher, 10, namespace)
	  }
  }
}

service autocompleteService(namespace:String, term : String){
  var jsonArray := JSONArray();
  var results := EntrySearcher.autoCompleteSuggest(term,namespace,["contentcase","filename_autocomplete"], 20);
    
  for(sug : String in results){
    jsonArray.put(sug);    
  }  
  return jsonArray;
}

function toSearcher(q:String, ns:String) : EntrySearcher{
  var searcher := search Entry matching q in namespace ns [nolucene, strict matching];   
  if (ns.length() > 0) {
      ~searcher with facets (file_ext, 60);
  }
  return searcher;
}

define navWithAnchor(n:String,a:String){
    rawoutput{ <a all attributes href=n+"#"+a>	elements </a> }
  }

define highlightedResult(cf : Entry, searcher : EntrySearcher){
  var highlightedContent : List<String>;
  var ruleOffset : String; 
  var linkText := cf.name;
  var location := cf.url.substring(0, cf.url.length() - cf.name.length() );
  
  init{
  	highlightedContent := highlightedResult(cf, searcher);
  	ruleOffset := "";
  	if(highlightedContent.length > 0){
  		ruleOffset := /\D+>(\d+).*/.replaceFirst("$1",highlightedContent[0]);
  	}
  	if(ruleOffset.length() > 5){
  		if(highlightedContent.length > 1){
  			ruleOffset := /\D+\>(\d+).*/.replaceFirst("$1",highlightedContent[1]);
  		}
  		if(ruleOffset.length() > 5) {
  			ruleOffset := "";
  		}
  	}
  	
  }
  
  div[class="searchresultlink"]{
  	navWithAnchor(navigate(showFile(searcher, cf)), ruleOffset){div[class="searchresultlocation"]{ output(location) } <b>output(linkText)</b>}    
  }
   div[class="searchresulthighlight"]{ 
      <pre>rawoutput(highlightedContent.concat("\n"))</pre>
    }
}


function highlightedResult(entry:Entry,searcher : EntrySearcher):List<String>{
  var raw := searcher.highlight("content", entry.content, "$OHL$","$CHL$", 2, 150, "\n");
  var highlighted := rendertemplate(output(raw)).replace("$OHL$","<span class=\"highlight\">").replace("$CHL$","</span>");
  var splitted := highlighted.split("\n");
  var list := List<String>();
  var alt := false;
  var style := "b";
  for(s:String in splitted){
  	//If highlighted text doesnt contain the linenumber at the beginning, put ... as line number
  	//We alternate between style a and b for different fragments
  	  if(/^\D/.find(s)){
  	  	if(list.length == 0){
  	  		list.add("<div class=\"linenumber" + style +"\"> </div>" + s);
  	  	} else {
	  	  	if(alt) {
	  	  		style := "b";
	  	  		alt := false;
	  	  	} else {
	  	  		alt := true;
	  	  		style := "a";
	  	  	}
	  	  	list.add("<div class=\"nolinenumber" + style +"\">...</div>\n<div class=\"linenumber" + style +"\"> </div>" + s);
	    }
  	  } else {
  	  	list.add(/(^\d+)\s?/.replaceAll("<div class=\"linenumber" + style +"\">$1</div>", s));
  	  }  	  
  }
  return list;
}

  define ajax paginatedTemplate(searcher :EntrySearcher, resultsPerPage : Int, namespace : String){

  		if(searcher.query().length() > 0) {
  			viewFacets(searcher, resultsPerPage, namespace)
  		}
	    placeholder resultArea{
	        paginatedResults(searcher,1,resultsPerPage)
	    }
    
  }
  
  define viewFacets(searcher :EntrySearcher, resultsPerPage : Int, namespace : String){
  	var hasSelection := [f | f : Facet in searcher.getFilteredFacets() where !f.isMustNot() ].length > 0;
   	if (namespace.length() > 0) {
		div[id="facet-selection"]{
  			div{<i>"Filter on file extension:"</i>}	
	        for(f : Facet in get all facets(searcher, file_ext) ) {
		        if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
		        	div[class="excludedFacet"]{
			        	if(f.isSelected()) {
			        		includeFacetSym()
			        		submitlink action{replace(resultAndfacetArea, paginatedTemplate(searcher.removeFilteredFacet(f), resultsPerPage, namespace));}{output(f.getValue()) " (" output(f.getCount()) ")"}
			          	} else {
			          		includeFacetSym()
			          		submitlink action{replace(resultAndfacetArea, paginatedTemplate((~searcher where f.should()), resultsPerPage, namespace));}{output(f.getValue()) " (" output(f.getCount()) ")"}
			          	}				          	
		         	}
		         } else {
		         	div[class="includedFacet"]{
		         		if(f.isSelected()) {
		          			submitlink action{replace(resultAndfacetArea, paginatedTemplate(searcher.removeFilteredFacet(f), resultsPerPage, namespace));}{excludeFacetSym output(f.getValue()) " (" output(f.getCount()) ") "}
		          		} else {
		          			submitlink action{replace(resultAndfacetArea, paginatedTemplate( (~searcher where f.mustNot() ), resultsPerPage, namespace));}{excludeFacetSym}
		          			submitlink action{replace(resultAndfacetArea, paginatedTemplate((~searcher where f.should()), resultsPerPage, namespace));}{output(f.getValue()) " (" output(f.getCount()) ")"}
		          			" " 
		          		}
		          	}        	
		        }
	        }
  	 	}
  	 }
  }
  
  define excludeFacetSym(){
  	<div class="excludefacetsym">"x"</div>  	
  }
  define includeFacetSym(){
  	<div class="includefacetsym">"v"</div>
  }

  define ajax paginatedResults(searcher : EntrySearcher, pagenumber : Int, resultsPerPage : Int){
    var resultList := get results(~searcher start ((pagenumber - 1) * resultsPerPage) limit resultsPerPage);
    var size := get size(searcher);
    var lastResult := size;
    init{
      if(size > pagenumber*resultsPerPage){
        lastResult := pagenumber * resultsPerPage;
      }
    }
    
    if(searcher.query().length()>0){
      div{
        if(size > 0) {	      
	      output(size) " results found in " output(get searchtime(searcher)) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
        } else {
      	  "no results found"
      	}
      }
      for (e : Entry in resultList){
        highlightedResult(e, searcher) 
      }
      par{
        resultIndex(searcher, pagenumber, resultsPerPage)
      }
    }
  }
  
  define resultIndex (searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int){  		
    var totalPages := (get size(searcher).floatValue() / resultsPerPage.floatValue()).ceil()
    var start : Int := SearchHelper.firstIndexLink(pagenumber,totalPages, 9) //9 index links at most
    var end : Int := SearchHelper.lastIndexLink(pagenumber,totalPages, 9)
    if(totalPages > 1){
      if (pagenumber > 1){
        submit("|<<", showResultsPage(searcher, 1, resultsPerPage))
        submit("<", showResultsPage(searcher, pagenumber-1, resultsPerPage))
      }	
      for(pagenum:Int from start to pagenumber){
       gotoresultpage(searcher, pagenum, resultsPerPage)
      }
      "-"output(pagenumber)"-"  	
      for(pagenum:Int from pagenumber+1 to end+1){
       gotoresultpage(searcher, pagenum, resultsPerPage)	
      }	 
      if(pagenumber < totalPages){
        submit(">", showResultsPage(searcher, pagenumber+1, resultsPerPage))
        submit(">>|", showResultsPage(searcher, totalPages, resultsPerPage))
      }
    }
    action showResultsPage(searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int){
      replace(resultArea, paginatedResults(searcher, pagenumber, resultsPerPage));
    } 
  }
  
  define gotoresultpage(searcher: EntrySearcher, pagenum: Int, resultsPerPage: Int){
    submit(pagenum, showResultsPage(searcher, pagenum, resultsPerPage))
    action showResultsPage(searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int){
      replace(resultArea, paginatedResults(searcher, pagenumber, resultsPerPage));
    }	
  } 

native class org.webdsl.search.SearchHelper as SearchHelper {
     static firstIndexLink(Int, Int, Int): Int
     static lastIndexLink(Int, Int, Int): Int
  }

define page showFile(searcher : EntrySearcher, cf : Entry){
  var linkText : String;
  var location : String;
  var highlighted : String;
  init{
  	linkText := cf.name;
    location := cf.url.substring(0, cf.url.length() - cf.name.length() );
    highlighted := searcher.highlight("content", cf.content, "$OHL$","$CHL$", 1, 9000000, " ");
    if( highlighted.length() == 0 ){
    	highlighted := cf.content;
    }
  }
  div[class="searchresultlink"]{
    navigate(url(cf.url)){ div[class="searchresultlocation"]{ output(location) } <b>output(linkText)</b> } 
  }
  div[class="searchresulthighlight"]{ 
    <pre>rawoutput( /(^|\n)(\d+)\s?([^\r\n$])/.replaceAll("$1<span class=\"linenumberb\"><a name=\"$2\"></a>$2</span>$3", rendertemplate(output(highlighted)).replace("$OHL$","<span class=\"highlight\">").replace("$CHL$","</span>")))</pre>
  }
}

