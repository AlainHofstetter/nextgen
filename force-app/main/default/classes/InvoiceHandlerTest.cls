@isTest
public with sharing class InvoiceHandlerTest {

    @TestSetup
    static void makeData(){
        // Invoice__c invoice = new Invoice__c();
        // insert invoice;
        TestFactory.makeData();
    }
    
    @isTest
    public static void InvoiceHandlerTest() {
        //InvoiceHelper.generateQRCode('a0Qb000000CWVOkEAP');
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 
    }
}