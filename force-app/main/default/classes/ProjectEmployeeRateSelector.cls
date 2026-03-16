public with sharing class ProjectEmployeeRateSelector  extends fflib_SObjectSelector
  implements IProjectEmployeeRateSelector {

  public static IProjectEmployeeRateSelector newInstance() {
    return (IProjectEmployeeRateSelector) Application.Selector.newInstance(ProjectEmployeeRate__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
    	ProjectEmployeeRate__c.Id,
    	ProjectEmployeeRate__c.Project__c,
    	ProjectEmployeeRate__c.ProjectCurrency__c,
	    ProjectEmployeeRate__c.ProjectEmployee__c,
    	ProjectEmployeeRate__c.ProjectEmployeeRateHour__c,
      	ProjectEmployeeRate__c.ProjectEmployeeRole__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ProjectEmployeeRate__c.sObjectType;
  }

  public List<ProjectEmployeeRate__c> selectByProjectId(Set<Id> ids){
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Project__c in :ids');
    return (List<ProjectEmployeeRate__c>) Database.query(query.toSOQL());
  }
}