module search

define page search(namespace:String, q:String){
  showSearch(toSearcher(q, namespace), namespace, 1)
}

define page doSearch(searcher : EntrySearcher, namespace:String, pageNum: Int){
	showSearch(searcher, namespace, pageNum)
}

define showSearch (entrySearcher : EntrySearcher, namespace : String, pageNum: Int){
  navigate(root()){"return to home"}
  includeJS("jquery-1.5.min.js")
  includeJS("jquery-ui-1.8.9.custom.min.js")
  includeCSS("jquery-ui.css")
  includeJS("completion.js")
  var source := "/autocompleteService"+"/"+namespace;
  var searcher := entrySearcher;
  var query := searcher.query();  
  
  <script>
    setupcompletion("~source");
  </script>  

  form {
  	<div class="ui-widget">
    input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()]
	submit action{return search(namespace,query);} {"search " output(namespace)}
	</div>    
  }  
  
  action updateResults(){
  	if(query.length() > 0){  		  		
	    searcher := toSearcher(query,namespace); //update with entered query	      
	    replace(resultAndfacetArea, paginatedTemplate(searcher, 10, 1, namespace));	    
	    //HTML5 feature, replace url without causing page reload
	    runscript("window.history.replaceState('','','" + navigate(doSearch(searcher, namespace, 1) ) + "');");
    } else {
    	clear(resultAndfacetArea);
    }
  }
  
  placeholder resultAndfacetArea{
	  if (query.length() > 0){
	  	 paginatedTemplate(searcher, 10, pageNum, namespace)
	  }
  }
}

service autocompleteService(namespace:String, term : String){
  var jsonArray := JSONArray();
  var results := EntrySearcher.autoCompleteSuggest(term,namespace,["contentHyphenCase","file_name"], 20);
    
  for(sug : String in results){
    jsonArray.put(sug);    
  }  
  return jsonArray;
}

define navWithAnchor(n:String,a:String){
    rawoutput{ <a all attributes href=n+"#"+a>	elements </a> }
  }

define highlightedResult(cf : Entry, searcher : EntrySearcher){
  var highlightedContent : List<List<String>>;
  var ruleOffset : String; 
  var linkText := cf.name;
  var location := cf.url.substring(0, cf.url.length() - cf.name.length() );
  
  init{
  	highlightedContent := highlightCodeLines(searcher, cf, 150, 2);
  	ruleOffset := "";
  	if(highlightedContent[0].length > 0){
  		ruleOffset := /\D+>(\d+).*/.replaceFirst("$1",highlightedContent[0][0]);
  	}
  	if(ruleOffset.length() > 5){
  		if(highlightedContent[0].length > 1){
  			ruleOffset := /\D+\>(\d+).*/.replaceFirst("$1",highlightedContent[0][1]);
  		}
  		if(ruleOffset.length() > 5) {
  			ruleOffset := "1";
  		}
  	}
  	ruleOffset := "" + (ruleOffset.parseInt() - 3);
  }
  
  div[class="search-result-link"]{
  	navWithAnchor(navigate(showFile(searcher, cf)), ruleOffset){div[class="search-result-location"]{ output(location) } <b>output(linkText)</b>}    
  }
   <div class="search-result-highlight">
   	 <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(highlightedContent[0].concat("<br />"))</div>
   	 <div class="code-area" style="left: 3.1em;"><pre style="WHITE-SPACE: pre">rawoutput(highlightedContent[1].concat("<br />"))</pre></div>
   </ div>
   
}

  define ajax paginatedTemplate(searcher :EntrySearcher, resultsPerPage : Int, pageNum : Int, ns : String){

  		if(searcher.query().length() > 0) {
  			viewFacets(searcher, resultsPerPage, ns)
  		}
	    div[class="main-container"]{
	        paginatedResults(searcher, pageNum, resultsPerPage, ns)
	    }
    
  }
  
  define viewFacets(searcher : EntrySearcher, resultsPerPage : Int, namespace : String){
  	var hasSelection := [f | f : Facet in searcher.getFilteredFacets() where !f.isMustNot() ].length > 0;
  	

	div[class="top-container"]{
		div{<i>"Filter on file extension:"</i>}	
        for(f : Facet in get all facets(searcher, file_ext) ) {
	        if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
	        	div[class="excluded-facet"]{
		        	if(f.isSelected()) {
		        		includeFacetSym()
		        		submitlink updateResults(searcher.removeFilteredFacet(f)){output(f.getValue()) " (" output(f.getCount()) ")"}
		          	} else {
		          		includeFacetSym()
		          		submitlink updateResults(~searcher where f.should()){output(f.getValue()) " (" output(f.getCount()) ")"}
		          	}				          	
	         	}
	         } else {
	         	div[class="included-facet"]{
	         		if(f.isSelected()) {
	          			 submitlink updateResults(searcher.removeFilteredFacet(f)){excludeFacetSym() output(f.getValue()) " (" output(f.getCount()) ") "}
	          		} else {
	          			submitlink updateResults(~searcher where f.mustNot() ) {excludeFacetSym()}
	          			submitlink updateResults(~searcher where f.should()  ) {output(f.getValue()) " (" output(f.getCount()) ")"}
	          			" " 
	          		}
	          	}        	
	        }
        }
 	}

  	 
  	action updateResults(searcher : EntrySearcher){  		    
	    return doSearch(searcher, namespace, 1);
    }
  
  }
  
  define excludeFacetSym(){
  	<div class="exclude-facet-sym">"x"</div>  	
  }
  define includeFacetSym(){
  	<div class="include-facet-sym">"v"</div>
  }

  define ajax paginatedResults(searcher : EntrySearcher, pagenumber : Int, resultsPerPage : Int, namespace : String){
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
        resultIndex(searcher, pagenumber, resultsPerPage, namespace)
      }
    }
  }
  
  define resultIndex (searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int, ns : String){  		
    var totalPages := (get size(searcher).floatValue() / resultsPerPage.floatValue()).ceil()
    var start : Int := SearchHelper.firstIndexLink(pagenumber,totalPages, 9) //9 index links at most
    var end : Int := SearchHelper.lastIndexLink(pagenumber,totalPages, 9)
    if(totalPages > 1){
      if (pagenumber > 1){
        submit("|<<", showResultsPage(searcher, 1))
        submit("<", showResultsPage(searcher, pagenumber-1))
      }	
      for(pagenum:Int from start to pagenumber){
       gotoresultpage(searcher, pagenum, ns)
      }
      "-"output(pagenumber)"-"  	
      for(pagenum:Int from pagenumber+1 to end+1){
       gotoresultpage(searcher, pagenum, ns)	
      }	 
      if(pagenumber < totalPages){
        submit(">", showResultsPage(searcher, pagenumber+1))
        submit(">>|", showResultsPage(searcher, totalPages))
      }
    }
    action showResultsPage(searcher: EntrySearcher, pagenumber : Int){
      return doSearch(searcher, ns, pagenumber);
    } 
  }
  
  define gotoresultpage(searcher: EntrySearcher, pagenum: Int, ns : String){
    submit action{return doSearch(searcher, ns, pagenum);}{output(pagenum)}
  } 

