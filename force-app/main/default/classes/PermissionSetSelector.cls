public with sharing class PermissionSetSelector   extends fflib_SObjectSelector
  implements IPermissionSetSelector {

  public static IPermissionSetSelector newInstance() {
    return (IPermissionSetSelector) Application.Selector.newInstance(PermissionSet.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
    	PermissionSet.Description,
    	PermissionSet.Id,
      	PermissionSet.Label,
      	PermissionSet.Name,
      	PermissionSet.NamespacePrefix
    };
  }

  public Schema.SObjectType getSObjectType() {
    return PermissionSet.sObjectType;
  }

  public List<PermissionSet> selectAll(){
    fflib_QueryFactory query = newQueryFactory();
    return (List<PermissionSet>) Database.query(query.toSOQL());
  }
}