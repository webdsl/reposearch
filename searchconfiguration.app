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
  charfilter = PatternReplaceCharFilter(pattern="^\\d+\\s", replacement="") //strip off line numbers
  tokenizer = PatternTokenizer(pattern="[a-zA-Z0-9\\_]+|[!-/:-@\\[-\\^{-~`]", group="0")
  tokenfilter = LowerCaseFilter
}

analyzer code_analyzer_casesensitive{
  charfilter = PatternReplaceCharFilter(pattern="^\\d+\\s", replacement="") //strip off line numbers
  tokenizer = PatternTokenizer(pattern="[a-zA-Z0-9\\-\\_]+|[!-/:-@\\[-\\^{-~`]", group="0")
}

analyzer kw{
  tokenizer = KeywordTokenizer
}