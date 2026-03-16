@IsTest
private class TestDateRange {

  @IsTest
  private static void testIsInBetween() {
    Date today = System.today();
    String dateFrom = '2017-01-10';
    String dateTo = Utils.formatDate(today, 'yyyy-MM-dd');

    DateRange dr = new DateRange(dateFrom, dateTo);

    System.assert(dr.isInBetween(today));
  }

}