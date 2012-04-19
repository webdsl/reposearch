module searchconfiguration

analyzer filename_analyzer{
  tokenizer = PatternTokenizer(pattern="[^\\.]+", group="0")
  tokenfilter = LowerCaseFilter
}

analyzer extension_analyzer{
  charfilter = PatternReplaceCharFilter(pattern="^([^\\.]+)$", replacement="$1\\.(no ext)")
  tokenizer = PatternTokenizer(pattern="\\.([^\\.]+)$", group="1")
  tokenfilter = LowerCaseFilter
}

analyzer keep_all_chars{
  tokenizer = PatternTokenizer(
             pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
             group="0" )
  tokenfilter = LowerCaseFilter
}

analyzer keep_all_chars_cs{
  tokenizer = PatternTokenizer(
             pattern="((\n|^)\\d+\\s)|([a-zA-Z_]\\w*)|\\d+|[!-/:-@\\[-`{-~]",
             group="0" )
}

analyzer code_identifiers_cs{
  //The line number pattern is filtered out by a charfilter: ((\n|^)\\d+\\s)
  charfilter = PatternReplaceCharFilter(pattern="(\n|^)\\d+\\s", replacement="")
  tokenizer  = PatternTokenizer(
                 pattern="([a-zA-Z_]\\w*([\\-\\.](?=\\w))?)+",
                 group="0" )
}

analyzer path_analyzer{
  charfilter = PatternReplaceCharFilter(
                pattern="(^.+://)(.*)/.*",
                replacement="$2" )
  tokenizer = PathHierarchyTokenizer( delimiter="/" )
}