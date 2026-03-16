/**
 * QRCodeService is responsible for generating QR codes for Invoice__c records.
 * It constructs the request payload using QRCodeRequestObj, performs the API callout,
 * and then associates the returned QR image with the invoice via ContentVersion and ContentDocumentLink.
 *
 * This class encapsulates the business logic and integration with the QR code generation API.
 *
 * @author 
 * @since Feb 2025
 * @documentation https://rest.qr-invoice.cloud/swagger-ui/index.html#/11%20Payment%20Part%20%26%20Receipt%20(QR%20Bill)/createPaymentPartReceipt
 */
public with sharing class QRCodeService {
    
    // Retrieve default tool settings for QR generation.
    static QRGeneratorToolSettings__c toolSettings = QRGeneratorToolSettings__c.getOrgDefaults();
    private static final String API_KEY_PARAM = '?api_key=';
    private static final String IMG_CONTENT_TYPE = 'image/jpeg';
    
    /**
     * Generates a QR code for the specified Invoice__c record.
     * Builds the QR code image, inserts it as a ContentVersion,
     * and creates a ContentDocumentLink to associate the image with the invoice.
     *
     * @param record The Invoice__c record for which the QR code is generated.
     */
    public static void generateQRCode(Invoice__c record) {
        // Validate that required custom settings are configured
        validateToolSettings();
        
        String qrCodeString = buildQRCodeImage(record);
        insertQRImage(record.Id, qrCodeString);
        
        Logger.info('QRCode generated.');
        Logger.saveLog();
    }
    
    /**
     * Validates that all required custom setting fields are configured.
     * @throws HandledException if any required field is missing.
     */
    private static void validateToolSettings() {
        // if (String.isBlank(toolSettings.API_endpoint__c)) {
        //     throw new HandledException('QR Generator API endpoint is not configured. Please configure the API_endpoint__c field in QRGeneratorToolSettings custom setting.');
        // }
        // if (String.isBlank(toolSettings.API_key__c)) {
        //     throw new HandledException('QR Generator API key is not configured. Please configure the API_key__c field in QRGeneratorToolSettings custom setting.');
        // }
    }
    
    /**
     * Inserts the QR image as a ContentVersion and creates a ContentDocumentLink
     * to associate the image with the given parent record.
     *
     * @param parentRecordId The ID of the parent Invoice__c record.
     * @param base64 The Base64 encoded QR code image.
     */
    private static void insertQRImage(Id parentRecordId, String base64) {
        String docName = Label.QRInvoicePrefix + '_' + Date.today().format();
        
        ContentVersion contentVersion = new ContentVersion(
            Title = docName,
            PathOnClient = docName + '.jpg',
            VersionData = EncodingUtil.base64Decode(base64)
        );
        insert contentVersion;
        
        // Retrieve the ContentDocumentId from the inserted ContentVersion.
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        
        // Create and insert a ContentDocumentLink to associate the document with the Invoice.
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = parentRecordId,
            ContentDocumentId = contentDocId,
            ShareType = 'V'
        );
        insert contentDocumentLink;
    }
    
    /**
     * Builds the QR code image for the specified Invoice__c record by making an HTTP POST callout
     * to the external QR code generation service.
     *
     * @param record The Invoice__c record.
     * @return A Base64 encoded string representing the QR code image.
     * @throws HandledException if an error occurs during the callout or processing.
     */
    @TestVisible
    private static String buildQRCodeImage(Invoice__c record) {
        // Set language based on the invoice's account language.
        String language = (record.AccountLanguage__c == 'DE') ? 'de' : 'en';
        
        // Build query parameters from tool settings.
        List<String> queryParameters = buildQueryParameters();
        
        // Build the JSON request body using QRCodeRequestObj.
        String requestBody = createRequestBody(record, language);
        System.debug('+++ Request body: ' + requestBody);
        
        HttpResponse response;
        try {
            response = doPost(queryParameters, requestBody, language);
        } catch (Exception ex) {
            Logger.exception('Error on QRCodeService.generateQRCode.', ex);
            throw new HandledException('Generate QR service general error. Please review the logs.');
        }
        
        String qrCodeString = EncodingUtil.base64Encode(response.getBodyAsBlob());
        if (String.isBlank(qrCodeString)) {
            Logger.error('Response body is empty.');
            Logger.saveLog();
            throw new HandledException('Generate QR service error. Please review the logs.');
        }
        
        return qrCodeString;
    }
    
    /**
     * Builds query parameters based on tool settings.
     *
     * @return A list of query parameters.
     */
    @TestVisible
    private static List<String> buildQueryParameters() {
        List<String> params = new List<String>();
        if (String.isNotBlank(toolSettings.API_resolution__c)) {
            params.add('resolution=' + toolSettings.API_resolution__c);
        }
        if (toolSettings.API_normalizeInput__c) {
            params.add('normalizeInput=' + toolSettings.API_normalizeInput__c);
        }
        if (toolSettings.API_boundaryLinesMargins__c) {
            params.add('boundaryLinesMargins=' + toolSettings.API_boundaryLinesMargins__c);
        }
        if (toolSettings.API_boundaryLineScissors__c) {
            params.add('boundaryLineScissors=' + toolSettings.API_boundaryLineScissors__c);
        }
        return params;
    }
    
    /**
     * Executes an HTTP POST callout to the QR code generation API.
     *
     * @param queryParameters A list of query parameters to be appended to the endpoint URL.
     * @param body The JSON request body.
     * @param language The language code for the request (e.g., 'en' or 'de').
     * @return The HttpResponse received from the API.
     * @throws HandledException if the response status code is not 200.
     */
    @TestVisible
    private static HttpResponse doPost(List<String> queryParameters, String body, String language) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        
        String endpoint = toolSettings.API_endpoint__c + API_KEY_PARAM + toolSettings.API_key__c;
        if (!queryParameters.isEmpty()){
            endpoint += '&' + String.join(queryParameters, '&');
        }
        
        request.setEndpoint(endpoint);
        request.setHeader('accept', IMG_CONTENT_TYPE);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept-Language', language);
        request.setBody(body);
        
        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200){
            Logger.error('Callout error. Status: ' + response.getStatus() + ' Code: ' + response.getStatusCode());
            Logger.info('Endpoint: ' + request.getEndpoint());
            Logger.info('Request body: ' + request.getBody());
            Logger.info('Response: ' + response.getBody());
            Logger.saveLog();
            throw new HandledException('Callout error. Status: ' + response.getStatus() + ' Code: ' + response.getStatusCode());
        }
        return response;
    }
    
    /**
     * Creates the JSON request body for the QR code generation API using the QRCodeRequestObj class.
     *
     * @param record The Invoice__c record.
     * @param language The language code for the request.
     * @return A JSON string representing the request payload.
     */
    @TestVisible
    private static String createRequestBody(Invoice__c record, String language) {
        // Query the invoice record to retrieve all necessary fields.
        record = [
            SELECT InvoiceReceiver__r.Name,
                   ProjectCostCenter__r.CHFIBAN__c,
                   ProjectCostCenter__r.CHFQRIBAN__c,
                   BillingAdressCity__c, 
                   BillingAddressStreetNr__c, 
                   BillingAddressZIP__c, 
                   InvoiceTotalAmountGross__c,
                   ProjectInvoiceCurrency__c, 
                   ProjectName__r.Name,
                   ESRFormatted__c,
                   ProjectCostCenter__r.Name,
                   AccountNameLegal__c,
                   InvoiceDocumentNr__c,
                   InvoiceStatus__c
            FROM Invoice__c
            WHERE Id = :record.Id
        ];
        
        // Retrieve organization information for address details.
        Organization companyInfo = [SELECT Name, Address FROM Organization LIMIT 1];
        
        String companyName = QRCodeUtils.getCompanyName(record.ProjectCostCenter__r.Name);
        String invoiceNameLabel = QRCodeUtils.getInvoiceNameLabel(record.InvoiceDocumentNr__c, language);
        if (String.isBlank(record.ProjectCostCenter__r.CHFQRIBAN__c)) {
            throw new HandledException('Missing CH-IBAN (ProjectCostCenter__r.CHFQRIBAN__c) for QR invoice.');
        }
        String iban = QRCodeUtils.cleanIban(record.ProjectCostCenter__r.CHFQRIBAN__c);
        
        // Build and populate the QRCodeRequestObj object.
        QRCodeRequestObj req = new QRCodeRequestObj();
        req.creditorInformation = new QRCodeRequestObj.CreditorInformation();
        req.creditorInformation.iban = iban;
        req.creditorInformation.creditor = new QRCodeRequestObj.Creditor();
        req.creditorInformation.creditor.addressType = 'STRUCTURED';
        req.creditorInformation.creditor.name = companyName;
        req.creditorInformation.creditor.streetName = companyInfo.Address.getStreet();
        req.creditorInformation.creditor.postalCode = companyInfo.Address.getPostalCode();
        req.creditorInformation.creditor.city = companyInfo.Address.getCity();
        req.creditorInformation.creditor.country = 'CH';
        
        req.ultimateDebtor = new QRCodeRequestObj.UltimateDebtor();
        req.ultimateDebtor.addressType = 'STRUCTURED';
        req.ultimateDebtor.name = record.AccountNameLegal__c;
        req.ultimateDebtor.streetName = record.BillingAddressStreetNr__c;
        req.ultimateDebtor.postalCode = record.BillingAddressZIP__c;
        req.ultimateDebtor.city = record.BillingAdressCity__c;
        req.ultimateDebtor.country = 'CH';
        
        req.paymentAmountInformation = new QRCodeRequestObj.PaymentAmountInformation();
        req.paymentAmountInformation.amount = record.InvoiceTotalAmountGross__c;
        req.paymentAmountInformation.currency_z = record.ProjectInvoiceCurrency__c;
        
        req.paymentReference = new QRCodeRequestObj.PaymentReference();
        req.paymentReference.additionalInformation = new QRCodeRequestObj.AdditionalInformation();
        // Validate the amount and set the unstructured message accordingly.
        if(req.paymentAmountInformation.amount != 0){
            req.paymentReference.additionalInformation.unstructuredMessage = invoiceNameLabel;
        } else {
            req.paymentReference.additionalInformation.unstructuredMessage = 'DO NOT USE FOR PAYMENT';
        }
        
        // If the IBAN is a QR-IBAN, generate a structured reference.
        if (QRCodeUtils.isQrIban(iban)) {
            if (record.InvoiceStatus__c == 'Draft' && record.InvoiceDocumentNr__c == null)
            {
                record.InvoiceDocumentNr__c = 0;
                record.ESRFormatted__c = 'DRAFT Invoice';
            }

            String baseForReference;
            if (record.InvoiceDocumentNr__c != null) {
                baseForReference = String.valueOf(record.InvoiceDocumentNr__c);
            } else if (String.isNotBlank(record.ESRFormatted__c)) {
                baseForReference = record.ESRFormatted__c;
            } else {
                throw new HandledException('Missing InvoiceDocumentNr__c and ESRFormatted__c for QR reference generation.');
            }
            String qrReference = QRCodeUtils.generateQrReference(baseForReference);
            req.paymentReference.reference = qrReference;
            req.paymentReference.referenceType = 'QRR';
        } else {
            req.paymentReference.reference = '';
            req.paymentReference.referenceType = '';
        }
        
        return req.toJson();
    }
}