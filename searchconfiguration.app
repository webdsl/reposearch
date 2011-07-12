module searchconfiguration

analyzer standard{
  tokenizer = StandardTokenizer
  tokenfilter = StandardFilter
  tokenfilter = LowerCaseFilter
  tokenfilter = StopFilter (words="analyzerfiles/stopwords.txt")
}

default analyzer code_analyzer{
  tokenizer = PatternTokenizer(pattern="[a-zA-Z0-9\\-\\_]+|[!-/:-@\\[-\\^{-~`]", group="0")
  tokenfilter = LowerCaseFilter
}