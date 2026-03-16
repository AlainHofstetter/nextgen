public with sharing class ExpenseSelector extends fflib_SObjectSelector
  implements IExpenseSelector {

  public static IExpenseSelector newInstance() {
    return (IExpenseSelector) Application.Selector.newInstance(Expense__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Expense__c.Id,
      Expense__c.ExpenseDate__c,
      Expense__c.LocalCurrency__c,
      Expense__c.LocalCurrencyToCHF__c,
      Expense__c.CurrencyRateToCHF__c,
      Expense__c.Distance__c,
      Expense__c.DistanceCompensation__c,
      Expense__c.ExpenseGross__c,
      Expense__c.ExpenseGrossApproved__c,
      Expense__c.ExpenseValidatedFinance__c,
      Expense__c.CostsExpenseGross__c,
      Expense__c.CurrencyRateToProjectCurrency__c,
      Expense__c.ExpenseValidatedProjectResponsible__c,
      Expense__c.ServiceExpenseNet__c,
      Expense__c.CostsExpenseNet__c,
      Expense__c.VATPercent__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Expense__c.sObjectType;
  }

  public override String getOrderBy() {
    return 'ExpenseTracker__r.Name ASC, ExpenseDate__c DESC, RecordType.Name DESC, ExpenseValidatedProjectResponsible__c ASC';
  }

}