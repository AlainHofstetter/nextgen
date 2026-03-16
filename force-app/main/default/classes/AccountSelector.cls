public with sharing class AccountSelector extends fflib_SObjectSelector
  implements IAccountSelector {

  public static IAccountSelector newInstance() {
    return (IAccountSelector) Application.Selector.newInstance(Account.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Account.Id,
      Account.LegalCode__c,
      Account.LastInvoiceNr__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Account.sObjectType;
  }

}