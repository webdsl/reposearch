module search

define page search(namespace:String, q:String){
  init{  if(q.length() > 0){ incSearchCount(namespace); }  }
  title { output(q + " - Reposearch") }
  showSearch(toSearcher(q, namespace), namespace, 1)
}

define page doSearch(searcher : EntrySearcher, namespace:String, pageNum: Int){
    title { output("Reposearch - '" + searcher.getQuery() +  "' in " + namespace) }
    showSearch(searcher, namespace, pageNum)
}

define showSearch (entrySearcher : EntrySearcher, namespace : String, pageNum: Int){
  var source := "/autocompleteService"+"/"+namespace;
  var searcher := entrySearcher;
  var query := searcher.getQuery();
  var caseSensitive := SearchPrefs.caseSensitive;

  includeJS("jquery-1.5.min.js")
  includeJS("jquery-ui-1.8.9.custom.min.js")
  includeJS("completion.js")
  includeCSS("jquery-ui.css")

  includeCSS("prettify.css")
  includeJS("prettify.js")

  <script>
    setupcompletion("~source");
    //avoid too many request while typing in a field with onkeyup trigger
    var onkeyupdelay = function(){
        var timer = 0; //scoped inside this function block, triggering onkeyup again before timeout resets the timer for that particular action
        return function(callback){
            clearTimeout(timer);
            timer = setTimeout(callback, 500);
        }
    }();
  </script>

  navigate(root()){"return to home"}

  form {
    <div class="ui-widget">
      input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()]
      submit action{return search(namespace,query);} {"search " output(namespace)}
      <br /> input(SearchPrefs.caseSensitive)[onclick=updateResults(), title="Case sensitive search"]{"case sensitive"}
      <br /> input(SearchPrefs.exactMatch)[onclick=updateResults(), title="If enabled, the exact sequence of characters is matched in that order (recommended)"]{"exact match"}
    </div>
  }

  action updateResults(){
      if(query.length() > 2){
        searcher := toSearcher(query,namespace); //update with entered query
        replace(resultAndfacetArea, paginatedTemplate(searcher, 1, namespace));
        //HTML5 feature, replace url without causing page reload
        runscript("window.history.pushState('history','reposearch','" + navigate(doSearch(searcher, namespace, 1) ) + "');");
        incSearchCount(namespace);
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

  function incSearchCount(namespace : String){
    if(namespace != ""){findProject(namespace).incSearchCount();}
  }

service autocompleteService(namespace:String, term : String){
  var jsonArray := JSONArray();
  var results := EntrySearcher.autoCompleteSuggest(term,namespace,["codeIdentifiers","fileName"], 20);

  for(sug : String in results){
    jsonArray.put(sug);
  }

  return jsonArray;
}

define navWithAnchor(n:String,a:String){
    rawoutput{ <a all attributes href=n+"#"+a>    elements </a> }
  }

define highlightedResult(cf : Entry, searcher : EntrySearcher){
  var highlightedContent : List<List<String>>;
  var ruleOffset : String;
  var linkText := "";
  var location := cf.url.substring(0, cf.url.length() - cf.name.length() );

  init{
      linkText := searcher.highlight("fileName", cf.name, "<u>","</u>", 1, 256, "");
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
      navWithAnchor(navigate(viewFile(searcher.getQuery(), cf.url, cf.projectname)), ruleOffset){
        div[class="search-result-location"]{
          output(location)
        }
        <b>
          output(if(linkText.length()>0) linkText else "-")
        </b>
      }
  }
   <div class="search-result-highlight">
        <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(highlightedContent[0].concat("<br />"))</div>
        <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(highlightedContent[1].concat("<br />"))</pre></div>
   </ div>

}

  define ajax paginatedTemplate(searcher :EntrySearcher, pageNum : Int, ns : String){
      //highlight code using google-code-prettify
        //prettify code
        <script>$(function(){prettyPrint();})</script>
          if(searcher.getQuery().length() > 0) {
              viewFacets(searcher, ns)
              div[class="main-container"]{
              paginatedResults(searcher, pageNum, ns)
            }
        }
  }

  define viewFacets(searcher : EntrySearcher, namespace : String){
      var selected         := searcher.getFacetSelection();
      var path_hasSel      := false;
      var ext_hasSel       := false;
      var path_selection   := List<Facet>();
      init {
          for ( f : Facet in selected ){
              if ( f.getFieldName() == "fileExt" && !f.isMustNot() ) {
                  ext_hasSel := true;
              } else { if ( f.getFieldName() == "repoPath" ) {
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
          for(f : Facet in all fileExt facets from searcher ) {    showFacet(searcher, f, ext_hasSel, namespace) }
        }
        div[class="facet-area"]{"Filter on file location:"}
        for (f : Facet in path_selection) { showFacet(searcher, f, path_hasSel, namespace) <br /> }
        placeholder repoPathPh{
          showpathfacets(searcher, path_hasSel, namespace, false)
        }
     }
  }

  define ajax showpathfacets(searcher : EntrySearcher, hasSelection : Bool, namespace : String, show : Bool){

      if( show ){
         submitlink action{replace(repoPathPh, showpathfacets( searcher, hasSelection, namespace, false));}{"shrink"}
        div{
          for(f : Facet in all repoPath facets from searcher) {
          showFacet(searcher, f, hasSelection, namespace) <br />
        }
      }
    } else {
      submitlink action{replace(repoPathPh, showpathfacets( searcher, hasSelection, namespace, true));}{"expand"}
    }
  }

  define showFacet(searcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String) {
    if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
        div[class="excluded-facet"]{
            if(f.isSelected()) {
                includeFacetSym()
                submitlink updateResults(searcher.removeFacetSelection(f)){output(f.getValue()) " (" output(f.getCount()) ")"}
              } else {
                  includeFacetSym()
                  submitlink updateResults(~searcher matching f.should()){output(f.getValue()) " (" output(f.getCount()) ")"}
              }
         }
     } else {
         div[class="included-facet"]{
             if(f.isSelected()) {
                  submitlink updateResults(searcher.removeFacetSelection(f)){excludeFacetSym() output(f.getValue()) " (" output(f.getCount()) ") "}
              } else {
                  submitlink updateResults(~searcher matching f.mustNot() ) {excludeFacetSym()}
                  submitlink updateResults(~searcher matching f.should()  ) {output(f.getValue()) " (" output(f.getCount()) ")"}
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
    var resultsPerPage := SearchPrefs.resultsPerPage;
    var options := [5, 10, 25, 50, 100, 500];
    var resultList := results from (~searcher offset ((pagenumber - 1) * resultsPerPage) limit resultsPerPage);
    var size := count from searcher;
    var lastResult := size;
    var current : Int;
    init{
      if(size > pagenumber*resultsPerPage){
        lastResult := pagenumber * resultsPerPage;
      }
    }
    if(searcher.getQuery().length()>0){
      div{
        if(size > 0) {
          output(size) " results found in " output(searchtime from searcher) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
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
      submitlink action{ SearchPrefs.resultsPerPage := new; return doSearch(searcher, namespace, 1); }{ output(new) }
  }

  define resultIndex (searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int, ns : String){
    var totalPages := ( (count from searcher).floatValue() / resultsPerPage.floatValue() ).ceil()
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

//backwards compatibility
define page showFile(searcher : EntrySearcher, cf : Entry){
    init{return viewFile(searcher.getQuery(),cf.url, cf.projectname);}
}

define page viewFile(query : String, url:URL, projectName:String){
  var cf := (from Entry as e where e.url=~url and e.projectname = ~projectName)[0]
  var linkText    := "";
  var location    : String;
  var lineNumbers : String;
  var codeLines   : String;
  var highlighted : List<List<String>>;
  var searcher    := toSearcher(query, "");
  title { output(cf.name + " - Reposearch") }

  init{
      linkText := searcher.highlight("fileName", cf.name, "<u>","</u>", 1, 256, "");
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
  //highlight code using google-code-prettify
  includeCSS("prettify.css")
  includeJS("prettify.js")
  <script>$(function(){prettyPrint();})</script>

  navigate(search(cf.projectname, ""))[target:="_blank"]{"new search"}
  div[class="search-result-link"]{
    navigate(url(cf.url)){ div[class="search-result-location"]{ output(location) } <b>rawoutput(linkText)</b> }
  }
  <div class="search-result-highlight">
        <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(lineNumbers)</div>
        <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(codeLines)</pre></div>
  </ div>
  navigate(search(cf.projectname, ""))[target:="_blank"]{"new search"}
}

function toSearcher(q:String, ns:String) : EntrySearcher{
  var searcher := search Entry in namespace ns with facets (fileExt, 120), (repoPath, 200) [no lucene, strict matching];
  var slop := if(SearchPrefs.exactMatch) 0 else 100000;
  if(SearchPrefs.caseSensitive) { searcher:= ~searcher matching contentCase, fileName: q~slop; }
  else   { searcher:= ~searcher matching q~slop; }
  return searcher;
}

function highlightCodeLines(searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int, fullContentFallback: Bool) : List<List<String>>{
  var raw : String;
  if(SearchPrefs.caseSensitive){
    raw := searcher.highlightLargeText("contentCase", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  } else{
    raw := searcher.highlightLargeText("content", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
  }
  if(fullContentFallback && raw.length() < 1) {
    raw := entry.content;
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
    submit action{SearchStatistics.clear();}{"Reset global statistics"}

    header{"Search counts per project"}
    for(pr : Project order by pr.searchCount desc){
        searchCount(pr)<br />
    }<br />
    submit action{for(pr : Project){ pr.resetSearchCount(); }}{"Reset project search statistics"}

}