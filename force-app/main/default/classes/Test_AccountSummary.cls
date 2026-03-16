@isTest
/**
*	@description Unit test for AccountSummary class and related triggers.
*	
*	@author akr
*	@copyright PARX
*/
public class Test_AccountSummary
{
	/**
	*	@description Test the rollup summary on accoount update.
	*//*
	private testmethod static void testUpdateAccount()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc1 = new Account(Name = 'Account1', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		Account anAcc2 = new Account(Name = 'Account2', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '1234');
		insert new List<Account>{anAcc1, anAcc2};

		Contact aCont1 = new Contact(FirstName = 'TCont', LastName = 'Last1', AccountId = anAcc1.Id, LocationStreetNr__c = '123',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont2 = new Contact(FirstName = 'BCont', LastName = 'Last2', AccountId = anAcc1.Id, LocationStreetNr__c = '1234',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont3 = new Contact(FirstName = 'ACont', LastName = 'Last56789', AccountId = anAcc2.Id, LocationStreetNr__c = '12345',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont4 = new Contact(FirstName = 'FCont', LastName = 'Last4', AccountId = anAcc2.Id, LocationStreetNr__c = '123456',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		insert new List<Contact>{aCont1, aCont2, aCont3, aCont4};
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont1.Id, Deputy__c = aCont2.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc2.Id, AccountManager__c = aCont4.Id, Deputy__c = aCont3.Id, Customer__c = 'Actual',
				Supplier__c = false, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC'));
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont3.Id, Deputy__c = null, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = false, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c>{aRelation1, aRelation2};
		
		TriggerTemplateV2.startUnitTest();
		insert aRelation3;
		Test.stopTest();

		List<Account> aResults = [SELECT Id, AccountManager__c, Deputy__c, CustomerActual__c, Supplier__c, Partner__c FROM Account];
		for (Account aRes: aResults)
		{
			System.assertEquals(aRes.Id == anAcc1.Id ? 'HBC' : 'BLC', aRes.CustomerActual__c, 'Wrong CustomerActual__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH; HBC' : null, aRes.Supplier__c, 'Wrong Supplier__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'HBC' : 'BLC', aRes.Partner__c, 'Wrong Partner__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567; TLast1' : 'FLast4' , aRes.AccountManager__c, 'Wrong AccountManager__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'BLast2' : 'ALast567' , aRes.Deputy__c, 'Wrong Deputy__c: ' + aRes);
		}
	}*/
	
	/**
	*	@description tests if summary works on Unit Relation object insert.
	*//*
	private testmethod static void testInsert()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc1 = new Account(Name = 'Account1', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		Account anAcc2 = new Account(Name = 'Account2', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '1234');
		insert new List<Account>{anAcc1, anAcc2};

		Contact aCont1 = new Contact(FirstName = 'TCont', LastName = 'Last1', AccountId = anAcc1.Id, LocationStreetNr__c = '123',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont2 = new Contact(FirstName = 'BCont', LastName = 'Last2', AccountId = anAcc1.Id, LocationStreetNr__c = '1234',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont3 = new Contact(FirstName = 'ACont', LastName = 'Last56789', AccountId = anAcc2.Id, LocationStreetNr__c = '12345',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont4 = new Contact(FirstName = 'FCont', LastName = 'Last4', AccountId = anAcc2.Id, LocationStreetNr__c = '123456',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		insert new List<Contact>{aCont1, aCont2, aCont3, aCont4};
		
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont1.Id, Deputy__c = aCont2.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc2.Id, AccountManager__c = aCont4.Id, Deputy__c = aCont3.Id, Customer__c = 'Actual',
				Supplier__c = false, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC'));
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont3.Id, Deputy__c = null, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = false, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c>{aRelation1, aRelation2, aRelation3};
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		anAcc1.Partner__c = 'BLC; HBC';
		anAcc1.CustomerActual__c = 'BLC; HBC';
		anAcc1.Deputy__c = 'BLC; HBC';
		update anAcc1;
		Test.stopTest();

		List<Account> aResults = [SELECT Id, AccountManager__c, Deputy__c, CustomerActual__c, Supplier__c, Partner__c FROM Account];
		for (Account aRes: aResults)
		{
			System.assertEquals(aRes.Id == anAcc1.Id ? 'HBC' : 'BLC', aRes.CustomerActual__c, 'Wrong CustomerActual__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH; HBC' : null, aRes.Supplier__c, 'Wrong Supplier__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'HBC' : 'BLC', aRes.Partner__c, 'Wrong Partner__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567; TLast1' : 'FLast4' , aRes.AccountManager__c, 'Wrong AccountManager__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'BLast2' : 'ALast567' , aRes.Deputy__c, 'Wrong Deputy__c: ' + aRes);
		}
	}*/
	
