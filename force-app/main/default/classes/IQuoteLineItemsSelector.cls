/**
 * Created by dudunato on 30.11.17.
 */

public interface IQuoteLineItemsSelector extends  fflib_ISObjectSelector {

    List<QuoteLineItem> byId(Set<Id> ids);

    List<QuoteLineItem> byProduct(Set<Id> ids);

    List<QuoteLineItem> byQuoteId(Set<Id> ids);
    
}