native class org.webdsl.search.SearchHelper as SearchHelper {
     static firstIndexLink(Int, Int, Int): Int
     static lastIndexLink(Int, Int, Int): Int
  }

define page showFile(searcher : EntrySearcher, cf : Entry){
  var linkText    : String;
  var location    : String;
  var lineNumbers : String;
  var codeLines   : String;  
  var highlighted : List<List<String>>;
  
  init{
  	linkText := cf.name;
    location := cf.url.substring(0, cf.url.length() - cf.name.length() );
    highlighted := highlightCodeLines( searcher, cf, 1000000, 2 );
    if( highlighted[0].length != 0 ){
    	lineNumbers := highlighted[0].concat("<br />");
    	codeLines := highlighted[1].concat("<br />");    	
    	//add line number anchors
    	lineNumbers := />(\d+)</.replaceAll( "><a name=\"$1\">$1</a><", lineNumbers );
    } else {
    	lineNumbers := "";
    	codeLines := cf.content;
    }    
  }
  div[class="search-result-link"]{
    navigate(url(cf.url)){ div[class="search-result-location"]{ output(location) } <b>output(linkText)</b> } 
  }
  <div class="search-result-highlight">
   	 <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(lineNumbers)</div>
   	 <div class="code-area" style="left: 3.1em;"><pre style="WHITE-SPACE: pre">rawoutput(codeLines)</pre></div>
   </ div>
}

function toSearcher(q:String, ns:String) : EntrySearcher{
  var searcher := search Entry matching q in namespace ns with facets (file_ext, 120) [nolucene, strict matching];   
  return searcher;
}

function highlightCodeLines(searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int) : List<List<String>>{
  var raw := searcher.highlight("contentHyphenSym", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  if(raw.length() < 1){
  	//search field contentHyphenSym does not match anything (no fragment from highlighting), try highlighting on less restrictive searchfield
  	raw := searcher.highlight("content", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  }
  var highlighted := rendertemplate(output(raw)).replace("$OHL$","<span class=\"highlight\">").replace("$CHL$","</span>");//.replace("\r", "");
  var splitted := highlighted.split("\n");
  var listCode := List<String>();
  var listLines := List<String>();
  var lists := List<List<String>>();
  var lineNum : String;
  var alt := false;
  var style := "b";
  for(s:String in splitted){
  	//We alternate between style a and b for different fragments
    if(/^%frgmtsep%/.find(s)){
	  if(alt) {
	  	style := "b";
	  	alt := false;
	  } else {
	  	alt := true;
	  	style := "a";
	  }
	  listLines.add("<div class=\"nolinenumber" + style +"\">...</div>" );
	  listCode.add("");
	} else {
	  //If line number is stripped off by highlighting, put a hyphen as line number
	  if(/^\D/.find(s)){
	    listLines.add("<div class=\"linenumber" + style + "\">-</div>");
	    listCode.add(s);
	  } else {
	    // line numbers are added at the beginning of code lines followed by a whitespace 
	    // original: 'foo:bar'
	  	// modified: '34 foo:bar '
	  	lineNum := /^(\d+).*/.replaceFirst("$1", s);
	  	listLines.add("<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + lineNum + "</div>" );
	  	if (s.length() != lineNum.length()){
	  	  listCode.add(s.substring(lineNum.length() + 1));
	    } else {
	      //if code line itself is an empty line, substring will encounter an empty string -> exception
	  	  listCode.add("");
	  	}
	  } 
	}
  }
  lists.add(listLines);
  lists.add(listCode);
  return lists;	
}