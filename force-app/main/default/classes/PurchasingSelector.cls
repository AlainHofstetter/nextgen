public with sharing class PurchasingSelector extends fflib_SObjectSelector
  implements IPurchasingSelector {

  public static IPurchasingSelector newInstance() {
    return (IPurchasingSelector) Application.Selector.newInstance(Purchasing__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Purchasing__c.Id,
      Purchasing__c.BillerAccountProjectNr__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Purchasing__c.SObjectType;
  }

  public override String getOrderBy() {
    return 'CreatedDate DESC';
  }

  public List<Purchasing__c> byBillerAccountProjectNr(Set<String> billerAccountProjNr) {
      fflib_QueryFactory query = newQueryFactory();
      query.setCondition('BillerAccountProjectNr__c IN :billerAccountProjNr');
      return (List<Purchasing__c>) Database.query(query.toSOQL());
  }

}