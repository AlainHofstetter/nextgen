/*
 * @Class : QRCodeServiceTest
 *
 * @Author     : Lisis Rodriguez <lisis.rodriguez@empaua.com>
 * @Created    : 25 Oct 2023
 * @Description: Test class for QRCodeService
 */
@isTest
public with sharing  class QRCodeServiceTest {
    @TestSetup
    static void makeData(){
        TestFactory.makeData();
    }

    @isTest
    public static void generateQRCodeTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        FinanceAccount__c finAcc = [SELECT Id FROM FinanceAccount__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        inv.ProjectInvoiceCurrency__c = 'EUR';
        insert inv; 
        
        String docName = Label.QRInvoicePrefix + '_' + Date.today().format();

        Test.startTest();
        //This line is not here because of testing purposes, just to avoid a Too Many queries exception
        insert TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);
        
        //Invoking QRCodeService.generateQRCode from a future method to be able to call a web service after a DML operation
        generateQRCodeFuture(inv.Id);
        Test.stopTest();

        List<ContentDocumentLink> cdls = [SELECT Id, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =: inv.Id];

        System.assert(!cdls.isEmpty(), 'No ContentDocumentLink was generated');
        System.assertEquals(docName,cdls.get(0).ContentDocument.Title, 'Document title is the expected');

    }
    
    @future (callout=true)
    private static void generateQRCodeFuture(Id invId){
        Invoice__c inv = [SELECT Id,
                                ProjectInvoiceCurrency__c, 
                                AccountLanguage__c, 
                                BillingViaCompany__c, 
                                ProjectName__c, 
                                ProjectCostCenter__c 
                            FROM Invoice__c 
                            WHERE Id =: invId ];
        QRCodeService.generateQRCode(inv);
    }

    @isTest
    public static void createRequestBodyTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        FinanceAccount__c finAcc = [SELECT Id FROM FinanceAccount__c LIMIT 1];
        
        Test.startTest();
        // This lines are not here because of testing purposes, just to avoid a Too Many queries exception caused 
        // by fflib module installed after the creation of the test data
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        inv.ProjectInvoiceCurrency__c = 'EUR';
        insert inv;
        insert TestFactory.createInvoicePosition(inv.Id, null, service.Id, finAcc.Id);

        String req = QRCodeService.createRequestBody(inv, 'en');

        Test.stopTest();
        System.assert(!String.isBlank(req), 'No request has been created');
    }

    @isTest
    public static void doPostTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        inv.ProjectInvoiceCurrency__c = 'EUR';
        insert inv; 
        
        List<String> queryParams = new List<String>{'resolution=MEDIUM_300_DPI', 'boundaryLinesMargins=true', 'boundaryLineScissors=true'};
        String body = 'testingBody';

        Test.startTest();
    
        QRCodeService.doPost(queryParams,body, 'en');
        try{
            queryParams.add('fail');
            QRCodeService.doPost(queryParams,body, 'en');
        }catch(HandledException ex){
            System.assert(ex != null);

        }
        Test.stopTest();
    }

    @isTest
    public static void buildQRCodeImageTest(){
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        inv.ProjectInvoiceCurrency__c = 'EUR';
        insert inv; 

        QRGeneratorToolSettings__c toolSet = new QRGeneratorToolSettings__c();
        toolSet.API_resolution__c = 'MEDIUM_300_DPI';
        toolSet.API_normalizeInput__c = true;
        toolSet.API_boundaryLinesMargins__c = true; 
        toolSet.API_boundaryLineScissors__c = true;

        Test.startTest();
    
        String qr = QRCodeService.buildQRCodeImage(inv);
        Test.stopTest();

        System.assert(!String.isBlank(qr), 'No request has been created');
    }
}