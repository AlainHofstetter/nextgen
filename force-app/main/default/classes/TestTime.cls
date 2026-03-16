@IsTest
private class TestTime {

  @IsTest(SeeAllData=true)
  private static void testTrigger() {
    SObjectType t = Time__c.SObjectType;
    fflib_QueryFactory qf = new fflib_QueryFactory(t);
    qf.selectFields(t.getDescribe().fields.getMap().values());
    qf.setCondition('Timetracker__r.User__r.InternalContactID__c != NULL');
    qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    qf.setLimit(1);
    List<Time__c> theList = (List<Time__c>) Database.query(qf.toSOQL());

    if (!theList.isEmpty())
      update theList;
  }

  @IsTest
  private static void callingSaveShouldRegisterNew() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    //Given
    Time__c t = new Time__c(
        DurationHhMmN__c = 1
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    ITimeDomain tDomain = TimeDomain.newInstance(new List<Time__c> {t});
    tDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Time__c.DurationHhMmN__c => t.DurationHhMmN__c
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
    Time__c t = new Time__c(
        Id = fflib_IDGenerator.generate(Time__c.SObjectType),
        DurationHhMmN__c = 1
    );
    Application.UnitOfWork.setMock(uowMock);

    // When
    ITimeDomain tDomain = TimeDomain.newInstance(new List<Time__c> {t});
    tDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Time__c.Id => t.Id,
              Time__c.DurationHhMmN__c => t.DurationHhMmN__c
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
    new TimeDomain(new List<Time__c> ()).callInheritedFieldValue(true);

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
    new TimeDomain(new List<Time__c> ()).callInheritedFieldValue(false);

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
    new TimeDomain(new List<Time__c> ()).callParentUpdate(new Map<Id, SObject>());

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
    new TimeDomain(new List<Time__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

    // Then
    ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
    ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
  }

  @IsTest
  private static void testSetTimeDuration() {

    // Given
    Time__c t = new Time__c(
        DurationHhMm__c = '8:30'
    );

    // When
    TimeDomain tDomain = new TimeDomain(new List<Time__c> {t});
    tDomain.setTimeDuration();

    // Then
    System.assertEquals( 8.5, t.DurationHhMmN__c);
  }

  @IsTest
  private static void testSetAbacusTimeTypeDefault() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector pckSelectorMock = new Mocks.PackageSelector(mocks);
    IContactSelector cSelectorMock = new Mocks.ContactSelector(mocks);

    // Given
    mocks.startStubbing();
    Contact c = new Contact(
        Id = fflib_IDGenerator.generate(Contact.SObjectType),
        AbacusDefaultTimeType__c = TimeDomain.ABACUSTIME_TYPE_DEFAULT
    );
    Package__c pck = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType),
        AbacusTimeType__c = TimeDomain.ABACUSTIME_TYPE_DEFAULT
    );
    Time__c t = new Time__c(
        Package__c = pck.Id,
        Timetracker__c = c.Id
    );
    mocks.when(pckSelectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(pckSelectorMock.selectById(new Set<Id> {pck.Id})).thenReturn(new List<Package__c>{pck});
    mocks.when(cSelectorMock.sObjectType()).thenReturn(Contact.SObjectType);
    mocks.when(cSelectorMock.selectById(new Set<Id> {c.Id})).thenReturn(new List<Contact>{c});
    mocks.stopStubbing();
    Application.Selector.setMock(pckSelectorMock);
    Application.Selector.setMock(cSelectorMock);

    // When
    TimeDomain tDomain = new TimeDomain(new List<Time__c> {t});
    tDomain.setAbacusTimeType();

    // Then
    System.assertEquals(c.AbacusDefaultTimeType__c, t.AbacusTimeType__c);

  }

  @IsTest
  private static void testSetAbacusTimeTypeNoDefault() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector pckSelectorMock = new Mocks.PackageSelector(mocks);
    IContactSelector cSelectorMock = new Mocks.ContactSelector(mocks);

    // Given
    mocks.startStubbing();
    Contact c = new Contact(
        Id = fflib_IDGenerator.generate(Contact.SObjectType),
        AbacusDefaultTimeType__c = TimeDomain.ABACUSTIME_TYPE_DEFAULT
    );
    Package__c pck = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType),
        AbacusTimeType__c = 'NoDefault'
    );
    Time__c t = new Time__c(
        Package__c = pck.Id,
        Timetracker__c = c.Id
    );
    mocks.when(pckSelectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(pckSelectorMock.selectById(new Set<Id> {pck.Id})).thenReturn(new List<Package__c>{pck});
    mocks.when(cSelectorMock.sObjectType()).thenReturn(Contact.SObjectType);
    mocks.when(cSelectorMock.selectById(new Set<Id> {c.Id})).thenReturn(new List<Contact>{c});
    mocks.stopStubbing();
    Application.Selector.setMock(pckSelectorMock);
    Application.Selector.setMock(cSelectorMock);

    // When
    TimeDomain tDomain = new TimeDomain(new List<Time__c> {t});
    tDomain.setAbacusTimeType();

    // Then
    System.assertEquals(pck.AbacusTimeType__c, t.AbacusTimeType__c);

  }

  @IsTest
  private static void testSetRate() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IPackageSelector pckSelectorMock = new Mocks.PackageSelector(mocks);
    IProjectEmployeeRateSelector perSelectorMock = new Mocks.ProjectEmployeeRateSelector(mocks);

    // Given
    mocks.startStubbing();
    Package__c pck = new Package__c(
        Id = fflib_IDGenerator.generate(Package__c.SObjectType),
        ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType),
        PackageRateHour__c = 2,
        EmployeeSpecificRate__c = true
    );
    Time__c t = new Time__c(
        Package__c = pck.Id,
        Timetracker__c = fflib_IDGenerator.generate(Contact.SObjectType)
    );
    ProjectEmployeeRate__c per = new ProjectEmployeeRate__c(
        ProjectEmployee__c = t.Timetracker__c,
        Project__c = pck.ProjectName__c,
        ProjectEmployeeRateHour__c = 4
    );
    mocks.when(pckSelectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
    mocks.when(pckSelectorMock.selectById(new Set<Id> {pck.Id})).thenReturn(new List<Package__c>{pck});
    mocks.when(perSelectorMock.sObjectType()).thenReturn(ProjectEmployeeRate__c.SObjectType);
    mocks.when(perSelectorMock.selectByProjectId(new Set<Id> {pck.ProjectName__c})).thenReturn(new List<ProjectEmployeeRate__c>{per});
    mocks.stopStubbing();
    Application.Selector.setMock(pckSelectorMock);
    Application.Selector.setMock(perSelectorMock);

    // When
    TimeDomain tDomain = new TimeDomain(new List<Time__c> {t});
    tDomain.setRate();

    // Then
    ((IPackageSelector) mocks.verify(pckSelectorMock)).selectById(new Set<Id> {pck.Id});
    ((IProjectEmployeeRateSelector) mocks.verify(perSelectorMock)).selectByProjectId(new Set<Id> {pck.ProjectName__c});
    System.assertEquals(per.ProjectEmployeeRateHour__c, t.RateHour__c);
    System.assertEquals(TimeDomain.EMPLOYEE_RATE, t.RateOrigin__c);

  }

  @IsTest
  private static void testSetContactId() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IUserSelector selectorMock = new Mocks.UserSelector(mocks);

    // Given
    mocks.startStubbing();
    User u = new User(InternalContactID__c = fflib_IDGenerator.generate(Contact.SObjectType));
    Time__c t = new Time__c();
    mocks.when(selectorMock.sObjectType()).thenReturn(User.SObjectType);
    mocks.when(selectorMock.selectById(fflib_Match.anyId())).thenReturn(u);
    mocks.stopStubbing();
    Application.Selector.setMock(selectorMock);

    // When
    TimeDomain tDomain = new TimeDomain(new List<Time__c> {t});
    tDomain.setContactId();

    // Then
    ((IUserSelector) mocks.verify(selectorMock)).selectById(fflib_Match.anyId());
    System.assertEquals(u.InternalContactID__c, t.Timetracker__c);

  }

  @IsTest
  private static void testSaveRegisterNew() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    // Given
    Time__c t = new Time__c(
        TimetrackerStaffNr__c = '007'
    );

    Application.UnitOfWork.setMock(uowMock);

    // When
    ITimeDomain tDomain = TimeDomain.newInstance(new List<Time__c> {t});
    tDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerNew(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Time__c.TimetrackerStaffNr__c => t.TimetrackerStaffNr__c
            }
          )
      );

  }

  @IsTest
  private static void testSaveRegisterDirty() {

    // Create mocks
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

    // Given
    Time__c t = new Time__c(
        Id = fflib_IDGenerator.generate(Time__c.SObjectType),
        TimetrackerStaffNr__c = '007'
    );

    Application.UnitOfWork.setMock(uowMock);

    // When
    ITimeDomain tDomain = TimeDomain.newInstance(new List<Time__c> {t});
    tDomain.save(uowMock);

    // Then
    ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
      .registerDirty(
          fflib_Match.sObjectWith(
            new Map<SObjectField, Object>{
              Time__c.Id => t.Id,
              Time__c.TimetrackerStaffNr__c => t.TimetrackerStaffNr__c
            }
          )
      );

  }

}