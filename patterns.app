module patterns

  entity Pattern {
    name    :: String (id, default="change me")
    pattern :: String
    group   :: Int
    caseSensitive :: Bool
    projects-> Set<Project> (inverse = Project.patterns)

    search mapping{
        name using none
    }

    function queryString(term : String) : String { return queryString(name, term); }
  }

  function queryString(patternName: String, term : String) : String { return patternName+"#MATCH#"+term; }
  // derive crud Pattern

  extend entity Project{
      patterns -> Set<Pattern>
  }

  entity PatternMatch {
      entry   -> Entry
      pattern -> Pattern

      /*store names of matches which are extracted by
       the pattern's group, preceded by pattern's name
       and seperators, eg.: #NEWITEM#class#MATCH#SvnFetcher
      */
      matches :: Text := getMatches()
      function getMatches() : String{
          return MatchExtractor.extract(pattern.name, pattern.pattern, pattern.group, pattern.caseSensitive, entry.content);
      }

      search mapping{
          matches using definedPatternMatchAnalyzer
      }
  }

  extend entity Entry{
      patternMatches <> Set<PatternMatch> (inverse = PatternMatch.entry)

      function addPatternMatches(){
            for( pattern : Pattern in this.repo.project.patterns){
                this.patternMatches.add( PatternMatch{ entry := this pattern := pattern } );
            }
      }
  }

  native class regex.MatchExtractor as MatchExtractor {
     static extract(String, String, Int, Bool, String) : String
     static replaceAll(String, String, Int, Bool, String) : String
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
      action addPattern(p : Pattern){ pr.patterns.add(p);}
      action removePattern(p : Pattern){ pr.patterns.remove(p);}
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
          derive editRows from p for (name,pattern,group,projects)
          }
          action("Save", save())
      }

      action save() {
        p.save();
        return manage();
    }
  }

//
//   define output( p : Pattern ){
//
//   }