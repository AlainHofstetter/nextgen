public without sharing class InvoicePositionSelector extends fflib_SObjectSelector
        implements IInvoicePositionSelector {

    public InvoicePositionSelector() {
        super(true, false, false);
    }

    public static IInvoicePositionSelector newInstance() {
        return (IInvoicePositionSelector) Application.Selector.newInstance(InvoicePos__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return InvoicePos__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> (
                getSObjectType().getDescribe().fields.getMap().values()
        );
    }

    public List<InvoicePos__c> selectWithRelated(Set<Id> ids, Set<String> related) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(related);

        query.setCondition('id IN :ids');
        return (List<InvoicePos__c>) Database.query(query.toSOQL());
    }

    public List<InvoicePos__c> selectByInvoice(Set<Id> invoiceIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('InvoiceName__c IN :invoiceIds');
        return (List<InvoicePos__c>) Database.query(query.toSOQL());
    }

}