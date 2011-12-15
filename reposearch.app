application reposearch

  imports search
  imports searchconfiguration
  imports ac

  define page root(){
    
    navigate(search("", "")){"Search all projects"}
      <br/> <br/>
    for(p:Project order by p.name){
      navigate(search(p.name, "")){"Search " output(p.name)}
      <br/>
    }
    <br/>navigate(manage()){"Manage"}<br/><br/>
    navigate(dologin()){"log in/out"}
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
    repo -> Repo
    searchmapping{
      + content
      + content as contentcase using code_analyzer_casesensitive * 4.0 (autocomplete)
      + name using filename_analyzer
      name using kw as filename_autocomplete (autocomplete)
      name using extension_analyzer as file_ext
      namespace by projectname      
    }
  }
  

  native class svn.Svn as Svn{
    //static getCommits(String):List<Commit>
    static getFiles(String):List<Entry>
    static checkoutSvn(String):List<Entry>
    static checkoutGithub(String,String):List<Entry>
  }
    
  //todo:configurable filter on file extension
  //jar zip tbl png jpg bmp
  
  define page manage(){
    var p := ""


        
    navigate(root()){"return to home"}
    form{
      input(p)
      submit action{Project{name:=p}.save();} {"Add project"}
    }
    <br/>
    for(pr:Project){
      
      div[class="top-container"]{"Project: " <b>output(pr.name)</b> " [" submitlink("remove", removeProject(pr))"]"}
      div[class="main-container"]{
      	  placeholder reposPH{
	        showRepos(pr)
          }     
	      placeholder addRepoPH{
	      	addRepoBtn(pr)
	      }
	  }
    }
        
    action removeProject(pr : Project){
    	for(r:Repo in pr.repos){
    		deleteRepoEntries(r);
    		r.delete();
    	}
      pr.delete();
      settings.reindex := true;
      return manage();
    }
    
    <br /><br /><br />
    submit action{ 
    	for(pr:Project){
    		for(r:Repo in pr.repos){
    			queryRepo(r);
    		}
    	}
    	return manage();
    	 } {"REFRESH ALL REPOSITORIES (with checkout)"}
  }
  
  define ajax addRepoBtn(pr : Project){
  	submit action{ replace(addRepoPH, addRepo(pr));} {"Add repository"}
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
	          submit action{ pr.repos.add(SvnRepo{url:=n}); replace(addRepoPH, addRepoBtn(pr)); replace(reposPH, showRepos(pr));} {"Add repository"}
	        }
	        form{
	          "Github user: "
	          input(gu)
	          " repository: "
	          input(gr)
	          submit action{ pr.repos.add(GithubRepo{user:=gu repo:=gr}); replace(addRepoPH, addRepoBtn(pr)); replace(reposPH, showRepos(pr)); } {"Add repository"}
	        }
	}
	div{
		submit action{ replace(addRepoPH, addRepoBtn(pr));} {"Cancel"}
	}
  }
  
  define showrepo(p:Project, r:Repo){
    div[class="show-repo"]{
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
      div{
	      if(r.refresh){
	        "REFRESH SCHEDULED"
	        submit action{cancelQueryRepo(r);} {"Cancel refresh"}  
	      }
	      else{
	        submit action{queryRepo(r);} {"Refresh (checkout)"}  
	        if(r isa SvnRepo){  	
	          submit action{queryRepoSVN(r);} {"Refresh (no checkout)"}  
	        }	
	      }
	      submit action{p.repos.remove(r);deleteRepoEntries(r); replace(reposPH, showRepos(p));} {"Remove"}
	      submit action{return skippedFiles(r);}{"skipped files"}
      }
      if(r.error){
      	div{
      	  "ERROR OCCURRED DURING REFRESH"
      	}
      }
    }
    
  }
  
  define page skippedFiles(r : Repo){
  	rawoutput(r.skippedFiles)
  }
  
  entity Project {
    name :: String (id)
    repos -> List<Repo>
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
  init{
    Project{name:="WebDSL" repos:=[(SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo)]}.save();
  }
  
  function cancelQueryRepo(r:Repo){
    r.refresh := false;
    r.refreshSVN := false;
  }
  
  function queryRepo(r:Repo){
    r.refresh := true;
  }
  
  function queryRepoSVN(r:Repo){
    r.refresh := true;
    r.refreshSVN := true;
  }
  
  invoke queryRepoTask() every 30 seconds
  
  function queryRepoTask(){
    var repos := from Repo where refresh=true;
    var skippedFiles := List<String>();
    if(repos.length > 0){
      var r := repos[0];
      var col : List<Entry>;
      if(r.refreshSVN){
        col := Svn.getFiles((r as SvnRepo).url);
      }
      else{
        if(r isa SvnRepo){ col := Svn.checkoutSvn((r as SvnRepo).url); }
        if(r isa GithubRepo){ col := Svn.checkoutGithub((r as GithubRepo).user,(r as GithubRepo).repo); }
      }
      if(col != null){ 
        deleteRepoEntries(r);
        for(c: Entry in col){
          if(c.content == "BINFILE"){
          	skippedFiles.add("<a href=\"" + c.url + "\">"+c.name+"</a>");
          } else {
	          c.projectname := r.project.name;
	          c.repo := r;
	          c.save();
          }
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
      r.skippedFiles := skippedFiles.concat("<br />");
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
  