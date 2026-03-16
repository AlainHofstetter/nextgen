trigger AccountTrigger on Account (after delete, after insert, after undelete,
    after update, before delete, before insert, before update) {
  fflib_SObjectDomain.triggerHandler(AccountDomain.class);
}