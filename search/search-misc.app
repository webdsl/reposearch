module search/search-misc

  native class utils.URLFilter as URLFilter {
    static filter( String ) :String
  }

  define prettifyCode() { prettifyCodeHelper( "" ) }
  define prettifyCode( projectName : String ) { prettifyCodeHelper( "\""+URLFilter.filter( projectName ) +"\"" ) }
  define prettifyCodeHelper( projectName : String ) {
    //highlight code using google-code-prettify
    includeCSS( "prettify.css" )
    includeJS( "prettify.js" )
    includeJS( "make-clickable.js" )
    <script>
      prettifyAndMakeClickable( ~projectName );
    </script>
  }

  service autocompleteService( namespace:String, term : String ) {
    var jsonArray := JSONArray();
    var results := EntrySearcher.autoCompleteSuggest( term,namespace,["codeIdentifiers","fileName"], 20 );
    for( sug : String in results ) {
      jsonArray.put( sug );
    }
    return jsonArray;
  }