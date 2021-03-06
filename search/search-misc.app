module search/search-misc

  invoke updateSearchCounts() every 60 seconds

  native class utils.URLFilter as URLFilter {
    static filter( String ) :String
  }
  
  native class org.webdsl.reposearch.SearchCounter as SearchCounter{
    static inc(String)
    static getDirtyProjects() : Set<String>
    static steal(String) : Int
  }

  define prettifyCode() { prettifyCodeHelper( "", true ) }
  define prettifyCode( projectName : String ) { prettifyCodeHelper( "\"" + URLFilter.filter( projectName ) + "\"", true) }
  define prettifyCodeHelper( projectName : String, clickable : Bool ) {
    //highlight code using google-code-prettify
    includeCSS( "prettify.css" )
    includeJS( "prettify/prettify.js" )
    includeJS( "make-clickable.js" )
    if(clickable){
	    <script>
	      prettifyAndMakeClickable( ~projectName );
	    </script>
    } else {
    	<script>
    	  prettyPrint();
    	</script>
    }
  }

  service autocompleteService( namespace:String, term : String ) {
    var jsonArray := JSONArray();
    var results := EntrySearcher.autoCompleteSuggest( term,namespace,["codeIdentifiers","fileName"], 20 );
    for( sug : String in results ) {
      jsonArray.put( sug );
    }
    return jsonArray;
  }
  
  function updateSearchCounts(){
    var cnt := 0;
    var prj : Project;
    
    for ( ns : String in SearchCounter.getDirtyProjects() ) {
      cnt := SearchCounter.steal( ns );
      prj := findProject( ns );
      if ( prj != null ) { prj.addSearchCount( cnt ); }
    }
  }