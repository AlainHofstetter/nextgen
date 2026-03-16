/**
 */
@isTest
private class TestILVQueueable {

    @isTest
    static void myUnitTest() {
        
        Invoice__c draft = new Invoice__c();
        List<ILVPos__c> positions = new List<ILVPos__c>();
        System.enqueueJob(new ILVQueueable(draft, positions));

        ILVQueueable.mockTest();
    }
}