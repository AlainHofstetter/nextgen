public with sharing class PermissionSetAssignmentMDT   extends fflib_SObjectDomain
  implements IPermissionSetAssignmentMDT {
  
  public static IPermissionSetAssignmentMDT newInstance(List<PermissionSetAssigment__mdt> records) {
    return (IPermissionSetAssignmentMDT) Application.Domain.newInstance(records);
  }

  public PermissionSetAssignmentMDT(List<PermissionSetAssigment__mdt> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new PermissionSetAssignmentMDT(sObjectList);
		}
	}

  public void applyPermissionSets(fflib_ISObjectUnitOfWork uow, List<SObject> userRecords, List<PermissionSetAssignment> userPerms){
    //get a map of available permission sets to use when creating new assignments
    List<PermissionSet> permSets = PermissionSetSelector.newInstance().selectAll();
    Map<String, Id> permSetMap = new Map<String, Id>();
    for(PermissionSet s : permSets){
      permSetMap.put(s.Name, s.Id);
    }

    for(SObject obj : userRecords){
      //create a set of the user's permission sets
      Map<String, PermissionSetAssignment> userPermMap = new Map<String, PermissionSetAssignment>();
      for(PermissionSetAssignment p : userPerms){
        if(p.AssigneeId == (Id)obj.get('Id')){
          userPermMap.put(p.PermissionSet.Name, p);
        }
      }

      for(PermissionSetAssigment__mdt f: (List<PermissionSetAssigment__mdt>)records){
        if((Boolean)obj.get(f.Field__r.APIName__c) == true){
          //is there an existing permission set for this user?
          if(!userPermMap.containsKey(f.PermissionSet__c)){
            //if not create it
            PermissionSetAssignment assign = new PermissionSetAssignment();
            assign.AssigneeId = (Id)obj.get('Id');
            assign.PermissionSetId = (Id)permSetMap.get(f.PermissionSet__c);
            uow.registerNew(assign);
          }
         
        }

        if((Boolean)obj.get(f.Field__r.APIName__c) == false){
          //is there an existing permission set for this user?
          if(userPermMap.containsKey(f.PermissionSet__c)){
            //if so then remove it
            uow.registerDeleted(userPermMap.get(f.PermissionSet__c));
          }
        }
      }
    }
  }
}