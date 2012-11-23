package svn;

import java.util.List;

import webdsl.generated.domain.*;

public class RepoTaskResult {
  private List<Entry> entriesForAddition;
  private List<String> entriesForRemoval;
  private long revision;
  public RepoTaskResult ( List<Entry> entriesForAddition, List<String> entriesForRemoval, long revision ) {
    this.entriesForAddition = entriesForAddition;
    this.entriesForRemoval = entriesForRemoval;
    this.revision = revision;
  }

  public long getRevision() {
    return revision;
  }
  public List<Entry> getEntriesForAddition() {
    return entriesForAddition;
  }
  public List<String> getEntriesForRemoval() {
    return entriesForRemoval;
  }
}

