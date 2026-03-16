/**
 * @description
 *   Unit test class for InvoiceInvocableService. Validates that the invocable method
 *   processes a request for invoice creation or cancellation.
 *
 * @Who:         david@inspireai.com
 * @When:        2025-07-09
 */
@isTest
private class InvoiceInvocableServiceTest {
    @TestSetup
    static void makeData(){
        TestFactory.makeData();
    }

    /**
     * @description
     *   Test the invoiceServices method with a valid invoice creation request.
     *   This assumes InvoiceDocumentController.createInvoicePDF is a static method and is safe to call during test.
     */
    @isTest
    static void testInvoiceService_Create() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv;

        // Arrange: Create test request
        InvoiceInvocableService.Requests request = new InvoiceInvocableService.Requests(inv.Id, InvoiceInvocableService.SERVICE_CREATE_INVOICE);
        List<InvoiceInvocableService.Requests> requests = new List<InvoiceInvocableService.Requests>{request};

        Test.startTest();
            // Act: Call the invocable method
            InvoiceInvocableService.invoiceServices(requests);
        Test.stopTest();

        // Assert: No exceptions means success (can extend to validate effects if applicable)
        System.assertEquals(1, requests.size(), 'One request should be processed');
        System.assertEquals(inv.Id, requests[0].invoiceId);
        System.assertEquals(InvoiceInvocableService.SERVICE_CREATE_INVOICE, requests[0].service);
    }

    /**
     * @description
     *   Test the invoiceServices method with a valid invoice cancellation request.
     */
    @isTest
    static void testInvoiceService_Cancel() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        CostCenter__c costCenter = [SELECT Id FROM CostCenter__c LIMIT 1];
        Invoice__c inv = TestFactory.createInvoice(acc.Id, proj.Id, costCenter.Id);
        insert inv;

        // Arrange
        InvoiceInvocableService.Requests request = new InvoiceInvocableService.Requests(inv.Id, InvoiceInvocableService.SERVICE_CANCEL_INVOICE);
        List<InvoiceInvocableService.Requests> requests = new List<InvoiceInvocableService.Requests>{request};

        Test.startTest();
            InvoiceInvocableService.invoiceServices(requests);
        Test.stopTest();

        // Assert
        System.assertEquals(inv.Id, requests[0].invoiceId);
        System.assertEquals(InvoiceInvocableService.SERVICE_CANCEL_INVOICE, requests[0].service);
    }
}