	/**
	*	@description tests if summary works on Unit Relation object update.
	*//*
	private testmethod static void testUpdate()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc1 = new Account(Name = 'Account1', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		Account anAcc2 = new Account(Name = 'Account2', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '1234');
		insert new List<Account>{anAcc1, anAcc2};

		Contact aCont1 = new Contact(FirstName = 'TCont', LastName = 'Last1', AccountId = anAcc1.Id, LocationStreetNr__c = '123',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont2 = new Contact(FirstName = 'BCont', LastName = 'Last2', AccountId = anAcc1.Id, LocationStreetNr__c = '1234',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont3 = new Contact(FirstName = 'ACont', LastName = 'Last567', AccountId = anAcc2.Id, LocationStreetNr__c = '12345',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont4 = new Contact(FirstName = 'FCont', LastName = 'Last4', AccountId = anAcc2.Id, LocationStreetNr__c = '123456',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		insert new List<Contact>{aCont1, aCont2, aCont3, aCont4};
		
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont1.Id, Deputy__c = aCont2.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc2.Id, AccountManager__c = aCont4.Id, Deputy__c = aCont3.Id, Customer__c = 'Actual',
				Supplier__c = false, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC'));
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont3.Id, Deputy__c = null, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = false, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c>{aRelation1, aRelation2};
		insert aRelation3;
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		aRelation3.Deputy__c = aCont3.Id;
		aRelation3.AccountManager__c = null;
		aRelation3.Partner__c = true;
		update aRelation3;
		Test.stopTest();

		List<Account> aResults = [SELECT Id, AccountManager__c, Deputy__c, CustomerActual__c, Supplier__c, Partner__c FROM Account];
		for (Account aRes: aResults)
		{
			System.assertEquals(aRes.Id == anAcc1.Id ? 'HBC' : 'BLC', aRes.CustomerActual__c, 'Wrong CustomerActual__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH; HBC' : null, aRes.Supplier__c, 'Wrong Supplier__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH; HBC' : 'BLC', aRes.Partner__c, 'Wrong Partner__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'TLast1' : 'FLast4' , aRes.AccountManager__c, 'Wrong AccountManager__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567; BLast2' : 'ALast567' , aRes.Deputy__c, 'Wrong Deputy__c: ' + aRes);
		}
	}*/
	
