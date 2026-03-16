public with sharing class ILVPosSelector extends fflib_SObjectSelector
  implements IILVPosSelector {

  public static IILVPosSelector newInstance() {
    return (IILVPosSelector) Application.Selector.newInstance(ILVPos__c.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField> {
      ILVPos__c.Id,
      ILVPos__c.RelevantToRevenue__c,
      ILVPos__c.ILVPositionDate__c,
      ILVPos__c.ILVType__c,
      ILVPos__c.FinanceAccountILVGiver__c,
      ILVPos__c.FinanceAccountNrILVGiver__c,
      ILVPos__c.CostCenterILVReceiver__c,
      ILVPos__c.FinanceAccountILVReceiver__c,
      ILVPos__c.FinanceAccountNrILVReceiver__c,
      ILVPos__c.CostCenterNrILVReceiver__c,
      ILVPos__c.PackageName__c,
      ILVPos__c.InvoiceName__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ILVPos__c.sObjectType;
  }

  public List<ILVPos__c> selectWithRelated(Set<Id> ids, Set<String> related) {
    fflib_QueryFactory query = newQueryFactory();
    query.selectFields(related);

    query.setCondition('id in :ids').toSOQL();
    return (List<ILVPos__c>) Database.query(query.toSOQL());
  }

  public List<ILVPos__c> selectByInvoice(Set<Id> invoiceIds) {
    fflib_QueryFactory query = newQueryFactory(false, false, true);
    query.setCondition('InvoiceName__c in :invoiceIds').toSOQL();
    return (List<ILVPos__c>) Database.query(query.toSOQL());
  }

}