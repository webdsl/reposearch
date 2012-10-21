module patterns

  entity Pattern {
    name    :: String (id, default="change me")
    pattern :: String
    group   :: Int
    fileExts:: String
    caseSensitive :: Bool
    nameNoSpaces :: String := name.replace(" ", "_")
    projects-> Set<Project> (inverse = Project.patterns)

    function addPatternConstraint(searcher : EntrySearcher) { addPatternConstraint(searcher, name); }
  }

  function addPatternConstraint(searcher : EntrySearcher, patternName: String) {
    var constraint := patternName.replace(" ", "_") + "#MATCH#" + searcher.getQuery();
    ~searcher matching patternMatches.matches: +constraint;
  }
  // derive crud Pattern

  extend entity Project{
      patterns -> Set<Pattern>
  }

  entity PatternMatch {
      entry   -> Entry
      pattern -> Pattern

      /*store names of matches which are extracted by
       the pattern's group, preceded by pattern's name
       and a seperator (#NEWITEM#), eg.: #NEWITEM#class#MATCH#SvnFetcher
      */
      matches :: Text := getMatches()
      function getMatches() : String{
          return MatchExtractor.extract(pattern.nameNoSpaces, pattern.pattern, pattern.group, pattern.caseSensitive, entry.content);
      }

      search mapping{
          matches using definedPatternMatchAnalyzer
      }
  }

  extend entity Entry{
      patternMatches <> Set<PatternMatch> (inverse = PatternMatch.entry)

      function addPatternMatches(){
          this.patternMatches.clear();
          for( pattern : Pattern in this.repo.project.patterns){
              var ext := /^.*\.([^\.]+)$/.replaceAll("$1", this.name);
              if (pattern.fileExts.contains(ext)){
                  this.patternMatches.add( PatternMatch{ entry := this pattern := pattern } );
              }
          }
      }
  }

  native class regex.MatchExtractor as MatchExtractor {
     static extract(String, String, Int, Bool, String) : String
     static decorateMatches(Pattern, String, String) : String
  }

  define managePatterns( pr : Project ){
      "Available match patterns:"
      list{form{
        for( pattern : Pattern in from Pattern){
            listitem{
                output( pattern ) " [" navigate(editPattern( pattern )){"edit"}  "] "
                if (pattern in pr.patterns) {"[" submitlink("remove",removePattern(pattern)) "]"}
                else                        {"[" submitlink("add",addPattern(pattern)) "]"}
            }
        }
      }}
      action addPattern(p : Pattern){ pr.patterns.add(p); patternRenewSchedule.projects.add(pr); replace("projectPH"+pr.name, showProject(pr)); }
      action removePattern(p : Pattern){ pr.patterns.remove(p); replace("projectPH"+pr.name, showProject(pr));}
      navigate( createPattern()){"new pattern"}
  }


  define page createPattern(){
      var p:= Pattern{ }
      editPattern(p)
  }

  define page editPattern(p : Pattern){
      editPattern(p)
  }

  define editPattern(p : Pattern){
      form{
          group("Details") {
          derive editRows from p for (name,fileExts,pattern,group,projects)
          }
          action("Cancel", cancel()) " " action("Save", save()) " " action("Remove permanently", remove())
      }
      action cancel(){ return manage(); }
      action save() {
        p.save();
        patternRenewSchedule.projects.addAll(p.projects);
        return manage();
      }
      action remove() {
          p.projects.clear();
          p.delete();
          return manage();
      }
  }

  entity PatternRenewSchedule{
      projects -> List<Project>

      function run(){
          for(pr : Project in projects){
              Svn.log("Reindexing entries for project '" + pr.name + "' because of a change in assigned patterns");
              for( repo : Repo in pr.repos){
                  for(e:Entry where e.repo == repo){
                      e.addPatternMatches();
                  }
              }
          }
          projects.clear();
      }
  }