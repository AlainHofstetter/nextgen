trigger ContentDocumentLinksTrigger on ContentDocumentLink (after delete, after insert, after undelete,
    after update, before delete, before insert, before update) {
    fflib_SObjectDomain.triggerHandler(ContentDocumentLinks.class);
}