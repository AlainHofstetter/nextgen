public interface IPackageSelector extends fflib_ISObjectSelector {

  List<Package__c> selectAll();

  List<Package__c> selectById(Set<Id> ids);

  List<Package__c> selectByProjectId(Set<Id> ids);

  List<Package__c> byProjectId(Set<Id> ids);

  List<Package__c> selectBySuperiorExcludedFields(Set<Id> ids, Set<String> excludedFields);

  List<Package__c> selectByProjectExcludedFields(Set<Id> ids, Set<String> excludedFields);

  PackageSelector.Model selectFull(PackageSelector.Params parameters);

  ProjectStructureBean selectProjectStructure(Id projectId, String dateFrom, String dateTo);

  ILVCreation selectILVInfo(Id projectId, String dateFrom, String dateTo);

}