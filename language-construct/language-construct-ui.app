module language-construct/language-construct-ui

section pages/templates

  define manageLangConstructs( pr : Project ) {
    "Language constructs management:"
    table {form{
        for( lc : LangConstruct in( from LangConstruct order by name ) ) {
          row {
            column {output( lc ) }
            column {" [" navigate( editLangConstruct( lc ) ) {"edit"}  "] "
              if( lc in pr.langConstructs ) {"[" submitlink( "remove",removeLangConstruct( lc ) ) "]"}
              else                        {"[" submitlink( "add",addLangConstruct( lc ) ) "]"}
            }
          }
        }
      }
    }
    action addLangConstruct( p : LangConstruct ) { pr.langConstructs.add( p ); langConsRenewSchedule.dirtyProjects.add( pr ); replace( "projectPH"+pr.name, showProject( pr ) ); }
    action removeLangConstruct( p : LangConstruct ) { pr.langConstructs.remove( p ); replace( "projectPH"+pr.name, showProject( pr ) );}
    navigate( createLangConstruct() ) {"new language construct"}
  }
  
  
  define page createLangConstruct() {
    var p:= LangConstruct { }
    mainResponsive( "Projects", "New language construct" ) {
      editLangConstruct( p )
    }
  }
  
  define page editLangConstruct( p : LangConstruct ) {
    mainResponsive( "Projects", "Edit language construct" ) {
      editLangConstruct( p )
    }
  }
  
  define editLangConstruct( lc : LangConstruct ) {
    form {
      group( "Details" ) {
        derive editRows from lc for( name,fileExts,pattern,group,projects )
        }
      action( "Cancel", cancel() ) " " action( "Save", save() ) " " action( "Remove permanently", remove() )
    }
    action cancel() { return manage(); }
    action save() {
      lc.save();
      langConsRenewSchedule.dirtyProjects.addAll( lc.projects );
      return manage();
    }
    action remove() {
      lc.projects.clear();
      for( cm in from ConstructMatch as c where( c.langConstruct = ~lc ) ) {
        cm.langConstruct := null;
      }
      lc.delete();
      return manage();
    }
  }