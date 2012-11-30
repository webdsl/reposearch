module project/project


  entity Project {
    cache //Project entitities are retrieved on any page
    name                 :: String( id )
    repos                -> List<Repo>
    displayName          :: String   := capitalize(name)
    searchCount          :: Int      ( default=0 )
    weeklySearchCount    :: Int      := if( weekStartSearchCount != null ) searchCount - weekStartSearchCount else 0
    weekStartSearchCount :: Int      ( default=0 )
    countSince           :: DateTime ( default=now() )

    validate( name.length() > 2, "length must be greater than 2" )

    function resetSearchCount() {
      searchCount := 0;
      weekStartSearchCount := 0;
      countSince := now();
    }
  
    function addSearchCount( count : Int) {
      searchCount := searchCount + count;
    }
    function newWeek() {
      weekStartSearchCount := searchCount;
    }
  }
  
  function capitalize(name : String) : String {
    return if( name.length() > 0 ) name.substring( 0,1 ).toUpperCase() + name.substring( 1, name.length() ) else name;
  }