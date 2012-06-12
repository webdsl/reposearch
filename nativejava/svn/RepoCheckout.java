package svn;

import java.util.List;

import webdsl.generated.domain.*;

public class RepoCheckout {
    private List<Entry> entries;
    private List<Entry> binEntries;
    private long revision;
    public RepoCheckout(List<Entry> entries, List<Entry> binEntries, long revision){
        this.entries = entries;
        this.binEntries = binEntries;
        this.revision = revision;
    }

    public long getRevision(){
        return revision;
    }
    public List<Entry> getEntries(){
        return entries;
    }
    public List<Entry> getBinEntries(){
        return binEntries;
    }

}

