/**
 * QRBillPARXHandler
 * @author ldo
 * @Modified By Manjiri
 * @copyright PARX
 *
 */
public class QRBillRequest {
    
    // Creditor information
    public String creditor_account;
    public String creditor_name;
    public String creditor_street;
    public String creditor_houseNumber;
    public String creditor_country;
    public String creditor_postalCode;
    public String creditor_town;

    // Debtor information
    public String debtor_name;
    public String debtor_street;
    public String debtor_houseNumber;
    public String debtor_country;
    public String debtor_postalCode;
    public String debtor_town;

    // Bill information
    public String billCurrency;
    public Decimal amount;
    public String creditorReference;
    public String additionlInformation;
    public String billLanguage;

    public String recordId;
    public String name;
    
    Map<String, QRCountryCode__mdt> mapCountryCodes = QRCountryCode__mdt.getAll();
    Map<String, QRLanguageCode__mdt> mapLanguageCodes = QRLanguageCode__mdt.getAll();
    
    public QRBillRequest(Invoice__c obj, String description){
        name = obj.Name;
        this.recordId = obj.Id;
		this.creditor_account = obj.ProjectInvoiceCurrency__c == 'CHF'? obj.ProjectCostCenter__r.CHFQRIBAN__c : obj.ProjectCostCenter__r.EURQRIBAN__c;
        //this.creditor_account = 'CH373000527314691801Z';
        //this.creditor_name = obj.ProjectCostCenter__r.Name;
        this.creditor_name = obj.ProjectCostCenter__r.LegalAccount__r.Name;
        this.creditor_street = obj.ProjectCostCenter__r.LegalAccount__r.BillingStreetNr__c;
        this.creditor_houseNumber = '';
        this.creditor_country = ( mapCountryCodes.get(obj.ProjectCostCenter__r.LegalAccount__r.BillingCountry__c) != null) ? mapCountryCodes.get(obj.ProjectCostCenter__r.LegalAccount__r.BillingCountry__c).CountryCode__c : ''; 
        this.creditor_postalCode = obj.ProjectCostCenter__r.LegalAccount__r.BillingZip__c;
        this.creditor_town = obj.ProjectCostCenter__r.LegalAccount__r.BillingCity__c;
        this.creditorReference = obj.ESRunformatted__c;
        //this.creditorReference = null;
        this.debtor_name = obj.AccountNameLegal__c;
        //this.debtor_name = 'Stiftung juristische Weiterbildung Zürich Zürcher Abfallverwertungs AG';
        this.debtor_street = (obj.BillingNameAddition__c != null) ? obj.BillingNameAddition__c+'\n'+obj.BillingAddressStreetNr__c : obj.BillingAddressStreetNr__c;
        this.debtor_houseNumber = '';
        this.debtor_country = ( mapCountryCodes.get(obj.BillingAddressCountry__c) != null) ? mapCountryCodes.get(obj.BillingAddressCountry__c).CountryCode__c : ''; 
        this.debtor_postalCode = obj.BillingAddressZIP__c;
        this.debtor_town = obj.BillingAdressCity__c;
        this.billCurrency = obj.ProjectInvoiceCurrency__c; 
        this.amount = obj.InvoiceTotalAmountGross__c;
        this.additionlInformation = ''+obj.InvoiceDocumentNr__c;
		this.billLanguage = ( mapLanguageCodes.get(obj.InvoiceReceiver__r.AccountLanguage__c) !=null ) ? mapLanguageCodes.get(obj.InvoiceReceiver__r.AccountLanguage__c).LanguageCode__c : '';

        system.debug('***** obj.ProjectInvoiceCurrency__c : *****'+obj.ProjectInvoiceCurrency__c);
        system.debug('***** obj.ProjectCostCenter__r.CHFQRIBAN__c : *****'+obj.ProjectCostCenter__r.CHFQRIBAN__c);
        system.debug('***** obj.ProjectCostCenter__r.EURQRIBAN__c : *****'+obj.ProjectCostCenter__r.EURQRIBAN__c);        
        system.debug('***** recordId             : *****'+this.recordId);
        system.debug('***** debtor_town          : *****'+this.debtor_town);
        system.debug('***** debtor_street        : *****'+this.debtor_street);
        system.debug('***** debtor_postalCode    : *****'+this.debtor_postalCode);
        system.debug('***** debtor_country       : *****'+this.debtor_country);
        system.debug('***** debtor_houseNumber   : *****'+this.debtor_houseNumber);
        system.debug('***** debtor_name          : *****'+this.debtor_name);
        system.debug('***** creditor_account     : *****'+this.creditor_account);
        system.debug('***** creditor_name        : *****'+this.creditor_name);
        system.debug('***** creditor_street      : *****'+this.creditor_street);
        system.debug('***** creditor_houseNumber : *****'+this.creditor_houseNumber);
        system.debug('***** creditor_country     : *****'+this.creditor_country);
        system.debug('***** creditor_postalCode  : *****'+this.creditor_postalCode);
        system.debug('***** creditor_town        : *****'+this.creditor_town);
        system.debug('***** creditorReference    : *****'+this.creditorReference);
        system.debug('***** billLanguage         : *****'+this.billLanguage);
        system.debug('***** this.additionlInformation         : *****'+this.additionlInformation);
    }  

}