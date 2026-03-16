public with sharing class ParentObjectUpdateMDTSelector extends fflib_SObjectSelector
  implements IParentObjectUpdateMDTSelector {

  public static IParentObjectUpdateMDTSelector newInstance() {
    return (IParentObjectUpdateMDTSelector) Application.Selector.newInstance(ParentObjectUpdate__mdt.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      ParentObjectUpdate__mdt.Condition__c,
      ParentObjectUpdate__mdt.ConditionField__c,
      ParentObjectUpdate__mdt.DeveloperName,
      ParentObjectUpdate__mdt.Id,
      ParentObjectUpdate__mdt.Insert__c,
      ParentObjectUpdate__mdt.isActive__c,
      ParentObjectUpdate__mdt.Label,
      ParentObjectUpdate__mdt.Language,
      ParentObjectUpdate__mdt.MasterLabel,
      ParentObjectUpdate__mdt.NamespacePrefix,
      ParentObjectUpdate__mdt.QualifiedApiName,
      ParentObjectUpdate__mdt.RelationField__c,
      ParentObjectUpdate__mdt.Requirement__c,
      ParentObjectUpdate__mdt.SourceField__c,
      ParentObjectUpdate__mdt.SourceObject__c,
      ParentObjectUpdate__mdt.TargetField__c,
      ParentObjectUpdate__mdt.TargetObject__c,
      ParentObjectUpdate__mdt.Update__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ParentObjectUpdate__mdt.sObjectType;
  }

  public List<ParentObjectUpdate__mdt> selectBySourceObj(String typeName) {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('ConditionField__r.APIName__c');
    query.selectField('SourceField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.selectField('RelationField__r.APIName__c');
    query.setCondition('isActive__c = true AND SourceObject__r.APIName__c = :typeName');
    return (List<ParentObjectUpdate__mdt>) Database.query(query.toSOQL());
  }

  public List<ParentObjectUpdate__mdt> selectActives() {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('ConditionField__r.APIName__c');
    query.selectField('SourceField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.selectField('RelationField__r.APIName__c');
    query.setCondition('isActive__c = true');
    return (List<ParentObjectUpdate__mdt>) Database.query(query.toSOQL());
  }

  public List<ParentObjectUpdate__mdt> getParentObjectMDTTest() {
    fflib_QueryFactory query = newQueryFactory();

    query.selectField('TargetObject__r.APIName__c');
    query.selectField('SourceObject__r.APIName__c');
    query.selectField('ConditionField__r.APIName__c');
    query.selectField('SourceField__r.APIName__c');
    query.selectField('TargetField__r.APIName__c');
    query.selectField('RelationField__r.APIName__c');
    query.setCondition('SourceObject__r.APIName__c = \'Contact\' AND SourceField__r.APIName__c = \'Id\'');
    return (List<ParentObjectUpdate__mdt>) Database.query(query.toSOQL());
  }


}