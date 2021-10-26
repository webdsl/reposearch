package org.webdsl.reposearch.repositories;


import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.tmatesoft.svn.core.SVNErrorMessage;
import org.tmatesoft.svn.core.SVNException;
import org.tmatesoft.svn.core.SVNLogEntry;
import org.tmatesoft.svn.core.SVNLogEntryPath;
import org.tmatesoft.svn.core.SVNNodeKind;
import org.tmatesoft.svn.core.SVNURL;
import org.tmatesoft.svn.core.internal.io.dav.DAVRepositoryFactory;
import org.tmatesoft.svn.core.internal.io.fs.FSRepositoryFactory;
import org.tmatesoft.svn.core.internal.io.svn.SVNRepositoryFactoryImpl;
import org.tmatesoft.svn.core.io.SVNRepository;
import org.tmatesoft.svn.core.io.SVNRepositoryFactory;
import org.tmatesoft.svn.core.wc.SVNClientManager;
import org.tmatesoft.svn.core.wc.SVNRevision;
import org.tmatesoft.svn.core.wc.SVNUpdateClient;
import org.webdsl.logging.Logger;

import webdsl.generated.domain.Entry;

import com.google.common.io.Files;

public class RepositoryFetcher {
  private static StringBuilder logBuilder = new StringBuilder();
  private static final Lock lock = new ReentrantLock();

  public static void main ( String[] args ) {
    test();
  }

  public static void test() {
    String repo = "https://svn.strategoxt.org/repos/reposearch/reposearch/";
    updateFromRevOrCheckout ( repo, 65 );
  }

  public static RepoTaskResult updateFromRevOrCheckout ( String user,String repo, String path, long rev ) {
    return updateFromRevOrCheckout ( "https://github.com/"+user+"/"+repo+"/"+path, rev );
  }
  public static RepoTaskResult checkout ( String user,String repo,String path ) {
    return checkout ( "https://github.com/"+user+"/"+repo+"/"+path );
  }
  
  public static RepoTaskResult checkout ( utils.File repoFile ) {
    List<Entry> entriesForAddition = new ArrayList<Entry>();
    File dst = null;
    ZipInputStream zis = null;
    byte[] buffer = new byte[1024];
    
    try {
      zis = new ZipInputStream( repoFile.getContentStream() );
      dst = Files.createTempDir();
      log ( "checkout in temp dir: " + dst );      
      
      //get the zipped file list entry
      ZipEntry ze = zis.getNextEntry();
 
      while(ze!=null){
        if (ze.isDirectory()){
          ze = zis.getNextEntry();
          continue;
        }
        String fileName = ze.getName();
        File newFile = new File(dst.getAbsolutePath() + File.separator + fileName);
 
        log("file unzip : "+ newFile.getAbsoluteFile());
 
        //create all non exists folders
        //else you will hit FileNotFoundException for compressed folder
        new File(newFile.getParent()).mkdirs();

        FileOutputStream fos = new FileOutputStream(newFile);             
 
        int len;
        while ((len = zis.read(buffer)) > 0) {
          fos.write(buffer, 0, len);
        }
 
        fos.close();   
        ze = zis.getNextEntry();
      }
 
      zis.closeEntry();
      zis.close();
      
      addEntryRecursive ( repoFile.getFileName() + ":","",dst, entriesForAddition );
    } catch ( IOException e ) {
      e.printStackTrace();
    } catch ( SQLException e1 ) {
      // TODO Auto-generated catch block
      e1.printStackTrace();
    }
    
    //delete temp dir
    try {
      delete ( dst );
      log ( "Removed temp dir: " + dst );
    } catch ( IOException e ) {
      log ( e.getMessage() );
      e.printStackTrace();
    }
    
    return new RepoTaskResult( entriesForAddition, new ArrayList<String>(), 0 );
  }
  

  private static final long latestRevision = -1;

  public static RepoTaskResult checkout ( String repo ) {
    return updateFromRevOrCheckout ( repo, -10 );
  }

