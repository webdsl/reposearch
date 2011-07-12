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
      navigate(search(p)){"Search " output(p.name)}
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
    content :: Text(searchable)
    url :: URL
    projectname :: String(searchable)
    repo ->Repo
       searchmapping{
        content    		
        projectname
      }
  }
  

  native class svn.Svn as Svn{
    static getCommits(String):List<Commit>
    static getFiles(String):List<Entry>
  }
    
  //todo:configurable filter on file extension
  //jar zip tbl png jpg bmp
  
  define page manage(){
    var p := ""
    var n :URL
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
          input(n)
          submit action{ pr.repos.add(Repo{url:=n}); } {"Add repository"}
        }
      }
      <br/>
    }
  }
  
  define showrepo(p:Project, r:Repo){
    div{
      output(r.url)
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
    name :: String
    repos -> List<Repo>
  }
  entity Repo{
    project -> Project (inverse=Project.repos)
    url :: URL
    refresh :: Bool
    error::Bool
  }
  init{
    Project{name:="WebDSL" repos:=[Repo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"}]}.save();
  }
  
  
  
  function queryRepo(r:Repo){
    r.refresh := true;
  }
  
  invoke queryRepoTask() every 30 seconds
  
  function queryRepoTask(){
    var repos := from Repo where refresh=true;
    if(repos.length > 0){
      var r := repos[0];
      var col := Svn.getFiles(r.url);
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
      
    }
  }
  
  function deleteRepoEntries(r:Repo){
    for(e:Entry where e.repo == r){e.delete();}
  }
  