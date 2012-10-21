module searchconfiguration

analyzer filename_analyzer{
  tokenizer = PatternTokenizer(pattern="[^\\.]+", group="0")
  token filter = LowerCaseFilter
}

analyzer extension_analyzer{
  char filter = PatternReplaceCharFilter(pattern="^([^\\.]+)$", replacement="$1\\.(no ext)")
  tokenizer = PatternTokenizer(pattern="\\.([^\\.]+)$", group="1")
  token filter = LowerCaseFilter
}

analyzer keep_all_chars{
  tokenizer = PatternTokenizer(
             pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
             group="0" )
  token filter = LowerCaseFilter
}

analyzer keep_all_chars_cs{
  tokenizer = PatternTokenizer(
             pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
             group="0" )
  token filter = PatternReplaceFilter(
                   pattern="(\n|^)\\d+\\s",
                   replacement="",
                   replace="all" )
}

analyzer code_identifiers_cs{
  //The line number pattern is filtered out by a char filter: ((\n|^)\\d+\\s)
  char filter = PatternReplaceCharFilter(pattern="(\n|^)\\d+\\s", replacement=" ")
  tokenizer  = PatternTokenizer(
                 pattern="([a-zA-Z_]\\w*([\\-\\.](?=\\w))?)+",
                 group="0" )
}

analyzer path_analyzer{
  char filter = PatternReplaceCharFilter(
                pattern="(^.+://)(.*)/.*",
                replacement="$2" )
  tokenizer = PathHierarchyTokenizer( delimiter="/" )
}

  analyzer definedPatternMatchAnalyzer{
      //charfilter = aCharFilter
      tokenizer    = WhitespaceTokenizer
      token filter = LowerCaseFilter
      //tokenfilter = aTokenFilter
  }