public with sharing class StartBillingButtonController {

    @AuraEnabled
    public static Id get(Id recordId) {
        User u = UserService.getLogged();

        if (u == null || !u.IsProjectManager__c)
            return null;

        if (Project__c.SObjectType == recordId.getSObjectType())
            return recordId;

        Invoice__c inv = InvoiceService.get(recordId);
        return inv != null ? inv.ProjectName__c : null;
    }

}