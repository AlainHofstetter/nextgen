@IsTest
private class TestExpense {

  @IsTest(SeeAllData=true)
  private static void testTrigger() {
    SObjectType t = Expense__c.SObjectType;
    fflib_QueryFactory qf = new fflib_QueryFactory(t);
    qf.selectField('Id');
    qf.setCondition('ExpenseValidatedFinance__c = false AND ExpenseValidatedProjectResponsible__c = false AND Expensetracker__c != NULL AND Expensetracker__r.User__r.InternalContactID__c != NULL');
    qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    qf.setLimit(1);

    List<Expense__c> theList = (List<Expense__c>) Database.query(qf.toSOQL());

    if (!theList.isEmpty())
      update theList;
  }

  @IsTest
  private static void callingSaveShouldRegisterNew() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Expense__c e = new Expense__c(
        CostsExpenseGross__c = 10
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IExpense eDomain = Expense.newInstance(new List<Expense__c> {e});
    eDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Expense__c.CostsExpenseGross__c => e.CostsExpenseGross__c
            }
          )
      );
  }

  @IsTest
  private static void callingSaveShouldRegisterDirty() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Expense__c e = new Expense__c(
        Id = fflib_IDGenerator.generate(Expense__c.SObjectType),
        CostsExpenseGross__c = 10
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IExpense eDomain = Expense.newInstance(new List<Expense__c> {e});
    eDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Expense__c.Id => e.Id,
              Expense__c.CostsExpenseGross__c => e.CostsExpenseGross__c
            }
          )
      );
  }

    @IsTest
  private static void callingCallInheritedFieldValueShouldCallDomainAndCommmitWork() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IInheritedFieldValueMDT domainMock = new Mocks.InheritedFieldValueMDT(mocks);

    //Given
    mocks.startStubbing();
    mocks.when(domainMock.sObjectType()).thenReturn(InheritedFieldValue__mdt.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    new Expense(new List<Expense__c> ()).callInheritedFieldValue(true);

    // Then
    ((IInheritedFieldValueMDT) mocks.verify(domainMock)).go(uowMock, new List<SObject>());
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
  }

  @IsTest
  private static void callingCallInheritedFieldValueShouldCallDomain() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IInheritedFieldValueMDT domainMock = new Mocks.InheritedFieldValueMDT(mocks);

    //Given
    mocks.startStubbing();
    mocks.when(domainMock.sObjectType()).thenReturn(InheritedFieldValue__mdt.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Domain.setMock(domainMock);

    // When
    new Expense(new List<Expense__c> ()).callInheritedFieldValue(false);

    // Then
    ((IInheritedFieldValueMDT) mocks.verify(domainMock)).go(null, new List<SObject>());
  }

  @IsTest
  private static void callingCallParentUpdateShouldCallDomainAndCommmitWork() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IParentObjectUpdateMDTSelector selectorMock = new Mocks.ParentObjectUpdateMDTSelector(mocks);
    IParentObjectUpdateMDT domainMock = new Mocks.ParentObjectUpdateMDT(mocks);

    //Given
    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(ParentObjectUpdate__mdt.SObjectType);
    mocks.when(selectorMock.selectBySourceObj(fflib_Match.anyString())).thenReturn(new List<ParentObjectUpdate__mdt>());
    mocks.when(domainMock.sObjectType()).thenReturn(ParentObjectUpdate__mdt.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Selector.setMock(selectorMock);
    Application.Domain.setMock(domainMock);

    // When
    new Expense(new List<Expense__c> ()).callParentUpdate(new Map<Id, SObject>());

    // Then
    ((IParentObjectUpdateMDTSelector) mocks.verify(selectorMock)).selectBySourceObj(fflib_Match.anyString());
    ((IParentObjectUpdateMDT) mocks.verify(domainMock)).go(uowMock, new List<SObject>(), new Map<Id, SObject>());
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
  }

  @IsTest
  private static void callingCallUpdateExchangeRateShouldCallDomainAndCommmitWork() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
    IObjectMDTSelector selectorMock = new Mocks.ObjectMDTSelector(mocks);
    IFieldMDT domainMock = new Mocks.FieldMDT(mocks);

    //Given
    Object__mdt obj
      = ((List<Object__mdt>) fflib_ApexMocksUtils.makeRelationship(
        List<Object__mdt>.class,
        new List<Object__mdt> {new Object__mdt()},
        Field__mdt.Object__c,
        new List<List<Field__mdt>> { new List<Field__mdt> {new Field__mdt()}}
      ))[0];
    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Object__mdt.SObjectType);
    mocks.when(selectorMock.selectCurrencyFields(fflib_Match.anyString())).thenReturn(new List<Object__mdt>{obj});
    mocks.when(domainMock.sObjectType()).thenReturn(Field__mdt.SObjectType);
    mocks.stopStubbing();
    Application.UnitOfWork.setMock(uowMock);
    Application.Selector.setMock(selectorMock);
    Application.Domain.setMock(domainMock);

    // When
    new Expense(new List<Expense__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

    // Then
    ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
    ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
  }

  @IsTest
  private static void testSetExpenseTracker() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IUserSelector selectorMock = new Mocks.UserSelector(mocks);

    //Given
    mocks.startStubbing();
    User u = new User(InternalContactID__c = fflib_IDGenerator.generate(Contact.SObjectType));
    Expense__c e = new Expense__c();
    mocks.when(selectorMock.sObjectType()).thenReturn(User.SObjectType);
    mocks.when(selectorMock.selectById(fflib_Match.anyId())).thenReturn(u);
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    new Expense(new List<Expense__c> {e}).setExpenseTracker();

    // Then
    ((IUserSelector) mocks.verify(selectorMock)).selectById(fflib_Match.anyId());
    System.assertEquals(u.InternalContactID__c, e.Expensetracker__c);
  }

  @IsTest
  private static void testSecExchangeRate() {

    Expense__c e = new Expense__c(
        ExpenseDate__c = Date.today(),
        LocalCurrency__c = 'CHF',
        VATPercent__c = '0%',
        CurrencyRateToCHF__c = 0.3,
        RecordTypeId = Utils.getRecordTypeIdByDevName('Expense__c', Expense.CAR_TRAVEL)
    );

    // When
    new Expense(new List<Expense__c> {e}).setSecExchangeRate();

    // Then
    System.assertEquals(0, e.Distance__c);
    System.assertEquals(0, e.DistanceCompensation__c);
    System.assertEquals(0, e.ExpenseGross__c);
    System.assertEquals(0, e.ExpenseGrossApproved__c);
    System.assertNotEquals(null, e.CostsExpenseNet__c);
    System.assertEquals(e.ServiceExpenseNet__c, e.CostsExpenseNet__c);
  }

  @IsTest
  private static void testGetExchangeRate() {

    List<DatedConversionRate> rates = DatedConversionRateSelector.newInstance().selectAll();
    Expense eDomain = new Expense(new List<Expense__c>{new Expense__c()});
    Double exchangeRate = eDomain.getExchangeRate(rates, System.today(), 'CHF');
    System.assert(exchangeRate > 0);

  }

}