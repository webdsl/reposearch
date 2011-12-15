module searchconfiguration

analyzer standard{
  tokenizer = StandardTokenizer
  tokenfilter = StandardFilter
  tokenfilter = LowerCaseFilter
  tokenfilter = StopFilter
}

analyzer filename_analyzer{  
  tokenizer = PatternTokenizer(pattern="([^\\.]+)\\.", group="1")
  tokenfilter = LowerCaseFilter
}

analyzer extension_analyzer{
  charfilter = PatternReplaceCharFilter(pattern="^([^\\.]+)$", replacement="$1\\.(no ext)")
  tokenizer = PatternTokenizer(pattern="\\.([^\\.]+)$", group="1")
  tokenfilter = LowerCaseFilter
}

default analyzer code_analyzer{
  //The line number pattern is first matched as token, and then filtered out by the tokenfilter: ((\n|^)\\d+\\s)
  tokenizer = PatternTokenizer(pattern="((\n|^)\\d+\\s)|[a-zA-Z0-9\\_]+|[!-,\\./:-@\\[\\^{-~`]", group="0")
  tokenfilter = PatternReplaceFilter(pattern="(\n|^)\\d+\\s", replacement="", replace="all")
  tokenfilter = LowerCaseFilter  
}

analyzer code_analyzer_casesensitive{
  //The line number pattern is first matched as token, and then filtered out by the tokenfilter: ((\n|^)\\d+\\s)
  tokenizer = PatternTokenizer(pattern="((\n|^)\\d+\\s)|[a-zA-Z0-9\\_\\-]+|[!-,\\./:-@\\[\\^{-~`]", group="0")
  tokenfilter = PatternReplaceFilter(pattern="(\n|^)\\d+\\s", replacement="", replace="all")  
}

analyzer kw{
  tokenizer = KeywordTokenizer
}