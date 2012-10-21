package regex;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import svn.Svn;

public class MatchExtractor {
    public static final String SEP = " ";
    public static final String INFIX = "#MATCH#";
    public static String extract(String patternName, String pattern, int group, boolean caseSensitive, String text){
        try{
            Matcher matcher = getMatcher(patternName, pattern, group, caseSensitive, text);
            String prefix = getPrefix( patternName );
            StringBuffer sb = new StringBuffer();

            while(matcher.find()){

                sb.append(prefix);
                sb.append(matcher.group(group));
            }

            return sb.toString();
        } catch( Exception ex) {
            ex.printStackTrace();
            return "";
        }

    }

    public static String replaceAll(String patternName, String pattern, int group, boolean caseSensitive, String text){
        Matcher matcher = getMatcher(patternName, pattern, group, caseSensitive, text);

        String currentMatch, currentReplacement;
        StringBuffer sb = new StringBuffer();
        while(matcher.find()){
            currentMatch = matcher.group();
            currentReplacement = currentMatch.replace(matcher.group(group), getPrefix( patternName ) + matcher.group(group) + SEP);
            matcher.appendReplacement(sb, currentReplacement);
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    private static String getPrefix(String patternName){
        return SEP + patternName + INFIX;
    }

    private static Matcher getMatcher(String patternName, String pattern, int group, boolean caseSensitive, String text){
        Pattern p = caseSensitive ? Pattern.compile( pattern ) : Pattern.compile( pattern, Pattern.CASE_INSENSITIVE);
        return p.matcher( text );
    }
}
