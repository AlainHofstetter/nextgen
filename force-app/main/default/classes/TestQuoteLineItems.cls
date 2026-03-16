/**
 * Created by dudunato on 30.11.17.
 */

@IsTest
private class TestQuoteLineItems {

    @IsTest(SeeAllData=true)
    private static void testTrigger() {
        SObjectType t = QuoteLineItem.SObjectType;
        fflib_QueryFactory qf = new fflib_QueryFactory(t);
        qf.selectField('Id');
        qf.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(1);
        List<QuoteLineItem> theList = (List<QuoteLineItem>) Database.query(qf.toSOQL());

        if (!theList.isEmpty())
            update theList;
    }

    @IsTest
    private static void testFindQuoteLineItemsSuperior() {

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        IQuoteLineItemsSelector selectorMock = new Mocks.QuoteLineItemsSelector(mocks);

        // Given
        mocks.startStubbing();
        Product2 prod = new Product2(
                Id = fflib_IDGenerator.generate(Product2.SObjectType),
                SuperiorProduct__c = fflib_IDGenerator.generate(Product2.SObjectType)
        );
        QuoteLineItem item = new QuoteLineItem(
                Id = fflib_IDGenerator.generate(QuoteLineItem.SObjectType),
                QuoteId = fflib_IDGenerator.generate(Quote.SObjectType)
        );
        item.Product2 = prod;
        QuoteLineItem itemSuperior = new QuoteLineItem(
                Id = fflib_IDGenerator.generate(QuoteLineItem.SObjectType),
                Product2Id = prod.SuperiorProduct__c,
                QuoteId = item.QuoteId
        );
        mocks.when(selectorMock.sObjectType()).thenReturn(QuoteLineItem.SObjectType);
        mocks.when(selectorMock.byId(new Set<Id>{
                item.Id
        })).thenReturn(new List<QuoteLineItem>{item});
        mocks.when(selectorMock.byProduct(new Set<Id>{
                prod.SuperiorProduct__c
        })).thenReturn(new List<QuoteLineItem>{itemSuperior});
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Selector.setMock(selectorMock);

        // When
        new QuoteLineItems(new List<QuoteLineItem> {item}).findQuoteLineItemsSuperior();

        // Then
        ((IQuoteLineItemsSelector) mocks.verify(selectorMock)).byId(new Set<Id>{item.Id});
        ((IQuoteLineItemsSelector) mocks.verify(selectorMock)).byProduct(new Set<Id>{prod.SuperiorProduct__c});
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock))
                .registerDirty(
                fflib_Match.sObjectWith(
                        new Map<SObjectField, Object>{
                                QuoteLineItem.Id => item.Id,
                                QuoteLineItem.SuperiorQuoteLineItem__c => itemSuperior.Id
                        }
                )
        );
        ((fflib_ISObjectUnitOfWork) mocks.verify(uowMock)).commitWork();
    }

}