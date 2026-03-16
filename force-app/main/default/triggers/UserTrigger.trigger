trigger UserTrigger on User (after delete, after insert, after undelete, 
		after update, before delete, before insert, before update) 
{
  fflib_SObjectDomain.triggerHandler(UserDomain.class);
}