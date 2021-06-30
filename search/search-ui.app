module search/search-ui

imports built-in
imports reposearch
imports analytics/analytics
imports entry/entry
imports language-construct/language-construct-data
imports search/search-data
imports search/search-misc

imports elib-bootstrap-3/icons
imports elib/elib-bootstrap/lib
imports elib/elib-utils/pageindex
imports elib/elib-utils/string

section pages/templates

  page search( namespace:String, q:String ) {
    init { SearchPrefs.addToHistory( namespace ); }
    showSearch( toSearcher( q, namespace, "" ), namespace, "", 1 )
  }

  page doSearch( searcher : EntrySearcher, namespace:String, langCons : String, pageNum: Int ) {
  	init{ if( searcher.getNamespace() != namespace){ ~searcher in namespace namespace; } }
    showSearch( searcher, namespace, langCons, pageNum )
  }

  define showSearch( entrySearcher : EntrySearcher, namespace : String, langCons : String, pageNum: Int ) {    
    var prjName := if ( namespace == "" ) "All projects" else capitalize(namespace);  
    var source := "/autocompleteService"+"/"+URLFilter.filter( namespace );
    var searcher := entrySearcher;
    var query := searcher.getQuery();
    var caseSensitive := SearchPrefs.caseSensitive;
    init {
      if( query.length() > 0 && count from searcher  > 0 ) { incSearchCount( namespace ); }
    }
    
    if ( query.length() > 0 ) {
      title       { output( query + " - " +  prjName + " | Reposearch" ) }
      description { output( "Search results for '" + query + "' in source code repositories of " + prjName) }
    } else {
      title       { output( "Search " + prjName + "'s source code | Reposearch" ) }
      description { output( "Search the " +  prjName + " source code repositories instantly with the ability to filter on file extension, file location and language construct.") }
    }
    mainResponsive( namespace ) {
      includeJS( "completion.js" )
      includeJS( "jquery.history.js")
      <script>
      /*Fixes encode issue for history.js see: https://github.com/browserstate/history.js/issues/257#issuecomment-15831039 */
       // no fix yet
       
      setupcompletion( "~source" );
      
      var updatingResults = false;
      
      (function(window,undefined){
        var History = window.History;

        // Bind to State Change
        History.Adapter.bind(window,'statechange',function(){ // Note: We are using statechange instead of popstate
          // Only load the page from address bar if the history state changed by a back/forward action from browser,
          // not by our own pushState call during updateResults action 
          if(updatingResults) {                          
             updatingResults = false;
          } else {
             window.open(location.href,'_self','',true);
          }
        });
      })(window);
      </script>
      
      gridRow { gridCol( 12 ) {
        wellSmall {
          inlForm{
            gridRow{
              gridCol( 10,1 ) {
                gridRow {
                  gridCol( 8 ) {
                    formEntry( "Search " + prjName )  { <span class="ui-widget">input( query ) [autocomplete="off", autofocus="", id="searchfield", oninput="$(this).keyup();", onkeyup=updateResults(), type="search"] </span>}
                  }
                  gridCol( 4 ) {
                    formEntry( "Results per page" )  {
                      placeholder "paginationOptions" {
                        paginationButtons( searcher, namespace, langCons )
                      }
                    }
                  }
                }
                gridRow { gridCol(12){
                  input( SearchPrefs.caseSensitive ) [onclick=updateResults(), title="Case sensitive search"]{"case sensitive"}
                  " " input( SearchPrefs.exactMatch ) [onclick=updateResults(), title="If enabled, the exact sequence of characters is matched in that order(recommended)"]{"exact match"}
                  " " submitlink action{return search( namespace,query );} [class="btn btn-sm btn-primary"] { iSearch " search" }
                } }
              }
            }
            // gridRow{ gridCol( 12 ) {
              placeholder "facetArea" {
                if( searcher.getQuery().length() > 0 ) { viewFacets( searcher, namespace, langCons ) }
              }
            // } }

          }
        }
      } }
      placeholder "resultArea" {
        if( searcher.getQuery().length() > 0 ) { paginatedTemplate( searcher, pageNum, namespace, langCons ) }
        else { prettifyCode } // force correct imports
      }
    }
    action updateResults() {
      if( query.length() > 2 ) {
        searcher := toSearcher( query,namespace, "" ); //update with entered query, discard lang construct constraint
        if( count from searcher  > 0 ){
          var queryJs := query.escapeJavaScript();
          //replace url without causing page reload
          log("URL: " + navigate( doSearch( searcher, namespace, langCons, 1 ) ));
          runscript(
            "window.updatingResults = true; History.pushState({},'" + queryJs + " - " +  prjName + " | Reposearch" + "','" + navigate( doSearch( searcher, namespace, langCons, 1 ) ) + "');" 
          );
          
          incSearchCount( namespace );
        }
        updateAreas( searcher, 1, namespace, "" );
        replace( "paginationOptions", paginationButtons( searcher, namespace, "" ) );
      } else {
        clear( "resultArea" );
        clear( "facetArea" );
      }
    }
  }

  function updateAreas( searcher : EntrySearcher, page : Int, namespace : String, langCons : String ) {
    replace( "facetArea", viewFacets( searcher, namespace, langCons ) );
    replace( "resultArea", paginatedTemplate( searcher, page, namespace, langCons ) );
  }

  define navWithAnchor( n:String,a:String ) {
    <a all attributes href=n+"#"+a> elements </a> 
  }

  define ajax highlightedResultToggled( e : Entry, searcher : EntrySearcher, nOfFragments : Int, langCons : String ) {
    highlightedResult( e, searcher, nOfFragments, langCons )
    prettifyCode( e.projectname )
  }
  
  define highlightedResult( e : Entry, searcher : EntrySearcher, nOfFragments : Int, langCons : String ) {
    var highlightedContent : List<List<String>>;
    var ruleOffset : String;
    var linkText := "";
    var toggleText := if( nOfFragments != 10 ) "more fragments" else "less fragments";
    var location := e.url.substring( 0, e.url.length() - e.name.length() );
    var viewFileUri := navigate( viewFile( searcher.getQuery(), e.url, e.projectname, langCons ) );
    init {
      linkText := searcher.highlight( "fileName", e.name, "<span class=\"hlcontent\">","</span>", 1, 256, "" );
      if( linkText.length() < 1 ) {
        linkText := e.name;
      }
      highlightedContent := highlightCodeLines( searcher, e, 150, nOfFragments, false, viewFileUri, langCons );
      
      if( highlightedContent[0].length < 1 ) {
        ruleOffset := "1";
      } else {
        ruleOffset := /.+#(\d+|\?).>.*/.replaceFirst("$1",highlightedContent[0][0]);
      }
    }
    gridRow { gridCol(12){
      navWithAnchor( viewFileUri , ruleOffset ) {
        <h5>
        rawoutput( if( linkText.length() >0 ) linkText else "-" )
            pullRight { div[class="repoFolderLocation"]{ output( location ) } }
        </h5>
      }
    } }
    gridRow { gridCol(12){
      <div class="search-result-highlight">
        <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput( highlightedContent[0].concat( "<br />" ) ) </div>
          <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput( highlightedContent[1].concat( "<br />" ) ) </pre></div>
              </ div>
    } }
            
    submitlink toggleAllFragments() { buttonMini { output( toggleText ) } }
    action toggleAllFragments() {
      if( nOfFragments != 10 ) {replace( "result-"+e.url, highlightedResultToggled( e, searcher, 10, langCons ) ); }
      else                     {replace( "result-"+e.url, highlightedResultToggled( e, searcher, 3, langCons ) ); }
    }
  }

  define ajax paginatedTemplate( searcher :EntrySearcher, pageNum : Int, ns : String, langCons : String ) {
    if( searcher.getQuery().length() > 0 ) {
      paginatedResults( searcher, pageNum, ns, langCons )
    }
    prettifyCode( ns )
  }

  define ajax viewFacets( searcher : EntrySearcher, namespace : String, langCons : String ) {
    var selected         := searcher.getFacetSelection();
    var path_hasSel      := false;
    var ext_hasSel       := false;
    var lc_hasSel        := langCons.length() > 0;
    // var prj              := findProject( namespace );
    var path_selection   := List<Facet>();
    var langConsFacets   := getLanguageConstructFacets( searcher );
    init {
      for( f : Facet in selected ) {
        if( f.getFieldName() == "fileExt" && !f.isMustNot() ) {
          ext_hasSel := true;
        } else {
          if( f.getFieldName() == "repoPath" ) {
            path_selection.add( f );
            if( !f.isMustNot() ) {
              path_hasSel := true;
            }
          }
        }
      }
    }
    // formActions {
      div[class="facet-area"]{ gridRow{ gridCol(10,1){
      	if(namespace == ""){
      		gridRow{ gridCol(12){
      			formEntry( "Project" ){ div {
      				for( f : Facet in ~"_WebDSLNamespaceID_" facets from searcher order by f.getValue() ) {  
      					pullLeft {
      						buttonGroup {div[class="btn btn-default btn-xs"]{ includeFacetSym() } navigate doSearch( searcher, f.getValue(), langCons, 1 )[class="btn btn-default btn-xs"]{ output( f.getValue() ) " (" output( f.getCount() ) ")" }}
  					    }
      				}
  				} }
      		} }
      	}
      	
        gridRow{
          gridCol( 7 ) {
            formEntry( "File extension" ) { div{ 
              for( f : Facet in fileExt facets from searcher ) {  pullLeft {  showFacet( searcher, f, ext_hasSel, namespace, langCons )  } }
            } }
          }

          gridCol( 5 ) {
            if( langConsFacets.length  > 0 ) {
              formEntry( "Language construct" ) { div{ 
                for( f : Facet in langConsFacets order by f.getValue() ) {
                  pullLeft {
                    if( lc_hasSel ) {
                      if( f.getValue() == langCons ) {
                        navigate search( namespace, searcher.getQuery() ) { buttonGroup { buttonMini{excludeFacetSym() } buttonMini{ output( f.getValue() ) " (" output( f.getCount() ) ")" } } }
                      } else {
                        submitlink updateResults( f.getValue() ){ buttonGroup{ div[class="btn btn-default btn-xs disabled"]{ includeFacetSym() } div[class="btn btn-default btn-xs disabled"]{  output( f.getValue() ) " (" output( f.getCount() ) ")" }} }
                      }
                    } else {
                      submitlink updateResults( f.getValue() ) { buttonGroup {buttonMini{ includeFacetSym() } buttonMini{ output( f.getValue() ) " (" output( f.getCount() ) ")" }}}
                    }
                  }
                }
              } } 
            }
          }
        }

        gridRow{ gridCol(12){
          formEntry( "File location" ) {
            placeholder "repoPathPh" {
              showPathFacets( searcher, path_hasSel, namespace, false, langCons )
            }
            for( f : Facet in path_selection ) { showFacet( searcher, f, path_hasSel, namespace, langCons ) }
          }
        } }
      // }
    } } }
    action updateResults( langConstructName : String ) {
      var p := findLangConstruct( langConstructName );
      if( lc_hasSel ) {
        return doSearch( p.replaceLangConstructConstraint( searcher ), namespace, p.name, 1 );
      } else {
        p.addLangConstructConstraint( searcher );
        return doSearch( searcher , namespace, p.name, 1 );
      }
    }
  }

  define ajax showPathFacets( searcher : EntrySearcher, hasSelection : Bool, namespace : String, show : Bool, langCons : String ) {
    if( show ) {
      submitlink action {replace( "repoPathPh", showPathFacets( searcher, hasSelection, namespace, false, langCons ) );} [class="btn btn-default btn-sm"] {"collapse"}
      <br />
      div {
        for( f : Facet in interestingPathFacets( searcher ) ) {
          gridRow {
            pullLeft{
              showFacet( searcher, f, hasSelection, namespace, langCons )
            }
          }
        }
      }
    } else {
      submitlink action {replace( "repoPathPh", showPathFacets( searcher, hasSelection, namespace, true, langCons ) );} [class="btn btn-default btn-sm"] {"expand"}
    }
  }

  define showFacet(entrysearcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String, langCons : String ) {
    if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
      if( f.isSelected() ) {
        submitlink updateResults( entrysearcher.removeFacetSelection( f ) ) { buttonGroup {div[class="btn btn-default btn-xs disabled"]{includeFacetSym() } div[class="btn btn-default btn-xs disabled"]{output( f.getValue() ) " (" output( f.getCount() ) ")"}}}
      } else {
        submitlink updateResults( ~entrysearcher matching f.should() ) { buttonGroup {div[class="btn btn-default btn-xs disabled"]{includeFacetSym() }    div[class="btn btn-default btn-xs disabled"]{ output( f.getValue() ) " (" output( f.getCount() ) ")"}}}
      }
    } else {
      if( f.isSelected() ) {
        submitlink updateResults( entrysearcher.removeFacetSelection( f ) ) { buttonGroup { buttonMini{excludeFacetSym() } buttonMini{output( f.getValue() ) " (" output( f.getCount() ) ") "} } }
      } else {
        buttonGroup {
          submitlink updateResults( ~entrysearcher matching f.mustNot() ) [class="btn btn-default btn-xs"]{ excludeFacetSym() } " "
          submitlink updateResults( ~entrysearcher matching f.should()  ) [class="btn btn-default btn-xs"]{ output( f.getValue() ) " (" output( f.getCount() ) ")"}
        }
        " "
      }
    }
    action updateResults( searcher : EntrySearcher ) {
      return doSearch( searcher, namespace, langCons, 1 );
    }
  }

  define excludeFacetSym() {
    rawoutput( "&times;" )
  }
  define includeFacetSym() {
    "+"
  }

  define ajax paginatedResults( searcher : EntrySearcher, pagenumber : Int, namespace : String, langCons : String ) {
    var resultsPerPage := SearchPrefs.resultsPerPage;
    var resultList := results from ~searcher offset( ( pagenumber - 1 ) * resultsPerPage ) limit resultsPerPage;
    var size := count from searcher;
    var lastResult := size;
    var current : Int;
    init {
      if( size > pagenumber*resultsPerPage ) {
        lastResult := pagenumber * resultsPerPage;
      }
    }

    if( searcher.getQuery().length() >0 ) {
      trackEvent(namespace, "Search")      
      gridRow { gridCol(12){
        pullLeft {
          pageIndex( pagenumber, size, resultsPerPage, 12, 3 )
        } pullRight{
          if( size > 0 ) {
            <strong> output( size ) " results" </strong> " found in " output( searchtime from searcher ) ", displaying results " output( ( pagenumber-1 ) *resultsPerPage + 1 ) "-" output( lastResult )
          } else {
            "no results found"
          }
        }
      }}
      gridRow { gridCol(12){
        for( e : Entry in resultList ) {
          wellSmall {
            placeholder "result-"+e.url {highlightedResult( e, searcher, 3, langCons ) }
          }
        }
      } }
      gridRow { gridCol(12) { pullLeft{
          pageIndex( pagenumber, size, resultsPerPage, 12, 3 )
      } } }
    }
    define pageIndexLink( page: Int, lab : String ) {
      navigate( doSearch( searcher, namespace, langCons, page ) ) { output( lab ) }
    }
  }

  define ajax paginationButtons( searcher : EntrySearcher, namespace : String, langCons : String ) {
    var limit := SearchPrefs.resultsPerPage;
    buttonGroup[data-toggle="buttons-radio"] {
      for( i : Int in [5, 10, 25, 50, 100, 500] ) {
        submitlink action { SearchPrefs.resultsPerPage := i; updateAreas( searcher, 1, namespace, langCons ); } [class="btn btn-default btn-sm", id="limit"+i] {  output( i ) }
      }
    }
    <script>
      $ ( "#limit~limit" ).button( 'toggle' );
    </script>
  }



