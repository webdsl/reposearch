module elib/checkboxWikiText


section checkbox 

  define selectcheckboxWiki(set:Ref<Set<Entity>>){
    selectcheckboxWiki(set, false)[all attributes]{elements()}
  }
  define selectcheckboxWiki(set:Ref<Set<Entity>>, readonly: Bool){
    selectcheckboxWiki(set, set.getAllowed(), readonly)[all attributes]{ elements() }
  }
  
  
  define selectcheckboxWiki(set:Ref<Set<Entity>>, from : List<Entity>){
    selectcheckboxWiki(set, from, false)[all attributes]{ elements() }
  }
  define selectcheckboxWiki(set:Ref<Set<Entity>>, from : List<Entity>, readonly: Bool){
    var tname := getTemplate().getUniqueId()
    request var errors : List<String> := null
  
    if(errors != null && errors.length > 0){
      errorTemplateInput(errors){
        inputCheckboxSetInternalWiki(set,from,tname, readonly)[all attributes]
      }
      validate{ getPage().enterLabelContext(tname); } 
      elements() 
      validate{ getPage().leaveLabelContext();}
    }
    else{
      inputCheckboxSetInternalWiki(set,from,tname, readonly)[all attributes]
      validate{ getPage().enterLabelContext(tname); } 
      elements() 
      validate{ getPage().leaveLabelContext();}
    }
    validate{
      errors := set.getValidationErrors();
      errors.addAll(getPage().getValidationErrorsByName(tname)); //nested validate elements
      errors := handleValidationErrors(errors);
    }
  }
  
  define inputCheckboxSetInternalWiki(set : Ref<Set<Entity>>, from : List<Entity>, tname:String, readonly: Bool){
    var tnamehidden := tname + "_isinput"
    var reqhidden := getRequestParameter(tnamehidden)
    request var tmpset := Set<Entity>()
    
    <div class="checkbox-set "+attribute("class") all attributes except ["class","onclick"]>
      <input type="hidden" name=tnamehidden /> 
      for(e:Entity in from){
        inputCheckboxSetInternalHelperWiki(set,tmpset,e,tname+"-"+e.id, readonly)[onclick=""+attribute("onclick")]
      }
    </div>
    databind{
      if(reqhidden != null){
        set := tmpset;
      }
    }
  }

  define inputCheckboxSetInternalHelperWiki(set:Ref<Set<Entity>>, tmpset:Set<Entity>,e:Entity,tname:String, readonly: Bool){
    var tmp := getRequestParameter(tname)
    var tnamehidden := tname + "_isinput"
    var tmphidden := getRequestParameter(tnamehidden)
    <div class="checkbox-set-element">
      <input type="hidden" name=tnamehidden />
      <input type="checkbox" 
        name=tname 
        if(tmphidden!=null && tmp!=null || tmphidden==null && e in set){
          checked="true"  
        }
        if(readonly){ disabled="true" }
        id=tname+e.id
        all attributes
      />
      <label for=tname+e.id>
        output(e.name as WikiText)
      </label>
    </div>
    databind{
      if(tmphidden != null && tmp != null && !readonly){ tmpset.add(e); }
    }
  }
