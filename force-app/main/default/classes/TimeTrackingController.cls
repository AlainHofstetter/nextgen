public with sharing class TimeTrackingController {

    @AuraEnabled
    public static List<Contact> searchLookup() {
        return [SELECT Id, Name, CreatedDate FROM Contact];
    }

}