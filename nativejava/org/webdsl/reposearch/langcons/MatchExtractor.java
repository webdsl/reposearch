package org.webdsl.reposearch.langcons;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MatchExtractor {
  public static final String SEP = " ";
  public static final String INFIX = "#MATCH#";
  public static String extract ( webdsl.generated.domain.LangConstruct langCons, String text ) {
    try {
      Matcher matcher = getMatcher ( langCons.getPattern(), langCons.getCaseSensitive(), text );
      String prefix = getPrefix ( langCons.getName() );
      StringBuffer sb = new StringBuffer();
      while ( matcher.find() ) {
        sb.append ( prefix );
        sb.append ( matcher.group ( langCons.getGroup() ) );
      }
      return sb.toString();
    } catch ( Exception ex ) {
      ex.printStackTrace();
      return "";
    }
  }

  public static String decorateMatches ( webdsl.generated.domain.LangConstruct langCons, String text, String queryTerm ) {
    Matcher matcher = getMatcher ( langCons.getPattern(), langCons.getCaseSensitive(), text );
    String currentMatchTerm, currentReplacement;
    StringBuffer sb = new StringBuffer();
    while ( matcher.find() ) {
      currentMatchTerm = matcher.group ( langCons.getGroup() );
      //now, only replace instances for query matches
      if ( currentMatchTerm.equalsIgnoreCase ( queryTerm ) ) {
        currentReplacement = matcher.group().replace ( currentMatchTerm, getPrefix ( langCons.getName() ) + matcher.group ( langCons.getGroup() ) + SEP );
      } else {
        currentReplacement = matcher.group();
      }
      matcher.appendReplacement ( sb, currentReplacement );
    }
    matcher.appendTail ( sb );
    return sb.toString();
  }

  private static String getPrefix ( String patternName ) {
    return SEP + patternName.replaceAll ( " ", "_" ) + INFIX;
  }

  private static Matcher getMatcher ( String pattern, boolean caseSensitive, String text ) {
    Pattern p = caseSensitive ? Pattern.compile ( pattern ) : Pattern.compile ( pattern, Pattern.CASE_INSENSITIVE );
    return p.matcher ( text );
  }
}