  //It returns a RepoTaskResult object with:
  // -if fromRev is not the latest: non-null file lists with updated/deleted file representations.
  // -if fromRev < 1 : It performs a checkout and returns a RepoTaskResult object with all files in HEAD revision
  // -if fromRev is the latest: null file lists (no need to update)
  public static RepoTaskResult updateFromRevOrCheckout ( String repoUrl, long fromRev ) {
    log ( "Trying to update (r>0) or checkout (r<1) location: '" + repoUrl + "' from r=" + fromRev );
    String url = repoUrl;
    setupLibrary();
    SVNRepository repository = null;
    try {
      repository = SVNRepositoryFactory.create ( SVNURL.parseURIEncoded ( url ) );
      SVNNodeKind nodeKind = repository.checkPath ( "", latestRevision );
      if ( nodeKind == SVNNodeKind.NONE ) {
        log ( "There is no entry at '" + url + "'." );
        throw new SVNException ( SVNErrorMessage.UNKNOWN_ERROR_MESSAGE );
      } else if ( nodeKind == SVNNodeKind.FILE ) {
        log ( "The entry at '" + url + "' is a file." );
        List<Entry> entriesForAddition = new ArrayList<Entry>();
        List<String> entriesForRemoval = new ArrayList<String>();
        long rev = repository.getLatestRevision();
        if ( fromRev < 1 ) {
          log ( "Checkout: " + repoUrl );
          getFile ( "", repository, entriesForAddition );
        } else {
          if ( fromRev < rev )
            rev = updateToRevision ( repository, fromRev, entriesForAddition, entriesForRemoval );
          else {
            log ( "Skipped update for repo: " + repoUrl + ". This one is already at HEAD" );
            return new RepoTaskResult ( null, null, rev );
          }
        }
        return new RepoTaskResult ( entriesForAddition, entriesForRemoval, rev );
      } else {
        long repoUrlHeadRev;
        try {
          repoUrlHeadRev = repository.getDir ( "", latestRevision, true, null ).getRevision();
        } catch ( SVNException ex ) {
          repoUrlHeadRev= repository.getLatestRevision();
        }
        if ( fromRev >= repoUrlHeadRev ) {
          log ( "Skipped update for repo: " + repoUrl + ". This one is already at HEAD" );
          return new RepoTaskResult ( null, null, repoUrlHeadRev );
        }
        List<Entry> entriesForAddition = new ArrayList<Entry>();
        List<String> entriesForRemoval = new ArrayList<String>();
        if ( fromRev < 1 ) {
          log ( "Checkout: " + repoUrl );
          doSVNCheckout ( repoUrl, entriesForAddition );
          log ( "Finished checking out: " + repoUrl );
        } else {
          log ( "Updating: " + repoUrl + " from " + fromRev + " to HEAD (r" + repoUrlHeadRev + ")" );
          updateToRevision ( repository, fromRev, entriesForAddition, entriesForRemoval );
        }
        return new RepoTaskResult ( entriesForAddition, entriesForRemoval, repoUrlHeadRev );
      }
    } catch ( SVNException svne ) {
      log ( svne.getMessage() );
      svne.printStackTrace();
      return null;
    } finally {
      if ( repository != null ) {
        try {
          repository.closeSession();
        } catch ( Exception ex ) {
          ex.printStackTrace();
        }
      }
    }
  }

  private static long updateToRevision ( SVNRepository repository, long start, List<Entry> entriesForAddition, List<String> entriesForRemoval ) throws SVNException {
    Collection<?> logEntries = null;
    String repositoryRootUrl = repository.getRepositoryRoot ( false ).toString();
    logEntries = repository.log ( new String[] { "" } , null , start+1 , latestRevision , true , true );
    Iterator<?> logs = logEntries.iterator();
    Map<?,?> changedPaths;
    Set<String> toAdd = new HashSet<String>(), toRemove = new HashSet<String>();
    SVNLogEntry log = null;
    while ( logs.hasNext() ) {
      log = ( ( SVNLogEntry ) logs.next() );
      changedPaths = log.getChangedPaths();
      for ( Iterator<?> pathEntries = changedPaths.keySet().iterator( ); pathEntries.hasNext( ); ) {
        SVNLogEntryPath entryPath = ( SVNLogEntryPath ) changedPaths.get ( pathEntries.next( ) );
        if ( entryPath.getKind().equals ( SVNNodeKind.DIR ) &&
             entryPath.getType() == SVNLogEntryPath.TYPE_DELETED ) {
          toRemove.add ( entryPath.getPath() );
        }
        if ( !entryPath.getKind().equals ( SVNNodeKind.FILE )
             || !entryPath.getPath().startsWith ( repository.getRepositoryPath ( "" ) ) )
          continue; //ignore entry paths that dont represent files or do not reside in the chosen repository directory
        switch ( entryPath.getType() ) {
        case SVNLogEntryPath.TYPE_ADDED :
          toAdd.add ( entryPath.getPath() );
          break;
        case SVNLogEntryPath.TYPE_MODIFIED: //modified -> remove and add
        case SVNLogEntryPath.TYPE_REPLACED:
          toAdd.add ( entryPath.getPath() );
          toRemove.add ( entryPath.getPath() );
          break;
        case SVNLogEntryPath.TYPE_DELETED:
          toRemove.add ( entryPath.getPath() );
          toAdd.remove ( entryPath.getPath() );
          break;
        default:
          break;
        }
      }
    }
    long latestRev = ( log == null ) ? start : log.getRevision();
    if ( log != null ) {
      StringBuilder sb = new StringBuilder ( "Reposearch deltas for " + repositoryRootUrl + " from base r" + start + " to target r" + latestRev +  " (modified files will be deleted and added):" );
      sb.append ( "\n--------------------------------" );
      for ( String path : toRemove ) {
        entriesForRemoval.add ( fixUrl ( repositoryRootUrl+repository.getRepositoryPath ( path ) ) );
        sb.append ( "\n- " );
        sb.append ( path );
      }
      for ( String path : toAdd ) {
        getFile ( path, repository, entriesForAddition );
        sb.append ( "\n+ " );
        sb.append ( path );
      }
      sb.append ( "\n--------------------------------" );
      log ( sb.toString() );
    } else {
      log ( "No updates for location: " + repository.getLocation() + ". This one is already at HEAD" );
    }
    return latestRev;
  }



