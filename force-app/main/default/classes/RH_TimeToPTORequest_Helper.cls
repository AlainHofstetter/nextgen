public class RH_TimeToPTORequest_Helper {
    /*
    @future
    public static void processPTORequests(Set<Id> timeids) {
        //Get map of time records
        Map<Id, Time__c> existing_times = new Map<Id, Time__c>([SELECT Id,
                                                                        Name,
                                                                        DateFrom__c,
                                                                        DateUntil__c,
                                                                        DurationHhMmN__c,
                                                                        Projectname__c,
                                                                        ProjectName__r.ProjectType__c,
                                                                        ProjectName__r.ProjectSubType__c,
                                                                        CreatedById
                                                                FROM Time__c
                                                                WHERE Id IN :timeids
                                                                    AND ProjectName__r.ProjectType__c = 'Internal'
                                                                    AND ProjectName__r.ProjectSubType__c = 'Absence']);

        //Get set of createdbyids so that we can query resources
        Set<Id> createdbyids = new Set<Id>();
        for(Time__c t : existing_times.values()) {
            createdbyids.add(t.CreatedById);
        }
        
        List<ResourceHeroApp__Resource__c> res = [SELECT Id, ResourceHeroApp__User__c FROM ResourceHeroApp__Resource__c WHERE ResourceHeroApp__User__c != null AND ResourceHeroApp__User__c IN :createdbyids];
        Map<Id, Id> user_to_res = new Map<Id, Id>();
        for(ResourceHeroApp__Resource__c re : res) {
            user_to_res.put(re.ResourceHeroApp__User__c, re.Id);
        }

        //Only continue if these times exist and have linked resources
        if(existing_times.size() > 0 && user_to_res.size() > 0) {
            //Get existing pto requests
            Map<Id, ResourceHeroApp__PTO_Request__c> existing_ptorequests = new Map<Id, ResourceHeroApp__PTO_Request__c>([SELECT Id, Name, ResourceHeroApp__Date__c, ResourceHeroApp__Hours__c, ResourceHeroApp__Status__c, ResourceHeroApp__Type__c, ResourceHeroApp__Resource__c, Time__c
                                                                                                                          FROM ResourceHeroApp__PTO_Request__c
                                                                                                                          WHERE Time__c != null AND Time__c IN :timeids]);
            //Generate reference map to get from time id to pto request
            Map<Id, ResourceHeroApp__PTO_Request__c> time_to_ptor = new Map<Id, ResourceHeroApp__PTO_Request__c>();
            for(ResourceHeroApp__PTO_Request__c ptor : existing_ptorequests.values()) {
                time_to_ptor.put(ptor.Time__c, ptor);
            }
            
            //Create lists that we will use for insert / update operations
            List<ResourceHeroApp__PTO_Request__c> ptors_forinsert = new List<ResourceHeroApp__PTO_Request__c>();
            List<ResourceHeroApp__PTO_Request__c> ptors_forupdate = new List<ResourceHeroApp__PTO_Request__c>();
            
            //Iterate through time ids
            for(Time__c t : existing_times.values()) {
                //if pto request for time entry does not exist create it
                if(time_to_ptor.containsKey(t.Id) == false && user_to_res.containsKey(t.CreatedById)) {
                    ptors_forinsert.add(new ResourceHeroApp__PTO_Request__c(Time__c = t.Id
                                                                            , ResourceHeroApp__Date__c = t.DateFrom__c
                                                                            , ResourceHeroApp__Type__c = 'FROM TIME RECORD'
                                                                            , ResourceHeroApp__Status__c = 'Approved'
                                                                            , ResourceHeroApp__Resource__c = user_to_res.get(t.CreatedById)
                                                                            , ResourceHeroApp__Hours__c = t.DurationHhMmN__c));
                }
                //if pto request for time entry does exist, update it
                else if(time_to_ptor.containsKey(t.Id) && user_to_res.containsKey(t.CreatedById)){
                    ResourceHeroApp__PTO_Request__c ptoforupdate = time_to_ptor.get(t.Id);
                    ptoforupdate.ResourceHeroApp__Date__c = t.DateFrom__c;
                    ptoforupdate.ResourceHeroApp__Type__c = 'FROM TIME RECORD';
                    ptoforupdate.ResourceHeroApp__Status__c = 'Approved';
                    ptoforupdate.ResourceHeroApp__Hours__c = t.DurationHhMmN__c;
                    ptors_forupdate.add(ptoforupdate);
                }
            }
            
            if(ptors_forinsert.size() > 0)
                insert ptors_forinsert;
            
            if(ptors_forupdate.size() > 0)
                update ptors_forupdate;
        }
    }
    
    
    @future
    public static void deletePTORequests(Set<Id> ptorequestids) {
        List<ResourceHeroApp__PTO_Request__c> ptors_fordelete = [SELECT Id FROM ResourceHeroApp__PTO_Request__c WHERE Id IN :ptorequestids];
        if(ptors_fordelete.size() > 0)
            delete ptors_fordelete;
    }
    */
}