public interface IILVPosSelector extends fflib_ISObjectSelector {

  List<ILVPos__c> selectWithRelated(Set<Id> ids, Set<String> related);

  List<ILVPos__c> selectByInvoice(Set<Id> invoiceIds);

}