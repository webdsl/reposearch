module search

define page search(namespace:String, q:String){
  title { output(q + " - Reposearch") }
  showSearch(toSearcher(q, namespace), namespace, "", 1)
}
//depricated
// define override page doSearch(searcher : EntrySearcher, namespace:String, pageNum: Int){
//     init{return doSearch(searcher, namespace, "", pageNum);}
// }

define page doSearch(searcher : EntrySearcher, namespace:String, pattern : String, pageNum: Int){
    title { output("Reposearch - '" + searcher.getQuery() +  "' in " + namespace) }
    showSearch(searcher, namespace, pattern, pageNum)
}

define showSearch (entrySearcher : EntrySearcher, namespace : String, pattern : String, pageNum: Int ){
  var prj := findProject(namespace);
  var source := "/autocompleteService"+"/"+URLFilter.filter(namespace);
  var searcher := entrySearcher;
  var query := searcher.getQuery();
  var caseSensitive := SearchPrefs.caseSensitive;
  init{
    if ( prj == null  && namespace != "" ){ return root(); }
    if ( query.length() > 0 ){ incSearchCount(prj); }
  }

  includeJS("jquery-1.5.min.js")
  includeJS("jquery-ui-1.8.9.custom.min.js")
  includeJS("completion.js")
  includeCSS("jquery-ui.css")

  includeCSS("prettify.css")
  includeJS("prettify.js")
  includeJS("make-clickable.js")

  <script>
    setupcompletion("~source");
  </script>

  <center>
    <b>"project: " output(namespace)</b>
    form {
      <span class="ui-widget">
        input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()]
      </span>
      submit action{return search(namespace,query);} {"search"} <br />
      input(SearchPrefs.caseSensitive)[onclick=updateResults(), title="Case sensitive search"]{"case sensitive"}
      input(SearchPrefs.exactMatch)[onclick=updateResults(), title="If enabled, the exact sequence of characters is matched in that order (recommended)"]{"exact match"}
      input(SearchPrefs.regex)[onclick=updateResults(), title="Use regular expressions"]{"regular expressions"}
    }
  </center>
  <br />
  homeLink()

  placeholder facetArea{
    if(query.length() > 0){ viewFacets(searcher, namespace, pattern) }
  }

  placeholder resultArea{
    if(query.length() > 0){ paginatedTemplate(searcher, pageNum, namespace, pattern) }
  }

  action updateResults(){
    if(query.length() > 2){
      searcher := toSearcher(query,namespace); //update with entered query
      updateAreas(searcher, 1, namespace, pattern);
      //HTML5 feature, replace url without causing page reload
      runscript("window.history.pushState('history','reposearch','" + navigate(doSearch(searcher, namespace, pattern, 1) ) + "');");
      incSearchCount(prj);
    } else {
      clear(resultArea);
      clear(facetArea);
    }
  }
  googleAnalytics()
}

function incSearchCount(prj : Project){
  if(prj != null){prj.incSearchCount();}
}

function updateAreas(searcher : EntrySearcher, page : Int, namespace : String, pattern : String){
  replace(facetArea, viewFacets(searcher, namespace, pattern));
  replace(resultArea, paginatedTemplate(searcher, page, namespace, pattern));
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
    rawoutput{ <a all attributes href=n+"#"+a> elements </a> }
  }

define ajax highlightedResultToggled(e : Entry, searcher : EntrySearcher, nOfFragments : Int, pattern : String){
  highlightedResult(e, searcher, nOfFragments, pattern)
  prettifyCode(e.projectname)
}

