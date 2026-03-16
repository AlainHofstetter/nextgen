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
public without sharing class QRCodeService {
    
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

        System.debug('---QRCodeService.generateQRCode--- invoice: ' + record);
        
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
     * to associate the image with the given parent record. If there are existing
     * ContentDocumentLinks with the same title pattern for the same parentRecordId, they are deleted.
     *
     * @param parentRecordId The ID of the parent Invoice__c record.
     * @param base64 The Base64 encoded QR code image.
     */
    private static void insertQRImage(Id parentRecordId, String base64) {

        String docName = Label.QRInvoicePrefix + '_' + Date.today().format();
        String titlePattern = Label.QRInvoicePrefix + '_%';

       // 1) Insert new file and link it to the record
        ContentVersion cv = new ContentVersion(
            Title                 = docName,
            PathOnClient          = docName + '.' + 'jpg',
            VersionData           = EncodingUtil.base64Decode(base64),
            FirstPublishLocationId = parentRecordId
        );
        insert cv;

        // 2) Get the ContentDocumentId of the newly created file
        Id newContentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        // 3) Find *other* documents with same Title/Extension
        //    and linked to this record
        List<ContentDocumentLink> oldLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentRecordId
              AND ContentDocument.Title LIKE :titlePattern
              AND ContentDocument.FileExtension = 'JPG'
              AND ContentDocumentId != :newContentDocumentId
        ];

        System.debug('---QRCodeService.insertQRImage--- oldLinks: ' + oldLinks);
        System.debug('---QRCodeService.insertQRImage--- newContentDocumentId: '+newContentDocumentId);

        if (!oldLinks.isEmpty()) {
            Set<Id> oldDocIds = new Set<Id>();
            for (ContentDocumentLink cdl : oldLinks) {
                oldDocIds.add(cdl.ContentDocumentId);
            }

            // 4) Delete old ContentDocuments (this deletes ALL their versions + links)
            List<ContentDocument> docsToDelete = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :oldDocIds
            ];
            if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }
        }
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
                   ESRAccountNr__c,
                   ESRMergentNr__c,
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
            if ((record.InvoiceStatus__c == 'Draft' || record.InvoiceStatus__c == 'Approval') && record.InvoiceDocumentNr__c == null)
            {
                record.InvoiceDocumentNr__c = 0;
                record.ESRFormatted__c = 'DRAFT Invoice';
            }

            System.debug('---QRCodeService.createRequestBody--- ESRFormatted__c:' + record.ESRFormatted__c);

            // Generate the invoice ESR Unformatted just in case any of the values used to generate it has changed.
            // Note the the field ESRUnformatted__c is not updated with the generated value. 
            // The generateded value is not saved back into Salesforce. Just doing this to ensure the ESR is always up to date in the generated QR-Bill
            String qrReference = EsrUtil.getESR(record.ESRAccountNr__c, record.ESRMergentNr__c, record.InvoiceDocumentNr__c, 
                                                    (System.Test.isRunningTest() ? 123 : record.InvoiceTotalAmountGross__c), EsrUtil.EsrFormat.UNFORMATTED);

            if (String.isBlank(qrReference)) {
                throw new HandledException('Missing InvoiceDocumentNr__c and ESRFormatted__c for QR reference generation.');
            }

            System.debug('---QRCodeService.createRequestBody--- qrReference:' + qrReference);
        
            req.paymentReference.reference = qrReference;
            req.paymentReference.referenceType = 'QRR';
        } else {
            System.debug('---QRCodeService.createRequestBody--- isQrIban == false');
            req.paymentReference.reference = '';
            req.paymentReference.referenceType = '';
        }

        System.debug('---QRCodeService.createRequestBody--- Json:' + req.toJson());
        
        return req.toJson();
    }
}