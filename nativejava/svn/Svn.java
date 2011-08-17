package svn;


import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.io.FileUtils;
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
import org.tmatesoft.svn.core.wc.SVNClientManager;
import org.tmatesoft.svn.core.wc.SVNRevision;
import org.tmatesoft.svn.core.wc.SVNUpdateClient;

import com.google.common.io.Files;

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
    
    public static List<Entry> checkoutSvn(String repo1) {
        return checkout(repo1,null);
    }
    public static List<Entry> checkoutGithub(String user,String repo) {
        return checkout("http://svn.github.com/"+user+"/"+repo+".git",
                        "https://github.com/"+user+"/"+repo+"/blob/master/");
    }
    public static List<Entry> checkout(String repo1, String repo2) {
        if(repo2==null){
            repo2=repo1;
        }
        setupLibrary();
        File dst;
        List<Entry> list;
        try {
            dst = Files.createTempDir();
            System.out.println("temp dir: " + dst);
            SVNURL svnurl = SVNURL.parseURIEncoded(repo1);

            SVNClientManager cm = SVNClientManager.newInstance();
            SVNUpdateClient uc = cm.getUpdateClient();
            
            uc.doCheckout(svnurl, dst, SVNRevision.UNDEFINED, SVNRevision.HEAD, true);

            list = new ArrayList<Entry>();
            
            if(!repo2.endsWith("/")){
                repo2 = repo2+"/";
            }
            addEntryRecursive(repo2,"",dst,list);

        } catch (SVNException svne) {
            svne.printStackTrace();
            return null;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        //ignore failed delete
        try {
            //Files.deleteRecursively(dst);  //fails
            FileUtils.deleteDirectory(dst);	
        } catch (IOException e) {
            System.out.println(e.getMessage());
            e.printStackTrace();
        }

        return list;
    }

    private static void addEntryRecursive(String repo, String dir, File dst, List<Entry> list) throws IOException{
        File[] files = dst.listFiles();
        if (files != null) { // Either dir does not exist or is not a directory
            for (File f : files) {
               // System.out.println("file name: "+f.getName());
                //System.out.println(f.getAbsolutePath());
                if(f.isDirectory()){
                    if(!f.getName().equals(".svn")){
                        System.out.println("dir: "+f.getName());
                        addEntryRecursive(repo,dir+f.getName()+"/",f,list);
                    }
                }
                else{
                    if(!(f.getName().endsWith(".zip")
                            ||f.getName().endsWith(".tbl")		
                            ||f.getName().endsWith(".png")		
                            ||f.getName().endsWith(".jpg")		
                            ||f.getName().endsWith(".bmp")		
                            ||f.getName().endsWith(".jar"))){
                        Entry c = new Entry();
                        list.add(c);
                        c.setNameNoEventsOrValidation(f.getName());
                        //System.out.println("file name: "+f.getName());
                        c.setContentNoEventsOrValidation(Files.toString(f,Charset.defaultCharset()));
                        //System.out.println("file contents: "+Files.toString(f,Charset.defaultCharset()));
                        c.setUrlNoEventsOrValidation(repo+dir+f.getName());
                        //System.out.println("file url: "+repo+dir+f.getName());
                    }
                }
            }
        }
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