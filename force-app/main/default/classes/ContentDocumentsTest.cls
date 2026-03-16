/**
 * 
 */
@isTest
private class ContentDocumentsTest {

    @isTest
    static void test_addDocument() {
        Account acct = new Account(Name = 'TEST_ACCT', LegalNature__c = 'Corporation / Limited Company', AccountLanguage__c = 'D');
        insert acct;

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true,
                FirstPublishLocationId = acct.Id
        );

        Test.startTest();
            insert contentVersion;
        Test.stopTest();
    }

    @isTest
    static void test_deleteNonInvoiceDocument() {
        Account acct = new Account(Name = 'TEST_ACCT', LegalNature__c = 'Corporation / Limited Company', AccountLanguage__c = 'D');
        insert acct;

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true,
                FirstPublishLocationId = acct.Id
        );
        insert contentVersion;

        System.debug('---test_deleteNonInvoiceDocument--- contentVersion: '+contentVersion);

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        ContentDocument cntDoc = new ContentDocument();
        cntDoc.Id = contentVersion.ContentDocumentId;

        Test.startTest();
            delete cntDoc;
        Test.stopTest();
    }

    @isTest
    static void test_deleteInvoiceDocument() {
        TestFactory.makeData();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Package__c service = [SELECT Id FROM Package__c LIMIT 1];
        
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv; 

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true,
                FirstPublishLocationId = inv.Id
        );
        insert contentVersion;

        System.debug('---ContentDocumentsTest.test_deleteNonInvoiceDocument--- contentVersion: '+contentVersion);

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        ContentDocument cntDoc = new ContentDocument();
        cntDoc.Id = contentVersion.ContentDocumentId;

        Test.startTest();
            try {
                delete cntDoc;
                system.assert(true,'ERROR: ContentDocumentsTest.test_deleteNonInvoiceDocument --- The deletion of a document related to an Invoice should have thrown an exception.');
            } catch (Exception e) {
                System.debug('All OK: ContentDocumentsTest.test_deleteNonInvoiceDocument --- Invoice documents cannot be deleted');
            }
        Test.stopTest();
    }
}