public with sharing class SupplierCostsSelector extends fflib_SObjectSelector
  implements ISupplierCostsSelector {

  public static ISupplierCostsSelector newInstance() {
    return (ISupplierCostsSelector) Application.Selector.newInstance(SupplierCosts__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      SupplierCosts__c.Id
    };
  }

  public Schema.SObjectType getSObjectType() {
    return SupplierCosts__c.sObjectType;
  }

  public override String getOrderBy() {
    return 'SupplierCostsDate__c DESC, SupplierCostsInvoicedPM__c ASC';
  }

}