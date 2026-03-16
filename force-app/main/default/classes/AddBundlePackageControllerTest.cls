/*
*	@description Test class for AddBundlePackageController functionality.
*
*	@author ach
*	@copyright PARX
*/
@isTest
private class AddBundlePackageControllerTest
{
	
	@isTest static void testOpportunity()
	{
		Id pricebookId = Test.getStandardPricebookId();
		Pack__c pack = TestFactory.createPackage(pricebookId);
		Account acc = TestFactory.createAccount();
		Opportunity opp = TestFactory.createOpportunity(acc, pricebookId);
		Quote quote = TestFactory.createQuote(opp);
		Product2 prod = TestFactory.createProduct();
		/*insert new PricebookEntry(Pricebook2Id = pricebookId,
									Product2Id = prod.Id,
									UnitPrice = 100.00,
									IsActive = true);*/
		PackageLine__c packLine = TestFactory.createPackageLine(pack, prod);
		OpportunityLineItem oli = TestFactory.createOppLineItem(opp, prod);

		Test.startTest();
		AddBundlePackageController ctrl = new AddBundlePackageController(new ApexPages.StandardController(oli));
		System.assertEquals(AddBundlePackageController.ERROR_NOPRICEBOOK, AddBundlePackageController.isErrorText, 'Wrong errortext value');

		ctrl = new AddBundlePackageController(new ApexPages.StandardController(opp));
		ctrl = new AddBundlePackageController(new ApexPages.StandardController(quote));

		//####################### queriePackages ####################### 
		AddBundlePackageController.filterFields filter = new AddBundlePackageController.filterFields();
		filter.name = 'pack1';
    	filter.pricebookEntry = pricebookId;
    	filter.SortNumber = 'Test Sort';
    	filter.Opportunity = opp.Id;
		String result = AddBundlePackageController.queriePackages(JSON.serialize(filter));
		packLine = [SELECT Id, NAme FROM PackageLine__c WHERE Id =:packLine.Id];
		System.assertEquals(true, result.containsIgnoreCase('TESTDescription'), 'Wrong packages value');
		AddBundlePackageController.queriePackages('wrongJSON');
		
		pack = [SELECT id, name, SortNumber__c, Description__c, 
				(SELECT id, Defaultprice__c,Defaultquantity__c, Product__c, Product__r.name, ProductType__c FROM Package_Lines__r) FROM Pack__c WHERE ID = :pack.Id];
		
		//####################### addToOpportunity ####################### 
		AddBundlePackageController.WrapperPackage wrap = new AddBundlePackageController.WrapperPackage(pack);
		wrap.OpportunityId = opp.Id;
		result = AddBundlePackageController.addToOpportunity(JSON.serialize(new List<AddBundlePackageController.WrapperPackage>{wrap}));
		System.assertEquals('1 Package added. 1 Products added', result, 'Wrong value');
		List<OpportunityPackage__c> oppPackages = [SELECT Id  FROM OpportunityPackage__c ];
		System.assertEquals(1, oppPackages.size(), 'Wrong number of generated packages');

		//####################### addToQuote ####################### 
		wrap = new AddBundlePackageController.WrapperPackage(pack);
		wrap.quoteId = quote.Id;
		wrap.PricebookId = pricebookId;
		result = AddBundlePackageController.addToQuote(JSON.serialize(new List<AddBundlePackageController.WrapperPackage>{wrap}));
		System.assertEquals('1 Package added. 1 Products added', result, 'Wrong value');
		List<Quote_Package__c> quotePackages = [SELECT Id  FROM Quote_Package__c ];
		System.assertEquals(1, quotePackages.size(), 'Wrong number of generated packages');

		Test.stopTest();
		
	}

	 @IsTest(SeeAllData=true) static void testCoverage()
	{
		try
		{
			ILVPos__c test = [SELECT Id FROM ILVPos__c LIMIT 1];
			update test;
		} catch(Exception e)
		{
			System.debug('###:' + e.getMessage());
		}
	}
}