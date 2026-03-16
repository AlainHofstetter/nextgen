@IsTest
private class TestTimeService {

  @IsTest
  private static void callingServiceShouldCallDomain() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    ITimeDomain domainMock = new Mocks.TimeDomain(mocks);

    //Given
    mocks.startStubbing();
    Time__c t = new Time__c(DurationHhMmN__c = 1);
    mocks.when(domainMock.sObjectType()).thenReturn(Time__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    TimeService.save(new List<Time__c> {t});

    // Then
    ((ITimeDomain) mocks.verify(domainMock)).save(uowMock);
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }

}