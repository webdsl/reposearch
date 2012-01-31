module search

define page search(namespace:String, q:String){
  title { output(q + " - Reposearch") }
  
  showSearch(toSearcher(q, namespace), namespace, 1)
}

define page doSearch(searcher : EntrySearcher, namespace:String, pageNum: Int){
	title { output("Reposearch - '" + searcher.query() +  "' in " + namespace) }
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
	    replace(resultAndfacetArea, paginatedTemplate(searcher, 1, namespace));	    
	    //HTML5 feature, replace url without causing page reload
	    runscript("window.history.replaceState('','','" + navigate(doSearch(searcher, namespace, 1) ) + "');");
    } else {
    	clear(resultAndfacetArea);
    }
  }
  
  placeholder resultAndfacetArea{
	  if (query.length() > 0){
	  	 paginatedTemplate(searcher, pageNum, namespace)
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
  var linkText := "";
  var location := cf.url.substring(0, cf.url.length() - cf.name.length() );
  
  init{
  	linkText := searcher.highlight("file_name", cf.name, "<u>","</u>", 1, 256, "");
  	if(linkText.length() < 1){
  		linkText := cf.name;
  	}  	
  	highlightedContent := highlightCodeLines(searcher, cf, 150, 2, false);
  	ruleOffset := "";
  	if(highlightedContent[0].length < 1){
  		ruleOffset := "1";
  	} else {
  		ruleOffset := /\D+>(\d+).*/.replaceFirst("$1",highlightedContent[0][0]);
  		
  		if( !(/^\d+$/.match(ruleOffset))  && highlightedContent[0].length > 1){
  			ruleOffset := /\D+\>(\d+).*/.replaceFirst("$1",highlightedContent[0][1]);
        }
        if( !(/^\d+$/.match(ruleOffset)) ) {
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

  define ajax paginatedTemplate(searcher :EntrySearcher, pageNum : Int, ns : String){
  		if(searcher.query().length() > 0) {
  			viewFacets(searcher, ns)
	    	
	    	div[class="main-container"]{
	        paginatedResults(searcher, pageNum, ns)
	        }
        }
  }
  
  define viewFacets(searcher : EntrySearcher, namespace : String){
  	var selected         := searcher.getFilteredFacets();
  	var selected         := searcher.getFilteredFacets();
  	var path_hasSel      := false;
  	var ext_hasSel       := false;
  	var path_selection   := List<Facet>();
  	init {
  		for ( f : Facet in selected ){
  			if ( f.getFieldName() == "file_ext" && !f.isMustNot() ) {
  				ext_hasSel := true;
  			} else { if ( f.getFieldName() == "repo_path" ) {
  				path_selection.add(f);
  				if( !f.isMustNot() ) {
  				  path_hasSel := true;
  				}
  			}}
  		}
  	}
	div[class="top-container"]{
		div[class="facet-area"]{"Filter on file extension:"}
		div{
	      for(f : Facet in get all facets(searcher, file_ext) ) {	showFacet(searcher, f, ext_hasSel, namespace) }
        }
        div[class="facet-area"]{"Filter on file location:"}
        for (f : Facet in path_selection) { showFacet(searcher, f, path_hasSel, namespace) <br /> }
        placeholder repo_pathPh{       	  
          showpathfacets(searcher, path_hasSel, namespace, false)
        }
 	} 	 
  }
  
  define ajax showpathfacets(searcher : EntrySearcher, hasSelection : Bool, namespace : String, show : Bool){
  	
  	if( show ){
  	   submitlink action{replace(repo_pathPh, showpathfacets( searcher, hasSelection, namespace, false));}{"shrink"}
  	  div{
  	    for(f : Facet in get all facets(searcher, repo_path) ) {
	      showFacet(searcher, f, hasSelection, namespace) <br />
        }
      }
    } else {
      submitlink action{replace(repo_pathPh, showpathfacets( searcher, hasSelection, namespace, true));}{"expand"}
    }
  }
      
  define showFacet(searcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String) {
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

  define ajax paginatedResults(searcher : EntrySearcher, pagenumber : Int, namespace : String){
  	var resultsPerPage := searchSettings.getResultsPerPage();
  	var options := [5, 10, 25, 50, 100, 500];
    var resultList := get results(~searcher start ((pagenumber - 1) * resultsPerPage) limit resultsPerPage);
    var size := get size(searcher);
    var lastResult := size;
    var current : Int;
    init{
      if(size > pagenumber*resultsPerPage){
        lastResult := pagenumber * resultsPerPage;
      }
    }        
    if(searcher.query().length()>0){
      div{
        if(size > 0) {	      
	      output(size) " results found in " output(get searchtime(searcher)) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
	      " [results per page: " 
	      for(i : Int in options) {
	      	if(resultsPerPage != i){ showOption(searcher, namespace, i) } else { output(i) } " "
	      }
	     "]"
        } else {
      	  "no results found"
      	}
      }
      par{
        resultIndex(searcher, pagenumber, resultsPerPage, namespace)
      }
      for (e : Entry in resultList){
        highlightedResult(e, searcher) 
      }
      par{
        resultIndex(searcher, pagenumber, resultsPerPage, namespace)
      }
    }    
    
  }
  
  define showOption(searcher : EntrySearcher, namespace : String, new : Int) {
  	submitlink action{ searchSettings.resultsPerPage := new; return doSearch(searcher, namespace, 1); }{ output(new) }
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
  title { output(cf.name + " - Reposearch") }
  var linkText    := "";
  var location    : String;
  var lineNumbers : String;
  var codeLines   : String;  
  var highlighted : List<List<String>>;
  
  init{
  	linkText := searcher.highlight("file_name", cf.name, "<u>","</u>", 1, 256, "");
  	if(linkText.length() < 1){
  		linkText := cf.name;
  	}
    location := cf.url.substring(0, cf.url.length() - cf.name.length() );
    highlighted := highlightCodeLines( searcher, cf, 1000000, 2, true);
	lineNumbers := highlighted[0].concat("<br />");
	codeLines := highlighted[1].concat("<br />");    	
	//add line number anchors
	lineNumbers := />(\d+)</.replaceAll( "><a name=\"$1\">$1</a><", lineNumbers );
  }
  div[class="search-result-link"]{
    navigate(url(cf.url)){ div[class="search-result-location"]{ output(location) } <b>rawoutput(linkText)</b> } 
  }
  <div class="search-result-highlight">
   	 <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(lineNumbers)</div>
   	 <div class="code-area" style="left: 3.1em;"><pre style="WHITE-SPACE: pre">rawoutput(codeLines)</pre></div>
   </ div>
}

function toSearcher(q:String, ns:String) : EntrySearcher{
  var searcher := search Entry matching q in namespace ns with facets (file_ext, 120), (repo_path, 200) [nolucene, strict matching];
  
  return searcher;
}

function highlightCodeLines(searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int, fullContentFallback: Bool) : List<List<String>>{
  var raw := searcher.highlight("contentHyphenSym", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  if(raw.length() < 1){
  	//search field contentHyphenSym does not match anything (no fragment from highlighting), try highlighting on less restrictive searchfield
  	raw := searcher.highlight("content", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  	if(fullContentFallback && raw.length() < 1) {
  		raw := entry.content;
  	}
  }
  var highlighted := rendertemplate(output(raw)).replace("$OHL$","<span class=\"hlcontent\">").replace("$CHL$","</span>");//.replace("\r", "");
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

page searchStats(){
	title { output("Reposearch Search Statistics") }
	showSearchStats()
	submit action{SearchStatistics.clear();}{"Reset statistics"}
}