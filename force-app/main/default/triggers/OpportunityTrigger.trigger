trigger OpportunityTrigger on Opportunity (after delete, after insert, after undelete, 
after update, before delete, before insert, before update)
{
	TriggerTemplate.TriggerManager aTriggerManager = new TriggerTemplate.TriggerManager();
	aTriggerManager.addHandler(new OpportunityTriggerHandler(), new List<TriggerTemplate.TriggerAction>
											{	TriggerTemplate.TriggerAction.beforeinsert,
												TriggerTemplate.TriggerAction.beforeupdate,
												TriggerTemplate.TriggerAction.afterinsert, 
												TriggerTemplate.TriggerAction.afterupdate,
												TriggerTemplate.TriggerAction.afterdelete});
	aTriggerManager.runHandlers();
}