public interface ITimeSelector extends fflib_ISObjectSelector {

  List<Time__c> selectById(Set<Id> idSet);

}