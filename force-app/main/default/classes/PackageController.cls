public without sharing class PackageController {

  @AuraEnabled
  public static Boolean isUserAllowed() {
    User u = UserService.getLogged();
    return u == null ? false : u.IsProjectManager__c;
  }

  @AuraEnabled
  public static List<Package__c> get(Id projectId) {
    return PackageService.get(projectId);
  }

  @AuraEnabled
  public static void save(List<Package__c> packages) {
    PackageService.save(new List<Package__c> (packages));
  }

  @AuraEnabled
  public static void del(List<Package__c> packages) {
    PackageService.del(new List<Package__c> (packages));
  }

  @AuraEnabled
  public static Map<String, Map<String, List<String>>> getPicklists() {
    return Utils.getPicklistGroupedByRecordType('Package__c', new List<String> {'PackageSubType__c', 'PackageStatus__c'});
  }

}