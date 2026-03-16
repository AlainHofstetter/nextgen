trigger QuotePackage on Quote_Package__c (before delete) {
	
	
	QuotePackageHandler handler = new QuotePackageHandler();
	
	if(trigger.isBefore) {
		
		if (trigger.isDelete) {
			handler.OnBeforeDelete(Trigger.oldMap);
		}
	}
    
}