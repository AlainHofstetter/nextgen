public with sharing class SupplierCostsService {

  private static ISupplierCostsService service() {
    return (ISupplierCostsService) Application.Service.newInstance(ISupplierCostsService.class);
  }

  public static void save(List<SupplierCosts__c> scList) {
    service().save(scList);
  }

}