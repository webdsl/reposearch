module searchconfiguration

analyzer standard{
  tokenizer = StandardTokenizer
  tokenfilter = StandardFilter
  tokenfilter = LowerCaseFilter
  tokenfilter = StopFilter
}

default analyzer code_analyzer{
  tokenizer = PatternTokenizer(pattern="[a-zA-Z0-9\\-\\_]+|[!-/:-@\\[-\\^{-~`]", group="0")
  tokenfilter = LowerCaseFilter
}

analyzer code_analyzer_casesensitive{
  tokenizer = PatternTokenizer(pattern="[a-zA-Z0-9\\-\\_]+|[!-/:-@\\[-\\^{-~`]", group="0")
}

analyzer kw{
  tokenizer = KeywordTokenizer
}