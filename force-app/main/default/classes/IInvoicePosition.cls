public interface IInvoicePosition extends fflib_ISObjectDomain {

  void save(fflib_ISObjectUnitOfWork uow, Invoice__c inv);

  void findSuperiors(fflib_ISObjectUnitOfWork uow, List<Package__c> packages);

}