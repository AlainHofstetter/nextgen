public with sharing class FieldMDTSelector extends fflib_SObjectSelector
  implements IFieldMDTSelector {

  public static IFieldMDTSelector newInstance() {
    return (IFieldMDTSelector) Application.Selector.newInstance(Field__mdt.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      Field__mdt.APIName__c,
      Field__mdt.ControlsDeletion__c,
      Field__mdt.CurrencyManagementFieldType__c,
	    Field__mdt.DeletionErrorMessage__c,
      Field__mdt.DeveloperName,
      Field__mdt.ExcludeFromTemplate__c,
      Field__mdt.Id,
      Field__mdt.MasterLabel,
      Field__mdt.NamespacePrefix,
      Field__mdt.Object__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Field__mdt.sObjectType;
  }

  public List<Field__mdt> selectDeletionControlFields(String typeName) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Object__r.ApiName__c = :typeName AND ControlsDeletion__c = true');
    return (List<Field__mdt>) Database.query(query.toSOQL());
  }

  public Set<String> selectExcludedFromTemplate(String typeName) {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Object__r.ApiName__c = :typeName AND ExcludeFromTemplate__c = true');

    List<Field__mdt> fields = (List<Field__mdt>) Database.query(query.toSOQL());
    Set<String> fieldsExcluded = new Set<String>();

    for(Field__mdt f: fields) {
      fieldsExcluded.add(f.APIName__c);
    }

    return fieldsExcluded;
  }

  public List<Field__mdt> getFieldMDTTest() {
    fflib_QueryFactory query = newQueryFactory();
    query.setCondition('Object__r.APIName__c = \'Expense__c\' AND CurrencyManagementFieldType__c != NULL');
    return (List<Field__mdt>) Database.query(query.toSOQL());
  }
}