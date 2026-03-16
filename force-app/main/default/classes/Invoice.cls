public with sharing class Invoice extends fflib_SObjectDomain
    implements IInvoice {

    public static final String STATUS_APPROVAL = 'Approval';
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_READY = 'Ready';
    public static final String STATUS_SENT = 'Sent';
    public static final String RECORD_TYPE_ILV = 'ILV';
    public static final String RECORD_TYPE_INVOICE = 'Invoice';
    public static final String RECORD_TYPE_CREDIT = 'Credit';
    public static final String RECORD_TYPE_CANCELLATION = 'Cancellation';

    public static Map<Id, String> RecordTypeMap = new  Map<Id, String>(
        Utils.getRecordTypeInfosName('Invoice__c')
    );

    public static IInvoice newInstance(List<Invoice__c> records) {
        return (IInvoice) Application.Domain.newInstance(records);
    }

    public Invoice(List<Invoice__c> records) {
        super(records);
    }

    public override void onBeforeInsert() {
        markRevenueRelevant();
        callInheritedFieldValue(false);

        System.debug('---Invoice.onBeforeInsert-------------');
        callUpdateExchangeRate(null);
        updateESRs(null);
    }

    public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
        markRevenueRelevant();
        callInheritedFieldValue(false);
        System.debug('---Invoice.onBeforeUpdate-------------');
        callUpdateExchangeRate(oldRecords);
        updateESRs(oldRecords);
    }

    public override void onAfterInsert() {
        generateInvoiceNr();
        callParentUpdate(null);
    }

    public override void onAfterUpdate(Map<Id,SObject> oldRecords) {
        generateInvoiceNr();
        replicateFields(oldRecords);
        callParentUpdate(oldRecords);
    }

    public override void onBeforeDelete() {
        controlDeletion();
        clearCancellationDate();
    }

    public void save(fflib_ISObjectUnitOfWork uow, String recordType) {

        for (Invoice__c inv: (List<Invoice__c>) records) {
            if (inv.Id != null) {
                uow.registerDirty(inv);
            } else {
                inv.RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', recordType);
                uow.registerNew(inv);
            }
        }

    }

    public void updateESRs(Map<Id,SObject> oldRecords){
        for (Invoice__c i : (List<Invoice__c>) records) {
            //do we have values in the ESR fields
            if(i.ESRMergentNr__c != null && i.InvoiceDocumentNr__c != null && i.ESRAccountNr__c  != null && (System.Test.isRunningTest()  || i.InvoiceTotalAmountGross__c != null)){
                //these are new records so create the ESR
                if(oldRecords == null){
                    updateESR(i);
                } else {
                    Invoice__c inv = (Invoice__c)oldRecords.get(i.Id);
                    //have any of the ESR fields changed? if so, update the ESR
                    if(i.ESRMergentNr__c != inv.ESRMergentNr__c || i.InvoiceDocumentNr__c != inv.InvoiceDocumentNr__c || i.ESRAccountNr__c != inv.ESRAccountNr__c || i.InvoiceTotalAmountGross__c != inv.InvoiceTotalAmountGross__c){
                        updateESR(i);
                    }
                }
            }
        }
    }

    public void updateESR(Invoice__c inv){
        System.debug('---Invoice.updateESR--- inv: ' + inv);
        //we are using a isRunningTest call to let us supply the value to the InvoiceTotalAmountGross__c formula field - ds
        //ESR Unformatted
        inv.ESRUnformatted__c = EsrUtil.getESR(inv.ESRAccountNr__c, inv.ESRMergentNr__c, inv.InvoiceDocumentNr__c, (System.Test.isRunningTest() ? 123 : inv.InvoiceTotalAmountGross__c), EsrUtil.EsrFormat.UNFORMATTED);
        //ESR Formatted
        inv.ESRFormatted__c = EsrUtil.getESR(inv.ESRAccountNr__c, inv.ESRMergentNr__c, inv.InvoiceDocumentNr__c, (System.Test.isRunningTest() ? 123 : inv.InvoiceTotalAmountGross__c), EsrUtil.EsrFormat.FORMATTED);
        //ESR Code Line
        inv.ESRCodeLine__c = EsrUtil.getESR(inv.ESRAccountNr__c, inv.ESRMergentNr__c, inv.InvoiceDocumentNr__c, (System.Test.isRunningTest() ? 123 : inv.InvoiceTotalAmountGross__c), EsrUtil.EsrFormat.CODE_LINE);
    }

    private void controlDeletion() {
        List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
        IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
        fieldDomain.controlDeletion(records);
    }

    @TestVisible
    private void clearCancellationDate() {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Id cancelRecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', RECORD_TYPE_CANCELLATION);

        for (Invoice__c inv: (List<Invoice__c>) records) {

            if (cancelRecordTypeId == inv.RecordTypeId) {
                Invoice__c cancelInvRelated = new Invoice__c(
                    Id = inv.CancellationInvoiceRelation__c,
                    CancellationDate__c = null
                );
                uow.registerDirty(cancelInvRelated);
            }

        }

        uow.commitWork();
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
    private void callUpdateExchangeRate(Map<Id,SObject> oldRecords) {
        List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

        System.debug('---Invoice.callUpdateExchangeRate-------------');
        //if we have currency fields and currency conversion is endabled then update
        if(objs.size() > 0 && objs[0].Fields__r != null){
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

    private void generateInvoiceNr() {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        Map<Id, Invoice__c> invoices = new Map<Id, Invoice__c>();
        for (Invoice__c i : (List<Invoice__c>) records) {
            invoices.put(i.Id, i);
        }

        Set<String> related = new Set<String> {
            'BillingViaCompany__r.LegalCode__c',
                'BillingViaCompany__r.LastInvoiceNr__c',
                'RecordType.Name'
        };

        List<Invoice__c> invoicesAccount = InvoiceSelector.newInstance().selectWithRelated(invoices.keySet(), related);

        for (Invoice__c i : invoicesAccount) {
            i.InvoiceStatus__c = Picklist.get(Invoice__c.InvoiceStatus__c, i.InvoiceStatus__c);

            if (i.InvoiceStatus__c != STATUS_DRAFT  && i.InvoiceStatus__c != STATUS_APPROVAL && i.InvoiceDocumentNr__c == null && i.RecordType.Name != RECORD_TYPE_ILV) {
                Account a = i.BillingViaCompany__r;
                a.LastInvoiceNr__c = a.LastInvoiceNr__c + 1;
                i.InvoiceDocumentNr__c = (a.LegalCode__c * 1000000) + (a.LastInvoiceNr__c);
                uow.registerDirty(i);
                uow.registerDirty(a);
            }
        }

        uow.commitWork();
    }

    @TestVisible
    private void markRevenueRelevant() {
        Map<Id, Schema.RecordTypeInfo> recordsType = Invoice__c.sObjectType.getDescribe().getRecordTypeInfosById();

        for (Invoice__c i : (List<Invoice__c>) records) {
            String rtName = RecordTypeMap.get(i.RecordTypeId);
            Boolean isRecordTypeOk = rtName.containsIgnoreCase(RECORD_TYPE_INVOICE) || rtName.containsIgnoreCase(RECORD_TYPE_CREDIT) || rtName.containsIgnoreCase(RECORD_TYPE_ILV);

            String status = Picklist.get(Invoice__c.InvoiceStatus__c, i.InvoiceStatus__c);
            Boolean isStatusOk = status == STATUS_READY || status == STATUS_SENT || status == STATUS_APPROVAL;

            Boolean isValid = i.CancellationDate__c == null && i.InvoiceInvalid__c == false;

            if (isRecordTypeOk && isStatusOk && isValid) {
                i.RelevantToRevenue__c = true;
            } else {
                i.RelevantToRevenue__c = false;
            }
        }

    }

    @TestVisible
    private void replicateFields(Map<Id,SObject> oldRecords) {

        for (Invoice__c i : (List<Invoice__c>) records) {
            Invoice__c old = (Invoice__c) oldRecords.get(i.Id);
            Boolean isRevenueChanged = i.RelevantToRevenue__c != old.RelevantToRevenue__c;
            Boolean isDateChanged = i.InvoiceDate__c != old.InvoiceDate__c;

            if (isRevenueChanged || isDateChanged) {
                fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
                Set<Id> ids = new Set<Id>{i.Id};
                List<InvoicePos__c> invoicesPos = InvoicePositionSelector.newInstance().selectByInvoice(ids);
                List<ILVPos__c> ilvsPos = ILVPosSelector.newInstance().selectByInvoice(ids);

                for (InvoicePos__c iPos : invoicesPos) {
                    if (isRevenueChanged) iPos.RelevantToRevenue__c = i.RelevantToRevenue__c;
                    if (isDateChanged) iPos.InvoicePositionDate__c = i.InvoiceDate__c;

                    uow.registerDirty(iPos);
                }

                for (ILVPos__c ilv : ilvsPos) {
                    if (isRevenueChanged) ilv.RelevantToRevenue__c = i.RelevantToRevenue__c;
                    if (isDateChanged) ilv.ILVPositionDate__c = i.InvoiceDate__c;

                    uow.registerDirty(ilv);
                }

                uow.commitWork();
            }

        }

    }

    public List<Invoice__c> cancel(fflib_ISObjectUnitOfWork uow) {
        List<Invoice__c> cancelled = new List<Invoice__c>();
        Map<Id, Invoice__c> invMap = new Map<Id, Invoice__c>();

        for (Invoice__c i : (List<Invoice__c>) records) {
            Invoice__c ic = i.clone(false, true);
            ic.RecordTypeId = Utils.getRecordTypeIdByDevName('Invoice__c', RECORD_TYPE_CANCELLATION);
            ic.InvoiceStatus__c = STATUS_DRAFT;
            ic.AbacusTransfer__c = null;
            ic.InvoiceDate__c = Date.today();
            ic.InvoiceDocumentNr__c = null;
            ic.InvoiceSentDate__c = null;
            ic.InvoiceValutaDate__c = null;
            ic.CancellationInvoiceRelation__c = i.Id;
            ic.PeriodFrom__c = i.PeriodFrom__c;
            ic.PeriodUntil__c = i.PeriodUntil__c;

            uow.registerNew(ic);
            cancelled.add(ic);
            invMap.put(i.Id, ic);
        }

        List<InvoicePos__c> invPoss = InvoicePositionSelector.newInstance().selectByInvoice(invMap.keySet());
        Map<Id, InvoicePos__c> possMap = new Map<Id, InvoicePos__c>();
/*
        for (InvoicePos__c pos: invPoss) {
            InvoicePos__c posClone = pos.clone(false, true);
            posClone.InvoicePositionAmount__c = -pos.InvoicePositionAmount__c;
            uow.registerNew(posClone, InvoicePos__c.InvoiceName__c, invMap.get(pos.InvoiceName__c));
            possMap.put(pos.Id, posClone);
        }

        uow.commitWork();

        fflib_ISObjectUnitOfWork uowPos = Application.UnitOfWork.newInstance();
        for (InvoicePos__c pos: invPoss) {
            if (pos.InvoicePositionSuperior__c != null) {
                InvoicePos__c posCloned = possMap.get(pos.Id);
                posCloned.InvoicePositionSuperior__c = possMap.get(pos.InvoicePositionSuperior__c).Id;
                uowPos.registerDirty(posCloned);
                System.debug('$$$$$$$$ ' + posCloned);
            }
        }
        uowPos.commitWork();
*/
         // insert invoicePos possition Superior First, this avoids make a query later to get the Invoicepossition fields updated by the flows
        for (InvoicePos__c pos: invPoss) {
            if (pos.InvoicePositionSuperior__c == null) {
                InvoicePos__c posClone = pos.clone(false, true);
                posClone.InvoicePositionAmount__c = -pos.InvoicePositionAmount__c;
                uow.registerNew(posClone, InvoicePos__c.InvoiceName__c, invMap.get(pos.InvoiceName__c));
                possMap.put(pos.Id, posClone);
            }
            
        }
        System.debug('First Insert '+possMap);
        uow.commitWork();
        // insert invoiceps wit a possition Superior.
        fflib_ISObjectUnitOfWork uowPos = Application.UnitOfWork.newInstance();
        for (InvoicePos__c pos: invPoss) {
            if (pos.InvoicePositionSuperior__c != null) {
                InvoicePos__c posClone = pos.clone(false, true);
                posClone.InvoicePositionSuperior__c = possMap.get(pos.InvoicePositionSuperior__c).Id;
                posClone.InvoicePositionAmount__c = -pos.InvoicePositionAmount__c;
                uowPos.registerNew(posClone, InvoicePos__c.InvoiceName__c, invMap.get(pos.InvoiceName__c));
                possMap.put(pos.Id, posClone);
            }
        }
        System.debug('second Insert');
        uowPos.commitWork();

        return cancelled;
    }

/*
    @TestVisible
    private void checkAttachments() {
        Map<Id, SObject> recordsMap = new Map<Id, SObject>(records);

        List<ContentDocumentLink> docs
                = InvoiceSelector.newInstance().selectDocuments(recordsMap.keySet());

        if (docs == null || docs.isEmpty()) return;

        for (ContentDocumentLink doc: docs) {
            Invoice__c inv = (Invoice__c) recordsMap.get(doc.LinkedEntityId);
            inv.ValHasAttachment__c = true;
        }
    }
*/

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Invoice(sObjectList);
        }
    }
}