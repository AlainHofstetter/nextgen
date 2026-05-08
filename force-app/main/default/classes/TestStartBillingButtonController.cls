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

    // Stub UserService to return a project-manager user so the early-return guard is bypassed.
    // Without this, the real DB user (not a PM) causes get() to return null before calling InvoiceService.
    // See TARGET_COMPAT_NOTES.md.
    Mocks.UserService mockUserService = new Mocks.UserService(mocks);
    Application.Service.setMock(IUserService.class, mockUserService);
    mocks.startStubbing();
    mocks.when(mockUserService.getLogged()).thenReturn(new User(IsProjectManager__c = true));
    mocks.stopStubbing();

    // When
    StartBillingButtonController.get(invId);

    // Then
    ((IInvoiceService) mocks.verify(mockInvoiceService)).get(invId);

  }

}
