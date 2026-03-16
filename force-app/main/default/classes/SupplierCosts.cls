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

    // public void save(fflib_ISObjectUnitOfWork uow) {

    //     for (SupplierCosts__c sc: (List<SupplierCosts__c>) records) {
    //         if (sc.Id == null)
    //             uow.registerNew(sc);
    //         else
    //             uow.registerDirty(sc);
    //     }

    // }

    public void save(fflib_ISObjectUnitOfWork uow) {

        List<SupplierCosts__c> input = (List<SupplierCosts__c>) records;

        System.debug('---SupplierCosts.save--- uow: '+uow);
        System.debug('---SupplierCosts.save--- records: '+records);
        System.debug('---SupplierCosts.save--- input: '+input);

        // Track first occurrence per Abacus key within this payload
        Map<String, SupplierCosts__c> firstByKey = new Map<String, SupplierCosts__c>();
        Set<String> keysToCheck = new Set<String>();

        for (SupplierCosts__c sc : input) {

            Boolean hasId = (sc.Id != null);
            Boolean hasKey = !String.isBlank(sc.AbacusDocumentNrPosNr__c);

            if (!hasId && hasKey) {
                String key = sc.AbacusDocumentNrPosNr__c.trim();

                if (!firstByKey.containsKey(key)) {
                    firstByKey.put(key, sc);
                    keysToCheck.add(key);
                }
            }
        }

        // Find keys that already exist in Salesforce
        Set<String> existingKeys = new Set<String>();
        if (!keysToCheck.isEmpty()) {
            for (SupplierCosts__c existing : [SELECT AbacusDocumentNrPosNr__c FROM SupplierCosts__c WHERE AbacusDocumentNrPosNr__c IN :keysToCheck]) {
                existingKeys.add(existing.AbacusDocumentNrPosNr__c);
            }
        }

        System.debug('---SupplierCosts.save--- existingKeys: '+existingKeys);

        // Register DML intentions
        for (SupplierCosts__c sc : input) {

            System.debug('---SupplierCosts.save--- sc: '+sc);

            Boolean hasId  = (sc.Id != null);
            Boolean hasKey = !String.isBlank(sc.AbacusDocumentNrPosNr__c);
            Boolean isFirstInPayload = false;
            Boolean existsInDb = false;

            System.debug('---SupplierCosts.save--- hasId: '+hasId + ' hasKey: '+hasKey);

            if (hasKey) {
                String key = sc.AbacusDocumentNrPosNr__c.trim();
                isFirstInPayload = (firstByKey.get(key) == sc);
                existsInDb = existingKeys.contains(key);
            }

            System.debug('---SupplierCosts.save--- existsInDb: '+existsInDb  + ' isFirstInPayload: '+isFirstInPayload);

            if (hasId) {
                System.debug('---SupplierCosts.save--- registerDirty - sc: '+sc);
                uow.registerDirty(sc);

            } else if (!hasKey) {
                System.debug('---SupplierCosts.save--- Non-Abacus registerNew - sc: '+sc);
                // Non-Abacus record
                uow.registerNew(sc);

            } else if (isFirstInPayload && !existsInDb) {
                System.debug('---SupplierCosts.save--- Abacus registerNew - sc: '+sc);
                // First occurrence + not already stored
                uow.registerNew(sc);

            }
            else { // duplicate in payload OR already in DB → intentionally ignored
                System.debug('---SupplierCosts.save--- isFirstInPayload: '+isFirstInPayload + ' existsInDb: '+existsInDb);
                System.debug('---SupplierCosts.save--- Duplicated: '+sc);
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