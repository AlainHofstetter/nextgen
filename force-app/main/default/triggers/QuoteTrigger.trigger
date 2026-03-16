trigger QuoteTrigger on Quote (before insert,
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		QuoteHandler handler = new QuoteHandler();
		
		if (Trigger.isBefore) {
    		if (Trigger.isInsert) {
				//handler.OnBeforeInsert(Trigger.new);
			} else if (Trigger.isUpdate) {
				//	handler.OnBeforeUpdate(Trigger.oldMap, Trigger.new);
			} else if (trigger.isDelete) {
				//handler.OnBeforeDelete(Trigger.old);
			}
		} else if (Trigger.isAfter) {
	    	if (Trigger.isInsert) {
	    		//handler.OnAfterInsert(Trigger.new);
			} else if (Trigger.isUpdate) {
				handler.OnAfterUpdate(Trigger.oldMap, Trigger.new);
			} else if (trigger.isDelete) {
				//handler.OnAfterDelete(Trigger.old);
			}    

}
}