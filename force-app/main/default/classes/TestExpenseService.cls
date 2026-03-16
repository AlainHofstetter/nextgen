@IsTest
private class TestExpenseService {

  @IsTest
  private static void callingServiceShouldCallDomain() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IExpense domainMock = new Mocks.Expense(mocks);

    //Given
    mocks.startStubbing();
    Expense__c e = new Expense__c(CostsExpenseGross__c = 10);
    mocks.when(domainMock.sObjectType()).thenReturn(Expense__c.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    ExpenseService.save(new List<Expense__c> {e});

    // Then
    ((IExpense) mocks.verify(domainMock)).save(uowMock);
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

  }

}