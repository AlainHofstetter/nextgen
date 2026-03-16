/**
 * Created by dudunato on 28.11.17.
 */

public without sharing class ContentDocumentLinks extends fflib_SObjectDomain
    implements  IContentDocumentLinks {

    public static IContentDocumentLinks newInstance(List<ContentDocumentLink> records) {
        return (IContentDocumentLinks) Application.Domain.newInstance(records);
    }

    public ContentDocumentLinks(List<ContentDocumentLink> records) {
        super(records);
        Configuration.disableTriggerCRUDSecurity();
    }

    public override void onAfterInsert() {
        checkInvoiceAttachments(null);
    }

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        checkInvoiceAttachments(null);
    }

    public override void onAfterDelete() {
        checkInvoiceAttachments(null);
    }

    public void checkInvoiceAttachments(Set<Id> deletedIds) {
        fflib_SObjectDomain.getTriggerEvent(Invoice.class).disableAll();

        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Map<Id, Invoice__c> invMap  = new Map<Id, Invoice__c>();

        if (deletedIds == null) deletedIds = new Set<Id>();

        for (ContentDocumentLink doc: (List<ContentDocumentLink>) records) {
            if (doc.LinkedEntityId.getSObjectType() == Invoice__c.SObjectType)
                invMap.put(doc.LinkedEntityId, new Invoice__c(Id = doc.LinkedEntityId));
        }

        System.debug('INVMAP--> ' + invMap);

        if (invMap.isEmpty()) return;

        List<ContentDocumentLink> docs
                = InvoiceSelector.newInstance().selectDocuments(invMap.keySet());

        System.debug('DOCS --> ' + docs);

        Map<Id, Set<Id>> docsMap = new Map<Id, Set<Id>>();

        for (ContentDocumentLink docLink: docs) {
            Set<Id> links = docsMap.get(docLink.LinkedEntityId);

            if (links == null) {
                docsMap.put(docLink.LinkedEntityId, new Set<Id>{docLink.Id});
            } else {
                links.add(docLink.Id);
            }
        }

        for (Invoice__c inv: invMap.values()) {
            if(docsMap.get(inv.Id) == null || deletedIds.containsAll(docsMap.get(inv.Id)))
                inv.ValHasAttachment__c = false;
            else
                inv.ValHasAttachment__c = true;

            uow.registerDirty(inv);
        }

        uow.commitWork();
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ContentDocumentLinks(sObjectList);
        }
    }
}