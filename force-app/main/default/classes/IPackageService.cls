public interface IPackageService {

  List<Package__c> get(Id projectId);

  PackageSelector.Model get(PackageSelector.Params parameters);

  void save(List<Package__c> packages);

  void del(List<Package__c> packages);

}