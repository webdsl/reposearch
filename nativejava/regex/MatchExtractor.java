package regex;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MatchExtractor {
    public static final String SEP = "#NEWITEM#";
    public static final String INFIX = "#MATCH#";
    public static String extract(String patternName, String pattern, int group, boolean caseSensitive, String text){
        String prefix = SEP + patternName + INFIX;
        Pattern p = caseSensitive ? Pattern.compile( pattern ) : Pattern.compile( pattern, Pattern.CASE_INSENSITIVE);
        Matcher matcher = p.matcher( text );
        StringBuffer sb = new StringBuffer();

        while(matcher.find()){
            sb.append(prefix);
            sb.append(matcher.group(group));
        }

        return sb.toString();

    }

    public static String replaceAll(String patternName, String pattern, int group, boolean caseSensitive, String text){

    }

    private static void log(String str){
        System.out.println(str);
    }
}
