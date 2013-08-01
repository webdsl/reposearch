module search-configuration

  analyzer filename_analyzer {
    tokenizer = PatternTokenizer( pattern="[^\\.]+", group="0" )
    token filter = LowerCaseFilter
  }

  analyzer extension_analyzer {
    char filter = PatternReplaceCharFilter( pattern="^([^\\.]+)$", replacement="$1\\.(no ext)" )
    tokenizer = PatternTokenizer( pattern="\\.([^\\.]+)$", group="1" )
    token filter = LowerCaseFilter
  }

  analyzer keep_all_chars {
    tokenizer = PatternTokenizer(
      pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
      group="0" )
    token filter = PatternReplaceFilter(
      pattern="\\d+\\s",
      replacement=" ",
      replace="all" )
    token filter = LowerCaseFilter
  }

  analyzer keep_all_chars_cs {
    tokenizer = PatternTokenizer(
      pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
      group="0" )
    token filter = PatternReplaceFilter(
      pattern="\\d+\\s",
      replacement=" ",
      replace="all" )
  }

  analyzer code_identifiers_cs {
    //The line number pattern is filtered out by a char filter: ((\n|^)\\d+\\s)
    char filter = PatternReplaceCharFilter( pattern="((\n|^)\\d+\\s)|[^a-zA-Z_\\-0-9\\.]+", replacement=" ")
    tokenizer  = WhitespaceTokenizer
    token filter = LengthFilter(min="2", max="100", enablePositionIncrements="false")
    // token filter = HyphenationCompoundWordTokenFilter() //see http://lucene.apache.org/solr/api/org/apache/solr/analysis/HyphenationCompoundWordTokenFilterFactory.html for available parameters
  }

  analyzer path_analyzer {
    index {
      char filter = PatternReplaceCharFilter(
                      pattern="(^.+://)(.*)/.*",
                      replacement="$2" )
      tokenizer = PathHierarchyTokenizer( delimiter="/" )
    } query { 
      //We currently only query directory locations for deletion, not file locations,
      //so dont strip off the 'file' at the end, which is a directory at query time
      char filter = PatternReplaceCharFilter(
                      pattern="(^.+://)(.*)",
                      replacement="$2" )
      tokenizer = KeywordTokenizer
    }
  }

  analyzer definedConstructMatchAnalyzer {
    //charfilter = aCharFilter
    tokenizer    = WhitespaceTokenizer
    token filter = LowerCaseFilter
    //tokenfilter = aTokenFilter
  }