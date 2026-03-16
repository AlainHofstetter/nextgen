@IsTest
private class TestInvoice {

    @IsTest(SeeAllData=true)
    private static void testTrigger() {
        SObjectType t = Invoice__c.SObjectType;
        fflib_QueryFactory qf = new fflib_QueryFactory(t);
        qf.selectFields(t.getDescribe().fields.getMap().values());
        qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(1);
        List<Invoice__c> theList = (List<Invoice__c>) Database.query(qf.toSOQL());

        if (!theList.isEmpty())
            update theList;
    }

    @IsTest
    private static void callingSaveShouldCallRegisterNew() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        //Given
        Invoice__c inv = new Invoice__c();
        Application.UnitOfWork.setMock(uowMock);

        // When
        IInvoice invDomain = Invoice.newInstance(new List<Invoice__c>{
                inv
        });
        invDomain.save(uowMock, Invoice.RECORD_TYPE_INVOICE);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.RecordTypeId => Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_INVOICE)
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
        Invoice__c inv = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)
        );
        Application.UnitOfWork.setMock(uowMock);

        // When
        IInvoice invDomain = Invoice.newInstance(new List<Invoice__c>{
                inv
        });
        invDomain.save(uowMock, Invoice.RECORD_TYPE_INVOICE);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.Id => inv.Id
                        }
                )
        );

    }


    @IsTest
    private static void updateESROnInsert() {

        //Given
        Invoice__c inv = new Invoice__c();
        inv.ESRMergentNr__c = '201111';
        inv.InvoiceDocumentNr__c = 78901;
        inv.ESRAccountNr__c = '01-8513-5';

        Map<Id, Invoice__c> oldRecords = new Map<Id, Invoice__c>();

        // When
        IInvoice invDomain = Invoice.newInstance(new List<Invoice__c>{
                inv
        });
        invDomain.updateESRs(null);

        System.assert(inv.ESRUnformatted__c.substring(0, 6) == '201111');
        System.assert(inv.ESRFormatted__c.substring(0, 4) == '20 1');
        System.assert(inv.ESRCodeLine__c.substring(0, 2) == '01');
        System.assert(inv.ESRUnformatted__c.length() == 27);
        System.assert(inv.ESRFormatted__c.length() == 32);
        System.assert(inv.ESRCodeLine__c.length() == 53);
    }

    @IsTest
    private static void updateESROnUpdate() {

        //Given
        Invoice__c inv = new Invoice__c();
        inv.Id = fflib_IDGenerator.generate(Invoice__c.SObjectType);
        inv.ESRMergentNr__c = '201111';
        inv.InvoiceDocumentNr__c = 78901;
        inv.ESRAccountNr__c = '01-8513-5';

        Invoice__c oldInv = new Invoice__c();
        oldInv.Id = inv.Id;
        oldInv.ESRMergentNr__c = '201111';
        oldInv.InvoiceDocumentNr__c = 78901;
        oldInv.ESRAccountNr__c = '01-8513-6';

        Map<Id, Invoice__c> oldRecords = new Map<Id, Invoice__c>();
        oldRecords.put(inv.Id, oldInv);

        // When
        IInvoice invDomain = Invoice.newInstance(new List<Invoice__c>{
                inv
        });
        invDomain.updateESRs(oldRecords);

        System.assert(inv.ESRUnformatted__c.substring(0, 6) == '201111');
        System.assert(inv.ESRFormatted__c.substring(0, 4) == '20 1');
        System.assert(inv.ESRCodeLine__c.substring(0, 2) == '01');
        System.assert(inv.ESRUnformatted__c.length() == 27);
        System.assert(inv.ESRFormatted__c.length() == 32);
        System.assert(inv.ESRCodeLine__c.length() == 53);
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
        new Invoice(new List<Invoice__c>()).callInheritedFieldValue(true);

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
        new Invoice(new List<Invoice__c>()).callInheritedFieldValue(false);

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
        new Invoice(new List<Invoice__c>()).callParentUpdate(new Map<Id, SObject>());

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
                        new List<Object__mdt>{
                                new Object__mdt()
                        },
                        Field__mdt.Object__c,
                        new List<List<Field__mdt>>{
                                new List<Field__mdt>{
                                        new Field__mdt()
                                }
                        }
                ))[0];
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Object__mdt.SObjectType);
        mocks.when(selectorMock.selectCurrencyFields(fflib_Match.anyString())).thenReturn(new List<Object__mdt>{
                obj
        });
        mocks.when(domainMock.sObjectType()).thenReturn(Field__mdt.SObjectType);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);
        Application.Domain.setMock(domainMock);

        // When
        new Invoice(new List<Invoice__c>()).callUpdateExchangeRate(new Map<Id, SObject>());

        // Then
        ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
        ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
    }

    @IsTest
    private static void testMarkRevenueRelevantTrue() {

        // Given
        Invoice__c inv = new Invoice__c(
                RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_INVOICE),
                InvoiceStatus__c = Invoice.STATUS_READY,
                InvoiceInvalid__c = false
        );

        // When
        new Invoice(new List<Invoice__c>{
                inv
        }).markRevenueRelevant();

        // Then
        System.assert(inv.RelevantToRevenue__c);

    }

    @IsTest
    private static void testMarkRevenueRelevantFalse() {

        // Given
        Invoice__c inv = new Invoice__c(
                RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_INVOICE),
                InvoiceStatus__c = Invoice.STATUS_READY,
                InvoiceInvalid__c = true
        );

        // When
        new Invoice(new List<Invoice__c>{
                inv
        }).markRevenueRelevant();

        // Then
        System.assert(!inv.RelevantToRevenue__c);

    }

    @IsTest
    private static void testCancel() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IInvoicePositionSelector ipSelectorMock = new Mocks.InvoicePositionSelector(mocks);

        // Given
        mocks.startStubbing();
        Invoice__c inv = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType),
                RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_INVOICE),
                InvoiceStatus__c = Invoice.STATUS_READY
        );
        InvoicePos__c pos = new InvoicePos__c(
                InvoiceName__c = inv.Id,
                PackageName__c = fflib_IDGenerator.generate(Package__c.SObjectType),
                InvoicePositionAmount__c = 10700
        );
        mocks.when(ipSelectorMock.sObjectType()).thenReturn(InvoicePos__c.SObjectType);
        mocks.when(ipSelectorMock.selectByInvoice(new Set<Id>{
                inv.Id
        })).thenReturn(new List<InvoicePos__c>{
                pos
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(ipSelectorMock);

        // When
        new Invoice(new List<Invoice__c>{
                inv
        }).cancel(uowMock);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.RecordTypeId => Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_CANCELLATION),
                                Invoice__c.InvoiceDate__c => Date.today(),
                                Invoice__c.InvoiceStatus__c => Invoice.STATUS_DRAFT,
                                Invoice__c.CancellationInvoiceRelation__c => inv.Id
                        }
                )
        );

        ((IInvoicePositionSelector) mocks.verify(ipSelectorMock)).selectByInvoice(new Set<Id>{
                inv.Id
        });

        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                InvoicePos__c.PackageName__c => pos.PackageName__c,
                                InvoicePos__c.InvoicePositionAmount__c => -10700
                        }
                ),
                fflib_Match.eqSObjectField(InvoicePos__c.InvoiceName__c),
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.CancellationInvoiceRelation__c => inv.Id
                        }
                )
        );
    }

    @IsTest
    private static void testReplicateFields() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IInvoicePositionSelector ipSelectorMock = new Mocks.InvoicePositionSelector(mocks);
        IILVPosSelector ilpSelectorMock = new Mocks.ILVPosSelector(mocks);

        // Given
        mocks.startStubbing();
        Date today = Date.today();
        Invoice__c invOld = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType),
                RelevantToRevenue__c = false,
                InvoiceDate__c = today
        );
        Invoice__c invNew = new Invoice__c(
                Id = invOld.Id,
                RelevantToRevenue__c = true,
                InvoiceDate__c = today.addDays(1)
        );
        InvoicePos__c iPos = new InvoicePos__c();
        ILVPos__c ilvPos = new ILVPos__c();
        Map<Id, SObject> oldRecords = new Map<Id, SObject>{
                invOld.Id => invOld
        };
        mocks.when(ipSelectorMock.sObjectType()).thenReturn(InvoicePos__c.SObjectType);
        mocks.when(ipSelectorMock.selectByInvoice(new Set<Id>{
                invNew.Id
        })).thenReturn(new List<InvoicePos__c>{
                iPos
        });
        mocks.when(ilpSelectorMock.sObjectType()).thenReturn(ILVPos__c.SObjectType);
        mocks.when(ilpSelectorMock.selectByInvoice(new Set<Id>{
                invNew.Id
        })).thenReturn(new List<ILVPos__c>{
                ilvPos
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(ipSelectorMock);
        Application.Selector.setMock(ilpSelectorMock);

        // When
        new Invoice(new List<Invoice__c>{
                invNew
        }).replicateFields(oldRecords);

        // Then
        ((IInvoicePositionSelector) mocks.verify(ipSelectorMock)).selectByInvoice(new Set<Id>{
                invNew.Id
        });
        ((IILVPosSelector) mocks.verify(ilpSelectorMock)).selectByInvoice(new Set<Id>{
                invNew.Id
        });

        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                InvoicePos__c.RelevantToRevenue__c => invNew.RelevantToRevenue__c,
                                InvoicePos__c.InvoicePositionDate__c => invNew.InvoiceDate__c
                        }
                )
        );

        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                ILVPos__c.RelevantToRevenue__c => invNew.RelevantToRevenue__c,
                                ILVPos__c.ILVPositionDate__c => invNew.InvoiceDate__c
                        }
                )
        );

        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    private static void testClearCancellationDate() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        // Given
        Invoice__c inv = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType),
                CancellationInvoiceRelation__c = fflib_IDGenerator.generate(Invoice__c.SObjectType),
                RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', Invoice.RECORD_TYPE_CANCELLATION)
        );
        Application.UnitOfWork.setMock(uowMock);

        // When
        new Invoice(new List<Invoice__c>{
                inv
        }).clearCancellationDate();

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Invoice__c.Id => inv.CancellationInvoiceRelation__c,
                                Invoice__c.CancellationDate__c => null
                        }
                )
        );
    }

/*
    @IsTest
    private static void testCheckAttachments() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IInvoiceSelector selectorMock = new Mocks.InvoiceSelector(mocks);

        // Given
        mocks.startStubbing();
        Invoice__c inv = new Invoice__c(
                Id = fflib_IDGenerator.generate(Invoice__c.SObjectType)
        );
        ContentDocumentLink doc = new ContentDocumentLink(LinkedEntityId = inv.Id);
        mocks.when(selectorMock.sObjectType()).thenReturn(Invoice__c.SObjectType);
        mocks.when(selectorMock.selectDocuments(new Set<Id>{
                inv.Id
        })).thenReturn(new List<ContentDocumentLink>{doc});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorMock);

        // When
        new Invoice(new List<Invoice__c> {inv}).checkAttachments();

        // Then
        System.assertEquals(true, inv.ValHasAttachment__c);
    }
*/


}