  public static void doSVNCheckout ( String url, List<Entry> entriesForAddition ) {
    setupLibrary();
    File dst = null;
    try {
      dst = Files.createTempDir();
      log ( "checkout in temp dir: " + dst );
      SVNURL svnurl = SVNURL.parseURIEncoded ( url );
      SVNClientManager cm = SVNClientManager.newInstance();
      SVNUpdateClient uc = cm.getUpdateClient();
      uc.doCheckout ( svnurl, dst, SVNRevision.UNDEFINED, SVNRevision.HEAD, true );
      if ( !url.endsWith ( "/" ) ) {
        url = url+"/";
      }
      addEntryRecursive ( url,"",dst, entriesForAddition );
    } catch ( SVNException svne ) {
      svne.printStackTrace();
    } catch ( IOException e ) {
      e.printStackTrace();
    }
    //delete temp checkout dir
    try {
      delete ( dst );
      log ( "Removed temp dir: " + dst );
    } catch ( IOException e ) {
      log ( e.getMessage() );
      e.printStackTrace();
    }
  }
  
    
  private static void delete ( File f ) throws IOException {
    if ( f == null )
      return;
    if ( f.isDirectory() ) {
      for ( File c : f.listFiles() )
        delete ( c );
    }
    if ( !f.delete() )
      throw new FileNotFoundException ( "Failed to delete file: " + f );
  }



  private static void addEntryRecursive ( String repo, String dir, File dst, List<Entry> entries ) throws IOException {
    File[] files = dst.listFiles();
    if ( files != null ) { // Either dir does not exist or is not a directory
      String content =null, contentFixed =null;
      for ( File f : files ) {
        if ( f.isDirectory() ) {
          if ( !f.getName().equals ( ".svn" ) ) {
            log ( "dir: "+f.getName() );
            addEntryRecursive ( repo,dir+f.getName() +"/",f,entries );
          }
        } else {
          boolean isBinFile = true;
          Entry c = Entry._static_createEmpty_();
          c.setNameNoEventsOrValidation ( f.getName() );
          c.setUrlNoEventsOrValidation ( fixUrl ( repo+dir+f.getName() ) );
          if ( !hasBinaryFileExtension ( f.getName() ) ) {
            //We use a File property instead of String property
            //to workaround encoding exceptions.
            utils.File webdslFile = new utils.File();
            FileInputStream in = null;
            try {
              in = new FileInputStream ( f );
              webdslFile.setContentStream ( in );
              long size = webdslFile.getSizeInBytes();
              if(size < 1024*1024) {
                content = webdslFile.getContentAsString();
                contentFixed = fixEncoding ( content );
                isBinFile = ( contentFixed.length() < 1 && !contentFixed.equals ( content ) ) ;
              }
            } catch ( IOException ex ) {
              log ( ex.getMessage() );
              ex.printStackTrace();
            } finally {
              try {
                if ( in != null )
                  in.close();
              } catch ( java.io.IOException ex ) {
                log ( "file close exception during getFile reposearch:" );
                ex.printStackTrace();
              }
            }
          }
          if ( isBinFile ) {
            c.setContentNoEventsOrValidation ( addLines ( "BINFILE" ) );
          } else {
            c.setContentNoEventsOrValidation ( addLines ( contentFixed ) );
          }
          entries.add ( c );
        }
      }
    }
  }

  private static String fixUrl ( String url ) {
    if ( url.startsWith ( "https://github.com/" ) ) {
      //fix file link for github
      return url.replaceAll ( ".com/([^/]+/[^/]+)/trunk/", ".com/$1/blob/master/" ).replaceAll ( ".com/([^/]+/[^/]+)/(tags|branch)/([^/]+)/", ".com/$1/blob/$3/" );
    }
    //else
    return url;
  }


