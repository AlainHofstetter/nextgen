@IsTest
private class TestPackageService {

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetFullPackages() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

    // Given
    mocks.startStubbing();
    PackageSelector.Model model = new PackageSelector.Model(new List<Package__c>());
    mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(selectorMock.selectFull(new PackageSelector.Params())).thenReturn(model);
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    PackageService.get(new PackageSelector.Params());

    // Then
    ((IPackageSelector) mocks.verify(selectorMock)).selectFull((PackageSelector.Params) fflib_Match.anyObject());

  }

  @IsTest
  private static void callingServiceShouldCallSelectorAndGetByProjectId() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

    // Given
    mocks.startStubbing();
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(selectorMock.selectByProjectId(new Set<Id>{projectId})).thenReturn(new List<Package__c>());
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    PackageService.get(projectId);

    // Then
    ((IPackageSelector) mocks.verify(selectorMock)).selectByProjectId(new Set<Id>{projectId});
  }

  @IsTest
  private static void callingServiceShouldCallDomainSave() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IPackageDomain domainMock = new Mocks.PackageDomain(mocks);

    //Given
    mocks.startStubbing();
    Package__c pck = new Package__c();
    mocks.when(domainMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    PackageService.save(new List<Package__c> {pck});

    // Then
    ((IPackageDomain) mocks.verify(domainMock)).save(uowMock);
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }

  @IsTest
  private static void callingServiceShouldCallDomainDel() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IPackageDomain domainMock = new Mocks.PackageDomain(mocks);

    //Given
    mocks.startStubbing();
    Package__c pck = new Package__c(Id = fflib_IDGenerator.generate(Package__c.SObjectType));
    mocks.when(domainMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    PackageService.del(new List<Package__c> {pck});

    // Then
    ((IPackageDomain) mocks.verify(domainMock)).del(uowMock);
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }
}