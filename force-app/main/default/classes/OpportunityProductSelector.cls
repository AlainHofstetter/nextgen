public with sharing class OpportunityProductSelector extends fflib_SObjectSelector
  implements IOpportunityProductSelector {

  public static IOpportunityProductSelector newInstance() {
    return (IOpportunityProductSelector) Application.Selector.newInstance(OpportunityLineItem.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> (
      getSObjectType().getDescribe().fields.getMap().values()
    );
  }

  public Schema.SObjectType getSObjectType() {
    return OpportunityLineItem.sObjectType;
  }

  public override String getOrderBy() {
    return 'SortNr__c ASC';
  }
}