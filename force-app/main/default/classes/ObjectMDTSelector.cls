public with sharing class ObjectMDTSelector extends fflib_SObjectSelector
  implements IObjectMDTSelector {

  public static IObjectMDTSelector newInstance() {
    return (IObjectMDTSelector) Application.Selector.newInstance(Object__mdt.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Object__mdt.APIName__c,
      Object__mdt.CurrencyManagement__c,
      Object__mdt.CustomObject__c,
      Object__mdt.DeveloperName,
      Object__mdt.Id,
      Object__mdt.Label,
      Object__mdt.Language,
      Object__mdt.MasterLabel,
      Object__mdt.NamespacePrefix,
      Object__mdt.QualifiedApiName
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Object__mdt.sObjectType;
  }

  public List<Object__mdt> selectCurrencyFields(String typeName) {
    fflib_QueryFactory query = newQueryFactory();
    fflib_QueryFactory objectQuery = new FieldMDTSelector().addQueryFactorySubselect(query);
    objectQuery.setCondition('CurrencyManagementFieldType__c != NULL');    
    query.setCondition('ApiName__c = :typeName');
    return (List<Object__mdt>) Database.query(query.toSOQL());
  }

}