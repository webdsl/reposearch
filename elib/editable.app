module elib/editable

/*
section conditional editable input fields 

  define input(x: Ref<String>, edit: Bool) {
    if(edit) { input(x) } else { output(x) }
  }
  
  define input(x: Ref<Bool>, edit: Bool) {
    if(edit) { input(x) } else { output(x) }
  }
  
  define input(x: Ref<Int>, edit: Bool) {
    if(edit) { input(x) } else { output(x) }
  }

access control rules

  rule ajaxtemplate editableText(text : Ref<WikiText>) {
    true
  } 
  rule ajaxtemplate showWikiText(text : Ref<WikiText>) {
    mayView(text.getEntity())
    rule action edit() { mayEdit(text.getEntity()) }
  }
  rule ajaxtemplate editWikiText(text : Ref<WikiText>) {
    mayEdit(text.getEntity())
  }
  
section editable text

  define ajax editableText(text : Ref<WikiText>) {
    block[class="editableText"] {
	    placeholder showText{ showWikiText(text) }
    }
  }
  
  define ajax showWikiText(text : Ref<WikiText>) {
    action edit(){ replace(showText, editWikiText(text)); }
    block[class="showWikiTextEdit editLink"]{ submitlink edit() { "[edit]" } }
    output(text)
  }
  
  define ajax editWikiText(text : Ref<WikiText>) {
    form{ 
      input(text) 
      submit action{ modified(text.getEntity()); replace(showText, showWikiText(text)); }{ "Save" }
    }
    submit action{ replace(showText, showWikiText(text)); }{ "Cancel" }
  }
  
access control rules

  rule ajaxtemplate editableString(x : Ref<String>) {
    true
  }
  rule ajaxtemplate showString(x : Ref<String>) {
    mayView(x.getEntity())
    rule action edit() { mayEdit(x.getEntity()) }
  }
  rule ajaxtemplate editString(x : Ref<String>) {
    mayEdit(x.getEntity())
    rule action save() { mayEdit(x.getEntity()) }
    rule action cancel() { mayEdit(x.getEntity()) }
  }

section editable strings

  define ajax editableString(x : Ref<String>) {
    block[class="editableString"]{
      placeholder showString{ showString(x) }
    }
  }
  
  define ajax showString(x : Ref<String>) {
    action edit(){ replace(showString, editString(x)); }
    output(x) " "
    block[class="showString editLink"]{ submitlink edit() { "[edit]" } }
  }
  
  define ajax editString(x : Ref<String>) {
    action save() { modified(x.getEntity()); replace(showString, showString(x)); }
    action cancel() { replace(showString, showString(x)); }
    form{ input(x) " " submit save() { "Save" } " " }
    submit cancel() { "Cancel" }
  }

access control rules

  rule ajaxtemplate editableURL(x : Ref<URL>) {
    true
  }
  rule ajaxtemplate showURL(x : Ref<URL>) {
    mayView(x.getEntity())
    rule action edit() { mayEdit(x.getEntity()) }
  }
  rule ajaxtemplate editURL(x : Ref<URL>) {
    mayEdit(x.getEntity())
  }
  
section editable URLs

  define ajax editableURL(x : Ref<URL>) {
    placeholder showURL{ 
      if(x == null && mayEdit(x.getEntity())) {
        editURL(x)
      } else {
        showURL(x) 
      }
    }
  }
  
  define ajax showURL(x : Ref<URL>) {
    action edit(){ replace(showURL, editURL(x)); }
    output(x) " "
    block[class="showURL editLink"]{ submitlink edit() { "[edit]" } }
  }
  
  define ajax editURL(x : Ref<URL>) {
    form{ 
      input(x) 
      submit action{ modified(x.getEntity()); replace(showURL, showURL(x)); }{ "Save" }
    }
    form{ submit action{ replace(showURL, showURL(x)); }{ "Cancel" } }
  }

access control rules

  rule ajaxtemplate editableBool(x : Ref<Bool>) {
    true
  }
  rule ajaxtemplate showBool(x : Ref<Bool>) {
    mayView(x.getEntity())
    rule action toggle() { mayEdit(x.getEntity()) }
  }
  
section editable Bools

  define ajax editableBool(x : Ref<Bool>) {
    placeholder showBool{ showBool(x) }
  }
    
  define ajax showBool(x : Ref<Bool>) {
    action toggle() { x := !x; replace(showBool, showBool(x)); }
    form{ input(x)[onclick:=toggle()] }
  }
*/
