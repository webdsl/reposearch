module patterns

  entity Pattern {
    name    :: String (id, default="change me")
    pattern :: String
    group   :: Int
    caseSensitive :: Bool
    projects-> Set<Project> (inverse = Project.patterns)
    matches -> Set<PatternMatch> (inverse = PatternMatch.pattern)
  }
  derive crud Pattern

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
  }

  define managePatterns( pr : Project ){
      list{
        for( pattern : Pattern in pr.patterns){
            listitem{ output( pattern ) "-" navigate(editPattern( pattern )){"edit"} }
        }
      }
      navigate( createPattern()){"new pattern"}
  }
//
//   define output( p : Pattern ){
//
//   }