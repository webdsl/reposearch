package svn;


import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
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

import webdsl.generated.domain.Commit;
import webdsl.generated.domain.Entry;

import com.google.common.io.Files;

public class Svn {
    public static void main(String[] args){
        String repo = "https://svn.strategoxt.org/repos/WebDSL/webdsls/trunk/";
        for(Entry c: getFiles(repo).getEntries()){
            System.out.println(c);
        }
        /*
        for(Commit c: getCommits(repo)){
            System.out.println(c);
        }
        */
    }

    public static RepoCheckout checkoutSvn(String repo1) {
        return checkout(repo1,null);
    }
    public static RepoCheckout checkoutGithub(String user,String repo) {
        return checkout("http://svn.github.com/"+user+"/"+repo+".git",
                        "https://github.com/"+user+"/"+repo+"/blob/master/");
    }


    public static RepoCheckout checkout(String repo1, String repo2) {
        if(repo2==null){
            repo2=repo1;
        }
        setupLibrary();
        File dst;
        long revision;
        List<Entry> list;
        try {
            dst = Files.createTempDir();
            System.out.println("Checking out repo: " + repo1);
            System.out.println("temp dir: " + dst);
            SVNURL svnurl = SVNURL.parseURIEncoded(repo1);

            SVNClientManager cm = SVNClientManager.newInstance();
            SVNUpdateClient uc = cm.getUpdateClient();

            revision = uc.doCheckout(svnurl, dst, SVNRevision.UNDEFINED, SVNRevision.HEAD, true);

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

        return new RepoCheckout(list, revision);
    }

    private static void addEntryRecursive(String repo, String dir, File dst, List<Entry> list) throws IOException{
        File[] files = dst.listFiles();
        if (files != null) { // Either dir does not exist or is not a directory
            String content, contentFixed;
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
                    Entry c = new Entry();
                    list.add(c);
                    c.setNameNoEventsOrValidation(f.getName());
                    //System.out.println("file name: "+f.getName());
                    if(!(f.getName().endsWith(".zip")
                      ||f.getName().endsWith(".tbl")
                      ||f.getName().endsWith(".png")
                      ||f.getName().endsWith(".jpg")
                      ||f.getName().endsWith(".bmp")
                      ||f.getName().endsWith(".jar"))){
                        //We use a File property instead of String property
                        //to workaround encoding exceptions.
                        utils.File webdslFile = new utils.File();
                        FileInputStream fis = null;
                        try{
                            fis= new FileInputStream(f);
                            webdslFile.setContentStream(fis);
                            //c.setFileNoEventsOrValidation(webdslFile);

                            content = webdslFile.getContentAsString();
                            contentFixed = fixEncoding( content );

                            if ( contentFixed.length() < 1 && !contentFixed.equals( content ) )
                                c.setContentNoEventsOrValidation( addLines("BINFILE") );
                            else
                                c.setContentNoEventsOrValidation( addLines( contentFixed ) );

                        } finally{
                            try{
                                if(fis != null)
                                    fis.close();
                            } catch (java.io.IOException ex){
                                System.out.println("file close exception during svn checkout reposearch 1:");
                                ex.printStackTrace();
                            }
                        }
                    } else {
                        c.setContentNoEventsOrValidation("BINFILE");
                    }
                    //System.out.println("file contents: "+Files.toString(f,Charset.defaultCharset()));
                    c.setUrlNoEventsOrValidation(repo+dir+f.getName());
                    //System.out.println("file url: "+repo+dir+f.getName());
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

    public static RepoCheckout getFiles(String repo) {
        return getFilesIfNew(repo, -1);
    }

    //returns: RepoCheckout object if newer revision is available and files are checked out, null when given revision (rev) is newest
    public static RepoCheckout getFilesIfNew(String repo, long rev) {
        String url = repo;

        setupLibrary();
        SVNRepository repository = null;
        try {
            repository = SVNRepositoryFactory.create(SVNURL.parseURIEncoded(url));
            if (rev >= repository.getLatestRevision()) {
                System.out.println("Skipped checkout for repo: " + repo + ". This one is already at head revision");
                return new RepoCheckout(null, repository.getLatestRevision());
            }

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

            return new RepoCheckout(list, repository.getLatestRevision());
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
        String content, contentFixed;
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
                //System.out.println("file: "+o.getName());
                Entry c = new Entry();
                list.add(c);
                c.setNameNoEventsOrValidation(o.getName());
                if(  o.getName().endsWith(".zip")
                ||o.getName().endsWith(".tbl")
                ||o.getName().endsWith(".png")
                ||o.getName().endsWith(".jpg")
                ||o.getName().endsWith(".bmp")
                ||o.getName().endsWith(".jar")) {
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    repo.getFile(dir+o.getName(), latestRevision, null, out);
                    //Use utils.File as container for converting to String with proper encoding
                    utils.File f = new utils.File();
                    ByteArrayInputStream in = null;
                    try{
                        in = new ByteArrayInputStream(out.toByteArray());
                        f.setContentStream(in);

                        content = f.getContentAsString();
                        contentFixed = fixEncoding( content );
                        if ( contentFixed.length() < 1 && !contentFixed.equals( content ) )
                            c.setContentNoEventsOrValidation( addLines("BINFILE") );
                        else
                            c.setContentNoEventsOrValidation( addLines( contentFixed ) );
                    } catch( IOException ex){
                        ex.printStackTrace();
                    } finally {
                        try{
                            if (in != null)
                                in.close();
                            if(out != null)
                                out.close();
                        } catch (java.io.IOException ex){
                            System.out.println("file close exception during svn checkout reposearch 2:");
                            ex.printStackTrace();
                        }

                    }
                } else {
                    c.setContentNoEventsOrValidation("BINFILE");
                }

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

    private static String addLines(String content){
          content = content.replaceAll("\n\r|\r\n|\r", "\n");
          String[] lines = content.split("\n");
          StringBuilder sb = new StringBuilder();
          int cnt = 1;
          for (String line : lines) {
            sb.append(cnt++ + " " + line + "\n");
          }
          return sb.toString().trim();

    }

    public static String fixEncoding(String input){
      try {
        int errors = 0;
        byte[] bytes = input.getBytes("UTF-8");
        for (int pos = 0; pos < bytes.length; pos++) {
          if ((bytes[pos] & 0x80) != 0) {
            bytes[pos] = (byte) '?';
            if (errors++ > 100){
                return "";
            }
          }
        }
        if(errors > 0)
          return new String(bytes);
        else
          return input;
      } catch (UnsupportedEncodingException e) {
        // Impossible, throw unchecked
        throw new IllegalStateException("No Latin1 or UTF-8: " + e.getMessage());
      }
    }
}