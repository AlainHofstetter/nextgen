/**
 * Processes Invoice__c trigger events
 * This trigger handler is kept thin to maintain clarity and separation of responsibilities.
 * 
 * @author Jorge Valdes jorge@inspireai.com
 * @since Feb 2025
 */
public with sharing class InvoiceHandler {
    
    /**
     * Handles after-update events for Invoice__c.
     *
     * @param oldMap A map of Invoice__c records before update.
     * @param newMap A map of Invoice__c records after update.
     */
    public static void handleAfterUpdate(Map<Id, Invoice__c> oldMap, Map<Id, Invoice__c> newMap) {
        // Check if any of the updated invoices needs a new QR Code
        InvoiceHelper.updateQRCode(oldMap, newMap);
    }
}