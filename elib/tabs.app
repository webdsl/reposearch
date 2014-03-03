module elib/tabs

section tab set

  define tabs() { 
  	div[class="tabs"]{
  		elements
  	}
  }
  
  define tab(label: String) { 
  	tab(label, false){ elements }
  }
   
  define tabDefault(label: String) { 
  	tab(label, true){ elements }
  }
    
  define tab(label: String, checked: Bool) { 
  	var tname := getTemplate().getUniqueId()
  	div[class="tab"]{
  		if(checked) {
	  	  <input type="radio" id=tname name="tab-group-1" checked="true"></input>
	  	} else {
	  	  <input type="radio" id=tname name="tab-group-1"></input>	  		
	  	}
	  	<label for=tname>output(label)</label>
	  	div[class="content"]{
	  		elements
	  	}
  	}
  }