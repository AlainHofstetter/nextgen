/**
 * Created by dudunato on 29.11.17.
 */

public without sharing class QuoteLineItems extends fflib_SObjectDomain
        implements IQuoteLineItems {

    public static IQuoteLineItems newInstance(List<QuoteLineItem> records) {
        return (IQuoteLineItems) Application.Domain.newInstance(records);
    }

    public QuoteLineItems(List<QuoteLineItem> records) {
        super(records);
        Configuration.disableTriggerCRUDSecurity();
    }

    public override void onAfterInsert() {
        findQuoteLineItemsSuperior();
    }

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        findQuoteLineItemsSuperior();
    }

    @TestVisible
    private void findQuoteLineItemsSuperior() {
        fflib_SObjectDomain.getTriggerEvent(QuoteLineItems.class).disableAllAfter();
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        List<QuoteLineItem> items = QuoteLineItemsSelector.newInstance().byId(new Map<Id, SObject>(records).keySet());

        Map<Id, List<SObject>> itemsPerSuperiorProduct
                = Utils.listToMapLists('Product2.SuperiorProduct__c', items);

        List<QuoteLineItem> superiorItems = QuoteLineItemsSelector.newInstance().byProduct(itemsPerSuperiorProduct.keySet());

        for (QuoteLineItem item : superiorItems) {
            List<QuoteLineItem> childrenItems = (List<QuoteLineItem>) itemsPerSuperiorProduct.get(item.Product2Id);

            for (QuoteLineItem childItem : childrenItems) {
                if (item.QuoteId == childItem.QuoteId) {
                    childItem.SuperiorQuoteLineItem__c = item.Id;
                    uow.registerDirty(childItem);
                }
            }
        }

        uow.commitWork();
    }


    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new QuoteLineItems(sObjectList);
        }
    }
}