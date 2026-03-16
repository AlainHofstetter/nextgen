public with sharing class UserSelector  extends fflib_SObjectSelector
  implements IUserSelector {

  public static IUserSelector newInstance() {
    return (IUserSelector) Application.Selector.newInstance(User.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      User.BLCAbrechnungslisteFachberater__c,
      User.CanTrackExpensesForOthers__c,
      User.CanTrackTimeForOthers__c,
      User.CompensationTime__c,
      User.HourlyWage__c,
      User.ID_18_digits__c,
      User.InternalContactID__c,
      User.IsHRManager__c,
      User.IsProjectManager__c,
      User.Name,
      User.Username,
      User.PasswordSent__c,
      User.Phone_external__c,
      User.PiketSpecial__c,
      User.SFLicense__c,
      User.Staff_Number_Old__c,
      User.ProfileId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return User.sObjectType;
  }

  public List<User> selectAll(){
    fflib_QueryFactory query = newQueryFactory();
    return (List<User>) Database.query(query.toSOQL());
  }

  public User selectById(Id userId){
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Id = :userId');
    List<User> users = Database.query(query.toSOQL());
    return users.size() > 0 ? users[0] : null;
  }
}