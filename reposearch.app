application reposearch

  imports built-in

  imports ac
  imports analytics/analytics
  imports entry/entry
  imports language-construct/*
  imports manage/*
  imports project/project
  imports repository/repository
  imports request/request
  imports search/*
  imports tools/tools

  imports elib/*
  imports elib-bootstrap-3/*

  init {
  	var repo := (SvnRepo{ url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac" refresh:=true } as Repo);
    Project{name:="WebDSL" repos:=[ repo ] }.save();
  }
  
  entity BootstrapTheme{
  	name : String (id)
  	filename : String
  	cache
  }
  entity ActiveTheme{
  	theme : BootstrapTheme (validate(theme != null, "Please select a theme"))
  	cache
  }
  var activeTheme := ActiveTheme{ theme := BootstrapTheme{ name:= "bootstrap" filename:= "bootstrap.min.css" } }
  
  function initThemes(){
  	var theme : BootstrapTheme;
  	var names := ["cerulean","cosmo","flatly","lumen","simplex","spacelab","yeti"];
  	for(name in names){
  		theme := BootstrapTheme{ name := name filename:= name+".min.css" };
  		theme.save();
  	}
  }
  define mainResponsive( ns : String ) {
    var project := if( ns == "" ) "All projects" else capitalize(ns);
    var query := "";
   
	template gridContainer(){ div[class="container-fluid", all attributes]{ elements } }
   
    includeCSS( "bootstrap/css/" + activeTheme.theme.filename + "?1" ) 
    includeCSS( "bootstrap-adapt.css?1" )
    includeCSS( IncludePaths.jQueryUICSS() )
    includeJS( IncludePaths.jQueryJS() )
    includeJS( IncludePaths.jQueryUIJS() )
    includeJS( "bootstrap/js/bootstrap.min.js?1" )

    includeHead( "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" )
    includeHead( gAnalytics() )
    
    navbarResponsive {
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
          navItem { navigate( search( ns, "" ) ) { iRefresh() " New search"  } }
          navItem { navigate( search( ns, "" ) ) [target:="_blank"]{ iPlus() " New tab"  } }
        }
        navItem{
          dropdownInNavbar( "Add project" ) {
            dropdownMenu {
              dropdownMenuItem{<a data-toggle="modal" href="#addProject">"New project request"</a>}
              dropdownMenuItem{ navigate( pendingRequests() ) { "Pending requests" } }
            }
          }
        }
        navItem{ navigate( indentTool() )    { iIndentRight " Code Indenter" } }
  
        navItem{ navigate( manage() )         { "Manage"           } }
        navItem{ navigate( searchStats() )    {"Search statistics" } }
  
      }
    }
    addProject()
    gridContainer[id="content"] {
      placeholder "notificationsPH"{}
      elements
    }
    footer {
      gridContainer{
        gridRow{ gridCol(12){
          navigate( url( "http://yellowgrass.org/project/Reposearch" ) ) { "Issue tracker" } " - "
          navigate( url( "https://github.com/webdsl/reposearch" ) ) { "Reposearch on GitHub" } " - "
          navigate( download() ) { "Download Reposearch" } " - "
          navigate( dologin() ) {"Admin log in/out"  }
          pullRight{
            "Powered by " navigate( url( "http://www.webdsl.org" ) ) {"WebDSL"}
          }
        } }
      }
    }
	<script>
		$('input[type=text],input[type=search],input[type=password],select,textarea').addClass('form-control');
	</script>
  }
  
  define override appname() { "Reposearch" }
  
  page root() {
    title       { "Reposearch Source Code Search Engine - Good in finding code fragments" }
    description { "A powerful source code search engine with project-scoped type ahead suggestions. With support for any SVN/Github repository location. Supports filtering on file extension, location and language construct." }
    mainResponsive( "Projects" ) {
      gridRow {
        gridCol( 12 ) {
            <center> rawoutput( globalMessages.frontPageMsg ) </center>
        }
      }
      gridRow {
        gridCol( 5,1 ) { instantSearch } gridCol( 5 ){ recentProjects }      
      }
      gridRow{
        gridCol( 10,1 ) { filterProjectHomepage }
      }
    }
  }
  
  define ajax showProjects( projects : List<Project> ){
  	gridRow{ gridCol(12){
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
    } }
  }
  
  define instantSearch(){
  	var source := "/autocompleteService/";
  	var query := ""
  	includeJS( "completion.js" )
  	<script>setupcompletion( "~source" );</script>
  	
  	header3 { "Instantly search all projects" }
  	gridRow{ gridCol(8){ inlForm{
  		<span class="ui-widget" id="instant-search">input( query ) [autocomplete="off", autofocus="", id="searchfield", type="search", placeholder="Search"] </span>
  		submit action{ return search("", query);}[style="display: none;", id="perform-search"]{"search"}
  	} } }
  	
  	<script>
  	var instantSearch = $("#instant-search");
  	instantSearch.keyup(function (e) {
	    if (e.keyCode == 13) {
	        $("#perform-search").click();
	    }
	});
	instantSearch.focus();
  	</script>
  }
  
  define filterProjectHomepage(){ 
  	var projects := from Project;
  	header3 { "Or pick a project" }
  	filterProject( projects )
	    placeholder "projectsArea" {  
		  showProjects( projects )
    }
  }
  
  define filterProject( projects : Ref<List<Project>> ){
    var prefix := "";
    
    gridRow{ gridCol(4){ form[onsubmit="javascript:return false"]{ 
      input( prefix ) [id="filterInput", autocomplete="off", oninput="$(this).keyup();", onkeyup=updateProjects(), placeholder="Filter"] 
    } } }
    
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
      header3 { "Or pick a recently searched project" }
	      for( prjStr : String in recentProjects ){
		      gridRow{ gridCol(12){ navigate( search( prjStr, "" ) ) { output( capitalize( prjStr ) ) } } }
		    }
    }
  }
  
  page download(){
    title       { "Download page | Reposearch" }
    description { "Download Reposearch source code search engine" }
  	mainResponsive( "Projects" ){
  		gridRow {
        gridCol( 12 ) {
        	rawoutput( globalMessages.downloadMsg )
        }
      }
  	}
  }
  
  ignore-access-control page doDownload(){
  	mainResponsive("Projects"){
  		<iframe width=1 height=1 frameborder=0 src=downloadLink()></iframe>
  		<center> "Your download should begin shortly" </center>  	
  		trackEvent("Download", "Download reposearch standalone")
    }
  }
  
  function downloadLink() : String {
  	return "http://hydra.nixos.org/job/webdsl/reposearch-app/reposearch-app/latest/download-by-type/file/zip";
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
