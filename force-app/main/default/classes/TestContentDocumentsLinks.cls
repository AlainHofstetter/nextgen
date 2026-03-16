/**
 * Created by dudunato on 28.11.17.
 */

@IsTest
private class TestContentDocumentsLinks {

    @IsTest
    private static void testTrigger() {
        Account acct = new Account(Name = 'TEST_ACCT');
        insert acct;

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
        );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acct.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
    }


    @IsTest
    private static void testCheckInvoiceAttachments() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IInvoiceSelector selectorMock = new Mocks.InvoiceSelector(mocks);

        // Given
        mocks.startStubbing();
        Invoice__c inv = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)
        );
        ContentDocumentLink doc = new ContentDocumentLink(LinkedEntityId = inv.Id);
        mocks.when(selectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
        mocks.when(selectorMock.selectDocuments(new Set<Id>{
                inv.Id
        })).thenReturn(new List<ContentDocumentLink>{
                doc
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);

        // When
        new ContentDocumentLinks(new List<ContentDocumentLink>{
                doc
        }).checkInvoiceAttachments(null);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.Id => inv.Id,
                                Invoice__c.ValHasAttachment__c => true
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

}