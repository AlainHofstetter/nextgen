@IsTest
private class TestInvoiceService {

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetInvoice() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IInvoiceSelector selectorMock = new Mocks.InvoiceSelector(mocks);

    // Given
    mocks.startStubbing();
    Invoice__c inv = new Invoice__c(
        Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)
    );
    mocks.when(selectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(selectorMock.selectSObjectsById(new Set<Id>{inv.Id})).thenReturn(new List<SObject>{inv});
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    InvoiceService.get(inv.Id);

    // Then
    ((IInvoiceSelector) mocks.verify(selectorMock)).selectSObjectsById(new Set<Id>{inv.Id});

  }

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetProjectStruture() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

    // Given
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    mocks.startStubbing();
    ProjectStructureBean proj = new ProjectStructureBean(null, new List<Package__c>());
    mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(selectorMock.selectProjectStructure(projectId, '2016-12-01', '2017-01-05')).thenReturn(proj);
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    InvoiceService.getProjectStructure(projectId, '2016-12-01', '2017-01-05');

    // Then
    ((IPackageSelector) mocks.verify(selectorMock)).selectProjectStructure(projectId, '2016-12-01', '2017-01-05');

  }

  @IsTest
  private static void callingServiceShouldCallSelectAndCancelAndCommitWork() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IInvoiceSelector selectorMock = new Mocks.InvoiceSelector(mocks);
    IInvoice domainMock = new Mocks.Invoice(mocks);

    // Given
    Id invoiceId = fflib_IDGenerator.generate(Invoice__c.SObjectType);
    mocks.startStubbing();
    ProjectStructureBean proj = new ProjectStructureBean(null, new List<Package__c>());
    mocks.when(selectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(selectorMock.selectSObjectsById(new Set<Id> {invoiceId})).thenReturn(new List<Invoice__c>());
    mocks.when(domainMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(domainMock.cancel(uowMock)).thenReturn(new List<Invoice__c>{ new Invoice__c()});
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Selector.setMock(selectorMock);
    Application.Domain.setMock(domainMock);

    // When
    InvoiceService.cancel(invoiceId);

    // Then
    ((IInvoiceSelector) mocks.verify(selectorMock)).selectSObjectsById(new Set<Id> {invoiceId});
    ((IInvoice) mocks.verify(domainMock)).cancel(uowMock);

  }

  @IsTest
  private static void callingServiceShouldCallDomainsAndCommitWorkTwice() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IInvoice invDomainMock = new Mocks.Invoice(mocks);
    IInvoicePosition posDomainMock = new Mocks.InvoicePosition(mocks);
    IPackageDomain pckDomainMock = new Mocks.PackageDomain(mocks);

    // Given
    mocks.startStubbing();
    mocks.when(invDomainMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(posDomainMock.sObjectType()).thenReturn(InvoicePos__c.SObjectType);
    mocks.when(pckDomainMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(invDomainMock);
    Application.Domain.setMock(posDomainMock);
    Application.Domain.setMock(pckDomainMock);

    // When
    InvoiceService.save(new Invoice__c(), new List<Package__c>(), new List<InvoicePos__c>());

    // Then
    ((IInvoice) mocks.verify(invDomainMock)).save(uowMock, Invoice.RECORD_TYPE_INVOICE);
    ((IPackageDomain) mocks.verify(pckDomainMock)).save(uowMock);
    ((IInvoicePosition) mocks.verify(posDomainMock)).save(uowMock, new Invoice__c());
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 2)).commitWork();

  }

}