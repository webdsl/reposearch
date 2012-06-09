application reposearch

  imports manage
  imports search
  imports searchconfiguration
  imports ac

  var fpMsg := if( (from Message).length > 0) (from Message)[0]  else Message{msg := ""};
  var schedule := if( (from Schedule).length > 0) (from Schedule)[0] else Schedule{dayCounter := 0 nextInvocation := now().addDays(4)};

  entity Schedule{
    dayCounter      :: Int
    intervalInDays  :: Int (default=5)
    nextInvocation  :: DateTime
    lastInvocation  :: DateTime
    function newDay(){
      if (dayCounter >= intervalInDays) { dayCounter := 0; }
      else {dayCounter := dayCounter + 1;}
      nextInvocation := now().addDays( intervalInDays - dayCounter );
      if (dayCounter == 0){ refreshAllRepos(); }
    }
    function shiftByDays(days : Int){
        dayCounter := dayCounter - days;
        nextInvocation := nextInvocation.addDays( days );
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
          column{ navigate(search(p.name, "")){output(p.displayName)} } column{ placeholder "repos-"+p.displayName {showReposLink(p) }}
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
    var r : Request := Request{};

    "Add your project/repository!"
    form{
      table {
        row { column{"Project name: "}     column{input(p)} }
        row { column{"SVN: "}              column{input(n)}    }
        row { column{<span class="home-text">"or"</span>} column{}    }
        row { column{"Github user: "}      column{input(gu)} }
        row { column{"Github repository: "}column{input(gr)} }
      }
      submit action{replace("requestPH", req(""));} {"cancel"}
      submit action{
          //TODO FIXME: validate doesnt work atm:
            // exception occured while handling request URL: http://localhost:8080/reposearch/addProject
            // exception message: could not initialize proxy - no Session
            // org.hibernate.LazyInitializationException: could not initialize proxy - no Session
            // ...
          // validate(/[A-Za-z0-9]+[A-Za-z0-9\-_\.\s][A-Za-z0-9]+/.match(p), "Project name should be at least 3 characters (allowed chars: a-z,A-Z,0-9,-,_, ,.)");
          // validate( (n.length() > 0 || (gu.length() > 0 && gr.length() > 0) ), "Please specify an SVN repository url or Github user and repository");

          r.project:=p; r.svn:=n; r.gu:=gu; r.gr:=gr; r.save(); replace("requestPH", req("Your request is sent to the administrators. Please allow some time to process your request"));} {"add request"}
    }
    submitlink openPendingRequests(){nOfPendingRequests()}

    action openPendingRequests(){return pendingRequests();}
  }

  define page pendingRequests(){
      title { "Pending requests - Reposearch" }
      navigate(root()){"return to home"}
      for(r:Request order by r.project){
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
  }

  entity Project {
    name :: String (id)
    repos -> List<Repo>
    displayName :: String := name.substring(0,1).toUpperCase() + name.substring(1, name.length())
    validate(name.length() > 2, "length must be greater than 2")
  }
  entity Repo{
    project -> Project (inverse=Project.repos)
    refresh :: Bool
    refreshSVN :: Bool
    error::Bool
    skippedFiles :: Text
    rev :: Long
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
    static getFiles(String):RepoCheckout
    static getFilesIfNew(String,Long):RepoCheckout
    static checkoutSvn(String):RepoCheckout
    static checkoutGithub(String,String):RepoCheckout
  }

  native class svn.RepoCheckout as RepoCheckout{
      getRevision() : Long
      getEntries()  : List<Entry>
  }
