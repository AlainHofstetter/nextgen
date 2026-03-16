public interface IProjectEmployeeRateSelector  extends fflib_ISObjectSelector {
	List<ProjectEmployeeRate__c> selectByProjectId(Set<Id> ids);
}