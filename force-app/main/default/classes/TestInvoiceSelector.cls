@IsTest
private class TestInvoiceSelector {

    @IsTest
    static void getSObjectFieldList_containsRequiredFields() {
        // Use the concrete selector implementation directly
        InvoiceSelector selector = new InvoiceSelector();

        List<Schema.SObjectField> fields = selector.getSObjectFieldList();

        System.assert(
            fields.contains(Invoice__c.PeriodFrom__c),
            'InvoiceSelector must select Invoice__c.PeriodFrom__c'
        );
        System.assert(
            fields.contains(Invoice__c.PeriodUntil__c),
            'InvoiceSelector must select Invoice__c.PeriodUntil__c'
        );
        System.assert(
            fields.contains(Invoice__c.Id),
            'InvoiceSelector should select Invoice__c.Id as a base field'
        );
    }

    @IsTest
    static void newInstance_and_getSObjectType_work() {
        // Covers static newInstance()
        IInvoiceSelector inst = InvoiceSelector.newInstance();
        System.assertNotEquals(null, inst, 'newInstance should return a non-null selector');

        // Covers public override of getSObjectType()
        InvoiceSelector concrete = new InvoiceSelector();
        Schema.SObjectType typeFromSelector = concrete.getSObjectType();

        System.assertEquals(
            Invoice__c.SObjectType,
            typeFromSelector,
            'getSObjectType must return Invoice__c.SObjectType'
        );
    }

    @IsTest
    static void selectWithRelated_executesQuery_noData() {
        InvoiceSelector selector = new InvoiceSelector();

        // Empty id set still exercises query-building; SOQL is valid for Invoice__c
        Set<Id> ids = new Set<Id>();
        Set<String> related = new Set<String>{
            'Id',
            'Name'
        };

        Test.startTest();
        List<Invoice__c> result = selector.selectWithRelated(ids, related);
        Test.stopTest();

        System.assertEquals(
            0,
            result.size(),
            'With an empty id set, selectWithRelated should return an empty list'
        );
    }

    @IsTest
    static void draftByProject_executesQuery_andReturnsNullWithoutMatches() {
        InvoiceSelector selector = new InvoiceSelector();

        // Any Id / type name will do; query simply won't match any rows
        Id fakeProjectId = UserInfo.getUserId();
        String invoiceTypeName = 'NonExistingRecordTypeName';

        Test.startTest();
        Invoice__c draft = selector.draftByProject(fakeProjectId, invoiceTypeName);
        Test.stopTest();

        System.assertEquals(
            null,
            draft,
            'Without matching data, draftByProject should return null'
        );
    }

    @IsTest
    static void selectDocuments_withNonEmptyIdsReturnsEmptyListWhenNoLinks() {
        InvoiceSelector selector = new InvoiceSelector();

        // IMPORTANT: ContentDocumentLink requires a non-empty Id set in the filter
        Set<Id> ids = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        List<ContentDocumentLink> links = selector.selectDocuments(ids);
        Test.stopTest();

        // We don't expect any matches, but the query must run without throwing
        System.assertEquals(
            0,
            links.size(),
            'With a non-matching id, selectDocuments should return an empty list'
        );
    }
}