define highlightedResult(e : Entry, searcher : EntrySearcher, nOfFragments : Int, pattern : String){
  var highlightedContent : List<List<String>>;
  var ruleOffset : String;
  var linkText := "";
  var toggleText := if(nOfFragments != 10) "show all fragments" else "less fragments";
  var location := e.url.substring(0, e.url.length() - e.name.length() );
  var viewFileUri := navigate(viewFile(searcher.getQuery(), e.url, e.projectname, pattern));

  init{
    linkText := searcher.highlight("fileName", e.name, "<u>","</u>", 1, 256, "");
    if(linkText.length() < 1){
      linkText := e.name;
    }
    highlightedContent := highlightCodeLines(searcher, e, 150, nOfFragments, false, viewFileUri, pattern);
    ruleOffset := "";
    if(highlightedContent[0].length < 1){
      ruleOffset := "1";
    } else {
      ruleOffset := /.+#(\d+).>.*/.replaceFirst("$1",highlightedContent[0][0]);
      if( !(/^\d+$/.match(ruleOffset)) ){
        if(highlightedContent[0].length > 1) {
          ruleOffset := /.+#(\d+).>.*/.replaceFirst("$1",highlightedContent[0][1]);
        } else {
        ruleOffset := "3";
        }
      }
    }
    ruleOffset := "" + (ruleOffset.parseInt() - 3);
  }

  div[class="search-result-link"]{
    navWithAnchor(viewFileUri , ruleOffset){
      div[class="search-result-location"]{
        output(location)
      }
      <b>output(if(linkText.length()>0) linkText else "-")</b>
    }
    "[" actionLink(toggleText,toggleAllFragments()) "]"
  }
  <div class="search-result-highlight">
    <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(highlightedContent[0].concat("<br />"))</div>
    <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(highlightedContent[1].concat("<br />"))</pre></div>
  </ div>
  action toggleAllFragments(){
      if(nOfFragments != 10) {replace("result-"+e.url, highlightedResultToggled(e, searcher, 10, pattern)); }
      else                   {replace("result-"+e.url, highlightedResultToggled(e, searcher, 3, pattern)); }

  }

}

define ajax paginatedTemplate(searcher :EntrySearcher, pageNum : Int, ns : String, pattern : String){
  prettifyCode(ns)
  if(searcher.getQuery().length() > 0) {
    div[class="main-container"]{
      paginatedResults(searcher, pageNum, ns, pattern)
    }
  }
}

define ajax viewFacets(searcher : EntrySearcher, namespace : String, pattern : String){
  var selected         := searcher.getFacetSelection();
  var path_hasSel      := false;
  var ext_hasSel       := false;
  var prj              := findProject(namespace);
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
      } }
    }
  }

  div[class="top-container"]{
    div[class="facet-area"]{"Filter on file extension:"}
    div{
      for(f : Facet in fileExt facets from searcher ) {    showFacet(searcher, f, ext_hasSel, namespace, pattern) }
    }
    if (prj != null){
      div[class="facet-area"]{"Filter on pattern:"}
      if (pattern.length() > 0){
          div[class="included-facet"]{ excludeFacetSym() navigate search(namespace, searcher.getQuery()) { output(pattern) } }
      } else {
          for(p : Pattern in prj.patterns){
              div[class="included-facet"]{
                  submitlink updateResults(searcher, p){ output(p.name)}
              }
          }
      }
    }

    div[class="facet-area"]{"Filter on file location:"}
    for (f : Facet in path_selection) { showFacet(searcher, f, path_hasSel, namespace, pattern) <br /> }
    placeholder repoPathPh{
      showPathFacets(searcher, path_hasSel, namespace, false, pattern)
    }
  }
  action updateResults(searcher1 : EntrySearcher, p: Pattern){
    return doSearch( (~searcher matching patternMatches.matches: +p.queryString( searcher.getQuery() ) ) , namespace, p.name, 1);
  }
}

define ajax showPathFacets(searcher : EntrySearcher, hasSelection : Bool, namespace : String, show : Bool, pattern : String){
  if( show ){
    submitlink action{replace(repoPathPh, showPathFacets( searcher, hasSelection, namespace, false, pattern));}{"collapse"}
    div{
      for(f : Facet in interestingPathFacets(searcher)) {
        showFacet(searcher, f, hasSelection, namespace, pattern) <br />
      }
    }
  } else {
    submitlink action{replace(repoPathPh, showPathFacets( searcher, hasSelection, namespace, true, pattern));}{"expand"}
  }
}

