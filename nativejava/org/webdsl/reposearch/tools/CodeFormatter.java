package org.webdsl.reposearch.tools;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.StringUtils;

public class CodeFormatter {
    
  public static String format(String input, boolean openOnNewLine, boolean whiteSpaceBeforeOpen, String indentChars){
    String[] lines = input.split( "\\r?\\n" );
    List<String> formatted = new ArrayList<String>();
    String currentIndent="";
    Pattern p = Pattern.compile( "(\\S?)\\s*(\\{|(<[^/]+>))\\s*$" );
    String replacement = openOnNewLine ? "$1\n$2$3" : (whiteSpaceBeforeOpen ? "$1 $2" : "$1$2");
    Pattern closePattern= Pattern.compile("(^[^\\{\"]*\\})|(^[^<\"]*</)");
    Pattern openPattern= Pattern.compile("(\\{[^\\}]*$)|(^\\s*<[^/]*>[^<]*)$");
    
    for ( String line : lines ) {
      String lineNoComment = line.replaceAll("(//.*)||(/\\*[^\\*]*)","");
//      int opens = StringUtils.countMatches( lineNoComment, "{" );
//      int closes = StringUtils.countMatches( lineNoComment, "}" );
      if(closePattern.matcher(lineNoComment).find() && currentIndent.length() > 0){
        currentIndent = currentIndent.substring( 0, currentIndent.length() - indentChars.length() );
      }
      line = currentIndent + StringUtils.trim( line );
      Matcher m = p.matcher( line );
//      System.out.println("Before:");
//      System.out.println(line);
      line = m.replaceAll( replacement );
//      System.out.println("After:");
//      System.out.println(line);
      if(openPattern.matcher( lineNoComment ).find()){
        currentIndent += indentChars;
      }
      formatted.add( line );
    }
    
    
    
    return StringUtils.join( formatted, "\n" );
  }
  
}

