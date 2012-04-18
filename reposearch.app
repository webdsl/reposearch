application reposearch

  imports manage
  imports search
  imports searchconfiguration
  imports ac

  define page root(){
      title { "Reposearch" }
    <span class="home-text">"Search within project or " navigate(search("", "")){"all"} " projects:"</span>
      <br/> <br/>
    for(p:Project order by p.displayName ){
      navigate(search(p.name, "")){output(p.displayName)}
      <br/>
    }
    <br/><br/><br/>
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

  session SearchSettings{
      resultsPerPage :: Int  (default=10)
      caseSensitive  :: Bool (default=false)
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
    searchmapping Entry {
      + content using keep_all_chars      as content
      + content using keep_all_chars_cs   as contentCase * 10.0
      content   using code_identifiers_cs as codeIdentifiers (autocomplete)
      + name    using filename_analyzer   as fileName (autocomplete)
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
    static getFiles(String):List<Entry>
    static checkoutSvn(String):List<Entry>
    static checkoutGithub(String,String):List<Entry>
  }
