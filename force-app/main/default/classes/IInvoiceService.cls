public interface IInvoiceService {

  Invoice__c get(Id recordId);

  ProjectStructureBean getProjectStructure(Id projectId, String dateFrom, String dateTo);

  void save(Invoice__c draft, List<Package__c> packages, List<InvoicePos__c> positions);

  Invoice__c cancel(Id invoiceId);

}