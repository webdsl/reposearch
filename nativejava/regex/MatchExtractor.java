package regex;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MatchExtractor {
    public static final String SEP = " ";
    public static final String INFIX = "#MATCH#";
    public static String extract(String patternName, String pattern, int group, boolean caseSensitive, String text){
        try{
            Matcher matcher = getMatcher(pattern, caseSensitive, text);
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

    public static String decorateMatches(webdsl.generated.domain.Pattern pattern, String text, String queryTerm){
        Matcher matcher = getMatcher(pattern.getPattern(), pattern.getCaseSensitive(), text);

        String currentMatchTerm, currentReplacement;
        StringBuffer sb = new StringBuffer();
        while(matcher.find()){
            currentMatchTerm = matcher.group(pattern.getGroup());
            //now, only replace instances for query matches
            if ( currentMatchTerm.equalsIgnoreCase( queryTerm ) ) {
                currentReplacement = matcher.group().replace(currentMatchTerm, getPrefix( pattern.getName() ) + matcher.group( pattern.getGroup() ) + SEP);
            } else {
                currentReplacement = matcher.group();
            }
            matcher.appendReplacement(sb, currentReplacement);
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    private static String getPrefix(String patternName){
        return SEP + patternName.replaceAll(" ", "_") + INFIX;
    }

    private static Matcher getMatcher(String pattern, boolean caseSensitive, String text){
        Pattern p = caseSensitive ? Pattern.compile( pattern ) : Pattern.compile( pattern, Pattern.CASE_INSENSITIVE);
        return p.matcher( text );
    }
}
