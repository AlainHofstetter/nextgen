public with sharing class Project extends fflib_SObjectDomain
        implements IProject {

    public static IProject newInstance(List<Project__c> records) {
        return (IProject) Application.Domain.newInstance(records);
    }

    public Project(List<Project__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        copyProjectTemplateFields(records);
        callInheritedFieldValue(false);
        callUpdateExchangeRate(null);
        updateAccountLookups();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        copyProjectTemplateFields(getRecordsWithChangedTemplates(oldRecords));
        callInheritedFieldValue(false);
        callUpdateExchangeRate(oldRecords);
        updateAccountLookups();
    }

    public override void onAfterInsert() {
        copyProjectTemplatePackages(records);
        retrieveQuoteProducts(null);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        copyProjectTemplatePackages(getRecordsWithChangedTemplates(oldRecords));
        updatePackageRates(oldRecords);
        retrieveQuoteProducts(oldRecords);
    }

    public override void onBeforeDelete() {
        List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
        IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
        fieldDomain.controlDeletion(records);
    }

    @TestVisible
    public void updatePackageRates(Map<Id, SObject> oldRecords) {

        Set<Id> projectIds = new Set<Id>();
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>();

        for (Project__c project : (List<Project__c>) records) {

            Project__c oldProject = (Project__c) oldRecords.get(project.Id);

            if (oldProject == null || (project.ProjectRateHour__c != oldProject.ProjectRateHour__c)) {
                projectIds.add(project.Id);
                projectMap.put(project.Id, project);
            }

        }

        List<Package__c> packages = PackageSelector.newInstance().byProjectId(projectIds);
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        for (Package__c packageToUpdate : packages) {

            if (!packageToUpdate.PackageSpecificRate__c) {

                Project__c project = projectMap.get(packageToUpdate.ProjectName__c);
                packageToUpdate.PackageRateHour__c = project.ProjectRateHour__c;

                if (!oldRecords.isEmpty()) uow.registerDirty(packageToUpdate);

            }

        }

        if (!oldRecords.isEmpty()) uow.commitWork();

    }

    @TestVisible
    private void updateAccountLookups() {
        for (Project__c p : (List<Project__c>) records) {
            if (p.InvoiceReceiver__c == null) {
                p.InvoiceReceiver__c = p.ContractPartner__c;
            }
            if (p.ProjectPartner__c == null) {
                p.ProjectPartner__c = p.ContractPartner__c;
            }
        }
    }

    @TestVisible
    private void callUpdateExchangeRate(Map<Id, SObject> oldRecords) {
        List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

        //if we have currency fields and currency conversion is endabled then update
        if (objs.size() > 0 && objs[0].Fields__r != null) {
            IFieldMDT fieldDomain = FieldMDT.newInstance(objs[0].Fields__r);
            fieldDomain.updateExchangeRate(records, oldRecords);
        }
    }

    @TestVisible
    private List<SObject> getRecordsWithChangedTemplates(Map<Id, SObject> oldRecords) {
        List<SObject> recordsToUpdate = new List<SObject>();
        for (Project__c p : (List<Project__c>) records) {
            Project__c o = (Project__c) oldRecords.get(p.Id);
            if (p.ProjectTemplate__c != null && p.ProjectTemplate__c != o.ProjectTemplate__c) {
                recordsToUpdate.add(p);
            }
        }
        return recordsToUpdate;
    }

    @TestVisible
    private void copyProjectTemplateFields(List<SObject> recordsToUpdate) {
        Set<Id> templateIds = getTemplateIds(recordsToUpdate);
        if (templateIds.isEmpty()) return;

        List<Project__c> templates = (List<Project__c>) ProjectSelector.newInstance().selectSObjectsById(templateIds);
        List<Schema.SObjectField> fields = new ProjectSelector().getSObjectFieldList();
        Set<String> excludedFields = FieldMDTSelector.newInstance().selectExcludedFromTemplate(this.getSObjectType().getDescribe().getName());

        for (Project__c p : (List<Project__c>) recordsToUpdate) {

            for (Project__c t : templates) {
                if (p.ProjectTemplate__c == t.Id) {

                    for (Schema.SObjectField f : fields) {
                        if (p.get(f) == null && !excludedFields.contains(f.getDescribe().getName()) && f.getDescribe().isUpdateable()) {
                            p.put(f, t.get(f));
                        }
                    }

                }
            }

        }

    }

    @TestVisible
    private void copyProjectTemplatePackages(List<SObject> recordsToUpdate) {
        Set<Id> templateIds = getTemplateIds(recordsToUpdate);
        if (templateIds.isEmpty()) return;

        Map<String, Package__c> parentPackages = new Map<String, Package__c>();
        Map<String, List<Package__c>> childrenPackages = new Map<String, List<Package__c>>();

        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Set<String> excludedFields = FieldMDTSelector.newInstance().selectExcludedFromTemplate('Package__c');
        List<Package__c> packages = PackageSelector.newInstance().selectByProjectExcludedFields(templateIds, excludedFields);

        System.debug('PACK--> ' + templateIds + 'HAHA' + excludedFields);

        for (Project__c p : (List<Project__c>) recordsToUpdate) {
            for (Package__c pck : packages) {
                if (pck.PackageSuperior__c == null) {
                    Package__c newPck = pck.clone(false, true);
                    newPck.ProjectName__c = p.Id;
                    uow.registerNew(newPck);

                    registerSubPackages(uow, pck, newPck, excludedFields, parentPackages, childrenPackages);
                }
            }
        }

        uow.commitWork();
        makeSubPackagesLookup(parentPackages, childrenPackages);
    }

    @TestVisible
    private void registerSubPackages(fflib_ISObjectUnitOfWork uow, Package__c pck, Package__c newPck,
            Set<String> excludedFields, Map<String, Package__c> parentPackages, Map<String, List<Package__c>> childrenPackages) {

        List<Package__c> subPackages = PackageSelector.newInstance().selectBySuperiorExcludedFields(new Set<Id>{
                pck.Id
        }, excludedFields);

        if (subPackages != null && !subPackages.isEmpty()) {
            List<Package__c> children = new List<Package__c>();

            String key = Utils.newGuid();
            parentPackages.put(key, newPck);

            for (Package__c sub : subPackages) {
                Package__c newSub = sub.clone(false, true);
                newSub.ProjectName__c = newPck.ProjectName__c;
                newSub.PackageSuperior__c = null;
                uow.registerNew(newSub);

                children.add(newSub);
            }

            childrenPackages.put(key, children);
        }

    }

    @TestVisible
    private void makeSubPackagesLookup(Map<String, Package__c> parentPackages, Map<String, List<Package__c>> childrenPackages) {
        if (!parentPackages.isEmpty()) {
            fflib_ISObjectUnitOfWork uowSubPck = Application.UnitOfWork.newInstance();

            for (String key : parentPackages.keySet()) {
                Package__c parent = parentPackages.get(key);

                for (Package__c sub : childrenPackages.get(key)) {
                    sub.PackageSuperior__c = parent.Id;
                    uowSubPck.registerDirty(sub);
                }
            }

            uowSubPck.commitWork();
        }
    }

    @TestVisible
    private Set<Id> getTemplateIds(List<SObject> recs) {
        Set<Id> templateIds = new Set<Id>();
        for (Project__c p : (List<Project__c>) recs) {
            if (p.ProjectTemplate__c != null)
                templateIds.add(p.ProjectTemplate__c);
        }

        return templateIds;
    }

    @TestVisible
    private void callInheritedFieldValue(Boolean isUpdate) {
        List<InheritedFieldValue__mdt> inheritedFValues = InheritedFieldValueMDTSelector.newInstance().selectByTargetObj(this.getSObjectType().getDescribe().getName());
        IInheritedFieldValueMDT inheritedFVDomain = InheritedFieldValueMDT.newInstance(inheritedFValues);

        if (isUpdate) {
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            inheritedFVDomain.go(uow, records);
            uow.commitWork();
        } else {
            inheritedFVDomain.go(null, records);
        }

    }

    @TestVisible
    private void retrieveQuoteProducts(Map<Id, SObject> oldRecords) {

        Map<Id, List<Project__c>> projectsByQuote = new Map<Id, List<Project__c>>();
        for (Project__c proj: (List<Project__c>) records) {
            Project__c oldProj = oldRecords == null
                ? new Project__c(RetrieveQuoteProducts__c = false)
                : (Project__c) oldRecords.get(proj.Id);

            if (!oldProj.RetrieveQuoteProducts__c && proj.RetrieveQuoteProducts__c) {
                List<Project__c> projects = projectsByQuote.get(proj.Quote__c);

                if (projects == null)
                    projectsByQuote.put(proj.Quote__c, new List<Project__c> {proj});
                else
                    projects.add(proj);
            }

        }

        if (projectsByQuote.isEmpty()) return;

        List<QuoteLineItem>  items = QuoteLineItemsSelector.newInstance().byQuoteId(
                projectsByQuote.keySet()
        );

        if (items == null) return;

        fflib_ISObjectUnitOfWork superiorsUOW = Application.UnitOfWork.newInstance();
        fflib_ISObjectUnitOfWork childrenUOW = Application.UnitOfWork.newInstance();
        Map<Id, QuoteLineItem> itemsMap = new Map<Id, QuoteLineItem>(items);
        Map<Id, List<SObject>> itemsBySuperior = Utils.listToMapLists('SuperiorQuoteLineItem__c', items);
        Map<Id, Package__c> packageSuperiorMap = new Map<Id, Package__c>();

        for (Id superiorId: itemsBySuperior.keySet()) {
            QuoteLineItem superiorItem = itemsMap.get(superiorId);
            Package__c superiorPackage = new Package__c(
                    Name = superiorItem.Description,
                    RecordTypeId = Utils.getRecordTypeIdByDevName('Package__c', superiorItem.ProductType__c),
                    PackageSubType__c = superiorItem.ProductSubType__c,
                    PackageSortNr__c = superiorItem.SortNr__c,
                    ProjectName__c = projectsByQuote.get(superiorItem.QuoteId)[0].Id,
                    ProjectManagementAllowancePackage__c = superiorItem.ProjectManagementAllowancePackage__c,
                    ExcludeFromProjectMgmtAllowance__c = superiorItem.ProjectManagementAllowancePackage__c,
                    ExpenseAllowancePackage__c = superiorItem.ExpenseAllowancePackage__c,
                    SupplierCostsGroup__c = superiorItem.SupplierCostsGroup__c
            );
            packageSuperiorMap.put(superiorId, superiorPackage);
            superiorsUOW.registerNew(superiorPackage);
        }
        superiorsUOW.commitWork();

        for (QuoteLineItem item: items) {
            if (item.ProductType__c == PackageDomain.TYPE_GROUP && item.SuperiorQuoteLineItem__c == null)
                continue;

            Id superiorPackageId = null;
            if (item.SuperiorQuoteLineItem__c != null) {
                superiorPackageId = packageSuperiorMap.get(item.SuperiorQuoteLineItem__c).Id;
            }

            Package__c childPackage = new Package__c(
                    Name = item.Description,
                    RecordTypeId = Utils.getRecordTypeIdByDevName('Package__c', item.ProductType__c),
                    PackageSubType__c = item.ProductSubType__c,
                    PackageSortNr__c = item.SortNr__c,
                    PackageSuperior__c = superiorPackageId,
                    ProjectName__c = projectsByQuote.get(item.QuoteId)[0].Id,
                    ProjectManagementAllowancePackage__c = item.ProjectManagementAllowancePackage__c,
                    ExcludeFromProjectMgmtAllowance__c = item.ProjectManagementAllowancePackage__c,
                    ExpenseAllowancePackage__c = item.ExpenseAllowancePackage__c,
                    SupplierCostsGroup__c = item.SupplierCostsGroup__c
            );

            childrenUOW.registerNew(childPackage);
        }
        childrenUOW.commitWork();

    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Project(sObjectList);
        }
    }

}