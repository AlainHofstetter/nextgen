public with sharing class FinanceAccountSelector extends fflib_SObjectSelector
  implements IFinanceAccountSelector {

  public static IFinanceAccountSelector newInstance() {
    return (IFinanceAccountSelector) Application.Selector.newInstance(FinanceAccount__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      FinanceAccount__c.Id,
      FinanceAccount__c.FinanceAccountNr__c,
      FinanceAccount__c.FinanceClearingNr__c,
      FinanceAccount__c.CostCenter__c,
      FinanceAccount__c.TypeName__c,
      FinanceAccount__c.TypeName2__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return FinanceAccount__c.sObjectType;
  }

  public FinanceAccount__c selectByCostCenterAndType(Id costCenter, String type) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('CostCenter__c = :costCenter AND TypeName__c = :type');
    List<FinanceAccount__c> financeAccounts = (List<FinanceAccount__c>) Database.query(query.toSOQL());
    return (financeAccounts != null && !financeAccounts.isEmpty()) ? financeAccounts[0] : null;
  }

  public List<FinanceAccount__c> selectByCostCenterAndType(Set<Id> ccIds, Set<String> types) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('CostCenter__c IN :ccIds AND TypeName__c IN :types');
    return (List<FinanceAccount__c>) Database.query(query.toSOQL());
  }

  public List<FinanceAccount__c> selectByCostCenterAndType(Set<Id> ccIds, Set<String> types, Set<String> subTypes) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('CostCenter__c IN :ccIds AND TypeName__c IN :types AND TypeName2__c IN :subTypes');
    return (List<FinanceAccount__c>) Database.query(query.toSOQL());
  }

}