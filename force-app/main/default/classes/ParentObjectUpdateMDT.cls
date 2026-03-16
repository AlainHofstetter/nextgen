public with sharing class ParentObjectUpdateMDT extends fflib_SObjectDomain
  implements IParentObjectUpdateMDT {

  public static final String HAS_CHANGED = 'Has changed';
  public static final String EQUALS_TRUE = 'Equals true';

  public static IParentObjectUpdateMDT newInstance(List<ParentObjectUpdate__mdt> records) {
    return (IParentObjectUpdateMDT) Application.Domain.newInstance(records);
  }

  public ParentObjectUpdateMDT(List<ParentObjectUpdate__mdt> records) {
    super(records);
  }

  public void go(fflib_ISObjectUnitOfWork uow, List<SObject> children, Map<Id, SObject> oldChildren) {


    if (oldChildren == null) oldChildren = new Map<Id, SObject>();

    for (ParentObjectUpdate__mdt pou: (List<ParentObjectUpdate__mdt>) records) {

      //check to see if the parent update rule is allowed for this trigger event
      if((pou.Insert__c  != true && Trigger.isInsert == true) ||(pou.Update__c != true && Trigger.isUpdate == true)){
        continue;
      }

      for (SObject obj: children) {
        if (pou.Condition__c == HAS_CHANGED) {
            SObject oldObj = oldChildren.get(obj.Id);

            if (oldObj == null || obj.get(pou.ConditionField__r.APIName__c) != oldObj.get(pou.ConditionField__r.APIName__c)) {
              this.executeAction(pou, obj, uow);
            }
        } else if (pou.Condition__c == EQUALS_TRUE) {
          if (obj.get(pou.ConditionField__r.APIName__c) == true) {
            this.executeAction(pou, obj, uow);
          }
        }
      }

    }

  }

  private void executeAction(ParentObjectUpdate__mdt pou, SObject child, fflib_ISObjectUnitOfWork uow) {
    String typeName = pou.TargetObject__r.APIName__c;
    SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
    Id targetObjId = (Id) child.get(pou.RelationField__r.APIName__c);
    SObject targetObject = targetType.newSObject(targetObjId);

    Object targetValue = child.get(pou.SourceField__r.APIName__c);

    if (targetObjId != null && targetValue != null) {
      targetObject.put(pou.TargetField__r.APIName__c, targetValue);
      uow.registerDirty(targetObject);
    }

  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new ParentObjectUpdateMDT(sObjectList);
    }
  }

}