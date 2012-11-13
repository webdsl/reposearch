module elib/pageindex

  define span pageIndexLink(i : Int, lab : String) { 
    "no definition of pageIndexLink" 
  }
  
  define pageIndex(index : Int, count : Int, perpage : Int) {
    var idx := max(1,index)
    var pages : Int := 1 + count/perpage
    div[class="pagination pagination-centered"] { list {
	    if(pages > 1) { 
	      if(idx > 1) { 
	        listitem[class="active"]{ pageIndexLink(idx-1, "Prev") }
	      } else { 
	        listitem[class="disabled"]{ "Prev" }
	      }
	      for(i : Int from 1 to pages+1) {  
	        if(i == idx) {
	          listitem[class="disabled"]{ output(i) }
	        } else { 
	          listitem[class="active"]{ pageIndexLink(i, i + "") }
	        }
	      }
	      if(idx < pages) { 
	        listitem[class="active"]{ pageIndexLink(idx+1,"Next") }
	      } else { 
	        listitem[class="disabled"]{ "Next" }
	      }
	    }
    } }
  }
  
  function pageIndexIntervals(idx : Int, count : Int, perpage : Int, max: Int, end: Int): List<List<Int>> {
    var pages : Int := 1 + (count - 1)/perpage;
    var middle := (max - (2 * (end + 1)))/2;  
    var intervals : List<List<Int>>;
    if(pages <= max) {
      intervals := [[1,pages]];
    } else { if(idx <= end + 2 + middle) {
      intervals := [[1, end + 1 + 2 * middle], [pages - end + 1, pages]];
    } else { if(idx >= pages - end - middle) {
      intervals := [[1,end], [pages - end - 2 * middle, pages]];
    } else {
      intervals := [[1, end], [idx - middle, idx + middle - 1], [pages - end + 1, pages]];
    }}}
    return intervals;
  }
  
  define pageIndex(index : Int, count : Int, perpage : Int, max: Int, end: Int) {
    var pages : Int := 1 + (count - 1)/perpage
    var idx := min(max(1,index), pages)
    var intervals : List<List<Int>> := pageIndexIntervals(idx, count, perpage, max, end)
    // todo: redirect to normalized index page
    // init{
    //   if(index > pages) { goto ; }
    // }
    if(pages > 1) { 
      div[class="pagination pagination-centered"] { list {
        if(idx > 1) { 
          listitem{ pageIndexLink(idx-1, "Prev") }
        } else { 
          listitem[class="disabled"]{ <a href="#">"Prev"</a> }
        }
        for(iv : List<Int> in intervals) {
	        for(i : Int from iv.get(0) to iv.get(1) + 1) { 
	          if(i == idx) {
	            listitem[class="active"]{ <a href="#">output(i)</a> }
	          } else { 
	            listitem{ pageIndexLink(i, i + "") }
	          }
	        }
        } separated-by {
          listitem[class="disabled"]{ <a href="#">"..."</a> }
        }
        if(idx < pages) { 
          listitem{ pageIndexLink(idx+1,"Next") }
        } else { 
          listitem[class="disabled"]{ <a href="#">"Next"</a> }
        }
      } }
    }
  }

  define span pageIndexUpto(index : Int, more : Bool) {
    var pages : Int := index
    if(index > 1) { 
      pageIndexLink(index-1, "Previous") 
    } else { 
      listitem[class="indexprevious"]{ "Prev" }
    }
    for(i : Int from 1 to pages+1) {  
      if(i == index) {
        listitem[class="current"]{ output(i) }
      } else { 
        listitem[class="active"]{ pageIndexLink(i, i + "") }
      }
    }
    if(more) {
      pageIndexLink(index+1,"Next")
    } else {
      listitem[class="active"]{ "Next" }
    }
  }
