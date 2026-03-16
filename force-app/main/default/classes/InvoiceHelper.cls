/**
 * Trigger Helper class for Invoice Handler that contains utility methods.
 * 
 * Processes filtering of invoices and then handles QR code regeneration by deleting
 * old QR codes and invoking a future method to generate new ones.
 * 
 * @author Jorge Valdes
 * @since Feb 2025
 */
public with sharing class InvoiceHelper {
    
    // Set of field API names to monitor for changes.
    private static final Set<String> MONITORED_FIELDS = new Set<String>{
        'AccountNameLegal__c',
        'InvoiceReceiver__c',
        'BillingAddressStreetNr__c',
        'BillingAddressZIP__c',
        'BillingAdressCity__c',
        'ProjectInvoiceCurrency__c',
        'InvoiceTotalAmountGross__c',
        'BankName__c',
        'IBAN__c',
        'BankClearing__c',
        'SWIFT__c'
    };

    /**
     * Updates the QR code for qualifying Invoice__c records.
     * 
     * This method:
     * 1. Filters all invoices that have BillingCountry = 'SWITZERLAND' and any monitored field changed.
     * 2. Deletes old existing QR code files attached to those invoices.
     * 3. Invokes a future method to generate a new QR code for each qualifying invoice.
     *
     * @param oldMap Map of Invoice__c records before update.
     * @param newMap Map of Invoice__c records after update.
     */
    public static void updateQRCode(Map<Id, Invoice__c> oldMap, Map<Id, Invoice__c> newMap) {
        System.debug('+++ InvoiceHelper.updateQRCode() invoked. Invoice updated: ' + newMap.size());
        // Step 1: Filter invoices that need a new QR Code
        Map<Id, Invoice__c> invoicesToProcess = filterInvoicesForQRCode(oldMap, newMap);
        if (invoicesToProcess.isEmpty()) {
            return;
        }

        System.debug('+++ Found ' + invoicesToProcess.size() + ' invoices to process for QR code regeneration.');
        
        // Step 2: Delete old QR Codes
        Set<Id> invoiceIds = invoicesToProcess.keySet();
        List<ContentDocumentLink> lstContentDocumentLinks = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoiceIds
              AND ContentDocument.Title LIKE :Label.QRInvoicePrefix + '%'
        ];

        System.debug('+++ Found ' + lstContentDocumentLinks.size() + ' old QR code documents to delete.');
        
        if (!lstContentDocumentLinks.isEmpty()) {
            Set<Id> contentDocIds = new Set<Id>();
            for (ContentDocumentLink cdl : lstContentDocumentLinks) {
                contentDocIds.add(cdl.ContentDocumentId);
            }
            List<ContentDocument> docsToDelete = [
                SELECT Id FROM ContentDocument
                WHERE Id IN :contentDocIds
            ];
            if (!docsToDelete.isEmpty()) {
                try {
                    delete docsToDelete;
                } catch(Exception e) {
                    System.debug('+++ Error deleting old QR code documents: ' + e.getMessage());
                }
            }
        }
        
        // Step 3: Call method to generate a new QR code for each invoice
        for (Invoice__c invoiceRecord : invoicesToProcess.values()) {
            try {
                generateQRCode(invoiceRecord.Id);
            } catch(Exception e) {
                System.debug('+++ Error generating QR code for invoice ' + invoiceRecord.Id + ': ' + e.getMessage());
            }
        }
    }

    @future(callout=true)
    public static void generateQRCode(Id invoiceId) {
        // Include BillingAdressCity__c so we can normalize special characters such as "Zürich"
        Invoice__c invoiceRecord = [
            SELECT Id, Name, InvoiceTotalAmountGross__c, AccountLanguage__c, BillingAdressCity__c
            FROM Invoice__c
            WHERE Id = :invoiceId
        ];
        // Normalize in-memory only: convert "Zürich" (and any umlaut variants) to ASCII-friendly "Zurich"
        // No DML updates are performed.
        try {
            String city = (String)invoiceRecord.get('BillingAdressCity__c');
            if (city != null) {
                // Replace German umlauts and ß with ASCII equivalents
                // Specifically handle "Zürich" -> "Zurich"
                String normalized = city;
                normalized = normalized.replace('ä','a').replace('Ä','A');
                normalized = normalized.replace('ö','o').replace('Ö','O');
                normalized = normalized.replace('ü','u').replace('Ü','U');
                normalized = normalized.replace('ß','ss');
                // If downstream QRCodeService reads the field value, pass a shallow clone with normalized city
                // to avoid mutating the original sObject.
                Invoice__c qrInput = invoiceRecord.clone(false, true, false, false);
                qrInput.put('BillingAdressCity__c', normalized);
                QRCodeService.generateQRCode(qrInput);
                return;
            }
        } catch (Exception e) {
            system.debug('Error with Normalization of BillingAdressCity '+ InvoiceRecord.BillingAdressCity__c + 'Invoice ID: '+ InvoiceRecord.Id);
        }
        QRCodeService.generateQRCode(invoiceRecord);
    }

    /**
     * Filters Invoice__c records that need a new QR code.
     *
     * An invoice qualifies if:
     *   - It has a non-null InvoiceReceiver__c and its related Account's BillingCountry__c equals 'SWITZERLAND'
     *   - At least one of the monitored fields has changed between the old and new versions.
     *
     * @param oldMap Map of Invoice__c records before update.
     * @param newMap Map of Invoice__c records after update.
     * @return Map of Invoice__c records to process for QR code regeneration.
     */
    public static Map<Id, Invoice__c> filterInvoicesForQRCode(Map<Id, Invoice__c> oldMap, Map<Id, Invoice__c> newMap) {
        System.debug('---InvoiceHelper.filterInvoicesForQRCode---  oldMap: ' +oldMap);
        System.debug('---InvoiceHelper.filterInvoicesForQRCode---  newMap: ' +newMap);
        Map<Id, Invoice__c> invoicesToProcess = new Map<Id, Invoice__c>();
        
        // Collect all InvoiceReceiver__c Ids from the new invoices
        Set<Id> receiverIds = new Set<Id>();
        for (Invoice__c inv : newMap.values()) {
            if (inv.InvoiceReceiver__c != null) {
                receiverIds.add(inv.InvoiceReceiver__c);
            }
        }
        
        // Query the Account for BillingCountry__c
        Map<Id, Account> receiverAccountMap = new Map<Id, Account>(
            [SELECT Id, BillingCountry__c FROM Account WHERE Id IN :receiverIds]
        );
        
        // Iterate over the new Invoice__c records and filter those meeting the criteria
        for (Invoice__c newInv : newMap.values()) {
            // Ensure the InvoiceReceiver is present and the queried Account has BillingCountry__c == 'SWITZERLAND'
            if (newInv.InvoiceReceiver__c == null ||
                !receiverAccountMap.containsKey(newInv.InvoiceReceiver__c) ||
                receiverAccountMap.get(newInv.InvoiceReceiver__c).BillingCountry__c != 'SWITZERLAND') {
                continue;
            }
            
            Invoice__c oldInv = oldMap.get(newInv.Id);
            System.debug('---InvoiceHelper.filterInvoicesForQRCode---  oldInv: ' +oldInv);
            if (haveMonitoredFieldsChanged(oldInv, newInv)) {
                invoicesToProcess.put(newInv.Id, newInv);
            }
        }
        return invoicesToProcess;
    }
    
    /**
     * Determines if any of the monitored fields have changed between two Invoice__c records.
     *
     * @param oldInv The original Invoice__c record.
     * @param newInv The updated Invoice__c record.
     * @return True if at least one monitored field has changed; otherwise, false.
     */
    @TestVisible
    private static Boolean haveMonitoredFieldsChanged(Invoice__c oldInv, Invoice__c newInv) {
        System.debug('---InvoiceHelper.haveMonitoredFieldsChanged---  oldInv: ' +oldInv);
        System.debug('---InvoiceHelper.haveMonitoredFieldsChanged---  newInv: ' +newInv);
        for (String fieldName : MONITORED_FIELDS) {
            System.debug('---InvoiceHelper.haveMonitoredFieldsChanged---  fieldName: ' +fieldName+' old: '+oldInv.get(fieldName)+' new: '+newInv.get(fieldName));
            if (oldInv.get(fieldName) != newInv.get(fieldName)) {
                return true;
            }
        }
        return false;
    }
}