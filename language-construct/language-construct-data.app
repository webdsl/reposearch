module language-construct/language-construct-data

section entities
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

section functions

  function addLangConstructConstraint(searcher : EntrySearcher, constructName: String) {
    var constraint := constructName.replace(" ", "_") + "#MATCH#" + searcher.getQuery();
    ~searcher matching constructs.matches: +constraint;
  }
  function replaceLangConstructConstraint(oldSearcher : EntrySearcher, constructName : String) : EntrySearcher{
      var newSearcher := toSearcher(oldSearcher.getQuery(), oldSearcher.getNamespace(), constructName);
      newSearcher.addFacetSelection(oldSearcher.getFacetSelection());
      return newSearcher;
  }

  native class regex.MatchExtractor as MatchExtractor {
     static extract(LangConstruct, String) : String
     static decorateMatches(LangConstruct, String, String) : String
  }