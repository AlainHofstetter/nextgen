trigger InvoiceTrigger on Invoice__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
  fflib_SObjectDomain.triggerHandler(Invoice.class);

  if (Trigger.isAfter){
      if(Trigger.isUpdate){
          System.debug('***** In Trigger After *****');
          InvoiceHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
          //QRBillPARXHandler.startQrBillProcess(Trigger.new,Trigger.oldMap);
      }
  }
}