function interestingPathFacets(searcher : EntrySearcher) : List<Facet> {
  var previous : Facet;
  var allFacets:= repoPath facets from searcher;
  var toReturn := List<Facet>();
  for(f : Facet in allFacets order by f.getValue()) {
    if(previous != null && (f.getValue().startsWith(previous.getValue()) && f.getCount() == previous.getCount() )) {
      toReturn.removeAt(toReturn.length - 1);
    }
    toReturn.add(f);
    previous := f;
  }
  return toReturn;
}

define showFacet(searcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String, pattern : String) {
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
    return doSearch(searcher, namespace, pattern, 1);
  }
}

define excludeFacetSym(){
  <div class="exclude-facet-sym">"x"</div>
}
define includeFacetSym(){
  <div class="include-facet-sym">"v"</div>
}

define ajax paginatedResults(searcher : EntrySearcher, pagenumber : Int, namespace : String, pattern : String){
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
      <center>
        if(size > 0) {
          output(size) " results found in " output(searchtime from searcher) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)
          " [results per page: "
          for(i : Int in options) {
            if(resultsPerPage != i){ showOption(searcher, namespace, i, pattern) } else { output(i) } " "
          }
         "]"
        } else {
          "no results found"
        }
      </center>
    }
    par{
      <center>resultIndex(searcher, pagenumber, resultsPerPage, namespace, pattern)</center>
    }
    for (e : Entry in resultList){
      placeholder "result-"+e.url {highlightedResult(e, searcher, 3, pattern)}
    }
    par{
      <center>resultIndex(searcher, pagenumber, resultsPerPage, namespace, pattern)</center>
    }
  }
}

define showOption(searcher : EntrySearcher, namespace : String, new : Int, pattern : String) {
  submitlink action{ SearchPrefs.resultsPerPage := new; return doSearch(searcher, namespace, pattern, 1); }{ output(new) }
}

define resultIndex (searcher: EntrySearcher, pagenumber : Int, resultsPerPage : Int, ns : String, pattern : String){
  var totalPages := ( (count from searcher).floatValue() / resultsPerPage.floatValue() ).ceil()
  var start : Int := SearchHelper.firstIndexLink(pagenumber,totalPages, 9) //9 index links at most
  var end : Int := SearchHelper.lastIndexLink(pagenumber,totalPages, 9)
  if(totalPages > 1){
    if (pagenumber > 1){
      submit("|<<", showResultsPage(searcher, 1))
      submit("<", showResultsPage(searcher, pagenumber-1))
    }
    for(pagenum:Int from start to pagenumber){
     gotoresultpage(searcher, pagenum, ns, pattern)
    }
    "-"output(pagenumber)"-"
    for(pagenum:Int from pagenumber+1 to end+1){
     gotoresultpage(searcher, pagenum, ns, pattern)
    }
    if(pagenumber < totalPages){
      submit(">", showResultsPage(searcher, pagenumber+1))
      submit(">>|", showResultsPage(searcher, totalPages))
    }
  }
  action showResultsPage(searcher: EntrySearcher, pagenumber : Int){
    return doSearch(searcher, ns, pattern, pagenumber);
  }
}

define gotoresultpage(searcher: EntrySearcher, pagenum: Int, ns : String, pattern : String){
  submit action{return doSearch(searcher, ns, pattern, pagenum);}{output(pagenum)}
}

native class org.webdsl.search.SearchHelper as SearchHelper {
  static firstIndexLink(Int, Int, Int): Int
  static lastIndexLink(Int, Int, Int): Int
}

//backwards compatibility
define page showFile(searcher : EntrySearcher, e : Entry){
    init{return viewFile(searcher.getQuery(),e.url, e.projectname, "");}
}

