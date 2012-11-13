module elib/rss 

section RSS
  
  define span rssWrapper() {
    //mimetype("text/xml")
    mimetype("application/rss+xml")
    //<?xml version="1.0" encoding="utf-8" ?>
    <rss version="2.0">
       elements()
    </rss>
  }
  
  define rssDateTime(d: DateTime) {
    output(d.format("EEE, dd MMM yyyy hh:mm:ss ZZZ"))
  }
  
  // see http://www.rssboard.org/rss-specification for documentation
  
  define rssWrapper(title: String, url: String, feedURL: String, desc: Text, pubDate: DateTime) {
    var now := now()
    mimetype("application/rss+xml")
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel> 
        <atom:link href=url rel="self" type="application/rss+xml" />
        <link>output(feedURL)</link>
        <title>output(title)</title>
        <description>output(desc)</description>
        if(pubDate != null) { <pubDate>rssDateTime(pubDate)</pubDate> }
        <docs>"http://www.rssboard.org/rss-specification"</docs>
        //<language></language>
        //<copyright></copyright>
        elements
      </channel>
    </rss>
  }
  
      //   <item> 
      //   <title>output(pub.title)</title>
      //   <link>output(navigate(publication(pub,"","")))</link>
      //   <description>citation(pub)</description>
      //   <guid>output(navigate(publication(pub,"","")))</guid>
      //   <pubDate>output(pub.created)</pubDate>
      // </item>
