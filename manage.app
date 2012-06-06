module manage

  define page manage(){
    title { "Manage - Reposearch" }
    var p := ""
    var fr := (from Repo where project is null);

    navigate(root()){"return to home"}
    form{
      input(p)
      submit action{Project{name:=p}.save();} {"Add project"}
    }
    <br/>
    placeholder requestsPH{
      showRequests()
    }
    <br/>
    for(pr:Project order by pr.displayName){

      div[class="top-container"]{"Project: " <b>output(pr.name)</b> " [" submitlink("remove*", removeProject(pr))"]"}
      div[class="main-container"]{
        placeholder "reposPH" + pr.name{
          showRepos(pr)
        }
        placeholder "addRepoPH" + pr.name{
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

    <br />"*Removal may take some time. Please wait until the repository or project disappears."
    <br /><br />
    submit action{
      refreshAllRepos();
      return manage();
    } {"Refresh all repos where HEAD > indexed rev"}

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
          "REFRESH SCHEDULED"
          submit action{cancelQueryRepo(r);} {"Cancel refresh"}
        }
        else{
          submit action{queryRepo(r);} {"Force checkout HEAD"}
          if(r isa SvnRepo){
            submit action{queryRepoSVN(r);} {"Checkout if head > r" output(r.rev)}
          }
        }
        submit action{pr.repos.remove(r);deleteRepoEntries(r); replace("reposPH" + pr.name, showRepos(pr));} {"Remove*"}
        submit action{return skippedFiles(r);}{"skipped files"}
      }
      if(r.error){
        div{
          "ERROR OCCURRED DURING REFRESH"
        }
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
      title { "Skipped files - Reposearch" }
      "The following files are not indexed for repository [" output(r) "]:"
      par{
        rawoutput(r.skippedFiles)
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
  }

  function queryRepoSVN(r:Repo){
    r.refresh := true;
    r.refreshSVN := true;
  }

  invoke queryRepoTask() every 30 seconds

  invoke refreshAllRepos() every 5 days

  function refreshAllRepos(){
      for(pr:Project){
        for(r:Repo in pr.repos){
           if(r isa SvnRepo){
             queryRepoSVN(r);
           } else {
                queryRepo(r);
           }
        }
      }
  }

  function queryRepoTask(){
    var repos := from Repo where refresh=true;
    var skippedFiles := List<String>();
    if(repos.length > 0){
      var r := repos[0];
      var col : RepoCheckout;
      var oldRev : Long := if(r.rev == null) -1 else r.rev;
      var rev : Long;
      if(r.refreshSVN){
        col := Svn.getFilesIfNew( (r as SvnRepo).url, oldRev );
      }
      else{
        if(r isa SvnRepo){ col := Svn.checkoutSvn((r as SvnRepo).url); }
        if(r isa GithubRepo){ col := Svn.checkoutGithub((r as GithubRepo).user,(r as GithubRepo).repo); }
      }
      if(col != null){
        deleteRepoEntries(r);
        for(c: Entry in col.getEntries()){
          if(c.content == "BINFILE"){
              skippedFiles.add("<a href=\"" + c.url + "\">"+c.name+"</a>");
          } else {
              c.projectname := r.project.name;
              c.repo := r;
              c.save();
          }
        }
        r.rev := col.getRevision();
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
      IndexManager.renewFacetIndexReaders();
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