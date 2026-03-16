/**
 * Created by dudunato on 29.11.17.
 */

trigger ContentDocumentsTrigger on ContentDocument (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(ContentDocuments.class);
}