  private static void getFile ( String path, SVNRepository repository, List<Entry> entries ) throws SVNException {
    String url = repository.getRepositoryRoot ( false ).toString() + repository.getRepositoryPath ( path );
    String fileName = url.substring ( url.lastIndexOf ( '/' ) +1 );
    String content = null, contentFixed = null;
    boolean isBinFile = true;
    Entry c = Entry._static_createEmpty_();
    c.setNameNoEventsOrValidation ( fileName );
    c.setUrlNoEventsOrValidation ( fixUrl ( url ) );
    if ( ! hasBinaryFileExtension ( fileName ) ) {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      if ( repository.checkPath ( path, latestRevision ).equals ( SVNNodeKind.NONE ) ) {
        log ( "Failed to download (possibly deleted) file: " + url );
        return;
      }
      repository.getFile ( path, latestRevision, null, out );
      //Use utils.File as container for converting to String with proper encoding
      utils.File webdslFile = new utils.File();
      ByteArrayInputStream in = null;
      try {
        in = new ByteArrayInputStream ( out.toByteArray() );
        webdslFile.setContentStream ( in );
        long size = webdslFile.getSizeInBytes();
        if(size < 1024*1024) {
          content = webdslFile.getContentAsString();
          contentFixed = fixEncoding ( content );
          isBinFile = ( contentFixed.length() < 1 && !contentFixed.equals ( content ) ) ;
        }
      } catch ( IOException ex ) {
        log ( ex.getMessage() );
        ex.printStackTrace();
      } finally {
        try {
          if ( in != null )
            in.close();
          if ( out != null )
            out.close();
        } catch ( java.io.IOException ex ) {
          log ( "file close exception during getFile reposearch:" );
          ex.printStackTrace();
        }
      }
    }
    if ( isBinFile ) {
      c.setContentNoEventsOrValidation ( addLines ( "BINFILE" ) );
    } else {
      c.setContentNoEventsOrValidation ( addLines ( contentFixed ) );
    }
    entries.add ( c );
  }


  private static boolean hasBinaryFileExtension ( String fileName ) {
    return ( fileName.endsWith ( ".zip" )
             ||fileName.endsWith ( ".tbl" )
             ||fileName.endsWith ( ".png" )
             ||fileName.endsWith ( ".jpg" )
             ||fileName.endsWith ( ".bmp" )
             ||fileName.endsWith ( ".jar" )
             ||fileName.endsWith ( ".stxlib" )
           );
  }

  /*
   * Initializes the library to work with a repository via
   * different protocols.
   */
  private static void setupLibrary() {
    /*
     * For using over http:// and https://
     */
    DAVRepositoryFactory.setup();
    /*
     * For using over svn:// and svn+xxx://
     */
    SVNRepositoryFactoryImpl.setup();
    /*
     * For using over file:///
     */
    FSRepositoryFactory.setup();
  }

  private static String addLines ( String content ) {
    content = content.replaceAll ( "\n\r|\r\n|\r", "\n" );
    String[] lines = content.split ( "\n" );
    StringBuilder sb = new StringBuilder();
    int cnt = 1;
    for ( String line : lines ) {
      sb.append ( cnt++ + " " + line + "\n" );
    }
    return sb.toString().trim();
  }

  public static String fixEncoding ( String input ) {
    try {
      int errors = 0;
      byte[] bytes = input.getBytes ( "UTF-8" );
      for ( int pos = 0; pos < bytes.length; pos++ ) {
        if ( ( bytes[pos] & 0x80 ) != 0 ) {
          bytes[pos] = ( byte ) '?';
          if ( errors++ > 100 ) {
            return "";
          }
        }
      }
      if ( errors > 0 )
        return new String ( bytes );
      else
        return input;
    } catch ( UnsupportedEncodingException e ) {
      // Impossible, throw unchecked
      throw new IllegalStateException ( "No Latin1 or UTF-8: " + e.getMessage() );
    }
  }

  public static void log ( String msg ) {
    Logger.info ( msg );
    try {
      lock.tryLock ( 3, TimeUnit.SECONDS );
      logBuilder.append ( new java.util.Date() );
      logBuilder.append ( ": " );
      logBuilder.append ( msg );
      logBuilder.append ( "\n" );
    } catch ( InterruptedException e ) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    } finally {
      lock.unlock();
    }
  }
  public static String getLog() {
    String toReturn = null;
    try {
      lock.tryLock ( 3, TimeUnit.SECONDS );
      if ( logBuilder.length() < 1 )
        toReturn = "";
      else
        toReturn = logBuilder.toString();
      logBuilder = new StringBuilder();
    } catch ( InterruptedException e ) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    } finally {
      lock.unlock();
    }
    return toReturn;
  }
}
