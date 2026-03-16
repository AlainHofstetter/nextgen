/*
*   @Class  		:	QuoteHandler
*
*   @Author         : 	Lisis Rodríguez <lisis.rodriguez@empaua.com>
*   @Created        : 	22 Aug 2018
*   @Description    : 	Handler for Quote_Trigger 
*
*   Modification Log
*   --------------------------------------------------------------------------------------
*   #       Developer           				Date            		Description
*   --------------------------------------------------------------------------------------
*   1       Lisis Rodríguez      				 20 Nov 2018     		Creation
*
*/
public  class QuoteHandler {
	
	/*public void OnBeforeInsert(list<Quote> newList) {

    }*/

    /*public void OnBeforeUpdate(Map<Id, Quote> oldMap,list<Quote> newList) {
    }
    
   /* public void OnBeforeDelete(List<Quote> oldList) {
       
    }*/
    
    
  /*  public void OnAfterInsert(List<Quote> newList) {
    	
    }*/

    public void OnAfterUpdate(Map<Id, Quote> oldMap, List<Quote> newList){
      List<Quote> toSync = new List<Quote>();
      for(Quote iQuote: newList){
        if(iQuote.Start_sync__c && !oldMap.get(iQuote.Id).Start_sync__c){
          toSync.add(iQuote);
        }
      }
      System.debug(loggingLevel.WARN, '....QuoteHandler toSync: ' + toSync);
      if(!toSync.isEmpty()){
        syncQuoteWithOppProd(toSync);
      }
    	
    }

   /* public void OnAfterDelete(List<Quote> oldList) {
      	
    }*/


    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Syncronize Opp Product with Quote Line Items 
     */
   /* Commmented by PARX ach 11.10.2019: its not used.
    public  void startSync( List<Quote> toSync){
        Map<Id, List<OpportunityLineItem>> mapOppId_Oli = new Map<Id, List<OpportunityLineItem>>();
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, Id> mapOppId_QuoteId = new Map<Id, Id>();

        for(Quote iQ: toSync){
          mapOppId_Oli.put(iQ.OpportunityId, new List<OpportunityLineItem>());
          mapOppId_QuoteId.put(iQ.OpportunityId, iQ.Id);
          
        }

        deleteExistentQuotesLineItems(quoteIds);
        deleteExistentQuotesPackages(quoteIds);
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityPackage__c, ServiceDate, Discount, 
                                                Description, Product2Id, Quantity, UnitPrice, OpportunityId ,
                                                ZImportId__c, ZImportSource__c, ZImportTimeStamp__c,
                                                PricebookEntryId
                                            FROM OpportunityLineItem
                                            WHERE OpportunityId IN: mapOppId_Oli.keySet()];
        Set<Id> oppPackageSet = new Set<Id>();
        Map<Id, Quote_Package__c> mapOppPackageId_QuotePack = new Map<Id, Quote_Package__c>();

        for(OpportunityLineItem oli: olis){
            oppPackageSet.add(oli.OpportunityPackage__c);
            //Adding to the map 
            List<OpportunityLineItem> oLiList = mapOppId_Oli.get(oli.OpportunityId);
            oLiList.add(oli);
            mapOppId_Oli.put(oli.OpportunityId, oLiList);

        }

        List<OpportunityPackage__c> oppPackages = [SELECT Id, BundlePackage__c, Opportunity__c
                                                FROM OpportunityPackage__c
                                                WHERE Id IN: oppPackageSet];

        List<Quote_Package__c> quotePackages = copyOppPackage(oppPackages,mapOppId_QuoteId);
        if(!quotePackages.isEmpty()){
            insert quotePackages;
        }

        for(Quote_Package__c iQPack: quotePackages){
            mapOppPackageId_QuotePack.put(iQPack.Opportunity_Package__c, iQPack); 
        }


        List<QuoteLineItem> qLis = copyOppProducts(mapOppId_Oli,toSync, mapOppPackageId_QuotePack);
        if(!qlis.isEmpty()){
            insert qLis;
        }
    }*/

