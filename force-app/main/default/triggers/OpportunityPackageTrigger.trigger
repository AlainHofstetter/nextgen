trigger OpportunityPackageTrigger on OpportunityPackage__c (before delete) {
    
    OpportunityPackageHandler handler = new OpportunityPackageHandler();
	
	if(trigger.isBefore) {
		
		if (trigger.isDelete) {
			handler.OnBeforeDelete(Trigger.oldMap);
		}
	}
}