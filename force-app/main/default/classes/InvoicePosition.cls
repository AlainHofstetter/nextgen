public with sharing class InvoicePosition extends fflib_SObjectDomain
    implements IInvoicePosition {

    public static IInvoicePosition newInstance(List<InvoicePos__c> records) {
        return (IInvoicePosition) Application.Domain.newInstance(records);
    }

    public InvoicePosition(List<InvoicePos__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(null);
        setFinancialAccountInfo();
    }

    public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(oldRecords);
        setFinancialAccountInfo();
    }

    public override void onBeforeDelete() {
        List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
        IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
        fieldDomain.controlDeletion(records);
    }

    public override void onAfterInsert() {
        callParentUpdate(null);
    }

    public override void onAfterUpdate(Map<Id,SObject> oldRecords) {
        callParentUpdate(oldRecords);
    }

    public void save(fflib_ISObjectUnitOfWork uow, Invoice__c inv) {

        for (InvoicePos__c ip : (List<InvoicePos__c>) records) {
            if (ip.Id != null) {
                uow.registerDirty(ip);
            } else {
                uow.registerNew(ip, InvoicePos__c.InvoiceName__c, inv);
            }
        }

    }

    public void findSuperiors(fflib_ISObjectUnitOfWork uow, List<Package__c> packages) {

        Map<Id, Package__c> packMap = new Map<Id, Package__c>(packages);
        Map<Id, SObject> possMap = Utils.listToMap(InvoicePos__c.PackageName__c, records);

        for (InvoicePos__c ip : (List<InvoicePos__c>) records) {
            Package__c pck = (Package__c) packMap.get(ip.PackageName__c);

            System.debug('PCK::::: ' + pck);

            if (pck.PackageSuperior__c != null) {
                System.debug('IP::::: ' + ip);
                ip.InvoicePositionSuperior__c = possMap.get(pck.PackageSuperior__c).Id;
                uow.registerDirty(ip);
            }
        }

    }

    @TestVisible
    private void callUpdateExchangeRate(Map<Id,SObject> oldRecords){
        List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

        //if we have currency fields and currency conversion is endabled then update
        if(objs.size() > 0 && objs[0].Fields__r != null){
            IFieldMDT fieldDomain = FieldMDT.newInstance(objs[0].Fields__r);
            fieldDomain.updateExchangeRate(records, oldRecords);
        }
    }

    @TestVisible
    private void callParentUpdate(Map<Id,SObject> oldRecords) {
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

    @TestVisible
    private void setFinancialAccountInfo() {

        Set<String> related = new Set<String> {'ProjectName__r.ProjectCostCenter__c'};
        Set<Id> invIds = Utils.listToMap(InvoicePos__c.InvoiceName__c, records).keySet();

        Map<Id, Invoice__c> invoices = new Map<Id, Invoice__c>(
                InvoiceSelector.newInstance().selectWithRelated(invIds, related)
        );

        Set<Id> ccIds = new Set<Id>();
        Set<String> types = new Set<String>();
        Set<String> subTypes = new Set<String>();

        for (Invoice__c inv: invoices.values())
            ccIds.add(inv.ProjectName__r.ProjectCostCenter__c);

        for (InvoicePos__c ip: (List<InvoicePos__c>) records) {
            types.add(ip.PackageType__c);
            subTypes.add(ip.PackageSubType__c);
        }

        List<FinanceAccount__c> financeAccounts = FinanceAccountSelector.newInstance().selectByCostCenterAndType(ccIds, types, subTypes);

        for (InvoicePos__c iPos : (List<InvoicePos__c>) records) {
            Invoice__c inv = invoices.get(iPos.InvoiceName__c);

            for (FinanceAccount__c fa : financeAccounts) {

                if (fa.CostCenter__c == inv.ProjectName__r.ProjectCostCenter__c
                        && fa.TypeName__c == iPos.PackageType__c
                        && fa.TypeName2__c == iPos.PackageSubType__c) {

                    iPos.FinanceAccount__c = fa.Id;
                    iPos.FinanceAccountNr__c = fa.FinanceAccountNr__c;
                }

            }

        }

    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new InvoicePosition(sObjectList);
        }
    }
}