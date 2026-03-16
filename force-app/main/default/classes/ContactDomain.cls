public with sharing class ContactDomain extends fflib_SObjectDomain
  implements IContactDomain {

  public static IContactDomain newInstance(List<Contact> records) {
    return (IContactDomain) Application.Domain.newInstance(records);
  }

  public ContactDomain(List<Contact> records) {
    super(records);
  }

  public override void onAfterInsert() {
    callParentUpdate(null);
  }

  public override void onAfterUpdate(Map<Id,SObject> oldRecords) {
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

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new ContactDomain(sObjectList);
    }
  }
}