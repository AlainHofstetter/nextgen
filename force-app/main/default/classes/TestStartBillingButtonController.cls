@IsTest
private class TestStartBillingButtonController {

  @IsTest
  private static void callingGetShouldCallService() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Id invId = fflib_IDGenerator.generate(Invoice__c.SObjectType);
    Mocks.InvoiceService mockInvoiceService = new Mocks.InvoiceService(mocks);
    Application.Service.setMock(IInvoiceService.class, mockInvoiceService);

    // When
    StartBillingButtonController.get(invId);

    // Then
    ((IInvoiceService) mocks.verify(mockInvoiceService)).get(invId);

  }

}