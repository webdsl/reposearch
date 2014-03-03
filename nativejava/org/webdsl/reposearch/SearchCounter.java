package org.webdsl.reposearch;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public final class SearchCounter {
  static Map<String,MutableInt> projectCountMap = new HashMap<String, MutableInt>();
  private static final Lock lock = new ReentrantLock();
  
  public static final void inc( String project ){
    try {
      lock.tryLock ( 1, TimeUnit.SECONDS );
      MutableInt count = projectCountMap.get( project );
      if ( count == null ) {
        projectCountMap.put( project, new MutableInt() );
      } else {
          count.increment();
      }
    } catch ( InterruptedException e ) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    } finally {
      lock.unlock();
    }
  }
  
  public static final Set<String> getDirtyProjects() {
    return projectCountMap.keySet();
  }
  
  public static final int steal( String project ) {
    try {
      lock.tryLock ( 1, TimeUnit.SECONDS );
      return projectCountMap.remove( project ).get();
    } catch ( Exception e ) {
      e.printStackTrace();
      return 0;
    } finally {
      lock.unlock();
    }
  }
}


final class MutableInt {
  int value = 1; // note that we start at 1 since we're counting
  public void increment () { ++value;      }
  public int  get ()       { return value; }
}