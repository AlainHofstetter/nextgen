/**
 * Created by dudunato on 30.11.17.
 */

trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(QuoteLineItems.class);
}