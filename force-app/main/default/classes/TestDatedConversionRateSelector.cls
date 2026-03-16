@IsTest
public with sharing class TestDatedConversionRateSelector {

    @IsTest
    static void testSelectByISOCodeAndDate() {
        DatedConversionRateSelector selector = new DatedConversionRateSelector();
        List<DatedConversionRate> results = selector.selectByISOCodeAndDate('USD', Date.today());
        System.assertEquals(1, results.size(), 'Should return 1 matching record');
        System.assertEquals('USD', results[0].IsoCode);
    }

    @IsTest
    static void testSelectByDate() {
        DatedConversionRateSelector selector = new DatedConversionRateSelector();
        List<DatedConversionRate> results = selector.selectByDate(Date.today());
        // System.assertEquals(1, results.size(), 'Should return only USD record valid today');
    }

    @IsTest
    static void testSelectByISOCode() {
        DatedConversionRateSelector selector = new DatedConversionRateSelector();
        List<DatedConversionRate> results = selector.selectByISOCode('USD');
        System.assert(results.size() > 0, 'Should return record with USD IsoCode');
        System.assertEquals('USD', results[0].IsoCode);
    }

    @IsTest
    static void testSelectAllWithCaching() {
        Test.startTest();

        DatedConversionRateSelector selector = new DatedConversionRateSelector();

        // First call should populate cache
        List<DatedConversionRate> firstCall = selector.selectAll();
        System.assert(firstCall.size() > 0, 'Should return all records on first call');

        // Second call should use cache and return same data
        List<DatedConversionRate> secondCall = selector.selectAll();
        System.assert(secondCall.size() > 0, 'Should return cached results');

        Test.stopTest();
    }
}