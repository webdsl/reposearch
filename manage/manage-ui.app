module manage/manage-ui

section pages/templates

  define page manage() {
    init {
      if( langConsRenewSchedule.enabled == null ) {
        langConsRenewSchedule.enabled := true;
      }
    }
    title { output( "Manage Reposearch | Reposearch" ) }
    mainResponsive( "Projects" ) {
      manageRefresh()
      manageRequestReceipts()
      placeholder requestsPH {
        showRequests()
      }
      manageProjects()
      <br />
      manageFrontpageMessage()
      <br />
      logMessage()
    }
  }

  page searchStats() {
    var startDate := if( manager.newWeekMoment!=null ) manager.newWeekMoment else now();
    var projectsInOrder := from Project order by searchCount desc;
    title { output( "Search statistics | Reposearch" ) }
    mainResponsive( "Projects" ) {
      showSearchStats()
      submit action {SearchStatistics.clear();} {"Reset global statistics"}
      header {"Search counts per project"}
      table {
        row{ column{ <i>"Project name"</i> } column{ <i>"total"</i> } column{ <i>"this week"</i> } column{ <center><i>"since"</i></center> } column{ <i>"reset"</i> }}
        for( pr : Project in projectsInOrder order by pr.weeklySearchCount desc ) {
          searchCountInTable( pr )
        }
      }
      form {
        "Change the day at which the week counters reset(date of last reset): " input( startDate )
        submit action{manager.newWeekMoment := startDate;}{"set"}
      } <br />
      submit action {for( pr : Project ) { pr.resetSearchCount(); }} {"Reset search statistics for all projects"}
    }
  }

  define manageRequestReceipts() {
    var addresses : String := manager.adminEmails;
    form {
      input( addresses ) {" will receive a notification upon a request."}
      validate( validateEmailList( addresses ) ,"Email addresses need to be seperated by a comma, without whitespace e.g. 'foo@bar.com,bar@foo.com'" )
      submit action{manager.adminEmails := addresses;}{"apply"}
    }
  }

  define ajax showProject( pr : Project ) {
    div[class="main-container"] {
      searchCount( pr )
      <br />
      placeholder "reposPH" + pr.name{
        showRepos( pr )
      }
      placeholder "addRepoPH" + pr.name{
        addRepoBtn( pr )
      }
      <br />
      div[class="langCons-container"]{
        manageLangConstructs( pr )
      }
    }
  }

  define manageProjects() {
    var p := "";
    var fr := ( from Repo where project is null );
    div[class="top-container"] {<b>"Manage Projects"</b>}
    div[class="main-container"] {
      form{
        input( p )
        submit action{Project{name:=p} .save();} {"Add new project"}
      }
      <br />
      for( pr:Project order by pr.displayName ) {
        div[class="top-container"] {
          <b>submitlink( pr.name, showProject( pr ) ) [ajax]</b>
          div[class="float-right"]{"[" submitlink( "remove project", removeProject( pr ) ) "]*"}
        }
        <div id=URLFilter.filter( "projectPH"+pr.name ) class="webdsl-placeholder" style="display: none;">showProject( pr ) </div>
        }
              "* Removal of a project may take over a minute, please be patient."
              <br />
      if( fr.length > 0 ) {
        <br />
        submit action {
          for( r:Repo in fr ) {
            deleteAllRepoEntries( r );
            r.delete();
          }
          return manage();
        } {"Remove foreign Repo's(" output( fr.length ) ")"} " (Repo entities where project == null)"
      }

    }
    action showProject( pr : Project ) {
      visibility( "projectPH"+pr.name, toggle );
    }
    action removeProject( pr : Project ) {
      for( r:Repo in pr.repos ) {
        deleteAllRepoEntries( r );
        r.delete();
      }
      pr.langConstructs.clear();
      settings.projects.remove( pr );
      pr.delete();
      settings.reindex := true;
      return manage();
    }
  }

  define searchCount( pr : Project ) {
    "searches this week(since " output( manager.newWeekMoment ) "): " <b>output( pr.weeklySearchCount ) </b>
    <br />
    "searches total(since " output( pr.countSince ) "): " <b>output( pr.searchCount ) </b> " " submitlink( "reset", action {pr.resetSearchCount();} )
    <br />
  }

  define searchCountInTable( pr : Project ) {
    row {
      column{output( pr.displayName ) }
      column{<center><b>output( pr.searchCount ) </b></center>}
      column{<center><b>output( pr.weeklySearchCount ) </b></center>}
      column{output( pr.countSince ) }
      column{submitlink( "reset", action{pr.resetSearchCount();} ) }
    }
  }

  define manageFrontpageMessage() {
    var fpMsgText := fpMsg.msg;
    div[class="top-container"] {<b>"Edit Frontpage Message"</b>}
    div[class="main-container"] {
      form{
        input( fpMsgText ) [onkeyup := updateFpMsgPreview( fpMsgText )]
        <br />submit action{fpMsg.msg := fpMsgText; fpMsg.save();}{"save"}
      }
      placeholder fpMsgPreview {FpMsgPreview( fpMsgText ) }
    }
    action ignore-validation updateFpMsgPreview( d : WikiText ) {
      replace( fpMsgPreview, FpMsgPreview( d ) );
    }
  }

  define ajax FpMsgPreview( d : WikiText ) {
    block {
      <center> output( d ) </center>
    }
  }

  define logMessage() {
    div[class="top-container"] {<b>"SVN Log"</b>}
    div[class="main-container"] {
      placeholder log {showLog() }<br />
      "Auto-refreshes every 5 seconds" <br />
      submit action{replace( log, showLog() );} [id = "autoRefresh", ajax]{"force refresh log"}
      <script>
      var refreshtimer;
      function setrefreshtimer() {
        clearTimeout( refreshtimer );
        refreshtimer = setTimeout( function() {
          $ ( "#autoRefresh" ).click();
          setrefreshtimer();
        },5000 );
      }
      setrefreshtimer();
      </script>
    }
  }

  define manageRefresh() {
    placeholder refreshManagement { refreshScheduleControl() } <br />
  }

  define ajax refreshScheduleControl() {
    var now := now();
    div[class="top-container"] {<b>"Manage Refresh Scheduling"</b>}
    div[class="main-container"] {
      table{
        row{ column{<i>"Refresh scheduling:" </i>}                  column{ submit action{resetSchedule();} {"reset"} } }
        row{ column{"Server time"}                                  column{ output( now ) } }
        row{ column{"Last refresh(all repos)"}                     column{ if( manager.lastInvocation != null ) { output( manager.lastInvocation ) } else {"unkown"} } }
        row{ column{"Next scheduled refresh(all repos)"}           column{ output( manager.nextInvocation ) " " submit action{manager.shiftByHours( -24 ); replace( refreshManagement, refreshScheduleControl() );} {"-1d"} submit action{manager.shiftByHours( -3 ); replace( refreshManagement, refreshScheduleControl() );} {"-3h"} submit action{manager.shiftByHours( 3 ); replace( refreshManagement, refreshScheduleControl() );} {"+3h"} submit action{manager.shiftByHours( 24 ); replace( refreshManagement, refreshScheduleControl() );} {"+1d"} } }
        row{ column{"Auto refresh interval(hours)"}                column{ form{ input( manager.intervalInHours ) [style := "width:3em;"]  submit action{manager.save(); replace( refreshManagement, refreshScheduleControl() );}{"set"}  } } }
        row{ column{<i>"Instant refresh management:" </i>}          column{ }}
        row{ column{"Update all repos to HEAD: "}                   column{submit action{refreshAllRepos();         replace( refreshManagement, refreshScheduleControl() );} {"refresh all"} } }
        row{ column{"Force a fresh checkout for all repos: "}       column{submit action{forceCheckoutAllRepos();   replace( refreshManagement, refreshScheduleControl() );} {"force checkout all"} } }
        row{ column{"Cancel all scheduled refresh/checkouts: "}     column{submit action{cancelScheduledRefreshes(); replace( refreshManagement, refreshScheduleControl() );} {"cancel all"} } }
        row{ column{"Auto renewal of language construct matches: "} column{ "enabled? " form{ input( langConsRenewSchedule.enabled ) submit action{langConsRenewSchedule.save(); replace( refreshManagement, refreshScheduleControl() );} {"apply"} } }}
      }
    }
  }

  define ajax addRepoBtn( pr : Project ) {
    submit action { replace( "addRepoPH" + pr.name, addRepo( pr ) );} {"Add repository"}
  }

  define ajax showRepos( pr : Project ) {
    for( r:Repo in pr.repos ) {
      showRepo( pr,r )
    }
  }

  define ajax addRepo( pr : Project ) {
    var gu:String
    var gr:String
    var isTag:=false;
    var n :URL
    div[class="new-repo"] {
      form{
        "SVN or github URL: "
        input( n )
        <br />"resides within github tag?: "
        input( isTag )
        submit action{ pr.repos.add( createNewRepo( n, isTag ) ); replace( "addRepoPH" + pr.name, addRepoBtn( pr ) ); replace( "reposPH" + pr.name, showRepos( pr ) );} {"Add repository"}
      }
    }
    div {
      submit action{ replace( "addRepoPH" + pr.name, addRepoBtn( pr ) );} {"Cancel"}
    }
  }

  define showRepo( pr:Project, r:Repo ) {
    div[class="show-repo"] {
      output( r )
      div{
        if( r.refresh ) {
          if( r.refreshSVN ) { "UPDATE TO HEAD SCHEDULED" }
          else { "CHECK OUT SCHEDULED" }
          submit action {cancelQueryRepo( r ); replace( "reposPH" + pr.name,showRepos( pr ) ); } {"Cancel"}
        } else{
          submit action{queryRepo( r ); replace( "reposPH" + pr.name,showRepos( pr ) );} {"Update if HEAD > r" output( r.rev ) }
          submit action{queryCheckoutRepo( r ); replace( "reposPH" + pr.name,showRepos( pr ) );} {"Force checkout HEAD"}
        }
        submit action{pr.repos.remove( r ); deleteAllRepoEntries( r ); replace( "reposPH" + pr.name, showRepos( pr ) );} {"Remove*"}
        submit action{return skippedFiles( r );}{"skipped files"}
      }
      if( r.error ) {
        div {"ERROR OCCURRED DURING REFRESH"}
      }
    }
  }

  define ajax showRequests() {
    for( r:Request order by r.project ) {
      showRequest( r )
    }
  }

  define showRequest( r : Request ) {
    var project := r.project;
    var repo : URL := r.svn;
    var isGithubTag := r.isGithubTag;
    var existing : List<Project>;
    var targetProject : Project;
    var reason : Text := "";
    div[class="top-container-green"] {"REQUEST"}
    div[class="main-container"] {
      "requester: " output( r.submitter )
      form{
        "Project name: "
        input( project )
        <br />"SVN: "
        input( repo )
        <br />"is Github tag?"
        input( isGithubTag )
        <br />"Reason in case of rejection: "
        <br />
        input( reason )
        <br />
        submit action{
          r.delete();
          replace( "requestsPH", showRequests() );
          sendRequestRejectedMail( r, reason );
        }{"reject(deletes request)"}
        submit action{
          existing := from Project where name = ~project;
          if( existing.length != 0 ) {
            targetProject := existing[0];
          } else {
            targetProject := Project{ name:=project };
          }
          targetProject.save();
          targetProject.repos.add( createNewRepo( repo, isGithubTag ) );

          sendRequestAcceptedMail( r );
          r.delete();
          return manage();
        }{"add to new/existing project"}
      }
    }
  }

  define page skippedFiles( r : Repo ) {
    init {
      return search( r.project.name , "BINFILE" );
    }
  }

  define ajax showLog() {
    init {updateLog();}
    table {
      row{ column{ <pre> rawoutput( manager.log ) </pre> } }
    }
  }

  define override logout() {
    "Logged in as: " output( securityContext.principal.name )
    form {
      submitlink signoffAction() {"Logout"}
    }
    action signoffAction() { logout(); return root(); }
  }