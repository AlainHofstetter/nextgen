trigger PackageTrigger on Package__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
  fflib_SObjectDomain.triggerHandler(PackageDomain.class);
}