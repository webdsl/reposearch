application reposearch

  imports manage/manage-data
  imports manage/manage-ui
  imports search/search-configuration
  imports search/search-data
  imports search/search-ui
  imports search/search-misc
  imports entry/entry
  imports repository/repository
  imports request/request
  imports project/project
  imports ac
  imports language-construct/language-construct-data
  imports language-construct/language-construct-ui
  imports elib/lib

  init{
    Project{name:="WebDSL" repos:=[(SvnRepo{url:="https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/test/fail/ac"} as Repo)]}.save();
  }

  define mainResponsive(ns : String, title : String) {
    var project := if (ns == "") "All projects" else ns;
    var query := "";
    var projects := [p | p : Project in (from Project) order by p.displayName];
    var half  : Int := projects.length/2;
    includeCSS("bootstrap/css/bootstrap.css")
    includeCSS("bootstrap/css/bootstrap-responsive.css")
    includeCSS("bootstrap/css/bootstrap-adapt.css")
    includeCSS("bootstrap-extension.css")
    includeCSS("prettify.css")
    includeCSS("jquery-ui-1.9.1.custom.min.css")
    includeJS("jquery-1.8.2.min.js")
    includeJS("jquery-ui-1.9.1.custom.min.js")
    includeJS("bootstrap/js/bootstrap.min.js")
    includeJS("completion.js")
    includeJS("prettify.js")
    includeJS("make-clickable.js")

    includeHead("<meta name='viewport' content='width=device-width, initial-scale=1.0'>")

    title { output("Reposearch - " + title) }

    navbarResponsive{

          navItems{
            if (ns != "Projects") {
                navItem{ navigate(search(ns, "")){ iRefreshWhite() " New search"  } }
                navItem{ navigate(search(ns, ""))[target:="_blank"]{ iPlusWhite() " New tab"  } }
            }
            navItem{
                dropdownInNavbar(project){
                    dropdownMenu{
                        dropdownMenuItem{ navigate search("","") {"All projects"} }
                        dropdownMenuDivider
                        if(projects.length > 10){

                            dropdownSubMenu(projects.get(0).displayName + " - " + projects.get(half-1).displayName){
                              dropdownMenu{
                                for( index:Int from 0 to half){
                                    dropdownMenuItem{ navigate search(projects.get(index).name , "") {output(projects.get(index).displayName)} }
                                }
                              }
                            }
                            dropdownSubMenu(projects.get(half).displayName + " - " + projects.get(projects.length-1).displayName){
                              dropdownMenu{
                                for( index:Int from half to projects.length){
                                    dropdownMenuItem{ navigate search(projects.get(index).name , "") {output(projects.get(index).displayName)} }
                                }
                              }
                            }
                        } else {
                            for(p:Project order by p.displayName ){
                               dropdownMenuItem{ navigate search(p.name, "") {output(p.displayName)} }
                            }
                        }
                    }
                }
            }
            navItem{
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
    placeholder notificationsPH{}

    addProject()

    gridContainerFluid{
      elements
    }
    googleAnalytics()
  }

  define override appname(){ "Reposearch" }

  define page root(){
    title { "Reposearch" }
    mainResponsive("Projects", "home"){
          gridRowFluid{
            gridSpan(12){
                wellSmall{
                    <center>output(fpMsg.msg)</center>
                }
            }
          }
          gridRowFluid{
            gridSpan(10,1){
                <span class="home-text">"Search within project or " navigate(search("", "")){"all"} " projects:"</span>
                  for(p:Project order by p.displayName ){
                    gridRowFluid{
                      gridSpan(2){navigate(search(p.name, "")){output(p.displayName)}}
                      gridSpan(10){reposLink(p) }
                    }
                  }
            }
          }
    }
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
