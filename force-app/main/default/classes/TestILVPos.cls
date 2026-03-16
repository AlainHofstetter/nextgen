@IsTest
private class TestILVPos {

  @IsTest(SeeAllData=true)
  private static void testTrigger() {

    SObjectType t = ILVPos__c.SObjectType;
    fflib_QueryFactory qf = new fflib_QueryFactory(t);
    qf.selectField('Id');
    qf.setCondition('InvoiceName__r.InvoiceStatus__c = \'Draft\'');
    qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    qf.setLimit(1);
    List<ILVPos__c> theList = (List<ILVPos__c>) Database.query(qf.toSOQL());

    if (!theList.isEmpty())
      update theList;
  }

  @IsTest
  private static void callingSaveShouldCallRegisterNew() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Invoice__c inv = new Invoice__c(
        Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)
    );
    ILVPos__c ip = new ILVPos__c();
    Application.UnitOfWork.setMock(uowMock);

    // When
    IILVPos ipDomain = ILVPos.newInstance(new List<ILVPos__c> {ip});
    ipDomain.save(uowMock, inv);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(ip, ILVPos__c.InvoiceName__c, inv);

  }

  @IsTest
  private static void callingSaveShouldCallRegisterDirty() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    ILVPos__c ip = new ILVPos__c(
        Id = fflib_IDGenerator.generate(ILVPos__c.SObjectType)
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IILVPos ipDomain = ILVPos.newInstance(new List<ILVPos__c> {ip});
    ipDomain.save(uowMock, null);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(ip);

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
    new ILVPos(new List<ILVPos__c> ()).callInheritedFieldValue(true);

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
    new ILVPos(new List<ILVPos__c> ()).callInheritedFieldValue(false);

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
    new ILVPos(new List<ILVPos__c> ()).callParentUpdate(new Map<Id, SObject>());

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
    new ILVPos(new List<ILVPos__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

    // Then
    ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
    ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
  }

  /* @IsTest */
  /* private static void testSetFinancialAccountInfo() { */
  /*  */
  /*   // Create mocks */
  /*   fflib_ApexMocks mocks = new fflib_ApexMocks(); */
  /*   IInvoiceSelector iSelectorMock = new Mocks.InvoiceSelector(mocks); */
  /*   IFinanceAccountSelector fSelectorMock = new Mocks.FinanceAccountSelector(mocks); */
  /*   ICostCenterSelector ccSelectorMock = new Mocks.CostCenterSelector(mocks); */
  /*  */
  /*   //Given */
  /*   mocks.startStubbing(); */
  /*   Project__c proj = new Project__c( */
  /*       ProjectCostCenter__c = fflib_IDGenerator.generate(Account.SObjectType) */
  /*   ); */
  /*   Invoice__c inv = new Invoice__c(Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)); */
  /*   inv.ProjectName__r = proj; */
  /*   CostCenter__c cc = new CostCenter__c(Id = fflib_IDGenerator.generate(CostCenter__c.SObjectType)); */
  /*   ILVPos__c invP = new ILVPos__c( */
  /*       ILVType__c = 'Test', */
  /*       InvoiceName__c = inv.Id, */
  /*       CostCenterILVReceiver__c = cc.Id */
  /*   ); */
  /*   FinanceAccount__c fa = new FinanceAccount__c( */
  /*       Id = fflib_IDGenerator.generate(FinanceAccount__c.SObjectType), */
  /*       FinanceAccountNr__c = '001' */
  /*   ); */
  /*   mocks.when(iSelectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType); */
  /*   mocks.when(iSelectorMock.selectWithRelated(new Set<Id>{invP.InvoiceName__c}, new Set<String> {'ProjectName__r.ProjectCostCenter__c'})).thenReturn(new List<Invoice__c>{inv}); */
  /*   mocks.when(fSelectorMock.sObjectType()).thenReturn(FinanceAccount__c.SObjectType); */
  /*   mocks.when(fSelectorMock.selectByCostCenterAndType(inv.ProjectName__r.ProjectCostCenter__c, invP.PackageType__c)).thenReturn(fa); */
  /*   mocks.stopStubbing(); */
  /*   Application.Selector.setMock(iSelectorMock); */
  /*   Application.Selector.setMock(fSelectorMock); */
  /*  */
  /*   // When */
  /*   new InvoicePosition(new List<InvoicePos__c> {invP}).setFinancialAccountInfo(); */
  /*  */
  /*   // Then */
  /*   ((IInvoiceSelector) mocks.verify(iSelectorMock)).selectWithRelated(new Set<Id>{invP.InvoiceName__c}, new Set<String> {'ProjectName__r.ProjectCostCenter__c'}); */
  /*   ((IFinanceAccountSelector) mocks.verify(fSelectorMock)).selectByCostCenterAndType(inv.ProjectName__r.ProjectCostCenter__c, invP.PackageType__c); */
  /* } */

}