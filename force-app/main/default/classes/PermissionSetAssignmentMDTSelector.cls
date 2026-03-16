public with sharing class PermissionSetAssignmentMDTSelector  extends fflib_SObjectSelector
  implements IPermissionSetAssignmentMDTSelector {

  public static IPermissionSetAssignmentMDTSelector newInstance() {
    return (IPermissionSetAssignmentMDTSelector) Application.Selector.newInstance(PermissionSetAssigment__mdt.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
    	PermissionSetAssigment__mdt.DeveloperName,
      	PermissionSetAssigment__mdt.Field__c,
      	PermissionSetAssigment__mdt.Id,
      	PermissionSetAssigment__mdt.isActive__c,
      	PermissionSetAssigment__mdt.MasterLabel,
      	PermissionSetAssigment__mdt.NamespacePrefix,
      	PermissionSetAssigment__mdt.PermissionSet__c
    };
  }

  public List<PermissionSetAssigment__mdt> selectBySourceObj(String typeName) {
    fflib_QueryFactory query = newQueryFactory();
    query.selectField('Field__r.APIName__c');
    query.setCondition('isActive__c = true AND Field__r.Object__r.APIName__c = :typeName');
    return (List<PermissionSetAssigment__mdt>) Database.query(query.toSOQL());
  }


  public Schema.SObjectType getSObjectType() {
    return PermissionSetAssigment__mdt.sObjectType;
  }
}