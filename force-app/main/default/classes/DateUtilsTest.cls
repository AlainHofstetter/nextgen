/**
 * @description
 *   Unit test class for DateUtils. Validates the behavior of the formatDateInGerman method,
 *   ensuring it correctly formats valid dates and handles null inputs gracefully.
 *
 * @Who:         david@inspireai.com
 * @When:        2025-07-09
 */
@isTest
private class DateUtilsTest {

    /**
     * @description
     *   Test that verifies formatDateInGerman correctly formats a valid Date value
     *   using the German date format "day. month year".
     */
    @isTest
    static void testFormatDateInGerman_withValidDate() {
        // Arrange: Set up a known date
        Date testDate = Date.newInstance(2024, 12, 25); // 25th December 2024

        // Act: Call the method under test
        String formattedDate = DateUtils.formatDateInGerman(testDate);

        // Assert: Validate the output matches the expected German date format
        System.assertEquals('25. Dezember 2024', formattedDate,
            'Formatted date should match the German date format "25. Dezember 2024"');
    }

    /**
     * @description
     *   Test that verifies formatDateInGerman handles a null Date input
     *   by returning an empty string as expected.
     */
    @isTest
    static void testFormatDateInGerman_withNullDate() {
        // Act: Call the method with a null value
        String formattedDate = DateUtils.formatDateInGerman(null);

        // Assert: Ensure the method returns an empty string
        System.assertEquals('', formattedDate,
            'Null input should return an empty string');
    }
}