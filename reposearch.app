application reposearch

  imports manage
  imports search
  imports searchconfiguration
  imports ac

  var fpMsg := if( (from Message).length > 0) (from Message)[0]  else Message{msg := ""};
  var manager := if( (from RepoSearchManager).length > 0) (from RepoSearchManager)[0] else RepoSearchManager{hourCounter := 0 nextInvocation := now().addHours(12) log:="" adminEmails:=""};
  var settings := if( (from Settings).length > 0) (from Settings)[0] else Settings{reindex := false projects := List<Project>()}

  function resetSchedule(){
    manager.hourCounter := 0;
    manager.intervalInHours := 12;
  }

  entity RepoSearchManager{
    hourCounter     :: Int (default=0)
    intervalInHours :: Int (default=12)
    nextInvocation  :: DateTime
    lastInvocation  :: DateTime
    log             :: Text
    adminEmails     :: Text
    function newHour(){
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
  }

  define page root(){
    title { "Reposearch" }
    <center>output(fpMsg.msg)</center>
    <span class="home-text">"Search within project or " navigate(search("", "")){"all"} " projects:"</span>
      <br/> <br/>
    table{
      for(p:Project order by p.displayName ){
        row{
          column{ navigate(search(p.name, "")){output(p.displayName)} } column{ reposLink(p) }
        }
      }
    }
    <br/><br/>
    placeholder requestPH{ req("") }
    <br/>navigate(manage()){"Manage"}
    <br/>navigate(searchStats()){"Search statistics"}<br/><br/>
    navigate(dologin()){<span class="login">"Admin log in/out"</span>}
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

  define ajax req(msg : String){
    <span class="home-text">output(msg)</span><br />
    submit action{replace(requestPH, addProject());}{"Add your project/repository?"} <br />
    submitlink action{return pendingRequests();}{nOfPendingRequests()}
  }

  define nOfPendingRequests() {
      var cnt := select count(r) from Request as r;
      if(cnt < 1){ "no requests pending"}
      else       { output(cnt) " pending request(s)" }
  }

  define ajax addProject(){
    var p := "";
    var gu := "";
    var gr := "";
    var n : URL := "";
    var submitter : Email := "";
    var r : Request := Request{};

    "Add your project/repository!"
    form{
      table {
        row { column{"Your email: "}       column{input(submitter)} }
        row { column{"Project name: "}     column{input(p)} }
        row { column{"SVN: "}              column{input(n)}    }
        row { column{<span class="home-text">"or"</span>} column{}    }
        row { column{"Github user: "}      column{input(gu)} }
        row { column{"Github repository: "}column{input(gr)} }
      }
       validate(/[A-Za-z0-9]+[A-Za-z0-9\-_\.\s][A-Za-z0-9]+/.match(p), "Project name should be at least 3 characters (allowed chars: a-z,A-Z,0-9,-,_, ,.)")
       validate( (n.length() > 6 || (gu.length()>1 && gr.length()>1) ), "please fill in a SVN or Github repository" )
       validate(validateEmail(submitter), "please enter a valid email address")
       submit action{replace("requestPH", req(""));} {"cancel"}
       submit action{
       r.project:=p; r.svn:=n; r.gu:=gu; r.gr:=gr; r.submitter:=submitter; r.save(); replace("requestPH", req("Your request is sent to the administrators. You will receive an email when your request is processed")); emailRequest(r);} {"add request"}

    }
    submitlink openPendingRequests(){nOfPendingRequests()}

    action openPendingRequests(){return pendingRequests();}
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
    par { "Github: " output(r.gu) " - " output(r.gr) }
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
    par { "Github: " output(r.gu) " - " output(r.gr) }
    par { navigate(manage()){"Go to manage page"} }
  }

  define page pendingRequests(){
    var pendingRequests := from Request order by project;
    title { "Pending requests - Reposearch" }
    if (pendingRequests.length < 1){"There are no pending requests at this moment." <br />}
    navigate(root()){"return to home"}
    for(r : Request in pendingRequests){
      div[class="top-container-green"]{ output(r.project) " (project name)"}
      div[class="main-container"]{
          list{
            listitem{"SVN: '" output(r.svn) "'"}
            listitem{"Github user: '" output(r.gu) "'"}
            listitem{"Github repo: '" output(r.gr) "'"}
        }
      }
    }
  }

  session SearchPrefs{
      resultsPerPage :: Int  (default=10)
      caseSensitive  :: Bool (default=false)
      exactMatch     :: Bool (default=true)
  }

  entity Request {
      project :: String
      svn :: URL
      gu  :: String
      gr  :: String
      submitter :: Email
  }

  entity Project {
    name        :: String (id)
    repos       -> List<Repo>
    displayName :: String := if(name.length() > 0) name.substring(0,1).toUpperCase() + name.substring(1, name.length()) else name
    searchCount :: Int
    countSince  :: DateTime
    validate(name.length() > 2, "length must be greater than 2")

    function resetSearchCount(){
        searchCount := 0;
        countSince := now();
    }
    function incSearchCount(){
        searchCount := searchCount + 1;
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
    user::String
    repo::String
  }
  entity Commit{
    rev :: Long
    author :: String
    message :: Text
    date :: DateTime
  }

  entity Entry {
    name :: String
    content :: Text
    url :: URL
    projectname :: String
    repo -> Repo
  }
    search mapping Entry {
      + content using keep_all_chars      as content
      + content using keep_all_chars_cs   as contentCase ^ 10.0
      content   using code_identifiers_cs as codeIdentifiers (autocomplete)
      + name    using filename_analyzer   as fileName ^ 20.0 (autocomplete)
      name      using extension_analyzer  as fileExt
      url       using path_analyzer       as repoPath
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
    //static getCommits(String):List<Commit>
    static test()
    static checkout(String):RepoTaskResult
    static updateFromRevOrCheckout(String,Long):RepoTaskResult
    static checkout(String,String):RepoTaskResult
    static updateFromRevOrCheckout(String,String,Long):RepoTaskResult
    static getLog() : String
  }

  native class svn.RepoTaskResult as RepoTaskResult{
      getRevision() : Long
      getEntriesForAddition()  : List<Entry>
      getEntriesForRemoval()   : List<String>
  }
