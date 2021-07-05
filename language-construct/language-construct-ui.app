module language-construct/language-construct-ui

imports built-in
imports reposearch
imports project/project
imports language-construct/language-construct-data
imports manage/-

section pages/templates

  define manageLangConstructs( pr : Project ) {
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
  
  
  page createLangConstruct() {
    var p:= LangConstruct { }
    title { output( "New language construct | Reposearch" ) }
    mainResponsive( "Projects") {
      editLangConstruct( p )
    }
  }
  
  page editLangConstruct( p : LangConstruct ) {
    title { output( "Edit language construct | Reposearch" ) }
    mainResponsive( "Projects" ) {
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