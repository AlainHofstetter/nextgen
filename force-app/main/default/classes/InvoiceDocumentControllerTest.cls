/*
 * @Class : InvoiceDocumentController
 * 
 * @Author     : Lisis Rodriguez <lisis.rodriguez@empaua.com>
 * @Created    : 3 Oct 2023
 * @Description: Test class for InvoiceDocumentController
 */
@isTest
public with sharing class InvoiceDocumentControllerTest {
    @TestSetup
    static void makeData(){
        TestFactory.makeData();
    }

    @isTest
    public static void controllerTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        FinanceAccount__c finAcc = [SELECT Id FROM FinanceAccount__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 
        
        Test.startTest();
        InvoicePos__c invPos1 = TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);
        InvoicePos__c invPos2 = TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);
        invPos2.PackageType__c = 'Flat';

        List<InvoicePos__c> invPositions = new List<InvoicePos__c>{invPos1,invPos2};
        insert invPositions;
        
        InvoicePos__c invPos3 = TestFactory.createInvoicePosition(inv.Id, invPos1.Id, service.Id, finAcc.Id);
        insert invPos3; 
        invPositions.add(invPos3);
        PageReference pageRef = Page.InvoicePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(inv.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(inv); 
        InvoiceDocumentController controller = new InvoiceDocumentController(sc);
        Test.stopTest();
    }

    @isTest
    public static void processInvoicePosTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        FinanceAccount__c finAcc = [SELECT Id FROM FinanceAccount__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 
        
        Test.startTest();
        
            InvoicePos__c invPos1 = TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);
            invPos1.PackageType__c = 'Time';
            InvoicePos__c invPos2 = TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);
            invPos2.PackageType__c = 'Flat';

            List<InvoicePos__c> invPositions = new List<InvoicePos__c>{invPos1,invPos2};
            insert invPositions;
            
            InvoicePos__c invPos3 = TestFactory.createInvoicePosition(inv.Id, invPos1.Id, service.Id, finAcc.Id);
            insert invPos3; 
            invPositions.add(invPos3);
            PageReference pageRef = Page.InvoicePDF;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('Id', String.valueOf(inv.Id));
            ApexPages.StandardController sc = new ApexPages.StandardController(inv); 
            InvoiceDocumentController controller = new InvoiceDocumentController(sc);
            controller.processInvoicePos(invPositions);
        
        Test.stopTest();
    
        System.assertEquals(4,controller.mapGroupNameAmount.size() );
        System.assertEquals(2,controller.mapInvPosGroup.size() );
        System.assertEquals(1,controller.nonGroupInvPos.size() );
    }

    @isTest
    public static void getImageURLTest(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 

        Test.startTest();
        //Creating document 
        ContentVersion cv = new ContentVersion(); 
        cv.Title = Label.QRInvoicePrefix + System.today(); 
        cv.PathOnClient = '/' + cv.Title + '.pdf'; 
        cv.VersionData =  Blob.valueOf('Unit Test ContentVersion Body'); 
        cv.origin = 'H';
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = inv.Id;
        cdl.ContentDocumentId = [SELECT ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id =: cv.Id].ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        insert cdl; 

        //Creating page and controller 
        PageReference pageRef = Page.InvoicePDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(inv.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(inv); 
        InvoiceDocumentController controller = new InvoiceDocumentController(sc);
        
        controller.getImageURL();

        Test.stopTest();
        System.AssertNotEquals(null, controller.imageURL);    
    }


    @isTest
    public static void createInvoicePDFTest(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 

        InvoiceInvocableService.Requests req1 = new InvoiceInvocableService.Requests(inv.Id, InvoiceInvocableService.SERVICE_CREATE_INVOICE);
        InvoiceInvocableService.Requests req2 = new InvoiceInvocableService.Requests(inv.Id, InvoiceInvocableService.SERVICE_CANCEL_INVOICE);

        List<InvoiceInvocableService.Requests> requests = new List<InvoiceInvocableService.Requests>{req1, req2};

        Test.startTest();
        InvoiceDocumentController.createInvoicePDF(requests);
        Test.stopTest();

        System.assertEquals(2, [SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId =: inv.Id], 'ContentDocumentLinks were not well generated ');
    }


        
}