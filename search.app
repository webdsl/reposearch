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

function toSearcher(q:String, ns:String) : EntrySearcher{
  var searcher := search Entry matching q in namespace ns [nolucene, strict matching];
   
  if (ns.length() > 0) {
      ~searcher with facets (file_ext, 60);
  }
  return searcher;
}

define highlightedResult(cf : Entry, searcher : EntrySearcher){
  //var code : String := rendertemplate(output(searcher.highlight("code",cf.code,"$OHL$","$CHL$"))).replace("\n","<br/>").replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>")
  var linkText : String := cf.name;
  var location : String := cf.url.substring(0, cf.url.length() - cf.name.length() );
  
  div[class="searchresultlink"]{
    navigate(url(cf.url)){ div[class="searchresultlocation"]{ output(location) } <b>output(linkText)</b> } 
    
  }
   div[class="searchresulthighlight"]{ 
    //for(line:Entry in cf.lines){
      for(s:String in highlightedResult(cf,searcher)){
        div { rawoutput(s) }
      }
    //} 
    }
}

function highlightedResult(entry:Entry,searcher : EntrySearcher):List<String>{
  var i : Int := 0;
  var contentLine := addLines(entry.content);
  var raw := highlight contentLine for searcher on content surround with ("$OHL$","$CHL$");
  // var highlighted := rendertemplate(output(raw)).replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>").replace("$LNO$","<div class=\"linenumber\">").replace("$LNC$","</div>");
  var highlighted := rendertemplate(output(raw)).replace(" ","&nbsp;").replace("$OHL$","<b>").replace("$CHL$","</b>");
  var splitted := highlighted.split("\n");
  var list := List<String>();
  var previous := "";
  var toAdd : String;
  for(s:String in splitted){
    if(s!=""&&s.contains("<b>")){
      toAdd := /^\d+:/.replaceAll("<div class=\"linenumber\">$0&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</div>",s);
      list.add(/*previous+"<br/>"+*/toAdd);
    }
    previous := s;
  }
  return list;
}

function addLines(content : String) : String{
	var lines  := /\n/.split(content);
	var currentLine : String;
	var number : Int := 1;
	var toReturn := "";
	for(l : String in lines){
		// currentLine := "$LNO$" + number + ":$LNC$      " + l;		
		currentLine := number + ":" + l;
		toReturn := toReturn + currentLine + "\n";
		number := number + 1; 
	}
	
	return toReturn;
}

  define ajax paginatedTemplate(searcher :EntrySearcher, resultsPerPage : Int, namespace : String){
  		// searcher := search Entry matching q

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
        output(size) " results found in " output(get searchtime(searcher)) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
      }
      //list{
      for (e : Entry in resultList){
        highlightedResult(e, searcher) 
      }//}
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
    action showResultsPage(searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int){replace(resultArea, paginatedResults(searcher, pagenumber, resultsPerPage));}
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


 // define page showFile(e:Entry){
 //   output(/\n/.replaceAll("<br />", e.content))
 //   <br/>
 //   <br/>
 //   var c := /\n/.split(e.content)
 //   for(i:Int from 0 to c.length){
 //     div{
 //       output(i+1) " : " output(c[i])
 //     }
 //   }
 // }


