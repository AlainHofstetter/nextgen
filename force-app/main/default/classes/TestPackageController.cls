@IsTest
private class TestPackageController {

  @IsTest
  private static void callingIsUserAllowedShouldCallUserServiceGetLogged() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Mocks.UserService mockUserService = new Mocks.UserService(mocks);
    Application.Service.setMock(IUserService.class, mockUserService);

    // When
    PackageController.isUserAllowed();

    // Then
    ((IUserService) mocks.verify(mockUserService)).getLogged();

  }

  @IsTest
  private static void callingGetShouldCallServiceGet() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Id projectId = fflib_IDGenerator.generate(Project__c.SObjectType);
    Mocks.PackageService mockPackageService = new Mocks.PackageService(mocks);
    Application.Service.setMock(IPackageService.class, mockPackageService);

    // When
    PackageController.get(projectId);

    // Then
    ((IPackageService) mocks.verify(mockPackageService)).get(projectId);

  }

  @IsTest
  private static void callingGetShouldCallServiceSave() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    List<Package__c> pcks = new List<Package__c>{new Package__c()};
    Mocks.PackageService mockPackageService = new Mocks.PackageService(mocks);
    Application.Service.setMock(IPackageService.class, mockPackageService);

    // When
    PackageController.save(pcks);

    // Then
    ((IPackageService) mocks.verify(mockPackageService)).save(pcks);

  }

  @IsTest
  private static void callingGetShouldCallServiceDel() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    List<Package__c> pcks = new List<Package__c>{new Package__c(Id = fflib_IDGenerator.generate(Package__c.SObjectType))};
    Mocks.PackageService mockPackageService = new Mocks.PackageService(mocks);
    Application.Service.setMock(IPackageService.class, mockPackageService);

    // When
    PackageController.del(pcks);

    // Then
    ((IPackageService) mocks.verify(mockPackageService)).del(pcks);

  }

}