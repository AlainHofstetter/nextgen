public class TimeSelector extends fflib_SObjectSelector
  implements ITimeSelector {

  public static ITimeSelector newInstance() {
    return (ITimeSelector) Application.Selector.newInstance(Time__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Time__c.Id,
      Time__c.Package__c,
      Time__c.AbacusTimeType__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Time__c.sObjectType;
  }

  public override String getOrderBy() {
    return 'Timetracker__r.Name ASC, DateFrom__c DESC, ServiceType__c DESC, OutOfScope__c ASC, TimeValidatedProjectResponsible__c ASC';
  }

  public List<Time__c> selectById(Set<Id> idSet) {
    fflib_QueryFactory query = newQueryFactory();
    query.selectFields(new Set<String>{'Timetracker__r.AbacusDefaultTimeType__c', 'Package__r.AbacusTimeType__c'});
    query.setCondition('id in :idSet').toSOQL();

    return (List<Time__c>) Database.query(query.toSOQL());
  }

}