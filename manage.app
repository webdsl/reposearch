module manage

  invoke queryRepoTask()      every 30 seconds
  invoke invokeCheckReindex() every 60 seconds
  invoke schedule.newHour()   every 1 hours

  define page manage(){
    title { "Manage - Reposearch" }
    navigate(root()){"return to home"}

    manageRefresh()

    placeholder requestsPH{
      showRequests()
    }

    manageProjects()
    <br />
    manageFrontpageMessage()
    <br />
    logMessage()

  }

  define manageProjects(){
    var p := "";
    var fr := (from Repo where project is null);
    div[class="top-container"]{<b>"Manage Projects"</b>}
    div[class="main-container"]{
      form{
        input(p)
        submit action{Project{name:=p}.save();} {"Add new project"}
      }
      <br />
      for(pr:Project order by pr.displayName){
        div[class="top-container"]{"Project: " <b>output(pr.name)</b> " [" submitlink("remove project*", removeProject(pr)) "] *be patient, this may take over a minute"}
        div[class="main-container"]{
          searchCount(pr)
          placeholder "reposPH" + pr.name{
            showRepos(pr)
          }
          placeholder "addRepoPH" + pr.name{
            addRepoBtn(pr)
          }
        }
      }

      if(fr.length > 0){
        <br />
        submit action{
          for(r:Repo in fr){
            r.delete();
          }
          return manage();
        } {"Remove foreign Repo's (" output(fr.length) ")"} " (Repo entities where project == null)"
      }

    }
    action removeProject(pr : Project){
      for(r:Repo in pr.repos){
        deleteAllRepoEntries(r);
          r.delete();
      }
      pr.delete();
      settings.reindex := true;
      return manage();
    }
  }

  define searchCount(pr : Project){
      "# of searches since " output(pr.countSince) " for project " output(pr.displayName) ": " <b>output(pr.searchCount)</b> " " submitlink("reset", action{pr.resetSearchCount();})
  }

  define manageFrontpageMessage(){
    var fpMsgText := fpMsg.msg;
    div[class="top-container"]{<b>"Edit Frontpage Message"</b>}
    div[class="main-container"]{
      form{
        input(fpMsgText)[onkeyup := updateFpMsgPreview(fpMsgText)]
        <br />submit action{fpMsg.msg := fpMsgText; fpMsg.save();}{"save"}
      }
      placeholder fpMsgPreview {FpMsgPreview(fpMsgText)}
    }
    action ignore-validation updateFpMsgPreview(d : WikiText) {
        replace(fpMsgPreview, FpMsgPreview(d));
    }
  }

  define ajax FpMsgPreview(d : WikiText) {
    block{
      <center> output(d) </center>
    }
  }

  define logMessage(){
    div[class="top-container"]{<b>"SVN Log"</b>}
    div[class="main-container"]{
      placeholder log {showLog()}<br />
      submit action{replace(log, showLog());}{"refresh"}
    }
  }

  define manageRefresh(){
    placeholder refreshManagement{ refreshScheduleControl() } <br />
  }

  define ajax refreshScheduleControl(){
    var now := now();
    div[class="top-container"]{<b>"Manage Refresh Scheduling"</b>}
    div[class="main-container"]{
      table{
      row{ column{<i>"Refresh scheduling:" </i>}                  column{ submit action{resetSchedule();} {"reset"} } }
      row{ column{"Server time"}                                  column{ output(now) } }
      row{ column{"Last refresh (all repos)"}                     column{ if(schedule.lastInvocation != null) { output(schedule.lastInvocation) } else {"unkown"} } }
      row{ column{"Next scheduled refresh (all repos)"}           column{ output(schedule.nextInvocation) " " submit action{schedule.shiftByHours(-24); replace(refreshManagement, refreshScheduleControl());} {"-1d"} submit action{schedule.shiftByHours(-3); replace(refreshManagement, refreshScheduleControl());} {"-3h"} submit action{schedule.shiftByHours(3); replace(refreshManagement, refreshScheduleControl());} {"+3h"} submit action{schedule.shiftByHours(24); replace(refreshManagement, refreshScheduleControl());} {"+1d"} } }
      row{ column{"Auto refresh interval (hours)"}                column{ form{ input(schedule.intervalInHours)[style := "width:3em;"]  submit action{schedule.save(); replace(refreshManagement, refreshScheduleControl());}{"set"}  } } }
      row{ column{<i>"Instant refresh management:" </i>}          column{ }}
      row{ column{"Update all repos to HEAD: "}                   column{submit action{refreshAllRepos();         replace(refreshManagement, refreshScheduleControl());} {"refresh all"} } }
      row{ column{"Force a fresh checkout for all repos: "}       column{submit action{forceCheckoutAllRepos();   replace(refreshManagement, refreshScheduleControl());} {"force checkout all"} } }
      row{ column{"Cancel all scheduled refresh/checkouts: "}     column{submit action{cancelScheduledRefreshes();replace(refreshManagement, refreshScheduleControl());} {"cancel all"} } }
      }
    }
  }

  define ajax addRepoBtn(pr : Project){
      submit action{ replace("addRepoPH" + pr.name, addRepo(pr));} {"Add repository"}
  }

  define ajax showRepos(pr : Project){
    for(r:Repo in pr.repos){
      showrepo(pr,r)
    }
  }

  define ajax addRepo(pr : Project){
    var gu:String
    var gr:String
    var n :URL
    div[class="new-repo"]{
      form{
        "SVN: "
        input(n)
        submit action{ pr.repos.add(SvnRepo{url:=n}); replace("addRepoPH" + pr.name, addRepoBtn(pr)); replace("reposPH" + pr.name, showRepos(pr));} {"Add repository"}
      }
      form{
        "Github user: "
        input(gu)
        " repository: "
        input(gr)
        submit action{ pr.repos.add(GithubRepo{user:=gu repo:=gr}); replace("addRepoPH" + pr.name, addRepoBtn(pr)); replace("reposPH" + pr.name, showRepos(pr)); } {"Add repository"}
      }
    }
    div{
      submit action{ replace("addRepoPH" + pr.name, addRepoBtn(pr));} {"Cancel"}
    }
  }

  define showrepo(pr:Project, r:Repo){
    div[class="show-repo"]{
      output(r)
      div{
        if(r.refresh){
          if(r.refreshSVN){ "UPDATE TO HEAD SCHEDULED" } else { "CHECK OUT SCHEDULED" }
          submit action{cancelQueryRepo(r); replace("reposPH" + pr.name,showRepos(pr)); } {"Cancel"}
        }
        else{
          submit action{queryRepo(r); replace("reposPH" + pr.name,showRepos(pr));} {"Update if HEAD > r" output(r.rev)}
          submit action{queryCheckoutRepo(r); replace("reposPH" + pr.name,showRepos(pr));} {"Force checkout HEAD"}
        }
        submit action{pr.repos.remove(r);deleteAllRepoEntries(r); replace("reposPH" + pr.name, showRepos(pr));} {"Remove*"}
        submit action{return skippedFiles(r);}{"skipped files"}
      }
      if(r.error){
        div{"ERROR OCCURRED DURING REFRESH"}
      }
    }

  }

  define ajax showRequests(){
    for(r:Request order by r.project){
      showRequest(r)
    }
  }

  define showRequest(r : Request){
    var project := r.project;
    var repo : URL := r.svn;
    var gu:= r.gu;
    var gr:= r.gr;
    var existing : List<Project>;
    var targetProject : Project;

    div[class="top-container-green"]{"REQUEST"}
    div[class="main-container"]{
      form{
        "Project name: "
        input(project)
        <br />"SVN: "
        input(repo)
        <br />"Github user: "
        input(gu)
        <br />"Github repo: "
        input(gr)
        <br />
        submit action{r.delete();
            replace("requestsPH", showRequests());
        }{"reject (deletes request)"}
         submit action{ existing := from Project where name = ~project;
            if( existing.length != 0 ){
                targetProject := existing[0];
            } else {
                targetProject := Project{ name:=project };
            }
            targetProject.save();
            if(repo.length() != 0){
                targetProject.repos.add( SvnRepo{ url:=repo refresh:=true } );
            }
            if(gu.length() != 0  && gr.length() != 0){
                targetProject.repos.add( GithubRepo{ user:=gu repo:=gr refresh:=true } );
            }
            r.delete();
            return manage();
         }{"add to new/existing project"}
       }
     }
  }

  define page skippedFiles(r : Repo){
      init{
        return search( r.project.name , "BINFILE" );
      }
  }

  init{
    Project{name:="WebDSL" repos:=[(SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo)]}.save();
  }

  function cancelQueryRepo(r:Repo){
    r.refresh := false;
    r.refreshSVN := false;
  }

  function queryRepo(r:Repo){
    r.refresh := true;
    r.refreshSVN := true;
  }
  function queryCheckoutRepo(r:Repo){
    r.refresh := true;
    r.refreshSVN := false;
  }

  function refreshAllRepos(){
    schedule.lastInvocation := now();
    for(pr:Project){
      for(r:Repo in pr.repos){
         queryRepo(r);
       }
    }
  }
  function forceCheckoutAllRepos(){
    schedule.lastInvocation := now();
    for(pr:Project){
      for(r:Repo in pr.repos){
        queryCheckoutRepo(r);
      }
    }
  }
  function cancelScheduledRefreshes(){
    for(pr:Project){
      for(r:Repo in pr.repos){
        cancelQueryRepo(r);
      }
    }
  }

  function queryRepoTask(){
    var repos := from Repo where refresh=true and (inrefresh=null or inrefresh=false);
    var skippedFiles := List<String>();
    if(repos.length > 0){
      var r := repos[0];
      var col : RepoTaskResult;
      var oldRev : Long := if(r.rev == null) -1 else r.rev;
      var rev : Long;
      var performNextRefresh := false;
      r.inRefresh:=true;
      if(r.refreshSVN){
        if(r isa SvnRepo){ col := Svn.updateFromRevOrCheckout( (r as SvnRepo).url, oldRev ); }
        if(r isa GithubRepo){ col := Svn.updateFromRevOrCheckout( (r as GithubRepo).user,(r as GithubRepo).repo, oldRev ); }
      }
      else{ //forced checkout
        if(r isa SvnRepo){ col := Svn.checkout((r as SvnRepo).url); }
        if(r isa GithubRepo){ col := Svn.checkout((r as GithubRepo).user,(r as GithubRepo).repo); }
      }
      if(col == null){
          r.error := true;
      } else {
        //only replace entries when new ones are retrieved, i.e. col.getEntriesForAddition() is not null
        if (col.getEntriesForAddition() != null) {
          if(r.refreshSVN){
              deleteRepoEntries(r, col);
          } else {
            deleteAllRepoEntries(r);
          }
          for(c: Entry in col.getEntriesForAddition()){
              c.projectname := r.project.name;
              c.repo := r;
              c.save();
          }
          settings.addProject(r.project);
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
      if(performNextRefresh){ queryRepoTask(); }

    }
  }

  function updateLog(){
      if (schedule.log == null){ schedule.log := "";}
      schedule.log := schedule.log + Svn.getLog();
      if(schedule.log.length() > 10000){ schedule.log := schedule.log.substring(schedule.log.length()-10000);}
  }

  define ajax showLog(){
    init{updateLog();}
    table{
      row{ column{ <pre> rawoutput(schedule.log) </pre> } }
    }
  }


  //If settings.reindex is set to true and no refresh is going on, refresh suggestions/facet readers
  function invokeCheckReindex(){
    if(settings.reindex && (from Repo where refresh=true).length < 1){
      var namespaces := [p.name | p:Project in settings.projects];
      //directly set to false, in case repositories are updated during suggestion reindexing
      settings.reindex := false;
      IndexManager.indexSuggestions(namespaces);
      IndexManager.renewFacetIndexReaders();
    }
  }

  entity Message{
    msg :: WikiText
  }

  entity Settings{
    reindex :: Bool
    projects-> List<Project>
    function addProject(p : Project) {
      if(!reindex){ reindex := true; }
      if(projects.indexOf(p) < 0 ){ projects.add(p); }
    }
  }

  function deleteAllRepoEntries(r:Repo){
    for(e:Entry where e.repo == r){e.delete();}
  }

  function deleteRepoEntries(r:Repo, rtr : RepoTaskResult){
      var entries : List<Entry>;
      var projectName := r.project.name;
      for(url:String in rtr.getEntriesForRemoval()){
          entries := (from Entry as e where e.url=~url and e.repo = ~r);
          //when no hits are retrieved, we might be dealing with a directory, so try to delete all files within that directory using search
          if (entries.length < 1)  { entries := (search Entry in namespace projectName matching repoPath:url).results(); }
          for(e : Entry in entries){ log("Reposearch: Deleted Entry: " + e.url); e.delete();}
      }
  }