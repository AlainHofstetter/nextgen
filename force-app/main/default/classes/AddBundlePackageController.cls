global with sharing class AddBundlePackageController {
    
    public static boolean isError;
    public static string isErrorText;
    public static string sortnumber{get;set;}
    public static string name {get; set;}
    public static id OpportunityId{get;set;}
    public  id QuoteId{get;set;}
    public static id PricebookId{get;set;}
    public static list<wrapperPackage> lst_wrapperPackageTemplates{get;set;}
    public final static String ERROR_NOPACKAGES = 'There are no packages available for the Opportunity Pricebook';
    public final static String ERROR_NOPRICEBOOK = 'There is no Pricebook assigned to the Opportunity, please select one first and try again';    
    public final static string BASICQUERIE = 'select id, name,SortNumber__c,Description__c,'
    										 +' (select id,Defaultprice__c,Defaultquantity__c,Product__r.name,ProductType__c' 
    										 +' From Package_Lines__r) from Pack__c '
    										 +' where PriceBook__c = \'REMOVEPRICEBOOK\' REMOVENAME REMOVESORT order by SortNumber__c';
    
    public final static string REMOVEPRICEBOOK = 'REMOVEPRICEBOOK'; 
    public final static string REMOVENAME = 'REMOVENAME'; 
    public final static string REMOVESORT = 'REMOVESORT'; 
    public final static string REPLACENAME = 'and name = ';
    public final static string REPLACESORT = 'and SortNumber__c =';
    public final static string BLANK = '';
    public final static string ERROR = 'ERROR';
    private final static string OPPPREFIX = '006';
    private final static string QUOTEPREFIX = '0Q0';
    
    global AddBundlePackageController (ApexPages.StandardController stdController) {
    	
    	if(stdController.getId().startsWith(OPPPREFIX)) {
    		Opportunity opp = (Opportunity)stdController.getRecord();
    		system.debug('....' + opp);
    		OpportunityId = stdController.getId();
    		PricebookId = [SELECT id,Pricebook2Id FROM Opportunity where id = :OpportunityId limit 1].Pricebook2Id;

    	}else if (stdController.getId().startsWith(QUOTEPREFIX)) {
    		Quote myquote = (Quote)stdController.getRecord();
    		system.debug('....' + myquote);
    		QuoteId = stdController.getId();
    		PricebookId = [SELECT id,Pricebook2Id FROM Quote where id = :QuoteId limit 1].Pricebook2Id;    	
    	}else {
    		isError = true;
    		isErrorText = ERROR_NOPACKAGES;
    	}
    	if(PricebookId == null) {
    		isError = true;
    		isErrorText = ERROR_NOPRICEBOOK;
    	}
    	
    	   	
    }
    
    @RemoteAction
    public static string queriePackages(string IncomingJson){
   		string result ='';
		try{
			system.debug('....' + IncomingJson);
	   		filterFields filters = (filterFields)JSON.deserialize(IncomingJson,filterFields.class);	   			   		
	   		string Querie = BASICQUERIE.replace(REMOVEPRICEBOOK,filters.pricebookEntry);
	   		Querie = (!String.isBlank(filters.name)) ? Querie.replace(REMOVENAME, REPLACENAME + +'\''+filters.name.trim()+'\''):  Querie.replace(REMOVENAME, BLANK);
	   		Querie = (!String.isBlank(filters.SortNumber)) ? Querie.replace(REMOVESORT, REPLACESORT+'\''+filters.SortNumber.trim()+'\''):  Querie.replace(REMOVESORT, BLANK);
	   		
	   		lst_wrapperPackageTemplates = new list<wrapperPackage>();
	   		system.debug('....' + Querie);
	   		List<sObject> sobjList = Database.query(Querie);
			list<Pack__c> lst_packs = (list<Pack__c>)sobjList;	
	   		for (Pack__c currentPack : lst_packs) {
										
				if (!currentPack.Package_Lines__r.isEmpty()) {
					lst_wrapperPackageTemplates.add(new WrapperPackage(currentPack));
				}					
			}
	   		
	   		lst_wrapperPackageTemplates = sortPackages(lst_wrapperPackageTemplates);
	   		
	   		result = json.serialize(lst_wrapperPackageTemplates);
	   		system.debug('....' + result);
	   		return result;
	   		
		}catch (Exception exc) {
			system.debug('....' + exc.getStackTraceString());
			system.debug('....' + exc.getLineNumber());
			return ERROR;
		}
   }   

    /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   22 Nov 2018
     * @Description     :   Deserialize Json and insert package into Opportunity
     */
    @RemoteAction
    
    public static string addToOpportunity(String jsonPackage){
    	system.debug('....' + jsonPackage);
    	jsonPackage = jsonPackage.replaceall('\"true\"','true');
    	system.debug('....' + jsonPackage);
        list<WrapperPackage> lst_wrapper = (list<WrapperPackage>) JSON.deserialize(jsonPackage, list<WrapperPackage>.class);
        List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem> ();
        
        map<integer,OpportunityPackage__c> map_possition_OpportunityPackage= new map<integer,OpportunityPackage__c>();
        map<integer,list<OpportunityLineItem>> map_position_listOLI= new map<integer,list<OpportunityLineItem>>();
        
        for (integer i = 0; i<lst_wrapper.size(); i++) {
        	
        	WrapperPackage currentWrapper = lst_wrapper[i];
        	
        	OpportunityPackage__c oP = new OpportunityPackage__c();
        	oP.BundlePackage__c = currentWrapper.bundlePackage;
        	oP.Opportunity__c = currentWrapper.OpportunityId;
        	oP.SortNumber__c = currentWrapper.sortNumber;
        	oP.TotalAmmount__c = Double.valueOf(currentWrapper.totalPrice);
        	
        	map_possition_OpportunityPackage.put(i,op);
        	map_position_listOLI.put(i,new list<OpportunityLineItem>());
        	
        	for (WrapperPackageItem currentLine :currentWrapper.listPackageItems) {
        		
        		OpportunityLineItem oli = new OpportunityLineItem();
          	    oli.Product2Id = currentLine.productId;
                oli.UnitPrice = Double.valueOf(currentLine.Defaultprice);
                if(oli.UnitPrice == 0){oli.UnitPrice = 1;}
                oli.Quantity = Double.valueOf(currentLine.Defaultquantity);
           		if(oli.Quantity == 0){oli.Quantity = 1;} 
             	//oli.TotalPrice = Double.valueOf(currentLine.Totalprice);
                oli.Opportunityid = currentWrapper.OpportunityId;
        		map_position_listOLI.get(i).add(oli);
        		
        		
        	}
        }
        insert map_possition_OpportunityPackage.values();
        system.debug('....' + map_possition_OpportunityPackage);
        list<OpportunityLineItem> list_opportunityLineItems = new list<OpportunityLineItem>();
        
        
        for (integer key:map_position_listOLI.keyset()) {
        	
        	for (OpportunityLineItem currentLine:map_position_listOLI.get(key)) {
        		
        		
        		currentLine.OpportunityPackage__c = map_possition_OpportunityPackage.get(Key).id;
        		list_opportunityLineItems.add(currentLine);
        	}
        }
        insert list_opportunityLineItems;
             
        return map_possition_OpportunityPackage.size()+' Package added. '+list_opportunityLineItems.size() + ' Products added';
    }

     /*
     * @Author          :   Lisis Rodriguez <lisis.rodriguez@empaua.com>
     * @Created         :   26 Nov 2018
     * @Description     :   Deserialize Json and insert package into Quote
     */
    @RemoteAction
    public static string addToQuote(String jsonPackage){
        system.debug('....' + jsonPackage);
        jsonPackage = jsonPackage.replaceall('\"true\"','true');
        system.debug('....' + jsonPackage);
        //WWrapperPackage is being using for Oportunity and Quote 
        list<WrapperPackage> lst_wrapper = (list<WrapperPackage>) JSON.deserialize(jsonPackage, list<WrapperPackage>.class);
        List<QuoteLineItem> olisToInsert = new List<QuoteLineItem> ();
        
        map<integer,Quote_Package__c> map_possition_QuotePackage= new map<integer,Quote_Package__c>();
        map<integer,list<QuoteLineItem>> map_position_listQLI= new map<integer,list<QuoteLineItem>>();
        Map<Id,Id> map_prodId_Pbe = new Map<Id, Id>();
        Set<Id>pricebookSet = new Set<Id>();
        
        for (integer i = 0; i<lst_wrapper.size(); i++) {
            
            WrapperPackage currentWrapper = lst_wrapper[i];
            
            Quote_Package__c qP = new Quote_Package__c();
            qP.Bundle_Package__c = currentWrapper.bundlePackage;
            qP.Quote__c = currentWrapper.quoteId;
            qP.Total_Amount__c = Double.valueOf(currentWrapper.totalPrice);
            qP.SortNumber__c = currentWrapper.sortNumber;
            
            map_possition_QuotePackage.put(i,qP);
            map_position_listQLI.put(i,new list<QuoteLineItem>());
            System.debug(loggingLevel.WARN, '....currentWrapper.PricebookId: ' + currentWrapper.PricebookId);
            pricebookSet.add(currentWrapper.PricebookId);
            
            for (WrapperPackageItem currentLine :currentWrapper.listPackageItems) {
                
                QuoteLineItem qli = new QuoteLineItem();
                qli.Product2Id = currentLine.productId;
                qli.UnitPrice = Double.valueOf(currentLine.Defaultprice);
                if(qli.UnitPrice == 0){qli.UnitPrice = 1;}
                qli.Quantity = Double.valueOf(currentLine.Defaultquantity);
                if(qli.Quantity == 0){qli.Quantity = 1;} 
                qli.QuoteId = currentWrapper.quoteId;
                map_position_listQLI.get(i).add(qli); 
                System.debug(loggingLevel.WARN, '....currentLine.productId: ' + currentLine.productId);
                map_prodId_Pbe.put(currentLine.productId, null);              
            }
        }
        insert map_possition_QuotePackage.values();
        system.debug('....' + map_possition_QuotePackage);
        
        list<QuoteLineItem> list_quoteLineItems = new list<QuoteLineItem>();
        for(PricebookEntry iPbe :[SELECT Id, Product2Id
                                FROM PricebookEntry
                                WHERE Pricebook2Id =: pricebookSet
                                AND Product2Id IN: map_prodId_Pbe.keySet()]){
            System.debug(loggingLevel.WARN, '....iPbe: ' + iPbe);
            map_prodId_Pbe.put(iPbe.Product2Id, iPbe.Id);
        }
        
        
        for (integer key:map_position_listQLI.keyset()) {
            
            for (QuoteLineItem currentLine:map_position_listQLI.get(key)) {
                currentLine.Quote_Package__c = map_possition_QuotePackage.get(Key).id;
                System.debug(loggingLevel.WARN, '....currentLine.Product2Id: ' + currentLine.Product2Id);
                currentLine.PriceBookEntryID = map_prodId_Pbe.get(currentLine.Product2Id);
                list_quoteLineItems.add(currentLine);
            }
        }
        insert list_quoteLineItems;
        return map_possition_QuotePackage.size()+' Package added. '+list_quoteLineItems.size() + ' Products added';
    }
	
	
	
    public class WrapperPackage {
    	boolean selected;
    	string name;
    	string sortNumber;
    	string description;
    	string totalPrice;
        string bundlePackage;
        @TestVisible
        string OpportunityId;
        @TestVisible
        string quoteId;
        @TestVisible
        string PricebookId;
        
    	list<WrapperPackageItem> listPackageItems;
    	
    	 public WrapperPackage(){
    	 	selected = false;
    	 	name = '';
    	 	sortNumber = '1';
    	 	description = '';
    	 	totalPrice = '0';
            bundlePackage = ' '; // cambiar
    	 	listPackageItems = new list<WrapperPackageItem>();
    	 }
    	 public WrapperPackage(pack__c pack){
    	 	selected = false;
    	 	name = pack.name;
    	 	sortNumber = pack.sortNumber__c;
    	 	description = pack.description__c;
    	 	totalPrice = '0';
            bundlePackage = pack.Id;
    	 	listPackageItems = new list<WrapperPackageItem>();
    	 	Decimal auxTotal= 0;
    	 	for (PackageLine__c packageLine :pack.Package_Lines__r) {
    	 		
    	 		system.debug('....' + 'Package Lines:'+ packageLine);
    	 		WrapperPackageItem auxPackageLineItem = new WrapperPackageItem(packageLine);
    	 		listPackageItems.add(auxPackageLineItem); 
    	 		auxTotal += Decimal.valueof(auxPackageLineItem.Totalprice);
    	 		
    	 	} 
    	 	totalPrice = String.valueof(auxTotal);
    	 }
    }
    public  class WrapperPackageItem {
    	boolean selected;
    	string name;
        string productId;
    	string ProductType;
    	string Defaultprice;
    	string Defaultquantity; 	
    	string Totalprice;
    	
    	
    	public WrapperPackageItem(PackageLine__c line) {
    		selected = false;
    		Defaultprice = String.valueof(line.Defaultprice__c);
    		Defaultquantity = String.valueof(line.Defaultquantity__c);
    		ProductType = line.ProductType__c;
    		name = line.product__r.name;
    		Totalprice = String.valueof(line.Defaultprice__c*line.Defaultquantity__c);   
            productId = line.Product__c;		
    	}
    	
    }
    
    public class filterFields {
    	@TestVisible
        string name;
        @TestVisible
    	string pricebookEntry;
        @TestVisible
    	string SortNumber;
        @TestVisible
    	string Opportunity;
    }
    private static list<WrapperPackage> sortPackages (list<WrapperPackage> listWP) {
		
		for (WrapperPackage WP:listWP) {
			
			WP.listPackageItems = sortPackageItems(WP.listPackageItems);
			
		}
		return listWP;
	}
	
	private static list<WrapperPackageItem> sortPackageItems (list<WrapperPackageItem> lst_wrapperPackageItems) {
		
		list<WrapperPackageItem> sortedList = new list<WrapperPackageItem>();
		map<string,WrapperPackageItem> map_key_item = new map<string,WrapperPackageItem>();
		list<string> listKeys = new list<string>();
		
		for(WrapperPackageItem item : lst_wrapperPackageItems) {
			
			string key = item.ProductType+item.name;
			map_key_item.put(key,item);
			listKeys.add(key);
			
		}
		listKeys.sort();
		
		for (string key : listKeys) {
			sortedList.add(map_key_item.get(key));
		}
		return sortedList;
		
	}
}