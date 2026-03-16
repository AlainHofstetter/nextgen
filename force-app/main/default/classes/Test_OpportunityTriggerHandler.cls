/*
*	@description Test class for OpportunityTriggerHandler functionality.
*
*	@author ach
*	@copyright PARX
*/
@isTest
public with sharing class Test_OpportunityTriggerHandler
{
	/**
	*	Init opportunity.
	*/
	private static Opportunity initOpportunity()
	{
		Opportunity aResult = new Opportunity(Name ='asd', Amount = 150000, Probability = 20, ProjectStart__c = Date.newInstance(2014, 08, 02),
				ProjectEnd__c = Date.newInstance(2014, 10, 10), DailyRate__c = 100, StageName = 'Potential', CloseDate = System.today().addYears(10));
		return aResult;
	}
	
	/**
	*	Init opportunity.
	*/
	private static Opportunity initOpportunity2()
	{
		Opportunity aResult = new Opportunity(Name ='asd', Amount = 150000, Probability = 20, ProjectStart__c = Date.newInstance(2014, 01, 01),
				ProjectEnd__c = Date.newInstance(2014, 01, 10), DailyRate__c = 1500, StageName = 'Potential', 
				CloseDate = System.today().addYears(10), CurrencyIsoCode = 'EUR');
		return aResult;
	}
	
	/*
	*	@description Check calculation.
	*/
	static testMethod void testCalculationProcess()
	{
		Opportunity anOpportunity = initOpportunity2();
		Test.startTest();
		insert anOpportunity;
		List<ResourceForecast__c> aForeCasts = [SELECT ID, Amount__c, DateFirstDayOfMonth__c, Days__c,
				ExpectedDays__c, ExpectedRevenue__c, CurrencyIsoCode FROM ResourceForecast__c];
		Test.stopTest();
		System.assertEquals(1, aForeCasts.size(), 'wrong number of created forecasts');
		System.assertEquals( 150000 , aForeCasts[0].Amount__c, 'wrong Amount__c');
		System.assertEquals(Date.newInstance(2014, 01, 01), aForeCasts[0].DateFirstDayOfMonth__c, 'wrong DateFirstDayOfMonth__c');
		System.assertEquals(100, aForeCasts[0].Days__c, 'wrong Days__c');
		System.assertEquals(20, aForeCasts[0].ExpectedDays__c, 'wrong ExpectedDays__c');
		System.assertEquals(30000, aForeCasts[0].ExpectedRevenue__c, 'wrong ExpectedRevenue__c');
		System.assertEquals('EUR', aForeCasts[0].CurrencyIsoCode, 'wrong CurrencyIsoCode');
	}
	
	/*
	*	@description Delete opportunity and check the forecars.
	*/
	static testMethod void testDeleteOpportunity()
	{
		Opportunity anOpportunity = initOpportunity();
		insert anOpportunity;
		List<ResourceForecast__c> aForeCasts = [SELECT ID FROM ResourceForecast__c];
		System.assertEquals(3, aForeCasts.size(), 'wrong number of created forecasts');
		
		Test.startTest();
		delete anOpportunity;
		Test.stopTest();
		aForeCasts = [SELECT ID FROM ResourceForecast__c];
		System.assertEquals(0, aForeCasts.size(), 'wrong number of created forecasts');
	}
	
	/*
	*	@description Clear important field: expect, that all forecasts where deleted.
	*/
	static testMethod void testClearImportantFields()
	{
		Opportunity anOpportunity = initOpportunity();
		insert anOpportunity;
		List<ResourceForecast__c> aForeCasts = [SELECT ID FROM ResourceForecast__c];
		System.assertEquals(3, aForeCasts.size(), 'wrong number of created forecasts');
		
		Test.startTest();
		anOpportunity.ProjectEnd__c = null;
		update anOpportunity;
		Test.stopTest();
		aForeCasts = [SELECT ID FROM ResourceForecast__c];
		System.assertEquals(0, aForeCasts.size(), 'wrong number of created forecasts');
	}
	
	/*
	*	@description Clear Not important field: expect, that all forecasts where deleted.
	*/
	static testMethod void testClearNotImportantFields()
	{
		Opportunity anOpportunity = initOpportunity();
		insert anOpportunity;
		List<ResourceForecast__c> aForeCasts = [SELECT ID, Days__c, ExpectedDays__c FROM ResourceForecast__c];
		System.assertEquals(3, aForeCasts.size(), 'wrong number of created forecasts');
		System.assertNotEquals(null, aForeCasts[0].Days__c, 'Days__c field should be defined');
		System.assertNotEquals(null, aForeCasts[0].ExpectedDays__c, 'ExpectedDays__c field should be defined');
		
		Test.startTest();
		anOpportunity.DailyRate__c = null;
		update anOpportunity;
		Test.stopTest();
		aForeCasts = [SELECT ID, Days__c, ExpectedDays__c FROM ResourceForecast__c];
		System.assertEquals(3, aForeCasts.size(), 'wrong number of created forecasts');
		System.assertEquals(null, aForeCasts[0].Days__c, 'Days__c field should be empty');
		System.assertEquals(null, aForeCasts[0].ExpectedDays__c, 'ExpectedDays__c field should be empty');
	}
}