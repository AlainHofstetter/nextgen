@IsTest
private class TestProject {

    @IsTest(SeeAllData=true)
    private static void testTrigger() {
        SObjectType t = Project__c.SObjectType;
        fflib_QueryFactory qf = new fflib_QueryFactory(t);
        qf.selectFields(t.getDescribe().fields.getMap().values());
        qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(1);
        List<Project__c> theList = (List<Project__c>) Database.query(qf.toSOQL());

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
        new Project(new List<Project__c>()).callInheritedFieldValue(true);

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
        new Project(new List<Project__c>()).callInheritedFieldValue(false);

        // Then
        ((IInheritedFieldValueMDT) mocks.verify(domainMock)).go(null, new List<SObject>());
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
        new Project(new List<Project__c>()).callUpdateExchangeRate(new Map<Id, SObject>());

        // Then
        ((IObjectMDTSelector) mocks.verify(selectorMock)).selectCurrencyFields(fflib_Match.anyString());
        ((IFieldMDT) mocks.verify(domainMock)).updateExchangeRate(new List<SObject>(), new Map<Id, SObject>());
    }

    @IsTest
    private static void testGetTemplateIds() {

        //Given
        Project__c p = new Project__c(
                ProjectTemplate__c = fflib_IDGenerator.generate(Project__c.SObjectType)
        );

        // When
        Set<Id> ids = new Project(new List<Project__c>()).getTemplateIds(new List<Project__c>{
                p
        });

        // Then
        System.assert(ids.contains(p.ProjectTemplate__c));

    }

    @IsTest
    private static void testMakeSubPackagesLookup() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        //Given
        String key = Utils.newGuid();
        Package__c parent = new Package__c(
                Id = fflib_IDGenerator.generate(Package__c.SObjectType)
        );
        Map<String, Package__c> parentPackages = new Map<String, Package__c>{
                key => parent
        };
        Package__c child = new Package__c();
        Map<String, List<Package__c>> childrenPackages = new Map<String, List<Package__c>>{
                key => new List<Package__c>{
                        child
                }
        };
        Application.UnitOfWork.setMock(uowMock);

