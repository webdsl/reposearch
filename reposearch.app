application reposearch

  imports manage/manage-data
  imports manage/manage-ui
  imports search/search-configuration
  imports search/search-data
  imports search/search-ui
  imports search/search-misc
  imports entry/entry
  imports repository/repository
  imports request/request
  imports project/project
  imports ac
  imports language-construct/language-construct-data
  imports language-construct/language-construct-ui
  imports elib/lib
  
  init {
    Project{name:="WebDSL" repos:=[ ( SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo )]} .save();
  }

  function gAnalytics() : String {
    return "<script type=\"text/javascript\">var _gaq = _gaq || []; _gaq.push( ['_setAccount', 'UA-10588367-1'] ); _gaq.push( ['_trackPageview'] ); ( function() { var ga = document.createElement( 'script' ); ga.type = 'text/javascript'; ga.async = true; ga.src = ( 'https:' == document.location.protocol ? 'https://ssl' : 'http://www' ) + '.google-analytics.com/ga.js'; var s = document.getElementsByTagName( 'script' ) [0]; s.parentNode.insertBefore( ga, s ); } ) ();</script>";
  }
  
  define mainResponsive( ns : String ) {
    var project := if( ns == "" ) "All projects" else capitalize(ns);
    var query := "";
    var projects := [p | p : Project in( from Project ) order by p.displayName];
    var half  : Int := projects.length/2;
    includeCSS( "bootstrap/css/bootstrap.min.css" )
    includeCSS( "bootstrap/css/bootstrap-adapt.css" )
    includeCSS( "bootstrap-extension.css" )
    includeCSS( "prettify.css" )
    includeCSS( "jquery-ui-1.9.1.custom.min.css" )
    includeJS( "jquery-1.8.2.min.js" )
    includeJS( "jquery-ui-1.9.1.custom.min.js" )
    includeJS( "bootstrap/js/bootstrap.min.js" )
    includeHead( "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" )
    includeHead( gAnalytics() )
    navbarResponsive {
  
      navItems{
        if( ns != "Projects" ) {
          navItem { navigate( search( ns, "" ) ) { iRefreshWhite() " New search"  } }
          navItem { navigate( search( ns, "" ) ) [target:="_blank"]{ iPlusWhite() " New tab"  } }
        }
        navItem{
          dropdownInNavbar( project ) {
            dropdownMenu {
              for ( prj : String in SearchPrefs.projectHistoryNotNull.split( ";" ) ){
                dropdownMenuItem{ navigate search( prj ,"" ) { output( capitalize(prj) ) } }  
              }
              dropdownMenuDivider
              dropdownMenuItem{ navigate search( "","" ) { "All projects" } }
              dropdownMenuDivider
              if( projects.length > 10 ) {
                dropdownSubMenu( projects.get( 0 ).displayName + " - " + projects.get( half-1 ).displayName ) {
                  dropdownMenu {
                    for( index:Int from 0 to half ) {
                      dropdownMenuItem { navigate search( projects.get( index ).name , "" ) {output( projects.get( index ).displayName ) } }
                    }
                  }
                }
                dropdownSubMenu( projects.get( half ).displayName + " - " + projects.get( projects.length-1 ).displayName ) {
                  dropdownMenu {
                    for( index:Int from half to projects.length ) {
                      dropdownMenuItem { navigate search( projects.get( index ).name , "" ) {output( projects.get( index ).displayName ) } }
                    }
                  }
                }
              } else {
                for( p:Project order by p.displayName ) {
                  dropdownMenuItem { navigate search( p.name, "" ) {output( p.displayName ) } }
                }
              }
            }
          }
        }
        navItem{
          dropdownInNavbar( "Add your project" ) {
            dropdownMenu {
              dropdownMenuItem{<a data-toggle="modal" href="#addProject">"New project request"</a>}
              dropdownMenuItem{ navigate( pendingRequests() ) { "Pending requests" } }
            }
          }
        }
  
        navItem{ navigate( manage() )         { "Manage"           } }
        navItem{ navigate( searchStats() )    {"Search statistics" } }
  
      }
    }
    addProject()
    gridContainerFluid[id="content"] {
      placeholder notificationsPH{}
      elements
    }
    footer {
      gridContainerFluid{
        gridRowFluid{
          navigate( url( "http://yellowgrass.org/project/Reposearch" ) ) { "Issue tracker" } " - "
          navigate( url( "https://github.com/webdsl/reposearch" ) ) { "Reposearch on GitHub" } " - "
          navigate( dologin() ) {"Admin log in/out"  }
          pullRight{
            "Powered by " navigate( url( "http://www.webdsl.org" ) ) {"WebDSL"}
          }
        }
      }
    }
  }
  
  define override appname() { "Reposearch" }
  
  define page root() {
    title       { "Reposearch - Good in finding code fragments" }
    description { "A powerful source code search facility with project-scoped type ahead suggestions. With support for any SVN/Github repository location. Supports filtering on file extension, location and language construct." }
    mainResponsive( "Projects" ) {
      gridRowFluid {
        gridSpan( 12 ) {
          wellSmall {
            <center>output( fpMsg.msg ) </center>
          }
        }
      }
      gridRowFluid {
        gridSpan( 10,1 ) {
          header4 { "Search within project or " navigate( search( "", "" ) ) {"all"} " projects:" }
          tableNotBordered {
            theader{
              row{
                th[class="span4"]{ "Project" } th[class="span8"]{ "Repositories" }
              }
            }
            for( p:Project order by p.displayName ) {
              row {
                column{ navigate( search( p.name, "" ) ) {output( p.displayName ) }}
                column{ reposLink( p ) }
              }
            }
          }
        }
      }
    }
  }
 
  native class org.webdsl.reposearch.repositories.RepositoryFetcher as RepositoryFetcher {
    static test()
    static checkout( String ) : RepoTaskResult
    static checkout( File )   : RepoTaskResult
    static updateFromRevOrCheckout( String,Long ) : RepoTaskResult
    static checkout( String,String,String )       : RepoTaskResult
    static updateFromRevOrCheckout( String,String,String,Long ) : RepoTaskResult
    static log( String )
    static getLog() : String
  }
  
  native class org.webdsl.reposearch.repositories.RepoTaskResult as RepoTaskResult {
    getRevision() : Long
    getEntriesForAddition()  : List<Entry>
    getEntriesForRemoval()   : List<String>
  }
