/*
*	@description Opportunity Trigger functionality.
*
*	@author ach
*	@copyright PARX
*/
public with sharing class OpportunityTriggerHandler implements TriggerTemplate.Handler
{
	private List<Opportunity> newValues = null;
	private Map<Id, Opportunity> oldValues = null;
	
	/**
	*	@description Set Trigger.new and Trigger.old to newValues and oldValues accordingly
	*
	*	@param theNewValues is a Trigger.new records
	*	@param theOldValues is a Trigger.old.Map records
	*/
	public void setValues(List<sObject> theNewValues, Map<Id, sObject> theOldValues)
	{
		newValues = theNewValues;
		oldValues = (Map<Id, Opportunity>) theOldValues;
	}
	
	/**
	*	@description Handle method for actions
	*
	*	@param theAction is a Trigger actions
	*/
	public void handle(TriggerTemplate.TriggerAction theAction)
	{
		if (theAction == TriggerTemplate.TriggerAction.afterupdate || theAction == TriggerTemplate.TriggerAction.afterinsert)
		{
			updateForecasts();
		} 
	}
	
	/**
	*	update the forecasts related to the modified opportunities
	*/
	private void updateForecasts()
	{
		// get only those Opportunities that have changes in the calculated fields
		Set<sObject> aModifiedObjects = Utils.getModifiedObjects(new List<String>{'Amount', 'Probability', 'ProjectStart__c', 
				'ProjectEnd__c', 'DailyRate__c', 'CurrencyIsoCode'}, newValues, oldValues);
		List<Opportunity> aModifiedOpportunities = new List<Opportunity>();
		for (sObject anObject : aModifiedObjects)
		{
			aModifiedOpportunities.add((Opportunity)anObject);
		}
		OpportunityService.updateForecasts(aModifiedOpportunities);
	}
}