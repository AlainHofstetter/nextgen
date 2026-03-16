public with sharing class PackageDomain extends fflib_SObjectDomain
        implements IPackageDomain {

    public static String TYPE_GROUP = 'Group';
    public static String TYPE_TIME = 'Time';
    public static String TYPE_EXPENSE = 'Expense';
    public static String TYPE_SUPPLIER_COSTS = 'SupplierCosts';
    public static String SUB_TYPE_WORK_TIME = 'Work Time';
    public static String SUB_TYPE_3RD_PARTY = '3rd Party Costs';

    public static Map<String, Id> RecordTypeMap = new Map<String, Id>{
            TYPE_GROUP => Utils.getRecordTypeIdByDevName('Package__c', TYPE_GROUP),
            TYPE_TIME => Utils.getRecordTypeIdByDevName('Package__c', TYPE_TIME),
            TYPE_EXPENSE => Utils.getRecordTypeIdByDevName('Package__c', TYPE_EXPENSE),
            TYPE_SUPPLIER_COSTS => Utils.getRecordTypeIdByDevName('Package__c', TYPE_SUPPLIER_COSTS)
    };

    public static IPackageDomain newInstance(List<Package__c> records) {
        return (IPackageDomain) Application.Domain.newInstance(records);
    }

    public PackageDomain(List<Package__c> records) {
        super(records);
    }


    public override void onBeforeInsert() {
        callUpdateExchangeRate(null);
        updatePackageRates(null);
        callInheritedFieldValue(false);
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        callUpdateExchangeRate(oldRecords);
        updatePackageRates(oldRecords);
        callInheritedFieldValue(false);
    }

    public override void onBeforeDelete() {
        List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
        IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
        fieldDomain.controlDeletion(records);
    }

    public override void onAfterInsert() {
        callParentUpdate(null);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        fflib_SObjectDomain.getTriggerEvent(PackageDomain.class).disableAfterUpdate();
        callParentUpdate(oldRecords);
    }

    public void save(fflib_ISObjectUnitOfWork uow) {

        for (Package__c p : (List<Package__c>) records) {
            setPicklistValues(p);

            if (p.Id != null) {
                uow.registerDirty(p);
            } else {
                uow.registerNew(p);
            }
        }

    }

    private void setPicklistValues(Package__c p) {
        if (p.PackageSubType__c != null)
            p.PackageSubType__c = Picklist.get(Package__c.PackageSubType__c, p.PackageSubType__c);

        if (p.PackageStatus__c != null)
            p.PackageStatus__c = Picklist.get(Package__c.PackageStatus__c, p.PackageStatus__c);
    }

    public void del(fflib_ISObjectUnitOfWork uow) {
        for (Package__c p : (List<Package__c>) records) {
            uow.registerDeleted(p);
        }
    }

    public void updatePackageRates(Map<Id, SObject> oldRecords) {

        if (oldRecords == null) {
            oldRecords = new Map<Id, SObject>();
        }

        // get project's Ids
        Set<Id> projectIds = new Set<Id>();

        // for every given project
        for (Package__c packageToFetchProjectFor : (List<Package__c>) records) {

            // get the old records
            Package__c oldPackage = (Package__c) oldRecords.get(packageToFetchProjectFor.Id);

            // only add project if the project rate field or project specific rate changed
            if (oldPackage == null || (packageToFetchProjectFor.PackageRateHour__c != oldPackage.PackageRateHour__c) || (packageToFetchProjectFor.PackageSpecificRate__c != oldPackage.PackageSpecificRate__c)) {
                projectIds.add(packageToFetchProjectFor.ProjectName__c);
            }

        }

        // fetch the projects
        List<Project__c> projects = (List<Project__c>) ProjectSelector.newInstance().selectSObjectsById(projectIds);

        // map projects so we can fetch rate later on
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
        for (Project__c project : projects) {
            projectMap.put(project.Id, project);
        }

        // fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        for (Package__c packageToUpdate : (List<Package__c>) records) {

            // if it doesnt have a specific rate
            if (!packageToUpdate.PackageSpecificRate__c) {

                Project__c project = projectMap.get(packageToUpdate.ProjectName__c);

                //validate for packages with rates != projet rate but without out PackageSpecificRate__c set to true
                if (project != null && packageToUpdate.PackageRateHour__c != null && packageToUpdate.PackageRateHour__c != project.ProjectRateHour__c) {
                    packageToUpdate.addError(Label.Skywalk_PackageSpecificRateToTrue);
                    continue;
                }


                // set the package rate to the project rate
                if (project != null) {
                    packageToUpdate.PackageRateHour__c = project.ProjectRateHour__c;
                }

                // update!
                // uow.registerDirty(packageToUpdate);

            }

        }

        // uow.commitWork();


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
    private void callParentUpdate(Map<Id, SObject> oldRecords) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<ParentObjectUpdate__mdt> pous = ParentObjectUpdateMDTSelector.newInstance().selectBySourceObj(this.getSObjectType().getDescribe().getName());
        IParentObjectUpdateMDT pouDomain = ParentObjectUpdateMDT.newInstance(pous);

        pouDomain.go(uow, records, oldRecords);
        uow.commitWork();
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

    public static String getSubType(String type) {
        String subType = 'None';

        if (type == PackageDomain.TYPE_TIME) {
            subType = PackageDomain.SUB_TYPE_WORK_TIME;
        } else if (type == 'SupplierCosts') {
            subType = PackageDomain.SUB_TYPE_3RD_PARTY;
        }

        return subType;
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new PackageDomain(sObjectList);
        }
    }
}