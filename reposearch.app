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
    Project{name:="WebDSL" repos:=[ ( SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac" refresh:=true } as Repo )]} .save();
  }

  function gAnalytics() : String {
    return "<script type=\"text/javascript\">var _gaq = _gaq || []; var pluginUrl = '//www.google-analytics.com/plugins/ga/inpage_linkid.js'; _gaq.push(['_require', 'inpage_linkid', pluginUrl]); _gaq.push( ['_setAccount', 'UA-38993791-2'] ); _gaq.push( ['_trackPageview'] ); ( function() { var ga = document.createElement( 'script' ); ga.type = 'text/javascript'; ga.async = true; ga.src = ( 'https:' == document.location.protocol ? 'https://ssl' : 'http://www' ) + '.google-analytics.com/ga.js'; var s = document.getElementsByTagName( 'script' ) [0]; s.parentNode.insertBefore( ga, s ); } ) ();</script>";
  }
    
  define mainResponsive( ns : String ) {
    var project := if( ns == "" ) "All projects" else capitalize(ns);
    var query := "";
    includeCSS( "bootstrap/css/bootstrap.min.css" )
    includeCSS( "bootstrap/css/bootstrap-adapt.css" )
    includeCSS( "bootstrap-extension.css" )
    includeCSS( "jquery-ui-1.9.1.custom.min.css" )
    includeJS( "jquery-1.8.2.min.js" )
    includeJS( "jquery-ui-1.9.1.custom.min.js" )
    includeJS( "bootstrap/js/bootstrap.min.js" )
    includeHead( "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" )
    includeHead( gAnalytics() )
    navbar {
  
      navItems{
        navItem{
          dropdownInNavbar( project ) {
            dropdownMenu {
              for ( prj : String in SearchPrefs.projectHistoryNotNull.split( ";" ) ){
                dropdownMenuItem{ navigate search( prj ,"" ) { output( capitalize(prj) ) } }  
              }
              dropdownMenuDivider
              dropdownMenuItem{ navigate search( "","" ) { "All projects" } }
              dropdownMenuItem{ navigate root() { "Other project" } }
            }
          }
        }
        if( ns != "Projects" ) {
          navItem { navigate( search( ns, "" ) ) { iRefreshWhite() " New search"  } }
          navItem { navigate( search( ns, "" ) ) [target:="_blank"]{ iPlusWhite() " New tab"  } }
        }
        navItem{
          dropdownInNavbar( "Add project" ) {
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
          navigate( download() ) { "Download Reposearch" } " - "
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
    var projects := from Project;
    title       { "Reposearch Source Code Search Engine - Good in finding code fragments" }
    description { "A powerful source code search engine with project-scoped type ahead suggestions. With support for any SVN/Github repository location. Supports filtering on file extension, location and language construct." }
    mainResponsive( "Projects" ) {
      gridRowFluid {
        gridSpan( 12 ) {
            rawoutput( messages.frontPageMsg )
        }
      }
      gridRowFluid {
        gridSpan( 10,1 ) {
          
          recentProjects
          
          header3 { "Search within project or " navigate( search( "", "" ) ) {"all"} " projects:" }
          gridRowFluid{
            filterProject( projects )
          }
          
          placeholder "projectsArea" {  
            showProjects( projects )
          }        

        }
      }
    }
  }
  
  define ajax showProjects( projects : List<Project> ){
    if(projects.length < 1) {
      "No projects found"
    } else {
      // tableNotBordered{  //workaround for http://yellowgrass.org/issue/WebDSL/709 using inline html
      <table class="table table-striped table-condensed">
        for( p:Project in projects order by p.displayName ) {
          row {
            column[class="span4"]{ navigate( search( p.name, "" ) ) {output( p.displayName ) }}
            column[class="span8"]{ reposLink( p ) }
          }
        }   
      </table>
      // }
    }
  }
  
  define filterProject( projects : Ref<List<Project>> ){
    var prefix := "";
    gridSpan(4){ inlForm{ 
      input( prefix ) [id="filterInput", autocomplete="off", oninput="$(this).keyup();", autofocus="", onkeyup=updateProjects(), placeholder="Filter"] 
    } }
    
    action updateProjects(){
      if(prefix.length() > 0){
        var prefixq := ProjectSearcher.escapeQuery(prefix) + "*";
        projects := results from search Project matching prefixq;
      } else {
        projects := from Project;
      }
      replace("projectsArea");
    }
  }
    
  define recentProjects() {
    var recentProjects := SearchPrefs.projectHistoryNotNull.split( ";" );
    if (recentProjects.length > 0) {
      header3 { "Your recently searched projects" }
	      for( prjStr : String in recentProjects ){
		      gridRowFluid{ navigate( search( prjStr, "" ) ) { output( capitalize( prjStr ) ) } }
		    }
    }
  }
  
  page download(){
    title       { "Download page | Reposearch" }
    description { "Download Reposearch source code search engine" }
  	mainResponsive( "Projects" ){
  		gridRowFluid {
        gridSpan( 12 ) {
        	rawoutput( messages.downloadMsg )
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
