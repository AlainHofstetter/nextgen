public interface IInvoicePositionSelector extends fflib_ISObjectSelector {

  List<InvoicePos__c> selectWithRelated(Set<Id> ids, Set<String> related);

  List<InvoicePos__c> selectByInvoice(Set<Id> invoiceIds);

}