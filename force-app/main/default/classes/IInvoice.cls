public interface IInvoice extends fflib_ISObjectDomain {

  void save(fflib_ISObjectUnitOfWork uow, String recordType);

  List<Invoice__c> cancel(fflib_ISObjectUnitOfWork uow);

  void updateESR(Invoice__c inv);

  void updateESRs(Map<Id,SObject> oldRecords);

}