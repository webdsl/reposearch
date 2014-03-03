module elib/ace

section ace editor

  // https://github.com/ajaxorg/ace/wiki/Embedding---API
  
  // usage:
  // form{
  //   ace(foo.code, "foo") // to edit text value of foo.code, use "foo" once per page
  // }
  
  // make sure to add the following to css
  //   #editor<foo> {
  //     position: relative;
  //     width: 100%;
  //     height: 300px;
  //     border: 1px solid black;
  //   }
  
  define requireACE() {
    includeJS("src/ace.js")
    includeJS("src/mode-scala.js")
    includeJS("src/mode-javascript.js")
    includeJS("src/mode-c_cpp.js")
    includeJS("src/theme-eclipse.js") 
    includeJS("initACE.js")
  }
  
  define ace(code: Ref<Text>, lang : String) {  
  	var tname := getTemplate().getUniqueId()	
  	ace(code, lang, tname, false)
  }
  
  define ace(code: Ref<Text>, lang : String, readonly: Bool) { 
  	var tname := getTemplate().getUniqueId()
  	ace(code, lang, tname, readonly)
  }
  
  define ace(code: Ref<Text>, lang : String, id: String) {  	
  	ace(code, lang, id, false)
  }

  define aceView(code: Ref<Text>, lang : String) {  	
  	var tname := getTemplate().getUniqueId()	
  	ace(code, lang, tname, true)
  }
    
  define aceView(code: Ref<Text>, lang : String, id: String) {  	
  	ace(code, lang, id, true)
  }
  
  // 619px; height: 500px
  // todo: adapt size to window document.documentElement.clientWidth
  
  define ace(code: Ref<Text>, lang : String, id: String, readonly: Bool) {
  	requireACE() 
  	div[class="aceEditor", id="editor" + id, 
  	    style="position: absolute"
  	         + "; border: 1px solid #999;"
  	]{
  	  output(code)
  	}

  	input(code)[style="display:none",id=id]
  	case(lang.toLowerCase()) {
  		"scala" {
  			<script>
      		registerOnload(function() { scalaEditor('~id', ~readonly) });
    		</script>
  		}
  		"c" {
  			<script>
      		registerOnload(function() { cEditor('~id', ~readonly) });
    		</script>
  		}
		"js" {
                        <script>
                registerOnload(function() { jsEditor('~id', ~readonly) });
                </script>
                }
  	}
    // <script>
    //   registerOnload(function() { scalaEditor('~id', ~readonly) });
    // </script>
  }
