public with sharing class QuotePackageHandler {
    
    public void OnBeforeDelete (map<id,Quote_Package__c> map_olds) {
    	
    	deleteAssignedQuoteLines(map_olds.keyset());
    }
    
    private void deleteAssignedQuoteLines (set<id> set_idstocheck) {
    	
    	list<QuoteLineItem> lst_quoteLinesToDelete = [select id from QuoteLineItem where Quote_Package__c IN:set_idstocheck];
    	if(!lst_quoteLinesToDelete.isEmpty()) { delete lst_quoteLinesToDelete;}
    }
}