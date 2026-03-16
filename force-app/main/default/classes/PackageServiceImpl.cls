public with sharing class PackageServiceImpl
  implements IPackageService {

  public List<Package__c> get(Id projectId) {
    return PackageSelector.newInstance().selectByProjectId(new Set<Id>{projectId});
  }

  public PackageSelector.Model get(PackageSelector.Params parameters) {
    return PackageSelector.newInstance().selectFull(parameters);
  }

  public void save(List<Package__c> packages) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    IPackageDomain domain = PackageDomain.newInstance(packages);
    domain.save(uow);
    uow.commitWork();
  }

  public void del(List<Package__c> packages) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    IPackageDomain domain = PackageDomain.newInstance(packages);
    domain.del(uow);
    uow.commitWork();
  }
}