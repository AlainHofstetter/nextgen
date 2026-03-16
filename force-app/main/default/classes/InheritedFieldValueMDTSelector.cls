public with sharing class InheritedFieldValueMDTSelector extends fflib_SObjectSelector
  implements IInheritedFieldValueMDTSelector {

  public static IInheritedFieldValueMDTSelector newInstance() {
    return (IInheritedFieldValueMDTSelector) Application.Selector.newInstance(InheritedFieldValue__mdt.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      InheritedFieldValue__mdt.DeveloperName,
      InheritedFieldValue__mdt.Id,
      InheritedFieldValue__mdt.Insert__c,
      InheritedFieldValue__mdt.isActive__c,
      InheritedFieldValue__mdt.Label,
      InheritedFieldValue__mdt.Language,
      InheritedFieldValue__mdt.MasterLabel,
      InheritedFieldValue__mdt.NamespacePrefix,
      InheritedFieldValue__mdt.QualifiedApiName,
      InheritedFieldValue__mdt.RelationshipField__c,
      InheritedFieldValue__mdt.SourceObject__c,
      InheritedFieldValue__mdt.SourceQuery__c,
      InheritedFieldValue__mdt.TargetField__c,
      InheritedFieldValue__mdt.TargetObject__c,
      InheritedFieldValue__mdt.Update__c,
      InheritedFieldValue__mdt.UserValuesWinsOnInsert__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return InheritedFieldValue__mdt.sObjectType;
  }

  public List<InheritedFieldValue__mdt> selectByTargetObj(String typeName) {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('RelationshipField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.setCondition('isActive__c = true AND TargetObject__r.APIName__c = :typeName');
    return (List<InheritedFieldValue__mdt>) Database.query(query.toSOQL());
  }

  public List<InheritedFieldValue__mdt> selectActives() {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('RelationshipField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.setCondition('isActive__c = true');
    return (List<InheritedFieldValue__mdt>) Database.query(query.toSOQL());
  }

  public List<InheritedFieldValue__mdt> getInheritedFieldValueMDTTest() {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('RelationshipField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.setCondition('SourceObject__r.APIName__c = \'Project__c\' AND SourceQuery__c = \'InvoiceDescription__c\'');
    return (List<InheritedFieldValue__mdt>) Database.query(query.toSOQL());
  }

}