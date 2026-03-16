/**
	Trigger handler for UnitRelation__c object
	
	@copyright PARX
	@author akr
*/
public with sharing class UnitRelationTriggerHandler extends TriggerTemplateV2.TriggerHandlerAdapter
{
	public override void onBeforeInsert (List<sObject> newList)
	{
		//validates if unit relation can be added without duplication
		validateAccountUpdate(newList, null);
	}
	
	public override void onBeforeUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap)
	{
		//validates if unit relation can be added without duplication
		validateAccountUpdate(newList, (Map<Id, UnitRelation__c>) oldMap);
	}
	
	public override void  onAfterInsert (List<sObject> newList, Map<Id, sObject> newMap)
	{
		//Update related accounts with new Unit Relations data
		updateAccounts(newList, null);
	}
	
	public override void  onAfterUpdate (List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap)
	{
		//Update related accounts with new Unit Relations data
		updateAccounts(newList, (Map<Id, UnitRelation__c>) oldMap);
	}
	
	public override void  onAfterDelete (List<sObject> oldList, Map<Id, sObject> oldMap)
	{
		//Update related accounts with new Unit Relations data
		updateAccounts(null, (Map<Id, UnitRelation__c>) oldMap);
	}

	public override void  onAfterUndelete (List<sObject> newList, Map<Id, sObject> newMap)
	{
		//Update related accounts with new Unit Relations data
		updateAccounts(newList, null);
	}
	
	/**
		Validates if unit relation can be added without duplication
	*/
	public void validateAccountUpdate(List<UnitRelation__c> theNewValuesList, Map<Id, UnitRelation__c> theOldValuesMap)
	{
		Set<Id> anAccSet = new Set<Id>();
		Set<Id> anRTSet = new Set<Id>();
		Set<Id> aNewUnits = theOldValuesMap == null ? new Set<Id>() : theOldValuesMap.keySet();
		for (UnitRelation__c anUnit: theNewValuesList)
		{
			if (anUnit.Account__c != null)
			{
				anAccSet.add(anUnit.Account__c);
				anRTSet.add(anUnit.RecordTypeId);
			}
		}
		List<UnitRelation__c> anExistingUnitRelations = [SELECT Id, Name, RecordTypeId, Account__c FROM UnitRelation__c
				WHERE Account__c IN : anAccSet AND RecordTypeId IN :anRTSet AND Id NOT IN :aNewUnits];
		Map<String, UnitRelation__c> aRelRes = new Map<String, UnitRelation__c>();
		for (UnitRelation__c aRel: anExistingUnitRelations)
		{
			aRelRes.put(aRel.Account__c + '-' + aRel.RecordTypeId, aRel);
		}
		Map<Id, RecordType> aRTList = new Map<Id, RecordType>([SELECT Id, Name FROM RecordType WHERE Id IN :anRTSet]);
		for (UnitRelation__c anUnit: theNewValuesList)
		{
			UnitRelation__c aCopyRes = aRelRes.get(anUnit.Account__c + '-' + anUnit.RecordTypeId);
			if (aCopyRes != null)
			{
				anUnit.addError('For the Unit' + aRTList.get(anUnit.RecordTypeId).Name + ' a record already exist on this Account'
						+ (aCopyRes.Id == null ? '' : ': <a href="/' + aCopyRes.Id + '">' + aCopyRes.Name + '</a>'), false);
			} else
			{
				aRelRes.put(anUnit.Account__c + '-' + anUnit.RecordTypeId, aCopyRes);
			}
		}
	}
	
	/**
		Updates related accounts with new Unit Relations data
	*/
	private void updateAccounts(List<UnitRelation__c> theNewValuesList, Map<Id, UnitRelation__c> theOldValuesMap)
	{
		Set<Id> anAccIdSet = Utils.getModifiedObjectParents(new List<String>{'AccountManager__c', 'Account__c', 'Deputy__c', 'RecordTypeId', 'Customer__c',
					 'Supplier__c', 'Partner__c', 'Customer__c'}, 'Account__c', theNewValuesList, theOldValuesMap);
		AccountSummary.getInstance().updateObjects(anAccIdSet);
	}
}