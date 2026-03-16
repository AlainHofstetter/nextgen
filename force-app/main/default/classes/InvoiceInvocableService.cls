public with sharing class InvoiceInvocableService {

    public static final Integer SERVICE_CREATE_INVOICE = 1;
    public static final Integer SERVICE_CANCEL_INVOICE = 2;


    @InvocableMethod(label='Invoice Service. Create or cancel invoices.')
    public static void invoiceServices(List<Requests> requests){
        InvoiceDocumentController.createInvoicePDF(requests);
    }   

    public class Requests{
        @invocableVariable(label='Invoice Id' required=true)
        public String invoiceId;
            
        @invocableVariable(label='Service (Create = 1 or Cancel = 2)' required=true)
        public Integer service;

        public Requests(){}

        public Requests(String invoiceId, Integer service){
            this.invoiceId = invoiceId;
            this.service = service;
        }
    }
}