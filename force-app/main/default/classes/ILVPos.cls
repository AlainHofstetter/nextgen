public with sharing class ILVPos extends fflib_SObjectDomain
        implements IILVPos {

    public static IILVPos newInstance(List<ILVPos__c> records) {
        return (IILVPos) Application.Domain.newInstance(records);
    }

    public ILVPos(List<ILVPos__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(null);
        setFinancialAccountInfo();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(oldRecords);
        setFinancialAccountInfo();
    }

    public override void onAfterInsert() {
        callParentUpdate(null);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        callParentUpdate(oldRecords);
    }

    public override void onBeforeDelete() {
        List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
        IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
        fieldDomain.controlDeletion(records);
    }

    public void save(fflib_ISObjectUnitOfWork uow, Invoice__c inv) {

        for (ILVPos__c ip : (List<ILVPos__c>) records) {
            if (ip.Id != null) {
                uow.registerDirty(ip);
            } else {
                uow.registerNew(ip, ILVPos__c.InvoiceName__c, inv);
            }
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
    private void callUpdateExchangeRate(Map<Id, SObject> oldRecords) {
        List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

        //if we have currency fields and currency conversion is endabled then update
        if (objs.size() > 0 && objs[0].Fields__r != null) {
            IFieldMDT fieldDomain = FieldMDT.newInstance(objs[0].Fields__r);
            fieldDomain.updateExchangeRate(records, oldRecords);
        }
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

    private void setFinancialAccountInfo() {

        Set<String> invoiceRelated = new Set<String>{
                'ProjectName__r.ProjectCostCenter__c'
        };
        Set<String> centerRelated = new Set<String>{
                'LegalAccount__r.LegalCode__c'
        };

        Set<Id> invIds = Utils.listToMap(ILVPos__c.InvoiceName__c, records).keySet();
        Set<Id> centerIds = Utils.listToMap(ILVPos__c.CostCenterILVReceiver__c, records).keySet();

        Map<Id, Invoice__c> invoices = new Map<Id, Invoice__c>(
                InvoiceSelector.newInstance().selectWithRelated(invIds, invoiceRelated)
        );

        Map<Id, CostCenter__c> centers = new Map<Id, CostCenter__c>(
                CostCenterSelector.newInstance().selectWithRelated(centerIds, centerRelated)
        );

        Set<Id> ccIds = new Set<Id>();
        Set<String> types = new Set<String>();
        Set<String> subTypes = new Set<String>();

        for (Invoice__c inv : invoices.values())
            ccIds.add(inv.ProjectName__r.ProjectCostCenter__c);

        for (ILVPos__c ilv : (List<ILVPos__c>) records) {
            types.add(ilv.ILVType__c);
            subTypes.add(ilv.PackageSubType__c);
            ccIds.add(ilv.CostCenterILVReceiver__c);
        }

        List<FinanceAccount__c> financeAccounts = FinanceAccountSelector.newInstance().selectByCostCenterAndType(ccIds, types, subTypes);

        for (ILVPos__c ilv : (List<ILVPos__c>) records) {
            Invoice__c inv = invoices.get(ilv.InvoiceName__c);
            CostCenter__c centerReceiver = centers.get(ilv.CostCenterILVReceiver__c);

            if (inv == null || centerReceiver == null) continue;

            for (FinanceAccount__c fa : financeAccounts) {
                if (fa.CostCenter__c == inv.ProjectName__r.ProjectCostCenter__c
                        && fa.TypeName__c == ilv.ILVType__c
                        && fa.TypeName2__c == ilv.PackageSubType__c) {

                    ilv.FinanceAccountILVGiver__c = fa.Id;
                    ilv.FinanceAccountNrILVGiver__c = fa.FinanceAccountNr__c;
                }

                if (fa.CostCenter__c == ilv.CostCenterILVReceiver__c
                        && fa.TypeName__c == ilv.ILVType__c
                        && fa.TypeName2__c == ilv.PackageSubType__c) {

                    ilv.FinanceAccountILVReceiver__c = fa.Id;

                    if (centerReceiver.LegalAccount__r.LegalCode__c == inv.BillingViaLegalCode__c) {
                        ilv.FinanceAccountNrILVReceiver__c = fa.FinanceAccountNr__c;
                        ilv.CostCenterNrILVReceiver__c = centerReceiver.CostCenterNr__c;
                    } else {
                        ilv.FinanceAccountNrILVReceiver__c = fa.FinanceClearingNr__c;
                        ilv.CostCenterNrILVReceiver__c = centerReceiver.ClearingCostCenterNr__c;
                    }
                }

            }

        }

    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ILVPos(sObjectList);
        }
    }
}