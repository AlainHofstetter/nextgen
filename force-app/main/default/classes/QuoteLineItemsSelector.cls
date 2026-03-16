/**
 * Created by dudunato on 30.11.17.
 */

public without sharing class QuoteLineItemsSelector extends fflib_SObjectSelector
        implements IQuoteLineItemsSelector {

    public static IQuoteLineItemsSelector newInstance() {
        return (IQuoteLineItemsSelector) Application.Selector.newInstance(QuoteLineItem.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                QuoteLineItem.Id,
                QuoteLineItem.Product2Id,
                QuoteLineItem.QuoteId,
                QuoteLineItem.Description,
                QuoteLineItem.ProductType__c,
                QuoteLineItem.ProductSubType__c,
                QuoteLineItem.SortNr__c,
                QuoteLineItem.SuperiorQuoteLineItem__c,
                QuoteLineItem.ProjectManagementAllowancePackage__c,
                QuoteLineItem.ExpenseAllowancePackage__c,
                QuoteLineItem.SupplierCostsGroup__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return QuoteLineItem.sObjectType;
    }

    public List<QuoteLineItem> byId(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Product2.SuperiorProduct__c');
        query.setCondition('Id IN :ids');

        return (List<QuoteLineItem>) Database.query(query.toSOQL());
    }

    public List<QuoteLineItem> byProduct(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Product2Id IN :ids');

        return (List<QuoteLineItem>) Database.query(query.toSOQL());
    }

    public List<QuoteLineItem> byQuoteId(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('QuoteId IN :ids AND ProductType__c != \'Text\' AND Option__c != true');
        List<SObject> items = Database.query(query.toSOQL());

        return (items == null || items.isEmpty())
                ? null
                : (List<QuoteLineItem>) Database.query(query.toSOQL());
    }


}