module repository/repository

section entities

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

section pages/templates

  define reposLink(p: Project){
    placeholder "repos-"+p.displayName {showReposLink(p) }
  }

  define ajax showReposLink(p : Project){
    buttonSmall{ submitlink action{replace("repos-"+p.displayName, repos(p));}{"info"} }
  }

  define output(r : Repo){
    wellSmall{
      gridRowFluid(){
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
      } gridRowFluid {
      "Rev: " output(r.rev)
      } gridRowFluid {
      "Last refresh: " output(r.lastRefresh)
      } gridRowFluid {
        navigate(skippedFiles(r))[target:="_blank"]{"Files marked as binary (not indexed)"}
      }
    }
  }

  define ajax repos(p : Project){
    wellSmall{
      gridRowFluid(){
        buttonSmall{ submitlink action{replace("repos-"+p.displayName, showReposLink(p));}{"hide"} }
      }
      for(r : Repo in p.repos){
        gridRowFluid {
          output(r)
        }
      }
    }
  }
