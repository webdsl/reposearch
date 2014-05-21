module analytics/analytics

section functions and templates 

  function gAnalytics() : String {
    return "<script type=\"text/javascript\">var _gaq = _gaq || []; var pluginUrl = '//www.google-analytics.com/plugins/ga/inpage_linkid.js'; _gaq.push(['_require', 'inpage_linkid', pluginUrl]); _gaq.push( ['_setAccount', 'UA-38993791-2'] ); _gaq.push( ['_trackPageview'] ); ( function() { var ga = document.createElement( 'script' ); ga.type = 'text/javascript'; ga.async = true; ga.src = ( 'https:' == document.location.protocol ? 'https://ssl' : 'http://www' ) + '.google-analytics.com/ga.js'; var s = document.getElementsByTagName( 'script' ) [0]; s.parentNode.insertBefore( ga, s ); } ) ();</script>";
  }
  
  template trackEvent( namespace : String, event : String){
  	var ns := if(namespace == "") "All projects" else namespace
    <script>
      if (_gaq) _gaq.push(['_trackEvent', '~ns', '~event']);
    </script>
  }
