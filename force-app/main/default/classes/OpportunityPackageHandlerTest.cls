/*
*	@description Test class for OpportunityPackageHandler functionality.
*
*	@author ach
*	@copyright PARX
*/
@isTest
public with sharing class OpportunityPackageHandlerTest
{
	/*
	*	@description Test trigger logic
	*/
	static testMethod void testMainFunctionality()
	{
		Id pricebookId = Test.getStandardPricebookId();
		Pack__c pack = TestFactory.createPackage(pricebookId);
		Account acc = TestFactory.createAccount();
		Opportunity opp = TestFactory.createOpportunity(acc, pricebookId);
		List<Product2> products = new List<Product2>{TestFactory.createProduct(false), TestFactory.createProduct(false), TestFactory.createProduct(false)};
		insert products;
		OpportunityPackage__c oppPackage = TestFactory.createOpportunityPackage(opp, pack);
		List<OpportunityLineItem> lineItems = new  List<OpportunityLineItem>{
			TestFactory.createOppLineItem(opp, products[0], false),
			TestFactory.createOppLineItem(opp, products[1], false),
			TestFactory.createOppLineItem(opp, products[2], false)
		};
		lineItems[0].OpportunityPackage__c = oppPackage.Id;
		lineItems[1].OpportunityPackage__c = oppPackage.Id;
		insert lineItems;
		
		Test.startTest();
		delete oppPackage;
		Test.stopTest();
		
		lineItems = [SELECT Id  FROM OpportunityLineItem];
		System.assertEquals(1, lineItems.size(), 'Wrong number of OpportunityLineItem records: 2 from 3 should be deleted.');
	}
}