module search

define page search(namespace:String, q:String){
  title { output(q + " - Reposearch") }
  showSearch(toSearcher(q, namespace, ""), namespace, "", 1)
}
//deprecated
// define override page doSearch(searcher : EntrySearcher, namespace:String, pageNum: Int){
//     init{return doSearch(searcher, namespace, "", pageNum);}
// }

define page doSearch(searcher : EntrySearcher, namespace:String, langCons : String, pageNum: Int){
    title { output("Reposearch - '" + searcher.getQuery() +  "' in " + namespace) }
    showSearch(searcher, namespace, langCons, pageNum)
}

define showSearch (entrySearcher : EntrySearcher, namespace : String, langCons : String, pageNum: Int ){
  var prj := findProject(namespace);
  var source := "/autocompleteService"+"/"+URLFilter.filter(namespace);
  var searcher := entrySearcher;
  var query := searcher.getQuery();
  var caseSensitive := SearchPrefs.caseSensitive;
  var resultsPerPage := SearchPrefs.resultsPerPage;
  var options := [5, 10, 25, 50, 100, 500];
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

  mainResponsive(namespace){
      gridRowFluid{ gridSpan(12){
        wellSmall{
          gridRowFluid{ gridSpan(10,1){
              // pageHeader{ "Search " output(namespace) }
              inlForm{
                  gridRowFluid{
                  gridSpan(8){
                    formEntry("Search " + namespace)  { <span class="ui-widget">input(query)[autocomplete="off", id="searchfield", onkeyup=updateResults()] </span>}
                  } gridSpan(4){
                      formEntry("Results per page")  {
                          buttonGroup{
                              for(i : Int in options) {
                                showOption(searcher, namespace, i, langCons, (resultsPerPage != i) )
                              }
                          }
                      }
                  }

                }

                gridRowFluid{
                    input(SearchPrefs.caseSensitive)[onclick=updateResults(), title="Case sensitive search"]{"case sensitive"}
                                     " " input(SearchPrefs.exactMatch)[onclick=updateResults(), title="If enabled, the exact sequence of characters is matched in that order (recommended)"]{"exact match"}
                                     " " submit action{return search(namespace,query);} [class="btn btn-primary"] { "search" }
                }

                formActions{
                    placeholder facetArea{
                      if(query.length() > 0){ viewFacets(searcher, namespace, langCons) }
                    }
                }
              }
          } }
        }
        }
      }
      placeholder resultArea{
        if(query.length() > 0){ paginatedTemplate(searcher, pageNum, namespace, langCons) }
      }
  }

  action updateResults(){
    if(query.length() > 2){
      searcher := toSearcher(query,namespace, langCons); //update with entered query
      updateAreas(searcher, 1, namespace, langCons);
      //HTML5 feature, replace url without causing page reload
      runscript("window.history.pushState('history','reposearch','" + navigate(doSearch(searcher, namespace, langCons, 1) ) + "');");
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

function updateAreas(searcher : EntrySearcher, page : Int, namespace : String, langCons : String){
  replace(facetArea, viewFacets(searcher, namespace, langCons));
  replace(resultArea, paginatedTemplate(searcher, page, namespace, langCons));
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

define ajax highlightedResultToggled(e : Entry, searcher : EntrySearcher, nOfFragments : Int, langCons : String){
  highlightedResult(e, searcher, nOfFragments, langCons)
  prettifyCode(e.projectname)
}

define highlightedResult(e : Entry, searcher : EntrySearcher, nOfFragments : Int, langCons : String){
  var highlightedContent : List<List<String>>;
  var ruleOffset : String;
  var linkText := "";
  var toggleText := if(nOfFragments != 10) "more fragments" else "less fragments";
  var location := e.url.substring(0, e.url.length() - e.name.length() );
  var viewFileUri := navigate(viewFile(searcher.getQuery(), e.url, e.projectname, langCons));

  init{
    linkText := searcher.highlight("fileName", e.name, "<u>","</u>", 1, 256, "");
    if(linkText.length() < 1){
      linkText := e.name;
    }
    highlightedContent := highlightCodeLines(searcher, e, 150, nOfFragments, false, viewFileUri, langCons);
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

  // div[class="search-result-link"]{

  gridRowFluid{
      gridSpan(12){
        navWithAnchor(viewFileUri , ruleOffset){
          <span class="label badge-info"><b>output(if(linkText.length()>0) linkText else "-")</b></span>
          <span class="label pull-right"> output(location) </span>
        }
      }
  }
  gridRowFluid{
  <div class="search-result-highlight">
    <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(highlightedContent[0].concat("<br />"))</div>
    <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(highlightedContent[1].concat("<br />"))</pre></div>
  </ div>
  }

  submitlink toggleAllFragments()[class="btn btn-mini"] { output(toggleText) }

  action toggleAllFragments(){
      if(nOfFragments != 10) {replace("result-"+e.url, highlightedResultToggled(e, searcher, 10, langCons)); }
      else                   {replace("result-"+e.url, highlightedResultToggled(e, searcher, 3, langCons)); }

  }

}

define ajax paginatedTemplate(searcher :EntrySearcher, pageNum : Int, ns : String, langCons : String){

      prettifyCode(ns)
      if(searcher.getQuery().length() > 0) {
        paginatedResults(searcher, pageNum, ns, langCons)
      }

}

define ajax viewFacets(searcher : EntrySearcher, namespace : String, langCons : String){
  var selected         := searcher.getFacetSelection();
  var path_hasSel      := false;
  var ext_hasSel       := false;
  var lc_hasSel        := langCons.length() > 0;
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


    // gridRowFluid{
      // gridSpan(10,1){
        gridContainer{ formEntry("File extension"){
            for(f : Facet in fileExt facets from searcher ) {  gridSpan(2){  showFacet(searcher, f, ext_hasSel, namespace, langCons) } }
            }
        // }
      // }
    }
    // gridRowFluid{
      // gridSpan(10,1){
        gridContainer{ formEntry("Language construct"){
          if (prj != null && prj.langConstructs.length > 0){
              for(lc : LangConstruct in prj.langConstructs order by lc.name){
                if(lc_hasSel){
                  if(lc.name == langCons){
                     gridSpan(2){buttonMini{ navigate search(namespace, searcher.getQuery()) { excludeFacetSym() <b>output(langCons)</b> }}}
                  } else {
                     gridSpan(2){<div class="btn btn-mini disabled"> includeFacetSym() submitlink updateResults( lc ){ output(lc.name) } </div> }
                  }

                } else {
                     gridSpan(2){buttonMini{ includeFacetSym() submitlink updateResults( lc ){ <b>output(lc.name)</b> }} }
                }
              }
          }
        } }
      // }
    // }
    // gridRowFluid{
      // gridSpan(10,1){
        gridContainer{ formEntry("File location"){ gridSpan(12){
            placeholder repoPathPh{
              showPathFacets(searcher, path_hasSel, namespace, false, langCons)
            }
            for (f : Facet in path_selection) { showFacet(searcher, f, path_hasSel, namespace, langCons) <br /> }
        } } }
      // }
    // }

  action updateResults(p: LangConstruct){
    if( lc_hasSel ){
      return doSearch( p.replaceLangConstructConstraint ( searcher ), namespace, p.name, 1 );
    } else {
      p.addLangConstructConstraint( searcher );
      return doSearch( searcher , namespace, p.name, 1 );
    }
  }
}

define ajax showPathFacets(searcher : EntrySearcher, hasSelection : Bool, namespace : String, show : Bool, langCons : String){
  if( show ){
    buttonSmall{submitlink action{replace(repoPathPh, showPathFacets( searcher, hasSelection, namespace, false, langCons));}{<b>"collapse"</b>}}
    div{
      for(f : Facet in interestingPathFacets(searcher)) {
        showFacet(searcher, f, hasSelection, namespace, langCons) <br />
      }
    }
  } else {
     buttonSmall{submitlink action{replace(repoPathPh, showPathFacets( searcher, hasSelection, namespace, true, langCons));}{<b>"expand"</b>}}
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

define showFacet(searcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String, langCons : String) {


    // buttonGroup{

          if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
            <div class="btn btn-mini disabled">
              if(f.isSelected()) {
                submitlink updateResults(searcher.removeFacetSelection(f)){ includeFacetSym() " " output(f.getValue()) " (" output(f.getCount()) ")"}
              } else {
                submitlink updateResults(~searcher matching f.should()){ includeFacetSym() " " output(f.getValue()) " (" output(f.getCount()) ")"}
              }

            </div>
          } else {
            buttonMini{
              <b>
              if(f.isSelected()) {
                submitlink updateResults(searcher.removeFacetSelection(f)){excludeFacetSym() output(f.getValue()) " (" output(f.getCount()) ") "}
              } else {
                submitlink updateResults(~searcher matching f.mustNot() ){excludeFacetSym()} " "
                submitlink updateResults(~searcher matching f.should()  ){output(f.getValue()) " (" output(f.getCount()) ")"}
                " "
              }
              </b>
            }

      // }
    // }
  }

  action updateResults(searcher : EntrySearcher){
    return doSearch(searcher, namespace, langCons, 1);
  }
}

define excludeFacetSym(){
  iMinus()
}
define includeFacetSym(){
  iPlus()
}

define ajax paginatedResults(searcher : EntrySearcher, pagenumber : Int, namespace : String, langCons : String){
  var resultsPerPage := SearchPrefs.resultsPerPage;
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
          <p class="text-info">output(size) " results found in " output(searchtime from searcher) ", displaying results " output((pagenumber-1)*resultsPerPage + 1) "-" output(lastResult)</p>
        } else {
          <p class="text-info">"no results found"</p>
        }
      </center>
    }
    pageIndex(pagenumber, size, resultsPerPage, 12, 3)

    for (e : Entry in resultList){
      wellSmall{
        placeholder "result-"+e.url {highlightedResult(e, searcher, 3, langCons)}
      }
    }

    pageIndex(pagenumber, size, resultsPerPage, 12, 3)
  }

  define pageIndexLink(page: Int, lab : String){
      navigate (doSearch(searcher, namespace, langCons, page)){ output(lab) }
  }
}

define showOption(searcher : EntrySearcher, namespace : String, new : Int, langCons : String, isCurrent : Bool) {
  if(isCurrent){
    submitlink action{ SearchPrefs.resultsPerPage := new; return doSearch(searcher, namespace, langCons, 1); }[class="btn btn-small"]{ output(new) }
  } else {
    submitlink action{ SearchPrefs.resultsPerPage := new; return doSearch(searcher, namespace, langCons, 1); }[class="btn btn-small disabled"]{ output(new) }
  }
}

//backwards compatibility
define page showFile(searcher : EntrySearcher, e : Entry){
    init{return viewFile(searcher.getQuery(),e.url, e.projectname, "");}
}

define page viewFile(query : String, url:URL, projectName:String, langCons : String){
  var e := (from Entry as e where e.url=~url and e.projectname = ~projectName)[0]
  var viewFileUri := navigate(viewFile(query, url, projectName, langCons));
  var linkText    := "";
  var location    : String;
  var lineNumbers : String;
  var codeLines   : String;
  var highlighted : List<List<String>>;
  var searcher    := toSearcher(query, "", langCons);

  title { output(e.name + " - Reposearch") }

  init{
    linkText := searcher.highlight("fileName", e.name, "<u>","</u>", 1, 256, "");
    if(linkText.length() < 1) { linkText := e.name; }
    location := e.url.substring(0, e.url.length() - e.name.length() );
    highlighted := highlightCodeLines( searcher, e, 1000000, 1, true, viewFileUri, langCons );
    lineNumbers := highlighted[0].concat("<br />");
    codeLines := highlighted[1].concat("<br />");
    //add line number anchors
    lineNumbers := />(\d+)</.replaceAll( " a name=\"$1\">$1<", lineNumbers );
  }
  mainResponsive(projectName){

    wellSmall{
      gridRowFluid{
          gridSpan(12){
            navigate(url(e.url)){
              <span class="label badge-info"><b>rawoutput(if(linkText.length()>0) linkText else "-")</b></span>
              <span class="label pull-right"> output(location) </span>
            }
          }
      }

      gridRowFluid{
          <div class="search-result-highlight">
            <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput(lineNumbers)</div>
            <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput(codeLines)</pre></div>
          </ div>
      }
      navigate(search(e.projectname, ""))[target:="_blank"]{"new search"}
      prettifyCode(projectName)
    }
  }
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

function toSearcher(q:String, ns:String, langCons:String) : EntrySearcher{

  var searcher := search Entry in namespace ns with facets (fileExt, 120), (repoPath, 200) [no lucene, strict matching];
  // if (SearchPrefs.regex) {
  //     return searcher.regexQuery( q );
  // }
  var slop := if(SearchPrefs.exactMatch) 0 else 100000;

  if(SearchPrefs.caseSensitive) { searcher:= ~searcher matching contentCase, fileName: q~slop; }
  else   { searcher:= ~searcher matching q~slop; }

  if(langCons.length()>0){ addLangConstructConstraint(searcher, langCons); }
  return searcher;
}

function highlightCodeLines(searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int, fullContentFallback: Bool, viewFileUri : String, langConsStr : String) : List<List<String>>{
  var raw : String;
  if(langConsStr.length() > 0){
      //a langCons is used
      var langCons : LangConstruct := findLangConstruct(langConsStr);
      //decorate the langCons matches such that these will match for field constructs.matches
      var content := MatchExtractor.decorateMatches(langCons, entry.content, searcher.getQuery());
      //highlight
      raw := searcher.highlightLargeText("constructs.matches", content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n");
      //undecorate highlighted matches again
      raw := /\s?\$OHL\$[^#]+#MATCH#([^\$]+)\$CHL\$\s?/.replaceAll("\\$OHL\\$$1\\$CHL\\$", raw);
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
