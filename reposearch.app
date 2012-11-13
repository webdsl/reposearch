application reposearch

  imports manage
  imports search
  imports searchconfiguration
  imports ac
  imports language-constructs
  imports elib/lib

  var fpMsg := if( (from Message).length > 0) (from Message)[0]  else Message{msg := ""}
  var manager := if( (from RepoSearchManager).length > 0) (from RepoSearchManager)[0] else RepoSearchManager{hourCounter := 0 nextInvocation := now().addHours(12) log:="" adminEmails:=""}
  var settings := if( (from Settings).length > 0) (from Settings)[0] else Settings{reindex := false projects := List<Project>()}
  var langConsRenewSchedule := if( (from LangConstructRenewSchedule).length > 0) (from LangConstructRenewSchedule)[0] else LangConstructRenewSchedule{ dirtyProjects := Set<Project>() enabled:=true}

  function resetSchedule(){
    manager.hourCounter := 0;
    manager.intervalInHours := 12;
  }

  entity RepoSearchManager{
    hourCounter     :: Int (default=0)
    intervalInHours :: Int (default=12)
    nextInvocation  :: DateTime
    lastInvocation  :: DateTime
    newWeekMoment   :: Date(default=now())
    log             :: Text
    adminEmails     :: Text
    function newHour(){
      tryNewWeek();
      var execute := false;
      hourCounter := hourCounter + 1;
      if (hourCounter >= intervalInHours) { hourCounter := 0; execute := true; }
      nextInvocation := now().addHours( intervalInHours - hourCounter );
      if (execute){ refreshAllRepos(); }
    }
    function shiftByHours(hours : Int){
        hourCounter := hourCounter - hours;
        nextInvocation := nextInvocation.addHours( hours );
    }
    function tryNewWeek(){
        if(newWeekMoment.addDays(7).before(now())){
            newWeekMoment := newWeekMoment.addDays(7);
            for(p : Project){
              p.newWeek();
            }
        }
    }
  }

  define mainResponsive(ns : String) {
    var project := if (ns == "") "All projects" else ns;
    includeCSS("bootstrap/css/bootstrap.css")
    includeCSS("bootstrap/css/bootstrap-responsive.css")
    includeCSS("bootstrap/css/bootstrap-adapt.css")
    includeCSS("bootstrap-extension.css")
    includeJS("jquery.js")
    includeJS("bootstrap/js/bootstrap.js")
    includeHead("<meta name='viewport' content='width=device-width, initial-scale=1.0'>")
    //includeHead(rendertemplate(rssLink()))
    //includeHead(rendertemplate(bitterfont))
    //<link href="http://fonts.googleapis.com/css?family=Bitter" rel="stylesheet" type="text/css">
    navbarResponsive{
          navItems{
            dropdownInNavbar(project){
                dropdownMenu{
                    dropdownMenuItem{ navigate search("","") {"All projects"} }
                    for(p:Project order by p.displayName ){
                        dropdownMenuItem{ navigate search(p.name, "") {output(p.displayName)} }
                    }
                }
            }
            navItems{
                dropdownInNavbar("Add your project"){
                    dropdownMenu{
                        dropdownMenuItem{<a data-toggle="modal" href="#addProject">"New project request"</a>}
                        dropdownMenuItem{ navigate(pendingRequests()){ "Pending requests" } }
                    }
                }
            }
            navItem{ navigate(manage())         { "Manage"           } }
            navItem{ navigate(searchStats())    {"Search statistics" } }
            navItem{ navigate(dologin())        {"Admin log in/out"  } }

          }
    }
    placeholder notificationsPH

    addProject()

    elements
  }

  define override appname(){ "Reposearch" }

  define page root(){
    title { "Reposearch" }
    mainResponsive("Projects"){
        gridContainerFluid{
          gridRowFluid{
            gridSpan(12){
                wellSmall{
                    <center>output(fpMsg.msg)</center>
                }
            }
          }
          gridRowFluid{
            gridSpan(6,3){
                <span class="home-text">"Search within project or " navigate(search("", "")){"all"} " projects:"</span>
                <ul class="nav nav-list">
                  <li class="nav-header">"Projects"</li>
                  for(p:Project order by p.displayName ){
                    <li>gridSpan(4){navigate(search(p.name, "")){output(p.displayName)}}
                    gridSpan(8){reposLink(p) }</li>
                  }
                </ul>
            }
          }
        }
    }


    googleAnalytics()
  }

  define homeLink(){
    navigate(root()){"return to home"}
  }

  define divsmall(){
    <div style="font-size:10px;">
      elements()
    </div>
  }

  define reposLink(p: Project){
    placeholder "repos-"+p.displayName {showReposLink(p) }
  }

  define ajax showReposLink(p : Project){
    "  [" submitlink action{replace("repos-"+p.displayName, repos(p));}{"info"} "]"
  }

  define output(r : Repo){
      if(r isa SvnRepo){
          "SVN: "
          output((r as SvnRepo).url)
      } else { //Github repo
          "Github: "
          output((r as GithubRepo).user)
          " "
          output((r as GithubRepo).repo)
          " "
          output((r as GithubRepo).svnPath)
      }
      " at revision: " output(r.rev)
      " (last refresh: " output(r.lastRefresh) ")"
  }

  define ajax repos(p : Project){
      "  ["submitlink action{replace("repos-"+p.displayName, showReposLink(p));}{"hide"}" "
      if (p.repos.length > 1){ <br />}
      for(r : Repo in p.repos){
        output(r)
        " (" navigate(skippedFiles(r))[target:="_blank"]{"skipped files"} ")"
      }separated-by{<br />}
      if (p.repos.length > 1){ <br />}
      "]"
  }

  define nOfPendingRequests() {
      var cnt := select count(r) from Request as r;
      if(cnt < 1){ "no requests pending"}
      else       { output(cnt) " pending request(s)" }
  }

  define ajax addProject(){
    var p    := "";
    var gu   := "";
    var gr   := "";
    var path := "trunk";
    var tag  := false;
    var n : URL := "";
    var submitter : Email := "";
    var r : Request := Request{};
    <div id="addProject" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">


        horizontalForm("Add your project/repository!"){
          <div class="modal-body">
            controlGroup("Your email (hidden)") {  input(submitter) }
            controlGroup("Project name"){     input(p)}
            controlGroup("SVN or Github URL"){ input(n)}
            controlGroup("This URL is/resides within a github tag"){  input(tag){"this is a location within a tag on Github."} }
            controlGroup("Example links:"){ <i>"http://some.svn.url/repo/trunk"
                            <br />"https://github.com/hibernate/hibernate-search (master branch)"
                            <br />"https://github.com/hibernate/hibernate-search/tree/4.0 (4.0 branch)"
                            <br />"https://github.com/hibernate/hibernate-search/tree/4.0.0.Final (4.0.0.Final tag)"
                            <br />"https://github.com/mobl/mobl-lib/blob/v0.5.0/mobl/ui/generic/touchscroll.js (a file within v0.5.0 tag)"
                          </i>}

           validate(/[A-Za-z0-9][A-Za-z0-9\-_\.\s]{2,}/.match(p), "Project name should be at least 3 characters (allowed chars: a-z,A-Z,0-9,-,_, ,.)")
           validate( (n.length() > 6), "please fill in a SVN or Github repository" )
           validate(validateEmail(submitter), "please enter a valid email address")
         </div>
         <div class="modal-footer">
           submit action{  }[ignore-validation, class="btn"] {"close"}
           submit action{
             r.project:=p; r.svn:=n; r.submitter:=submitter; r.isGithubTag:=tag; r.save();
             newSuccessMessage("Your request is sent to the administrators. You will receive an email when your request is processed");
             emailRequest(r);
           }[ignore-validation,class="btn btn-primary"] {"add request"}
         </div>

        }
        submitlink openPendingRequests(){nOfPendingRequests()}
    </div>


    action openPendingRequests(){return pendingRequests();}
  }

  function newSuccessMessage(msg : String){
      append("notificationsPH", successMessage(msg));
  }

  define ignore-access-control ajax successMessage(msg : String){
      alertSuccess{ output(msg) }
  }

  function validateEmail(mail : String) : Bool {
    return /([a-zA-Z0-9_\-\.])+@(([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(([a-zA-Z0-9\-]+\.)+)([a-zA-Z]{2,4}))/.match(mail);
  }

  function emailRequest(r : Request){
    var emails : List<Text> := manager.adminEmails.split(",");
    for(e : Text in emails where validateEmail(e)){
      email adminRequestMail(e, "noreply@webdsl.org", r);
    }
  }

  function sendRequestAcceptedMail(r: Request){
      email submitterRequestMail(r, true, "");
  }

  function sendRequestRejectedMail(r: Request, reason : Text){
      email submitterRequestMail(r, false, reason);
  }

  define email submitterRequestMail(r:Request, added : Bool, reason : Text) {
    to(r.submitter)
    from("noreply@webdsl.org")
    if (added){ subject("Reposearch request accepted") } else { subject("Reposearch request rejected") }
    par { "Dear recipient," }
    par { "Your request to add the following repository to Reposearch has been "
      if(added){"accepted and should be available for search shortly."}
      else{ "rejected." <br/><br/> "Reason: " output(reason) }
    }
    <br />
    par { "Project: " output(r.project) }
    par { "SVN: " output(r.svn) }
    par { "Github tag?: " output(r.isGithubTag) }
    <br />
    par { navigate(root()){"Go to reposearch"} }
  }

  define email adminRequestMail(to:String,from:String, r : Request) {
    to(to)
    from(from)
    subject("New reposearch repository request")
    par { "A new request is added on reposearch" }
    par { "Requester: " output(r.submitter) }
    par { "Project: " output(r.project) }
    par { "SVN: " output(r.svn) }
    par { "Github tag?: " output(r.isGithubTag) }
    par { navigate(manage()){"Go to manage page"} }
  }

  define page pendingRequests(){
    var pendingRequests := from Request order by project;
    title { "Pending requests - Reposearch" }
    if (pendingRequests.length < 1){"There are no pending requests at this moment." <br />}
    homeLink()
    for(r : Request in pendingRequests){
      div[class="top-container-green"]{ output(r.project) " (project name)"}
      div[class="main-container"]{
          list{
            listitem{"SVN: '" output(r.svn) "'"}
            listitem{"is a Github tag: '" output(r.isGithubTag) "'"}
        }
      }
    }
    googleAnalytics()
  }

  session SearchPrefs{
      resultsPerPage :: Int  (default=10)
      caseSensitive  :: Bool (default=false)
      exactMatch     :: Bool (default=true)
      regex          :: Bool (default=false)
  }

  entity Request {
    project     :: String
    svn         :: URL
    isGithubTag :: Bool
    submitter   :: Email
  }

  entity Project {
    name                 :: String (id)
    repos                -> List<Repo>
    displayName          :: String   := if(name.length() > 0) name.substring(0,1).toUpperCase() + name.substring(1, name.length()) else name
    searchCount          :: Int      (default=0)
    weeklySearchCount    :: Int      := if(weekStartSearchCount != null) searchCount - weekStartSearchCount else 0
    weekStartSearchCount :: Int      (default=0)
    countSince           :: DateTime (default=now())

    validate(name.length() > 2, "length must be greater than 2")

    function resetSearchCount(){
        searchCount := 0;
        weekStartSearchCount := 0;
        countSince := now();
    }
    function incSearchCount(){
        searchCount := searchCount + 1;
    }
    function newWeek(){
        weekStartSearchCount := searchCount;
    }
  }

  entity Repo{
    project     -> Project  (inverse=Project.repos)
    refresh     :: Bool
    refreshSVN  :: Bool
    inRefresh   :: Bool     (default=false)
    error       :: Bool
    rev         :: Long
    lastRefresh :: DateTime (default=now().addYears(-20))
  }
  entity SvnRepo : Repo{
    url :: URL
  }
  entity GithubRepo : Repo{
    user    ::String (default="")
    repo    ::String (default="")
    svnPath ::String (default="")
  }
  entity Commit{
    rev     :: Long
    author  :: String
    message :: Text
    date    :: DateTime
  }

  entity Entry {
    name        :: String
    content     :: Text
    url         :: URL
    projectname :: String
    repo        -> Repo
  }
    search mapping Entry {
      + content using keep_all_chars      as content
      + content using keep_all_chars_cs   as contentCase ^ 50.0
      content   using code_identifiers_cs as codeIdentifiers (autocomplete)
      + name    using filename_analyzer   as fileName ^ 100.0 (autocomplete)
      name      using extension_analyzer  as fileExt
      url       using path_analyzer       as repoPath
      constructs with depth 1
      namespace by projectname
    }

  define override logout() {
      "Logged in as: " output(securityContext.principal.name)
      form{
        submitlink signoffAction() {"Logout"}
      }
      action signoffAction() { logout(); return root(); }
    }

  native class svn.Svn as Svn{
    static test()
    static checkout(String):RepoTaskResult
    static updateFromRevOrCheckout(String,Long):RepoTaskResult
    static checkout(String,String,String):RepoTaskResult
    static updateFromRevOrCheckout(String,String,String,Long):RepoTaskResult
    static log(String)
    static getLog() : String
  }

  native class svn.RepoTaskResult as RepoTaskResult{
      getRevision() : Long
      getEntriesForAddition()  : List<Entry>
      getEntriesForRemoval()   : List<String>
  }
