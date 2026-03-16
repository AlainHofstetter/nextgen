public with sharing class OpportunitySelector extends fflib_SObjectSelector
  implements IOpportunitySelector {

  public static IOpportunitySelector newInstance() {
    return (IOpportunitySelector) Application.Selector.newInstance(Opportunity.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> (
      getSObjectType().getDescribe().fields.getMap().values()
    );
  }

  public Schema.SObjectType getSObjectType() {
    return Opportunity.sObjectType;
  }

  public List<Opportunity> selectWithProducts(Set<Id> ids) {
    fflib_QueryFactory query = newQueryFactory();
    fflib_QueryFactory productQuery = new OpportunityProductSelector().addQueryFactorySubselect(query);
    productQuery.setCondition('ProductType__c != \'Content\'');
    return (List<Opportunity>) Database.query(query.toSOQL());
  }
}