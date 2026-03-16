public with sharing class SupplierCosts extends fflib_SObjectDomain
    implements ISupplierCosts {

    public static ISupplierCosts newInstance(List<SupplierCosts__c> records) {
        return (ISupplierCosts) Application.Domain.newInstance(records);
    }

    public SupplierCosts(List<SupplierCosts__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(null);
        setEmailAbacusVisa();
        setPurchasing();
    }

    public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
        callInheritedFieldValue(false);
        callUpdateExchangeRate(oldRecords);
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

    public void save(fflib_ISObjectUnitOfWork uow) {

        for (SupplierCosts__c sc: (List<SupplierCosts__c>) records) {
            if (sc.Id == null)
                uow.registerNew(sc);
            else
                uow.registerDirty(sc);
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
    private void setEmailAbacusVisa() {

        Map<String, List<SupplierCosts__c>> scVisaNrMap = new Map<String, List<SupplierCosts__c>>();

        for (SupplierCosts__c sc: (List<SupplierCosts__c>) records) {

            if (sc.VisaNr__c != null) {
                String cleanVisaNr = sc.VisaNr__c.stripTrailingZeros().toPlainString();

                List<SupplierCosts__c> listByVisaNr = scVisaNrMap.get(cleanVisaNr);

                if (listByVisaNr == null)
                    scVisaNrMap.put(cleanVisaNr, new List<SupplierCosts__c> {sc});
                else
                    listByVisaNr.add(sc);

            }

        }

        List<Contact> contacts = ContactSelector.newInstance().byAbacusVisaNr(scVisaNrMap.keySet());
        for (Contact con: contacts) {
            for (SupplierCosts__c sc: scVisaNrMap.get(con.AbacusVisaNr__c)) {
                sc.EmailAbacusVisa__c = con.Email;
            }
        }

    }

    @TestVisible
    private void setPurchasing() {
        Map<String, List<SupplierCosts__c>> scByBiller = new Map<String, List<SupplierCosts__c>>();

        for (SupplierCosts__c sc : (List<SupplierCosts__c>) records) {
            if (sc.BillerAccountProjectNr__c == null) continue;

            List<SupplierCosts__c> suppliersCosts = scByBiller.get(sc.BillerAccountProjectNr__c);

            if (suppliersCosts == null) {
                scByBiller.put(sc.BillerAccountProjectNr__c, new List<SupplierCosts__c> {sc});
            } else {
                suppliersCosts.add(sc);
            }
        }

        if (scByBiller.isEmpty()) return;

        List<Purchasing__c> purchasings = PurchasingSelector.newInstance().byBillerAccountProjectNr(
                scByBiller.keySet()
        );

        Set<String> purchasingsAdded = new Set<String>();
        for (Purchasing__c purchasing : purchasings) {
            if (purchasingsAdded.contains(purchasing.BillerAccountProjectNr__c)) continue;

            for (SupplierCosts__c sc: scByBiller.get(purchasing.BillerAccountProjectNr__c)) {
                sc.Purchasing__c = purchasing.Id;
                purchasingsAdded.add(purchasing.BillerAccountProjectNr__c);
            }
        }


    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new SupplierCosts(sObjectList);
        }
    }

}