/***************************************************************************************************
*  InvoiceHelperTest.cls
*
*  @description   Comprehensive unit tests for the InvoiceHelper class.  
*                 Verifies behaviour of:
*                 • updateQRCode – regenerates a QR code only when an eligible Invoice__c
*                   record changes.  
*                 • haveMonitoredFieldsChanged – detects changes in monitored fields.  
*
*  @created       2025-07-09
*  @author        david@inspireai.com
*
***************************************************************************************************/
@isTest
private class InvoiceHelperTest {
    @TestSetup
    static void makeData(){
        TestFactory.makeData();
    }

    /**
     *  Eligible invoice where a monitored field was modified
     *     - Create an invoice that meets QR-code criteria and then create a copy of it
     *       and change a monitored field. This is to simulate an after update trigger.
     *     - Invoke InvoiceHelper.updateQRCode via the after-update hook-style call.  
     *     - Assert: Exactly one record is flagged for regeneration.
     **/
    @isTest
    static void testUpdateQRCode_EligibleInvoice() {
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());

        // Create test Account with required Name and BillingCountry__c = SWITZERLAND
        Account receiver = new Account(Name = 'Swiss Account', BillingCountry__c='SWITZERLAND', LegalNature__c = 'Limited Partnership',
                                       AccountLanguage__c = 'D');
        insert receiver;

        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        // Insert old Invoice with one monitored field
        Invoice__c oldInvoice = new Invoice__c(
            InvoiceReceiver__c = receiver.Id,
            BillingAddressZIP__c = '8000',
            ProjectName__c = proj.Id,
            ESRAccountNr__c = '01-8513-5',
            ESRMergentNr__c = '207115',
            InvoiceDocumentNr__c = 25010829
        );
        insert oldInvoice;

        // Simulate a monitored field change
        Invoice__c newInvoice = oldInvoice.clone(false, true, false, false);
        newInvoice.Id = oldInvoice.Id;
        newInvoice.BillingAddressZIP__c = '9000';
        // insert newInvoice;

        Map<Id, Invoice__c> oldMap = new Map<Id, Invoice__c>{ oldInvoice.Id => oldInvoice };
        Map<Id, Invoice__c> newMap = new Map<Id, Invoice__c>{ newInvoice.Id => newInvoice };

        Test.startTest();
            InvoiceHelper.updateQRCode(oldMap, newMap);
        Test.stopTest();

        Map<Id, Invoice__c> filtered = InvoiceHelper.filterInvoicesForQRCode(oldMap, newMap);
        System.assertEquals(1, filtered.size(), 'Expected invoice to qualify for QR code regeneration');
    }

    /**
     *  Invoice updated but with no field change
     *    - Create an invoice and make a copy of it unchanged.  
     *    - Invoke updateQRCode.  
     *    - Assert No invoice qualifies.
     **/
    @isTest
    static void testUpdateQRCode_NoChanges() {
        Test.setMock(HttpCalloutMock.class, new QRCodeServiceMockResponse());

        // Create test Account with required Name and BillingCountry__c = SWITZERLAND
        Account receiver = new Account(Name = 'Swiss Account', BillingCountry__c='SWITZERLAND', LegalNature__c = 'Limited Partnership',
                                       AccountLanguage__c = 'D');
        insert receiver;

        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Invoice__c invoice = new Invoice__c(
            InvoiceReceiver__c = receiver.Id,
            BillingAddressZIP__c = '8000',
            ProjectName__c = proj.Id,
            ESRAccountNr__c = '01-8513-5',
            ESRMergentNr__c = '207115',
            InvoiceDocumentNr__c = 25010829
        );
        insert invoice;

        Invoice__c unchanged = invoice.clone(false, true, false, false);
        unchanged.Id = invoice.Id;

        Map<Id, Invoice__c> oldMap = new Map<Id, Invoice__c>{ invoice.Id => invoice };
        Map<Id, Invoice__c> newMap = new Map<Id, Invoice__c>{ unchanged.Id => unchanged };

        Test.startTest();
            InvoiceHelper.updateQRCode(oldMap, newMap);
        Test.stopTest();

        Map<Id, Invoice__c> filtered = InvoiceHelper.filterInvoicesForQRCode(oldMap, newMap);
        System.assertEquals(0, filtered.size(), 'Invoice should not qualify for QR update');
    }

    /**
     * Directly asserts the helper’s utility method with a before/after pair.
     * Check that if it detects a change and returns true.
     */
    @isTest
    static void testHaveMonitoredFieldsChanged() {
        // Create test Account with required Name and BillingCountry__c = SWITZERLAND
        Account receiver = new Account(Name = 'Swiss Account', BillingCountry__c='SWITZERLAND', LegalNature__c = 'Limited Partnership',
                                       AccountLanguage__c = 'D');
        insert receiver;

        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Invoice__c oldInv = new Invoice__c(BillingAddressZIP__c = '1000', ProjectName__c = proj.Id);

        Invoice__c newInv = oldInv.clone(false, true, false, false);
        newInv.BillingAddressZIP__c = '2000';
        newInv.Id = oldInv.Id;

        Boolean changed = InvoiceHelper.haveMonitoredFieldsChanged(oldInv, newInv);

        System.assertEquals(true, changed, 'Expected monitored field change to be detected');
    }
}