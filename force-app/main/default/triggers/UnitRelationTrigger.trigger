trigger UnitRelationTrigger on UnitRelation__c (after delete, after insert, after undelete, 
		after update, before insert, before update)
{
	new TriggerTemplateV2.TriggerManager(new UnitRelationTriggerHandler()).runHandlers();
}