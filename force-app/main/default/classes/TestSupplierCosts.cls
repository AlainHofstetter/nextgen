@IsTest
private class TestSupplierCosts {

    @IsTest(SeeAllData=true)
    private static void testTrigger() {
        SObjectType t = SupplierCosts__c.SObjectType;
        fflib_QueryFactory qf = new fflib_QueryFactory(t);
        qf.selectFields(t.getDescribe().fields.getMap().values());
        qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(1);
        List<SupplierCosts__c> theList = (List<SupplierCosts__c>) Database.query(qf.toSOQL());

        if (!theList.isEmpty())
            update theList;
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
        new SupplierCosts(new List<SupplierCosts__c> ()).callInheritedFieldValue(true);

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
        new SupplierCosts(new List<SupplierCosts__c> ()).callInheritedFieldValue(false);

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
        new SupplierCosts(new List<SupplierCosts__c> ()).callParentUpdate(new Map<Id, SObject>());

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
        new SupplierCosts(new List<SupplierCosts__c> ()).callUpdateExchangeRate(new Map<Id, SObject>());

        // Then
        ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
        ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
    }

    @IsTest
    private static void callingSaveShouldRegisterNew() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        //Given
        SupplierCosts__c sc = new SupplierCosts__c(
                CostsSupplierCostsGrossCHF__c = 10
                );
        Application.UnitOfWork.setMock(uowMock);

        // When
        ISupplierCosts scDomain = SupplierCosts.newInstance(new List<SupplierCosts__c> {sc});
        scDomain.save(uowMock);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
            .registerNew(
                    fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                            SupplierCosts__c.CostsSupplierCostsGrossCHF__c => sc.CostsSupplierCostsGrossCHF__c
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
        SupplierCosts__c sc = new SupplierCosts__c(
                Id = fflib_IDGenerator.generate(SupplierCosts__c.SObjectType),
                CostsSupplierCostsGrossCHF__c = 10
                );
        Application.UnitOfWork.setMock(uowMock);

        // When
        ISupplierCosts scDomain = SupplierCosts.newInstance(new List<SupplierCosts__c> {sc});
        scDomain.save(uowMock);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
            .registerDirty(
                    fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                            SupplierCosts__c.Id => sc.Id,
                                SupplierCosts__c.CostsSupplierCostsGrossCHF__c => sc.CostsSupplierCostsGrossCHF__c
                        }
                     )
             );
    }

    @IsTest
    private static void testSetEmailAbacusVisa() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IContactSelector selectorMock = new Mocks.ContactSelector(mocks);

        //Given
        mocks.startStubbing();
        SupplierCosts__c sc = new SupplierCosts__c(
                VisaNr__c = 1000
        );
        String cleanVisaNr = sc.VisaNr__c.stripTrailingZeros().toPlainString();
        Contact con = new Contact(
                Email = 'test@test.com',
                AbacusVisaNr__c = '1000'
        );
        mocks.when(selectorMock.sObjectType()).thenReturn(Contact.SObjectType);
        mocks.when(selectorMock.byAbacusVisaNr(new Set<String>{cleanVisaNr})).thenReturn(new List<Contact>{con});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorMock);

        // When
        new SupplierCosts(new List<SupplierCosts__c> {sc}).setEmailAbacusVisa();

        // Then
        ((IContactSelector) mocks.verify(selectorMock)).byAbacusVisaNr(new Set<String>{cleanVisaNr});
        System.assertEquals(sc.EmailAbacusVisa__c, con.Email);
    }

    @IsTest
    private static void testSetPurchasing() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IPurchasingSelector selectorMock = new Mocks.PurchasingSelector(mocks);

        //Given
        mocks.startStubbing();
        JSONGenerator pJSON = JSON.createGenerator(true);
        pJSON.writeStartObject();
        pJSON.writeStringField('BillerAccountProjectNr__c', '0001A');
        pJSON.writeEndObject();
        SupplierCosts__c sc = (SupplierCosts__c) JSON.deserialize(pJSON.getAsString(), SupplierCosts__c.class);
        Purchasing__c purchasing = (Purchasing__c) JSON.deserialize(pJSON.getAsString(), Purchasing__c.class);
        purchasing.Id = fflib_IDGenerator.generate(Purchasing__c.SObjectType);

        mocks.when(selectorMock.sObjectType()).thenReturn(Purchasing__c.SObjectType);
        mocks.when(selectorMock.byBillerAccountProjectNr(new Set<String> {sc.BillerAccountProjectNr__c})).thenReturn(new List<Purchasing__c> {purchasing});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorMock);

        // When
        new SupplierCosts(new List<SupplierCosts__c> {sc}).setPurchasing();

        // Then
        ((IPurchasingSelector) mocks.verify(selectorMock)).byBillerAccountProjectNr(new Set<String> {sc.BillerAccountProjectNr__c});
        System.assertEquals(purchasing.Id, sc.Purchasing__c);
    }


}