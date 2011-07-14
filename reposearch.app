application svnsearch

  imports search
  imports searchconfiguration

  define page root(){
    /*submit action{ 
      var col := Svn.getCommits("https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail"); 
      for(ce:Commit in col){
        ce.save();
      } 
    } 
    {"load"}*/
    /*
    submit action{ 
      var col := Svn.getFiles("https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"); 
      for(c: Entry in col){
        c.save();
      } 
    } 
    {"load"}
    submit action{ 
      for(ce:Commit){
        ce.delete(); 
      }  
    } 
    {"delete"}		
    
    for(c:Commit in from Commit as co order by co.rev desc){
      div{ output(c.rev) }	
      div{ rawoutput(rendertemplate(output(c.message)).replace("\n","<br>")) }	
      divsmall{ output(c.author) }	
      divsmall{ output(c.date) }	
    }
    for(c: Entry){
        div{ output(c.name) }	
        div{ rawoutput(rendertemplate(output(c.content)).replace("\n","<br>")) }
    } */
    /*
    init{
      return search("");
    }
    */
    for(p:Project){
      navigate(search(p, "")){"Search " output(p.name)}
      <br/>
    }
    navigate(manage()){"Manage"}
  }
  
  
  
    
  define divsmall(){
    <div style="font-size:10px;">
      elements()
    </div>
  }
  entity Commit{
    rev :: Long
    author :: String
    message :: Text
    date :: DateTime
  }
  entity Entry{
    name :: String
    content :: Text
    url :: URL
    projectname :: String
    repo ->Repo
       searchmapping{
        content (autocomplete)
        projectname using kw
      }
  }
  

  native class svn.Svn as Svn{
    //static getCommits(String):List<Commit>
    //static getFiles(String):List<Entry>
    static checkoutSvn(String):List<Entry>
    static checkoutGithub(String,String):List<Entry>
  }
    
  //todo:configurable filter on file extension
  //jar zip tbl png jpg bmp
  
  define page manage(){
    var p := ""
    var n :URL
    var gu:String
    var gr:String
    form{
      input(p)
      submit action{Project{name:=p}.save();} {"Add project"}
    }
    <br/>
    for(pr:Project){
      div{"Project: " output(pr.name) }
      div{
        "Repositories: "
        for(r:Repo in pr.repos){
          showrepo(pr,r)
        }
      }
      div{
        form{
          "SVN: "
          input(n)
          submit action{ pr.repos.add(SvnRepo{url:=n}); } {"Add repository"}
        }
        form{
          "Github user: "
          input(gu)
          " repository: "
          input(gr)
          submit action{ pr.repos.add(GithubRepo{user:=gu repo:=gr}); } {"Add repository"}
        }
      }
      <br/>
    }
  }
  
  define showrepo(p:Project, r:Repo){
    div{
      if(r isa SvnRepo){
        "SVN: " 
        output((r as SvnRepo).url)
      }
      if(r isa GithubRepo){
        "Github: " 
        output((r as GithubRepo).user) 
        " " 
        output((r as GithubRepo).repo)
      }
    }
    div{
      if(r.error){
        "ERROR OCCURRED DURING REFRESH"
      }
    }
    div{
      if(r.refresh){
        "REFRESH SCHEDULED"
      }
      else{
        submit action{queryRepo(r);} {"Refresh"}    	
      }
    }
    div{
      submit action{p.repos.remove(r);deleteRepoEntries(r);} {"Remove"}
    }
  }
  
  entity Project {
    name :: String (id)
    repos -> List<Repo>
  }
  entity Repo{
    project -> Project (inverse=Project.repos)
    refresh :: Bool
    error::Bool
  }
  entity SvnRepo : Repo{
    url :: URL  	
  }
  entity GithubRepo : Repo{
    user::String
    repo::String
  }
  init{
    Project{name:="WebDSL" repos:=[(SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo)]}.save();
  }
  
  
  
  function queryRepo(r:Repo){
    r.refresh := true;
  }
  
  invoke queryRepoTask() every 30 seconds
  
  function queryRepoTask(){
    var repos := from Repo where refresh=true;
    if(repos.length > 0){
      var r := repos[0];
      var col : List<Entry>;
      if(r isa SvnRepo){ col := Svn.checkoutSvn((r as SvnRepo).url); }
      if(r isa GithubRepo){ col := Svn.checkoutGithub((r as GithubRepo).user,(r as GithubRepo).repo); }
      if(col != null){ 
        deleteRepoEntries(r);
        for(c: Entry in col){
          c.projectname := r.project.name;
          c.repo := r;
          c.save();
        }
        r.error := false;
      } 
      else{
        r.error := true;	
      }
      r.refresh:=false;
      if(!settings.reindex){
        settings.reindex := true;
      }
    }
  }
  
  invoke invokeCheckReindex() every 60 seconds
  
  function invokeCheckReindex(){
    if(settings.reindex){
      IndexManager.indexSuggestions();
    }
    settings.reindex := false;
  }

  entity Settings{
    reindex :: Bool
  }
  var settings := Settings{} 
  
  function deleteRepoEntries(r:Repo){
    for(e:Entry where e.repo == r){e.delete();}
  }
  