	/**
	*	@description tests if summary works on Unit Relation object update.
	*//*
	private testmethod static void testUpdate2()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc1 = new Account(Name = 'Account1', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		Account anAcc2 = new Account(Name = 'Account2', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '1234');
		insert new List<Account>{anAcc1, anAcc2};

		Contact aCont1 = new Contact(FirstName = 'TCont', LastName = 'Last1', AccountId = anAcc1.Id, LocationStreetNr__c = '123',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont2 = new Contact(FirstName = 'BCont', LastName = 'Last2', AccountId = anAcc1.Id, LocationStreetNr__c = '1234',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont3 = new Contact(FirstName = 'ACont', LastName = 'Last567', AccountId = anAcc2.Id, LocationStreetNr__c = '12345',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont4 = new Contact(FirstName = 'FCont', LastName = 'Last4', AccountId = anAcc2.Id, LocationStreetNr__c = '123456',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		insert new List<Contact>{aCont1, aCont2, aCont3, aCont4};
		
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont1.Id, Deputy__c = aCont2.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc2.Id, AccountManager__c = aCont4.Id, Deputy__c = aCont3.Id, Customer__c = 'Actual',
				Supplier__c = false, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC'));
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont3.Id, Deputy__c = null, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c>{aRelation1, aRelation2};
		insert aRelation3;
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		aRelation2.Account__c = anAcc1.Id;
		update aRelation2;
		Test.stopTest();

		List<Account> aResults = [SELECT Id, AccountManager__c, Deputy__c, CustomerActual__c, Supplier__c, Partner__c FROM Account];
		for (Account aRes: aResults)
		{
			System.assertEquals(aRes.Id == anAcc1.Id ? 'BLC; HBC' : null, aRes.CustomerActual__c, 'Wrong CustomerActual__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH; HBC' : null, aRes.Supplier__c, 'Wrong Supplier__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'BLC; GBCH; HBC' : null, aRes.Partner__c, 'Wrong Partner__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567; FLast4; TLast1' : null, aRes.AccountManager__c, 'Wrong AccountManager__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567; BLast2' : null , aRes.Deputy__c, 'Wrong Deputy__c: ' + aRes);
		}
	}*/
	
	/**
	*	@description tests if summary works on Unit Relation object delete.
	*//*
	private testmethod static void testDelete()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc1 = new Account(Name = 'Account1', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		Account anAcc2 = new Account(Name = 'Account2', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '1234');
		insert new List<Account>{anAcc1, anAcc2};

		Contact aCont1 = new Contact(FirstName = 'TCont', LastName = 'Last1', AccountId = anAcc1.Id, LocationStreetNr__c = '123',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont2 = new Contact(FirstName = 'BCont', LastName = 'Last2', AccountId = anAcc1.Id, LocationStreetNr__c = '1234',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont3 = new Contact(FirstName = 'ACont', LastName = 'Last567', AccountId = anAcc2.Id, LocationStreetNr__c = '12345',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		Contact aCont4 = new Contact(FirstName = 'FCont', LastName = 'Last4', AccountId = anAcc2.Id, LocationStreetNr__c = '123456',
				 RecordTypeId = Utils.recordTypes.get('Contact:InternalContact'), UnitRelevance__c = 'aa');
		insert new List<Contact>{aCont1, aCont2, aCont3, aCont4};
		
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont1.Id, Deputy__c = aCont2.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc2.Id, AccountManager__c = aCont4.Id, Deputy__c = aCont3.Id, Customer__c = 'Actual',
				Supplier__c = false, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC'));
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc1.Id, AccountManager__c = aCont3.Id, Deputy__c = null, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = false, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c>{aRelation1, aRelation2};
		insert aRelation3;
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		delete aRelation1;
		Test.stopTest();

		List<Account> aResults = [SELECT Id, AccountManager__c, Deputy__c, CustomerActual__c, Supplier__c, Partner__c FROM Account];
		for (Account aRes: aResults)
		{
			System.assertEquals(aRes.Id == anAcc1.Id ? null : 'BLC', aRes.CustomerActual__c, 'Wrong CustomerActual__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'GBCH' : null, aRes.Supplier__c, 'Wrong Supplier__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? null : 'BLC', aRes.Partner__c, 'Wrong Partner__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? 'ALast567' : 'FLast4' , aRes.AccountManager__c, 'Wrong AccountManager__c: ' + aRes);
			System.assertEquals(aRes.Id == anAcc1.Id ? null : 'ALast567' , aRes.Deputy__c, 'Wrong Deputy__c: ' + aRes);
		}
	}*/
}