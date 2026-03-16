/**
	Trigger handler for Account object
	
	@copyright PARX
	@author akr
*/
public with sharing class AccountTriggerHandler extends TriggerTemplateV2.TriggerHandlerAdapter
{
	public override void  onAfterUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap)
	{
		//Updates accounts if the auto-fields data was updated.
		updateAccounts(newList, (Map<Id, Account>) oldMap);
	}

	/**
		Updates accounts if the auto-fields data was updated.
	*/
	private void updateAccounts(List<Account> theNewValuesList, Map<Id, Account> theOldValuesMap)
	{
		Set<Id> anAccIdSet = Utils.getModifiedObjectIds(new List<String>{'CustomerActual__c', 'Supplier__c', 'Partner__c', 'AccountManager__c', 'Deputy__c'}, theNewValuesList, theOldValuesMap);
		AccountSummary.getInstance().updateObjects(anAccIdSet);
	}
}