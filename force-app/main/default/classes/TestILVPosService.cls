@IsTest
private class TestILVPosService {

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetILVCreation() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

    // Given
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(selectorMock.selectILVInfo(projectId, '2016-12-01', '2017-01-05')).thenReturn(null);
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    ILVPosService.get(projectId, '2016-12-01', '2017-01-05');

    // Then
    ((IPackageSelector) mocks.verify(selectorMock)).selectILVInfo(projectId, '2016-12-01', '2017-01-05');

  }

  @IsTest
  private static void callingServiceShouldCallDomainsAndCommitWork() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IInvoice invDomainMock = new Mocks.Invoice(mocks);
    IILVPos posDomainMock = new Mocks.ILVPos(mocks);

    // Given
    mocks.startStubbing();
    mocks.when(invDomainMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(posDomainMock.sObjectType()).thenReturn(ILVPos__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(invDomainMock);
    Application.Domain.setMock(posDomainMock);

    // When
    ILVPosService.save(new Invoice__c(), new List<ILVPos__c>());

    // Then
    ((IInvoice) mocks.verify(invDomainMock)).save(uowMock, Invoice.RECORD_TYPE_ILV);
    ((IILVPos) mocks.verify(posDomainMock)).save(uowMock, new Invoice__c());
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }

}