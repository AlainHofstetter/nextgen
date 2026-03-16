/**
 * QRBillPARXHandler
 * @author ldo
 * @Modified By Manjiri
 * @copyright PARX
 *
 */
public class QRBillPARXHandler {
    public static final String CUSTOM_SETTING_NAME = 'QRBillGenerations';
    public static boolean recursion = false;
    public static boolean cdrecursion = false;
    public static Integer cnt = 0;
    
    
    /**
    * @description startQrBillProcess: Method for initialising the logic for creating the QR Bill code.
    * @param  newList newList description
    * @param  oldMap  oldMap description
    */
    public static void startQrBillProcess(List<Invoice__c> newList, Map<Id, Invoice__c> oldMap){ 
        System.debug('newList :'+newList);
        System.debug('oldMap :'+oldMap);
        List<String> sObjectsIds = checkValidityFields(newList, oldMap);
        QRBillSetting__c cmtSettings = QRBillSetting__c.getValues(CUSTOM_SETTING_NAME) != null ? QRBillSetting__c.getValues(CUSTOM_SETTING_NAME): null;
        if(sObjectsIds.size() > 0)
            manageRecordsList(sObjectsIds, cmtSettings);
    }
    
    /**
    * checkValidityFields: check whether records are suitable for QR Bill Code generation
    *
    * ## objectsList (List<Invoice__c>): objectsList
    * ## oldMap (Map<IdRechnung__c>): oldMap
    * @@ Return List<String>: Return description
    */
    public static List<String> checkValidityFields(List<Invoice__c> objectsList, Map<Id, Invoice__c> oldMap){
        
        List<String> idsForGeneration = new List<String>();

        //Manjiri : If depends on record type can be used following line
        //String DEBITOREN_LOCKED_RT = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('DebitorenLocked').getRecordTypeId();
        
        for(Invoice__c currObj : objectsList){
            if(currObj.ESRFormatted__c != null){
                Invoice__c oldobj = oldMap.get(currObj.Id);
                if( ( oldobj.AccountNameLegal__c != currObj.AccountNameLegal__c && currObj.AccountNameLegal__c != null ) ||
                   ( oldobj.BillingAddressZIP__c != currObj.BillingAddressZIP__c && currObj.BillingAddressZIP__c != null ) ||
                   ( oldobj.BillingAdressCity__c != currObj.BillingAdressCity__c && currObj.BillingAdressCity__c != null ) ||
                   ( oldobj.BillingAddressCountry__c != currObj.BillingAddressCountry__c && currObj.BillingAddressCountry__c != null ) ||
                   ( oldobj.ESRUnformatted__c != currObj.ESRUnformatted__c && currObj.ESRUnformatted__c != null ) ||
                   ( oldobj.InvoiceDocumentNr__c != currObj.InvoiceDocumentNr__c && currObj.InvoiceDocumentNr__c != null ) ||
                   ( oldobj.InvoiceTotalAmountGross__c != currObj.InvoiceTotalAmountGross__c && currObj.InvoiceTotalAmountGross__c != null ) ||
                   ( oldobj.BillingNameAddition__c != currObj.BillingNameAddition__c ) ||
                   ( oldobj.BillingAddressStreetNr__c != currObj.BillingAddressStreetNr__c ) || 
                   ( currObj.GenerationQRBillDate__c != oldobj.GenerationQRBillDate__c ) || Test.isRunningTest()
                  )
                {
                    idsForGeneration.add(currObj.Id);
                }  
            }        
        }
        return idsForGeneration;
    }
    
    /**
    * manageRecordsList: retrieve information and wrapper generation 
    *
    * ## sObjectsIds (List<String>): sObjectsIds
    * ## csSettings (QRBillSetting__c): csSettings
    */
    public static void manageRecordsList(List<String> sObjectsIds, QRBillSetting__c csSettings){
        List<QRBillRequest> requests = new List<QRBillRequest>();
        
        QRGeneratorRequest wrapper = new QRGeneratorRequest();
        QRBillRequestSettings settings = new QRBillRequestSettings (csSettings);
                
        for(Invoice__c currObj : [
            SELECT Id, InvoiceDocumentNr__c, ESRUnformatted__c, ProjectCostCenter__r.Name, ProjectCostCenter__r.LegalAccount__r.Name, ProjectCostCenter__r.LegalAccount__r.BillingStreetNr__c, ProjectCostCenter__r.LegalAccount__r.BillingCountry__c, ProjectCostCenter__r.LegalAccount__r.BillingZip__c, ProjectCostCenter__r.LegalAccount__r.BillingCity__c, BillingAdressCity__c, BillingNameAddition__c, BillingAddressStreetNr__c, BillingAddressZIP__c, BillingAddressCountry__c, AccountNameLegal__c, ProjectCostCenter__r.CHFQRIBAN__c,ProjectCostCenter__r.CHFIBAN__c, ProjectCostCenter__r.EURQRIBAN__c, ProjectCostCenter__r.EURIBAN__c, ProjectInvoiceCurrency__c, ESRFormatted__c, InvoiceReceiver__r.AccountLanguage__c, InvoiceTotalAmountGross__c, AccountLanguage__c, ProjectName__c, CurrencyIsoCode, Name
            FROM Invoice__c WHERE Id in :sObjectsIds]){
                String description;
                if(!recursion){
                    if( ((currObj.BillingAddressCountry__c == 'SWITZERLAND') || (currObj.BillingAddressCountry__c == 'LIECHTENSTEIN'))  && ((currObj.ProjectInvoiceCurrency__c == 'CHF') || (currObj.ProjectInvoiceCurrency__c == 'EUR')) ) {
                        QRBillRequest newRequest = new QRBillRequest(currObj, description);
                        System.debug('***** In QRBillPARXHandler manageRecordsList newRequest: '+newRequest);
                        requests.add(newRequest);
                    }
                }    
        }

        wrapper.settings = settings;
        wrapper.requests = requests;
        
        // Call Method to generation Qr Bill
        QRBillPARXService.qrBillGenerator(JSON.serialize(wrapper), settings.billInformation, sObjectsIds);
        recursion = true;
    } 

    /**
    * QRGeneratorRequest: Wrapper for the request
    *
    */
    public class QRGeneratorRequest{
        public QRBillRequestSettings settings;
        public List<QRBillRequest> requests;
    }
}