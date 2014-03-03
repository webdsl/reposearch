module search/search-data

section entities

  session SearchPrefs {
    resultsPerPage :: Int   ( default=10 )
    caseSensitive  :: Bool  ( default=false )
    exactMatch     :: Bool  ( default=true )
    regex          :: Bool  ( default=false )
    projectHistory :: String( default="" )
    projectHistoryNotNull :: String := if( projectHistory == null ) "" else projectHistory
    
    function addToHistory( projectName : String ) {
      if ( projectName == "" ) { return; } 
      var prjList := projectHistoryNotNull.split( ";" );
      var newHistory := projectName;
      for( item : String in prjList where item != projectName limit 4 ) {
        newHistory := newHistory + ";" + item;
      }
      projectHistory := newHistory;
    } 
  }

section functions

  function incSearchCount( namespace : String ) {
    SearchCounter.inc( namespace );
  }

  function interestingPathFacets( searcher : EntrySearcher ) : List<Facet> {
    var previous : Facet;
    var userQuery :=  "";
    var allFacets:= repoPath facets from searcher;
    var toReturn := List<Facet>();
    for( f : Facet in allFacets order by f.getValue() ) {
      if( previous != null && ( f.getValue().startsWith( previous.getValue() ) && f.getCount() == previous.getCount() ) ) {
        toReturn.removeAt( toReturn.length - 1 );
      }
      toReturn.add( f );
      previous := f;
    }
    return toReturn;
  }

  function toSearcher( q:String, ns:String, langCons:String ) : EntrySearcher {

    var searcher := search Entry in namespace ns with facets fileExt(120), repoPath(200) [no lucene, strict matching];
    // if(SearchPrefs.regex) {
    //     return searcher.regexQuery( q );
    // }
    if( ns == ""){
    	~searcher with facet ~"_WebDSLNamespaceID_"(120);
    }
    
    var slop := if( SearchPrefs.exactMatch ) 0 else 100000;
    
    if( SearchPrefs.caseSensitive ) { searcher:= ~searcher matching contentCase, fileName: q~slop; }
    else                            { searcher:= ~searcher matching q~slop; }

    if( langCons.length() >0 ) { addLangConstructConstraint( searcher, langCons ); }
    return searcher;
  }

  function highlightCodeLines( searcher : EntrySearcher, entry : Entry, fragmentLength : Int, noFragments : Int, fullContentFallback: Bool, viewFileUri : String, langConsStr : String ) : List<List<String>> {
    var raw : String;
    var hlField := if( SearchPrefs.caseSensitive ) "contentCase" else "content";
    if( langConsStr.length() > 0 ) {
      //a langCons is used
      var langCons : LangConstruct := findLangConstruct( langConsStr );
      //decorate the langCons matches such that these will match for field constructs.matches
      var content := MatchExtractor.decorateMatches( langCons, entry.content, searcher.getQuery() );
      //highlight
      raw := searcher.highlightLargeText( "constructs.matches", content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n" );
      //undecorate highlighted matches again
      raw := /\s?\$OHL\$[^#]+#MATCH#([^\$]+)\$CHL\$\s?/.replaceAll("\\$OHL\\$$1\\$CHL\\$", raw);
    } else {
      raw := searcher.highlightLargeText( hlField, entry.content, "$OHL$","$CHL$", noFragments, fragmentLength, "\n%frgmtsep%\n" );
    }
    if( fullContentFallback && raw.length() < 1 ) {
      raw := entry.content;
    }
    var highlighted := rendertemplate( output( raw ) ).replace( "$OHL$","<span class=\"hlcontent\">" ).replace( "$CHL$","</span>" ); //.replace("\r", "");
    var splitted := highlighted.split( "\n" );
    var listCode := List<String>();
    var listLines := List<String>();
    var lists := List<List<String>>();
    var lineNum : String;
    var fixPrevious := false;
    var alt := false;
    var style := "b";
    for( s:String in splitted ) {
      //We alternate between style a and b for different fragments
      if( /^%frgmtsep%/.find( s ) ) {
        if( alt ) {
          style := "b";
          alt := false;
        } else {
          alt := true;
          style := "a";
        }
        listLines.add( "<div class=\"nolinenumber" + style +"\">...</div>" );
        listCode.add( "</pre><pre class=\"prettyprint\" style=\"WHITE-SPACE: pre\">" );
		    if(fixPrevious){
		      listLines.set( listLines.length-2 , "<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap( viewFileUri, "?" )  ) + "</div>" );
		      fixPrevious := false;
		    }		    
      } else {
        //If line number is stripped off by highlighting, postpone line number determination to next iteration
        if( /^\D/.find( s ) ) {
          listLines.add( "" );
          listCode.add( s );
          fixPrevious := true;
        } else {
          // line numbers are added at the beginning of code lines followed by a whitespace
          // original: 'foo:bar'
          // modified: '34 foo:bar '
          lineNum := /^ ( \d+ ).*/.replaceFirst( "$1", s );
          listLines.add( "<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap( viewFileUri, lineNum )  ) + "</div>" );
          if( fixPrevious ) {
            listLines.set( listLines.length-2 , "<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap( viewFileUri, ""+ ( lineNum.parseInt()-1 ) )  ) + "</div>" );
            fixPrevious := false;
          }
          if( s.length() != lineNum.length() ) {
            listCode.add( s.substring( lineNum.length() + 1 ) );
          } else {
            //if code line itself is an empty line, substring will encounter an empty string -> exception
            listCode.add( "" );
          }
        }
      }
    }
    //Line number unknown, link to line num 1
    if(fixPrevious){
      listLines.set( listLines.length-1 , "<div class=\"linenumber" + style +"\" UNSELECTABLE=\"on\">" + rendertemplate( issue599wrap( viewFileUri, "?" )  ) + "</div>" );
    }
    lists.add( listLines );
    lists.add( listCode );
    return lists;
  }

  define issue599wrap( viewFileUri: String, lineNum: String ) {
    navWithAnchor( viewFileUri, lineNum ) { output( lineNum ) }
  }