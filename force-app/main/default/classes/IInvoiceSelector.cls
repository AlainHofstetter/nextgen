public interface IInvoiceSelector extends fflib_ISObjectSelector {

  List<Invoice__c> selectWithRelated(Set<Id> ids, Set<String> related);

  Invoice__c draftByProject(Id projectId, String invoiceType);

  List<ContentDocumentLink> selectDocuments(Set<Id> ids);
}