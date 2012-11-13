module elib/wikitext

define outputRelaxed(s: WikiText){ rawoutput(s.relaxedFormat()) }

type WikiText{ org.webdsl.tools.RelaxedWikiFormatter.wikiFormat as relaxedFormat():String }
