public with sharing class CostCenterSelector extends fflib_SObjectSelector
  implements ICostCenterSelector {

  public static ICostCenterSelector newInstance() {
    return (ICostCenterSelector) Application.Selector.newInstance(CostCenter__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      CostCenter__c.Id,
      CostCenter__c.CostCenterNr__c,
      CostCenter__c.ClearingCostCenterNr__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return CostCenter__c.sObjectType;
  }

  public List<CostCenter__c> selectWithRelated(Set<Id> ids, Set<String> related) {
    fflib_QueryFactory query = newQueryFactory();
    query.selectFields(related);

    query.setCondition('id in :ids').toSOQL();
    return (List<CostCenter__c>) Database.query(query.toSOQL());
  }

}