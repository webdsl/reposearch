package svn;


import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import org.tmatesoft.svn.core.SVNDirEntry;
import org.tmatesoft.svn.core.SVNErrorMessage;
import org.tmatesoft.svn.core.SVNException;
import org.tmatesoft.svn.core.SVNLogEntry;
import org.tmatesoft.svn.core.SVNNodeKind;
import org.tmatesoft.svn.core.SVNProperties;
import org.tmatesoft.svn.core.SVNURL;
import org.tmatesoft.svn.core.internal.io.dav.DAVRepositoryFactory;
import org.tmatesoft.svn.core.internal.io.fs.FSRepositoryFactory;
import org.tmatesoft.svn.core.internal.io.svn.SVNRepositoryFactoryImpl;
import org.tmatesoft.svn.core.io.SVNRepository;
import org.tmatesoft.svn.core.io.SVNRepositoryFactory;

import webdsl.generated.domain.*;

public class Svn {

    public static void main(String[] args){
        String repo = "https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/";
        for(Entry c: getFiles(repo)){
            System.out.println(c);
        }
        /*
        for(Commit c: getCommits(repo)){
            System.out.println(c);
        }
        */
    }
    
    public static List<Commit> getCommits(String repo) {
        String url = repo;

        setupLibrary();
        SVNRepository repository = null;
        try {
            repository = SVNRepositoryFactory.create(SVNURL.parseURIEncoded(url));

            SVNNodeKind nodeKind = repository.checkPath("", -1);
            
            if (nodeKind == SVNNodeKind.NONE) {
                System.err.println("There is no entry at '" + url + "'.");
                throw new SVNException(SVNErrorMessage.UNKNOWN_ERROR_MESSAGE);
            } else if (nodeKind == SVNNodeKind.FILE) {
                System.err.println("The entry at '" + url + "' is a file while a directory was expected.");
                throw new SVNException(SVNErrorMessage.UNKNOWN_ERROR_MESSAGE);
            }

            long latestRevision = -1;
            latestRevision = repository.getLatestRevision();
            
            //long oldrev = 0;
            long oldrev = latestRevision - 10;
            //max(latestRevision - 10,0);
            
            @SuppressWarnings("rawtypes")
            Collection col = repository.log(null, null, latestRevision, oldrev, false, false);
            @SuppressWarnings("rawtypes")
            Iterator i = col.iterator();
            System.out.println(i.hasNext());
            List<Commit> list = new ArrayList<Commit>();
            while(i.hasNext()){
                SVNLogEntry o = (SVNLogEntry) i.next();
                System.out.println(o);
                Commit c = new Commit();
                list.add(c);
                c.setRevNoEventsOrValidation(o.getRevision());
                c.setAuthorNoEventsOrValidation(o.getAuthor());
                c.setMessageNoEventsOrValidation(o.getMessage());
                c.setDateNoEventsOrValidation(o.getDate());
            }

            return list;
        } catch (SVNException svne) {
            svne.printStackTrace();
            return null;
        }
    }
    
    private static final long latestRevision = -1;
    
    public static List<Entry> getFiles(String repo) {
        String url = repo;

        setupLibrary();
        SVNRepository repository = null;
        try {
            repository = SVNRepositoryFactory.create(SVNURL.parseURIEncoded(url));

            SVNNodeKind nodeKind = repository.checkPath("", -1);
            
            if (nodeKind == SVNNodeKind.NONE) {
                System.err.println("There is no entry at '" + url + "'.");
                throw new SVNException(SVNErrorMessage.UNKNOWN_ERROR_MESSAGE);
            } else if (nodeKind == SVNNodeKind.FILE) {
                System.err.println("The entry at '" + url + "' is a file while a directory was expected.");
                throw new SVNException(SVNErrorMessage.UNKNOWN_ERROR_MESSAGE);
            }

            List<Entry> list = new ArrayList<Entry>();
            addEntryRecursive("",repository,list);

            return list;
        } catch (SVNException svne) {
            svne.printStackTrace();
            return null;
        }
    }
    
    
    private static void addEntryRecursive(String dir,SVNRepository repo,List<Entry> list) throws SVNException{
        SVNProperties props = null;
        Collection<?> nullcol = null;
        System.out.println("getDir: "+dir);
        Collection<?> col = repo.getDir(dir, latestRevision, props, nullcol);
        @SuppressWarnings("rawtypes")
        Iterator i = col.iterator();
        //System.out.println(i.hasNext());
        while(i.hasNext()){
            SVNDirEntry o = (SVNDirEntry) i.next();
            //System.out.println(o.getName());
            //System.out.println(o.getKind());
            if(o.getKind()==SVNNodeKind.DIR){
                //System.out.println("dir: "+o.getName());
                addEntryRecursive(dir+o.getName()+"/",repo,list);
            }
            else{
                if(  o.getName().endsWith(".zip")
                   ||o.getName().endsWith(".tbl")		
                   ||o.getName().endsWith(".png")		
                   ||o.getName().endsWith(".jpg")		
                   ||o.getName().endsWith(".bmp")		
                   ||o.getName().endsWith(".jar")){break;}
                //System.out.println("file: "+o.getName());
                Entry c = new Entry();
                list.add(c);
                c.setNameNoEventsOrValidation(o.getName());
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                repo.getFile(dir+o.getName(), latestRevision, null, out);
                c.setContentNoEventsOrValidation(out.toString());
                c.setUrlNoEventsOrValidation(o.getURL().toString());
            }
        }
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
}