     /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Syncronize Opp Product with Quote Line Items 
     */
    public  void syncQuoteWithOppProd( List<Quote> toSync){
        Map<Id, List<QuoteLineItem>> mapQuoteId_Qlis = new Map<Id, List<QuoteLineItem>>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> quotePackageSet = new Set<Id>();
        Map<Id, Id> mapQuote_OppId = new Map<Id, Id>();

        for(Quote iQ: toSync){
          quoteIds.add(iQ.Id);
          mapQuote_OppId.put(iQ.Id, iQ.OpportunityId);
          mapQuoteId_Qlis.put(iQ.Id, new List<QuoteLineItem>());
          oppIds.add(iQ.OpportunityId);
        }

        deleteOppProducts(oppIds);
		deleteOppPackages(oppIds);
        List<QuoteLineItem> qlis = [SELECT PricebookEntryId, ServiceDate, Discount, Description, Product2Id, Quote_Package__c,
                                      Quantity, UnitPrice, ZImportId__c, ZImportSource__c, ZImportTimeStamp__c, QuoteId 
                                    FROM QuoteLineItem
                                    WHERE QuoteId IN: quoteIds]; 

        Set<Id> oppPackageSet = new Set<Id>();
        Map<Id, OpportunityPackage__c> mapQuotePackId_oppPack = new Map<Id, OpportunityPackage__c>();

        for(QuoteLineItem iQli: qlis){
          quotePackageSet.add(iQli.Quote_Package__c);
          List<QuoteLineItem> qliList = mapQuoteId_Qlis.get(iQli.QuoteId);
          qliList.add(iQli);
          mapQuoteId_Qlis.put(iQli.QuoteId, qliList);
        }

        List<Quote_Package__c> quotePackages = [SELECT Id, Bundle_Package__c, Quote__c
                                                FROM Quote_Package__c
                                                WHERE Id IN: quotePackageSet];

        List<OpportunityPackage__c> oppPackages = copyQuotePackage(quotePackages, mapQuote_OppId);
        if(!oppPackages.isEmpty()){
            insert oppPackages;
        }

        for(OpportunityPackage__c ioppPack: oppPackages){
            mapQuotePackId_oppPack.put(ioppPack.Quote_Package__c, ioppPack); 
        }

        List<OpportunityLineItem> oLis = copyQLiProducts(mapQuoteId_Qlis,toSync,mapQuotePackId_oppPack);
System.debug('***oLis ' + oLis);
        if(!oLis.isEmpty()){
            insert oLis;
        }
      }


    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Delete all Quote Line Items related to a Quote given a Quote Id 
     */
   /* Commmented by PARX ach 11.10.2019: its not used. 
   private void deleteExistentQuotesLineItems(Set<Id> quoteIds){
      List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId IN: quoteIds];
      if(!qlis.isEmpty()){
        delete qlis;
      }
    }*/
    
      /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Delete all Quote Line Items related to a Quote given a Quote Id 
     */
    /* Commmented by PARX ach 11.10.2019: its not used.
    private void deleteExistentQuotesPackages(Set<Id> quoteIds){
      List<Quote_Package__c> qlis = [SELECT Id FROM Quote_Package__c WHERE Quote__c IN: quoteIds];
      if(!qlis.isEmpty()){
        delete qlis;
      }
    }*/


    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   21 Nov 2018
     * @Description     :   Delete all Opp Line Items related to an Opp Set
     */
    private void deleteOppProducts(Set<Id> oppIds){
      List<OpportunityLineItem> olis= [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN:oppIds];
      if(!olis.isEmpty()){
        delete olis;
      }
    
    }
	/*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   21 Nov 2018
     * @Description     :   Delete all Opp Line Items related to an Opp Set
     */
    private void deleteOppPackages(Set<Id> oppIds){
      List<OpportunityPackage__c> olis= [SELECT Id FROM OpportunityPackage__c WHERE Opportunity__c IN:oppIds];
      if(!olis.isEmpty()){
        delete olis;
      }
    
    }

    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Given a List of Opp Package return a List of Quote Package by copying the fields 
     */
    /*Commmented by PARX ach 11.10.2019: its not used.
    private List<Quote_Package__c> copyOppPackage(List<OpportunityPackage__c> oppPackages, Map<Id, Id> mapOppId_QuoteId){
        List<Quote_Package__c> quotePackages = new List<Quote_Package__c>();
        for(OpportunityPackage__c iOppP: oppPackages){
            Quote_Package__c qP = new Quote_Package__c();
            qP.Bundle_Package__c = iOppP.BundlePackage__c;
            qP.Opportunity_Package__c = iOppP.Id;
            qP.Quote__c = mapOppId_QuoteId.get(iOppP.Opportunity__c);
            quotePackages.add(qP);
        }
        return quotePackages;
    }*/

