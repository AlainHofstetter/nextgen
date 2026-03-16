public with sharing class UserDomain extends fflib_SObjectDomain
  implements IUserDomain {

  public static IUserDomain newInstance(List<User> records) {
    return (IUserDomain) Application.Domain.newInstance(records);
  }

  public UserDomain(List<User> records) {
    super(records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new UserDomain(sObjectList);
    }
  }

  public override void onAfterInsert() {
    updatePermissionSets();
  }


  public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
    updatePermissionSets();
  }

  @TestVisible
  private void updatePermissionSets() {
    //get list of user permission sets
    Set<Id> userIds = new Map<Id,SObject>(records).keySet();
    List<PermissionSetAssignment> userPerms = PermissionSetAssignmentSelector.newInstance().selectByUserId(userIds);

    List<PermissionSetAssigment__mdt> perms = PermissionSetAssignmentMDTSelector.newInstance().selectBySourceObj(this.getSObjectType().getDescribe().getName());
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    IPermissionSetAssignmentMDT permDomain = PermissionSetAssignmentMDT.newInstance(perms);
    permDomain.applyPermissionSets(uow, records, userPerms);
    uow.commitWork();
  }
}