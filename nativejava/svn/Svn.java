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

    public static RepoCheckout getFilesIfNew(String user,String repo, long rev) {
        return getFilesIfNew("https://github.com/"+user+"/"+repo, rev);
    }
    public static RepoCheckout getFiles(String user,String repo) {
        return getFiles("https://github.com/"+user+"/"+repo);
    }

    private static final long latestRevision = -1;

    public static RepoCheckout getFiles(String repo) {
        return getFilesIfNew(repo, -10);
    }

    //returns: RepoCheckout object with:
    //- non-null file list if newer revision is available and files are checked out
    //- null file list when given revision (rev) is newest
    public static RepoCheckout getFilesIfNew(String repoUrl, long rev) {
        String url = repoUrl;

        setupLibrary();
        SVNRepository repository = null;
        try {
            repository = SVNRepositoryFactory.create(SVNURL.parseURIEncoded(url));

            //long headRevRepoRoot = repository.getLatestRevision();
            long headRevRepoUrl = repository.getDir("", latestRevision, true, null).getRevision();

            if (rev >= headRevRepoUrl) {
                System.out.println("Skipped checkout for repo: " + repoUrl + ". This one is already at head revision");
                return new RepoCheckout(null, headRevRepoUrl);
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

            return new RepoCheckout(list, headRevRepoUrl);
        } catch (SVNException svne) {
            svne.printStackTrace();
            return null;
        }
    }


    private static void addEntryRecursive(String dir,SVNRepository repo,List<Entry> list) throws SVNException{
        SVNProperties props = null;
        Collection<?> nullcol = null;
        System.out.println("Reposearch getdir: " + repo.getLocation().getPath() + "/" + dir);
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
                    c.setContentNoEventsOrValidation(addLines("BINFILE"));

                } else {
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