trigger RH_TimeToPTORequest on Time__c (after insert, after update, before delete) {
    /*
    ResourceHeroApp__RHA_Configuration__c killswitch = ResourceHeroApp__RHA_Configuration__c.getInstance('Killswitch - RH_TimeToPTORequest');
    if(killswitch == null || (killswitch != null && killswitch.ResourceHeroApp__Value__c != 'true')) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            //Generate set of Time ids that have been inserted
            Set<Id> timeids = new Set<Id>();
            for(Time__c t : Trigger.new) {
                timeids.add(t.Id);
            }
            
            //system.debug('Future:  ' + System.isFuture());
            //system.debug('timeids:  ' + timeids);

            //Send to future or flag for processing
            if(timeids.size() > 0 && !System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled())
                RH_TimeToPTORequest_Helper.processPTORequests(Trigger.newMap.keySet());
        }
        else if(Trigger.isDelete) {
            //Generate set of Time ids that have been deleted
            Set<Id> timeids = new Set<Id>();
            for(Time__c t : Trigger.old) {
                timeids.add(t.Id);
            }
            
            //Generate set of PTO Request ids that should be deleted
            Set<Id> ptorequestids = new Set<Id>();
            for(ResourceHeroApp__PTO_Request__c ptor : [SELECT Id FROM ResourceHeroApp__PTO_Request__c WHERE Time__c IN :timeids]) {
                ptorequestids.add(ptor.Id);
            }
            
            //Send to future or flag for processing
            if(ptorequestids.size() > 0 && !System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled())
                RH_TimeToPTORequest_Helper.deletePTORequests(ptorequestids);
        }
    }
*/
}