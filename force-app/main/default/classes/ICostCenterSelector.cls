public interface ICostCenterSelector extends fflib_ISObjectSelector {

  List<CostCenter__c> selectWithRelated(Set<Id> ids, Set<String> related);

}