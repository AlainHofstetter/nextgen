public with sharing class PackageService {

  private static IPackageService service() {
    return (IPackageService) Application.Service.newInstance(IPackageService.class);
  }

  public static List<Package__c> get(Id projectId) {
    return service().get(projectId);
  }

  public static PackageSelector.Model get(PackageSelector.Params parameters) {
    return service().get(parameters);
  }

  public static void save(List<Package__c> packages) {
    service().save(packages);
  }

  public static void del(List<Package__c> packages) {
    service().del(packages);
  }

}