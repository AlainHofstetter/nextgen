public with sharing class InvoiceService {

  private static IInvoiceService service() {
    return (IInvoiceService) Application.Service.newInstance(IInvoiceService.class);
  }

  public static Invoice__c get(Id recordId) {
    return service().get(recordId);
  }

  public static ProjectStructureBean getProjectStructure(Id projectId, String dateFrom, String dateTo) {
    return service().getProjectStructure(projectId, dateFrom, dateTo);
  }

  public static void save(Invoice__c draft, List<Package__c> packages, List<InvoicePos__c> positions) {
    service().save(draft, packages, positions);
  }

  public static Invoice__c cancel(Id invoiceId) {
    return service().cancel(invoiceId);
  }

}