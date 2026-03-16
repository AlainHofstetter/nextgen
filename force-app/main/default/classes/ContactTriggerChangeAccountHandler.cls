/*
*	@description Contact Trigger functionality.
*
*	@author dch
*	@copyright PARX
*/
public with sharing class ContactTriggerChangeAccountHandler implements TriggerTemplate.Handler
{
	private List<Contact> newValues = null;
	private Map<Id, Contact> oldValues = null;
	
	/**
	*	@description Set Trigger.new and Trigger.old to newValues and oldValues accordingly
	*
	*	@param theNewValues is a Trigger.new records
	*	@param theOldValues is a Trigger.old.Map records
	*/
	public void setValues(List<sObject> theNewValues, Map<Id, sObject> theOldValues)
	{
		newValues = theNewValues;
		oldValues = (Map<Id, Contact>) theOldValues;
	}
	
	/**
	*	@description Handle method for actions
	*
	*	@param theAction is a Trigger actions
	*/
	public void handle(TriggerTemplate.TriggerAction action)
	{
		if (action == TriggerTemplate.TriggerAction.beforeUpdate)
		{
			ContactService.defineAccountRecordType(Utils.getModifiedObjects(new List<String>{'AccountId'}, newValues, oldValues));
		}
	}
}