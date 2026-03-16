@IsTest
private class TestHumanResourcesTabController {

  @IsTest
  private static void callingSaveDataShouldCallServiceTimeExpenseSupplierCostsServices() {

    // Create Mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();

    // Given
    Time__c t = new Time__c(Id = fflib_IDGenerator.generate(Time__c.SObjectType));
    Expense__c e = new Expense__c(Id = fflib_IDGenerator.generate(Expense__c.SObjectType));
    SupplierCosts__c sc = new SupplierCosts__c(Id = fflib_IDGenerator.generate(SupplierCosts__c.SObjectType));
    Mocks.TimeService mockTimeService = new Mocks.TimeService(mocks);
    Mocks.ExpenseService mockExpenseService = new Mocks.ExpenseService(mocks);
    Mocks.SupplierCostsService mockSupplierCostsService = new Mocks.SupplierCostsService(mocks);
    Application.Service.setMock(ITimeService.class, mockTimeService);
    Application.Service.setMock(IExpenseService.class, mockExpenseService);
    Application.Service.setMock(ISupplierCostsService.class, mockSupplierCostsService);

    // When
    HumanResourcesTabController.saveData(
        new List<Time__c> {t},
        new List<Expense__c> {e},
        new List<SupplierCosts__c> {sc}
    );

    // Then
    ((ITimeService) mocks.verify(mockTimeService)).save(new List<Time__c> {t});
    ((IExpenseService) mocks.verify(mockExpenseService)).save(new List<Expense__c> {e});
    ((ISupplierCostsService) mocks.verify(mockSupplierCostsService)).save(new List<SupplierCosts__c> {sc});

  }

}