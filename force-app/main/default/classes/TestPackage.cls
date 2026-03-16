@IsTest
public class TestPackage {

  @IsTest(SeeAllData=true)
  private static void testTrigger() {
    SObjectType t = Package__c.SObjectType;
    fflib_QueryFactory qf = new fflib_QueryFactory(t);
    qf.selectFields(t.getDescribe().fields.getMap().values());
    qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    qf.setLimit(1);
    List<Package__c> theList = (List<Package__c>) Database.query(qf.toSOQL());

    if (!theList.isEmpty())
      update theList;
  }

  @IsTest
  private static void callingSaveShouldCallRegisterNew() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Package__c pck = new Package__c(
        ShowPositionAmount__c = true
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IPackageDomain pDomain = PackageDomain.newInstance(new List<Package__c> {pck});
    pDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Package__c.ShowPositionAmount__c => true
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
    Package__c pck = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType),
        ShowPositionAmount__c = true
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IPackageDomain pDomain = PackageDomain.newInstance(new List<Package__c> {pck});
    pDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Package__c.Id => pck.Id,
              Package__c.ShowPositionAmount__c => true
            }
          )
      );

  }

  @IsTest
  private static void callingDelShouldCallRegisterDeleted() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Package__c pck = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType)
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    IPackageDomain pDomain = PackageDomain.newInstance(new List<Package__c> {pck});
    pDomain.del(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDeleted(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Package__c.Id => pck.Id
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
    new PackageDomain(new List<Package__c> ()).callInheritedFieldValue(true);

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
    new PackageDomain(new List<Package__c> ()).callInheritedFieldValue(false);

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
    new PackageDomain(new List<Package__c> ()).callParentUpdate(new Map<Id, SObject>());

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
    new PackageDomain(new List<Package__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

    // Then
    ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
    ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
  }

}