module manage/manage-data

  invoke queryRepoTask()      every 30 seconds
  invoke invokeCheckReindex() every 60 seconds
  invoke manager.newHour()    every 1 hours

  var fpMsg := if( ( from Message ).length > 0 ) ( from Message ) [0]  else Message {msg := ""}
  var manager := if( ( from RepoSearchManager ).length > 0 ) ( from RepoSearchManager ) [0] else RepoSearchManager {hourCounter := 0 nextInvocation := now().addHours( 12 ) log:="" adminEmails:=""}
  var settings := if( ( from Settings ).length > 0 ) ( from Settings ) [0] else Settings {reindex := false projects := List<Project>() }
  var langConsRenewSchedule := if( ( from LangConstructRenewSchedule ).length > 0 ) ( from LangConstructRenewSchedule ) [0] else LangConstructRenewSchedule { dirtyProjects := Set<Project>() enabled:=true}


section entities

  entity Message {
    cache //home page message doesnt need to be fetched over and over again
    msg :: WikiText
  }

  entity Settings {
    reindex :: Bool
    projects-> List<Project>
    function addProject( p : Project ) {
      if( !reindex ) { reindex := true; }
      if( projects.indexOf( p ) < 0 ) { projects.add( p ); }
    }
  }

  entity RepoSearchManager {
    hourCounter     :: Int( default=0 )
    intervalInHours :: Int( default=12 )
    nextInvocation  :: DateTime
    lastInvocation  :: DateTime
    newWeekMoment   :: Date( default=now() )
    log             :: Text
    adminEmails     :: Text
    
    function newHour() {
      var execute := false;
      tryNewWeek();      
      hourCounter := hourCounter + 1;
      if( hourCounter >= intervalInHours ) {
         hourCounter := 0; execute := true; 
      }
      nextInvocation := now().addHours( intervalInHours - hourCounter );
      if( execute ) {
        refreshAllRepos();
      }
    }
    function shiftByHours( hours : Int ) {
      hourCounter := hourCounter - hours;
      nextInvocation := nextInvocation.addHours( hours );
    }
    function tryNewWeek() {
      if( newWeekMoment.addDays( 7 ).before( now() ) ) {
        newWeekMoment := newWeekMoment.addDays( 7 );
        for( p : Project ) {
          p.newWeek();
        }
      }
    }
  }


section functions

  function resetSchedule() {
    manager.hourCounter := 0;
    manager.intervalInHours := 12;
  }

  function validateEmailList( listStr : String ) : Bool {
    for( address : String in listStr.split( "," ) ) {
      if( !validateEmail( address ) ) { return false; }
    }
    return true;
  }
  
  function refreshAllRepos() {
    manager.lastInvocation := now();
    for( pr:Project ) {
      for( r:Repo in pr.repos ) {
        if( !( r isa FileRepo) ){
          queryRepo( r );
        }
      }
    }
  }
  function forceCheckoutAllRepos() {
    manager.lastInvocation := now();
    for( pr:Project ) {
      for( r:Repo in pr.repos ) {
        queryCheckoutRepo( r );
      }
    }
  }
  function cancelScheduledRefreshes() {
    for( pr:Project ) {
      for( r:Repo in pr.repos ) {
        cancelQueryRepo( r );
      }
    }
  }

  function queryRepoTask() {
    langConsRenewSchedule.run();
    var repos := from Repo where refresh=true and( inrefresh=null or inrefresh=false );
    var skippedFiles := List<String>();
    if( repos.length > 0 ) {
      var r := repos[0];
      var col : RepoTaskResult;
      var oldRev : Long := if( r.rev == null ) -1 else r.rev;
      var rev : Long;
      var performNextRefresh := false;
      r.inRefresh:=true;
      if( r isa FileRepo ){
        col := RepositoryFetcher.checkout( ( r as FileRepo ).repositoryFile ); 
      }
      if( r.refreshSVN ) {
        if( r isa SvnRepo ) { col := RepositoryFetcher.updateFromRevOrCheckout( ( r as SvnRepo ).url, oldRev ); }
        if( r isa GithubRepo ) { col := RepositoryFetcher.updateFromRevOrCheckout( ( r as GithubRepo ).user, ( r as GithubRepo ).repo, ( r as GithubRepo ).svnPath, oldRev ); }
      } else { //forced checkout
        if( r isa SvnRepo ) { col := RepositoryFetcher.checkout( ( r as SvnRepo ).url ); }
        if( r isa GithubRepo ) { col := RepositoryFetcher.checkout( ( r as GithubRepo ).user, ( r as GithubRepo ).repo, ( r as GithubRepo ).svnPath ); }
      }
      if( col == null ) {
        r.error := true;
      } else {
        //only replace entries when new ones are retrieved, i.e. col.getEntriesForAddition() is not null
        if( col.getEntriesForAddition() != null ) {
          if( !(r isa FileRepo) && r.refreshSVN ) {
            deleteRepoEntries( r, col );
          } else {
            deleteAllRepoEntries( r );
          }
          for( c: Entry in col.getEntriesForAddition() ) {
            c.projectname := r.project.name;
            c.repo := r;
            c.addconstructs();
            c.save();
          }
          settings.addProject( r.project );
        } else {
          performNextRefresh := true;
        }
        r.rev := col.getRevision();
        r.lastRefresh := now();
        r.error := false;
      }
      r.refresh:=false;
      r.refreshSVN := false;
      r.inRefresh:=false;
      if( performNextRefresh ) { queryRepoTask(); }
    }
  }

  function updateLog() {
    var toAdd := RepositoryFetcher.getLog();
    if( manager.log == null ) { manager.log := "";}
    if( toAdd.length() > 0 ) {
      manager.log := manager.log + toAdd;
      if( manager.log.length() > 25000 ) { manager.log := manager.log.substring( manager.log.length()-25000 );}
    }
  }

  //If settings.reindex is set to true and no refresh is going on, refresh suggestions/facet readers
  function invokeCheckReindex() {
    if( settings.reindex && ( from Repo where refresh=true ).length < 1 ) {
      var namespaces := [p.name | p:Project in settings.projects];
      //directly set to false, in case repositories are updated during suggestion reindexing
      settings.reindex := false;
      settings.projects := List<Project>();
      IndexManager.indexSuggestions( namespaces );
      IndexManager.renewFacetIndexReaders();
    }
  }

  function deleteAllRepoEntries( r:Repo ) {
    for( e:Entry where e.repo == r ) {  e.delete();}
  }

  function deleteRepoEntries( r:Repo, rtr : RepoTaskResult ) {
    var entries : List<Entry>;
    var projectName := r.project.name;
    for( url:String in rtr.getEntriesForRemoval() ) {
      entries := from Entry as e where e.repo = ~r and e.url=~url;
      
      //when no hits are retrieved, we might be dealing with a directory, so try to delete all files within that directory
      if( entries.length < 1 )  { entries := from Entry as e where e.repo = ~r and e.url like ~(url+"/%"); }
      
      for( e : Entry in entries ) { RepositoryFetcher.log( "Deleting Entry: " + e.url ); e.delete();  }
    }
  }