        // When
        new Project(new List<Project__c>()).makeSubPackagesLookup(parentPackages, childrenPackages);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Package__c.PackageSuperior__c => parent.Id
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();

    }

    @IsTest
    private static void testRegisterSubPackages() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

        //Given
        mocks.startStubbing();
        Package__c parentOld = new Package__c(
                Id = fflib_IDGenerator.generate(Package__c.SObjectType),
                BudgetNotes__c = 'Test'
        );
        Package__c parent = new Package__c(
                ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType)
        );
        Map<String, Package__c> parentPackages = new Map<String, Package__c>();
        Map<String, List<Package__c>> childrenPackages = new Map<String, List<Package__c>>();
        mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
        mocks.when(selectorMock.selectBySuperiorExcludedFields(new Set<Id>{
                parentOld.Id
        }, new Set<String>())).thenReturn(new List<Package__c>{
                parentOld
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);

        // When
        new Project(new List<Project__c>()).registerSubPackages(uowMock, parentOld, parent, new Set<String>(), parentPackages, childrenPackages);

        // Then
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Package__c.ProjectName__c => parent.ProjectName__c,
                                Package__c.BudgetNotes__c => 'Test'
                        }
                )
        );
        ((IPackageSelector) mocks.verify(selectorMock)).selectBySuperiorExcludedFields(new Set<Id>{
                parentOld.Id
        }, new Set<String>());
        System.assert(!parentPackages.isEmpty());
        System.assert(!childrenPackages.isEmpty());

    }

    @IsTest
    private static void testCopyProjectTemplatePackages() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IFieldMDTSelector fSelectorMock = new Mocks.FieldMDTSelector(mocks);
        IPackageSelector pSelectorMock = new Mocks.PackageSelector(mocks);

        //Given
        mocks.startStubbing();
        Project__c proj = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                ProjectTemplate__c = fflib_IDGenerator.generate(Project__c.SObjectType)
        );
        Package__c pck = new Package__c(
                Id = fflib_IDGenerator.generate(Package__c.SObjectType),
                BudgetNotes__c = 'Test'
        );
        mocks.when(fSelectorMock.sObjectType()).thenReturn(Field__mdt.SObjectType);
        mocks.when(fSelectorMock.selectExcludedFromTemplate(fflib_Match.anyString())).thenReturn(new Set<String>());
        mocks.when(pSelectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
        mocks.when(pSelectorMock.selectByProjectExcludedFields(new Set<Id>{
                proj.ProjectTemplate__c
        }, new Set<String>())).thenReturn(new List<Package__c>{
                pck
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(pSelectorMock);
        Application.Selector.setMock(fSelectorMock);

        // When
        new Project(new List<Project__c>()).copyProjectTemplatePackages(new List<Project__c>{
                proj
        });

        // Then
        ((IFieldMDTSelector) mocks.verify(fSelectorMock)).selectExcludedFromTemplate(fflib_Match.anyString());
        ((IPackageSelector) mocks.verify(pSelectorMock)).selectByProjectExcludedFields(new Set<Id>{
                proj.ProjectTemplate__c
        }, new Set<String>());
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Package__c.ProjectName__c => proj.Id,
                                Package__c.BudgetNotes__c => 'Test'
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    private static void testCopyProjectTemplateFields() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IProjectSelector pSelectorMock = new Mocks.ProjectSelector(mocks);
        IFieldMDTSelector fSelectorMock = new Mocks.FieldMDTSelector(mocks);

        //Given
        mocks.startStubbing();
        Project__c template = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                ProjectRateHour__c = 0
        );
        Project__c proj = new Project__c(
                ProjectTemplate__c = template.Id
        );
        mocks.when(pSelectorMock.sObjectType()).thenReturn(Project__c.SObjectType);
        mocks.when(pSelectorMock.selectSObjectsById(new Set<Id>{
                proj.ProjectTemplate__c
        })).thenReturn(new List<Project__c>{
                template
        });
        mocks.when(fSelectorMock.sObjectType()).thenReturn(Field__mdt.SObjectType);
        mocks.when(fSelectorMock.selectExcludedFromTemplate(fflib_Match.anyString())).thenReturn(new Set<String>());
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(pSelectorMock);
        Application.Selector.setMock(fSelectorMock);

        // When
        new Project(new List<Project__c>()).copyProjectTemplateFields(new List<Project__c>{
                proj
        });

        // Then
        ((IProjectSelector) mocks.verify(pSelectorMock)).selectSObjectsById(new Set<Id>{
                proj.ProjectTemplate__c
        });
        ((IFieldMDTSelector) mocks.verify(fSelectorMock)).selectExcludedFromTemplate(fflib_Match.anyString());
        System.assertEquals(template.InvoiceContact__c, proj.InvoiceContact__c);
    }

    @IsTest
    private static void testGetRecordsWithChangedTemplates() {

        //Given
        Project__c old = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                ProjectTemplate__c = fflib_IDGenerator.generate(Project__c.SObjectType)
        );
        Project__c proj = new Project__c(
                Id = old.Id,
                ProjectTemplate__c = fflib_IDGenerator.generate(Project__c.SObjectType)
        );
        Map<Id, SObject> oldRecords = new Map<Id, SObject>{
                old.Id => old
        };

        // When
        List<SObject> theList = new Project(new List<Project__c>{
                proj
        }).getRecordsWithChangedTemplates(oldRecords);

        // Then
        System.assertEquals((Project__c) thelist[0], proj);
    }

    @IsTest
    private static void testUpdateAccountLookups() {

        //Given
        Project__c proj1 = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                InvoiceReceiver__c = fflib_IDGenerator.generate(Account.SObjectType),
                ContractPartner__c = fflib_IDGenerator.generate(Account.SObjectType)
        );
        Project__c proj2 = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                ProjectPartner__c = fflib_IDGenerator.generate(Account.SObjectType),
                ContractPartner__c = fflib_IDGenerator.generate(Account.SObjectType)
        );

        // When
        new Project(new List<Project__c>{
                proj1, proj2
        }).updateAccountLookups();

        // Then
        System.assertEquals(proj1.ProjectPartner__c, proj1.ContractPartner__c);
        System.assertEquals(proj2.InvoiceReceiver__c, proj2.ContractPartner__c);
    }

    @IsTest
    private static void testUpdatePackageRates() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IPackageSelector selectorMock = new Mocks.PackageSelector(mocks);

        //Given
        mocks.startStubbing();
        Project__c old = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                ProjectRateHour__c = 10
        );
        Project__c proj = new Project__c(
                Id = old.Id,
                ProjectRateHour__c = 20
        );
        Package__c pck = new Package__c(
                PackageSpecificRate__c = false,
                ProjectName__c = old.Id
        );
        Map<Id, SObject> oldRecords = new Map<Id, SObject>{
                old.Id => old
        };
        mocks.when(selectorMock.sObjectType()).thenReturn(Package__c.SObjectType);
        mocks.when(selectorMock.byProjectId(new Set<Id>{
                old.Id
        })).thenReturn(new List<Package__c>{
                pck
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);

        // When
        new Project(new List<Project__c>{
                proj
        }).updatePackageRates(oldRecords);

        // Then
        ((IPackageSelector) mocks.verify(selectorMock)).byProjectId(new Set<Id>{
                old.Id
        });
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Package__c.PackageRateHour__c => proj.ProjectRateHour__c
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

    @IsTest
    private static void testRetrieveQuoteProducts() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IQuoteLineItemsSelector selectorMock = new Mocks.QuoteLineItemsSelector(mocks);

        //Given
        mocks.startStubbing();
        Project__c proj = new Project__c(
                Id = fflib_IDGenerator.generate(Project__c.SObjectType),
                Quote__c = fflib_IDGenerator.generate(Quote.SObjectType),
                RetrieveQuoteProducts__c = true
        );
        QuoteLineItem superiorItem = new QuoteLineItem(
                Id = fflib_IDGenerator.generate(QuoteLineItem.SObjectType),
                Description = 'Test',
                ProductType__c = 'Group',
                SortNr__c = '100',
                QuoteId = proj.Quote__c
        );
        QuoteLineItem childItem = new QuoteLineItem(
                Id = fflib_IDGenerator.generate(QuoteLineItem.SObjectType),
                Description = 'Test',
                ProductType__c = 'Group',
                SortNr__c = '100',
                QuoteId = proj.Quote__c,
                SuperiorQuoteLineItem__c = superiorItem.Id
        );
        mocks.when(selectorMock.sObjectType()).thenReturn(QuoteLineItem.SObjectType);
        mocks.when(selectorMock.byQuoteId(new Set<Id>{
                proj.Quote__c
        })).thenReturn(new List<QuoteLineItem>{
                superiorItem,
                childItem
        });
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);

        // When
        new Project(new List<Project__c>{
                proj
        }).retrieveQuoteProducts(null);

        // Then
        ((IQuoteLineItemsSelector) mocks.verify(selectorMock)).byQuoteId(   new Set<Id>{
                proj.Quote__c
        });
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 2))
                .registerNew(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                Package__c.Name => superiorItem.Description,
                                Package__c.ProjectName__c => proj.Id
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock, 2)).commitWork();
    }


}