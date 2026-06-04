@IsTest
private class TestSupplierCostsService {

  @IsTest
  private static void callingServiceShouldCallDomain() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    ISupplierCosts domainMock = new Mocks.SupplierCosts(mocks);

    //Given
    mocks.startStubbing();
    SupplierCosts__c sc = new SupplierCosts__c(CostsSupplierCostsGrossCHF__c = 10);
    mocks.when(domainMock.sObjectType()).thenReturn(SupplierCosts__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    SupplierCostsService.save(new List<SupplierCosts__c> {sc});

    // Then
    ((ISupplierCosts) mocks.verify(domainMock)).save(uowMock);
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }

}