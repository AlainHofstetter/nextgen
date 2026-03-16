@IsTest
private class TestInvoicePosition {

  @IsTest(SeeAllData=true)
  private static void testTrigger() {

    SObjectType t = InvoicePos__c.SObjectType;
    fflib_QueryFactory qf = new fflib_QueryFactory(t);
    qf.selectFields(t.getDescribe().fields.getMap().values());
    qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    qf.setLimit(1);
    List<InvoicePos__c> theList = (List<InvoicePos__c>) Database.query(qf.toSOQL());

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
    InvoicePos__c invP = new InvoicePos__c(
        InvoicePositionAmount__c = 10
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IInvoicePosition invPDomain = InvoicePosition.newInstance(new List<InvoicePos__c> {invP});
    invPDomain.save(uowMock, inv);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              InvoicePos__c.Id => invP.Id,
              InvoicePos__c.InvoicePositionAmount__c => 10
            }
          ),
          fflib_Match.eqSObjectField(InvoicePos__c.InvoiceName__c),
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Invoice__c.Id => inv.Id
            }
          )
      );

  }

  @IsTest
  private static void callingSaveShouldCallRegisterDirty() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    InvoicePos__c invP = new InvoicePos__c(
        Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
        InvoicePositionAmount__c = 10
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IInvoicePosition invPDomain = InvoicePosition.newInstance(new List<InvoicePos__c> {invP});
    invPDomain.save(uowMock, new Invoice__c());

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              InvoicePos__c.Id => invP.Id,
              InvoicePos__c.InvoicePositionAmount__c => 10
            }
          )
      );

  }

  @IsTest
  private static void callingFindSuperiorShouldCallRegisterDirty() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Package__c pGroup = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType)
    );
    Package__c pTime = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType),
        PackageSuperior__c = pGroup.Id
    );
    InvoicePos__c invPGroup = new InvoicePos__c(
        Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
        PackageName__c = pGroup.Id
    );
    InvoicePos__c invPTime = new InvoicePos__c(
        Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
        PackageName__c = pTime.Id
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IInvoicePosition invPDomain = InvoicePosition.newInstance(new List<InvoicePos__c> {invPGroup, invPTime});
    invPDomain.findSuperiors(uowMock, new List<Package__c> {pGroup, pTime});

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              InvoicePos__c.Id => invPTime.Id,
              InvoicePos__c.InvoicePositionSuperior__c => invPGroup.Id
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
    new InvoicePosition(new List<InvoicePos__c> ()).callInheritedFieldValue(true);

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
    new InvoicePosition(new List<InvoicePos__c> ()).callInheritedFieldValue(false);

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
    new InvoicePosition(new List<InvoicePos__c> ()).callParentUpdate(new Map<Id, SObject>());

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
    new InvoicePosition(new List<InvoicePos__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

    // Then
    ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
    ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
  }

  @IsTest
  private static void testSetFinancialAccountInfo() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IInvoiceSelector iSelectorMock = new Mocks.InvoiceSelector(mocks);
    IFinanceAccountSelector fSelectorMock = new Mocks.FinanceAccountSelector(mocks);

    //Given
    mocks.startStubbing();
    Project__c proj = new Project__c(
        ProjectCostCenter__c = fflib_IDGenerator.generate(Account.SObjectType)
    );
    Invoice__c inv = new Invoice__c(Id = fflib_IDGenerator.generate(Invoice__c.SObjectType));
    inv.ProjectName__r = proj;
    InvoicePos__c invP = new InvoicePos__c(
        PackageType__c = 'Test',
        PackageSubType__c = 'SubTest',
        InvoiceName__c = inv.Id
    );
    FinanceAccount__c fa = new FinanceAccount__c(
        Id = fflib_IDGenerator.generate(FinanceAccount__c.SObjectType),
        FinanceAccountNr__c = '001',
        CostCenter__c = proj.ProjectCostCenter__c,
        TypeName__c = 'Test',
        TypeName2__c = 'SubTest'
    );
    mocks.when(iSelectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
    mocks.when(iSelectorMock.selectWithRelated(new Set<Id>{invP.InvoiceName__c}, new Set<String> {'ProjectName__r.ProjectCostCenter__c'})).thenReturn(new List<Invoice__c>{inv});
    mocks.when(fSelectorMock.sObjectType()).thenReturn(FinanceAccount__c.SObjectType);
    mocks.when(fSelectorMock.selectByCostCenterAndType(new Set<Id>{inv.ProjectName__r.ProjectCostCenter__c}, new Set<String>{invP.PackageType__c}, new Set<String>{invP.PackageSubType__c})).thenReturn(new List<FinanceAccount__c>{fa});
    mocks.stopStubbing();
    Application.Selector.setMock(iSelectorMock);
    Application.Selector.setMock(fSelectorMock);

    // When
    new InvoicePosition(new List<InvoicePos__c> {invP}).setFinancialAccountInfo();

    // Then
    ((IInvoiceSelector) mocks.verify(iSelectorMock)).selectWithRelated(new Set<Id>{invP.InvoiceName__c}, new Set<String> {'ProjectName__r.ProjectCostCenter__c'});
    ((IFinanceAccountSelector) mocks.verify(fSelectorMock)).selectByCostCenterAndType(new Set<Id>{inv.ProjectName__r.ProjectCostCenter__c}, new Set<String>{invP.PackageType__c}, new Set<String>{invP.PackageSubType__c});
    System.assertEquals(invP.FinanceAccount__c, fa.Id);
    System.assertEquals(invP.FinanceAccountNr__c, fa.FinanceAccountNr__c);
  }

}