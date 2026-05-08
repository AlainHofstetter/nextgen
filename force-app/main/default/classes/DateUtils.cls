/**
 * @description
 *   Utility class for date formatting. Provides methods to convert standard Salesforce Date
 *   objects into human-readable string formats in the German language.
 */
public class DateUtils {
    /**
     * @description
     *   Formats a given Date into a German date format string.
     *   The output format is "dd. MMMM yyyy", for example: "25. Dezember 2024".
     *
     * @param d The Date value to be formatted.
     * @return A string representing the formatted date in German, or an empty string if the input is null.
     *
     * @example
     *   DateUtils.formatDateInGerman(Date.newInstance(2024, 12, 25)) 
     *   returns "25. Dezember 2024"
     * 
     * @unit test
     *   DateUtilsTest
     */
    public static String formatDateInGerman(Date d) {
        if (d == null) {
            return '';
        }
        // Define German month names
        List<String> months = new List<String>{
            'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
            'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
        };
        
        // Format the date
        String day = String.valueOf(d.day());
        String month = months[d.month() - 1];
        String year = String.valueOf(d.year());
        
        return day + '. ' + month + ' ' + year;
    }
}