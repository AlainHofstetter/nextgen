/*
*	@description Test class for QuoteHandler functionality.
*
*	@author ach
*	@copyright PARX
*/
@isTest
public with sharing class QuoteHandlerTest
{
	/*
	*	@description Test trigger functionality.
	*/
	static testMethod void testMainFunctionality()
	{
		Id pricebookId = Test.getStandardPricebookId();
		Pack__c pack = TestFactory.createPackage(pricebookId);
		Account acc = TestFactory.createAccount();
		Opportunity opp = TestFactory.createOpportunity(acc, pricebookId);
		Quote quote = TestFactory.createQuote(opp);
		Quote_Package__c quotePackage = TestFactory.createQuotePackage(quote, pack);
		OpportunityPackage__c oppPackage = TestFactory.createOpportunityPackage(opp, pack); 
		List<Product2> products = new List<Product2>{TestFactory.createProduct(false), TestFactory.createProduct(false), 
					TestFactory.createProduct(false), TestFactory.createProduct(false)};
		insert products;

		List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
			TestFactory.createQuoteLineItem(quote, products[0], false),
			TestFactory.createQuoteLineItem(quote, products[1], false)
		};
		quoteLineItems[0].Quote_Package__c = quotePackage.Id;
		quoteLineItems[1].Quote_Package__c = quotePackage.Id;
		insert quoteLineItems;

		List<OpportunityLineItem> oppLineItems = new  List<OpportunityLineItem>{
			TestFactory.createOppLineItem(opp, products[2], false),
			TestFactory.createOppLineItem(opp, products[3], false)
		};
		oppLineItems[0].OpportunityPackage__c = oppPackage.Id;
		oppLineItems[1].OpportunityPackage__c = oppPackage.Id;
		insert oppLineItems;
		
		Test.startTest();
		quote.Start_sync__c = true;
		update quote;
		Test.stopTest();
		//deleteOppProducts()
		oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE Id =:oppLineItems[0].Id OR Id =:oppLineItems[1].Id];
		System.assertEquals(0, oppLineItems.size(), 'Wrong number of oppLineItems: we expect that old items were deleted.');
		
		//deleteOppPackages()
		List<OpportunityPackage__c> oppPackages = [SELECT Id FROM OpportunityPackage__c WHERE Id =:oppPackage.Id];
		System.assertEquals(0, oppPackages.size(), 'Wrong number of oppPackages: we expect that old items were deleted.');

		//copyQuotePackage()
		oppPackages = [SELECT Id, BundlePackage__c, Opportunity__c, Quote_Package__c FROM OpportunityPackage__c];
		System.assertEquals(1, oppPackages.size(), 'Wrong number of generated OpportunityPackage__c records: we should have new record per every Quote_Package__c ');
		System.assertEquals(quotePackage.Bundle_Package__c, oppPackages[0].BundlePackage__c, 'Wrong BundlePackage__c value');
		System.assertEquals(opp.Id, oppPackages[0].Opportunity__c, 'Wrong Opportunity__c value');
		System.assertEquals(quotePackage.Id, oppPackages[0].Quote_Package__c, 'Wrong Quote_Package__c value');

		//copyQLiProducts()
		oppLineItems = [SELECT Id, Quantity, OpportunityId, OpportunityPackage__c FROM OpportunityLineItem];
		System.assertEquals(2, oppLineItems.size(), 'Wrong number of generated OpportunityLineItem records: we should have new record per every QuoteLineItem ');
		for (OpportunityLineItem item : oppLineItems)
		{
			System.assertEquals(opp.Id, item.OpportunityId, 'Wrong OpportunityId value');
			System.assertEquals(1, item.Quantity, 'Wrong Quantity value');
			System.assertEquals(oppPackages[0].Id, item.OpportunityPackage__c, 'Wrong OpportunityId value');
		}
	}
}