define page viewFile(query : String, url:URL, projectName:String, pattern : String){
  var e := (from Entry as e where e.url=~url and e.projectname = ~projectName)[0]
  var viewFileUri := navigate(viewFile(query, url, projectName, pattern));
  var linkText    := "";
  var location    : String;
  var lineNumbers : String;
  var codeLines   : String;
  var highlighted : List<List<String>>;
  var searcher    := toSearcher(query, "");

  title { output(e.name + " - Reposearch") }

  init{
    linkText := searcher.highlight("fileName", e.name, "<u>","</u>", 1, 256, "");
    if(linkText.length() < 1){
      linkText := e.name;
    }
    location := e.url.substring(0, e.url.length() - e.name.length() );
    if (pattern.length() > 0) { ~searcher matching patternMatches.matches: + queryString( pattern, searcher.getQuery() ); }
    highlighted := highlightCodeLines( searcher, e, 1000000, 1, true, viewFileUri, pattern );
    lineNumbers := highlighted[0].concat("<br />");
    codeLines := highlighted[1].concat("<br />");
    //add line number anchors
    lineNumbers := />(\d+)</.replaceAll( " a name=\"$1\">$1<", lineNumbers );
  }
  prettifyCode(projectName)

  navigate(search(e.projectname, ""))[target:="_blank"]{"new search"}
  div[class="search-result-link"]{
    navigate(url(e.url)){ div[class="search-result-location"]{ output(location) } <b>rawoutput(linkText)</b> }
  }
  <div class="search-result-highlight">
    <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(lineNumbers)</div>
    <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(codeLines)</pre></div>
  </ div>
  navigate(search(e.projectname, ""))[target:="_blank"]{"new search"}
  googleAnalytics()
}

native class utils.URLFilter as URLFilter {
  static filter(String):String
}

define prettifyCode(){ prettifyCodeHelper("") }
define prettifyCode(projectName : String){ prettifyCodeHelper("\""+URLFilter.filter(projectName)+"\"") }
define prettifyCodeHelper(projectName : String){
  //highlight code using google-code-prettify
  includeCSS("prettify.css")
  includeJS("prettify.js")
  includeJS("make-clickable.js")
  <script>
    prettifyAndMakeClickable(~projectName);
  </script>
}

function toSearcher(q:String, ns:String) : EntrySearcher{

  var searcher := search Entry in namespace ns with facets (fileExt, 120), (repoPath, 200) [no lucene, strict matching];
  if (SearchPrefs.regex) {
      return searcher.regexQuery( q );
  }
  var slop := if(SearchPrefs.exactMatch) 0 else 100000;
  if(SearchPrefs.caseSensitive) { searcher:= ~searcher matching contentCase, fileName: q~slop; }
  else   { searcher:= ~searcher matching q~slop; }
  return searcher;
}

function highlightCodeLines(searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int, fullContentFallback: Bool, q : String, patternStr : String) : List<List<String>>{
  var raw : String;
  if(patternStr.length() > 0){
       var pattern : Pattern := findPattern(patternStr);
       var content := MatchExtractor.replaceAll(pattern.name, pattern.pattern, pattern.group, pattern.caseSensitive, entry.content);
       raw := searcher.highlightLargeText("patternMatches.matches", content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
       raw := /\s\$OHL\$\w+#MATCH#(\w+)\$CHL\$\s/.replaceAll("\\$OHL\\$$1\\$CHL\\$", raw);
  } else {
      if(SearchPrefs.caseSensitive){
        raw := searcher.highlightLargeText("contentCase", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
      } else{
        raw := searcher.highlightLargeText("content", entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
      }
  }
  if(fullContentFallback && raw.length() < 1) {
    raw := entry.content;
  }
  var viewFileUri := q;
  var highlighted := rendertemplate(output(raw)).replace("$OHL$","<span class=\"hlcontent\">").replace("$CHL$","</span>");//.replace("\r", "");
  var splitted := highlighted.split("\n");
  var listCode := List<String>();
  var listLines := List<String>();
  var lists := List<List<String>>();
  var lineNum : String;
  var fixPrevious := false;
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
        fixPrevious := true;
      } else {
        // line numbers are added at the beginning of code lines followed by a whitespace
        // original: 'foo:bar'
        // modified: '34 foo:bar '
        lineNum := /^(\d+).*/.replaceFirst("$1", s);
        listLines.add("<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap(viewFileUri, lineNum)  ) + "</div>" );
        if (fixPrevious) {
            listLines.set( listLines.length-2 , "<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap(viewFileUri, ""+(lineNum.parseInt()-1))  ) + "</div>" );
            fixPrevious := false;
        }
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

define issue599wrap(viewFileUri: String, lineNum: String) {
    navWithAnchor(viewFileUri, lineNum){ output(lineNum) }
}
