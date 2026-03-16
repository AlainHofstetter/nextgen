public with sharing class PermissionSetAssignmentDomain extends fflib_SObjectDomain
  implements IPermissionSetAssignmentDomain {
  
  public static IPermissionSetAssignmentDomain newInstance(List<PermissionSetAssignment> records) {
    return (IPermissionSetAssignmentDomain) Application.Domain.newInstance(records);
  }

  public PermissionSetAssignmentDomain(List<PermissionSetAssignment> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new PermissionSetAssignmentDomain(sObjectList);
        }
    }
}