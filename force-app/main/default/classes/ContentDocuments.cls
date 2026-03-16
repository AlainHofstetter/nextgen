/**
 * Created by dudunato on 28.11.17.
 */

public without sharing class ContentDocuments extends fflib_SObjectDomain implements  IContentDocuments {

    public static IContentDocuments newInstance(List<ContentDocument> records) {
        return (IContentDocuments) Application.Domain.newInstance(records);
    }

    public ContentDocuments(List<ContentDocument> records) {
        super(records);
        Configuration.disableTriggerCRUDSecurity();
    }

    public override void onBeforeDelete() {
        checkDeletedInvoiceAttachments();
    }

    private void checkDeletedInvoiceAttachments() {
        Set<Id> docIds = new Map<Id, SObject>(records).keySet();
        Map<Id, ContentDocument> cntDocs = new Map<Id, ContentDocument>((List<ContentDocument>) records);

        List<ContentDocumentLink> docLinks = [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :docIds
        ];

        // Prevents the deletion of documents from an Invoice
        // -- However allow for certain profiles
        Boolean allowDeletion = bypassDocDeletionPrevention();
        
        for (ContentDocumentLink docLink : docLinks) {
            if (!allowDeletion && docLink.LinkedEntityId.getSobjectType() == Invoice__c.SObjectType) {
                cntDocs.get(doclink.ContentDocumentId).addError('Invoice\'s Attachments/Documents cannot be deleted.');
            }
        }

        ContentDocumentLinks.newInstance(docLinks).checkInvoiceAttachments(
                new Map<Id, SObject>(docLinks).keySet()
        );
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ContentDocuments(sObjectList);
        }
    }

    /**
     * Check if the current transaction is been performed by a user with
     * a profile for which the deletion of the document is allowed.
     */
    private static Boolean bypassDocDeletionPrevention() {
        Id profileId = userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;

        if (profileName == 'P120 - Standard - Finance' || profileName == 'System Administrator') {
            return true;
        }
        else {
            return false;
        }
    }

}