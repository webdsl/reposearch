module manage

  invoke queryRepoTask()      every 30 seconds
  invoke invokeCheckReindex() every 60 seconds
  invoke manager.newHour()   every 1 hours

section entities
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

section pages/templates
  define page manage(){
    title { "Manage - Reposearch" }
    homeLink()

    manageRefresh()

    manageRequestReceipts()

    placeholder requestsPH{
      showRequests()
    }

    manageProjects()
    <br />
    manageFrontpageMessage()
    <br />
    logMessage()

  }

  page searchStats(){
    title { output("Reposearch Search Statistics") }

    var startDate := if(manager.newWeekMoment!=null) manager.newWeekMoment else now();
    var projectsInOrder := from Project order by searchCount desc;

    homeLink()
    showSearchStats()
    submit action{SearchStatistics.clear();}{"Reset global statistics"}

    header{"Search counts per project"}
    table{
      row{ column{ <i>"Project name"</i> } column{ <i>"total"</i> } column{ <i>"this week"</i> } column{ <center><i>"since"</i></center> } column{ <i>"reset"</i> }}
      for(pr : Project in projectsInOrder order by pr.weeklySearchCount desc){
        searchCountInTable(pr)
      }
    }
    form{
      "Change the day at which the week counters reset (date of last reset): " input(startDate)
      submit action{manager.newWeekMoment := startDate;}{"set"}
    } <br />
    submit action{for(pr : Project){ pr.resetSearchCount(); }}{"Reset search statistics for all projects"}

  }

  define manageRequestReceipts(){
      var addresses : String := manager.adminEmails;
      form{
          input(addresses){" will receive a notification upon a request."}
          validate(validateEmailList(addresses) ,"Email addresses need to be seperated by a comma, without whitespace e.g. 'foo@bar.com,bar@foo.com'")
          submit action{manager.adminEmails := addresses;}{"apply"}
      }
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
        div[class="top-container"]{"Project: " <b>output(pr.name)</b> " [" submitlink("remove project*", removeProject(pr)) "] *this may take over a minute"}
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
      settings.projects.remove(pr);
      pr.delete();
      settings.reindex := true;
      return manage();
    }
  }

  define searchCount(pr : Project){
      "# of searches total / this week for project " output(pr.displayName) ": " <b>output(pr.searchCount)</b>  " (since " output(pr.countSince) ") / " <b>output(pr.weeklySearchCount)</b> " (since " output(manager.newWeekMoment) ") " submitlink("reset", action{pr.resetSearchCount();})
  }

  define searchCountInTable(pr : Project){
      row{
        column{output(pr.displayName)}
        column{<center><b>output(pr.searchCount)</b></center>}
        column{<center><b>output(pr.weeklySearchCount)</b></center>}
        column{output(pr.countSince)}
        column{submitlink("reset", action{pr.resetSearchCount();})}
      }
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
      "Auto-refreshes every 5 seconds" <br />
      submit action{replace(log, showLog());}[id = "autoRefresh", ajax]{"force refresh log"}
      <script>
        var refreshtimer;
        function setrefreshtimer(){
          clearTimeout(refreshtimer);
          refreshtimer = setTimeout(function() {
            $("#autoRefresh").click();
            setrefreshtimer();
          },5000);
        }
        setrefreshtimer();
      </script>
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
      row{ column{"Last refresh (all repos)"}                     column{ if(manager.lastInvocation != null) { output(manager.lastInvocation) } else {"unkown"} } }
      row{ column{"Next scheduled refresh (all repos)"}           column{ output(manager.nextInvocation) " " submit action{manager.shiftByHours(-24); replace(refreshManagement, refreshScheduleControl());} {"-1d"} submit action{manager.shiftByHours(-3); replace(refreshManagement, refreshScheduleControl());} {"-3h"} submit action{manager.shiftByHours(3); replace(refreshManagement, refreshScheduleControl());} {"+3h"} submit action{manager.shiftByHours(24); replace(refreshManagement, refreshScheduleControl());} {"+1d"} } }
      row{ column{"Auto refresh interval (hours)"}                column{ form{ input(manager.intervalInHours)[style := "width:3em;"]  submit action{manager.save(); replace(refreshManagement, refreshScheduleControl());}{"set"}  } } }
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
    var isTag:=false;
    var n :URL
    div[class="new-repo"]{
      form{
        "SVN or github URL: "
        input(n)
        <br />"resides within github tag?: "
        input(isTag)
        submit action{ pr.repos.add(createNewRepo(n, isTag)); replace("addRepoPH" + pr.name, addRepoBtn(pr)); replace("reposPH" + pr.name, showRepos(pr));} {"Add repository"}
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
    var isGithubTag := r.isGithubTag;
    var existing : List<Project>;
    var targetProject : Project;
    var reason : Text := "";

    div[class="top-container-green"]{"REQUEST"}
    div[class="main-container"]{
      "requester: " output(r.submitter)
      form{
        "Project name: "
        input(project)
        <br />"SVN: "
        input(repo)
        <br />"is Github tag?"
        input(isGithubTag)
        <br />"Reason in case of rejection: "
        <br />
        input(reason)
        <br />
        submit action{r.delete();
            replace("requestsPH", showRequests());
            sendRequestRejectedMail(r, reason);
        }{"reject (deletes request)"}
         submit action{ existing := from Project where name = ~project;
            if( existing.length != 0 ){
                targetProject := existing[0];
            } else {
                targetProject := Project{ name:=project };
            }
            targetProject.save();
            targetProject.repos.add( createNewRepo(repo, isGithubTag) );

            sendRequestAcceptedMail(r);
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

  define ajax showLog(){
    init{updateLog();}
    table{
      row{ column{ <pre> rawoutput(manager.log) </pre> } }
    }
  }

section functions

  init{
    Project{name:="WebDSL" repos:=[(SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo)]}.save();
  }

  function validateEmailList(listStr : String) : Bool {
      for(address : String in listStr.split(",")){
          if(!validateEmail(address)){ return false; }
      }
      return true;
  }

  function createNewRepo(url:String,isGithubTag:Bool) : Repo{
    if(url.toLowerCase().contains("github.com")){
        //https://github.com/mobl/mobl/tree/master/editor/java/mobl/strategies
        var params := /.*github\.com/([^/]+)/([^/]+)/?(.*)/.replaceAll("$1,$2,$3", url).split(",");
        var u := params[0];
        var r := params[1];
        var p := "trunk";
        var prefixPath := "";
        log("params[2]:" + params[2]);
        if(/(^$)|((tree|blob)/master.*)/.match(params[2])) {
          prefixPath := "trunk";
        } else {
          prefixPath := if (isGithubTag) "tags" else "branch";
        }
        if(params[2].length() > 1) {
          p := /^(tree|blob)(/master)?/.replaceFirst(prefixPath, params[2]);
        }
        return GithubRepo{ user:=u.trim() repo:=r.trim() svnPath:=p.trim() refresh:=true};
    }
    else{
        return SvnRepo{ url:=url.trim() refresh:=true };
    }
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
    manager.lastInvocation := now();
    for(pr:Project){
      for(r:Repo in pr.repos){
         queryRepo(r);
       }
    }
  }
  function forceCheckoutAllRepos(){
    manager.lastInvocation := now();
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
        if(r isa GithubRepo){ col := Svn.updateFromRevOrCheckout( (r as GithubRepo).user,(r as GithubRepo).repo, (r as GithubRepo).svnPath, oldRev ); }
      }
      else{ //forced checkout
        if(r isa SvnRepo){ col := Svn.checkout((r as SvnRepo).url); }
        if(r isa GithubRepo){ col := Svn.checkout((r as GithubRepo).user,(r as GithubRepo).repo, (r as GithubRepo).svnPath); }
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
      var toAdd := Svn.getLog();
      if (manager.log == null){ manager.log := "";}
      if (toAdd.length() > 0) {
          manager.log := manager.log + toAdd;
          if(manager.log.length() > 20000){ manager.log := manager.log.substring(manager.log.length()-20000);}
      }
  }

  //If settings.reindex is set to true and no refresh is going on, refresh suggestions/facet readers
  function invokeCheckReindex(){
    if(settings.reindex && (from Repo where refresh=true).length < 1){
      var namespaces := [p.name | p:Project in settings.projects];
      //directly set to false, in case repositories are updated during suggestion reindexing
      settings.reindex := false;
      settings.projects := List<Project>();
      IndexManager.indexSuggestions(namespaces);
      IndexManager.renewFacetIndexReaders();
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