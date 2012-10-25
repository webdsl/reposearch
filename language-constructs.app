module language-constructs

  entity LangConstruct {
    name    :: String (id, default="change me")
    pattern :: String
    group   :: Int
    fileExts:: String
    caseSensitive :: Bool
    nameNoSpaces  :: String := name.replace(" ", "_")
    projects      -> Set<Project> (inverse = Project.langConstructs)

    function addLangConstructConstraint(searcher : EntrySearcher) { addLangConstructConstraint(searcher, name); }
    function replaceLangConstructConstraint(searcher : EntrySearcher) : EntrySearcher { return replaceLangConstructConstraint(searcher, name); }
  }

  function addLangConstructConstraint(searcher : EntrySearcher, constructName: String) {
    var constraint := constructName.replace(" ", "_") + "#MATCH#" + searcher.getQuery();
    ~searcher matching constructs.matches: +constraint;
  }
  function replaceLangConstructConstraint(oldSearcher : EntrySearcher, constructName : String) : EntrySearcher{
      var newSearcher := toSearcher(oldSearcher.getQuery(), oldSearcher.getNamespace(), constructName);
      newSearcher.addFacetSelection(oldSearcher.getFacetSelection());
      return newSearcher;
  }
  // derive crud LangConstruct

  extend entity Project{
      langConstructs -> Set<LangConstruct>
  }

  entity ConstructMatch {
      entry         -> Entry
      langConstruct -> LangConstruct

      /*store names of matches which are extracted by
       the pattern's group, preceded by pattern's name
       and a seperator (#NEWITEM#), eg.: #NEWITEM#class#MATCH#SvnFetcher
      */
      matches :: Text := getMatches()
      function getMatches() : String{
          return MatchExtractor.extract(langConstruct, entry.content);
      }

      search mapping{
          matches using definedConstructMatchAnalyzer
      }
  }

  extend entity Entry{
      constructs <> Set<ConstructMatch> (inverse = ConstructMatch.entry)

      function addconstructs(){
          this.constructs.clear();
          var fileExt := /^.*\.([^\.]+)$/.replaceAll("$1", this.name);
          for( lc : LangConstruct in this.repo.project.langConstructs){
              if (lc.fileExts.contains(fileExt)){
                  this.constructs.add( ConstructMatch{ entry := this langConstruct := lc } );
              }
          }
      }
  }

  native class regex.MatchExtractor as MatchExtractor {
     static extract(LangConstruct, String) : String
     static decorateMatches(LangConstruct, String, String) : String
  }

  define manageLangConstructs( pr : Project ){
      "Language constructs management:"
      table{form{
        for( lc : LangConstruct in ( from LangConstruct order by name)){
            row{
                column {output( lc ) }
                column {" [" navigate(editLangConstruct( lc )){"edit"}  "] "
                if ( lc in pr.langConstructs ) {"[" submitlink("remove",removeLangConstruct(lc)) "]"}
                else                        {"[" submitlink("add",addLangConstruct(lc)) "]"}
                }
            }
        }
      }}
      action addLangConstruct(p : LangConstruct){ pr.langConstructs.add(p); langConsRenewSchedule.dirtyProjects.add(pr); replace("projectPH"+pr.name, showProject(pr)); }
      action removeLangConstruct(p : LangConstruct){ pr.langConstructs.remove(p); replace("projectPH"+pr.name, showProject(pr));}
      navigate( createLangConstruct()){"new language construct"}
  }


  define page createLangConstruct(){
      var p:= LangConstruct{ }
      editLangConstruct(p)
  }

  define page editLangConstruct(p : LangConstruct){
      editLangConstruct(p)
  }

  define editLangConstruct(lc : LangConstruct){
      form{
          group("Details") {
          derive editRows from lc for (name,fileExts,pattern,group,projects)
          }
          action("Cancel", cancel()) " " action("Save", save()) " " action("Remove permanently", remove())
      }
      action cancel(){ return manage(); }
      action save() {
        lc.save();
        langConsRenewSchedule.dirtyProjects.addAll(lc.projects);
        return manage();
      }
      action remove() {
          lc.projects.clear();
          for(cm in from ConstructMatch as c where (c.langConstruct = ~lc)){
              cm.langConstruct := null;
          }

          lc.delete();
          return manage();
      }
  }

  entity LangConstructRenewSchedule{
      dirtyProjects -> Set<Project> (default=Set<Project>())
      enabled :: Bool (default=true)

      function run(){
          if(enabled){
          for(pr : Project in dirtyProjects){
              Svn.log("Reindexing entries for project '" + pr.name + "' because of a change in assigned language constructs");
              for( repo : Repo in pr.repos){
                  for(e:Entry where e.repo == repo){
                      if(enabled){
                        e.addconstructs();
                      }
                  }
              }
            Svn.log("Done adding language construct matches to project '" +  pr.name + "'");
          }
        }//reschedule dirty projects if task is disabled
        if(enabled){
          dirtyProjects.clear();
        }
      }
  }