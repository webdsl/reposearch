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
             pattern="((\n|^)\\d+\\s)|[a-zA-Z0-9_]+|[!-/:-@\\[-`{-~]",
             group="0" )
  tokenfilter = LowerCaseFilter
}

analyzer keep_all_chars_cs{
  tokenizer = PatternTokenizer(
         pattern="((\n|^)\\d+\\s)|[a-zA-Z0-9_]+|[!-/:-@\\[-`{-~]",
         group="0" )
}

analyzer code_identifiers_cs{
  //The line number pattern is first matched as token, and then filtered out by the tokenfilter: ((\n|^)\\d+\\s)
  tokenizer = PatternTokenizer(
                 pattern="((\n|^)\\d+\\s)|([a-zA-Z0-9_][\\-\\.]?)+",
                 group="0" )
  tokenfilter = PatternReplaceFilter(
                   pattern="(\n|^)\\d+\\s",
                   replacement="",
                   replace="all" )
}

analyzer path_analyzer{
  charfilter = PatternReplaceCharFilter(
                pattern="(^.+://)(.*)/.*",
                replacement="$2" )
  tokenizer = PathHierarchyTokenizer( delimiter="/" )
}