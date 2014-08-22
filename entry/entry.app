module entry/entry

section entities

  entity Entry {
    name        :: String
    content     :: Text
    url         :: URL (length=511)
    projectname :: String
    repo        -> Repo
  }
  search mapping Entry {
    + content using keep_all_chars      as content
    + content using keep_all_chars_cs   as contentCase ^ 50.0
    content   using code_identifiers_cs as codeIdentifiers ( autocomplete )
    + name    using filename_analyzer   as fileName ^ 100.0 ( autocomplete )
    name      using extension_analyzer  as fileExt
    url       using path_analyzer       as repoPath
    constructs with depth 1
    namespace by projectname
  }

section pages/templates

  //backwards compatibility
  define page showFile( searcher : EntrySearcher, e : Entry ) {
    init {return viewFile( searcher.getQuery(),e.url, e.projectname, "" );}
  }

  define page viewFile( query : String, url:URL, projectName:String, langCons : String ) {
    var e := ( from Entry as e where e.url=~url and e.projectname = ~projectName ) [0]
    var viewFileUri := navigate( viewFile( query, url, projectName, langCons ) );
    var linkText    := "";
    var location    : String;
    var lineNumbers : String;
    var codeLines   : String;
    var highlighted : List<List<String>>;
    var searcher    := toSearcher( query, "", langCons );
    init {
      linkText := searcher.highlight( "fileName", e.name, "<span class=\"hlcontent\">","</span>", 1, 256, "" );
      if( linkText.length() < 1 ) { linkText := e.name; }
      location := e.url.substring( 0, e.url.length() - e.name.length() );
      highlighted := highlightCodeLines( searcher, e, 1000000, 1, true, viewFileUri, langCons );
      lineNumbers := highlighted[0].concat( "<br />" );
      codeLines := highlighted[1].concat( "<br />" );
      //add line number anchors
      lineNumbers := /> ( \d+ ) </.replaceAll( ">$1<a class=shift-top name=\"$1\"/><", lineNumbers );
    }    
    title       { output( e.name + ":" + query + " - " + projectName + " | Reposearch" ) }
    description { output (
                  "Source code of file: " + e.name + 
                  ", project: " + projectName  + 
                  ", query: " + query + 
                  ", repository url: " + e.url)
                }
                
    trackEvent( projectName, "View file" )
    
    mainResponsive( projectName ) {
      wellSmall {
        gridRow{
          navigate( url( e.url ) ) {
            <h5>
            <b>rawoutput( if( linkText.length() >0 ) linkText else "-" ) </b>
                pullRight { div[class="repoFolderLocation"]{ output( location ) } }
            </h5>
          }
        }

        gridRow{
          <div class="search-result-highlight">
            <div class="linenumberarea" style="left: 0em; width: 3.1em;">rawoutput( lineNumbers ) </div>
            <div class="code-area" style="left: 3.1em;" id="code-area"><pre class="prettyprint" style="WHITE-SPACE: pre">rawoutput( codeLines ) </pre></div>
          </ div>
        }
        prettifyCode( projectName )
      }
    }
  }


