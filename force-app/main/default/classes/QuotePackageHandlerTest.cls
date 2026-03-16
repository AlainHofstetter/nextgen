/*
*	@description Test class for QuotePackageHandler functionality.
*
*	@author ach
*	@copyright PARX
*/
@isTest
public with sharing class QuotePackageHandlerTest
{
	/*
	*	@description Test trigger logic.
	*/
	static testMethod void testMainFunctionality()
	{
		//Insert
		Id pricebookId = Test.getStandardPricebookId();
		Pack__c pack = TestFactory.createPackage(pricebookId);
		Account acc = TestFactory.createAccount();
		Opportunity opp = TestFactory.createOpportunity(acc, pricebookId);
		Quote quote = TestFactory.createQuote(opp);
		Quote_Package__c quotePackage = TestFactory.createQuotePackage(quote, pack); 
		List<Product2> products = new List<Product2>{TestFactory.createProduct(false), TestFactory.createProduct(false), TestFactory.createProduct(false)};
		insert products;

		List<QuoteLineItem> lineItems = new List<QuoteLineItem>{
			TestFactory.createQuoteLineItem(quote, products[0], false),
			TestFactory.createQuoteLineItem(quote, products[1], false),
			TestFactory.createQuoteLineItem(quote, products[2], false)
		};
		lineItems[0].Quote_Package__c = quotePackage.Id;
		lineItems[1].Quote_Package__c = quotePackage.Id;
		insert lineItems;
		
		Test.startTest();
		delete quotePackage;
		Test.stopTest();
		lineItems = [SELECT Id  FROM QuoteLineItem];
		System.assertEquals(1, lineItems.size(), 'Wrong number of QuoteLineItem records: 2 from 3 should be deleted.');
	}
}