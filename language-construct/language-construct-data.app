module language-construct/language-construct-data

section entities
    entity LangConstruct {      
      cache //LangConstruct entities are fetched on every search page
      name    :: String( id, default="change me" )
      pattern :: String
      group   :: Int
      fileExts:: String
      caseSensitive :: Bool
      projects      -> Set<Project> ( inverse = Project.langConstructs )
    
      function addLangConstructConstraint( searcher : EntrySearcher ) { addLangConstructConstraint( searcher, name ); }
      function replaceLangConstructConstraint( searcher : EntrySearcher ) : EntrySearcher { return replaceLangConstructConstraint( searcher, name ); }
    }
    
    extend entity Project {
      langConstructs -> Set<LangConstruct>
    }
    
    entity ConstructMatch {
      entry         -> Entry
      langConstruct -> LangConstruct
      langConsName  :: String := langConstruct.name 
      project       :: String := entry.projectname 
    
      /**
      * Retrieves matches in the form of: ' class#MATCH#SvnFetcher SvnFetcher'
      * The search field 'matches' is used in 2 contexts:
      *  one matching an identifier independent on the language construct (for faceting), using token 'SvnFetcher'
      *  one matching the identifier specific for a language construct, using token 'class#MATCH#SvnFetcher'
      */
      matches :: Text := MatchExtractor.extract( langConstruct, entry.content )
    
      search mapping {
        langConsName using none
        matches      using definedConstructMatchAnalyzer
        namespace by project
      }
    }
    
    extend entity Entry {
      constructs <> Set<ConstructMatch> ( inverse = ConstructMatch.entry )
    
      function addconstructs() {
        this.constructs.clear();
        var fileExt := /^.*\. ( [^\.]+ ) $/.replaceAll( "$1", this.name );
        for( lc : LangConstruct in this.repo.project.langConstructs ) {
          if( lc.fileExts.contains( fileExt ) ) {
            this.constructs.add( ConstructMatch { entry := this langConstruct := lc } );
          }
        }
      }
    }
    
  entity LangConstructRenewSchedule {
    dirtyProjects -> Set<Project> ( default=Set<Project>() )
    enabled :: Bool( default=true )

    function run() {
      if( enabled ) {
        for( pr : Project in dirtyProjects ) {
          RepositoryFetcher.log( "Reindexing entries for project '" + pr.name + "' because of a change in assigned language constructs" );
          for( repo : Repo in pr.repos ) {
            for( e:Entry where e.repo == repo ) {
              if( enabled ) {
                e.addconstructs();
              }
            }
          }
          RepositoryFetcher.log( "Done adding language construct matches to project '" +  pr.name + "'" );
        }
      }//reschedule dirty projects if task is disabled
      if( enabled ) {
        dirtyProjects.clear();
      }
    }
  }
    
section functions

  function getLanguageConstructFacets( searcher : EntrySearcher ) : List<Facet> {                                                      
    return langConsName facets from search ConstructMatch matching matches: +searcher.getQuery() [no lucene]
                                                          with facets (langConsName, 20)
                                                          in namespace searcher.getNamespace();
  }
    
  function addLangConstructConstraint( searcher : EntrySearcher, constructName: String ) {
    var constraint := constructName.replace( " ", "_" ) + "#MATCH#" + searcher.getQuery();
    ~searcher matching constructs.matches: +constraint [no lucene];
  }
  
  function replaceLangConstructConstraint( oldSearcher : EntrySearcher, constructName : String ) : EntrySearcher {
    var newSearcher := toSearcher( oldSearcher.getQuery(), oldSearcher.getNamespace(), constructName );
    newSearcher.addFacetSelection( oldSearcher.getFacetSelection() );
    return newSearcher;
  }
  
  function deleteUnlinkedConstructMatches( ) {
    var unlinked := from ConstructMatch as c where c.entry = null;
    RepositoryFetcher.log( "Number of unlinked construct matches (should be 0, otherwise we're dealing with a bug):" + unlinked.length);
    for( c : ConstructMatch in unlinked ) {  c.delete();}
  }
  
section native java

  native class org.webdsl.reposearch.langcons.MatchExtractor as MatchExtractor {
    static extract( LangConstruct, String ) : String
    static decorateMatches( LangConstruct, String, String ) : String
  }
