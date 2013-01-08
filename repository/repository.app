module repository/repository

section entities

  entity Repo {
    project     -> Project  ( inverse=Project.repos )
    refresh     :: Bool
    refreshSVN  :: Bool
    inRefresh   :: Bool     ( default=false )
    error       :: Bool
    rev         :: Long
    lastRefresh :: DateTime( default=now().addYears( -20 ) )
  }
  
  entity SvnRepo : Repo {
    url :: URL
  }
  
  entity GithubRepo : Repo {
    user    ::String( default="" )
    repo    ::String( default="" )
    svnPath ::String( default="" )
  }
  
  entity FileRepo : Repo {
    repositoryFile :: File
  }
  
section functions

  function createNewRepo( url:String,isGithubTag:Bool, f : File ) : Repo {
    if( f != null){
      return FileRepo{ repositoryFile := f refresh := true };
    } else {
	    if( url.toLowerCase().contains( "github.com" ) ) {
	      //https://github.com/mobl/mobl/tree/master/editor/java/mobl/strategies
	      var params := /.*github\.com/ ( [^/]+ ) / ( [^/]+ ) /? ( .* ) /.replaceAll( "$1,$2,$3", url ).split( "," );
	      var u := params[0];
	      var r := params[1];
	      var p := "trunk";
	      var prefixPath := "";
	      log( "params[2]:" + params[2] );
	      if( / ( ^$ ) | ( ( tree|blob ) /master.* ) /.match( params[2] ) ) {
	        prefixPath := "trunk";
	      } else {
	        prefixPath := if( isGithubTag ) "tags" else "branch";
	      }
	      if( params[2].length() > 1 ) {
	        p := /^ ( tree|blob ) ( /master ) ?/.replaceFirst( prefixPath, params[2] );
	      }
	      return GithubRepo { user:=u.trim() repo:=r.trim() svnPath:=p.trim() refresh:=true};
	    } else{
	      return SvnRepo{ url:=url.trim() refresh:=true };
	    }
    }
  }
  
  function queryRepo( r:Repo ) {
    r.refresh := true;
    r.refreshSVN := true;
  }
  function queryCheckoutRepo( r:Repo ) {
    r.refresh := true;
    r.refreshSVN := false;
  }
  function cancelQueryRepo( r:Repo ) {
    r.refresh := false;
    r.refreshSVN := false;
  }


section pages/templates

  define reposLink( p: Project ) {
    placeholder "repos-"+p.displayName {showReposLink( p ) }
  }

  define ajax showReposLink( p : Project ) {
    var nOfRepos := p.repos.length; 
    var btnText := if ( nOfRepos == 1) 1+" repository" else nOfRepos+" repositories"
    submitlink action {replace( "repos-"+p.displayName, repos( p ) );} {  buttonMini{ output( btnText ) } }
  }

  define output( r : Repo ) {
    wellSmall {
      gridRowFluid() {
        if( r isa SvnRepo ) {
          "SVN: "
          output( ( r as SvnRepo ).url )
        } else { if ( r isa GithubRepo ) {
          "Github: "
          output( ( r as GithubRepo ).user )
          " "
          output( ( r as GithubRepo ).repo )
          " "
          output( ( r as GithubRepo ).svnPath )
        } else {
          //file repo
          "Uploaded file: " output( ( r as FileRepo).repositoryFile.fileName() )          
        } }
      }
      gridRowFluid {
        "Rev: " output( r.rev )
      } gridRowFluid {
        "Last refresh: " output( r.lastRefresh )
      } gridRowFluid {
        navigate( skippedFiles( r ) ) [target:="_blank"]{"Files marked as binary(not indexed)"}
      }
      
      elements
    }
  }

  define ajax repos( p : Project ) {
    gridRowFluid() {
      submitlink action {replace( "repos-"+p.displayName, showReposLink( p ) );} { buttonMini{"hide"} }
    }
    for( r : Repo in p.repos ) {
      gridRowFluid {
        output( r )
      }
    }
  }
