trigger AbacusTransferNGTrigger on AbacusTransferNG__c(before insert) {
  AbacusTransferNGTriggerHandler.handleBeforeInsert(Trigger.new);
}
