package svn;

import java.util.List;

import webdsl.generated.domain.*;

public class RepoCheckout {
    private List<Entry> entries;
    private long revision;
    public RepoCheckout(List<Entry> entries, long revision){
        this.entries = entries;
        this.revision = revision;
    }

    public long getRevision(){
        return revision;
    }
    public List<Entry> getEntries(){
        return entries;
    }

}
