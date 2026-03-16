public with sharing class ProjectSelector extends fflib_SObjectSelector
  implements IProjectSelector {

  public static IProjectSelector newInstance() {
    return (IProjectSelector) Application.Selector.newInstance(Project__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> (
      getSObjectType().getDescribe().fields.getMap().values()
    );
  }

  public Schema.SObjectType getSObjectType() {
    return Project__c.sObjectType;
  }

}