public with sharing class PermissionSetAssignmentSelector  extends fflib_SObjectSelector
  implements IPermissionSetAssignmentSelector {

  public static IPermissionSetAssignmentSelector newInstance() {
    return (IPermissionSetAssignmentSelector) Application.Selector.newInstance(PermissionSetAssignment.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
    	PermissionSetAssignment.AssigneeId,
    	PermissionSetAssignment.Id,
      PermissionSetAssignment.PermissionSetId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return PermissionSetAssignment.sObjectType;
  }

  public override  String getOrderBy() {
    return 'AssigneeId DESC';
  }

  public List<PermissionSetAssignment> selectByUserId(Set<Id> ids){
    fflib_QueryFactory query = newQueryFactory();
    query.selectField('PermissionSet.Name');
    query.setCondition('AssigneeId in :ids');
    return (List<PermissionSetAssignment>) Database.query(query.toSOQL());
  }
}