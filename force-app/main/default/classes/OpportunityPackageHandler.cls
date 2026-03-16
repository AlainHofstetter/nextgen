public class OpportunityPackageHandler {
    
    
     public void OnBeforeDelete (map<id,OpportunityPackage__c> map_olds) {
    	
    	deleteAssignedOpportunityLines(map_olds.keyset());
    }
    
    private void deleteAssignedOpportunityLines (set<id> set_idstocheck) {
    	
    	list<OpportunityLineItem> lst_OpportunityLinesToDelete = [select id from OpportunityLineItem where OpportunityPackage__c IN:set_idstocheck];
    	if(!lst_OpportunityLinesToDelete.isEmpty()) { delete lst_OpportunityLinesToDelete;}
    }
}