@isTest
/**
*	@description Unit test for UnitRelationTrigger.
*	
*	@author akr
*	@copyright PARX
*/
private class Test_UnitRelationTrigger
{
	static testMethod void testValidation()
	{
		TriggerTemplateV2.setupUnitTest();
		Account anAcc = new Account(Name = 'Account New', RecordTypeId = Utils.recordTypes.get('Account:InternalAccount'), LocationStreetNr__c = '123');
		insert anAcc;
		
		UnitRelation__c aRelation1 = new UnitRelation__c(Account__c = anAcc.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		UnitRelation__c aRelation2 = new UnitRelation__c(Account__c = anAcc.Id, Customer__c = 'Dis',
				Supplier__c = true, Partner__c = false, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:GbCh'));
		insert new List<UnitRelation__c> {aRelation1, aRelation2};
		
		Test.startTest();
		TriggerTemplateV2.startUnitTest();
		UnitRelation__c aRelation3 = new UnitRelation__c(Account__c = anAcc.Id, Customer__c = 'Actual',
				Supplier__c = true, Partner__c = true, RecordTypeId = Utils.recordTypes.get('UnitRelation__c:Hbc'));
		Boolean isCorrect = false;
		try
		{
			insert aRelation3;
		} catch (Exception theExc)
		{
			System.assert(theExc.getMessage().contains('HBC') && theExc.getMessage().contains(aRelation1.Id),
					'Wrong error message was generated: ' + theExc.getMessage());
			isCorrect = true;
		}
		System.assert(isCorrect, 'The error message should be generated!');
		
		TriggerTemplateV2.startUnitTest();
		aRelation3.RecordTypeId = Utils.recordTypes.get('UnitRelation__c:BLC');
		insert aRelation3;
		Test.stopTest();
		
		System.assertNotEquals(null, aRelation3.Id, 'UnitRelation__c should be inserted without issues: ' + aRelation3);
	}
}