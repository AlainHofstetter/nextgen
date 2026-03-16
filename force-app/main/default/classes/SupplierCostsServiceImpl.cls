public with sharing class SupplierCostsServiceImpl
  implements ISupplierCostsService {

  public void save(List<SupplierCosts__c> scList) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    ISupplierCosts domain = SupplierCosts.newInstance(scList);
    domain.save(uow);
    uow.commitWork();
  }

}