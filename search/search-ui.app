module search/search-ui

section pages/templates

  define page search( namespace:String, q:String ) {
    init { SearchPrefs.addToHistory( namespace ); }
    showSearch( toSearcher( q, namespace, "" ), namespace, "", 1 )
  }

  define page doSearch( searcher : EntrySearcher, namespace:String, langCons : String, pageNum: Int ) {
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
      title       { output( "Search " + prjName + " | Reposearch" ) }
      description { output( "Search the " +  prjName + " source code repositories instantly with the ability to filter on file extension, file location and language construct.") }
    }
    mainResponsive( namespace ) {
      <script>
      setupcompletion( "~source" );
      
      //When using browser history, load the url which is previously pushed to the history:
      window.onpopstate = function() {
        $('body').load(location.href)
      };
      </script>
      
      gridRowFluid { gridSpan( 12 ) {
        wellSmall {
          inlForm{
            gridRowFluid{
              gridSpan( 10,1 ) {
                gridRowFluid {
                  gridSpan( 8 ) {
                    formEntry( "Search " + prjName )  { <span class="ui-widget">input( query ) [autocomplete="off", autofocus="", id="searchfield", onkeyup=updateResults()] </span>}
                  }
                  gridSpan( 4 ) {
                    formEntry( "Results per page" )  {
                      placeholder paginationOptions {
                        paginationButtons( searcher, namespace, langCons )
                      }
                    }
                  }
                }
                gridRowFluid {
                  input( SearchPrefs.caseSensitive ) [onclick=updateResults(), title="Case sensitive search"]{"case sensitive"}
                  " " input( SearchPrefs.exactMatch ) [onclick=updateResults(), title="If enabled, the exact sequence of characters is matched in that order(recommended)"]{"exact match"}
                  " " submit action{return search( namespace,query );} [class="btn btn-primary"] { "search" }
                }
              }
            }
            gridRowFluid{ gridSpan( 12 ) {
              placeholder facetArea {
                if( query.length() > 0 ) { viewFacets( searcher, namespace, langCons ) }
              }
            } }

          }
        }
      } }
      placeholder resultArea {
        if( query.length() > 0 ) { paginatedTemplate( searcher, pageNum, namespace, langCons ) }
      }
    }
    action updateResults() {
      if( query.length() > 2 ) {
        searcher := toSearcher( query,namespace, langCons ); //update with entered query
        if( count from searcher  > 0 ){
          //HTML5 feature, replace url without causing page reload
          runscript( "window.history.pushState('history','reposearch','" + navigate( doSearch( searcher, namespace, langCons, 1 ) ) + "');" );
          incSearchCount( namespace );
        }
        updateAreas( searcher, 1, namespace, langCons );
        replace( paginationOptions, paginationButtons( searcher, namespace, langCons ) );
      } else {
        clear( resultArea );
        clear( facetArea );
      }
    }
  }

  function updateAreas( searcher : EntrySearcher, page : Int, namespace : String, langCons : String ) {
    replace( facetArea, viewFacets( searcher, namespace, langCons ) );
    replace( resultArea, paginatedTemplate( searcher, page, namespace, langCons ) );
  }

  define navWithAnchor( n:String,a:String ) {
    rawoutput { <a all attributes href=n+"#"+a> elements </a> }
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
      ruleOffset := "";
      if( highlightedContent[0].length < 1 ) {
        ruleOffset := "1";
      } else {
        ruleOffset := /.+#(\d+).>.*/.replaceFirst("$1",highlightedContent[0][0]);
      }
      if( ! ( /^\d+$/.match( ruleOffset ) ) ) {
        ruleOffset := "?";
      } else {
        ruleOffset := "" + ( ruleOffset.parseInt() - 3 );
      }
    }
    gridRowFluid {

      navWithAnchor( viewFileUri , ruleOffset ) {
        <h5>
        output( if( linkText.length() >0 ) linkText else "-" )
            pullRight { div[class="repoFolderLocation"]{ output( location ) } }
        </h5>
      }
    }
    gridRowFluid {
      <div class="search-result-highlight">
        <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput( highlightedContent[0].concat( "<br />" ) ) </div>
          <div class="code-area" style="left: 3.1em;"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput( highlightedContent[1].concat( "<br />" ) ) </pre></div>
              </ div>
            }
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
    var prj              := findProject( namespace );
    var path_selection   := List<Facet>();
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
    formActions {
      div[class="facet-area"]{
        gridRowFluid{
          gridSpan( 7 ) {
            formEntry( "File extension" ) {
              for( f : Facet in fileExt facets from searcher ) {  pullLeft {  showFacet( searcher, f, ext_hasSel, namespace, langCons )  } }
            }
          }

          gridSpan( 5 ) {
            if( prj != null && prj.langConstructs.length > 0 ) {
              formEntry( "Language construct" ) {
                for( lc : LangConstruct in prj.langConstructs order by lc.name ) {
                  pullLeft {
                    if( lc_hasSel ) {
                      if( lc.name == langCons ) {
                        navigate search( namespace, searcher.getQuery() ) { buttonGroup { buttonMini{excludeFacetSym() } buttonMini{output( langCons ) } } }
                      } else {
                        buttonGroup {div[class="btn btn-mini disabled"]{ includeFacetSym() } div[class="btn btn-mini disabled"]{submitlink updateResults( lc ) { output( lc.name ) }}}
                      }
                    } else {
                      submitlink updateResults( lc ) { buttonGroup {buttonMini{ includeFacetSym() } buttonMini{output( lc.name ) }}}
                    }
                  }
                }
              }
            }
          }
        }

        gridRowFluid{
          formEntry( "File location" ) {
            placeholder repoPathPh {
              showPathFacets( searcher, path_hasSel, namespace, false, langCons )
            }
            for( f : Facet in path_selection ) { showFacet( searcher, f, path_hasSel, namespace, langCons ) }
          }
        }
      }
    }
    action updateResults( p: LangConstruct ) {
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
      submitlink action {replace( repoPathPh, showPathFacets( searcher, hasSelection, namespace, false, langCons ) );} [class="btn btn-small"] {"collapse"}
      <br />
      div {
        for( f : Facet in interestingPathFacets( searcher ) ) {
          gridRowFluid {
            pullLeft{
              showFacet( searcher, f, hasSelection, namespace, langCons )
            }
          }
        }
      }
    } else {
      submitlink action {replace( repoPathPh, showPathFacets( searcher, hasSelection, namespace, true, langCons ) );} [class="btn btn-small"] {"expand"}
    }
  }

  define showFacet( searcher : EntrySearcher, f : Facet, hasSelection : Bool, namespace : String, langCons : String ) {
    if( f.isMustNot() || ( !f.isSelected() && hasSelection ) ) {
      if( f.isSelected() ) {
        submitlink updateResults( searcher.removeFacetSelection( f ) ) { buttonGroup {div[class="btn btn-mini disabled"]{includeFacetSym() } div[class="btn btn-mini disabled"]{output( f.getValue() ) " (" output( f.getCount() ) ")"}}}
      } else {
        submitlink updateResults( ~searcher matching f.should() ) { buttonGroup {div[class="btn btn-mini disabled"]{includeFacetSym() }    div[class="btn btn-mini disabled"]{ output( f.getValue() ) " (" output( f.getCount() ) ")"}}}
      }
    } else {
      if( f.isSelected() ) {
        submitlink updateResults( searcher.removeFacetSelection( f ) ) { buttonGroup { buttonMini{excludeFacetSym() } buttonMini{output( f.getValue() ) " (" output( f.getCount() ) ") "} } }
      } else {
        buttonGroup {
          submitlink updateResults( ~searcher matching f.mustNot() ) [class="btn btn-mini"]{ excludeFacetSym() } " "
          submitlink updateResults( ~searcher matching f.should()  ) [class="btn btn-mini"]{ output( f.getValue() ) " (" output( f.getCount() ) ")"}
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
    var resultList := results from( ~searcher offset( ( pagenumber - 1 ) * resultsPerPage ) limit resultsPerPage );
    var size := count from searcher;
    var lastResult := size;
    var current : Int;
    init {
      if( size > pagenumber*resultsPerPage ) {
        lastResult := pagenumber * resultsPerPage;
      }
    }
    if( searcher.getQuery().length() >0 ) {
      gridRowFluid {
        pullLeft {
          pageIndex( pagenumber, size, resultsPerPage, 12, 3 )
        } pullRight{
          if( size > 0 ) {
            <strong> output( size ) " results" </strong> " found in " output( searchtime from searcher ) ", displaying results " output( ( pagenumber-1 ) *resultsPerPage + 1 ) "-" output( lastResult )
          } else {
            "no results found"
          }
        }
      }
      gridRowFluid {
        for( e : Entry in resultList ) {
          wellSmall {
            placeholder "result-"+e.url {highlightedResult( e, searcher, 3, langCons ) }
          }
        }
      }
      gridRowFluid { pullLeft{
          pageIndex( pagenumber, size, resultsPerPage, 12, 3 )
        }
      }
    }
    define pageIndexLink( page: Int, lab : String ) {
      navigate( doSearch( searcher, namespace, langCons, page ) ) { output( lab ) }
    }
  }

  define ajax paginationButtons( searcher : EntrySearcher, namespace : String, langCons : String ) {
    var limit := SearchPrefs.resultsPerPage;
    buttonGroup[data-toggle="buttons-radio"] {
      for( i : Int in [5, 10, 25, 50, 100, 500] ) {
        submitlink action { SearchPrefs.resultsPerPage := i; updateAreas( searcher, 1, namespace, langCons ); } [class="btn btn-small", id="limit"+i] {  output( i ) }
      }
    }
    <script>
      $ ( "#limit~limit" ).button( 'toggle' );
    </script>
  }