        /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   21 Nov 2018
     * @Description     :   Given a List of Quote Package return a List of Opp Package by copying the fields 
     */
    private List<OpportunityPackage__c> copyQuotePackage(List<Quote_Package__c> quotePackages, Map<Id, Id>mapQuote_OppId){
        List<OpportunityPackage__c> oppPackages = new List<OpportunityPackage__c>();
        for(Quote_Package__c iQp: quotePackages){
            OpportunityPackage__c oppP = new OpportunityPackage__c();
            oppP.BundlePackage__c = iQp.Bundle_Package__c;
            oppP.Opportunity__c = mapQuote_OppId.get(iQp.Quote__c);
            oppP.Quote_Package__c = iQp.Id;
            oppPackages.add(oppP);
        }
        return oppPackages;
    }

    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   19 Nov 2018
     * @Description     :   Copy fields from Opp Product to new Quote Line Item
     */
    /*Commmented by PARX ach 11.10.2019: its not used.
    private List<QuoteLineItem> copyOppProducts(Map<Id, List<OpportunityLineItem>> mapOppId_OliList, List<Quote> toSync,
                                               Map<Id, Quote_Package__c> mapOppPackageId_QuotePack){
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for(Quote iQ: toSync){
          for(OpportunityLineItem iOli: mapOppId_OliList.get(iQ.OpportunityId)){
              QuoteLineItem qLi = new QuoteLineItem();
              qLi.QuoteId = iQ.Id;
              qLi.PricebookEntryId = iOli.PricebookEntryId;
              qLi.ServiceDate = iOli.ServiceDate;
              qLi.Discount = iOli.Discount;
              qLi.Description = iOli.Description;
              qLi.Product2Id = iOli.Product2Id;
              qLi.Quantity = iOli.Quantity;
              qLi.UnitPrice = iOli.UnitPrice;
              qLi.ZImportId__c = iOli.ZImportId__c;
              qLi.ZImportSource__c = iOli.ZImportSource__c;
              qLi.ZImportTimeStamp__c = iOli.ZImportTimeStamp__c;
              if(mapOppPackageId_QuotePack.containsKey(iOli.OpportunityPackage__c)){
                  qLi.Quote_Package__c = mapOppPackageId_QuotePack.get(iOli.OpportunityPackage__c).Id;
              }
              qlis.add(qLi);
          }
        }
        return qlis;
    }*/

        /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   21 Nov 2018
     * @Description     :   Copy fields from Quote Line Item  to new Opp Product
     */
    private List<OpportunityLineItem> copyQLiProducts(Map<Id, List<QuoteLineItem>> mapQuoteId_Qlis, List<Quote> toSync,
                                               Map<Id, OpportunityPackage__c> mapQuotePackId_oppPack ){
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Quote iQ: toSync){
          for(QuoteLineItem iQli: mapQuoteId_Qlis.get(iQ.Id)){
              OpportunityLineItem oLi = new OpportunityLineItem();
              oLi.PricebookEntryId = iQli.PricebookEntryId;
              oLi.ServiceDate = iQli.ServiceDate;
              oLi.Discount = iQli.Discount;
              oLi.Description = iQli.Description;
              oLi.Product2Id = iQli.Product2Id;
              oLi.Quantity = iQli.Quantity;
              oLi.UnitPrice = iQli.UnitPrice;
              oLi.ZImportId__c = iQli.ZImportId__c;
              oLi.ZImportSource__c = iQli.ZImportSource__c;
              oLi.ZImportTimeStamp__c = iQli.ZImportTimeStamp__c;
              oLi.OpportunityId = iQ.OpportunityId;
              if(mapQuotePackId_oppPack.containsKey(iQli.Quote_Package__c)){
                  oLi.OpportunityPackage__c = mapQuotePackId_oppPack.get(iQli.Quote_Package__c).Id;
              }
              olis.add(oLi);
          }
        }
        return olis;
    }





    
 
}