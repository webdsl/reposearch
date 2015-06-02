package org.webdsl.reposearch.tools;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.StringUtils;

public class CodeFormatter {
  
  private static final Pattern OPEN_PATTERN = Pattern.compile( "(\\S?)(\\s*)(\\{|(<[^/]+>))\\s*$" );
  private static final Pattern SHOULD_REMOVE_INDENT_PATTERN= Pattern.compile("(^[^\\{\"]*\\})|(^[^<\"]*</)");
  private static final Pattern SHOULD_INDENT_PATTERN= Pattern.compile("(\\{[^\\}]*$)|(^\\s*<([^!/]*)>[^<]*)$");
  
  public static String format(String input, boolean openOnNewLine, boolean whiteSpaceBeforeOpen, String indentChars){
    String[] lines = input.split( "\\r?\\n" );
    List<String> formatted = new ArrayList<String>();
    String currentIndent="";    
    String replacement = openOnNewLine ? "$1\n$3" : (whiteSpaceBeforeOpen ? "$1 $3" : "$1$3");

    
    for ( String line : lines ) {
      boolean shouldAddLevel = false;
      String lineNoComment = line.replaceAll("(//.*)||(/\\*[^\\*]*)","");
      if(SHOULD_REMOVE_INDENT_PATTERN.matcher(lineNoComment).find() && currentIndent.length() > 0){
        currentIndent = currentIndent.substring( 0, currentIndent.length() - indentChars.length() );
      }
      line = line.trim();
      Matcher m2 = SHOULD_INDENT_PATTERN.matcher( lineNoComment );
      if(m2.find()){
        if(m2.group(3) == null || !m2.group(3).matches( "(area|base|br|col|command|embed|hr|img|input|keygen|link|meta|param|source|track|wbr).*" )){
          shouldAddLevel = true;
          Matcher m = OPEN_PATTERN.matcher( line );
          line = m.replaceAll( replacement );
          if(openOnNewLine){ line = line.replaceAll("\n", "\n"+currentIndent); }
        }        
      }
      formatted.add( currentIndent + line );
      
      if(shouldAddLevel){
        currentIndent += indentChars;
      }
      
    }
        
    return StringUtils.join( formatted, "\n" );
  }
  
}

