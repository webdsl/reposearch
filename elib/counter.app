module elib/counter

  function newCounter(): Counter { return Counter{}.init(); }

  entity Counter {
  	current :: Long (default=0L)
  	function init(): Counter {
  		current := current + 1L;
  		return this;
  	} 
  	function next(): Long {
  		current := current + 1L;
  		return current;
  	}
  	function nextKey(): String {
  	  return next() + "";
    }
  }
  
