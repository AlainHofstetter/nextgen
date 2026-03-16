public with sharing class AccountDomain extends fflib_SObjectDomain
  implements IAccountDomain {

  public static IAccountDomain newInstance(List<Account> records) {
    return (IAccountDomain) Application.Domain.newInstance(records);
  }

  public AccountDomain(List<Account> records) {
    super(records);
  }

  public override void onBeforeInsert() {
    callInheritedFieldValue(false);
    callUpdateExchangeRate(null);
  }

  public override void onBeforeUpdate(Map<Id,SObject> oldRecords) {
    callInheritedFieldValue(false);
    callUpdateExchangeRate(oldRecords);
  }

  public override void onAfterInsert() {
    callParentUpdate(null);
  }

  public override void onAfterUpdate(Map<Id,SObject> oldRecords) {
    fflib_SObjectDomain.getTriggerEvent(AccountDomain.class).disableAfterUpdate();
    callParentUpdate(oldRecords);
  }

  public override void onBeforeDelete() {
    List<Field__mdt> fields = FieldMDTSelector.newInstance().selectDeletionControlFields(this.getSObjectType().getDescribe().getName());
    IFieldMDT fieldDomain = FieldMDT.newInstance(fields);
    fieldDomain.controlDeletion(records);
  }

  @TestVisible
  private void callParentUpdate(Map<Id,SObject> oldRecords) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    List<ParentObjectUpdate__mdt> pous = ParentObjectUpdateMDTSelector.newInstance().selectBySourceObj(this.getSObjectType().getDescribe().getName());
    IParentObjectUpdateMDT pouDomain = ParentObjectUpdateMDT.newInstance(pous);

    pouDomain.go(uow, records, oldRecords);
    uow.commitWork();
  }

  @TestVisible
  private void callUpdateExchangeRate(Map<Id,SObject> oldRecords){
    List<Object__mdt> objs = ObjectMDTSelector.newInstance().selectCurrencyFields(this.getSObjectType().getDescribe().getName());

    if(objs.size() > 0 && objs[0].Fields__r != null){
      IFieldMDT fieldDomain = FieldMDT.newInstance(objs[0].Fields__r);
      fieldDomain.updateExchangeRate(records, oldRecords);
    }
  }

  @TestVisible
  private void callInheritedFieldValue(Boolean isUpdate) {
    List<InheritedFieldValue__mdt> inheritedFValues = InheritedFieldValueMDTSelector.newInstance().selectByTargetObj(this.getSObjectType().getDescribe().getName());
    IInheritedFieldValueMDT inheritedFVDomain = InheritedFieldValueMDT.newInstance(inheritedFValues);

    if (isUpdate) {
      fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
      inheritedFVDomain.go(uow, records);
      uow.commitWork();
    } else {
      inheritedFVDomain.go(null, records);
    }

  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new AccountDomain(sObjectList);
    }
  }
}